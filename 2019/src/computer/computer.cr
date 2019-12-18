require "immutable"
require "big/big_int"

enum OpCode
  Add,
  Multiply,
  Input,
  Output,
  JumpIfTrue,
  JumpIfFalse,
  LessThan,
  Equal,
  AdjustBase,
  Halt
end

alias IC = BigInt

record Operation,
       code : Int32,
       id : OpCode,
       num_read_params : Int32,
       num_write_params : Int32 do

  def size
    num_read_params + num_write_params + 1
  end
end

record Instruction,
       operation : Operation,
       read_params : Array(IC),
       write_params : Array(IC),
       mode : Array(Int32) do
  def self.from(data : Program, offset)
    opcode = data.at(offset).to_i
    op = Program.operations[opcode % 100]
    params = (offset + 1..offset + op.size).map { |i| data.at(i) }.each
    new operation: op,
        read_params: params.first(op.num_read_params).to_a,
        write_params: params.first(op.num_write_params).to_a,
        mode: opcode.to_s.rjust(op.size+1, '0').reverse.each_char.skip(2).map(&.to_i).to_a
  end

  def read(data : Program, relative_base : BigInt) : Array(IC)
    read_params.zip(mode).map do |p, m|
      case m
      when 0
        data.at(p)
      when 1
        p
      when 2
        data.at(relative_base + p)
      else raise "unknown parameter mode: #{m}"
      end
    end
  end

  def write_address(relative_base)
    case mode[operation.num_read_params]
    when 0, 1
      write_params.first
    when 2
      write_params.first + relative_base
    else raise "unknown parameter mode: #{mode[operation.size]}"
    end
  end

  def jump?(data, relative_base)
    case operation.id
    when OpCode::JumpIfTrue
      cond, target = read(data, relative_base)
      cond != 0 && target
    when OpCode::JumpIfFalse
      cond, target = read(data, relative_base)
      cond == 0 && target
    else
      false
    end
  end

  def output?
    operation.id == OpCode::Output
  end

  def adjust_base?(data, relative_base) : BigInt | Bool
    if operation.id == OpCode::AdjustBase
      read(data, relative_base).first
    else
      false
    end
  end

  def halt?
    operation.id == OpCode::Halt
  end
end

record Program,
       data : Immutable::Vector(IC),
       extra : Immutable::Map(BigInt, IC) do
  def self.operations
    {1  => Operation.new(code: 1,  id: OpCode::Add, num_read_params: 2, num_write_params: 1),
     2  => Operation.new(code: 2,  id: OpCode::Multiply, num_read_params: 2, num_write_params: 1),
     3  => Operation.new(code: 3,  id: OpCode::Input, num_read_params: 0, num_write_params: 1),
     4  => Operation.new(code: 4,  id: OpCode::Output, num_read_params: 1, num_write_params: 0),
     5  => Operation.new(code: 5,  id: OpCode::JumpIfTrue, num_read_params: 2, num_write_params: 0),
     6  => Operation.new(code: 6,  id: OpCode::JumpIfFalse, num_read_params: 2, num_write_params: 0),
     7  => Operation.new(code: 7,  id: OpCode::LessThan, num_read_params: 2, num_write_params: 1),
     8  => Operation.new(code: 8,  id: OpCode::Equal, num_read_params: 2, num_write_params: 1),
     9  => Operation.new(code: 9,  id: OpCode::AdjustBase, num_read_params: 1, num_write_params: 0),
     99 => Operation.new(code: 99, id: OpCode::Halt, num_read_params: 0, num_write_params: 0)}
  end

  def at(address : BigInt) : IC
    if address < data.size
      data.at(address.to_i)
    else
      extra.fetch address, BigInt.new(0)
    end
  end

  def set(address : BigInt, value : IC) : Program
    if address < data.size
      copy_with data: data.set(address, value)
    else
      copy_with extra: extra.set(address, value)
    end
  end
end

def panic(message, exit_code = 1)
  STDERR.puts "computer: #{message}"
  exit exit_code
end

def apply(instruction : Instruction,
          data : Program,
          relative_base : BigInt,
          input : IO::FileDescriptor | Channel(IC) = STDIN)
  case instruction.operation.id
  when OpCode::Add
    a, b = instruction.read(data, relative_base)
    data.set(instruction.write_address(relative_base), a + b)
  when OpCode::Multiply
    a, b = instruction.read(data, relative_base)
    data.set(instruction.write_address(relative_base), a * b)
  when OpCode::Input
    result = case input
             when IO::FileDescriptor
               STDERR.puts "computer: input integer"
               input.gets.not_nil!.to_big_i || raise "can't read int from input"
             when Channel(IC)
               input.receive
             else raise "unexpected input"
             end
    data.set(instruction.write_address(relative_base), result)
  when OpCode::LessThan
    a, b = instruction.read(data, relative_base)
    data.set(instruction.write_address(relative_base), (a < b ? 1 : 0).to_big_i)
  when OpCode::Equal
    a, b = instruction.read(data, relative_base)
    data.set(instruction.write_address(relative_base), (a == b ? 1 : 0).to_big_i)
  when OpCode::Output, OpCode::JumpIfFalse, OpCode::JumpIfTrue,
       OpCode::AdjustBase, OpCode::Halt
    data
  else
    panic "fatal: unrecognized opcode #{instruction.operation.code}"
  end
end

def run_intcode(data : Program,
                input : IO::FileDescriptor | Channel(IC) = STDIN,
                output : IO::FileDescriptor | Channel(IC) = STDOUT)
  offset = BigInt.new(0)
  relative_base = BigInt.new(0)
  loop do
    next_instruction = Instruction.from(data, offset)
    break data if next_instruction.halt?
    target = next_instruction.jump?(data, relative_base)
    offset = case target
             when Bool
               offset + next_instruction.operation.size
             when BigInt
               target
             else raise "unexpected target #{target}"
    end
    if next_instruction.output?
      value = next_instruction.read(data, relative_base).first
      case output
      when IO::FileDescriptor
        output.puts value
      when Channel(IC)
        output.send value
      else raise "unexpected output"
      end
    end
    adjust_base = next_instruction.adjust_base?(data, relative_base)
    case adjust_base
    when BigInt
      relative_base += adjust_base
    end
    data = apply(next_instruction, data, relative_base, input)
  end
end

def format_program(data : Program, use_newline = false)
  data.data.each_slice(4).map(&.join(" ")).join(use_newline ? "\n" : " ") + data.extra.to_s
end

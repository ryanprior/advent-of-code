require "immutable"

enum OpCode
  Add,
  Multiply,
  Input,
  Output,
  JumpIfTrue,
  JumpIfFalse,
  LessThan,
  Equal,
  Halt
end

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
       read_params : Array(Int32),
       write_params : Array(Int32),
       mode : Array(Int32) do
  def self.from(data_in, offset)
    opcode = data_in[offset]
    op = Intcode.operations[opcode % 100]
    params = data_in.to_a[offset + 1..offset + op.size].each
    new operation: op,
        read_params: params.first(op.num_read_params).to_a,
        write_params: params.first(op.num_write_params).to_a,
        mode: opcode.to_s.rjust(op.size+1, '0').reverse.each_char.skip(2).map(&.to_i).to_a
  end

  def read(data)
    read_params.zip(mode).map do |p, m|
      case m
      when 0
        data[p]
      when 1
        p
      else raise "unknown parameter mode: #{m}"
      end
    end
  end

  def jump?(data)
    case operation.id
    when OpCode::JumpIfTrue
      cond, target = read(data)
      cond != 0 && target
    when OpCode::JumpIfFalse
      cond, target = read(data)
      cond == 0 && target
    else
      false
    end
  end

  def output?
    operation.id == OpCode::Output
  end

  def halt?
    operation.id == OpCode::Halt
  end
end

module Intcode
  def self.operations
    {1  => Operation.new(code: 1,  id: OpCode::Add, num_read_params: 2, num_write_params: 1),
     2  => Operation.new(code: 2,  id: OpCode::Multiply, num_read_params: 2, num_write_params: 1),
     3  => Operation.new(code: 3,  id: OpCode::Input, num_read_params: 0, num_write_params: 1),
     4  => Operation.new(code: 4,  id: OpCode::Output, num_read_params: 1, num_write_params: 0),
     5  => Operation.new(code: 5,  id: OpCode::JumpIfTrue, num_read_params: 2, num_write_params: 0),
     6  => Operation.new(code: 6,  id: OpCode::JumpIfFalse, num_read_params: 2, num_write_params: 0),
     7  => Operation.new(code: 7,  id: OpCode::LessThan, num_read_params: 2, num_write_params: 1),
     8  => Operation.new(code: 8,  id: OpCode::Equal, num_read_params: 2, num_write_params: 1),
     99 => Operation.new(code: 99, id: OpCode::Halt, num_read_params: 0, num_write_params: 0)}
  end
end

def panic(message, exit_code = 1)
  STDERR.puts "computer: #{message}"
  exit exit_code
end

alias Program = Immutable::Vector(Int32)

def apply(instruction : Instruction,
          data : Program,
          input : IO::FileDescriptor | Channel(Int32) = STDIN)
  case instruction.operation.id
  when OpCode::Add
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a + b)
  when OpCode::Multiply
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a * b)
  when OpCode::Input
    result = case input
             when IO::FileDescriptor
               STDERR.puts "computer: input integer"
               input.gets.not_nil!.to_i || raise "can't read int from input"
             when Channel(Int32)
               input.receive
             else raise "unexpected input"
             end
    data.set(instruction.write_params.first, result)
  when OpCode::Output, OpCode::JumpIfFalse, OpCode::JumpIfTrue
    data
  when OpCode::LessThan
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a < b ? 1 : 0)
  when OpCode::Equal
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a == b ? 1 : 0)
  when OpCode::Halt
    data
  else
    panic "fatal: unrecognized opcode #{instruction.operation.code}"
  end
end

def run_intcode(data : Program,
                input : IO::FileDescriptor | Channel(Int32) = STDIN,
                output : IO::FileDescriptor | Channel(Int32) = STDOUT)
  offset = 0
  loop do
    panic "fatal: no more instructions" if offset > data.size
    next_instruction = Instruction.from(data, offset)
    break data if next_instruction.halt?
    target = next_instruction.jump?(data)
    offset = case target
             when Bool
               offset + next_instruction.operation.size
             when Int32
               target
             else raise "malformed target #{target}"
    end
    if next_instruction.output?
      value = next_instruction.read(data).first
      case output
      when IO::FileDescriptor
        output.puts value
      when Channel(Int32)
        output.send value
      else raise "unexpected output"
      end
    end
    data = apply(next_instruction, data, input)
  end
end

def format_program(data, use_newline = false)
  data.each_slice(4).map(&.join(" ")).join(use_newline ? "\n" : " ")
end

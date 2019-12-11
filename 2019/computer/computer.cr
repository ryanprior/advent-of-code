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
  def halt?
    code == 99
  end

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

def apply(instruction, data)
  case instruction.operation.id
  when OpCode::Add
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a + b)
  when OpCode::Multiply
    a, b = instruction.read(data)
    data.set(instruction.write_params.first, a * b)
  when OpCode::Input
    input = loop do
      STDERR.puts "computer: input integer"
      result = STDIN.gets || raise "can't read from stdin"
      break result.to_i do
        STDERR.puts "computer: try again"
        next
      end
    end || raise "can't get input"
    data.set(instruction.write_params.first, input)
  when OpCode::Output
    puts instruction.read(data).first
    data
  when OpCode::JumpIfFalse, OpCode::JumpIfTrue
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

def run(data)
  offset = 0
  loop do
    panic "fatal: no more instructions" if offset > data.size
    next_instruction = Instruction.from(data, offset)
    break data if next_instruction.operation.halt?
    target = next_instruction.jump?(data)
    offset = case target
             when Bool
               offset + next_instruction.operation.size
             when Int32
               target
             else raise "malformed target #{target}"
    end
    data = apply(next_instruction, data)
  end
end

def format_program(data, use_newline = false)
  data.each_slice(4).map(&.join(" ")).join(use_newline ? "\n" : " ")
end

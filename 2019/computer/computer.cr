require "immutable"

enum OpCode
  Add,
  Multiply,
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
       write_params : Array(Int32) do
  def self.from(data_in, offset)
    op = Intcode.operations[data_in[offset]]
    params = data_in.to_a[offset + 1..offset + op.size].each
    new operation: op,
        read_params: params.first(op.num_read_params).to_a,
        write_params: params.first(op.num_write_params).to_a
  end
end

module Intcode
  def self.operations
    {1  => Operation.new(code: 1,  id: OpCode::Add, num_read_params: 2, num_write_params: 1),
     2  => Operation.new(code: 2,  id: OpCode::Multiply, num_read_params: 2, num_write_params: 1),
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
    a, b = instruction.read_params.map { |param| data[param] }
    data.set(instruction.write_params.first, a + b)
  when OpCode::Multiply
    a, b = instruction.read_params.map { |param| data[param] }
    data.set(instruction.write_params.first, a * b)
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
    offset += next_instruction.operation.size
    data = apply(next_instruction, data)
  end
end

def format_program(data, use_newline = false)
  data.each_slice(4).map(&.join(" ")).join(use_newline ? "\n" : " ")
end

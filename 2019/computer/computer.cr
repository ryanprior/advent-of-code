require "immutable"

def instruction(data, offset)
  [data[offset*4], data[offset*4 + 1]?, data[offset*4 + 2]?, data[offset*4 + 3]?]
end

def halt?(instruction)
  instruction.first == 99
end

def panic(message, exit_code = 1)
  STDERR.puts "computer: #{message}"
  exit exit_code
end

def apply(instruction, data)
  opcode, register_a, register_b, destination = instruction
  return data if !register_a
  register_a = register_a || 0
  register_b = register_b || 0
  destination = destination || 0
  data.set(destination, case opcode
                        when 1
                          data[register_a] + data[register_b]
                        when 2
                          data[register_a] * data[register_b]
                        else
                          panic "fatal: unrecognized opcode #{opcode}"
                        end)
end

def run(data)
  offset = 0
  loop do
    panic "warning: no more instructions, halting" if offset*4 > data.size
    next_instruction = instruction(data, offset)
    break if halt? next_instruction
    data = apply(next_instruction, data)
    offset += 1
  end
  data
end

def format_program(data, use_newline = false)
  data.each_slice(4).map(&.join(" ")).join(use_newline ? "\n" : " ")
end

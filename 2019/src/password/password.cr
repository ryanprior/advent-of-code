require "option_parser"
require "immutable"

def six_digits?(num)
  num.to_s.size == 6
end

# def two_consecutive_digits?(num)
#   chars = num.to_s.each_char.to_a
#   chars[0..-2].zip(chars[1..-1]).any? { |pair| pair.first == pair.last }
# end

def digit_runs(num)
  num.to_s.each_char
    .reduce(Immutable::Vector.new([] of NamedTuple(digit: Char, length: Int32))) do |runs, digit|
    if runs.last? && runs.last[:digit] == digit
      runs.set(-1, runs.last.merge({length: runs.last[:length] + 1}))
    else
      runs << {length: 1, digit: digit}
    end
  end
end

def increasing?(num)
  num.to_s.each_char.reduce('\0') do |highest, char|
    return false if char < highest
    {highest, char}.max
  end
  true
end

def panic(message, exit_code = 1)
  STDERR.puts "password: #{message}"
  exit exit_code
end

def run_length_qualifies?(num, cap_length)
  if cap_length
    digit_runs(num).any? { |run| run[:length] == 2 }
  else
    digit_runs(num).any? { |run| run[:length] >= 2 }
  end
end

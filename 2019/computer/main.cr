require "cli"
require "./computer.cr"

abstract class IntcodeCommand < Cli::Command
  @program : Program | Nil = nil

  class Options
    bool ["-v", "--verbose"], desc: "print verbose output", default: false
    bool ["-o", "--one-line"], desc: "print output on one line", default: false
    arg "file", desc: "intcode program filename", default: "-"
    help
  end

  def program : Program
    return @program.not_nil! if @program
    program_file = case args.file
                   when "", "-"
                     STDIN
                   else
                     File.open(args.file)
                   end

    result = Immutable.from(program_file.gets.not_nil!.split(",").map(&.to_big_i))
    @program = Program.new result, Immutable::Map(BigInt, IC).new
    STDERR.puts "program:\n#{format_program(@program.not_nil!, !options.one_line?)}" if options.verbose?
    @program.not_nil!
  end
end

class Computer < Cli::Supercommand
  command "run", default: true

  class Options
    help
  end

  class Run < IntcodeCommand

    class Options
      bool ["-q", "--quiet"], desc: "quiet program result; only print explicit outputs"
      array ["-s", "--substitute"], desc: "substitute data before running the program (eg \"1,12\")"
    end

    class Help
      header "Virtual machine to execute intcode programs"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      new_program = options.substitute.reduce(program) do |accum, sub|
        index, value = sub.split(",").map(&.to_big_i)
        accum.set(index, value)
      end
      STDERR.puts "(end of program output)" if options.verbose?
      STDERR.puts "result:" if options.verbose?
      result = run_intcode(new_program)
      puts format_program(result, !options.one_line?) unless options.quiet?
    end
  end

  class Search < IntcodeCommand
    class Options
      string "--target", desc: "Search target", required: true
      string "--domain", desc: "Search domain, comma-separated (eg \"0,99\")", required: true
    end

    class Help
      header "Utility to search for appropriate inputs to intcode programs"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def domain
      domain_panic_message = "error: domain must be two comma-separated integers"
      result = options.domain.split(",")
      panic domain_panic_message unless result.size == 2
      result.map(&.to_big_i)
    end

    def target
      options.target.to_big_i
    end

    def success(noun, verb)
      puts "computer: search success: noun #{noun} and verb #{verb} produce result #{target}"
      exit 0
    end

    def failure
      puts "computer: search failure: no combination of inputs in #{domain} produce result #{target}"
      exit 2
    end

    def progress(noun, verb, result)
      STDERR.puts "computer: progress: noun #{noun} and verb #{verb} produced non-matching result #{result}"
    end

    def run
      chan = Channel({noun: IC, verb: IC, result: IC}).new

      min, max = domain
      (min..max).each do |noun|
        spawn do
          (min..max).each do |verb|
            new_program = program.set(BigInt.new(1), noun).set(BigInt.new(2), verb)
            chan.send({noun: noun, verb: verb, result: run_intcode(new_program).data.first})
          end
        end
      end
      ((max-min)**2).times do
        data = chan.receive
        if data[:result] == target
          success data[:noun], data[:verb]
        else
          progress data[:noun], data[:verb], data[:result] if options.verbose?
        end
      end
      failure
    end
  end

  class Optimize < IntcodeCommand
    class Options
      string "--domain",
             desc: "domain of phase input, comma separated (eg \"0,4\")",
             required: true
      bool "--loop", desc: "loop the inputs and outputs for modules during optimization"
    end

    class Help
      header "Utility to optimize output to thrusters"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def domain
      domain_panic_message = "error: domain must be two comma-separated integers"
      result = options.domain.split(",")
      panic domain_panic_message unless result.size == 2
      result.map(&.to_big_i)
    end

    def run
      candidates = Channel({phase: Array(IC), result: IC}).new
      min, max = domain

      (min..max).to_a.each_permutation.each_slice(16) do |group|
        spawn do
          group.each do |phase|
            channels = phase.map { |n| Channel(IC).new(2).send n }
            ch_init = channels.shift
            ch_init.send 0.to_big_i
            channels.push options.loop? ? ch_init : Channel(IC).new(2)
            status = Channel(Symbol).new()
            result = channels.reduce(ch_init) do |ch_in, ch_next|
              spawn same_thread: true do
                run_intcode(program,
                            input: ch_in,
                            output: ch_next)
                status.send :finished
              end
              ch_next
            end
            (max-min).times { status.receive }
            candidates.send({phase: phase,
                             result: result.receive})
          end
        end
      end

      max_output = {phase: [0], result: -1}
      Math.gamma(max - min + 2).to_i.times do
        data = candidates.receive
        if data[:result] > max_output[:result]
          max_output = data
        end
      end
      STDERR.puts "max output result:"
      puts max_output[:result]
      STDERR.puts "corresponding phase inputs:"
      puts max_output[:phase]
    end
  end
end

Computer.run ARGV

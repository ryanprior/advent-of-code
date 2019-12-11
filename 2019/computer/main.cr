# require "option_parser"
require "cli"
require "./computer.cr"

abstract class IntcodeCommand < Cli::Command
  class Options
    bool ["-v", "--verbose"], desc: "print verbose output", default: false
    bool ["-o", "--one-line"], desc: "print output on one line", default: false
    arg "file", desc: "intcode program filename", default: "-"
    help
  end

  def program
    program_file = case args.file
                   when "", "-"
                     STDIN
                   else
                     File.read(args.file)
                   end

    result = Immutable.from(program_file.each_line.first.split(",").map(&.to_i))
    STDERR.puts "program:\n#{format_program(result, !options.one_line?)}" if options.verbose?
    result
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
        index, value = sub.split(",").map(&.to_i { panic "error: substitutions must be integers" })
        accum.set(index, value)
      end
      STDERR.puts "(end of program output)" if options.verbose?
      STDERR.puts "result:" if options.verbose?
      result = run(new_program)
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
      result.map(&.to_i { panic domain_panic_message })
    end

    def target
      options.target.to_i { panic "error: target must be an integer" }
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
      min, max = domain
      (min..max).each do |noun|
        (min..max).each do |verb|
          new_program = program.set(1, noun).set(2, verb)
          result = run(new_program)
          if result.first == target
            success noun, verb
          else
            progress noun, verb, result.first if options.verbose?
          end
        end
      end
      failure
    end
  end
end

Computer.run ARGV

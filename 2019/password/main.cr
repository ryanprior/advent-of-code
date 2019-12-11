require "./password"
require "cli"

class Password < Cli::Command
  class Options
    bool ["-v", "--verbose"], desc: "Print verbose output"
    bool "--cap-run-length", desc: "Disqualify runs of more than two identical digits"
    arg "min", desc: "minimum password bound", required: true
    arg "max", desc: "maximum password bound", required: true
  end

  class Help
    header "Searches for secure container passwords according to specifications provided by elves"
    footer "This tool is part of Ryan Prior's 2019 Advent of Code"
  end

  def range
    {args.min.to_i { panic "error: min not an integer" },
     args.max.to_i { panic "error: max not an integer" }}
  end

  def run
    result = [] of Int32
    (range.first..range.last).each do |i|
      result << i if six_digits?(i) &&
                     run_length_qualifies?(i, options.cap_run_length?) &&
                     # two_consecutive_digits?(i) &&
                     increasing?(i)
    end
    STDERR.puts "# of matches:" if options.verbose?
    puts result.size
    if options.verbose?
      STDERR.puts "matches:"
      STDERR.puts result.join('\n')
    end
  end
end

Password.run ARGV

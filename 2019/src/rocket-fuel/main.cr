require "cli"
require "./rocket-fuel"
require "cli"

class RocketFuel < Cli::Command
  class Options
    bool ["-x", "--extra"],
         desc: "Add extra fuel per-module to account for module fuel weight",
         default: false
    arg "file", desc: "Input file with comma-separated module weights", required: true
    help
  end

  class Help
    header "Calculate rocket fuel requirement to rescue Santa"
    footer "This tool is part of Ryan Prior's 2019 Advent of Code"
  end

  def run
    input = File.read(args.file).each_line.map(&.to_f)
    puts fuel_total(input, options.extra?)
  rescue
    STDERR.puts "rocket-fuel: error: no such file \"#{args.file}\""
  end
end

RocketFuel.run ARGV

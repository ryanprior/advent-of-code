require "./orbit"
require "cli"

def panic(message, exit_code = 1)
  STDERR.puts "orbit: #{message}"
  exit exit_code
end

abstract class OrbitCommand < Cli::Command
  class Options
    arg "file", desc: "universal orbit map filename", default: "-"
    help
  end

  def program_file
    case args.file
    when "-"
      STDIN
    else begin
           File.read(args.file)
         rescue
           panic "error: no such file #{args.file}"
         end
    end
  end

  def input
    program_file.each_line.map(&.split(")"))
  end

  def orbits
    input.reduce(OrbitMap.new) do |orbits, pair|
      add_orbit(pair.last, pair.first, orbits)
    end
  end
end

class OrbitCli < Cli::Supercommand
  class Options
    help
  end

  class Help
    header "Reads and processes Universal Orbit Maps"
    footer "This tool is part of Ryan Prior's 2019 Advent of Code"
  end

  class Sum < OrbitCommand
    def run
      puts sum_distances(orbits)
    end
  end

  class PathDistance < OrbitCommand
    def run
      path_you = path_to_root("YOU", orbits)
      path_san = path_to_root("SAN", orbits)
      puts path_you.size + path_san.size - 2*(path_you & path_san).size
    end
  end
end

OrbitCli.run ARGV

require "./trace-wires"
require "cli"

abstract class WireCommand < Cli::Command
  class Options
    arg "file", desc: "wire input filename", default: "-"
    help
  end

  def instructions
    input = args.file != "-" ? File.read(args.file) : STDIN
    input.each_line.map do |line|
      line.split(",").map { |i| parse_instruction i }
    end.to_a.compact
  end

  def wires
    instructions.map { |w| trace_wire w }
  end
end

class TraceWires < Cli::Supercommand
  command "print-wires", default: true

  class Options
    help
  end

  class PrintWires < WireCommand
    class Help
      header "Print wire segments"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      wire_a, wire_b = wires
      puts wire_a
      puts wire_b
    end
  end

  class Intersections < WireCommand
    class Help
      header "Find all wire intersections"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      wire_a, wire_b = wires
      puts intersections(wire_a, wire_b).reject({0, 0}).uniq
    end
  end

  class NearestIntersection < WireCommand
    class Help
      header "Find distance to wire intersection nearest to origin"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      wire_a, wire_b = wires
      puts intersections(wire_a, wire_b).reject({0, 0}).map(&.map(&.abs).sum).min
    end
  end

  class ShortestPathIntersection < WireCommand
    class Help
      header "Finds the shortest path distance from the origin to any intersection"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      wire_a, wire_b = wires
      candidates = intersections(wire_a, wire_b).reject({0, 0}).uniq
      shortest_path = candidates.map do |candidate|
        path_distance_to(wire_a, candidate) + path_distance_to(wire_b, candidate)
      end.min
      puts shortest_path
    end
  end
end

TraceWires.run ARGV

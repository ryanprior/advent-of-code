require "cli"
require "immutable"
require "./asteroid"

class AsteroidCommand < Cli::Command
  @map : Array(Point) | Nil = nil

  class Options
    string %w(-c --center), desc: "center viewpoint from which to calculate (eg \"0, 3\")"
    arg "file", desc: "map file", required: true
    help
  end

  def center
    values = options.center.split(",")
             .map(&.to_i { abort "detect: error: center point must have integer values"})
    abort "detect: error: center point must have exactly two values (eg \"0,3\")" unless values.size == 2
    {x: values[0], y: values[1]}
  end

  def file
    File.open(args.file)
  rescue
    abort "asteroid: error: no such file #{args.file}"
  end

  def map(center=nil) : Array(Point)
    return @map.not_nil! if @map
    result = load_map(file)
    if(center)
      abort "asteroid: error: no asteroid present at center #{center}" unless result.includes? center
      result.delete center
    end
    @map = result
  end
end

class Asteroid < Cli::Supercommand
  class Optimize < AsteroidCommand
    class Help
      header "Locates a site that can detect the greatest number of asteroids"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      if(options.center?)
        puts visible_asteroids(center, map(center)).size
      else
        best = map.max_by { |c| visible_asteroids(c, map.reject c).size }
        puts best, visible_asteroids(best, map.reject best).size
      end
    end
  end

  class Vaporize < AsteroidCommand
    class Options
      string %w(-c --center), required: true
      string "--number", required: false
    end

    class Help
      header "Vaporizes visible asteroids, reporting progress"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def number
      options.number.to_i { abort "asteroid: error: number must be an integer"}
    end

    def run
      targets = AsteroidIterator.new(center, map(center))
      if options.number?
        puts targets.skip(number-1).first
      else
        puts targets
      end
    end
  end
end

Asteroid.run ARGV

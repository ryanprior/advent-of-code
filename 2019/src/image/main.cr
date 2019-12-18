require "cli"
require "./image.cr"

class ImageCommand < Cli::Command
  class Options
    string %w(-d --dimensions),
           desc: "dimensions of input image in pixels (eg \"3x5\")",
           required: true
    arg "file", desc: "image file to read (in Space Image Format)"
    help
  end

  def dimensions
    args.dimensions.split("x").map(&.to_i {abort "image: error: dimensions must be integers"})
  end
end

class Image < Cli::Supercommand
  class Check < ImageCommand
    class Help
      header "Summarizes the content of an image (SIF) for error checking purposes"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      input = File.read(args.file).strip
      counts = layers(input, dimensions).map(&.tally)
      layer = counts.min_by(&.fetch '0', 0)
      puts layer['1'] * layer['2']
    end
  end

  class Show < ImageCommand
    class Help
      header "Prints an image (SIF) to the console"
      footer "This tool is part of Ryan Prior's 2019 Advent of Code"
    end

    def run
      input = File.read(args.file).strip
      puts format_sif(assemble(layers(input, dimensions)), dimensions.first)
    end
  end
end

Image.run ARGV

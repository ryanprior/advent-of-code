require "colorize"

def layers(data, dimensions)
  data.each_char.each_slice(dimensions.product).to_a
end

def assemble(layers)
  layers.reduce(['2'] * layers.first.size) do |result, layer|
    result.zip(layer).map { |a, b| a == '2' ? b : a }
  end
end

def format_sif(image, width)
  image.each_slice(width).map do |line|
    line.map do |char|
      case char
      when '1'
        "█".colorize :white
      when '0'
        "█".colorize :black
      else
        " "
      end
    end.join
  end.join "\n"
end

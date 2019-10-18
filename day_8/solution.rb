require 'hamster'

module SleighNavigationLicense
  Node = Struct.new(:children, :meta, keyword_init: true) do
    def all_metadata
      Hamster::Vector.new(meta) + children.map { |child| child.all_metadata }
    end
  end

  def self.read_license(string)
    input = Hamster::Vector.new(string.split(' '))
    num_children, num_meta = input.take(2).map(&:to_i)
    input = input.drop 2
    children = case num_children
               when 0 then []
               else
                 result = []
                 num_children.times do
                   child, rem = self.read_license(input.join(' '))
                   result << child
                   input = input.drop(input.length - rem.length)
                 end
                 result
               end
    meta = input.take(num_meta).map(&:to_i)
    input = input.drop(num_meta)
    result = Node.new(children: children, meta: meta)
    [result, input]
  end
end

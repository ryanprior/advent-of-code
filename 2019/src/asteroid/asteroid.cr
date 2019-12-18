alias Point = {x: Int32, y: Int32}

def load_map(file) : Array(Point)
  file.each_line.map_with_index do |line, i|
    line.each_char.map_with_index do |char, j|
      case char
      when '#'
        {x: j, y: i}
      else
        nil
      end
    end
  end.flatten.compact
end

record Vector2, x : Float64, y : Float64 do
  def initialize(point_a : Point, point_b : Point)
    @x = (point_b[:x] - point_a[:x]).to_f64
    @y = (point_b[:y] - point_a[:y]).to_f64
  end

  def length : Float64
    Math.sqrt(x ** 2.0 + y ** 2.0)
  end

  def /(n : Float)
    copy_with x: x / n, y: y / n
  end

  def round(n)
    copy_with x: x.round(n), y: y.round(n)
  end

  def to_unit
    self / length
  end

  def angle_displacement(offset=0.0)
    (Math.atan2(y, x) + offset) % (2*Math::PI)
  end

  def same_direction?(other)
    (to_unit.x - other.to_unit.x < 0.0000001) &&
      (to_unit.y - other.to_unit.y < 0.0000001)
  end
end

def visible_asteroids(center, asteroid_map)
  asteroid_map.reduce(Immutable::Map(Vector2, Point).new) do |accum, point|
    vec = Vector2.new(center, point)
    key = vec.to_unit.round(6)
    if(accum[key]? && Vector2.new(center, accum[key]).length < vec.length)
      accum
    else
      accum.set(key, point)
    end
  end
end

class AsteroidIterator
  @visible : Array(Point)
  @center : Point
  @remaining : Array(Point)
  @index : Int32

  include Iterator(Point)
  def initialize(@center : Point, map)
    @visible = visible_asteroids(center, map).values.sort_by do |p|
      Vector2.new(center, p).angle_displacement(Math::PI/2)
    end
    @remaining = map - @visible
    @index = 0
  end

  def next
    if @index < @visible.size
      result = @visible[@index]
      @index += 1
      result
    else
      if @remaining.size > 0
        @visible = visible_asteroids(@center, @remaining).values.sort_by do |p|
          Vector2.new(@center, p).angle_displacement(Math::PI/2)
        end
        @remaining = @remaining - @visible
        @index = 1
        @remaining[0]
      else
        stop
      end
    end
  end
end

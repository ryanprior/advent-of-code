enum Direction
  Up
  Right
  Down
  Left
end

def panic(message, exit_code = 1)
  STDERR.puts "trace-wires: #{message}"
  exit exit_code
end

def intersect?(segment_a, segment_b)
  # WOLOG, segment_a is always parallel to the x axis & segment_b to the y axis
  segment_a, segment_b = {segment_b, segment_a} if segment_a[0][0] != segment_a[1][0]
  return nil unless segment_a[0][0] == segment_a[1][0] && segment_b[0][1] == segment_b[1][1]
  if segment_a.map(&.at(1)).min <= segment_b[0][1] &&
     segment_a.map(&.at(1)).max >= segment_b[0][1] &&
     segment_b.map(&.at(0)).min <= segment_a[0][0] &&
     segment_b.map(&.at(0)).max >= segment_a[0][0]
    {segment_a[0][0], segment_b[0][1]}
  else
    nil
  end
end

def intersections(wire_a, wire_b)
  # This algorithm has N-squared run time, we could create a spanning tree
  # structure to improve this if necessary
  result = [] of {Int32, Int32}
  wire_a.each do |segment_a|
    wire_b.each do |segment_b|
      i = intersect? segment_a, segment_b
      result << i if i
    end
  end
  result
end

def trace_wire_from(start_point, instruction)
  start_x, start_y = start_point
  direction = instruction[:direction]
  distance = instruction[:distance]
  {start_point, case direction
                when Direction::Up
                  {start_x, start_y + distance}
                when Direction::Right
                  {start_x + distance, start_y}
                when Direction::Down
                  {start_x, start_y - distance}
                when Direction::Left
                  {start_x - distance, start_y}
                else raise "unknown direction: #{direction}"
                end}
end

def trace_wire(instructions, origin = {0, 0})
  instructions.reduce([{origin, origin}]) do |accum, instruction|
    accum.push(trace_wire_from(accum.last.last, instruction))
  end
end

def segment_length(point_a, point_b)
  (point_a[0] - point_b[0]).abs + (point_a[1] - point_b[1]).abs
end

def path_distance_to(wire, intersection)
  wire.reduce(0) do |accum, segment|
    i = intersect? segment, {intersection, intersection}
    if i
      return accum + segment_length(segment[0], intersection)
    else
      accum + segment_length(*segment)
    end
  end
end

def parse_instruction(string)
  direction, distance_string = string[0], string[1..-1]
  {direction: case direction
              when 'U'
                Direction::Up
              when 'R'
                Direction::Right
              when 'D'
                Direction::Down
              when 'L'
                Direction::Left
              else
                panic "error: directions must be characters [URDL]"
              end,
   distance: distance_string.to_i { panic "error: distances must be integers" }}
end

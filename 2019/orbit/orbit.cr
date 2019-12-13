require "immutable"

alias OrbitMap = Immutable::Map(String, String)

def add_orbit(name, direct_name, orbits)
  orbits.set(name, direct_name)
end

class Orbits
  include Iterator(String)
  def initialize(name : String, data : OrbitMap)
    @data = data
    @name = name
  end

  def next
    result = @data[@name]?
    if result
      @name = result
      result
    else
      stop
    end
  end
end

def path_to_root(name, orbits)
  Orbits.new(name, orbits).to_a
end

def distance_to_root(name, orbits)
  path_to_root(name, orbits).size
end

def sum_distances(orbits)
  orbits.keys.map { |orbit| distance_to_root orbit, orbits }.sum
end

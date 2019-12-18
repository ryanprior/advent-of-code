def fuel_amount(mass, add_fuel_for_fuel)
  result = (mass/3).floor - 2
  return 0 if result < 0
  add_fuel_for_fuel ? result + fuel_amount result, add_fuel_for_fuel : result
end

def fuel_total(modules, add_fuel_for_fuel)
  modules.map { |mod| fuel_amount mod, add_fuel_for_fuel }.sum
end

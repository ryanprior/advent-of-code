all: bin/rocket-fuel bin/computer bin/trace-wires bin/password

bin/%: %/main.cr %/*.cr
	crystal build $< -o $@

# bin/rocket-fuel: day-1/main.cr day-1/rocket-fuel.cr
# 	crystal build $< -o $@

# bin/computer: day-2/main.cr day-2/computer.cr
# 	crystal build $< -o $@

# bin/trace-wires: day-3/trace-wires.cr
# 	crystal build $< -o $@

# bin/password: day-4/password.cr
# 	crystal build $< -o $@

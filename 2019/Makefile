bins := rocket-fuel computer trace-wires password orbit image asteroid

all: $(foreach bin,$(bins),bin/$(bin))

bin/%: src/%/main.cr src/%/*.cr
	crystal build -Dpreview_mt $< -o $@

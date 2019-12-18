all: bin/rocket-fuel bin/computer bin/trace-wires bin/password bin/orbit bin/image

bin/%: src/%/main.cr src/%/*.cr
	crystal build -Dpreview_mt $< -o $@

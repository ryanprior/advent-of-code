all: bin/rocket-fuel bin/computer bin/trace-wires bin/password bin/orbit bin/image

bin/%: %/main.cr %/*.cr
	crystal build -Dpreview_mt $< -o $@

INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)

default: build

build clean:
	@dune $@

install uninstall:
	@dune $@ $(INSTALL_ARGS)

reinstall: uninstall install

run: build
	@dune exec hello.exe

test:
	@dune runtest

.PHONY: default install uninstall reinstall test clean

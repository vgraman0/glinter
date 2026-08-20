.PHONY: test hooks install uninstall

test:
	lua tests/run.lua
	nvim --headless -u NONE -n -l tests/nvim_spec.lua
	./bin/glinter tests/fixtures/good.txt
	./bin/glinter tests/fixtures/bad.txt; test $$? -eq 1
	sh tests/install_spec.sh

install:
	./install-nvim

uninstall:
	./install-nvim --uninstall

hooks:
	git config core.hooksPath .githooks

.PHONY: test hooks

test:
	lua tests/run.lua
	nvim --headless -u NONE -n -l tests/nvim_spec.lua
	./bin/glinter tests/fixtures/good.txt
	./bin/glinter tests/fixtures/bad.txt; test $$? -eq 1

hooks:
	git config core.hooksPath .githooks

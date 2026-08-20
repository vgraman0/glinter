.PHONY: test

test:
	lua tests/run.lua
	nvim --headless -u NONE -n -l tests/nvim_spec.lua

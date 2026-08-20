LUA ?= lua
export LUA_PATH := ./?.lua;./?/init.lua;$(LUA_PATH)

.PHONY: test lint demo setup

setup:
	./scripts/dev-setup.sh

test:
	busted spec/

lint:
	luacheck glinter spec bin/glinter

demo:
	./bin/glinter --version
	./bin/glinter lint --no-color "feat: add parser"
	./bin/glinter lint --no-color "WIP" || true

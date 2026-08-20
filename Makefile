.PHONY: test hooks install uninstall release

VERSION ?=

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

# Cut a release: make release VERSION=0.2.0
# Edit lua/glinter/version.lua and CHANGELOG.md first. This checks them,
# runs the tests, and writes the tag. Push it with:
#   git push -u origin main && git push origin v0.2.0
release:
	@test -n "$(VERSION)" || { echo "usage: make release VERSION=X.Y.Z" >&2; exit 2; }
	@echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' \
		|| { echo "version must be X.Y.Z" >&2; exit 2; }
	@test -z "$$(git status --porcelain)" \
		|| { echo "working tree is dirty" >&2; exit 2; }
	@src=$$(./bin/glinter --version | awk '{print $$2}'); \
		test "$$src" = "$(VERSION)" \
		|| { echo "lua/glinter/version.lua says $$src" >&2; exit 2; }
	@grep -q '^## \[$(VERSION)\]' CHANGELOG.md \
		|| { echo "CHANGELOG.md has no entry for $(VERSION)" >&2; exit 2; }
	@git rev-parse -q --verify refs/tags/v$(VERSION) >/dev/null \
		&& { echo "tag v$(VERSION) already exists" >&2; exit 2; } || true
	$(MAKE) test
	git tag -a v$(VERSION) -m "glinter v$(VERSION)"
	@echo "tagged v$(VERSION); push it with: git push origin v$(VERSION)"

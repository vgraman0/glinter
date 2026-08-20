# Glinter

Lua CLI that lints commit messages against Conventional Commits.

## Commands

- Run tests: `make test`
- Lint Lua sources: `make lint`
- Smoke the CLI: `./bin/glinter lint --no-color "feat: add parser"`
- Install local toolchain: `./scripts/dev-setup.sh`

## Cursor Cloud specific instructions

Cloud Agents should use Lua 5.4. `scripts/dev-setup.sh` installs `lua5.4`,
`luarocks`, `busted`, and `luacheck`. This is a CLI, not a long-running
server; do not start a development server. Use `make test` to verify
changes.

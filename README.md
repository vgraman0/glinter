# Glinter

Write better commit messages. Instant feedback.

Glinter is a small Lua CLI that lints git commit messages against
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
and tells you exactly what to fix.

## Requirements

- Lua 5.4 (5.1+ works for the linter itself)
- [LuaRocks](https://luarocks.org/) plus `busted` and `luacheck` for tests

```sh
./scripts/dev-setup.sh
```

## Usage

```sh
./bin/glinter lint "feat: add parser"
./bin/glinter lint --file .git/COMMIT_EDITMSG
echo "WIP" | ./bin/glinter lint
./bin/glinter hook install
```

A good message:

```
✔ commit message looks good
```

A bad message:

```
✖ commit message failed lint
  • header-format: header must be `type(scope)?: subject`
    Example: feat(cli): add lint command
```

Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`,
`refactor`, `revert`, `style`, `test`.

## Development

```sh
make test
make lint
make demo
```

# AGENTS.md

## Cursor Cloud specific instructions

`glinter` is a Neovim/Lua plugin plus a Lua CLI that lint git commit messages
(Chris Beams structure + clear English). There is no server and no build step:
`lua/` and `plugin/` load directly, and `bin/glinter` runs the same engine from
the shell. See `README.md`, `Makefile`, and `docs/rules.md` for the full picture.

### Dependencies

The only dependencies are the system packages `lua5.4` and `neovim`, installed
by the startup update script (matching `.github/workflows/ci.yml`). Nothing else
is fetched per-repo; there is no lockfile or package-manager install step.

### Test, lint, run

- Test: `make test`. It runs the Lua unit tests (`lua tests/run.lua`), the
  headless Neovim highlight checks (`nvim --headless -u NONE -n -l
  tests/nvim_spec.lua`), the CLI against `tests/fixtures/{good,bad}.txt`, and
  `tests/install_spec.sh`.
- Lint a message: `bin/glinter FILE`, `bin/glinter --stdin`, or a commit range
  `bin/glinter --range origin/main..HEAD`. Exit code is non-zero on errors or
  warnings. `bin/glinter --version` prints the version.
- Run in Neovim (interactive): `./install-nvim` links this checkout into the
  per-user packpath (`~/.local/share/nvim/site/pack/glinter/start/glinter`);
  `./install-nvim --check` verifies it loads. The plugin attaches on `FileType
  gitcommit` and paints only the message lines, leaving comments and the diff
  alone. Rest the cursor on a highlight or run `:GlinterHover` for the rule id.

### Non-obvious notes

- `bin/glinter` picks the first of `lua`, `lua5.4`, `lua5.1`, then `nvim
  --headless`. With this environment it uses `lua5.4`.
- The `commit-msg` hook (`make hooks` sets `core.hooksPath .githooks`) resolves
  `bin/glinter` relative to the committing repo's root, so it only works inside a
  glinter checkout. It blocks the commit on both errors and warnings.
- Commits in this repo are linted by CI and by the glinter skill/rule
  (`.cursor/rules/glinter.mdc`, `.cursor/skills/glinter/SKILL.md`). Write commit
  messages that pass `bin/glinter`: imperative capitalized subject, no trailing
  period, no adverbs/hedges/passive voice. Do not use `--no-verify`.

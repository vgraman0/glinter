# glinter

Hemingway-style live highlighting for git commit messages in Neovim, plus
the [Chris Beams](https://cbea.ms/git-commit/) structure rules. No grade
level. No Conventional Commits.

While you type in `COMMIT_EDITMSG`, glinter paints the **message** lines
only. Git comments and the verbose diff are left alone. The same rules
run in a `commit-msg` hook and in CI.

## Install (Neovim)

lazy.nvim:

```lua
{
  dir = "/path/to/glinter", -- or your git URL
  ft = "gitcommit",
}
```

The plugin attaches on `FileType gitcommit` and refreshes on
`TextChanged` / `TextChangedI`. Optional setup:

```lua
require("glinter").setup({
  debounce_ms = 40,
  colorcolumn = true, -- 51 and 73
})
```

Colors match Hemingway: yellow/red sentences, blue adverbs and
qualifiers, green passive, purple simpler words.

## CLI and hook

```
bin/glinter FILE
bin/glinter --stdin
bin/glinter --range origin/main..HEAD
```

Needs Lua 5.1+ or Neovim. In this repository:

```
make hooks    # git config core.hooksPath .githooks
make test
```

The hook fails on errors and warnings.

## Rules

See [docs/rules.md](docs/rules.md) and
[`.cursor/skills/glinter/SKILL.md`](.cursor/skills/glinter/SKILL.md).

# glinter

Hemingway-style live highlighting for git commit messages in Neovim, plus
the [Chris Beams](https://cbea.ms/git-commit/) structure rules. No grade
level. No Conventional Commits.

While you type in `COMMIT_EDITMSG`, glinter paints the **message** lines
only. Git comments and the verbose diff are left alone. The same rules
are in a Cursor skill, a `commit-msg` hook, and CI.

Use Neovim, the agent skill, the CLI, or any mix. None of them requires
the others.

## Neovim, first time

Install [Neovim](https://neovim.io) (`nvim --version`). You do not need
a plugin manager, an `init.lua`, or any Lua.

```sh
git clone https://github.com/vgraman0/glinter
cd glinter
./install-nvim
```

That links this clone into Neovim's built-in plugin folder. Keep the
clone; update with `git pull` and restart Neovim.

Point git at Neovim, then commit as usual:

```sh
git config --global core.editor nvim
git commit
```

While you type, glinter paints the **message** lines. Git comments and
the verbose diff stay as they are. Quit Neovim with `:q`.

See a sample without committing:

```sh
./install-nvim --try
```

Windows (PowerShell), skip the script and clone into Neovim's plugin
folder:

```powershell
git clone https://github.com/vgraman0/glinter $env:LOCALAPPDATA\nvim-data\site\pack\glinter\start\glinter
```

You do not need the Cursor skill, the CLI, or a git hook. Only `lua/`
and `plugin/` load.

The plugin attaches on `FileType gitcommit` and refreshes on
`TextChanged` / `TextChangedI`. Skip the next block unless you want
to change defaults:

```lua
require("glinter").setup({
  debounce_ms = 40,
  colorcolumn = true, -- 51 and 73
  hover_ms = 300, -- delay before the recommendation float
})
```

Colors are set by glinter, not your colorscheme: Hemingway pastels
(yellow/red sentences, blue adverbs, green passive, purple simpler
words) with a dark foreground so the text stays readable. Override
the `Glinter*` highlight groups if you want them to follow a theme.

Rest the cursor on a highlight (or press `K` / `:GlinterHover`) to see
the rule id and the fix, for example `[H4] Use active voice`.

A plugin install does not copy the Cursor skill into your project.

### Already using a plugin manager?

Skip `./install-nvim`. lazy.nvim:

```lua
{
  "vgraman0/glinter",
  ft = "gitcommit",
}
```

Neovim 0.12 (`vim.pack`):

```lua
vim.pack.add({ "https://github.com/vgraman0/glinter" })
```

## Agent skill only

Copy [`.cursor/skills/glinter/SKILL.md`](.cursor/skills/glinter/SKILL.md)
to one of:

- this project: `.cursor/skills/glinter/SKILL.md`
- every project: `~/.cursor/skills/glinter/SKILL.md`

The skill is the rule tables. Cursor does not need Neovim, `bin/glinter`,
or this repository on disk after the copy.

Optional: copy [`.cursor/rules/glinter.mdc`](.cursor/rules/glinter.mdc)
so the skill always applies when committing. That rule file tells the
agent to run `bin/glinter` only when the binary exists.

## CLI and hook

Optional enforcement, used in this repository:

```
bin/glinter FILE
bin/glinter --stdin
bin/glinter --range origin/main..HEAD
```

Needs Lua 5.1+ or Neovim. In a clone of this repository:

```
make hooks    # git config core.hooksPath .githooks
make test
```

The hook fails on errors and warnings. You can use the CLI without
Neovim or Cursor.

## Rules

See [docs/rules.md](docs/rules.md) and
[`.cursor/skills/glinter/SKILL.md`](.cursor/skills/glinter/SKILL.md).

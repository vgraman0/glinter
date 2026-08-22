# glinter

[![CI](https://github.com/vgraman0/glinter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vgraman0/glinter/actions/workflows/ci.yml)

<img src="./doc/demo-no-zoom-v3.gif" alt="glinter highlighting weasel words in a git commit message"/>

**glinter** flags problems in your git commit message while you write it. The rules are based on Chris Beams' ![prose conventions](https://cbea.ms/git-commit/) (imperative mood, body wrapping, etc). There are also guidelines for clearer language (long sentences, passive voice, simpler-word alternatives). See [Rules](#rules) for more details.

Three ways to run them, each standalone:
- Neovim plugin
- CLI for commit-msg hooks and CI
- Skill.md if an agent writes your messages

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Rules](#rules)
- [CLI and hook](#cli-and-hook)
- [Skill (optional)](#skill-optional)
- [Options](#options)
- [Releases](#releases)

## Requirements

- Neovim 0.7 or newer
- Git
- Lua 5.1+ only if you want the CLI without Neovim

## Installation

<details>
  <summary>lazy.nvim</summary>

```lua
{
  "vgraman0/glinter",
  ft = "gitcommit",
  version = "*", -- latest release; drop this line to track main
}
```

</details>

<details>
  <summary>Packer</summary>

```lua
use {
  "vgraman0/glinter",
  ft = "gitcommit",
}
```

</details>

<details>
  <summary>Paq</summary>

```lua
require("paq") {
  "vgraman0/glinter",
}
```

</details>

<details>
  <summary>vim-plug</summary>

```vim
Plug 'vgraman0/glinter'
```

</details>

<details>
  <summary>dein</summary>

```vim
call dein#add('vgraman0/glinter')
```

</details>

<details>
  <summary>vim.pack (Neovim 0.12+)</summary>

```lua
vim.pack.add({
  { src = "https://github.com/vgraman0/glinter", version = vim.version.range("*") },
})
```

</details>

<details>
  <summary>Pathogen</summary>

```sh
git clone https://github.com/vgraman0/glinter ~/.vim/bundle/glinter
```

</details>

<details>
  <summary>Neovim native package</summary>

Install [Neovim](https://neovim.io) (`nvim --version`). You do not need
a plugin manager, an `init.lua`, or any Lua. Clone into Neovim's
built-in plugin folder:

```sh
git clone https://github.com/vgraman0/glinter \
  ~/.local/share/nvim/site/pack/glinter/start/glinter
```

Windows (PowerShell):

```powershell
git clone https://github.com/vgraman0/glinter $env:LOCALAPPDATA\nvim-data\site\pack\glinter\start\glinter
```

Keep the clone; update with `git pull` and restart Neovim. Only `lua/`
and `plugin/` load.

</details>

## Quick Start

Point git at Neovim, then commit as usual:

```sh
git config --global core.editor nvim
git commit
```

Rest the cursor on a highlight (or press `K` / `:GlinterHover`) to see
the rule id and the fix, for example `[H4] Use active voice`.

Full docs in Neovim: `:help glinter`. Run `:checkhealth glinter` if
highlighting or the hook does not look right.

Agents can follow the same rules without Neovim: see
[Skill (optional)](#skill-optional).

## Rules

Git tooling and [How to Write a Git Commit Message](https://cbea.ms/git-commit/).
One-line commits are valid. A body is not required. Git-generated
subjects (`Merge `, `Revert `, `fixup! `, `squash! `, `amend! `) are
exempt.

### Chris Beams structure (must-fix)

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| S0  | subject-empty        | Subject is non-empty after comments are ignored. |
| S1  | subject-blank-line   | If a body exists, a blank line separates it from the subject. |
| S3  | subject-hard-length  | Subject is at most 72 characters. Highlight column 73+. |
| S4  | subject-capitalize   | Subject starts with uppercase `A–Z` (UTF-8 letters pass). Leading space fails. |
| S5  | subject-no-period    | Subject does not end with `.`, `!`, or `?`. Interior periods (`U.S.`) are fine. |
| B1  | body-wrap            | Body lines wrap at 72 characters. Exempt: trailers, lines that are a single URL. |

### Chris Beams mood and content (should-fix)

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| S6  | subject-imperative   | Completes *If applied, this commit will \<subject\>*. |
| S7  | subject-wip          | Subject does not start with `WIP`. |
| C1  | why-not-how          | Body explains why, not how. Weak machine check. |

### Clear English (should-fix)

Prefer short, active, plain sentences. Do not score grade level.

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| H1  | sentence-hard        | Sentence is more than 20 words (yellow). |
| H2  | sentence-very-hard   | Sentence is more than 30 words (red). H2 replaces H1. |
| H3  | adverb               | Manner adverbs and intensifiers (blue). |
| H4  | passive              | Be-verb plus past participle (green). |
| H5  | qualifier            | Hedges such as `maybe`, `I think` (blue). |
| H6  | simpler-word         | Closed list of weasel words with a simpler synonym (purple). |

Each rule, with its heuristic, is also in `:help glinter-rules`.

## CLI and hook

Optional enforcement, used in this repository:

```
bin/glinter FILE
bin/glinter --stdin
bin/glinter --range origin/main..HEAD
bin/glinter --version
```

Needs Lua 5.1+ or Neovim. In a clone of this repository:

```
make hooks    # git config core.hooksPath .githooks
make test
```

The hook fails on errors and warnings.

## Skill (optional)

The rule tables also ship as an agent skill, so a coding agent writes
commit messages the same way. Copy [SKILL.md](SKILL.md) from the
repository into your own project, or into `~/.cursor/skills/glinter/`.

Installing the plugin does not install the skill.

## Options

The plugin attaches on `FileType gitcommit` and refreshes on
`TextChanged` / `TextChangedI`. Call `setup` only if you want to
change defaults:

```lua
require("glinter").setup({
  debounce_ms = 40,
  colorcolumn = true, -- 73
  hover_ms = 300, -- delay before the recommendation float
})
```

### Colors

Colors are set by glinter, not your colorscheme. A dark foreground
keeps the text readable. Override the `Glinter*` highlight groups if
you want them to follow a theme.

| Group | Color | Rules |
| --- | --- | --- |
| `GlinterHard` | yellow | H1 (sentence > 20 words) |
| `GlinterVeryHard` | red | H2 (sentence > 30 words) |
| `GlinterAdverb` | blue | H3 |
| `GlinterQualifier` | blue | H5 |
| `GlinterPassive` | green | H4 |
| `GlinterComplex` | purple | H6 |
| `GlinterSubjectHard` | red | S3, B1 |
| `GlinterError` | red | S0, S1, S4, S5 |
| `GlinterWarning` | yellow | S6, S7, C1 |
| `GlinterReplacement` | purple italic | simpler-word hint at end of line |

```lua
vim.api.nvim_set_hl(0, "GlinterHard", { link = "WarningMsg" })
```

## Releases

Releases are tags of the form `vMAJOR.MINOR.PATCH`. Read
[CHANGELOG.md](CHANGELOG.md) for what each one changed, and
[doc/releasing.md](doc/releasing.md) for how to cut one.
`bin/glinter --version` and `require("glinter").version` print the
version you have.

Version 0.x means the Lua API and the rule ids can still change in a
minor release.

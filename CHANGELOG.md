# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Tags are
`vMAJOR.MINOR.PATCH`, so `version = "*"` in lazy.nvim and a tag in
`vim.pack` both pin to a release.

Version 0.x means the Lua API and the rule ids can still change in a minor
release. Breaking changes always show up here.

## [Unreleased]

### Added

- `:help glinter`, covering options, commands, highlight groups, the
  rules, and the CLI.
- `:checkhealth glinter`, for the Neovim version, a git work tree, and
  the commit-msg hook.

### Removed

- S2 (`subject-soft-length`): the 50-character subject warning. Subjects
  may run to 72 characters. The color column is 73 only.

### Fixed

- H3 no longer treats `Dragonfly` as an adverb.

## [0.1.0] - 2026-08-21

First tagged release.

### Added

- Live highlighting in `COMMIT_EDITMSG`, on message lines only. Git
  comments and the verbose diff stay as they are.
- Chris Beams structure rules: subject length, mood, trailing period,
  blank second line, and body wrapping.
- Clear English prose rules: long sentences, passive voice, adverbs,
  hedges, and simpler words.
- Hover on a highlight, or press `K` / `:GlinterHover`, for the rule id
  and the fix.
- `bin/glinter` for a file, `--stdin`, or `--range REV`. It exits 1 when
  it finds a problem.
- `glinter --version`, and `require("glinter").version` in Lua.
- A `commit-msg` hook in `.githooks` and a CI job that lints the commits
  in a push or a pull request.
- A Cursor skill (`SKILL.md`) and rule that carry the same rule tables.

[Unreleased]: https://github.com/vgraman0/glinter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/vgraman0/glinter/releases/tag/v0.1.0

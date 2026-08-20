# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Tags are
`vMAJOR.MINOR.PATCH`, so `version = "*"` in lazy.nvim and a tag in
`vim.pack` both pin to a release.

Version 0.x means the Lua API and the rule ids can still change in a minor
release. Breaking changes always show up here.

## [Unreleased]

## [0.1.0] - 2026-08-20

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
- A Cursor skill and rule that carry the same rule tables.
- `install-nvim` for people who do not use a plugin manager.

[Unreleased]: https://github.com/vgraman0/glinter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/vgraman0/glinter/releases/tag/v0.1.0

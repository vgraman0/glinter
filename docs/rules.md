# Glinter rule catalog

Glinter checks git commit messages. It is not a general prose editor.

## Classify (not a style rule)

Diagnostics apply to the real message only:

- Ignore lines that start with `core.commentChar` (default `#`).
- Ignore the scissors line (`# --- >8 ---`) and everything after it.
- Subject is the first non-empty message line. A body is optional.
- Trailer lines at the end (`Signed-off-by:`, `Fixes:`,
  `(cherry picked from commit …)`) are structure, not prose.
- Auto-generated subjects are exempt: `Merge `, `Revert `, `fixup! `,
  `squash! `, `amend! `.

Byte offsets use buffer coordinates in `COMMIT_EDITMSG`. Classify which
ranges to lint; do not delete lines from the buffer.

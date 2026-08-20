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

## Chris Beams structure (must-fix)

Git tooling and [How to Write a Git Commit Message](https://cbea.ms/git-commit/).

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| S0  | subject-empty        | Subject is non-empty after comments are ignored. |
| S1  | subject-blank-line   | If a body exists, a blank line separates it from the subject. |
| S3  | subject-hard-length  | Subject is at most 72 characters. Highlight column 73+. |
| S4  | subject-capitalize   | Subject starts with uppercase `A–Z` (UTF-8 letters pass). Leading space fails. |
| S5  | subject-no-period    | Subject does not end with `.`, `!`, or `?`. Interior periods (`U.S.`) are fine. |
| B1  | body-wrap            | Body lines wrap at 72 characters. Exempt: trailers, lines that are a single URL. |

## Chris Beams mood and content (should-fix)

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| S2  | subject-soft-length  | Subject is at most 50 characters. Highlight columns 51–72. |
| S6  | subject-imperative   | Completes *If applied, this commit will \<subject\>*. |
| S7  | subject-wip          | Subject does not start with `WIP`. |
| C1  | why-not-how          | Body explains why, not how. Weak machine check. |

One-line commits are valid. A body is not required.

### S6 heuristic

Flag the first word when it is a common past-tense verb (`Fixed`, `Added`,
…), a gerund (`Fixing`), or a pronoun starter (`This`, `I`, `We`, `I've`).
`Don't` / `Do not` are imperative. Noun-phrase subjects (`Overflow fix`)
may slip through.

## Out of scope

- Conventional Commit types (`feat:`, `fix:`)
- Atomic-commit / squash policy
- Highlighting the verbose diff

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

Live Neovim highlighting re-classifies the buffer on every edit and
paints only message ranges. Comment lines and the verbose diff stay
with the default gitcommit syntax.

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

## Clear English (should-fix, no grade level)

Prefer short, active, plain sentences. No ARI, Flesch–Kincaid, or overall
score. Flag long sentences and weakeners.

| ID  | Name                 | Check |
| --- | -------------------- | ----- |
| H1  | sentence-hard        | Sentence is more than 20 words (yellow). |
| H2  | sentence-very-hard   | Sentence is more than 30 words (red). H2 replaces H1. |
| H3  | adverb               | Manner adverbs and intensifiers (blue). |
| H4  | passive              | Be-verb plus past participle (green). |
| H5  | qualifier            | Hedges such as `maybe`, `I think` (blue). |
| H6  | simpler-word         | Closed list of weasel words with a simpler synonym (purple). |

The subject is one sentence even without a period. Apply H* to subject
and body prose only, not comments, diffs, trailers, or URL lines.

## Out of scope

- Readability grade / ARI / Flesch–Kincaid
- Grammar, spelling, punctuation
- Conventional Commit types (`feat:`, `fix:`)
- Atomic-commit / squash policy
- Highlighting the verbose diff

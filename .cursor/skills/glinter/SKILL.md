---
name: glinter
description: Write simple git commit messages (Chris Beams + Hemingway, no grade level). Use when committing, drafting COMMIT_EDITMSG, amending, squashing, or reviewing commit text.
---

# Glinter commit messages

Every commit in this repo must pass `bin/glinter`. Do not use Conventional
Commits (`feat:`, `fix:`). Do not skip the hook with `--no-verify`.

A properly formed subject completes: **If applied, this commit will
\<subject\>**.

## Before you commit

1. Write the message (subject + optional body).
2. Run `bin/glinter path/to/COMMIT_EDITMSG` (or `--stdin`).
3. Fix every diagnostic. This repo fails on errors **and** warnings.

In Neovim, glinter highlights `gitcommit` buffers while you type. Comments
and the verbose diff are not part of the message.

## Structure (must-fix)

| ID | Rule |
| --- | --- |
| S0 | Subject is not empty |
| S1 | Blank line between subject and body (if there is a body) |
| S2 | Subject ≤ 50 characters (warning; columns 51–72) |
| S3 | Subject ≤ 72 characters (error; column 73+) |
| S4 | Capitalize the subject. No leading space |
| S5 | No `.` `!` `?` at the end of the subject |
| B1 | Wrap body lines at 72 characters (URLs and trailers exempt) |

A one-line commit is fine. Git-generated subjects (`Merge `, `Revert `,
`fixup! `, `squash! `, `amend! `) are exempt.

## Mood and content

| ID | Rule |
| --- | --- |
| S6 | Imperative subject. Not `Fixed`, `Fixing`, `This`, `I`, `We` |
| S7 | Do not start with `WIP` |
| C1 | Body explains **why**, not how. The diff already shows how |

## Hemingway style (no grade level)

| ID | Color | Rule |
| --- | --- | --- |
| H1 | yellow | Sentence > 20 words |
| H2 | red | Sentence > 30 words |
| H3 | blue | Adverbs (`really`, `quickly`, `very`, `too` + adjective) |
| H4 | green | Passive (`was written`, `were added`) |
| H5 | blue | Qualifiers (`maybe`, `I think`, `just`, `basically`) |
| H6 | purple | Weasel word with a simpler synonym |

`-ly` allowlist (do not flag): only, early, likely, daily, weekly, monthly,
yearly, family, apply, supply, reply, ally, assembly, fly.

Simpler words: utilize→use, leverage→use, facilitate→help, commence→start,
subsequently→then, therefore→so, additional→more, attempt→try, obtain→get,
regarding→about, numerous→many, assist→help, accomplish→do,
demonstrate→show, terminate→end, remainder→rest, sufficient→enough,
necessitate→need, in order to→to, due to the fact that→because,
at this time→now, in the event that→if. Sentence-initial however→but.

## Pass

```
Fix overflow on long commit subjects

Subjects longer than 72 characters break git log and GitHub.
Cap the hard limit and warn at 50 so the line stays a summary.
```

## Fail

```
fixed the thing.

Added a really comprehensive implementation that utilizes the new
framework so that highlighting can basically be applied in a way that is
very easily understood by users who might perhaps want to leverage it.
```

Full catalog: [docs/rules.md](../../../docs/rules.md).

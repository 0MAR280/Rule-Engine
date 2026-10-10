---
name: commit-staged
description: Draft a commit message following the repo's docs/Commit-Messages.md rules and commit only the currently staged changes. Use when the user asks to commit staged changes, write a commit message from staged files, or follow the project's commit message format in this repo.
---

# Commit Staged

Commits exactly what is already in the git index — nothing else. Never run `git add`, and never include unstaged or untracked changes in the commit or in the message's basis.

## Workflow

1. Read `docs/Commit-Messages.md` in the repo root and follow its format exactly.
2. Inspect **staged changes only**: `git status --short` and `git diff --cached --stat`, then `git diff --cached` for details. Ignore unstaged and untracked content when drafting the message.
3. Draft the message per the guide:
   - Title: `type(Scope) Short description` — lowercase `type` from the guide's table, main touched module as `(Scope)` with no space before `(`, one short line, no trailing period.
   - Blank line, then body bullets starting with `- `: plain English, one concrete change each, truthful (removed = removed, renamed = renamed), no filler like "update code" or "misc".
4. Run the checklist at the bottom of `docs/Commit-Messages.md` against the drafted message.
5. Write the message to a temp file and commit via the bundled script:
   `bash <skill-dir>/scripts/commit_staged.sh <message-file>`
6. Report the resulting commit hash and confirm unstaged/untracked files were untouched.

## Script behavior

`scripts/commit_staged.sh <message-file>`:

- Verifies it is inside a git work tree and that the message file exists.
- Refuses to commit when nothing is staged (`git diff --cached --quiet`), so an empty commit is never created.
- Runs `git commit -F <message-file>`, which records only the index — staged changes only, by construction.

On failure (nothing staged, bad message file), the script exits non-zero with a clear error; surface that error to the user instead of working around it.

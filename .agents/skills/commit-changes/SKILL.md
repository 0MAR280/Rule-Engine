---
name: commit-changes
description: Stage all changes in the repo, draft a commit message following the repo's docs/Commit-Messages.md rules, and commit. Use when the user asks to commit changes, stage and commit, save work, or follow the project's commit message format in this repo.
---

# Commit Changes

Stages every change in the repo (modifications, deletions, and untracked files) and commits them in one step. If the user wants to commit only what is already staged, use the `commit-staged` skill instead.

## Workflow

1. Read `docs/Commit-Messages.md` in the repo root and follow its format exactly.
2. Review what will be committed: `git status --short` and `git diff --stat`, plus `git diff` for unstaged details. The commit will include ALL of these, so the message must cover all of them.
3. Draft the message per the guide:
   - Title: `type(Scope) Short description` — lowercase `type` from the guide's table, main touched module as `(Scope)` with no space before `(`, one short line, no trailing period.
   - Blank line, then body bullets starting with `- `: plain English, one concrete change each, truthful (removed = removed, renamed = renamed), no filler like "update code" or "misc".
4. Run the checklist at the bottom of `docs/Commit-Messages.md` against the drafted message.
5. Write the message to a temp file and run the bundled script:
   `bash <skill-dir>/scripts/commit_changes.sh <message-file>`
6. Report the resulting commit hash and confirm the working tree is clean afterwards.

## Script behavior

`scripts/commit_changes.sh <message-file>`:

- Verifies it is inside a git work tree and that the message file exists.
- Refuses to run when there is nothing to commit (clean tree and index), so no empty commit is ever created.
- Runs `git add -A` followed by `git commit -F <message-file>` — everything in the repo is staged and committed in one commit.

On failure (nothing to commit, bad message file), the script exits non-zero with a clear error; surface that error to the user instead of working around it.

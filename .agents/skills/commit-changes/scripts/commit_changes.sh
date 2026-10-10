#!/usr/bin/env bash
# Stage all changes in the repo, then commit them with a message file.
# Refuses to run when there is nothing to commit.
set -euo pipefail

usage() {
  echo "usage: commit_changes.sh <message-file>" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage

MSG_FILE="$1"
[ -f "$MSG_FILE" ] || { echo "error: message file not found: $MSG_FILE" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: not inside a git work tree" >&2
  exit 1
}

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "error: no changes to commit -- working tree and index are clean" >&2
  exit 1
fi

git add -A
git commit -F "$MSG_FILE"

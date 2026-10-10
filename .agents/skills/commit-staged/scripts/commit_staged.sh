#!/usr/bin/env bash
# Commit only what is already staged, using a message file.
# Refuses to run when nothing is staged, so no empty commit is ever created.
set -euo pipefail

usage() {
  echo "usage: commit_staged.sh <message-file>" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage

MSG_FILE="$1"
[ -f "$MSG_FILE" ] || { echo "error: message file not found: $MSG_FILE" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: not inside a git work tree" >&2
  exit 1
}

if git diff --cached --quiet; then
  echo "error: nothing staged -- stage the intended changes first, then re-run" >&2
  exit 1
fi

# git commit records only the index; unstaged and untracked files are left alone.
git commit -F "$MSG_FILE"

#!/bin/sh
# Purpose: list a project's local changes under checks/ before a refresh overwrites them (v0.9.8.1 R5). Run as
# the plugin's own copy, sh "${CLAUDE_PLUGIN_ROOT}/checks/local-changes.sh", from the project's top level, so a
# project whose checks/ predates it needs nothing. Lists the commits touching checks/ since the last commit whose
# subject starts "Refresh checks/ to VID" (with none, since the commit that first carried checks/), then the
# uncommitted changes under checks/ (staged, unstaged, untracked). A refresh replaces checks/ whole: each listed
# change is carried over by hand or dropped on purpose. Prints, one a line: `since <sha> <subject>`, then `commit
# <sha> <subject>` and `uncommitted <status> <path>`, then a count line. Reads only; exit 0, or 2 outside a repository.
# Usage: sh local-changes.sh
set -eu
git rev-parse --git-dir >/dev/null 2>&1 || { echo 'ViD local-changes: not inside a repository' >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"
BASE=$(git log --format='%H' --grep='^Refresh checks/ to VID' -n 1 2>/dev/null || true)
if [ -z "$BASE" ]; then BASE=$(git log --format='%H' --reverse -- checks 2>/dev/null | head -n 1); fi
if [ -z "$BASE" ]; then echo 'since - (no commit carries checks/)'; RANGE=''; else
  echo "since $(git log -n 1 --format='%h %s' "$BASE")"; RANGE="$BASE..HEAD"; fi
NC=0; [ -z "$RANGE" ] || NC=$(git log --format=%h "$RANGE" -- checks | grep -c . || true)
[ -z "$RANGE" ] || git log --format='commit %h %s' "$RANGE" -- checks
git status --porcelain --untracked-files=all -- checks | awk '{ s = substr($0, 1, 2); gsub(/ /, ".", s); print "uncommitted " s " " substr($0, 4) }'
NU=$(git status --porcelain --untracked-files=all -- checks | grep -c . || true)
echo "local-changes: $NC commit(s) and $NU uncommitted change(s) under checks/ since the last refresh — a refresh overwrites them: carry each over, or drop it on purpose"

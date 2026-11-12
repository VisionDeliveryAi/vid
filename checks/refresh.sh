#!/bin/sh
# Purpose: bring a project's checks/ up to this plugin's, the one refresh of ticket mode (v0.26.10.26.7, R1, W-1). Run as
# the plugin's own copy, sh "${CLAUDE_PLUGIN_ROOT}/checks/refresh.sh", from the project's top level. The project's checks/ is
# current when every file of this plugin's checks/ is in it, byte for byte; files the project adds (its generated cases) are
# never compared, kept and never removed. The records version is not read: it stood still through changes that left an old
# checks/ refusing options the skills now pass. Prints `refresh: current` and exits 0, or, when not current, `stale <path>`
# a line, then local-changes.sh's list of the local edits a copy overwrites. With none listed, or with --yes (the owner's yes
# to that list), it copies the plugin's checks/ over ./checks/ and commits checks/ alone, VID_ROLE=fix, the subject
# `Refresh checks/ to VID <version>` (the form local-changes.sh counts from), and prints `refresh: refreshed <version> <sha>`.
# Exit 3, `refresh: waits for the owner's yes`, when edits are listed and --yes is not given; 2 outside a repository; 4 when the
# commit is refused: checks/ is put back as it was, and current is read against HEAD's checks/, so no later run is fooled.
# Usage: sh refresh.sh [--yes]
# serves: tickets (0.26.10.28.4, M9)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
YES=no; [ "${1:-}" != --yes ] || YES=yes
git rev-parse --git-dir > /dev/null 2>&1 || { echo 'ViD refresh: not inside a repository' >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"
[ "$(cd checks 2>/dev/null && pwd -P || true)" != "$(cd "$HERE" && pwd -P)" ] || { echo 'refresh: current'; exit 0; }
V=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$HERE/../.claude-plugin/plugin.json" 2>/dev/null | head -n 1)
[ -n "$V" ] || V=$(sed -n 's/^records: //p' "$HERE/records-version" | head -n 1 | sed 's/^/records /')
L=$(cd "$HERE" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)
# current means committed: each file compared with HEAD's, so a copy left uncommitted by a refused commit is never read as current
ST=$(printf '%s\n' "$L" | while IFS= read -r f; do [ -n "$f" ] || continue; git show "HEAD:checks/$f" 2>/dev/null | cmp -s "$HERE/$f" - || echo "stale $f"; done)
[ -n "$ST" ] || { echo 'refresh: current'; exit 0; }
printf '%s\n' "$ST"
LC=$(sh "$HERE/local-changes.sh")
printf '%s\n' "$LC"
N=$(printf '%s\n' "$LC" | grep -c -E '^(commit|uncommitted) ' || true)
if [ "$N" -gt 0 ] && [ "$YES" != yes ]; then echo "refresh: waits for the owner's yes — $N local change(s) under checks/ listed above are overwritten"; exit 3; fi
BK=$(mktemp -d); trap 'rm -rf "$BK"' EXIT; [ ! -d checks ] || cp -Rp checks "$BK/checks"   # the tree as it was, for a refused commit
mkdir -p checks
( cd "$HERE" && tar cf - . ) | ( cd checks && tar xf - )
git add -A -- checks
git diff --cached --quiet -- checks && { echo 'refresh: current'; exit 0; }
# the commit template the courts read (8.3, 8.1b): REQs:, Decisions:, Seams:; refused, the copy is unstaged
if ! VID_ROLE=fix git commit -q -m "Refresh checks/ to VID $V" -m "REQs: none
Decisions: none — checks/ copied from the plugin (checks/refresh.sh)
Seams: none" -- checks; then git reset -q -- checks; rm -rf checks; [ ! -d "$BK/checks" ] || cp -Rp "$BK/checks" checks; echo "refresh: the commit was refused (above): checks/ is put back as it was, and nothing is committed"; exit 4; fi
echo "refresh: refreshed $V $(git rev-parse --short HEAD)"

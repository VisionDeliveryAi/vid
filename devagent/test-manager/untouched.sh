#!/bin/sh
# Purpose: the check that the builder touched no test (v0.26.10.24.2 R3), beside run.sh. For every file a `Role: TA` or
# `Role: TM` commit reachable from the head touched, it compares the file at the head with the file at the newest such
# commit that touched it, and names each that differs or is gone. So a slip put right passes again, with no history
# rewritten. It is for honest slips, nothing more.
#   untouched.sh <clone> <head>
# Exit: 0 none named; 1 one or more named, one line each; 2 no such clone or commit.
# serves: dev side (0.26.10.28.4, M9)
set -eu
die() { echo "untouched.sh: $*" >&2; exit 2; }
[ $# -eq 2 ] || die 'usage: untouched.sh <clone> <head>'
C=$1; H=$(git -C "$C" rev-parse -q --verify "$2^{commit}" 2> /dev/null) || die "no commit $2 in $C"
L=$(mktemp); trap 'rm -f "$L"' EXIT
# newest first, so each path keeps the newest such commit that touched it
git -C "$C" -c core.quotePath=false log --topo-order --no-renames --name-only --format=%x01%H --grep='^Role: T[AM]$' "$H" |
  awk 'substr($0, 1, 1) == "\001" { c = substr($0, 2); next } NF && !s[$0]++ { print c "\t" $0 }' > "$L"
TAB=$(printf '\t'); bad=0
while IFS=$TAB read -r c f; do
  a=$(git -C "$C" ls-tree "$c" -- "$f"); b=$(git -C "$C" ls-tree "$H" -- "$f")
  [ "$a" != "$b" ] || continue; bad=$((bad + 1)); w=changed; [ -n "$b" ] || w=gone
  echo "$w: $f, left at $(printf %s "$c" | cut -c1-12)"
done < "$L"
n=$(($(wc -l < "$L"))); echo "untouched: $((n - bad)) of $n files as the test author and test manager left them"
[ "$bad" -eq 0 ]

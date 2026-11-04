#!/bin/sh
# Purpose: the row-review pass's output checker (v0.26.10.12.2 R6) — deterministic, judging one
# fresh pass's output against a calibration fixture. `sh pass-check.sh <fixture dir> <output file>`: the output's
# `finding <row id> | <why>` lines must name exactly the row ids of the fixture's expected.md `expect:` line (`none`:
# no finding, and the output says `none`). Any other line, an empty output, a missing or an extra finding convicts
# (exit 1, the reason on stderr); a match acquits (exit 0).
set -eu
FX=${1:-}; OUT=${2:-}
[ -f "$FX/expected.md" ] && [ -f "$OUT" ] || { echo 'pass-check: usage — sh pass-check.sh <fixture dir> <output file>' >&2; exit 2; }
EXP=$(sed -n 's/^expect: //p' "$FX/expected.md" | head -n 1 | tr ' ' '\n' | grep -v '^none$' | LC_ALL=C sort -u | tr '\n' ' ')
GOT=$(awk '{ l = $0; gsub(/^[ \t]+|[ \t]+$/, "", l) } l == "" { next } l == "none" { said = 1; next }
  l ~ /^finding [^ |]+[ \t]*\|[ \t]*[^ \t]/ { sub(/^finding /, "", l); sub(/[ \t]*\|.*/, "", l); print l; said = 1; next }
  { print "BAD"; said = 1 } END { if (!said) print "EMPTY" }' "$OUT" | LC_ALL=C sort -u | tr '\n' ' ')
case " $GOT " in *' BAD '*) echo 'pass-check: a line is neither a finding nor none' >&2; exit 1 ;; *' EMPTY '*) echo 'pass-check: the output is empty — no verdict' >&2; exit 1 ;; esac
[ "$GOT" = "$EXP" ] || { echo "pass-check: expected [${EXP% }], got [${GOT% }]" >&2; exit 1; }
echo "pass-check: $(basename "$FX") acquits — [${EXP% }]"

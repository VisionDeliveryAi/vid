#!/bin/sh
# Purpose: the fixture runner for the journey batch (v0.9.2 3.5 — a TOY, never
# installed). Runs one test file and prints the results reader's own line per
# case — for a journey one case PER TRANSITION. What a test file declares:
#   journey_rows                     → `<row> <actor> <transitions>` per journey row it pays
#   journey_<row>_setup              → (the row id with `-` as `_`: journey_ROW_010_setup) reaches the starting state (the API door and fixtures are legal
#                                      here; a transition is not)
#   journey_<row>_transition_<k>     → operates transition k's entry control through the ENGINE door
#                                      and asserts its observable effect (harness_assert)
#   behavior_rows                    → `<row> <actor>` per behavior row it pays
#   case_<row>                       → the behavior case (the API door)
# The log ($HARNESS_LOG) carries `transition <row> <k> begin|end` around each
# step — the return checker reads which door each step used.
# Usage: sh run.sh <test-file>
set -u
TEST=${1:?test file}; HERE=$(cd "$(dirname "$0")" && pwd)
: "${HARNESS_LOG:=$(mktemp)}"; export HARNESS_LOG; : > "$HARNESS_LOG"
HARNESS_STATE=$(mktemp -d); export HARNESS_STATE; trap 'rm -rf "$HARNESS_STATE"' EXIT
. "$HERE/harness.sh"; . "$TEST"
FILE=tests/invariants/$(basename "$TEST"); ANY=0
r() { case "$1" in 0) echo "case $FILE::$2 passed 0" ;; *) echo "case $FILE::$2 failed 0"; echo "  $2: $3" >&2; ANY=1 ;; esac; }
if command -v journey_rows >/dev/null 2>&1; then
  journey_rows | while read -r row actor n; do
    [ -n "$row" ] || continue
    harness_reset; harness_actor alpha "$actor" >/dev/null 2>&1; fn=$(printf '%s' "$row" | tr '-' '_')
    CASE_FAIL=''; if command -v "journey_${fn}_setup" >/dev/null 2>&1; then "journey_${fn}_setup" alpha "$actor" || true; fi
    k=1; while [ "$k" -le "$n" ]; do
      CASE_FAIL=''; printf 'transition %s %s begin\n' "$row" "$k" >> "$HARNESS_LOG"
      if command -v "journey_${fn}_transition_$k" >/dev/null 2>&1; then "journey_${fn}_transition_$k" alpha "$actor" || CASE_FAIL="${CASE_FAIL:-the step returned non-zero}"; else CASE_FAIL="no step declared for transition $k"; fi
      printf 'transition %s %s end\n' "$row" "$k" >> "$HARNESS_LOG"
      if [ -z "$CASE_FAIL" ]; then r 0 "$row[transition=$k/$n]"; else r 1 "$row[transition=$k/$n]" "$CASE_FAIL"; echo "$row $k" >> "$HARNESS_LOG.fail"; fi
      k=$((k + 1))
    done
  done
fi
if command -v behavior_rows >/dev/null 2>&1; then
  behavior_rows | while read -r row actor; do
    [ -n "$row" ] || continue
    harness_reset; harness_actor alpha "$actor" >/dev/null 2>&1; CASE_FAIL=''; fn=$(printf '%s' "$row" | tr '-' '_')
    if command -v "case_$fn" >/dev/null 2>&1; then "case_$fn" alpha "$actor" || CASE_FAIL="${CASE_FAIL:-the case returned non-zero}"; else CASE_FAIL='no case declared'; fi
    if [ -z "$CASE_FAIL" ]; then r 0 "$row"; else r 1 "$row" "$CASE_FAIL"; echo "$row" >> "$HARNESS_LOG.fail"; fi
  done
fi
[ -f "$HARNESS_LOG.fail" ] && { rm -f "$HARNESS_LOG.fail"; exit 1; }
exit 0

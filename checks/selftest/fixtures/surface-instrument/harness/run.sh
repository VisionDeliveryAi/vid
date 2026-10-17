#!/bin/sh
# Purpose: the fixture runner (v0.9.2 3.4 — a TOY, never installed): collects
# and runs one surface instrument against one scaffold and prints, per row ×
# engine, the results reader's own line — `case <file>::<row>[<engine>]
# <passed|failed> <seconds>` — with every failure's reason on stderr, one
# line per case, naming the row. What an instrument declares (the contract
# the pass writes to):
#   surface_rows                    → its row table: `<row> <marker/state> <actor> <route> <fixture|->` per
#                                     line (the fixture is one harness_fixture names; `-` for the default)
#   surface_literals MARKER STATE   → the state's literal set, the lines measure_state takes on stdin —
#                                     carried inside the file, read off the canvases at production time;
#                                     the rendered extractor (rendered.toy.sh) reads the same set through it
#   surface_case ROW ENGINE         → the case body: the actor door, ONE load through measure_state,
#                                     the assertions, then harness_run_hook pins_<marker>_<state>
#   pins_<marker>_<state>           → the row's pins hook (marker and state with `-` and `/` as `_`)
# Usage: sh run.sh <instrument> <scaffold-dir> [base-scaffold-dir]
#   HARNESS_LOG   where navigations and hook counts are recorded (default: <scaffold>/../harness.log)
#   TOY_EMPTY_HOOK=<name>  redeclares that hook empty after the instrument loads (the checker's probe)
set -u
INSTR=${1:?instrument}; SCAFFOLD=${2:?scaffold dir}; SCAFFOLD_BASE=${3:-}
export SCAFFOLD SCAFFOLD_BASE
HERE=$(cd "$(dirname "$0")" && pwd)
export HARNESS_ROOT="$HERE"
: "${HARNESS_LOG:=$(mktemp)}"; export HARNESS_LOG
: > "$HARNESS_LOG"
ERR=$(mktemp); trap 'rm -f "$ERR"' EXIT
. "$HERE/harness.sh"
. "$HERE/measure.sh"
. "$INSTR"
if [ -n "${TOY_EMPTY_HOOK:-}" ]; then eval "$TOY_EMPTY_HOOK() { :; }"; fi
command -v surface_rows >/dev/null 2>&1 || { echo 'run: the instrument declares no surface_rows' >&2; exit 2; }
command -v surface_case >/dev/null 2>&1 || { echo 'run: the instrument declares no surface_case' >&2; exit 2; }
command -v surface_literals >/dev/null 2>&1 || { echo 'run: the instrument declares no surface_literals' >&2; exit 2; }
FILE=tests/invariants/surfaces.sh
ANY=0
for row in $(surface_rows | awk '{print $1}'); do
  for eng in $(harness_engines); do
    CASE_FAIL=''; PINS_ASSERTS=0; HARNESS_FIXTURE=-
    start=$(date +%s)
    surface_case "$row" "$eng" 2>>"$ERR" || CASE_FAIL="${CASE_FAIL:-the case body returned non-zero}"
    end=$(date +%s)
    if [ -z "$CASE_FAIL" ]; then echo "case $FILE::$row[$eng] passed $((end - start))"
    else echo "case $FILE::$row[$eng] failed $((end - start))"; echo "  $row [$eng]: $CASE_FAIL" >&2; ANY=1; fi
  done
done
exit $ANY

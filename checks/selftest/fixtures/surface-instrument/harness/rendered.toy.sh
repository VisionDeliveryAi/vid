#!/bin/sh
# Purpose: the fixture's rendered extractor (report-only class) — the second
# reader of the ONE measure module: it enumerates the surface rows, hands
# each state to measure_state and prints its `differs` lines as orphans in
# the rendered class's subject form (`<marker>/<state>/<identifier>:<property>`);
# it compares nothing itself. Usage: sh rendered.toy.sh <instrument> <scaffold>
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
export HARNESS_ROOT="$HERE" SCAFFOLD="${2:?scaffold}" SCAFFOLD_BASE="${3:-}" HARNESS_LOG="${HARNESS_LOG:-/dev/null}"
. "$HERE/harness.sh"
. "$HERE/measure.sh"
. "${1:?instrument}"
n=0
for row in $(surface_rows | awk '{print $1}'); do
  set -- $(surface_rows | awk -v r="$row" '$1 == r')
  ms=$2; actor=$3; route=$4; fx=$5; m=${ms%%/*}; s=${ms#*/}
  harness_fixture "$fx"
  lits=$(surface_literals "$m" "$s" 2>/dev/null) || lits=''
  printf '%s\n' "$lits" | measure_state alpha "$actor" "$route" "$m" "$s" | awk -v row="$row" '
    /^ok / { print "ok " $2; n++ }
    /^differs / { sub(/^differs /, ""); subj = $1; $1 = ""; print "orphan " subj " " substr($0, 2) " (" row ")"; n++ }
    END { if (n == 0) print "inactive nothing measured for " row }'
done

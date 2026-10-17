#!/bin/sh
# Purpose: selftest case — extractors that finish in reverse order are
# judged in sorted order (v0.9.6 spec 3.14, R14; §7 case 4). Four stub
# extractors whose sleeps make the last-sorted finish first: with
# VID_COURT_JOBS=4 their `census <name>:` lines print in sorted order, each
# with its own counts, and the run takes less time than the sum of the
# sleeps (they did run side by side). census-rendered.sh keeps its
# verdicts under the default, parallel run. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors
n=3
for e in a b c d; do
  printf '#!/bin/sh\n# Purpose: stub extractor\nsleep %s\necho "ok %s1"\n' "$n" "$e" > "checks/extractors/invariant.$e.sh"
  n=$((n - 1))
done
S=$(date +%s)
OUT=$(VID_COURT_JOBS=4 sh "$CHECKS/census.sh")
E=$(( $(date +%s) - S ))
[ "$(printf '%s\n' "$OUT" | sed -n 's/^census \(invariant\.[a-d]\): population=1 ok=1 .*/\1/p' | tr '\n' ' ')" = 'invariant.a invariant.b invariant.c invariant.d ' ] || { echo 'census-parallel-order: not replayed in sorted order' >&2; printf '%s\n' "$OUT" >&2; exit 1; }
[ "$E" -lt 6 ] || { echo "census-parallel-order: $E s — the extractors did not run side by side" >&2; exit 1; }
sh "$CHECKS/selftest/cases/census-rendered.sh" || { echo 'census-parallel-order: census-rendered.sh changed its verdict under the parallel census' >&2; exit 1; }
exit 0

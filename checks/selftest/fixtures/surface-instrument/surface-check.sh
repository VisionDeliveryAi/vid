#!/bin/sh
# Purpose: the surface instrument's checker (v0.9.2 3.4; spec §5 Phase B's
# cut line, §7.6, §7.11) — the court tradition applied to the surface
# test-author pass. Runs ONE instrument through the fixture's scaffolds on
# the toy harness and judges what the spec names: one file whose cases are
# the rows × the engines, each case naming its row; the stray control
# failing its row; navigations = states × engines; every case collected
# and failing on the empty scaffold (no deferral); an emptied pins hook
# failing `pins not authored`; the three-column grid named by identifier
# and property; `missing element` by name; an identifier the canvas lacks
# under the stray rule; a colour in another notation and a length in
# another unit comparing equal; a load-bearing value painted differently
# failing the row; 0.9.1's own pin example (card count = page size; sort
# control present; salary shown when the record carries one) failing on
# the wrong-count page and the salary-less render and passing on the
# correct one; a console error and a missing marker failing; the rendered
# extractor and the instrument reading one measure module. Deterministic;
# the instrument is a fresh pass's work (protocol: the vid-test-inventory
# skill's selftest/README.md) or the fixture's reference. One line per
# expectation, counts never scores.
# Usage: sh surface-check.sh <instrument> [fixture-dir]
set -u
INSTR=${1:?instrument file}
FIX=${2:-$(cd "$(dirname "$0")" && pwd)}
[ -f "$INSTR" ] || { echo "surface-check: $INSTR missing" >&2; exit 1; }
H="$FIX/harness"; SC="$FIX/scaffolds"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
N=0; FAILS=0
expect() { N=$((N + 1)); if [ "$2" = 0 ]; then echo "ok    $1"; else echo "FAIL  $1"; FAILS=$((FAILS + 1)); fi; }
run() { # run NAME SCAFFOLD [BASE]  → $OUT (cases + reasons), $LOG
  LOG="$T/$1.log"; OUT="$T/$1.out"
  (cd "$FIX" && HARNESS_LOG="$LOG" DESIGN_TOKENS="$FIX/design/tokens.css" sh "$H/run.sh" "$INSTR" "$2" "${3:-}") > "$OUT" 2>&1 || true
}
passed() { grep -c "::$1\[[a-z]*\] passed" "$OUT" | tr -d ' '; }
failed() { grep -c "::$1\[[a-z]*\] failed" "$OUT" | tr -d ' '; }
names()  { grep -q "$1" "$OUT"; }

# --- the file itself
expect 'one file: declares surface_rows, surface_literals, surface_case and a pins hook per surface row' "$( { grep -q 'surface_rows' "$INSTR" && grep -q 'surface_literals' "$INSTR" && grep -q 'surface_case' "$INSTR" && grep -q 'pins_P01_default' "$INSTR" && grep -q 'pins_P01_empty' "$INSTR" && grep -q 'pins_P02_default' "$INSTR"; } && echo 0 || echo 1)"
expect 'one module: the instrument reads the page through measure_state and nothing else loads a page' "$( { grep -q 'measure_state' "$INSTR" && ! grep -q 'harness_load' "$INSTR"; } && echo 0 || echo 1)"

# --- correct scaffold: every case passes, one navigation per state per engine, every hook asserts
run correct "$SC/correct"
expect 'correct: 6 cases collected (3 rows × 2 engines), each naming its row, all passed' "$( [ "$(passed ROW-002)" = 2 ] && [ "$(passed ROW-003)" = 2 ] && [ "$(passed ROW-004)" = 2 ] && [ "$(grep -c '^case ' "$OUT")" = 6 ] && echo 0 || echo 1)"
expect 'correct: navigations = states × engines (6)' "$( [ "$(grep -c '^navigate ' "$LOG")" = 6 ] && echo 0 || echo 1)"
expect 'correct: every pins hook asserted at least once, in each engine (6 hook runs)' "$( [ "$(grep -c '^hook pins_.* assertions=[1-9]' "$LOG")" = 6 ] && echo 0 || echo 1)"
expect 'correct: 0.9.1 pin example passes on the correct page (ROW-004 both engines)' "$( [ "$(passed ROW-004)" = 2 ] && echo 0 || echo 1)"

# --- the stray control: the empty state draws a sibling state's control
run stray "$SC/stray" "$SC/correct"
expect 'stray control: ROW-003 fails in both engines naming stray P01/empty; the other rows pass' "$( [ "$(failed ROW-003)" = 2 ] && names 'stray P01/empty search-action' && [ "$(passed ROW-002)" = 2 ] && [ "$(passed ROW-004)" = 2 ] && echo 0 || echo 1)"

# --- the empty scaffold: every case collected and failing, no deferral
run empty "$SC/empty"
expect 'empty scaffold: all 6 cases collected and failed, none skipped or owed' "$( [ "$(grep -c '^case .* failed' "$OUT")" = 6 ] && [ "$(grep -c '^case ' "$OUT")" = 6 ] && ! grep -qiE 'skip|owed' "$OUT" && echo 0 || echo 1)"
expect 'empty scaffold: each failure names the missing route or marker' "$( [ "$(grep -cE 'missing marker|404' "$OUT")" -ge 6 ] && echo 0 || echo 1)"

# --- an emptied pins hook fails its case
LOG="$T/eh.log"; OUT="$T/eh.out"
(cd "$FIX" && TOY_EMPTY_HOOK=pins_P02_default HARNESS_LOG="$LOG" DESIGN_TOKENS="$FIX/design/tokens.css" sh "$H/run.sh" "$INSTR" "$SC/correct") > "$OUT" 2>&1 || true
expect 'empty hook: ROW-004 fails in both engines with pins not authored; the other rows pass' "$( [ "$(failed ROW-004)" = 2 ] && names 'pins not authored' && [ "$(passed ROW-002)" = 2 ] && [ "$(passed ROW-003)" = 2 ] && echo 0 || echo 1)"

# --- identifiers (R20)
run grid "$SC/grid-columns" "$SC/correct"
expect 'three-column grid drawn two: ROW-002 fails naming featured-grid and grid-template-columns' "$( [ "$(failed ROW-002)" = 2 ] && names 'featured-grid:grid-template-columns' && [ "$(passed ROW-003)" = 2 ] && echo 0 || echo 1)"
run missing "$SC/missing-element" "$SC/correct"
expect 'canvas element absent from the page: ROW-002 fails with missing element P01/default/featured-grid' "$( [ "$(failed ROW-002)" = 2 ] && names 'missing element P01/default/featured-grid' && echo 0 || echo 1)"
run extra "$SC/extra-identifier" "$SC/correct"
expect 'page identifier the canvas lacks: ROW-002 fails under the stray rule naming promo-banner' "$( [ "$(failed ROW-002)" = 2 ] && names 'stray P01/default promo-banner' && echo 0 || echo 1)"
run units "$SC/units-notation" "$SC/correct"
expect 'colours in another notation and lengths in another unit compare equal: all 6 pass' "$( [ "$(grep -c '^case .* passed' "$OUT")" = 6 ] && echo 0 || echo 1)"
run paint "$SC/wrong-paint" "$SC/correct"
expect 'a load-bearing value painted differently: ROW-002 fails naming search-action:background-color' "$( [ "$(failed ROW-002)" = 2 ] && names 'search-action:background-color' && echo 0 || echo 1)"

# --- the pins hook on 0.9.1's own example
run count "$SC/wrong-count" "$SC/correct"
expect 'wrong-count page: ROW-004 fails its hook in both engines; the other rows pass' "$( [ "$(failed ROW-004)" = 2 ] && [ "$(passed ROW-002)" = 2 ] && [ "$(passed ROW-003)" = 2 ] && echo 0 || echo 1)"
run salary "$SC/no-salary" "$SC/correct"
expect 'salary-less render of a record carrying one: ROW-004 fails its hook in both engines' "$( [ "$(failed ROW-004)" = 2 ] && echo 0 || echo 1)"

# --- a console error and a missing marker are failing cases
run console "$SC/console-error" "$SC/correct"
expect 'console error: ROW-002 fails naming it' "$( [ "$(failed ROW-002)" = 2 ] && names 'console error' && echo 0 || echo 1)"
run marker "$SC/missing-marker" "$SC/correct"
expect 'missing marker: ROW-004 fails naming it' "$( [ "$(failed ROW-004)" = 2 ] && names 'missing marker P02/default' && echo 0 || echo 1)"

# --- one comparison, two readers: the rendered extractor's orphan is the instrument's differs
EXT=$(cd "$FIX" && DESIGN_TOKENS="$FIX/design/tokens.css" sh "$H/rendered.toy.sh" "$INSTR" "$SC/grid-columns" "$SC/correct" 2>/dev/null | grep '^orphan' || true)
expect 'the rendered extractor reports the same subject through the same module (one comparison, two readers)' "$( printf '%s\n' "$EXT" | grep -q '^orphan P01/default/featured-grid:grid-template-columns' && grep -q 'measure.sh' "$H/rendered.toy.sh" && echo 0 || echo 1)"

echo "surface-check: expectations=$N failed=$FAILS"
[ "$FAILS" -eq 0 ] || { echo "surface-check: the instrument missed $FAILS expectation(s)." >&2; exit 1; }
exit 0

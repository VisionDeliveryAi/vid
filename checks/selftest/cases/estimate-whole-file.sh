#!/bin/sh
# Purpose: selftest case — a whole-file selection's estimate sums the file's recorded cases (v0.9.8.1 R26, F-15).
# Kept receipts at the home: an inline one with t.py's three cases (10, 200, 300 s; start-up 30 s) and a deployed one
# with two (40, 60 s). Under a harness declaring deployed-selector:, an iterate for ROW-001 (10 s of its own) selecting
# the file inline and in the deployed pass is estimated on 610 s of cases, from the selection's files (510 inline +
# 100 deployed), not 2 × 10; inline only, 510 s; a selection naming only ROW-001's test id keeps the rows' figure; and
# --expect still wins. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/estimate-files.sh"
fail() { echo "estimate-whole-file: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"
printf '%s' "$COMPOSEFILE" | awk '{ print } /^x-vid-harness:/ { print "  deployed-selector: -m deployed" }' > docker-compose.test.yml
g add -A && g commit -qm 'a deployed selector'; gate_on
F=tests/invariants/t.py
ef_hist d1 deployed 130 "$F::test_a[ROW-001]=40" "$F::test_d=60"
ef_hist h1 inline 540 "$F::test_a[ROW-001]=10" "$F::test_b=200" "$F::test_c=300"
touch "$T/hold"; export STUB_HOLD="$T/hold"
ef_req 'the file, both passes' -- "$F" --deployed-selection "$F"
grep -q "^estimate [0-9]*s (start-up 2 × [0-9]*s + cases 610s, from the selection's files) " "$T/out" || fail "both passes are not estimated on the file's cases: $(grep '^estimate' "$T/out")"
ef_req 'the file inline' -- "$F" --deployed-selection tests/invariants/other.py
grep -q "^estimate [0-9]*s (start-up 2 × [0-9]*s + cases 510s, from the selection's files) " "$T/out" || fail "the inline pass is not estimated on the file's inline cases: $(grep '^estimate' "$T/out")"
ef_req 'one test id' -- "$F::test_a[ROW-001]" --deployed-selection "$F::test_a[ROW-001]"
grep -q "^estimate [0-9]*s (start-up 2 × [0-9]*s + cases 2 × 10s) " "$T/out" || fail "a test-id selection did not keep the rows' figure: $(grep '^estimate' "$T/out")"
ef_req 'expected' --expect 77 -- "$F" --deployed-selection "$F"
grep -q "^estimate [0-9]*s (start-up 2 × [0-9]*s + cases 2 × 77s, from --expect) " "$T/out" || fail "--expect did not win: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
exit 0

#!/bin/sh
# Purpose: selftest case — 0.26.10.29.6 (S6): a missing priority mark is seen when the answer is written. From the
# 0.9.4 known-good fixture, three human answers that shape a must-never-break rule lose or lack `importance: priority`
# (A-006 settles T0 INV-001 and loses its mark; A-001 and A-002 are made to settle T0 INV-001 and INV-002). An
# ordinary run (no --pause) prints exactly three importance notes, one for each of the three answers, and exits 0:
# a note refuses nothing, so the pre-commit hook's plain run lets the commit through. Under --pause the same three
# are gaps, as before. The known-good fixture prints no importance note. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-priority-notes: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
cp "$FIXTURES/prd-094-good.md" G.md
run G.md; [ "$RC" -eq 0 ] || fail 'the known-good fixture convicted'
[ "$(printf '%s\n' "$OUT" | grep -c '^NOTE  importance (' || true)" = 0 ] || fail 'the known-good fixture printed an importance note'
sed -e 's/^\(A-006 | human | .*| settles: INV-001\) | importance: priority$/\1/' \
    -e 's/^\(A-001 | human | .*| settles: REQ-001\)$/\1, INV-001/' \
    -e 's/^\(A-002 | human | .*| settles: REQ-003, MECH-02\)$/\1, INV-002/' G.md > M.md
grep -q '^A-006 .*| settles: INV-001$' M.md && grep -q '^A-001 .*| settles: REQ-001, INV-001$' M.md \
  && grep -q '^A-002 .*| settles: REQ-003, MECH-02, INV-002$' M.md || fail 'the three plants did not apply'
run M.md
[ "$RC" -eq 0 ] || { printf '%s\n' "$OUT" | grep '^GAP' | head -3 >&2 || true; fail "an ordinary run refused (exit $RC): a missing mark is a note there"; }
N=$(printf '%s\n' "$OUT" | grep -c '^NOTE  importance (' || true)
[ "$N" = 3 ] || { printf '%s\n' "$OUT" | grep '^NOTE' >&2 || true; fail "an ordinary run printed $N importance notes, not 3"; }
for a in 'A-001): .*settles T0 INV-001' 'A-002): .*settles T0 INV-002' 'A-006): .*settles T0 INV-001'; do
  printf '%s\n' "$OUT" | grep -q "^NOTE  importance ($a" || fail "no note for $a"; done
run M.md --pause
[ "$RC" -ne 0 ] || fail 'the pause acquitted three missing marks'
[ "$(printf '%s\n' "$OUT" | grep -c '^GAP  importance (' || true)" = 3 ] || fail 'the pause did not convict the three'
exit 0

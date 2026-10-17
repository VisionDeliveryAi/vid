#!/bin/sh
# Purpose: selftest case — no move into hardening under another label (v0.9.7.2 spec 3.2, R3). Under breadth first,
# the same move of ROW-008 into H1 as a split, a rows change or other is refused, naming the row and the edge
# command; the decision is recorded refused and no plan-change is written. The rows newly in hardening are worked out
# against the last recorded plan, whatever the label. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "edge-via-split-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
N0=$(grep -c '^plan-change' .vid/metrics-events)
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-007' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-008..ROW-012 | kind: hardening'
for w in split rows other; do
  if chg "$w" 'a quiet move' > "$T/out" 2>&1; then fail "a $w change moved a row into hardening"; fi
  grep -q "this $w change places rows in a hardening step: ROW-008" "$T/out" || fail "the $w refusal does not name the row"
  grep -q 'change edge' "$T/out" || fail 'the refusal does not name the edge change'
done
[ "$(grep -c '^plan-change' .vid/metrics-events)" -eq "$N0" ] || fail 'a refused move was recorded'
[ "$(grep -l '^result=refused' .vid/plans/decisions/*.why | wc -l | tr -d ' ')" -eq 3 ] || fail 'the refusals were not kept as decisions'
exit 0

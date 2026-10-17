#!/bin/sh
# Purpose: selftest case — the graded gate (v0.9.7.2 spec 3.5, R7; the owner's option b). Under breadth first S2
# (building on S1) is refused while S1 is not closed, then while S1 is closed but not graded — naming the ungraded
# rows, `S1 is closed, not graded: 2 rows (ROW-003 ROW-004)` — each refusal recorded `refused … by=graded`; a
# breach doesn't hold the gate (ROW-004 BREACHED product counts as graded); once every row is graded, S2 is admitted.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "admit-needs-graded: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
sh checks/plan.sh start S1 > /dev/null
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'S2 was admitted before S1 closed'; fi
grep -q 'S1 is not closed: never closed' "$T/out" || fail 'the refusal does not say S1 never closed'
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null
keepall ROW-001 ROW-002
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'S2 was admitted with S1 ungraded'; fi
grep -q 'S1 is closed, not graded: 2 rows (ROW-003 ROW-004)' "$T/out" || fail 'the refusal does not name the ungraded rows'
[ "$(grep -c '^refused phase=admission by=graded .* step=S2 ' .vid/metrics-events)" -eq 2 ] || fail 'the refusals were not recorded by=graded'
verdict ROW-003 KEPT; verdict ROW-004 BREACHED product
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'a breach held the gate'
exit 0

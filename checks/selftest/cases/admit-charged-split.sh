#!/bin/sh
# Purpose: selftest case — the gate covers every admission (v0.9.7.2 spec 3.5, R7). S2 started while S1 was graded;
# then a row added to S1 is ungraded. Splitting S2's charged rows into a new step S4 (building on S1) makes a step of
# already-charged rows — under breadth first it is refused by the gate all the same; under depth first it is
# admitted without either rule, as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "admit-charged-split: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null
sh checks/plan.sh start S2 > /dev/null || fail 'S2 was refused with S1 graded'
rcpt r1 HEAD inline ROW-009=passed
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 ROW-009' "$S2L"
chg rows 'ROW-009 joins S1' > "$T/out" 2>&1 || fail 'the row was not added to S1'
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-009=passed > /dev/null || fail 'S1 did not close again'
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 ROW-009' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005 ROW-006' 'step S4 | name: fourth | modules: app/s2 | builds-on: S1 | rows: ROW-007 ROW-008'
chg split 'S2 in two' > "$T/out" 2>&1 || fail 'the split was refused'
if sh checks/plan.sh start S4 > "$T/out" 2>&1; then fail 'a step of charged rows passed the gate'; fi
grep -q 'S1 is closed, not graded: 1 rows (ROW-009)' "$T/out" || fail 'the refusal does not name ROW-009'
sh checks/plan.sh strategy depth-first --by owner --words 'depth' > /dev/null
sh checks/plan.sh start S4 > "$T/out" 2>&1 || fail 'under depth first the charged split was refused'
grep -q 'its rows all belonged to a started step, so neither rule applies' "$T/out" || fail 'the depth-first admission changed'
exit 0

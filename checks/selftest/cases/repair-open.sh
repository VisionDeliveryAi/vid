#!/bin/sh
# Purpose: selftest case — started steps keep their repair access (v0.9.7.2 spec 3.5, R7). S2 started under the gate;
# S1 then gains an ungraded row. S2's own work is never refused: `start S2` again and a fixer brief's admission for S2
# are admitted ("already started"), and nothing is recorded by=graded for them. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "repair-open: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null
sh checks/plan.sh start S2 > /dev/null || fail 'S2 was refused'
echo z >> app/s1/main.py; commit_all 'amend ROW-001'
printf 'amended row=ROW-001 sha=%s at=%s\n' "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events
ss S1 > "$T/out"; grep -q '^ungraded step=S1 row=ROW-001' "$T/out" || fail 'the amended row is not ungraded'
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'the started step was refused'
grep -q 'S2 already started — admitted' "$T/out" || fail 'not admitted as started'
brief .vid/briefs/1/fixer-1.md fixer S2 ROW-005
sh checks/plan.sh admit --brief .vid/briefs/1/fixer-1.md > "$T/out" 2>&1 || fail "a fixer brief for the started step was refused"
grep -q 'by=graded' .vid/metrics-events && fail 'a repair was recorded as a gate refusal'
exit 0

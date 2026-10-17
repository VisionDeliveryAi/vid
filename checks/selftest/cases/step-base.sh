#!/bin/sh
# Purpose: selftest case — a step's start commit (v0.9.6.1 spec 3.5, R5; §6
# case 4). In a toy develop run under a 0.9.6 plan, `plan.sh start S1`
# writes `step-start step=S1 plan=<hash> base=<HEAD>` and `plan.sh base S1`
# names it from=step-start. A step started before 0.9.6.1 (a step-start
# with no base=) falls back to the quoted-at of its first builder brief
# (from=brief) — not HEAD, and not a later brief's; with no brief, to the
# commit HEAD was on at its start time (from=step-start-time); a step never
# started is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "step-base: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004' \
  'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
H0=$(git rev-parse --short=12 HEAD); PH=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1)
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused'
grep -qE "^step-start step=S1 plan=$PH base=$H0 at=" .vid/metrics-events || fail 'the step-start does not carry base=<HEAD>'
[ "$(sh checks/plan.sh base S1)" = "base step=S1 commit=$H0 from=step-start" ] || fail "S1's base: $(sh checks/plan.sh base S1)"
# a step started before 0.9.6.1: its first builder brief's quoted-at
brief .vid/briefs/1/builder-1.md builder S2 ROW-003 ROW-004
printf 'brief-check path=.vid/briefs/1/builder-1.md result=ok at=%s\n' "$(utcnow)" >> .vid/metrics-events
printf 'step-start step=S2 plan=%s at=%s\n' "$PH" "$(utcnow)" >> .vid/metrics-events
printf 'later\n' >> app/s2/main.py; commit_all 'S2 work'; H1=$(git rev-parse --short=12 HEAD)
sleep 1; brief .vid/briefs/2/builder-2.md builder S2 ROW-003 ROW-004
printf 'brief-check path=.vid/briefs/2/builder-2.md result=ok at=%s\n' "$(utcnow)" >> .vid/metrics-events
[ "$(sh checks/plan.sh base S2)" = "base step=S2 commit=$H0 from=brief" ] || fail "S2's base is not its first brief's quoted-at: $(sh checks/plan.sh base S2)"
# no brief: the commit at its start time
printf 'step-start step=S3 plan=%s at=%s\n' "$PH" "$(utcnow)" >> .vid/metrics-events
[ "$(sh checks/plan.sh base S3)" = "base step=S3 commit=$H1 from=step-start-time" ] || fail "S3's base: $(sh checks/plan.sh base S3)"
if sh checks/plan.sh base S9 > "$T/out" 2>&1; then fail 'a step never started has a base'; fi
grep -q 'never started' "$T/out" || fail 'the refusal does not say the step never started'
exit 0

#!/bin/sh
# Purpose: selftest case — the plan check before a request is accepted
# (v0.9.7.0.2 spec 3.1, R6; §6 C-3). Inside a live run: a row of a step not
# yet started (no step-start) is refused for `iterate`, naming the step,
# and accepted for `full`; a row the plan does not hold is accepted (a new
# row's first proof); an empty row list is refused; a row of a started
# step is accepted. Nothing is made for a refused request. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "request-plan-check: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null || fail 'S1 did not start'
ask() { sh checks/test.sh request "$@" > "$T/out" 2>&1; }
nreq() { ls .vid/requests 2>/dev/null | grep -c . || true; }
if ask --type iterate --role builder --try t1 --rows ROW-003 --why 'a row of S2' -- tests/x; then fail 'a row of an unstarted step was accepted for iterate'; fi
grep -q 'ROW-003 (step S2)' "$T/out" || fail 'the refusal does not name the row and its step'
[ "$(nreq)" -eq 0 ] || fail 'a refused request made a ticket'
if ask --type iterate --role builder --try t1 --rows '' --why 'no rows' -- tests/x; then fail 'an empty row list was accepted'; fi
grep -q 'names no row' "$T/out" || fail 'the empty refusal does not say so'
ask --type iterate --role builder --try t1 --rows ROW-001 --why 'a row of S1' -- tests/x || fail 'a row of a started step was refused'
ask --type iterate --role test-author --rows ROW-099 --why 'a new row, not yet in the plan' -- tests/x || fail 'a row the plan does not hold was refused'
ask --type full --role orchestrator --why 'the whole ledger, S2 included' || fail 'a full request was refused for an unstarted step'
for k in $(ls .vid/requests); do VID_WAIT_MAX=60 sh checks/test.sh wait "$k" > "$T/out" 2>&1 || true; done
exit 0

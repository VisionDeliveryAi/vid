#!/bin/sh
# Purpose: selftest case — the observer's progress update (v0.9.6 spec
# 3.15, R15; §7 case 34). A toy develop run under a 0.9.6 plan, observed
# tick by tick (`tick --now`): the first tick records the update and its
# headline as one notice line; the next tick is silent; a plan change makes
# one update and one notice (trigger=plan-change); 3,600 s after the last
# update, one more (trigger=hourly), and a notice is never repeated.
# v0.9.7.0.9 (3.8, R13): the notice is an `observe: notice — ViD progress —
# …` heartbeat line, nothing is sent, and there is no pending send. Every
# update is `progress … by=observer`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-trigger: $*" >&2; cat "$T/tick" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/progress.sh" checks/
printf '# Heartbeat\n- %s | note: working\n' "$(utcnow)" > .vid/HEARTBEAT.md
plan 'step S1 | name: tenants | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
tick() { VID_OBSERVE_ONE=1 sh checks/observe.sh tick --now > "$T/tick" 2>&1 || true; }
np() { grep -c '^progress .* by=observer ' .vid/metrics-events || true; }
nn() { grep -c '^- [^|]* | observe: notice — ViD progress — repo: ' .vid/HEARTBEAT.md || true; }
age() { awk -v old="$(awk 'BEGIN { srand(); print "2026-01-01T00:00:00Z" }')" '$1 == "progress" { sub(/ at=[^ ]*$/, " at=" old) } { print }' .vid/metrics-events > x && mv x .vid/metrics-events; }
tick; [ "$(np)" -eq 1 ] && [ "$(nn)" -eq 1 ] || fail 'the first tick did not record and notify once'
tail -n 1 .vid/metrics-events | grep -q '^progress trigger=hourly by=observer ' || fail 'the first update is not trigger=hourly by=observer'
tick; [ "$(np)" -eq 1 ] && [ "$(nn)" -eq 1 ] || fail 'a second tick at once was not silent'
sleep 1; sh checks/plan.sh change reorder 'S1 first' --trigger unknown --expect 'the steps build in order' > /dev/null
tick; [ "$(np)" -eq 2 ] && [ "$(nn)" -eq 2 ] || fail 'a plan change did not make one update and one notice'
grep '^progress ' .vid/metrics-events | tail -n 1 | grep -q 'trigger=plan-change' || fail 'the update after a plan change is not trigger=plan-change'
tick; [ "$(np)" -eq 2 ] || fail 'the tick after the plan-change update was not silent'
age; tick; [ "$(np)" -eq 3 ] && [ "$(nn)" -eq 3 ] || fail '3,600 s after the last update, no hourly update and notice'
tick; [ "$(np)" -eq 3 ] && [ "$(nn)" -eq 3 ] || fail 'a recorded notice was repeated'
grep -q '^progress.pending ' .vid/observer.state && fail 'a pending send was kept'
exit 0

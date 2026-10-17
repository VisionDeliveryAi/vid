#!/bin/sh
# Purpose: selftest case — an admission refusal is recorded (v0.9.6.2 spec
# 3.4, R4; §6 case 18). Under the gate, as rule-a.sh: 30 rows of a started
# step unverified, admitting a 40-row step is refused by rule A and writes
# `refused phase=admission by=rule-A attempt=<id> step=S2`; `plan.sh start`
# of a step not in the plan writes `by=no-step step=S9`; an admitted step
# writes none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "refused-admission: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep '^refused' .vid/metrics-events >&2 || true; exit 1; }
plan_repo "$T/repo"; rows s1 1 30; rows s2 31 70; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-030' \
  'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-031..ROW-070' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'both build' > /dev/null
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused'
grep -q '^refused ' .vid/metrics-events && fail 'an admitted step wrote a refused event'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'rule A did not refuse'; fi
tail -n 1 .vid/metrics-events | grep -qxE "refused phase=admission by=rule-A attempt=[0-9]{8}T[0-9]{6}Z-[0-9a-f]{4} step=S2 $ATRE" || fail 'the rule A refusal is not recorded in its form'
if sh checks/plan.sh start S9 > "$T/out" 2>&1; then fail 'a step not in the plan was admitted'; fi
tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=no-step .* step=S9 ' || fail 'the missing step is not recorded'
exit 0

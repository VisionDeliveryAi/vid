#!/bin/sh
# Purpose: selftest case — rule A: a ceiling on unverified work (v0.9.6
# spec 3.5, R5; §7 case 26). With unverified-rows=60 (the default), 30 rows
# of a started step unverified: admitting a 40-row step is refused, naming
# the count; after 20 of the 30 pass, it is admitted (10 + 40 = 50). A
# budget raised in .vid/budget without a recorded `plan-change what=other`
# naming it is not honoured; recorded that way, it is. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "rule-a: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 30; rows s2 31 70; rows s3 71 110; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-030' \
  'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-031..ROW-070' \
  'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-071..ROW-110' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused (nothing started yet)'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'a 40-row step was admitted with 30 unverified under 60'; fi
grep -q 'rule A: 70 unverified rows would exceed unverified-rows=60' "$T/out" || fail 'the refusal does not name the count'
PASS=''; i=1; while [ $i -le 20 ]; do PASS="$PASS $(printf 'ROW-%03d=passed' $i)"; i=$((i + 1)); done
# shellcheck disable=SC2086
rcpt r1 HEAD inline $PASS
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'the 40-row step was refused after 20 of the 30 passed'
printf 'unverified-rows=200\n' > .vid/budget
if sh checks/plan.sh start S3 > "$T/out" 2>&1; then fail 'a budget raised without a recorded change was honoured'; fi
grep -q 'raised without a recorded' "$T/out" || fail 'the unrecorded raise was not said'
sh checks/plan.sh change other 'unverified-rows=200: the owner'"'"'s machine takes three environments' --trigger unknown --expect 'the steps build in order' > /dev/null || fail 'the recorded raise was refused'
sh checks/plan.sh start S3 > "$T/out" 2>&1 || fail 'the recorded raise was not honoured'
exit 0

#!/bin/sh
# Purpose: selftest case — an invalidated receipt is no current result
# (v0.9.6 spec 3.3, R3; §7 case 29). A receipt passing a row makes it pass;
# `invalidated slice=N report=<that receipt> <why>` (a void run, such as a
# boot race) makes the row never run again; a newer receipt of the same
# commit counts; an invalidation naming another receipt changes nothing.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "invalidated: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed
[ "$(state ROW-001)" = pass ] || fail 'the fixture receipt does not pass the row'
sh checks/event.sh 'invalidated slice=1 report=other.xml an unrelated void run'
[ "$(state ROW-001)" = pass ] || fail 'an invalidation naming another receipt changed the row'
sh checks/event.sh 'invalidated slice=1 report=r1 the product booted after the tests began'
[ "$(state ROW-001)" = never ] || fail 'an invalidated receipt still counted'
rcpt r2 HEAD inline ROW-001=passed
[ "$(state ROW-001)" = pass ] || fail 'the rerun on the same commit did not count'
exit 0

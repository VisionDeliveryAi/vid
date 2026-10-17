#!/bin/sh
# Purpose: selftest case — the expected-empty control (v0.9.7.0.3 spec
# 3.1, R1; §6 A-6). A cheap green request writes no analyst-due event and
# no `analyst due` result line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-green: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1[ROW-001]=passed:0.4" "$TF::test_2[ROW-002]=passed:1"
K=$(ask "$T/r" --type iterate --role builder --try t1 --rows ROW-001,ROW-002 --why 'a cheap green run' -- "$TF") || fail 'the request was refused'
grep -q '^status=0 ran-to-end=yes capped=no report=' "$T/res" && grep -qx 'cases passed=2' "$T/res" || fail 'the green run did not end green'
[ "$(cat ".vid/requests/$K/state")" = done ] || fail 'the state is not done'
[ -z "$(due "$K")" ] || fail 'a cheap green request wrote an analyst-due event'
grep -q '^analyst due' "$T/res" && fail 'a cheap green request said analyst due'
exit 0

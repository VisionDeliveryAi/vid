#!/bin/sh
# Purpose: selftest case — a representative heavy proof (v0.9.7.0.12 spec 3.8; R8; §6 E). With no receipt history
# `testenv.sh heaviest` says none. With two receipts' cases on record, it names the case of the largest recorded
# seconds and its receipt. A measured selection whose receipt leaves that case out is refused, naming it, and nothing
# is recorded; one whose receipt holds it is measured and recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-heavy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
cp "$CHECKS/testenv.sh" checks/; commit_all testenv
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
sh checks/testenv.sh heaviest > "$T/out" 2>&1; grep -q '^heaviest none' "$T/out" || fail 'heaviest with no history'
HC='tests/invariants/test_s1.py::test_heavy[ROW-001]'
mkdir -p .vid/ledger-results
printf 'case tests/invariants/test_s1.py::test_a[ROW-001] passed 5\ncase %s passed 300\n' "$HC" > .vid/ledger-results/r1.xml.cases; sleep 1
printf 'case tests/invariants/test_s1.py::test_b[ROW-001] passed 10\n' > .vid/ledger-results/r2.xml.cases
sh checks/testenv.sh heaviest > "$T/out" 2>&1; grep -qxF "heaviest case=$HC seconds=300 receipt=r1.xml" "$T/out" || fail "heaviest: $(cat "$T/out")"
# a selection without it: refused, nothing recorded
if sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' > "$T/out" 2>&1; then fail 'a measure without the heaviest case was recorded'; fi
grep -qF "left out the home's heaviest case $HC (300 s in r1.xml)" "$T/out" || fail 'the refusal does not name the heaviest case'
grep -q '^env-mb=' .vid/testenv 2>/dev/null && fail 'a refused measure recorded env-mb'
# with it: measured
STUB_BYSEL=1 sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' "$HC" > "$T/out" 2>&1 || fail 'a measure holding the heaviest case was refused'
grep -q '^testenv measure env-mb=' "$T/out" && grep -q '^env-mb=' .vid/testenv || fail 'the heavy measure was not recorded'
exit 0

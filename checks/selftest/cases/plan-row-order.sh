#!/bin/sh
# Purpose: selftest case — row order inside a step does not count
# (v0.9.7.0.11 spec 3.8a, R16). With a recorded plan, a block whose step's
# rows sit in another order, with runs of spaces, is no unrecorded change:
# `plan.sh start` admits the step, and its step-start names the recorded
# hash (hashes stay raw; recorded plans keep their names). The steps
# reordered is still a change, refused as unrecorded; so is a row dropped.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-row-order: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 3; rows s2 4 4; commit_all rows
SH="shared: $PLANS_SHARED"
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-003'
S2='step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-004'
plan "$S1" "$S2" "$SH"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'create'
H1=$(sed -n 's/.*hash=\([0-9a-f]*\) .*/\1/p' "$T/out")
plan 'step S1 | name: first |  modules: app/s1 | builds-on: - | rows: ROW-003   ROW-001 ROW-002' "$S2" "$SH"
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'rows in another order were refused as an unrecorded change'
tail -n 1 .vid/metrics-events | grep -q "^step-start step=S1 plan=$H1 " || fail 'the step-start does not name the recorded hash'
plan "$S2" "$S1" "$SH"
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'the steps reordered were not a change'; fi
grep -q 'the plan changed without a recorded change' "$T/out" || fail 'the reorder refusal does not name the unrecorded change'
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-002 ROW-001' "$S2" "$SH"
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'a row dropped was not a change'; fi
exit 0

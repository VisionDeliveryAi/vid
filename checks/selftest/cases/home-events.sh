#!/bin/sh
# Purpose: selftest case — an unlinked worktree's events land at the home
# it finds, beside its receipt (v0.9.7.0.1 spec 3.1, R1, R4; §6 A-5). A
# worktree with no .vid/ runs a row red through the live run found among
# the checkouts; its `event.sh 'red-observed …'` and `event.sh
# 'invalidated …'` lines land in the home's .vid/metrics-events, none in
# its own; `plan.sh redstamp --staged` there joins a staged proved-red
# stamp to that red. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "home-events: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/main"; rows s1 1 1; commit_all rows
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
HOMEP=$(pwd -P)
g worktree add -q "$T/X" -b x 2>/dev/null
cd "$T/X"
STUB_CASE=failed sh checks/test.sh --role builder -- 'tests/x' > "$T/out" 2>&1 || fail 'the red run failed to run'
R=$(cd "$HOMEP" && kept | grep '\.live\.sel-' | head -n 1)
[ -n "$R" ] && [ -f "$HOMEP/.vid/ledger-results/$R.cases" ] || fail "no receipt with its cases at the home: $R"
sh checks/event.sh "red-observed row=ROW-001 report=$R case=tests/invariants/t.py::a[ROW-001] assertion=\"the total is 12\""
sh checks/event.sh 'invalidated report=an-older-receipt reason="a test edit"'
grep -q "^red-observed row=ROW-001 report=$R " "$HOMEP/.vid/metrics-events" || fail 'the red-observed event is not at the home'
grep -q '^invalidated report=an-older-receipt ' "$HOMEP/.vid/metrics-events" || fail 'the invalidated event is not at the home'
[ ! -e .vid/metrics-events ] || fail "the worktree's own .vid/ holds events"
sed "s/^\\(ROW-001 | .*\\)\$/\\1 | proved-red: $(git rev-parse --short=12 HEAD)/" INVENTORY.md > "$T/inv" && mv "$T/inv" INVENTORY.md; g add INVENTORY.md
sh checks/plan.sh redstamp --staged > "$T/out" 2>&1 || fail 'the stamp join did not find the red at the home'
grep -q 'joined to their observed red: ROW-001' "$T/out" || fail 'the stamp was not joined'
exit 0

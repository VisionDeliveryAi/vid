#!/bin/sh
# Purpose: selftest case — a data-driven test file (v0.9.6.1 spec 3.4,
# revision 11, amendment 5; §6). One parameterised test, test_x[ROW-007-a]
# and test_x[ROW-008-a], with a data line per row above it. Editing
# ROW-007's data line stales ROW-007 only; editing test_x's body stales
# both. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-data: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows d 7 8
F=tests/invariants/test_d.py
printf 'DATA = {\n    "ROW-007": "seven",\n    "ROW-008": "eight",\n}\n\ndef test_x(row):\n    assert DATA[row]\n' > "$F"; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-007 ROW-008' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt_raw r1 HEAD "$F::test_x[ROW-007-a]=passed" "$F::test_x[ROW-008-a]=passed"
[ "$(state ROW-007)" = pass ] && [ "$(state ROW-008)" = pass ] || fail 'the receipt is not current at its own tree'
B=$(git rev-parse HEAD)
sed 's/"seven"/"seven, amended"/' "$F" > "$F.x" && mv "$F.x" "$F"; commit_all 'ROW-007 data'
[ "$(state ROW-007)" = stale ] || fail "editing ROW-007's data line did not stale it"
[ "$(state ROW-008)" = pass ] || fail "editing ROW-007's data line staled ROW-008"
g checkout -q -b body "$B"; sed 's/assert DATA\[row\]/assert DATA[row] != ""/' "$F" > "$F.x" && mv "$F.x" "$F"; commit_all 'test_x body'
[ "$(state ROW-007)" = stale ] && [ "$(state ROW-008)" = stale ] || fail 'editing the shared test body did not stale both rows'
exit 0

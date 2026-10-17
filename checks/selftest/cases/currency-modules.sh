#!/bin/sh
# Purpose: selftest case — what re-opens a passed result under the gate
# (v0.9.6 spec 3.3, R3; §7 case 23 — its verdict changed by v0.9.6.1 spec
# 3.4, R4). S2 builds on S1; S3 is unrelated. A receipt passing S2's rows,
# judged at later commits: 0.9.6 staled it after a change under S1's
# modules, a change to a shared: path, and a file moved out of S1 into S3
# (backlog R2-F1's ROW-1015 shape). Under 0.9.6.1 a result stands until the
# row's own test changes, it is amended, or a later receipt shows it
# otherwise — so after each of those changes, and after a change in S3,
# ROW-003 still passes, labelled with the commit it passed at. The guard
# given up is the owner's accepted trade (spec 3.4); such a break is caught
# at a close that selects the row, or at the final full run. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "currency-modules: $*" >&2; exit 1; }
detail() { sh checks/plan.sh map --all > "$T/map" 2>/dev/null; sh checks/evidence.sh rows --at "${2:-HEAD}" --map "$T/map" | awk -F'\t' -v r="$1" '$1 == r { print $3 }'; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' \
  'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-003=passed ROW-004=passed
[ "$(state ROW-003)" = pass ] || fail 'the receipt is not current at its own tree'
printf 'change\n' >> app/s3/main.py; commit_all 's3'; C1=$(git rev-parse HEAD)
[ "$(state ROW-003 "$C1")" = pass ] || fail 'a change in unrelated S3 staled S2'
g checkout -q -b s1change "$C1"; printf 'the toolbar label\n' >> app/s1/main.py; commit_all 's1'
[ "$(state ROW-003 HEAD)" = pass ] || fail 'a change under S1, which S2 builds on, re-opened S2'
detail ROW-003 HEAD | grep -q '^passed at ' || fail 'the older pass is not labelled with its commit'
g checkout -q -b sharedchange "$C1"; printf 'x\n' >> tests/invariants/harness.py; commit_all 'shared'
[ "$(state ROW-003 HEAD)" = pass ] || fail 'a change to a shared path re-opened S2'
g checkout -q -b moved "$C1"; g mv app/s1/main.py app/s3/moved.py; commit_all 'move out of S1'
[ "$(state ROW-003 HEAD)" = pass ] || fail 'a file moved out of S1 into S3 re-opened S2'
exit 0

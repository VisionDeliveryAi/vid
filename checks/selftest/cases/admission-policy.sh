#!/bin/sh
# Purpose: selftest case — admission follows the close policy (v0.9.6.1 spec
# 3.4, R4; §6 case 6). S2 and S3 build on S1, which passed. After a
# committed change under S1's modules, with no re-run, rule B admits S2
# (a builder brief for S2, checked by checks/brief.sh). Once S1's newest
# result for ROW-002 is failed, rule B refuses S3, naming the row. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "admission-policy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' \
  'step S3 | name: third | modules: app/s3 | builds-on: S1 | rows: ROW-005 ROW-006' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
printf 'a change under S1\n' >> app/s1/main.py; commit_all 's1 change'
brief .vid/briefs/1/builder-1.md builder S2 ROW-003 ROW-004
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'S2 was refused after an S1 module change with no re-run'
grep -q 'admitted S2' "$T/out" || fail 'the brief did not admit S2'
rcpt r2 HEAD inline ROW-001=passed ROW-002=failed
if sh checks/plan.sh start S3 > "$T/out" 2>&1; then fail 'S3 was admitted over S1'"'"'s newest failed result'; fi
grep -q 'S3 builds on S1, which is not passing: ROW-002 red' "$T/out" || fail 'the refusal does not name the red row'
exit 0

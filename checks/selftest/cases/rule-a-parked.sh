#!/bin/sh
# Purpose: selftest case — rule A ignores parked edge rows (v0.9.7.2 spec 3.2, R6). unverified-rows=5. S1 is started
# with its four rows unverified; two of them (ROW-003, ROW-004) move by edge to the unstarted hardening step H1 and
# leave rule A's count, so S3 (two new rows) is admitted: 2 + 2 within 5 — under depth first the same admission is
# refused (4 + 2). The hardening step's own admission counts its parked rows as new: S1's 2 + H1's 6 exceed 5,
# refused naming the 6. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "rule-a-parked: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
rows s3 13 14; commit_all 'S3 rows'
printf 'unverified-rows=5\n' > .vid/budget
S3L='step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-013 ROW-014'
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$S3L" "$H1L" > /dev/null
sh checks/plan.sh start S1 > /dev/null
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "$S2L" "$S3L" 'step H1 | name: harden | modules: app/s3 | builds-on: - | rows: ROW-003 ROW-004 ROW-009..ROW-012 | kind: hardening'
chg edge 'ROW-003 and ROW-004 are edge' > /dev/null || fail 'the edge move was refused'
sh checks/plan.sh strategy depth-first --by owner --words 'depth' > /dev/null
if sh checks/plan.sh start S3 > "$T/out" 2>&1; then fail 'under depth first the parked rows left the count'; fi
grep -q 'rule A: 6 unverified rows would exceed unverified-rows=5' "$T/out" || fail 'the depth-first count is not 4 + 2'
sh checks/plan.sh strategy breadth-first --by owner --words 'breadth' > /dev/null
sh checks/plan.sh start S3 > "$T/out" 2>&1 || fail 'the parked rows still counted under breadth first'
if sh checks/plan.sh start H1 > "$T/out" 2>&1; then fail 'the hardening step was admitted past rule A'; fi
grep -q 'rule A: 10 unverified rows would exceed unverified-rows=5 (4 rows of started steps are not passing on current results; 6 of H1' "$T/out" || fail 'the hardening admission does not count its parked rows as new'
exit 0

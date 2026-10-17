#!/bin/sh
# Purpose: selftest case — a plan change re-checks only what it adds, and
# charges everything admitted (v0.9.7.0.11 spec 3.8, R8). S2 builds on S1;
# both started, S1 passing. Change 1 adds ROW-004 to the started S2 (rule B
# holds: S1 passes). Then S1 turns red. Change 2 — a new step S3 not
# started, S2 untouched — is accepted: ROW-004 is in S2 of the last
# recorded plan, so it is not re-admitted. Change 3, adding ROW-006 to S2,
# is refused by rule B (S1 red): what a change adds is still checked. The
# charge is cumulative: a change leaving ROW-004 (charged by change 1) in
# no step is refused as an orphan; and under unverified-rows=2 a change
# adding ROW-006 to S1 is refused by rule A, counting ROW-004 among the
# started steps' rows not passing (3 > 2). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-change-added: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
SH="shared: $PLANS_SHARED"
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003'
S3='step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005'
ch() { sh checks/plan.sh change "$1" "$2" --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1; }
H=$(git rev-parse --short=12 HEAD)
rcpt "$H.run-20260101T000000Z-1.live.sel-1.xml" HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed
plan "$S1" "$S2" "$SH"; ch create 'two steps' || fail 'create'
sh checks/plan.sh start S1 > "$T/out" 2>&1 && sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'the steps did not start'
plan "$S1" "$S2 ROW-004" "$SH"; ch rows 'S2 gains ROW-004' || fail 'change 1, adding ROW-004 to S2 while S1 passes, was refused'
rcpt "$H.run-20260101T000100Z-2.live.sel-1.xml" HEAD inline ROW-001=failed
plan "$S1" "$S2 ROW-004" "$S3" "$SH"
ch add 'S3, not started' || fail 'change 2 re-admitted ROW-004, added to S2 by an earlier change'
plan "$S1" "$S2 ROW-004 ROW-006" "$S3" "$SH"
if ch rows 'S2 gains ROW-006'; then fail 'change 3, adding to S2 while S1 is red, was accepted'; fi
grep -q 'rule B' "$T/out" || fail 'change 3 was not refused by rule B'
plan "$S1" "$S2" "$S3" "$SH"
if ch rows 'ROW-004 dropped'; then fail 'a change leaving ROW-004 (charged by change 1) in no step was accepted'; fi
grep -q 'leaves rows of started steps in no step: ROW-004' "$T/out" || fail 'the orphan refusal does not name ROW-004'
printf 'unverified-rows=2\n' > .vid/budget
plan "$S1 ROW-006" "$S2 ROW-004" "$S3" "$SH"
if ch rows 'S1 gains ROW-006'; then fail 'rule A did not count ROW-004 among the started rows'; fi
grep -q 'rule A: 3 unverified rows would exceed unverified-rows=2' "$T/out" || fail 'rule A does not count the cumulative charge'
exit 0

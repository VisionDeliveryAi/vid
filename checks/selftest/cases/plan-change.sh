#!/bin/sh
# Purpose: selftest case — a plan change is a recorded change (v0.9.6 spec
# 3.2, R2; §7 case 21). With a recorded plan, an edit to the block with no
# `plan-change` event is refused at a builder brief check (recorded
# result=fail) and at `plan.sh start`, naming the unrecorded change; `plan.sh
# change add "<why>"` records it — the event carries what=, the block's
# 12-hex hash and why=, and the block is kept in .vid/plans/<hash>.plan —
# and the next brief check and start pass. A plan with no recorded change
# at all is refused likewise. v0.9.6.2 (3.3): every change passes its
# decision arguments, and the event names its decision=. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-change: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004 | lane: builder'
S3='step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006 | lane: builder'
SH="shared: $PLANS_SHARED"
plan "$S1" "$S2" "$SH"
if sh checks/plan.sh start S1 > "$T/out" 2>&1; then fail 'a plan with no recorded change was admitted'; fi
grep -q 'no recorded change' "$T/out" || fail 'the refusal does not say the plan was never recorded'
sh checks/plan.sh change create 'the first plan' --trigger initial --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'change create was refused'
H1=$(sed -n 's/.*hash=\([0-9a-f]*\) .*/\1/p' "$T/out"); [ "${#H1}" -eq 12 ] || fail 'no 12-hex hash'
[ -f ".vid/plans/$H1.plan" ] || fail 'the plan was not kept'
tail -n 1 .vid/metrics-events | grep -qE "^plan-change what=create hash=$H1 decision=[0-9]{8}T[0-9]{6}Z-$H1 why=\"the first plan\" at=" || fail 'the event is not in its form'
# an unrecorded edit
plan "$S1" "$S2" "$S3" "$SH"
brief .vid/briefs/1/builder-1.md builder S3 ROW-005
if sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1; then fail 'a brief check passed on an unrecorded plan change'; fi
grep -q 'the plan changed without a recorded change' "$T/out" || fail 'the brief refusal does not name the unrecorded change'
tail -n 1 .vid/metrics-events | grep -q '^brief-check path=.vid/briefs/1/builder-1.md result=fail ' || fail 'the refused admission was not recorded result=fail'
if sh checks/plan.sh start S3 > "$T/out" 2>&1; then fail 'plan.sh start passed on an unrecorded plan change'; fi
grep -q 'the plan changed without a recorded change' "$T/out" || fail 'the start refusal does not name the unrecorded change'
sh checks/plan.sh change add 'S3: the third area' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'change add was refused'
H2=$(sed -n 's/.*hash=\([0-9a-f]*\) .*/\1/p' "$T/out"); [ "$H2" != "$H1" ] && [ -f ".vid/plans/$H2.plan" ] && [ -f ".vid/plans/$H1.plan" ] || fail 'the new plan was not kept beside the old'
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'the brief check still failed after the change was recorded'
grep -q 'admitted S3' "$T/out" || fail 'the brief check did not admit S3'
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'plan.sh start failed after the change was recorded'
exit 0

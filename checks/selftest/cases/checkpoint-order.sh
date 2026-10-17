#!/bin/sh
# Purpose: selftest case — a late checkpoint never overwrites a newer result
# (v0.9.6.1 spec 3.4, 3.8, R4, review round 2 finding 2; §6 case 13). A
# checkpoint frozen at commit A passes ROW-001; a close at descendant B,
# published first, failed it; the checkpoint is published after. The row
# stays red — results are ordered by the commit they tested. Two receipts
# on one commit are ordered by publication (the later wins). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "checkpoint-order: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
A=$(git rev-parse HEAD)
printf 'work\n' >> app/s1/main.py; commit_all 'B'; B=$(git rev-parse --short=12 HEAD)
RCPT_KIND=close rcpt "$B.run-20260101T000200Z-2.close.xml" HEAD inline ROW-001=failed ROW-002=passed
RCPT_KIND=checkpoint rcpt "${A%"${A#????????????}"}.run-20260101T000100Z-1.checkpoint.xml" "$A" inline ROW-001=passed ROW-002=passed
[ "$(state ROW-001)" = red ] || fail "the late checkpoint at the ancestor overwrote the newer failure: $(state ROW-001)"
[ "$(state ROW-002)" = pass ] || fail 'ROW-002 lost its pass'
RCPT_KIND=close rcpt "$B.run-20260101T000300Z-3.close.xml" HEAD inline ROW-001=passed ROW-002=passed
[ "$(state ROW-001)" = pass ] || fail 'a later receipt on the same commit did not stand'
exit 0

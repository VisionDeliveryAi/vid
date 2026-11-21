#!/bin/sh
# Purpose: selftest case — nothing recorded while an analysis's proposal is fresh (GM-4 E4, GM-3 U4; decisions.sh record), beside
# dp-r2-draft-wait's draft. With .vid/next/proposal/target naming HEAD, `decisions.sh record` prints `decisions wait proposal`, reads
# no description, commits nothing, leaves DECISIONS.md as it was and records no event, as a commit would make the proposal stale. With
# the target another commit, the next record records the merge's line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-proposal-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD); cp DECISIONS.md "$T/d0"
mkdir -p .vid/next/proposal; echo "$H0" > .vid/next/proposal/target
dpr_pr 5 3 'ticket: #3

Decisions:
- pages hold 20 items | why: the list fits'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qx 'decisions wait proposal' "$T/out" || fail 'no line decisions wait proposal'
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a commit while the proposal targets HEAD'
cmp -s "$T/d0" DECISIONS.md || fail 'DECISIONS.md changed while the proposal targets HEAD'
[ "$(dpr_reads 5)" = 0 ] || fail 'the description was read while the proposal targets HEAD'
! grep -q '^decisions-recorded ' .vid/metrics-events 2>/dev/null || fail 'an event while the proposal targets HEAD'
git rev-parse HEAD~1 > .vid/next/proposal/target 2>/dev/null || echo 0123456789abcdef0123456789abcdef01234567 > .vid/next/proposal/target
dpr_rec; [ "$RC" = 0 ] || fail "record with the target moved off HEAD exited $RC"
! grep -q 'decisions wait proposal' "$T/out" || fail 'record still waits with the target moved off HEAD'
grep -q '^- \*\*D-002\*\* pages hold 20 items | why: the list fits | enforced: ticket 3 |' DECISIONS.md || fail 'the line was not recorded once the target moved off HEAD'
grep -q '^decisions-recorded pr=5 n=1 at=' .vid/metrics-events || fail 'no event once the target moved off HEAD'
exit 0

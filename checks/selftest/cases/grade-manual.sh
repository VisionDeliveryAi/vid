#!/bin/sh
# Purpose: selftest case — the owner's grade ask in GitHub manual (GM-4 K8), on GitHub manual's toy and the fake gh (fixtures/accept.sh).
# An ask made in GitHub manual (grade.sh ask, at a commit of main) and its report pushed: the next call's step 2, round.sh step, reads it
# with its counts (`grade-ask <n> read <k>: <graded> graded, <not pass> not pass, <findings> findings`), closes the ask, and its finding
# and its requirement not passing become lines of the owner's queue. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "grade-manual: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; sh "$CHECKS/github.sh" lock-free > /dev/null 2>&1 || fail 'the lock could not be freed'
printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed
start() { sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'; }
end_() { sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'; }
# a call: own work on, and the owner's grade ask
start; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'
sh "$CHECKS/next-move.sh" call own-work on 'Yes, do your own work now' > "$T/out" 2>&1 || true; grep -q '^done own-work on' "$T/out" || fail 'own work was not switched on'
RC=0; sh "$CHECKS/grade.sh" ask --reqs 'REQ-001 REQ-002' --commit "$AC_C" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the grade ask exited $RC"
G=$(sed -n 's/^asked \([0-9]*\) grade ask-.*/\1/p' "$T/out"); [ -n "$G" ] || fail 'no grade ask'; end_
# its report
rr_put "grade-$G-1" grade.txt "$(printf 'by: GR\ncommit: %s\nREQ-001 pass — the digest goes out\nREQ-002 partial — the unsubscribe link is missing\nfinding: bug high — a digest sent twice' "$AC_C")"; ac_send "grade-$G-1"
# the next call's step 2 reads it, with its counts
start; ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"
grep -qx "grade-ask $G read 1: 2 graded, 1 not pass, 1 findings" "$T/out" || fail "the report was not read with its counts: $(grep '^grade' "$T/out")"
[ -f ".vid/decide/grade/$G/done" ] && [ "$(cat "$FAKEGH/issues/$G/state")" = CLOSED ] || fail 'the grade ask was not closed once read'
grep -q 'a digest sent twice' .vid/RUN-STATE.md && grep -q 'REQ-002 partial' .vid/RUN-STATE.md || fail "the report's finding and its partial are no lines of the owner's queue"
end_
exit 0

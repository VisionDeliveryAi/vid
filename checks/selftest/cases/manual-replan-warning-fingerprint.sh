#!/bin/sh
# Purpose: selftest case — implement-replan's fingerprint holds the analysis's warnings, their counts of days left out (GM-3 U6; next.sh
# rpfp_). On the re-plan toy (fixtures/manual.sh's mn_replan_toy), the analysis's proposal made (replan.sh analyse, as
# manual-replan-moves makes it), with a warning that counts days, and listed (the call's raise). A change to that count of days alone
# leaves implement-replan's line as listed, its fingerprint kept; a change to the warning's words alone changes its fingerprint, and
# implement-replan named is shown again, nothing applied. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-replan-warning-fingerprint: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
mn_replan_toy "$T/toy" || { cp "$T/mr" "$T/out"; fail 'the re-plan toy could not be made'; }
CLAUDE_CODE_SESSION_ID=replan-fingerprint-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
HOME=$T/home; export HOME; mkdir -p "$HOME"
lines() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
  grep "^move${TB}implement-replan${TB}" "$T/tr" > "$T/ir" || { cp "$T/tr" "$T/out"; fail "$1: implement-replan is not listed"; }; }
fp() { sed -n 's/.*(its fingerprint \([0-9a-f]\{12\}\)).*/\1/p' "$T/ir"; }
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
# the analysis: the candidate tops #N2 up with ROW-021, takes ROW-019 out of S03, and moves ROW-002 and HOS-003 into S05, of stage 2
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md |
  sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^\(step S04 .*rows:\) ROW-002 \(.*\) HOS-003 /\1 \2 /' -e 's/^\(step S05 .*rows: ROW-017\)/\1 ROW-002 HOS-003/' \
    -e 's/^needs ROW-001 /needs ROW-021 ROW-001 /' -e 's/^\(needs .*\) ROW-019 /\1 /' -e 's/^needs ROW-002 \(.*\) HOS-003 /needs \1 /' -e 's/^needs ROW-017 /needs ROW-017 ROW-002 HOS-003 /' > "$C/block"
S=$(git rev-parse --short HEAD); for s in S02 S03 S04 S05; do printf '%s\tscope-change\tcommit:%s\tthe landed changes placed\n' "$s" "$S"; done > "$C/changes"
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
# a warning of the proposal's that counts days, as the analysis writes its warnings (kind TAB subject TAB why)
W=.vid/next/proposal/warnings; printf 'stage-ahead\tS05\tstage 2 starts while stage 1 is open, its newest ticket out 4 days\n' >> "$W"
lines 'the listing'; cp "$T/ir" "$T/ir0"; F0=$(fp); [ -n "$F0" ] || { cp "$T/ir" "$T/out"; fail 'implement-replan carries no fingerprint'; }
sh "$CHECKS/queue.sh" raise "$T/tr" > "$T/out" 2>&1 || fail 'queue.sh raise failed'; A0=$(cat .vid/tw/applied)
# the count of days alone: the line as listed, its fingerprint kept
sed 's/out 4 days$/out 11 days/' "$W" > "$T/w" && cat "$T/w" > "$W"; grep -q 'out 11 days$' "$W" || fail 'the toy did not change the count of days'
lines 'the count of days changed'; cmp -s "$T/ir0" "$T/ir" || { paste "$T/ir0" "$T/ir" > "$T/out"; fail "a change to a warning's count of days alone changed implement-replan's line (listed, then now, above)"; }
# the warning's words alone: the fingerprint changes, and implement-replan named is shown again, nothing applied
sed 's/stage 2 starts while stage 1 is open/stage 2 starts while two tickets of stage 1 are open/' "$W" > "$T/w" && cat "$T/w" > "$W"
lines "the warning's words changed"; F1=$(fp); [ -n "$F1" ] && [ "$F1" != "$F0" ] || { cp "$T/ir" "$T/out"; fail "a change to a warning's words left implement-replan's fingerprint $F0"; }
call implement-replan 'Yes, apply the re-plan'
[ "$RC" = 0 ] && grep -q '^again implement-replan -: what it would do, or its warnings, changed since the listing; shown again, not done' "$T/out" || fail "implement-replan, its warning changed since the listing, is not shown again"
! grep -q '^done implement-replan' "$T/out" || fail 'implement-replan was done though its warnings changed'
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail 'the implement-replan shown again applied something'
exit 0

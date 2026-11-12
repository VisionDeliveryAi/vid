#!/bin/sh
# Purpose: selftest case — a withdrawn fix ticket's retirement is not lost (0.26.10.28.6 R2, build review). tw-limits.sh's set-up,
# with ROW-004 retired before the fix ticket of ROW-003 is published, so the ticket carries `retired=ROW-004` (the tests the dev
# side removes). ROW-003 is ruled a known limit and no pull request names it: the ticket is withdrawn, as in tw-limits. Its
# retirement then counts as carried by no ticket, so the next ticket written carries `retired=ROW-004`. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-limits-retired: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; W=$CHECKS/writer.sh
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# the skeleton's round, its ticket #1 merged as pull request 2 (as close-fix plants it); S01 left open; stage 0's candidate, and stage 1's
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 2 >> .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
tw_hand 'row ROW-004 retired'
tw_hand 'fix ROW-003 | ROW-003: ROW-003 in chromium | close #9 of S01: req-9-p1c1-1'
rd next; F=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out"); [ -n "$F" ] && grep -q "^published $F kind=fix step=S01 rows=ROW-003 " .vid/tw/log || fail 'the fix ticket was not published'
sh "$GS" tw-sync > "$T/out" 2>&1; ok "open tickets $F\$"
grep -q "^published $F .*retired=ROW-004" .vid/tw/log || fail "the fix ticket carries no retirement: $(grep "^published $F " .vid/tw/log)"
tw_hand 'row ROW-003 known-limit'
rd step; sh "$W" due > "$T/out" 2>&1 || fail 'due failed'; ok "^withdraw $F limits=ROW-003\$"
rd next; ok "^withdrawn $F\$"; [ "$(cat "$T/gh/issues/$F/state")" = CLOSED ] || fail "#$F stayed open"
# red-first: the next ticket carries the retirement the withdrawn one held
tw_hand 'fix ROW-006 | ROW-006: ROW-006 in chromium | close #9 of S01: req-9-p1c1-2'
N2=$(sh "$W" write fix ROW-006 2> "$T/out") || fail "the next fix ticket was refused: $(cat "$T/out")"
grep -qx 'The retired rows whose tests TA removes: ROW-004.' "$N2" || fail "the next ticket does not carry ROW-004's retirement: $(grep -in 'retire' "$N2")"
exit 0

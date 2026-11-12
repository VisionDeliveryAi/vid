#!/bin/sh
# Purpose: selftest case — a fix ticket whose rows all became known limits (0.26.10.28.6 R2, E-2), checks/round.sh, writer.sh and
# github.sh tw-close on TW's toy and the fake gh. The skeleton merged, S01 not closed (so every later step waits on rule B and is refused),
# stage 0's candidate named; the round publishes the fix ticket of ROW-003, and its alarm ticket-hours is raised. ROW-003 is ruled a known
# limit (the handed record's line, as a close's limit leaves it), and no pull request names the ticket: `writer.sh due` owes `withdraw <n> limits=ROW-003`, and the round's
# next withdraws it — the issue closed with a comment giving the true reason, its rows ruled known limits, never a plan change, and
# `withdrawn <n> decision=known-limit` logged. It leaves the open set (the sync's open tickets, which next counts against open-tickets:, and
# the progress line), its alarm clears, and the round's step prints `nothing-left`; tw-close then refuses it, a closed ticket. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-limits: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; W=$CHECKS/writer.sh
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# the skeleton's round, its ticket #1 merged as pull request 2 (as close-fix plants it); S01 left open; stage 0's candidate, and stage 1's
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 2 >> .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
tw_hand 'fix ROW-003 | ROW-003: ROW-003 in chromium | close #9 of S01: req-9-p1c1-1'
rd next; F=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out"); [ -n "$F" ] && grep -q "^published $F kind=fix step=S01 rows=ROW-003 " .vid/tw/log || fail 'the fix ticket was not published'
sh "$GS" tw-sync > "$T/out" 2>&1; ok "open tickets $F\$"
# its alarm: published long ago
sed "s/^\(published $F .*\) at=.*/\1 at=2020-01-01T00:00:00Z/" .vid/tw/log > "$T/l" && cat "$T/l" > .vid/tw/log; rd step; ok "^flag ticket-hours $F\$"; no '^nothing-left'
# the owner rules ROW-003 a known limit; no pull request names the ticket
tw_hand 'row ROW-003 known-limit'
rd step; sh "$W" due > "$T/out" 2>&1 || fail 'due failed'; ok "^withdraw $F limits=ROW-003\$"; no "^amend $F"
rd next; ok "^withdrawn $F\$"; [ "$(cat "$T/gh/issues/$F/state")" = CLOSED ] || fail "#$F stayed open"
grep -rqx "vid: withdrawn. Its rows ROW-003 were ruled known limits or taken out of the plan, so nothing in it is left to build. This ticket is not to be merged." "$T/gh/issues/$F/comments" || fail "#$F's comment does not give the true reason: $(cat "$T/gh/issues/$F/comments"/* 2>/dev/null)"
! grep -rq 'plan change' "$T/gh/issues/$F/comments" || fail "#$F's comment speaks of a plan change"
grep -q "^withdrawn $F decision=known-limit rows=ROW-003 at=" .vid/tw/log || fail 'the withdrawal is not logged'
# out of the open set: its slot freed, its alarm cleared, nothing left
sh "$GS" tw-sync > "$T/out" 2>&1; ok 'open tickets none$'; sh "$W" due > "$T/out" 2>&1; [ ! -s "$T/out" ] || fail "due still owes: $(paste -sd ';' "$T/out")"
rd step; ok '^progress: accepted=[0-9]* open=0 '; ok '^nothing-left$'; grep -q "^flag-cleared word=ticket-hours on=$F" .vid/metrics-events || fail 'its alarm did not clear'
# never again: a closed ticket is never changed
if sh "$GS" tw-close "$F" > "$T/out" 2>&1; then fail "tw-close withdrew the closed #$F again"; fi; ok "the round owes no withdrawal of #$F"; [ "$(grep -c "^withdrawn $F " .vid/tw/log)" = 1 ] || fail 'withdrawn twice'
exit 0

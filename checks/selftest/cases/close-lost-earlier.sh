#!/bin/sh
# Purpose: selftest case — a stage close's lost chunk shows the owner's earlier answer (0.26.11.1.4, R2), checks/queue.sh on TW's toy, the
# stage's records planted. Candidate 1's C3 loses p1c1 twice and is answered again "<first>", then twice more and is answered again
# "<second>"; another chunk is answered after both. Candidate 2's C3 then loses p1c1: its Q line shows `answered before (<date>, <by>):`
# with the newest answer for the same stage, kind and chunk, the second, never the first nor the other chunk's. So do its lost D1,
# RH, D2, S1 and rest chunk p1cx lines, each answered on candidate 1: each shows its own earlier answer and no other's. The words are shown
# only: a bare again on candidate 2 sends none of them. A step close's lost line shows none. Where skills/ stands beside checks/, the
# close-lost row says the run manager gives no recommendation of its own: vid-step-close's row since GM-4 K3 carved the close's lines
# out of vid-run. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "close-lost-earlier: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; mkdir -p .vid/round .vid/decide
X=$(git --git-dir="$T/code.git" rev-parse main)
cand() { F=.vid/decide/stage/0/$1; mkdir -p "$F/cs"; printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$2" "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; }
qof() { sh "$QS" sync > /dev/null 2>&1 || true; sh "$QS" keys > "$T/keys" 2>&1 || true; awk -F'\t' -v k="$1" '$1 == k { print $2 }' "$T/keys"; }
line() { grep "^- $1 · " .vid/RUN-STATE.md || true; }
qa() { q=$(qof "$1"); [ -n "$q" ] || fail "no Q line for $1: $(cat "$T/keys")"; shift; RC=0; sh "$QS" answer "$q" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the answer was refused ($RC)"; }
# candidate 1: p1c1 lost twice, answered; lost twice more, answered again; then p1c2 lost and answered, newest of all
cand 1 5; echo 'lost p1c1 ROW-036:alpha:error #1' > .vid/decide/stage/0/1/cs/items
qa 'close:stage-0/1/cs:lost:p1c1:1' again 'first words: the sign-in seed'
echo 'lost p1c1 ROW-036:alpha:error #2' > .vid/decide/stage/0/1/cs/items
qa 'close:stage-0/1/cs:lost:p1c1:2' again 'second words: the staging switch is on now'
echo 'lost p1c2 ROW-189:alpha:error #1' > .vid/decide/stage/0/1/cs/items
qa 'close:stage-0/1/cs:lost:p1c2:1' again 'other chunk words'
# candidate 1's other lost lines, each answered: D1, RH, the grade S1, the rest chunk p1cx and D2
for d in d1 rh d2; do mkdir -p .vid/decide/stage/0/1/$d; echo "lost $d #1001" > .vid/decide/stage/0/1/$d/items; qa "close:stage-0/1/$d:lost:$d:1001" again "$d words: earlier"; done
echo 'lost s1 #1' > .vid/decide/stage/0/1/cs/items; qa 'close:stage-0/1/cs:lost:s1:1' again 's1 words: earlier'
echo 'lost p1cx ROW-200:alpha:error #1' > .vid/decide/stage/0/1/cs/items; qa 'close:stage-0/1/cs:lost:p1cx:1' again 'p1cx words: earlier'
# candidate 2, the newest: its p1c1 lost twice
cand 2 9; echo 'lost p1c1 ROW-1842:alpha:error #1' > .vid/decide/stage/0/2/cs/items
q=$(qof 'close:stage-0/2/cs:lost:p1c1:1'); [ -n "$q" ] || fail "no Q line for candidate 2's lost p1c1: $(cat "$T/keys")"; L=$(line "$q")
echo "$L" | grep -q ' · answered before (20[0-9-]*T[0-9:]*Z, owner): again "second words: the staging switch is on now"' || fail "candidate 2's line lacks the newest earlier answer: $L"
! echo "$L" | grep -q 'first words' || fail "candidate 2's line shows the older answer: $L"
! echo "$L" | grep -q 'other chunk words' || fail "candidate 2's line shows another chunk's answer: $L"
# candidate 2's D1, RH, S1, p1cx and D2 lost: each line shows its own kind's earlier answer, from candidate 1
printf 'lost s1 #1\nlost p1cx ROW-1843:alpha:error #1\n' >> .vid/decide/stage/0/2/cs/items
for d in d1 rh d2; do mkdir -p .vid/decide/stage/0/2/$d; echo "lost $d #2001" > .vid/decide/stage/0/2/$d/items; done
for kk in d1/lost:d1:2001 rh/lost:rh:2001 d2/lost:d2:2001 cs/lost:s1:1 cs/lost:p1cx:1; do w=${kk#*:}; w=${w%%:*}
  q=$(qof "close:stage-0/2/${kk%%/*}:${kk#*/}"); [ -n "$q" ] || fail "no Q line for candidate 2's lost $w: $(cat "$T/keys")"; L=$(line "$q")
  echo "$L" | grep -q " · answered before (20[0-9-]*T[0-9:]*Z, owner): again \"$w words: earlier\"" || fail "candidate 2's lost $w line lacks its earlier answer: $L"
  [ "$(echo "$L" | grep -o 'words: earlier' | wc -l | tr -d ' ')" = 1 ] || fail "candidate 2's lost $w line shows another kind's answer: $L"; done
# shown only: a bare again on candidate 2 sends no earlier words to DevAgent
qa 'close:stage-0/2/cs:lost:p1c1:1' again 'once more'   # GM-4 K6: the owner's answer carries the owner's words
! grep -q 'words' .vid/decide/stage/0/2/cs/againwhy 2>/dev/null || fail "an earlier answer's words would go out as why: $(cat .vid/decide/stage/0/2/cs/againwhy)"
grep -qxF 'allow p1c1' .vid/decide/stage/0/2/cs/again || fail 'the bare again was not taken'
# a step close's lost line: no earlier answer (none is the same stage)
mkdir -p .vid/decide/close/S01/1; printf 'issue\t3\n' > .vid/decide/close/S01/1/ask; echo 'lost p1c1 ROW-003:alpha:error #1' > .vid/decide/close/S01/1/items
q=$(qof 'close:S01/1:lost:p1c1:1'); [ -n "$q" ] || fail "no Q line for the step close: $(cat "$T/keys")"
! line "$q" | grep -q 'answered before' || fail "a step close's line shows a stage's answer: $(line "$q")"
# the close-lost row: the run manager adds no recommendation of its own (read only where skills/ stands beside checks/); GM-4 K3: the
# close's lines are vid-step-close's
VR=$CHECKS/../skills/vid-step-close/SKILL.md
[ ! -d "$CHECKS/../skills" ] || grep '^| `close-again <step> <chunk>`, `close-lost …`' "$VR" 2>/dev/null | grep -q 'Where ViD.s line gives no recommendation, give none of your own: relay the line' || fail "vid-step-close's close-lost row lacks the no-advice sentence"
echo 'close-lost-earlier: ok'

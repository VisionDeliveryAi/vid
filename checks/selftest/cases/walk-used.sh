#!/bin/sh
# Purpose: selftest case — a walk says what it used (FB-7 C1), and its brief has words for every item (FB-7 C3): walk.sh brief and read on
# the writer's toy, stage 1's walk due, its items the golden path, ROW-001, ROW-005 and ROW-006. `stopped — <what>` is an item's third word,
# the golden path's and the rows'; the wander's and a screen's never. Every item stopped, the wander done and the screen looked at: not done, `nothing could be
# used: <the golden path's words>`, or the first stopped item's where the golden path is not stopped, no W1 done, its findings kept, a
# question whose answers are again and, the owner's alone, close without the walk: a known limit in the walk's words, the walk owed no more
# (done, before). A walk the walker itself could not make reads as today, and takes again alone;
# one it could not finish, with items used and items stopped, says so with its number in its words and in the question. Some stopped: done, the done
# line and W1's record saying `walk 2 of 4 items used, 2 stopped by the product: golden path, ROW-005`. None stopped: `w1 done`, as today,
# W1's record empty. The status line and the summary's facts carry the words of a walk partly stopped, a summary without them is refused and
# one with them closes the stage; a walk with nothing stopped gives the summary no walk line. A row whose promise ends `; fails if` has its words in the brief, and one with none at all the words of a clause.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/one; mkdir -p "$T"; HOME=$T0/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "walk-used: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; WS=$CHECKS/walk.sh; QS=$CHECKS/queue.sh; mkdir -p .vid/round .vid/decide design/screens "$T/wk"; VID_WALK_TMP=$T/wk; export VID_WALK_TMP
wk() { RC=0; sh "$WS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
# ROW-001's promise ends `; fails if`, ROW-006's has no end before it; each cites the screen
echo '<html>the saved search canvas</html>' > 'design/screens/S01 Subscribe.dc.html'
sed -e 's/^\(ROW-001 | [^|]*| [^|]*| [^|]*| \)[^|]*| [^|]*|/\1S01\/saved | Each saved search is kept; fails if one is lost. |/' \
  -e 's/^\(ROW-006 | [^|]*| [^|]*| [^|]*| \)[^|]*| [^|]*|/\1S01\/saved | Every page shows the header, fails if one does not. |/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p "$K/cs" "$K/d1"
printf 'issue\t9\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$K/ask"; echo "$X" > "$K/commit"; : > "$K/named"; : > "$K/passed"; printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$K/cs/ask"; : > "$K/cs/passed"; : > "$K/cs/issue-closed"
printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\n' > "$K/d1/read"
# walk <golden> <ROW-001> <ROW-005> <ROW-006> <screen> <wander> [<finding line>]: a brief, the return written by hand, read
walk() { wk brief --stage 1; [ "$RC" = 0 ] || fail 'no brief'; B=$(tail -n 1 "$T/out"); { printf 'by: WA\ncandidate: %s\nbrowser: chrome\ngolden path: %s\nROW-001: %s\nROW-005: %s\nROW-006: %s\nscreen S01/saved: %s\nwander: %s\n' "$X" "$1" "$2" "$3" "$4" "$5" "$6"; [ -z "${7:-}" ] || printf '%s\n' "$7"; } > "$B/walk.txt"; wk read --stage 1; }
afresh() { rm -rf "$K/w1"; rm -f .vid/decide/queue/answers; }
notdone() { ok "^w1 not-done $1\$"; [ ! -f "$K/w1/done" ] || fail "W1 is done: $1"; [ -z "${2:-}" ] || ok "^walk-item 1 not done — $1 #"; }
# the brief's words (C3)
wk brief --stage 1; [ "$RC" = 0 ] || fail 'no brief'; B=$(tail -n 1 "$T/out")/brief.md
[ "$(sed -n '/^## The rows/,/^## The screens/s/^- \([A-Z]*-[0-9]*\):.*/\1/p' "$B" | paste -sd ' ' -)" = 'ROW-001 ROW-005 ROW-006' ] || fail "the brief's rows: $(grep '^- ' "$B")"
grep -qx -- '- ROW-001: Each saved search is kept;' "$B" || fail "ROW-001 has no words of its promise: $(grep '^- ROW-001' "$B")"
grep -qxF -- '- ROW-006: (walk it as a user would, by its screen)' "$B" || fail "ROW-006 has no words: $(grep '^- ROW-006' "$B")"; afresh
# none used: the golden path's words; its findings kept; a question, answered again
F='finding: bug — after sign-in the page is blank; every item stops there'
walk 'stopped — a blank page after sign-in' 'stopped — the blank page' 'stopped — no digest comes' 'stopped — the blank page' 'differs — the page is blank' done "$F"
notdone 'nothing could be used: a blank page after sign-in' item; grep -qxF "1	W1 $F" "$K/w1/findings" && grep -q 'W1 screen S01/saved: differs' "$K/w1/findings" || fail "its findings: $(cat "$K/w1/findings")"
[ "$(cat "$K/w1/1/read")" = 'not-done	nothing could be used: a blank page after sign-in' ] || fail "its read: $(cat "$K/w1/1/read")"
wk owed; ! grep -q '^walk 1' "$T/out" || fail 'a walk of which nothing was used starts again by itself'
QN=$(qn 'the walk W1 of stage-1: not done — nothing could be used: a blank page after sign-in'); [ -n "$QN" ] || fail "nothing used reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
grep -q "^- $QN · .*answer again: .*; or, yours alone, close without the walk" .vid/RUN-STATE.md || fail "the question does not offer close without the walk: $(grep "^- $QN" .vid/RUN-STATE.md)"
sh "$QS" answer "$QN" again 'it opens now' > "$T/out" 2>&1 || fail 'again was refused'; wk owed; ok '^walk 1$'
# again, and stopped once more: closed without the walk, by the owner alone
walk 'stopped — a blank page after sign-in' 'stopped — the blank page' 'stopped — no digest comes' 'stopped — the blank page' 'differs — the page is blank' done "$F"; notdone 'nothing could be used: a blank page after sign-in'
QN=$(qn 'the walk W1 of stage-1: not done — nothing could be used: a blank page after sign-in'); [ -n "$QN" ] || fail 'the second walk reached no Q line'
for by in RM stand-in; do RC=0; sh "$QS" answer "$QN" --by "$by" close without the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q "the owner's answer alone, never $by's" "$T/out" && [ ! -f "$K/w1/limit" ] || fail "close without the walk was taken from $by"; done
sh "$QS" answer "$QN" close without the walk > "$T/out" 2>&1 || fail "the owner's close without the walk was refused"
[ "$(sed -n 1p "$K/w1/limit")" = 'walk not done: nothing could be used: a blank page after sign-in' ] && sed -n 2p "$K/w1/limit" | grep -qE '^the owner, [0-9-]*T[0-9:]*Z$' || fail "the limit's record: $(cat "$K/w1/limit")"
wk owed; ! grep -q '^walk 1' "$T/out" || fail 'a walk closed without is owed again'; afresh
# the golden path not stopped: the first stopped item's words; a screen that matches and a wander done use nothing
walk 'not done — no inbox' 'stopped — a blank page' 'stopped — no digest comes' 'not done — no clock' matches done; notdone 'nothing could be used: a blank page'; afresh
# what stops the walker alone reads as today, and one item it could not make, beside ones it used
walk 'not done — the address does not answer' 'not done — the address does not answer' 'not done — the address does not answer' 'not done — the address does not answer' 'not done — the address does not answer' 'not done — the address does not answer'
notdone 'the address does not answer' item; QN=$(qn 'the walk W1 of stage-1: not done — the address does not answer'); ! grep -q "^- $QN · .*close without the walk" .vid/RUN-STATE.md || fail 'an address that does not answer offers close without the walk'
RC=0; sh "$QS" answer "$QN" close without the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && [ ! -f "$K/w1/limit" ] || fail 'close without the walk was taken for an address that does not answer'; afresh
walk done done 'not done — no inbox' 'stopped — an error page' matches done; M='no inbox; walk 2 of 4 items used, 1 stopped by the product: ROW-006'; notdone "$M" item; [ -n "$(qn "the walk W1 of stage-1: not done — $M")" ] || fail "a walk partly made reaches the owner without its numbers: $(grep '^- Q' .vid/RUN-STATE.md)"; afresh
# some used: done, with their number, said and on record
walk 'stopped — the digest never comes' done 'stopped — no digest comes' done matches done 'finding: bug — no digest comes'
W='walk 2 of 4 items used, 2 stopped by the product: golden path, ROW-005'; ok "^w1 done: $W\$"; [ "$(cat "$K/w1/done")" = "$W" ] || fail "W1's record: $(cat "$K/w1/done" 2>/dev/null)"
wk fin 1; [ "$RC" = 0 ] || fail 'W1 has no outcome'; afresh
# none stopped: as today
walk done done done done matches done; ok '^w1 done$'; [ -f "$K/w1/done" ] && [ ! -s "$K/w1/done" ] || fail 'a walk with nothing stopped records words'; afresh
# the third word is an item's alone, with what stopped it
walk 'stopped' done done done matches done; ok '^w1 refused golden path reads neither done, stopped nor not done$'; afresh
walk done done done done 'stopped — a blank page' done; ok '^w1 refused screen S01/saved reads neither matches, differs nor not done$'; afresh
walk done done done done matches 'stopped — a blank page'; ok '^w1 refused wander reads neither done nor not done$'
afresh
# the summary: a stage whose other conditions are met (planted), its walk partly stopped
part2() { T=$T0/$1; mkdir -p "$T"; tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out design/screens "$T/wk"; VID_WALK_TMP=$T/wk
  printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'; gh issue create -R owner/code --title t0 --body b > /dev/null; tw_close 1
  tk 2 skeleton S01 ROW-003,ROW-004 '' 0; mg 2; tk 3 step S02 ROW-001 '' 1; mg 3; tk 4 step S03 ROW-006,SEAM-001,RULE-001 'SEAM-001=seam RULE-001=rule' 1; mg 4; tk 5 step S04 ROW-002 '' 1; mg 5
  for r in ROW-003 ROW-004 ROW-001 ROW-006 ROW-002 RULE-001; do tw_hand "row $r accepted"; done; tw_hand 'row SEAM-001 owed'; tw_hand 'closed S01'; echo '<html>the saved search canvas</html>' > 'design/screens/S01 Subscribe.dc.html'
  K=.vid/decide/stage/1/1; cs stage 1; ok '^candidate 1 1$'; X=$(cat "$K/commit"); mkdir -p "$K/d1" "$K/cs"; : > "$K/passed"; : > "$K/done"; : > "$K/d1/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$K/d1/read"; : > "$K/cs/passed"; : > "$K/cs/ask"; tw_hand 'row SEAM-001 paid'
  for q in $(sed -n 's/^reqs\t//p' "$K/s1ask"); do printf '%s\tpass\t1\n' "$q"; done > .vid/decide/stage/1/s1; : > "$K/s1done"
  sh "$CHECKS/plan.sh" parse 2>/dev/null | awk -F'\t' '$1 == "row" && $3 ~ /^S0[234]$/ { print $2 }' | while read -r r; do grep -q "^row $r " .vid/tw/handed || tw_hand "row $r paid"; done; sh "$GS" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'
  wk brief --stage 1; [ "$RC" = 0 ] || fail 'no brief'; B=$(tail -n 1 "$T/out"); awk '/^## The rows/ { on = 1; next } /^## / { on = 0 } on && /^- / { x = substr($0, 3); sub(/:.*/, "", x); print x }' "$B/brief.md" > "$T/rs"; n=$(( $(grep -c . "$T/rs") + 1 ))
  { printf 'by: WA\ncandidate: %s\nbrowser: chrome\ngolden path: done\n' "$X"; while read -r r; do echo "$r: $2"; done < "$T/rs"; sed -n 's/^- screen \([^:]*\):.*/screen \1: matches/p' "$B/brief.md"; echo 'wander: done'; } > "$B/walk.txt"; wk read --stage 1; }
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s\n\n## Rows\n\n' "$1" "$2" "$3" "$6"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R owner/code --title "t$1" --body b --label ticket > /dev/null; printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && g commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); P=$((20 + $1)); echo "$P" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$P" "$1" "$MC" "$MC" >> .vid/decide/merges; }
part2 some 'stopped — it never comes'; W="walk 1 of $n items used, $((n - 1)) stopped by the product: $(paste -sd , "$T/rs" | sed 's/,/, /g')"; [ "$n" -gt 1 ] || fail 'the toy gives the walk no row'; ok "^w1 done: $W\$"
sh "$QS" status > "$T/out" 2>&1; grep -qF " · W1 done — $W · " "$T/out" || fail "the status line: $(grep '^stage 1:' "$T/out")"
cs stage 1; ok '^summary 1$'; grep -qxF "walk	$W" "$K/facts.txt" || fail "the facts: $(grep '^walk' "$K/facts.txt")"
sm() { { printf 'Went back: '; awk -F'\t' '$1 == "went-back" { printf "%s; ", $3 }' "$K/facts.txt"; printf '\nDecided for you: '; awk -F'\t' '$1 == "decided" { printf "%s; ", $2 }' "$K/facts.txt"; printf '\n%s\n' "$1"; } > "$K/summary.md"; }
sm 'Every item passed.'; cs stage 1; ok "^summary-refused 1 the summary does not say the walk's outcome: $W\$"; sm "The $W."; cs stage 1; ok '^stage-closed 1 at [0-9a-f]*$'
# none stopped: no walk line in the facts
part2 all done; ok '^w1 done$'; cs stage 1; ok '^summary 1$'; ! grep -q '^walk' "$K/facts.txt" || fail "a walk with nothing stopped has words: $(grep '^walk' "$K/facts.txt")"
# the walker's role
WM=$CHECKS/walker.md; grep -qF '`stopped — <what>`' "$WM" && grep -qxF 'golden path: done | stopped — <what> | not done — <why>' "$WM" && grep -qxF '<row id>: done | stopped — <what> | not done — <why>' "$WM" && grep -qxF 'wander: done | not done — <why>' "$WM" || fail 'walker.md does not give the third word'
exit 0

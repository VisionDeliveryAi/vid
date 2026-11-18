#!/bin/sh
# Purpose: selftest case — a fix ticket loses the rows a plan change moved out of its step (0.26.10.29.2, R11 with R3), checks/writer.sh
# and github.sh on TW's toy and the fake gh. S02's ticket merged, a fix ticket of S02 holds ROW-001 and ROW-012, its pull request open; a plan change
# moves ROW-012 into a new step S06. The round owes the fix ticket's amendment: it holds ROW-001 alone, its comment names ROW-012 removed, on the issue
# and the pull request alike; S06's ticket then holds ROW-012 and names the fix ticket and its pull request. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-fix-moved: $*" >&2; cat "$T/out" "$T/werr" "$T/due" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh; R=owner/code
due() { sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1; sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; }
last() { d=$T/gh/$1/$2/comments; k=$(ls "$d" 2>/dev/null | sort -n | tail -n 1); [ -n "$k" ] && cat "$d/$k"; }
tw_skel || fail 'the skeleton round failed'
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"; tw_close "$TW_N"; sh "$GS" tw-sync > /dev/null 2>&1
tw_hand 'fix ROW-001 ROW-012 | ROW-001: ROW-001 in chromium; ROW-012: ROW-012 in chromium | close #9 of S02: req-9-p1c1-1'; tw_post fix ROW-001 || fail 'the fix ticket failed'; F=$TW_N
[ "$(sed -n 's/^- rows: //p' "$TW_F")" = 'ROW-001 ROW-012' ] || fail "the fix ticket holds $(sed -n 's/^- rows: //p' "$TW_F")"
Wd=$T/w; git clone -q "$T/code.git" "$Wd" 2>/dev/null; git -C "$Wd" checkout -q -B fx origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m fx; git -C "$Wd" push -q -f origin fx
P=$(gh pr create -R $R --head fx --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$F")" | sed 's/.*\///')
# ROW-012 moves to S06: the fix ticket amended to ROW-001, told on the issue and the pull request
pt_rs 's/^\(step S02 .*\)ROW-012 /\1/'; pt_rs 's/^shared: web$/step S06 | name: the newest first at size | modules: ingest digest | builds-on: S01 | rows: ROW-012 | lane: devagent\nshared: web/'
sh "$CHECKS/plan.sh" change rows 'ROW-012 goes alone' --trigger scope-change --evidence step:S02 --expect 'S06 builds it' > "$T/out" 2>&1 || fail 'the plan change was refused'
due; grep -qx "amend $F" "$T/due" || fail "due does not owe the fix ticket's amendment: $(paste -sd ';' "$T/due")"
tw_post amend "$F" || fail "#$F could not be amended"; [ "$(sed -n 's/^- rows: //p' "$TW_F")" = ROW-001 ] || fail "the amended fix ticket holds $(sed -n 's/^- rows: //p' "$TW_F")"
last issues "$F" > "$T/ci"; last prs "$P" > "$T/cp"; grep -q '^- removed: ROW-012 (' "$T/ci" && cmp -s "$T/ci" "$T/cp" || fail "the issue and the pull request were not told ROW-012 left: $(cat "$T/ci")"
# S06's ticket carries ROW-012 and names the fix ticket's work
tw_start S06 || { cat "$T/start" >&2; fail 'S06 was refused'; }; tw_post step S06 || fail "S06's ticket failed"
sed -n 's/^- rows: //p' "$TW_F" | tr ' ' '\n' | grep -qx ROW-012 || fail "S06's ticket does not hold ROW-012"
grep -qx -- "- earlier work: ticket #$F, pull request #$P" "$TW_F" || fail "S06's ticket does not name #$F and its pull request"
# every row of a fix ticket moved out of its step: withdrawn, no second ticket owed for the row, and the step's close, which
# waited for that ticket's merge, no longer waits on it
tw_hand 'fix ROW-005 | ROW-005: ROW-005 in chromium | close #9 of S02: req-9-p1c1-2'; tw_post fix ROW-005 || fail 'the second fix ticket failed'; F2=$TW_N
K2=$(awk -v n="$F2" '$1 == "published" && $2 == n' .vid/tw/log | tr ' ' '\n' | sed -n 's/^fix=//p'); M=$(git --git-dir="$T/code.git" rev-parse main)
mkdir -p .vid/round .vid/decide/close/S02/1; printf 'issue\t92\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\n' "$M" > .vid/decide/close/S02/1/ask; : > .vid/decide/close/S02/1/done; printf '%s\tROW-005\n' "$K2" > .vid/decide/close/S02/1/fixes
owedc() { sh "$CHECKS/close.sh" owed > "$T/out" 2>&1 || fail 'close.sh owed failed'; }
owedc; ! grep -qx 'close S02' "$T/out" || fail "S02's close does not wait for its fix ticket #$F2"
pt_rs 's/^\(step S02 .*\)ROW-005 /\1/'; pt_rs 's/^\(step S06 .*rows: ROW-012\) /\1 ROW-005 /'
sh "$CHECKS/plan.sh" change rows 'ROW-005 goes with S06' --trigger scope-change --evidence step:S02 --expect 'S06 builds it' > "$T/out" 2>&1 || fail 'the second plan change was refused'
due; grep -q "^withdraw $F2 " "$T/due" || fail "due does not owe the withdrawal of #$F2: $(paste -sd ';' "$T/due")"; sh "$GS" tw-close "$F2" > "$T/out" 2>&1 || fail "#$F2 could not be withdrawn"
due; ! grep -q '^new fix' "$T/due" || fail "a second fix ticket is owed for the moved row: $(paste -sd ';' "$T/due")"
owedc; grep -qx 'close S02' "$T/out" || fail "S02's close still waits on the withdrawn fix ticket #$F2"
exit 0

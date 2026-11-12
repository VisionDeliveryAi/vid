#!/bin/sh
# Purpose: selftest case — a close a landing reaches is withdrawn and asked again (v0.26.10.26.7, R9, W-11), checks/land.sh,
# close.sh and writer.sh pending on the writer's toy and the fake gh. Live closes: S02's (its own rows), S03's (S02's ROW-008 a regression
# row), S04's (S02's ROW-001 and S03's ROW-014 dependency rows); S05 closed. Landing A, REQ-001 amended, reaches ROW-001 and ROW-008:
# S02, S03 and S04 withdrawn, each recording the rows; S05 left closed. No close is owed before the reached rows' ticket is published,
# though a new step is due in the same round. Ticket R1 holds them, in two steps: neither S02's nor S03's close is owed before it
# merges. Landing B, REQ-002 amended, reaches ROW-014: S04's withdrawn close gains it. Ticket R2 holds it, filed under S03; R1 merged,
# S02's close is owed, S03 and S04 wait for R2; R2 merged, S04 owed and asked at R2's merge; S03 (a regression row's close) waits for
# an open fix ticket that already held ROW-008 (so it was never pending), and is asked at its merge, holding R1's. A closed step stays closed throughout. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "close-reached: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; LS=$CHECKS/land.sh; R=owner/code; TAB=$(printf '\t')
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
# owed: with the writer's due set aside (WDUE empty: the toy's hand-made tickets carry no sent hashes, so the writer owes every step
# a new ticket), so the reached rows' wait and pending rows alone hold a close; owedr: with the writer's due as it is
owed() { WDUE= sh "$CS" owed > "$T/out" 2>&1 || fail "owed failed: $(tail -n 1 "$T/out")"; }; owedr() { sh "$CS" owed > "$T/out" 2>&1 || fail "owed failed: $(tail -n 1 "$T/out")"; }
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"; tw_hand 'engines alpha beta'
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
tk() { n=$(gh issue create -R $R --title "t$1" --body b --label ticket | sed 's/.*\///'); printf '# t\n\n## Header\n\n- number: %s\n- kind: step\n\n## Rows\n\n' "$n" > ".vid/tw/out/issue-$n.md"
  printf 'published %s kind=step step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$n" "$1" "$2" >> .vid/tw/log; echo "$n"; }
mkdir -p .vid/decide/close .vid/round; : > .vid/decide/merged-prs; : > .vid/decide/merges
for x in S02 S03 S04 S05; do printf 'step-start step=%s at=2026-11-09T09:00:00Z\n' "$x" >> .vid/metrics-events; done
N2=$(tk S02 ROW-001,ROW-005,ROW-008); N3=$(tk S03 ROW-006,ROW-014); N4=$(tk S04 ROW-002); N5=$(tk S05 ROW-017); mg 20 "$N2"; mg 21 "$N3"; mg 22 "$N4"; mg 23 "$N5"
ca() { s=$1; shift; mkdir -p ".vid/decide/close/$s/1"; i=$(gh issue create -R $R --title "Close run: $s" --body b --label run | sed 's/.*\///'); printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$i" "$MC" > ".vid/decide/close/$s/1/ask"
  for r; do echo "$r 30"; done > ".vid/decide/close/$s/1/rows"; }
FX=$(gh issue create -R $R --title fx --body b --label ticket | sed 's/.*\///'); printf 'published %s kind=fix step=S05 rows=ROW-008 at=2026-11-09T12:00:00Z\n' "$FX" >> .vid/tw/log   # an open fix ticket holding ROW-008
ca S02 ROW-001 ROW-005; ca S03 ROW-006 ROW-008; I3=$i; ca S04 ROW-002 ROW-001 ROW-014; ca S05 ROW-017 ROW-008; tw_hand 'closed S05'
# landing A: REQ-001 amended, no row changed
amend() { { cat PRD.md; printf '\n### 2026-11-10 (%s)\n\n```vid-prd\n' "$1"; grep "^$2 |" PRD.md | head -n 1 | sed "s/^$2 |/$2 AMENDED |/; s/$3/$4/"; printf '```\n'; } > "$T/p" && cp "$T/p" PRD.md; }
land() { printf 'none\n' > "$T/rv"; RC=0; sh "$LS" draft --review "$T/rv" --why "$1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "draft refused ($RC)"; n=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out")
  RC=0; sh "$LS" "$n" --words 'Yes' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "landing $n refused ($RC)"; }
amend 'once more' REQ-001 'arrive in one day' 'arrive in one day, or one is sent before eight'; grep -q '^REQ-001 AMENDED' PRD.md || fail 'no REQ-001 to amend'; land 'REQ-001 amended'
ok '^withdrawn S02 1$'; ok '^withdrawn S03 1$'; ok '^withdrawn S04 1$'; no '^withdrawn S05'; grep -q '^closed S05 ' .vid/tw/handed || fail 'S05 was reopened'
has() { grep -qx "$2" ".vid/decide/close/$1/1/reached" || fail "$1's reached lacks $2: $(paste -sd ' ' ".vid/decide/close/$1/1/reached")"; }; hasno() { ! grep -qx "$2" ".vid/decide/close/$1/1/reached" || fail "$1's reached holds $2"; }
has S02 ROW-001; has S03 ROW-008; hasno S03 ROW-006; has S04 ROW-001; hasno S04 ROW-014; hasno S04 ROW-002
[ ! -f .vid/decide/close/S05/1/withdrawn ] || fail 'the closed step S05 was withdrawn'; grep -q CLOSED "$T/gh/issues/$I3/state" || fail "S03's ask issue stayed open"
# before the reached rows' ticket: no close owed, with a new step due in the same round
sh "$GS" tw-sync > /dev/null 2>&1; sh "$CHECKS/writer.sh" pending > "$T/out" 2>&1; ok '^ROW-001 S02$'; no '^ROW-008 '   # ROW-008: in the open fix ticket, so not pending
sh "$GS" spec-export > /dev/null 2>&1 || fail 'no export'; sh "$GS" tw-sync > /dev/null 2>&1; tw_start S03 > /dev/null 2>&1 || true; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || true; cp "$T/out" "$T/due"
owed; no '^close S0'; owedr; grep -q '^new step S0' "$T/due" || fail 'no new step due in the round'; no '^close S0'
# ticket R1 holds them; unmerged, neither step's close
# rt: a reached-rows ticket as the writer publishes it, holding the pending rows and listing their rulings (the writer owes the toy's
# steps new tickets of their own here, so the ticket is posted by hand; its log line is the writer's form)
rt() { P=$(sh "$CHECKS/writer.sh" pending | cut -d' ' -f1 | paste -sd , -); [ -n "$P" ] || fail 'no pending reached rows'; F=$(sh "$CHECKS/writer.sh" pending | sed -n 1p | cut -d" " -f2)
  K=$(awk '$1 == "reached" && $4 ~ /^[0-9a-f]+$/ { print $2 ":" $3 ":" $4 }' .vid/tw/handed | paste -sd , -); n=$(gh issue create -R $R --title "reached" --body b --label ticket | sed 's/.*\///')
  printf '# t\n\n## Header\n\n- number: %s\n- kind: reached\n\n## Rows\n\n' "$n" > ".vid/tw/out/issue-$n.md"
  printf 'published %s kind=reached step=%s rows=%s reached=%s rulings=%s at=2026-11-10T10:00:00Z\n' "$n" "$F" "$P" "$P" "$K" >> .vid/tw/log; TW_N=$n; }
rt; R1=$TW_N; sh "$GS" tw-sync > /dev/null 2>&1; [ -z "$(sh "$CHECKS/writer.sh" pending)" ] || fail "rows pending after R1: $(sh "$CHECKS/writer.sh" pending)"
grep "^published $R1 " .vid/tw/log | grep -q 'ROW-001' || fail "R1's rows: $(grep "^published $R1 " .vid/tw/log)"
owed; no '^close S02$'; no '^close S03$'; no '^close S04$'
# landing B: REQ-002 amended reaches ROW-014; S04's withdrawn close gains it, S04 not withdrawn again
H0=$(git rev-parse HEAD); amend 'and again' REQ-002 'requires a sign-in' 'requires a sign-in or a second click'; land 'REQ-002 amended'; no '^withdrawn S04'
has S04 ROW-001; has S04 ROW-014
sh "$GS" tw-sync > /dev/null 2>&1; rt; R2=$TW_N; grep "^published $R2 " .vid/tw/log | grep -q 'ROW-014' || fail "R2's rows: $(grep "^published $R2 " .vid/tw/log)"
# R1 merged: S02 and S03 owed, S04 waits for R2; R2 merged: S04 owed, asked at the merge holding both
# (R2 is filed under S03, its first row's step, and holds S03's ROW-014: S03 waits for it too)
mg 30 "$R1"; M1=$MC; sh "$GS" tw-sync > /dev/null 2>&1; owed; ok '^close S02$'; no '^close S03$'; no '^close S04$'; no '^close S05$'
mg 31 "$R2"; M2=$MC; sh "$GS" tw-sync > /dev/null 2>&1; owed; ok '^close S04$'; no '^close S05$'; no '^close S03$'   # S03 waits for the fix ticket holding ROW-008
mg 32 "$FX"; MF=$MC; sh "$GS" tw-sync > /dev/null 2>&1; owed; ok '^close S03$'
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null || true; }; fetch
WDUE= sh "$CS" ask S04 > "$T/out" 2>&1 || fail "S04's close was not asked: $(tail -n 2 "$T/out")"; [ "$(sed -n "s/^commit$TAB//p" .vid/decide/close/S04/2/ask)" = "$M2" ] || fail "S04 asked at $(sed -n "s/^commit$TAB//p" .vid/decide/close/S04/2/ask), not R2's merge $M2"
WDUE= sh "$CS" ask S03 > "$T/out" 2>&1 || fail "S03's close was not asked: $(tail -n 2 "$T/out")"; C3=$(sed -n "s/^commit$TAB//p" .vid/decide/close/S03/2/ask)
git --git-dir="$T/code.git" merge-base --is-ancestor "$M1" "$C3" && [ "$C3" = "$MF" ] || fail "S03's commit $C3 is not the fix ticket's merge $MF, holding R1's"
echo 'close-reached: ok'

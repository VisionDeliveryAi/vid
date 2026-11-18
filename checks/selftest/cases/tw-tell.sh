#!/bin/sh
# Purpose: selftest case — a published ticket is always amended or withdrawn, and the team told (0.26.10.29.2 R11), checks/writer.sh and
# github.sh on TW's toy and the fake gh. S02's ticket, claimed, with an open pull request: a plan change moves ROW-012 out and ROW-002 in;
# its amendment's comment names the cause (the change and its why) and each row added and removed by id and promise, on the issue and
# the same on the pull request. S03's ticket, unclaimed, no pull request: a changed row is named on its issue. A change takes more than
# half of S03's rows out: it is withdrawn, not amended, its comment naming where each row went, and its kept rows go out in a new S03
# ticket that names it. A fix ticket whose every row is ruled a known limit while its pull request is open: told, naming its rows as
# known limits, and not withdrawn. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-tell: $*" >&2; cat "$T/out" "$T/werr" "$T/due" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh; R=owner/code
due() { sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1; sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; }
owes() { grep -qx -- "$1" "$T/due" || fail "due does not owe '$1': $(paste -sd ';' "$T/due")"; }
chg() { sh "$CHECKS/plan.sh" change "$1" "$2" --trigger scope-change --evidence "$3" --expect "$4" > "$T/out" 2>&1 || fail "the plan change '$2' was refused"; sed -n 's/.*decision=\([^ ]*\).*/\1/p' "$T/out" | head -n 1; }
last() { d=$T/gh/$1/$2/comments; k=$(ls "$d" 2>/dev/null | sort -n | tail -n 1); [ -n "$k" ] && cat "$d/$k"; }
tw_skel || fail 'the skeleton round failed'; sed 's/^open-tickets: 2$/open-tickets: 3/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"; N2=$TW_N; tw_start S03 && tw_post step S03 || fail "S03's ticket failed"; N3=$TW_N
printf 'vid: claimed\nby: DM\n' > "$T/c"; gh issue comment "$N2" -R $R --body-file "$T/c" > /dev/null
Wd=$T/w; git clone -q "$T/code.git" "$Wd" 2>/dev/null; git -C "$Wd" checkout -q -B tk2 origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m tk2; git -C "$Wd" push -q -f origin tk2
P2=$(gh pr create -R $R --head tk2 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N2")" | sed 's/.*\///')
# S02 amended: ROW-012 out, ROW-002 in; the comment names the cause and each row, on the issue and the pull request
pt_rs 's/^\(step S02 .*\)ROW-012 /\1/'; pt_rs 's/^\(step S04 .*rows: \)ROW-002 /\1ROW-012 /'; pt_rs 's/^\(step S02 .*rows: ROW-001\) /\1 ROW-002 /'
D=$(chg rows 'ROW-012 waits for S04 and ROW-002 comes forward' step:S02 'S02 ships the limit first')
due; owes "amend $N2"
# the pull requests read whole first: as many as the limit allows is a refusal, and nothing is posted
k=$(ls "$T/gh/issues/$N2/comments" | grep -c .); FA=$(sh "$W" write amend "$N2" 2> "$T/werr") || fail 'the amendment could not be written'
if VID_OPRS_LIMIT=1 sh "$GS" tw-post --amend "$N2" "$FA" > "$T/out" 2>&1; then fail "#$N2 was amended from a list of pull requests not read whole"; fi
grep -q 'could not be read whole' "$T/out" && [ "$(ls "$T/gh/issues/$N2/comments" | grep -c .)" = "$k" ] && ! grep -q "^amended $N2 " .vid/tw/log || fail 'a refused amendment posted something'
tw_post amend "$N2" || fail "#$N2 could not be amended"; last issues "$N2" > "$T/ci"
# its pull requests come from the list of open ones, as the round's read does, never from a search, which is indexed late
! grep -q '^gh pr list .*--state open .*--search' "$T/gh/log" || fail "the pull requests of #$N2 were looked for by a search"
grep -q "^vid: amended by plan change $D" "$T/ci" && grep -q "plan change $D, what rows: ROW-012 waits for S04 and ROW-002 comes forward" "$T/ci" || fail "#$N2's amendment does not name its cause: $(cat "$T/ci")"
grep -q '^- added: ROW-002 (A subscriber can keep up to ten saved searches' "$T/ci" && grep -q '^- removed: ROW-012 (The listings at the stated size' "$T/ci" || fail "#$N2's amendment does not name the rows added and removed: $(cat "$T/ci")"
last prs "$P2" > "$T/cp"; cmp -s "$T/ci" "$T/cp" || fail "the pull request of #$N2 was not told the same: $(cat "$T/cp")"
# S03's ticket, unclaimed and with no pull request: a changed row is named on its issue
sed 's/opens the unsubscribe page with no sign-in/opens the unsubscribe page, with no sign-in/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; g commit -qam 'ROW-007 amended'; tw_ratify 'Yes, ROW-007 amended' || fail 'ROW-007 was not ratified'
due; owes "amend $N3"; tw_post amend "$N3" || fail "#$N3 could not be amended"; last issues "$N3" > "$T/ci"
grep -q '^- changed: ROW-007 (' "$T/ci" || fail "#$N3's amendment does not name its changed row: $(cat "$T/ci")"
# more than half of S03's rows out: withdrawn, not amended; the kept rows go out in a new ticket naming it
pt_rs 's/^\(step S03 .*rows: ROW-006 ROW-007 ROW-010 ROW-014 ROW-019\) [^|]*|/\1 |/'
pt_rs 's/^shared: web$/step S06 | name: the footer rules and protections | modules: web mail | builds-on: S01 | rows: RULE-001..RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005 | lane: devagent\nshared: web/'
D3=$(chg split 'S03 split in two' step:S03 'each half ships alone'); due; owes "withdraw $N3 decision=$D3 what=split kept=S03"; ! grep -q "^amend $N3" "$T/due" || fail "#$N3 is owed an amendment"
sh "$GS" tw-close "$N3" > "$T/out" 2>&1 || fail "#$N3 could not be withdrawn"; last issues "$N3" > "$T/ci"
grep -q "^- HOS-002 (.*): to step S06" "$T/ci" && grep -q "^- ROW-006 (.*): stays in step S03" "$T/ci" || fail "#$N3's withdrawal does not say where its rows went: $(cat "$T/ci")"
due; owes 'new step S03'; tw_post step S03 || fail "S03's new ticket failed"; [ "$(sed -n 's/^- rows: //p' "$TW_F")" = 'ROW-006 ROW-007 ROW-010 ROW-014 ROW-019' ] || fail "S03's new ticket holds $(sed -n 's/^- rows: //p' "$TW_F")"
grep -qx -- "- earlier work: ticket #$N3" "$TW_F" || fail "S03's new ticket does not name #$N3"
# a landing, no plan change, takes 3 of its 5 rows: withdrawn, the landing named as the cause
N5=$TW_N; printf 'landed draft=L9 at=2026-11-15T00:00:00Z ids=ROW-006,ROW-007,ROW-010\n' >> .vid/tw/log; due; owes "withdraw $N5 kept=S03"
sh "$GS" tw-close "$N5" > "$T/out" 2>&1 || fail "#$N5 could not be withdrawn"; last issues "$N5" > "$T/ci"
! grep -q 'plan change none' "$T/ci" && grep -q '^Cause: a landing changed ROW-006 ROW-007 ROW-010' "$T/ci" || fail "#$N5's withdrawal does not name the landing: $(cat "$T/ci")"
# a fix ticket ruled all known limits while its pull request is open: told, naming its rows, not withdrawn
tw_hand 'fix ROW-003 | ROW-003: ROW-003 in chromium | close #9 of S01: req-9-p1c1-1'; tw_post fix ROW-003 || fail 'the fix ticket failed'; F=$TW_N
git -C "$Wd" checkout -q -B fx origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m fx; git -C "$Wd" push -q -f origin fx; PF=$(gh pr create -R $R --head fx --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$F")" | sed 's/.*\///')
tw_hand 'row ROW-003 known-limit'
# a read of the pull requests older than PF (an empty one): a withdrawal is refused, as a pull request names it; a hand-call reads afresh and tells
mkdir -p .vid/round; : > .vid/round/read; if sh "$GS" tw-close "$F" > "$T/out" 2>&1; then fail "#$F was withdrawn while a pull request names it"; fi
[ "$(cat "$T/gh/issues/$F/state")" = OPEN ] || fail "#$F was closed"; sh "$GS" tw-hand tell "$F" > "$T/out" 2>&1 || fail "#$F could not be told by hand"
last issues "$F" > "$T/ci"; last prs "$PF" > "$T/cp"; grep -q '^- ROW-003 (.*): a known limit' "$T/ci" && cmp -s "$T/ci" "$T/cp" || fail "#$F and its pull request were not told its rows are known limits: $(cat "$T/ci")"
[ "$(cat "$T/gh/issues/$F/state")" = OPEN ] && ! grep -q "^withdrawn $F " .vid/tw/log || fail "#$F was withdrawn"; due; ! grep -q " $F\( \|$\)" "$T/due" || fail "#$F is still owed something: $(cat "$T/due")"
exit 0

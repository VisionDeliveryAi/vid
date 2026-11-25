#!/bin/sh
# Purpose: selftest case — changes to a published ticket, W7 and F20 (v0.26.10.12.3 R7). On TW's toy with S02's ticket (#2) and S03's (#3) open, each change is RM's recorded plan change, and
# `writer.sh due` owes what TW then does: nothing while nothing changed; rows moved out of S02 (the change citing
# ticket:2), then a change to S05 alone — `amend 2`, the ticket amended in place naming the first change only, no new
# issue; S03 split into S03 and S06 —
# `amend 3` and `new step S06`, no row in both; S06 withdrawn (its rows to S07), then S05 renamed — `withdraw 4` with
# the withdrawing change, the issue closed with a comment naming it, not the newer one, `withdrawn` logged, and S07's
# ticket new; tw-close refuses a ticket due does not owe, the merged skeleton's and an open one's (F20); rows added to the started S02 — `amend 2`; an
# amended row in an open ticket — `amend 2`, its earlier results named as not counting; a changed decision — every open
# ticket quoting it amended at the new export, which its header names; an amended row of a closed ticket — `new step
# S03`, holding that row alone; a row a ruling reached in an open ticket — that ticket amended with the changed
# requirement quoted; one in no open ticket — into the next ticket TW writes, or `new reached`, a ticket of its own; a
# later ruling on a row already listed (REQ-001 reworded) sends it out again, that ruling's requirement quoted. A
# closed ticket is never amended. Fix 3: with decisions enough for parts, #2 amended twice in parts — every part
# comment of an earlier writing says it is replaced, naming the current writing and each of its part comments (gh api
# -X PATCH on the issue comment), and the current parts join to the ticket. FB-7 C4: each amendment's comment says which rows to run
# again changed when its regression list differs from the ticket's, and only then. Env: CHECKS.
# selftest-limit: 1140 s — 320 to 376 s alone under load, past 900 s in the suite (FB-2 C1, the runner's rule, ×3)
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-change: $*" >&2; cat "$T/out" "$T/werr" "$T/due" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh; P=$CHECKS/plan.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
hrows() { sed -n 's/^- rows: //p' "$1"; }
due() { sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1; sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; }
owes() { grep -qx "$1" "$T/due" || fail "due does not owe '$1': $(paste -sd ';' "$T/due")"; }
chg() { sh "$P" change "$1" "$2" --trigger scope-change --evidence "$3" --expect "$4" > "$T/out" 2>&1 || fail "the plan change '$2' was refused"; }
issues() { ls "$T/gh/issues" | grep -c .; }
regs() { sec "$1" 'Regression rows' | grep '^- ' | sort || true; }   # FB-7 C4
amend() { regs ".vid/tw/out/issue-$1.md" > "$T/g0"; tw_post amend "$1" || fail "#$1 could not be amended"; [ "$TW_N" = "$1" ] || fail "the amendment of #$1 posted #$TW_N"
  regs "$TW_F" > "$T/g1"; c=$(grep -l '^vid: amended' "$T/gh/issues/$1/comments"/* | sed 's|.*/||' | sort -n | tail -n 1); [ -n "$c" ] || fail "#$1's amendment has no comment"
  if cmp -s "$T/g0" "$T/g1"; then ! grep -q '^Rows to run again: ' "$T/gh/issues/$1/comments/$c" || fail "#$1's amendment says its rows to run again changed, and none did"
  else grep -q '^Rows to run again: ' "$T/gh/issues/$1/comments/$c" || fail "#$1's amendment does not say its rows to run again changed"; fi; }
tw_skel || fail 'the skeleton round failed'
tw_start S02 && tw_post step S02 || fail "S02's ticket failed"; tw_start S03 && tw_post step S03 || fail "S03's ticket failed"
due; [ ! -s "$T/due" ] || fail "due owes something while nothing changed: $(paste -sd ';' "$T/due")"
# tw-close withdraws only what due owes, never a closed ticket: not the merged skeleton #1, not the open #2 (F20)
for n in 1 2; do if sh "$GS" tw-close $n > "$T/out" 2>&1; then fail "tw-close withdrew #$n, which due does not owe"; fi
  grep -q "the round owes no withdrawal of #$n" "$T/out" && ! grep -q "^withdrawn $n " .vid/tw/log && ! grep -rqs '^vid: withdrawn' "$T/gh/issues/$n/comments" || fail "#$n was withdrawn"; done
[ "$(cat "$T/gh/issues/2/state")" = OPEN ] || fail '#2 was closed'
# rows moved out
pt_rs 's/^\(step S02 .*\)ROW-012 /\1/'; pt_rs 's/^\(step S04 .*rows: \)/\1ROW-012 /'
chg rows 'ROW-012 waits for S04' ticket:2 'S02 ships without it'; D1=$(sed -n 's/.*decision=\([^ ]*\).*/\1/p' "$T/out" | head -n 1)
pt_rs 's/^\(step S05 | name: \)synonym-aware search/\1search by other names/'; chg other 'S05 renamed' step:S05 'nothing else moves'; due; owes 'amend 2'
I0=$(issues); amend 2; [ "$(issues)" = "$I0" ] || fail 'an amendment made an issue'
! hrows "$TW_F" | grep -q ROW-012 && grep -q "^- amended: by plan change $D1, what rows$" "$TW_F" || fail '#2 was not amended naming the change, without ROW-012'
ls "$T/gh/issues/2/comments" | grep -q . && grep -rq "^vid: amended by plan change $D1" "$T/gh/issues/2/comments" || fail "#2's amendment is not named on the issue"
grep -q '^amended 2 kind=step step=S02 ' .vid/tw/log || fail 'the amendment is not logged'
# a split: S03 keeps its ROW rows, S06 takes the rest
pt_rs 's/^\(step S03 .*rows: ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001..RULE-003\) [^|]*|/\1 |/'   # 0.26.10.29.2 (R11): S03 keeps more than half, so it is amended
pt_rs 's/^shared: web$/step S06 | name: the footer rules and protections | modules: web mail | builds-on: S01 | rows: HOS-002 HOS-004 SEAM-001 HOS-005 | lane: devagent\nshared: web/'
chg split 'S03 split in two' step:S03 'each half ships alone'
sed 's/^open-tickets: 2$/open-tickets: 3/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
tw_start S06 || { cat "$T/start" >&2; fail 'S06 was refused'; }; grep -q 'neither rule applies' "$T/start" || fail 'the split is not admitted without rules A and B'
due; owes 'amend 3'; owes 'new step S06'; amend 3; A3=$(hrows "$TW_F"); tw_post step S06 || fail "S06's ticket failed"; [ "$TW_N" = 4 ] || fail "S06's ticket is #$TW_N"
[ "$A3" = 'ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001 RULE-002 RULE-003' ] && [ "$(hrows "$TW_F")" = 'HOS-002 HOS-004 SEAM-001 HOS-005' ] || fail "the split's tickets hold $A3 and $(hrows "$TW_F")"
# a withdrawal: S06 leaves the plan, its rows to S07
pt_rs 's/^step S06 | name: the footer rules and protections | modules: web mail/step S07 | name: the footer rules, again | modules: web mail/'
chg other 'S06 withdrawn, its rows planned again as S07' step:S03 'S07 goes out instead'; D2=$(sed -n 's/.*decision=\([^ ]*\).*/\1/p' "$T/out" | head -n 1)
pt_rs 's/^\(step S05 | name: \)search by other names/\1search by other words/'; chg other 'S05 renamed again' step:S05 'nothing else moves'
due; owes "withdraw 4 decision=$D2 what=other"; sh "$GS" tw-close 4 > "$T/out" 2>&1 || fail '#4 could not be withdrawn'
[ "$(cat "$T/gh/issues/4/state")" = CLOSED ] && grep -rq "^vid: withdrawn by plan change $D2" "$T/gh/issues/4/comments" && grep -q "^withdrawn 4 decision=$D2 " .vid/tw/log || fail '#4 was not withdrawn as the change says'
tw_start S07 || fail 'S07 was refused'; due; owes 'new step S07'; ! grep -q 'withdraw 4\|amend 4' "$T/due" || fail 'a withdrawn ticket is still owed something'
tw_post step S07 || fail "S07's ticket failed"; S7=$TW_N
# rows added to the started S02
pt_rs 's/^\(step S04 .*\)ROW-002 /\1/'; pt_rs 's/^\(step S02 .*rows: ROW-001\) /\1 ROW-002 /'
chg rows 'ROW-002 joins S02' step:S02 'S02 holds the limit'; due; owes 'amend 2'; amend 2; hrows "$TW_F" | grep -q 'ROW-001 ROW-002' || fail 'the added row is not in #2'
# an amended row in an open ticket
sed 's/one digest a day, holding only jobs/one digest each morning, holding only jobs/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; g commit -qam 'ROW-001 amended'
tw_ratify 'Yes, ROW-001 amended' || fail 'the amended row was not ratified'; due; owes 'amend 2'; ! grep -q 'amend 3' "$T/due" || fail 'an untouched ticket is owed an amendment'
amend 2; grep -q 'one digest each morning' "$TW_F" && grep -rq 'Earlier results for its changed rows do not count' "$T/gh/issues/2/comments" || fail "the amended row's ticket is not re-pointed"
# a changed decision re-points every open ticket quoting it, at the new export
sed 's/the mail provider is the one the owner named/the mail provider is the one the owner chose/' DECISIONS.md > "$T/d" && cat "$T/d" > DECISIONS.md
awk 'BEGIN { for (i = 1; i <= 700; i++) printf "- **D-%d** every page keeps one plain wording for the same thing, so readers learn it once and trust it after that | why: a large decision set | enforced: convention\n", 100 + i }' >> DECISIONS.md; g commit -qam 'D-001, and decisions enough for parts'
due; owes 'amend 2'; owes 'amend 3'; amend 3; E=$(git -C "$T/gh/repos/owner%code-spec/remote.git" rev-parse refs/heads/main)
grep -qx -- "- export: $E" "$TW_F" && grep -q 'the owner chose' "$TW_F" && grep -q "^- amended: at the spec export $E" "$TW_F" || fail '#3 is not re-pointed at the new export'
amend 2; tw_post amend "$S7" || fail "#$S7 could not be amended"
# an amended row of a closed ticket goes out again; a closed ticket is never amended
tw_close 3; tw_closed S03; sed 's/opens the unsubscribe page with no sign-in/opens the unsubscribe page, with no sign-in/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; g commit -qam 'ROW-007 amended'
tw_ratify 'Yes, ROW-007 amended' || fail 'ROW-007 was not ratified'; due; owes 'new step S03'
if sh "$W" write amend 3 > "$T/out" 2>&1; then fail 'a closed ticket was amended'; fi; grep -q 'is not open' "$T/out" || fail 'the closed ticket is not named'
tw_post step S03 || fail "S03's second ticket failed"; [ "$(hrows "$TW_F")" = ROW-007 ] || fail "S03's second ticket holds $(hrows "$TW_F")"
# rows a ruling reached: in an open ticket, that ticket amended; in none, the next ticket, or one of their own
tw_hand 'reached ROW-001 REQ-001'; due; owes 'amend 2'; amend 2
sec "$TW_F" 'Rows a ruling reached' | grep -q '^- ROW-001, its requirement REQ-001 changed:' && sec "$TW_F" 'Rows a ruling reached' | grep -q '^> REQ-001 | functional' || fail 'the reached row is not quoted in its open ticket'
# fix 3: #2 was amended in parts twice; every part comment of an earlier writing says it is replaced, naming the
# current writing and each of its part comments, and the current parts (the body, then its part comments) join to it
D=$T/gh/issues/2; CW=$(head -n 1 "$D/body" | sed -n 's/^Ticket #2, part 1 of [0-9]*, writing \([0-9a-f]*\)\.$/\1/p'); [ -n "$CW" ] || fail "#2's body names no writing"
cur=''; rp=''; for k in $(ls "$D/comments" | sort -n); do case "$(head -n 1 "$D/comments/$k")" in
    "Ticket #2, part "*", writing $CW.") cur="$cur $k" ;; 'Ticket #'*) fail "#2's part comment $k, of an earlier writing, does not say it is replaced" ;; 'vid: replaced.'*) rp="$rp $k" ;; esac; done
[ -n "$cur" ] && [ "$(echo $rp | wc -w)" -ge 2 ] || fail "#2 shows no current part comment, or fewer than two replaced parts:$cur /$rp"
for k in $rp; do grep -q "^vid: replaced. .*The current writing, $CW, is this issue.s body, then its part comments " "$D/comments/$k" || fail "#2's replaced comment $k does not name the current writing"
  for c in $cur; do grep -q "issues/2#issuecomment-$((2000 + c))" "$D/comments/$k" || fail "#2's replaced comment $k does not name the current part comment $c"; done; done
{ sed '1,2d' "$D/body"; for c in $cur; do sed '1,2d' "$D/comments/$c"; done; } | cmp -s - "$TW_F" || fail "#2's current parts do not join to the ticket"
grep -q '^gh api -X PATCH repos/owner/code/issues/comments/2[0-9]* -F body=@' "$T/gh/log" || fail 'the edits were not made as issue comment edits'
tw_hand 'reached ROW-004 REQ-001'; due; owes 'new reached'; tw_post reached || fail 'the reached rows ticket failed'; RT=$TW_N
grep -qx -- '- kind: reached' "$TW_F" && sec "$TW_F" 'Rows a ruling reached' | grep -q '^- ROW-004, its requirement REQ-001 changed' || fail 'the reached rows ticket does not hold ROW-004'
sec "$TW_F" Asks | grep -qF 'When every test is kept, commit nothing but one empty commit naming the kept rows, so the pull request has a head.' || fail 'the reached T1 does not say how a kept test returns'   # v0.26.10.26.7 (R6)
due; ! grep -q 'new reached' "$T/due" || fail 'a listed reached row is owed again'
tw_hand 'reached ROW-003 REQ-001'; tw_close 2; tw_close "$RT"; tw_close "$S7"; tw_closed S02; sh "$GS" tw-sync > /dev/null 2>&1
tw_start S04 || { cat "$T/start" >&2; fail 'S04 was refused'; }; tw_post step S04 || fail "S04's ticket failed"
sec "$TW_F" 'Rows a ruling reached' | grep -q '^- ROW-003, its requirement REQ-001 changed' || fail 'the reached row did not ride into the next ticket'
# a second ruling on a listed row: S04's ticket closed, REQ-001 reworded and ratified, ROW-003 goes out again, quoted
tw_close "$TW_N"; sed 's/one digest per saved search per day, containing/one digest per saved search each day, containing/' PRD.md > "$T/p" && cat "$T/p" > PRD.md; g commit -qam 'REQ-001 reworded'
tw_ratify 'Yes, REQ-001 reworded' || fail 'the reworded requirement was not ratified'; tw_hand 'reached ROW-003 REQ-001'; due; owes 'new reached'
tw_post reached || fail "the second ruling's ticket failed"; sec "$TW_F" 'Rows a ruling reached' > "$T/rr"
grep -q '^- ROW-003, its requirement REQ-001 changed' "$T/rr" && grep -q 'per saved search each day' "$T/rr" || fail 'the second ruling on ROW-003 is not sent, its requirement quoted'
due; ! grep -q 'new reached' "$T/due" || fail 'the second ruling is owed again'
exit 0

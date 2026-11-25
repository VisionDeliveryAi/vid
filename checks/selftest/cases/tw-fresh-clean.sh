#!/bin/sh
# Purpose: selftest case — a ticket just published owes nothing, and an amendment says what it changes (FB-7 C4). On TW's toy with the
# skeleton's rows planned ROW-004 ROW-003: the skeleton's rows landed, its step's fresh ticket lists them in the plan's order and
# `writer.sh due` owes nothing right after it is published (an amendment, with nothing changed, before). With S02's ticket open, a rule
# row newly accepted and then a decision the ticket quotes: the amendment's comment says `Rows to run again: RULE-001 added; none left
# out.` beside the rows it holds; the row failing and another decision: `none added; RULE-001 left out.`; a third decision, the
# list the same: no such line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-fresh-clean: $*" >&2; cat "$T/out" "$T/sk" "$T/werr" "$T/start" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
due() { sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1; sh "$W" due > "$T/due" 2> "$T/werr" || fail 'due failed'; }
hrows() { sed -n 's/^- rows: //p' "$1"; }
said() { c=$(grep -l '^vid: amended' "$T/gh/issues/$1/comments"/* | sed 's|.*/||' | sort -n | tail -n 1); cat "$T/gh/issues/$1/comments/$c"; }   # the newest amendment's comment
pt_rs 's/rows: ROW-003 ROW-004 |/rows: ROW-004 ROW-003 |/'
sh "$CHECKS/plan.sh" change rows "the skeleton's rows the other way round" --trigger initial --expect 'nothing else moves' > "$T/out" 2>&1 || fail 'the plan change was refused'
tw_skel || fail 'the skeleton round failed'
# the skeleton's rows landed: its step's fresh ticket, in the plan's order, owes nothing
printf 'landed draft=L9 at=2026-11-15T00:00:00Z ids=ROW-003,ROW-004\n' >> .vid/tw/log; due
grep -qx 'new step S01' "$T/due" || fail "the landed rows owe no ticket of their step: $(paste -sd ';' "$T/due")"
tw_post step S01 || fail "the skeleton's landed rows have no ticket"; [ "$(hrows "$TW_F")" = 'ROW-004 ROW-003' ] || fail "the landed rows are not in the plan's order: $(hrows "$TW_F")"
due; [ ! -s "$T/due" ] || fail "a ticket just published owes, with nothing changed: $(paste -sd ';' "$T/due")"
N1=$TW_N; tw_close "$N1"; tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; due
# an amendment says which rows to run again came and went
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket failed"; N2=$TW_N
dec() { printf -- '- **D-%s** S02 shows the saved state in one line | why: short | enforced: convention\n' "$1" >> DECISIONS.md; g commit -qam "D-$1"; due; grep -qx "amend $N2" "$T/due" || fail "the decision D-$1 owes #$N2 no amendment: $(paste -sd ';' "$T/due")"; tw_post amend "$N2" || fail "#$N2 could not be amended"; said "$N2" > "$T/sd"; }
tw_hand 'row RULE-001 accepted'; dec 005
grep -qxF 'Rows to run again: RULE-001 added; none left out.' "$T/sd" || fail "the amendment does not say the row to run again it adds: $(cat "$T/sd")"
tw_hand 'row RULE-001 failing'; dec 006
grep -qxF 'Rows to run again: none added; RULE-001 left out.' "$T/sd" || fail "the amendment does not say the row to run again it leaves out: $(cat "$T/sd")"
dec 007; ! grep -q 'Rows to run again' "$T/sd" || fail "an amendment whose list is the same says it changed: $(cat "$T/sd")"
exit 0

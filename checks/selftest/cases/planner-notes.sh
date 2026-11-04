#!/bin/sh
# Purpose: selftest case — the two notes, computed and never refusing (v0.26.10.12.3.1 R5). On
# the planner's toy (fixtures/planner-toy.sh: S05 of stage 2 at wave 3, stage 1's last wave 3) one ahead-of-order note
# names S05, and no journey is noted (ROW-004's home steps are of a later stage, ROW-005's are its own S02). ROW-005
# moved into S03 (which builds on S01 alone) is noted: it does not build on S02, the home of REQ-001 and INV-001; with
# `fakes: S02` the note adds "only a dashed link". With both notes `check` prints `planner: clean` and exits 0, they
# are not in its output, `ratify` succeeds and `ratified` holds; the page's "Notes" section holds both, and "none" on
# a plan with neither. v0.26.10.12.3.2 (R7): a step whose needs lines name exactly its
# builds-on is noted, in any order; one naming a further step, one line naming less, and one building on nothing are not;
# `check` stays clean. R8: rows 10 places after the last step they need are noted, one note per step, the latest of
# several steps counting and a `-` line counting as the block's first step; rows 9 places after are not. R9: a step of 41 rows, a journey counted once, is noted; one of 40 is not.
# R10: `prereq`, with no PLAN.md too, and the page name BASELINE.md's ## Stack and ARCHITECTURE.md's vid-hosting block, each
# missing and each empty; with both they name nothing; a gap leaves `check` and `ratify` as they were. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-notes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; printf '## Stack\n\n- one web framework\n' > BASELINE.md; printf '\n```vid-hosting\nplatform: one\n```\n' >> ARCHITECTURE.md; }
pl() { sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1; }
notes() { pl page || fail 'page failed'; sed -n '/^## Notes$/,/^## /p' .vid/plan/PLAN-PAGE.md | grep '^- ' || true; }
AH="- stage 2: 1 step can start, by its links, before an earlier stage's last step is done: S05 (wave 3); admission's stage rule holds a step of stage 2 until stage 1 has its candidate"
fresh; [ "$(notes)" = "$AH" ] || fail "the toy's notes are not the one ahead-of-order note: $(notes)"
# ROW-005 into S03, which builds on S01 alone
pt_rs 's/^\(step S02 .*\)ROW-005 /\1/'; pt_rs 's/^\(step S03 .*rows: \)/\1ROW-005 /'
JN='- ROW-005 in S03 does not build on S02 (REQ-001, INV-001)'
[ "$(notes)" = "$(printf '%s\n%s' "$AH" "$JN")" ] || fail "the journey note is not as expected: $(notes)"
pt_check; [ "$PT_RC" -eq 0 ] && grep -q '^planner: clean' "$T/out" || fail 'a note flags the plan'
grep -qE 'does not build on S02|can start' "$T/out" && fail 'check prints a note'
pt_record; printf 'none\n' > "$T/none"; pl review --in "$T/none"; pl page; pl ratify --words 'yes, with the notes' || fail 'ratify is refused with both notes standing'
pl ratified || fail 'ratified fails with both notes standing'
pt_rs 's/^\(step S03 .*\)$/\1 | fakes: S02/'; notes | grep -qxF -- '- ROW-005 in S03 does not build on S02 (REQ-001, INV-001; only a dashed link)' || fail 'the dashed link is not said'
# a plan with neither: S05 waits for S04
fresh; pt_rs 's/^\(step S05 .*builds-on: \)S02/\1S04/'; [ "$(notes)" = '- none' ] || fail "a plan with no note does not say none: $(notes)"
# R7: S05's needs repeat its builds-on; S04's name a further step, then the same two in another order
fresh; pt_rs 's/^needs ROW-017 | -$/needs ROW-017 | S02/'; pt_rs 's/^\(needs ROW-002 .*\) | -$/\1 | S01 S02 S03/'
notes | grep -qxF -- '- S05: every needs line repeats its builds-on (S02); read its rows one by one' || fail "S05's copied needs are not noted: $(notes)"
[ "$(notes | grep -c 'repeats its builds-on')" = 1 ] || fail "a step naming more, or building on nothing, is noted: $(notes)"
pt_record; pt_check; [ "$PT_RC" -eq 0 ] && grep -q '^planner: clean' "$T/out" || fail 'the copied-needs note flags the plan'
pt_rs 's/^\(needs ROW-002 .*\) | S01 S02 S03$/\1 | S03 S02/'; notes | grep -qxF -- '- S04: every needs line repeats its builds-on (S02, S03); read its rows one by one' || fail "S04's copied needs are not noted: $(notes)"
pt_rs 's/^needs ROW-002 \(.*\) | S03 S02$/needs \1 | S03 S02\nneeds ROW-002 | -/'; notes | grep -q '^- S04: every needs line' && fail "a step with one line naming less is noted: $(notes)"
# R8: ten steps more; S15 (place 15) holds rows needing S05 (10 late), S01 and S05 (10) and S01 and S06 (9); S11 and S10 rows needing nothing (10, 9)
fresh; pt_rs 's/ROW-001 //; s/ROW-012 //; s/ROW-013 //; s/ROW-015 //; s/ROW-016 //'; p=05
for k in 06 07 08 09 10 11 12 13 14 15; do pt_after "step S$p" "step S$k | name: step $k | modules: web | builds-on: S05 | rows: - | lane: devagent"; p=$k; done
pt_rs 's/^\(step S10 .*rows: \)- /\1ROW-016 /; s/^\(step S11 .*rows: \)- /\1ROW-015 /; s/^\(step S15 .*rows: \)- /\1ROW-012 ROW-001 ROW-013 /'
for l in 'needs ROW-012 | S05' 'needs ROW-001 | S01 S05' 'needs ROW-013 | S01 S06' 'needs ROW-015 ROW-016 | -'; do pt_after 'step S15' "$l"; done
notes | grep -qxF -- '- S15: 2 rows sit 10 or more steps after the last step they need: ROW-012, ROW-001' || fail "S15's rows held late are not noted: $(notes)"
notes | grep -qxF -- '- S11: 1 rows sit 10 or more steps after the last step they need: ROW-015' || fail "a row that needs nothing is not noted: $(notes)"
[ "$(notes | grep -c 'steps after the last step')" = 2 ] || fail "a row 9 places late is noted: $(notes)"
# R9: S05 gets 40 rows more, ROW-017 among its 41; then ROW-004 (a journey of three transitions) for ROW-017, still 41
fresh; i=101; while [ $i -le 140 ]; do echo "rule | RULE-$i | a rule | sites: every page | 1 | owed: spec-only — ticket | origin: REQ-002"; i=$((i + 1)); done > "$T/r"
sed "/^rule | RULE-005 /r $T/r" INVENTORY.md > I.x && cat I.x > INVENTORY.md; rm I.x; pt_rs 's/^\(step S05 .*rows: ROW-017\) /\1 RULE-101..RULE-140 /'
notes | grep -qxF -- '- S05: 41 rows, over 40; the aim is about 30' || fail "a 41-row step is not noted: $(notes)"
pt_rs 's/^\(step S01 .*\)ROW-004 /\1/; s/^\(step S05 .*rows: \)ROW-017/\1ROW-004/'; notes | grep -qxF -- '- S05: 41 rows, over 40; the aim is about 30' || fail "a journey is not counted once: $(notes)"
pt_rs 's/^\(step S05 .*rows: \)ROW-004 /\1/'; notes | grep -q 'over 40' && fail "a 40-row step is noted: $(notes)"
# R10
SG="the stack: BASELINE.md's \`## Stack\` section is missing or empty; the skeleton ticket quotes it"; HG="the hosting: ARCHITECTURE.md's \`vid-hosting\` block is missing or empty; the skeleton ticket quotes it"
pq() { PQ=$(sh "$CHECKS/planner.sh" prereq 2>&1) || fail "prereq did not exit 0: $PQ"; }
gap() { pq; [ "$PQ" = "$1" ] || fail "prereq says \"$PQ\", not \"$1\""; notes | grep -qxF -- "- $1" || fail "the page does not repeat \"$1\": $(notes)"; }
fresh; pq; [ -z "$PQ" ] || fail "with both, prereq says: $PQ"; notes | grep -q 'skeleton ticket quotes' && fail "with both, a gap is noted: $(notes)"
rm BASELINE.md; gap "$SG"; printf '## Stack\n\n## Other\n\nnothing\n' > BASELINE.md; gap "$SG"
fresh; sed '/^```vid-hosting/,$d' ARCHITECTURE.md > A.x; cp A.x ARCHITECTURE.md; gap "$HG"; printf '```vid-hosting\n```\n' >> ARCHITECTURE.md; gap "$HG"
pt_check; [ "$PT_RC" -eq 0 ] && grep -q '^planner: clean' "$T/out" || fail 'a gap flags the plan'; grep -q 'skeleton ticket quotes' "$T/out" && fail 'check prints a gap'
pl review --in "$T/none"; pl page; pl ratify --words 'yes, with the gap' || fail 'ratify is refused with a gap'; pl ratified || fail 'ratified fails with a gap'
rm A.x BASELINE.md PLAN.md; pq; [ "$PQ" = "$(printf '%s\n%s' "$SG" "$HG")" ] || fail "with no PLAN.md, prereq says: $PQ"
exit 0

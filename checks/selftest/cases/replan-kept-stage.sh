#!/bin/sh
# Purpose: selftest case — a test left in another stage's step is said, and kept (FB-4 A1b). On the form fixture's toy
# (fixtures/form.sh) in GitHub manual, ROW-022 and ROW-023, of stage 2, planned in S04, of stage 1, accepted to place there in the owner's words
# (.vid/tw/to-place, other-stage); S05, of stage 2, posted, so its trigger is raised; ROW-012 reworded and landed. The analysis of the
# plan as it stands lists ROW-022 as kept, with its words, in left and on the page, its trigger `left as it is`; the apply ends
# (exit 0), keeps the row on the list with its words, and the plan is ratified. A candidate that moves it into S05, a step of its own stage,
# lists it as kept no more, and its apply takes it off the list; ROW-023, which that candidate leaves in no step with why, is on the list
# after the apply as no-step, in the apply's words, and the plan is ratified. Env: CHECKS.
# selftest-limit: 1200 s
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-kept-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); P=.vid/next/proposal
fm_toy "$T/toy" || fail 'the toy could not be made'
awk '{ print } /^ROW-020 / && !d { print "ROW-022 | behavior | REQ-003 | anonymous | n/a | A search names the synonym it used. Fails if it does not. | REQ-003 | owed: spec-only — first stage | origin: REQ-003"
  print "ROW-023 | behavior | REQ-003 | anonymous | n/a | A search offers the words it found. Fails if it offers none. | REQ-003 | owed: spec-only — first stage | origin: REQ-003"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-022 and ROW-023 landed'; git rev-parse HEAD > .vid/tw/applied
pt_rs 's/^\(step S04 .*rows:\) /\1 ROW-022 ROW-023 /'; pt_rs '/^needs ROW-017 /{p;s/.*/needs ROW-022 | -/;p;s/.*/needs ROW-023 | -/;}'
for r in ROW-022 ROW-023; do printf '%s\tother-stage\t2026-11-19T10:00:00Z\tleave it in S04\n' "$r"; done > .vid/tw/to-place; cp .vid/tw/to-place "$T/tp0"
sh "$CHECKS/plan.sh" change rows 'S04 holds ROW-022 and ROW-023' --trigger scope-change --evidence "commit:$(git rev-parse --short HEAD)" --expect 'S04 builds it' > "$T/out" 2>&1 || fail 'the plan could not be recorded'
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified with ROW-022 to place in S04'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
fm_post S05 || { cp "$T/post" "$T/out"; fail 'S05 was not posted in manual'; }
reword() { sed "s/$1/$2/" INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam "$3"; am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }; }
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
placed() { mkdir -p "$1/placement"; printf 'placed round=1 listed=1 right=1 stands=0 partly=0 refuted=0 unjudged=0 at=2026-11-03T09:00:00Z\n' > "$1/placement/result"; }
# the plan as it stands
reword 'at the stated size of 10,000 active jobs' 'at the stated size of 20,000 active jobs' 'ROW-012 reworded'
C=$T/c1; mkdir -p "$C"; blk > "$C/block"; printf 'none\n' > "$C/review"; placed "$C"
sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
grep -q "^important${TB}\|^minor${TB}" "$P/triggers" && grep -q "${TB}to-place-active${TB}ROW-022${TB}" "$P/triggers" || { cp "$P/triggers" "$T/out"; fail 'the toy raises no to-place-active trigger of ROW-022'; }
grep "^kept${TB}ROW-022${TB}" "$P/left" | grep -q 'leave it in S04' || { cp "$P/left" "$T/out"; fail 'ROW-022, left in a step of another stage, is in no line of left'; }
cp "$P/REPLAN-PAGE.md" "$T/out"; awk '/^## What it leaves alone/ { on = 1; next } on && /^## / { exit } on' "$P/REPLAN-PAGE.md" | grep 'ROW-022' | grep -q 'leave it in S04' || fail 'the page does not list ROW-022 among what it leaves alone'
awk '/^## The triggers it covers/ { on = 1; next } on && /^## / { exit } on' "$P/REPLAN-PAGE.md" | grep 'to-place-active ROW-022' | grep -q 'left as it is$' || fail "ROW-022's trigger does not read left as it is"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the apply exited $RC"
cmp -s "$T/tp0" .vid/tw/to-place || { cat .vid/tw/to-place > "$T/out"; fail 'the apply does not keep ROW-022 and ROW-023 on the list with their words'; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the plan is not ratified after the apply'
# one moved into a step of its own stage, the other into no step
reword 'leaves the listings as one read does' 'leaves the listings just as one read does' 'ROW-013 reworded'
C=$T/c2; mkdir -p "$C"; blk | sed -e 's/^\(step S04 .*\) ROW-022 /\1 /' -e 's/^\(step S05 .*rows:\) /\1 ROW-022 /' -e 's/^\(step S04 .*\) ROW-023 /\1 /' -e '/^needs ROW-023 /d' > "$C/block"; printf 'no-step\tROW-023\tno step of its stage builds what it checks\n' > "$C/left"; printf 'none\n' > "$C/review"; placed "$C"
for s in S04 S05; do printf '%s\tscope-change\tcommit:%s\tROW-022 goes to its own stage\n' "$s" "$(git rev-parse --short HEAD)"; done > "$C/changes"
sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis of ROW-022 moved to its own stage was refused'
! grep -q "^kept${TB}ROW-022" "$P/left" || { cp "$P/left" "$T/out"; fail 'ROW-022, moved into a step of its own stage, is listed as kept'; }
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it too' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the second apply exited $RC"
! grep -q '^ROW-022' .vid/tw/to-place || { cat .vid/tw/to-place > "$T/out"; fail 'ROW-022, in a step of its own stage, is still on the list'; }
[ "$(grep '^ROW-023' .vid/tw/to-place | cut -f2,4)" = "no-step${TB}Yes, apply it too" ] || { cat .vid/tw/to-place > "$T/out"; fail "ROW-023, left in no step, is not on the list as no-step in the apply's words"; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the plan is not ratified after the second apply'
exit 0

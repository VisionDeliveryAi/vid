#!/bin/sh
# Purpose: selftest case — one landing step (GM-4 F9, its land.sh half): a re-cut's stage move, the plan change and the
# ratification stand once, in checks/land.sh, and both modes call them. Read: the plan block's rewrite (PCX) and the stage move
# (stmove) are defined in land.sh alone; replan.sh records no plan change, review or ratification of its own and calls
# `land.sh step`; land.sh calls plan.sh change rows, planner.sh reratify and planner.sh ratify once each. Then GitHub auto's
# landing on the writer's toy (fixtures/tw-toy.sh): a draft adding ROW-021 to S04, S02 and S03 closed, lands on the owner's yes,
# its plan change recorded as the owner's yes to draft 1 and the plan re-ratified in those words, its output as before (no
# `plan`, `answer` or `ratified` line). And GitHub manual's apply step on the switch toy (fixtures/manual.sh), RUN-STATE at
# `stage: 0` with stage 0 closed, inside a replan stage: `land.sh step --stages HEAD --block <the plan as recorded> --if-new …
# --review <none> --words …` prints `stage 1` and `ratified` and no `plan` line (the block is the newest recorded plan), and
# moves RUN-STATE's stage: to 1; then with no block, `--evidence commit:<HEAD>`, it prints `plan <the newest plan change's
# hash>` and `ratified`. A step given no ratification, or two, is a usage error (exit 2). And replan.sh edits no `stage:` line
# itself and passes `--stages "$TGT"` to the step; with RUN-STATE.md unreadable, the step refuses, exit 1, `the plan change was
# refused (RUN-STATE's plan could not be written)`, naming no missing file. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); T0=$T; trap 'rm -rf "$T0" "$T"' EXIT
fail() { echo "land-one-step: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
: > "$T/out"; LS=$CHECKS/land.sh
# read: one copy of each part, in land.sh
for d in '^PCX=' '^stmove()'; do x=$(grep -l "$d" "$CHECKS"/*.sh | sed 's|.*/||' | paste -sd ' ' -); [ "$x" = land.sh ] || fail "$d is defined in: ${x:-no script} (land.sh alone holds it)"; done
for p in 'plan.sh" change' 'planner.sh" ratify' 'planner.sh" review' 'planner.sh" reratify'; do ! grep -q "$p" "$CHECKS/replan.sh" || fail "replan.sh still runs $p itself"; done
grep -q 'land\.sh" step' "$CHECKS/replan.sh" || fail 'replan.sh apply does not call land.sh step'
# the apply's stage move is the step's: replan.sh edits no stage: line itself, and hands a pending re-cut's target to the step
! grep -n 's/^stage:' "$CHECKS/replan.sh" > "$T/out" || fail 'replan.sh moves RUN-STATE'"'"'s stage: itself'
grep -q -- '--stages "\$TGT"' "$CHECKS/replan.sh" || fail 'replan.sh apply hands no --stages "$TGT" to land.sh step'
for p in 'plan.sh" change rows' 'planner.sh" reratify' 'planner.sh" ratify'; do n=$(grep -c "$p" "$LS" || :); [ "$n" = 1 ] || fail "land.sh runs $p in $n places, not one"; done
# GitHub auto's landing
. "$CHECKS/selftest/fixtures/tw-toy.sh"
tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
printf 'none\n' > "$T/rv"; sed "s/^open-tickets: 2$/open-tickets: 9/" .vid/tw/settings > "$T/st" && cp "$T/st" .vid/tw/settings
tw_start S02 || fail "S02 was refused: $(cat "$T/start")"; tw_start S03 || fail "S03 was refused: $(cat "$T/start")"
tw_closed S02; tw_closed S03; tw_start S04 || fail "S04 was refused: $(cat "$T/start")"
awk '/^ROW-020 \|/ { print; print "ROW-021 | behavior | REQ-001 | (process) | n/a | A job read twice in a day is listed once with its first read time. Fails if a second read moves its time. | REQ-001 | owed: spec-only — ticket"; next } { print }' INVENTORY.md > "$T/inv" && cp "$T/inv" INVENTORY.md
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | sed 's/^\(step S04 .*rows: [^|]*RULE-004\) /\1 ROW-021 /; s/^\(needs ROW-002 .*RULE-004\) /\1 ROW-021 /' > "$T/plan"
grep -q 'RULE-004 ROW-021 |' "$T/plan" || fail "the plan block does not place ROW-021 in S04"
sh "$LS" draft --review "$T/rv" --why 'ROW-021 added to S04' --plan "$T/plan" > "$T/out" 2>&1 || fail 'the draft was refused'; grep -qx 'draft 1' "$T/out" || fail 'no draft 1'
n0=$(grep -c '^plan-change ' .vid/metrics-events || :)
sh "$LS" 1 --words 'Yes, land it' > "$T/out" 2>&1 || fail "GitHub auto's landing was refused"
grep -q '^landed 1 at ' "$T/out" || fail 'no landed line'
! grep -Eq '^(plan|answer|ratified)( |$)' "$T/out" || fail "GitHub auto's landing prints the step's own lines"
[ "$(grep -c '^plan-change ' .vid/metrics-events)" = $((n0 + 1)) ] || fail "the landing recorded no plan change, or more than one"
E=$(grep '^plan-change ' .vid/metrics-events | tail -n 1); D=$(printf '%s\n' "$E" | sed -n 's/.* decision=\([^ ]*\) .*/\1/p')
printf '%s\n' "$E" | grep -q "why=\"the owner's yes to draft 1: " && grep -qx 'trigger=owner-answer' ".vid/plans/decisions/$D.why" || { printf '%s\n' "$E" > "$T/out"; fail "the landing's plan change is not the owner's yes to draft 1"; }
tail -n 1 .vid/plan/ratified | grep -q 'words=Yes, land it' || { tail -n 1 .vid/plan/ratified > "$T/out"; fail 'the landing did not re-ratify the plan in the words of its yes'; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'not ratified after the landing'
# GitHub manual's apply step
T=$(mktemp -d); . "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
mn_project "$T/p"; : > "$T/out"
M1=$(gh_issue 'Skeleton'); mn_ticket "$M1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$M1" "$T/t1" body 2; printf '%s S01\n' "$M1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || { cp "$T/mo" "$T/out"; fail "the switch exited $MN_RC"; }
printf 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1\n' >> .vid/tw/handed
awk '{ print } /^run:/ { print "stage: 0" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
grep -qx 'stage: 0' .vid/RUN-STATE.md || fail 'RUN-STATE holds no stage: 0 line to move'
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' > "$T/blk"
sh "$CHECKS/event.sh" "stage name=replan state=start session=one-step records=29" > "$T/out" 2>&1 || fail 'no replan stage'
RC=0; sh "$LS" step --why 'x' --trigger scope-change --expect 'y' --words 'yes' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "a step with no ratification was not a usage error ($RC)"
RC=0; sh "$LS" step --why 'x' --trigger scope-change --expect 'y' --review "$T/review" --reratify a b c --words 'yes' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "a step with two ratifications was not a usage error ($RC)"
n0=$(grep -c '^plan-change ' .vid/metrics-events || :)
sh "$LS" step --stages HEAD --block "$T/blk" --if-new --why 'the re-plan applied on the owner yes: yes, the toy' --trigger scope-change --expect 'the plan as it is' --review "$T/review" --words 'yes, the toy' > "$T/out" 2>&1 || fail "GitHub manual's apply step was refused"
grep -qx 'stage 1' "$T/out" || fail "the step did not move RUN-STATE's stage: to 1"
grep -qx 'stage: 1' .vid/RUN-STATE.md || fail "RUN-STATE's stage: is not 1"
! grep -q '^plan ' "$T/out" && [ "$(grep -c '^plan-change ' .vid/metrics-events)" = "$n0" ] || fail 'a plan change was recorded for the plan as it is recorded'
grep -qx ratified "$T/out" || fail 'the step did not ratify'
sh "$CHECKS/planner.sh" ratified > "$T/x" 2>&1 || { cp "$T/x" "$T/out"; fail 'not ratified after the step'; }
sh "$LS" step --why 'the re-plan applied on the owner yes: yes, again' --trigger owner-answer --evidence "commit:$(git rev-parse --short=12 HEAD)" --expect 'the plan as it is' --review "$T/review" --words 'yes, again' > "$T/out" 2>&1 || fail "the step's plan change was refused"
H=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p')
[ "$(grep -c '^plan-change ' .vid/metrics-events)" = $((n0 + 1)) ] && grep -qx "plan $H" "$T/out" || fail "the step's plan change is not recorded and named (plan $H)"
grep -qx ratified "$T/out" || fail 'the step did not ratify after its plan change'
# RUN-STATE.md unreadable for one step: its plan block cannot be written, and the step says so, naming nothing missing
chmod 000 .vid/RUN-STATE.md; RC=0; sh "$LS" step --block "$T/blk" --why 'the re-plan applied: yes, once more' --trigger owner-answer --expect 'the plan as it is' --review "$T/review" --words 'yes, once more' > "$T/out" 2>&1 || RC=$?; chmod 644 .vid/RUN-STATE.md
[ "$RC" = 1 ] || fail "the step did not refuse a plan block it could not write ($RC)"
grep -qx "ViD land: the plan change was refused (RUN-STATE's plan could not be written)" "$T/out" || fail 'the refusal does not say the plan block could not be written'
! grep -qi 'no such file' "$T/out" || fail 'the refusal reads a file the step never made'
exit 0

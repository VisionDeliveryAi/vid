#!/bin/sh
# Purpose: selftest case — admission in ticket mode, F19 (v0.26.10.12.3 R6). On TW's toy (the
# planner toy in its plan session: S01 the skeleton of stage 0, S02 and S03 building on it, S04 on both, S05 of stage 2;
# open-tickets: 2) `plan.sh start`, reading only .vid/tw/handed, .vid/tw/log and .vid/budget: an unrecorded block is
# refused; S01 is admitted with `step-start step=S01 plan=<hash>`; S02 is refused by the stage rule in stage 0, and by
# rule B once stage 0 has its candidate, naming S01 and its rows; admitted once S01 is closed. S03 is refused by the
# open-ticket limit (S01's ticket open at the newest sync, S02 started with none published), and admitted once the
# sync shows S01's closed; S04 by the limit again, two tickets published after the sync. A started step is admitted
# again. In a fresh toy at unverified-rows=15: S03 is refused by rule A (S02's 11 open rows and S03's 13), and admitted
# when S02's rows are accepted; stacks=2 (60 × 2) admits it at unverified-rows=150; a recorded split of S02's rows into
# a new step S06 that builds on the unclosed S03 is admitted without A and B; rows added to the started S02 are refused
# by rule A. S05 is refused by the stage rule in stage 1 and admitted once stage 1 has its candidate; a row the plan's
# vid-rows moved: to stage 2, split into S06, recorded and ratified, is refused in stage 1 (its stage is planner.sh
# rows'), and so is a seam moved: so; a started step is admitted again once its row is moved so. Under breadth first
# the graded gate refuses S02 while S01 is not closed (by=graded), reading the handed records. `ticket:<n>` evidence
# resolves only against a `published <n>` line. Each refusal is recorded `refused phase=admission by=`.
# checks/evidence.sh and checks/metrics.sh are never called. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "plan-admit-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
P=$CHECKS/plan.sh
st() { sh "$P" start "$1" > "$T/out" 2>&1; }
admitted() { st "$1" || fail "$1 was refused $2"; grep -q "^step-start step=$1 plan=[0-9a-f]* " .vid/metrics-events || fail "no step-start for $1"; }
refused() { if st "$1"; then fail "$1 was admitted $3"; fi; grep -qF "$4" "$T/out" || fail "the refusal of $1 $3 does not say: $4"
  tail -n 1 .vid/metrics-events | grep -q "^refused phase=admission by=$2 .* step=$1 " || fail "the refusal of $1 $3 is not recorded by=$2"; }
log() { printf '%s at=2026-11-03T10:00:00Z\n' "$1" >> .vid/tw/log; }
tw_toy "$T/a"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # the stage rule reads them at the home
# an unrecorded block is refused
cp .vid/RUN-STATE.md "$T/rs"; pt_rs 's/rows: ROW-017 /rows: ROW-017 ROW-020 /'
refused S01 unrecorded-plan 'with the block changed' 'the plan changed without a recorded change'; cat "$T/rs" > .vid/RUN-STATE.md
admitted S01 'in stage 0'
refused S02 stage 'in stage 0' 'S02 holds rows outside stages 0 to 0'
tw_hand 'candidate 0'; tw_hand 'staged 0'
refused S02 rule-B 'with S01 open' 'S02 builds on S01, which is not closed, and its rows ROW-003 ROW-004 are not owed'
tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; tw_closed S01
log 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004'; log 'sync main=abc open=1'
admitted S02 'with S01 closed, one ticket open'
refused S03 open-tickets 'at the limit' 'the open-ticket limit: 2 tickets open or owed'
log 'sync main=abc open=-'; admitted S03 "once S01's ticket closed"
log 'published 2 kind=step step=S02 rows=ROW-001'; log 'published 3 kind=step step=S03 rows=ROW-006'
refused S04 open-tickets 'with two published after the sync' '2 tickets open or owed'
st S02 || fail 'a started step was refused'; grep -q 'S02 already started' "$T/out" || fail 'a started step is not said to be started'
# evidence ticket:<n>
pt_rs 's/^\(step S05 .*rows: ROW-017\)/\1 ROW-020/'
if sh "$P" change rows 'ROW-020 into S05' --trigger test-evidence --evidence ticket:9 --expect 'S05 holds it' > "$T/out" 2>&1; then fail 'ticket:9, never published, resolved'; fi
sh "$P" change rows 'ROW-020 into S05' --trigger test-evidence --evidence ticket:3 --expect 'S05 holds it' > "$T/out" 2>&1 || fail 'ticket:3, published, did not resolve'
# rule A, its ceiling, the split and rows added — a fresh toy at unverified-rows=15
cd "$T"; rm -rf "$T/gh" "$T/code.git" "$T/dev"; tw_toy "$T/b"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/; tw_hand 'candidate 0'; tw_hand 'staged 0'; sed 's/^open-tickets: 2/open-tickets: 9/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
admitted S01 'in a fresh toy'; tw_closed S01; admitted S02 'with S01 closed'
printf 'unverified-rows=15\n' > .vid/budget
refused S03 rule-A 'over the ceiling' 'rule A (tickets): 23 open rows would exceed the ceiling of 15 (11 rows of started steps'   # 0.26.10.29.2 (R9): S01's 2 rows accepted at its close
printf 'stacks=2\nunverified-rows=150\n' > .vid/budget; admitted S03 'at unverified-rows=150, capped at 60 × 2'
grep -q 'admitting under 120' "$T/out" || fail 'the ceiling is not capped at 60 × stacks=2'; printf 'unverified-rows=15\n' > .vid/budget
pt_rs 's/^\(step S02 .*\)rows: ROW-001 ROW-005 ROW-008 /\1rows: /'
pt_rs 's/^\(step S05 .*\)$/\1\nstep S06 | name: the first jobs, read and sent | modules: ingest digest | builds-on: S03 | rows: ROW-001 ROW-005 ROW-008 | lane: devagent/'
sh "$P" change split 'S02 split' --trigger discovered-dependency --evidence step:S02 --expect 'S06 builds alone' > "$T/out" 2>&1 || fail 'the split was refused'
admitted S06 'though S03 is not closed (its rows all belonged to a started step)'; grep -q 'neither rule applies' "$T/out" || fail 'the split is not said to skip rules A and B'
pt_rs 's/^\(step S04 .*\)rows: ROW-002 /\1rows: /'; pt_rs 's/^\(step S02 .*rows: .*\)ROW-012 /\1ROW-012 ROW-002 /'
if sh "$P" change rows 'ROW-002 into the started S02' --trigger cost --evidence step:S02 --expect 'S02 holds it' > "$T/out" 2>&1; then fail 'rows added to a started step over the ceiling were accepted'; fi
grep -q 'rows added to the started step S02 are admitted like a new step' "$T/out" || fail 'the added rows are not refused by rule A'
# the stage: S05 waits for stage 1's candidate
cd "$T"; rm -rf "$T/gh" "$T/code.git" "$T/dev"; tw_toy "$T/c"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/; tw_hand 'candidate 0'; tw_hand 'staged 0'
admitted S01 'in the third toy'; tw_closed S01; admitted S02 'in the third toy'; tw_closed S02
pt_rs 's/^stage: 0$/stage: 1/'
refused S05 stage 'in stage 1' 'S05 holds rows outside stages 0 to 1'
log 'published 1 kind=skeleton step=S01'; log 'published 2 kind=step step=S02'; log 'sync main=abc open=-'
# a planner moved: stage (F19): ROW-002 moved to stage 2 and split into S06, recorded and ratified, is refused in stage 1
pt_after 'standing work' 'ROW-002 | moved: STAGE-2 A-005'; pt_rs 's/^\(step S04 .*\)rows: ROW-002 /\1rows: /'
pt_rs 's/^\(step S05 .*\)$/\1\nstep S06 | name: the saved-search limit | modules: digest | builds-on: S02 | rows: ROW-002 | lane: devagent/'
sh "$P" change split 'ROW-002 moved to stage 2' --trigger scope-change --evidence step:S04 --expect 'S06 waits for stage 2' > "$T/out" 2>&1 || fail 'the move was refused'
tw_ratify 'Yes, ROW-002 to stage 2' || fail 'the move was not ratified'; refused S06 stage 'with ROW-002 moved to stage 2' 'S06 holds rows outside stages 0 to 1 (the current stage): ROW-002.'
# a seam moved: to stage 2 and split into S07 is refused in stage 1
pt_after 'standing work' 'SEAM-001 | moved: STAGE-2 A-005'; pt_rs 's/^\(step S03 .*\) SEAM-001 /\1 /'
pt_rs 's/^\(step S06 .*\)$/\1\nstep S07 | name: the mail seam | modules: mail | builds-on: S01 | rows: SEAM-001 | lane: devagent/'
sh "$P" change split 'SEAM-001 moved to stage 2' --trigger scope-change --evidence step:S03 --expect 'S07 waits for stage 2' > "$T/out" 2>&1 || fail 'the seam move was refused'
tw_ratify 'Yes, SEAM-001 to stage 2' || fail 'the seam move was not ratified'; refused S07 stage 'with SEAM-001 moved to stage 2' 'S07 holds rows outside stages 0 to 1 (the current stage): SEAM-001.'
# ROW-018 split into S08 and S08 admitted, then ROW-018 moved: to stage 2 — S08 is admitted again
pt_rs 's/^\(step S04 .*\) ROW-018 /\1 /'; pt_rs 's/^\(step S07 .*\)$/\1\nstep S08 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent/'
sh "$P" change split 'ROW-018 in its own step' --trigger scope-change --evidence step:S04 --expect 'S08 ships it' > "$T/out" 2>&1 || fail 'the split of ROW-018 was refused'
tw_ratify 'Yes, ROW-018 alone' || fail 'the split of ROW-018 was not ratified'; admitted S08 'in stage 1'
pt_after 'standing work' 'ROW-018 | moved: STAGE-2 A-005'; pt_rs 's/^step S08 | name: the failure log /step S08 | name: the failure log, later /'
sh "$P" change other 'ROW-018 moved to stage 2' --trigger scope-change --evidence step:S08 --expect 'S08 keeps its admission' > "$T/out" 2>&1 || fail 'the move of ROW-018 was refused'
tw_ratify 'Yes, ROW-018 to stage 2' || fail 'the move of ROW-018 was not ratified'
st S08 || fail 'the started S08 was refused once its ROW-018 moved to stage 2'; grep -q 'S08 already started' "$T/out" || fail 'the started S08 is not said to be started'
tw_hand 'candidate 1'; admitted S05 "once stage 1 has its candidate"
# breadth first: the graded gate reads the handed closed steps
cd "$T"; rm -rf "$T/gh" "$T/code.git" "$T/dev"; tw_toy "$T/d"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/; tw_hand 'candidate 0'; tw_hand 'staged 0'
pt_rs 's/^plan: required$/plan: required\nstrategy: breadth-first/'
admitted S01 'under breadth first'
refused S02 graded 'under breadth first with S01 open' 'S01 is not closed: never closed'
tw_closed S01; admitted S02 'under breadth first with S01 closed'
exit 0

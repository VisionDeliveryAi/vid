#!/bin/sh
# Purpose: selftest case — in GitHub manual a step is admitted with no hold, in a stage of its own (GM-2 T2). On the ticket
# writer's toy (fixtures/tw-toy.sh), with stages.sh and prd.sh at its home so the stage rule reads, open-tickets: 1 and the skeleton S01 started with no ticket, so the limit is reached, and
# the planning sitting ended, as /vid mode leaves it: S05, of stage 2 while stage 0 is current, building on S02, which is not
# closed, past the limit, is admitted by `plan.sh start` in manual, its step-start recorded; the start opened a `stage
# name=replan` of its own and ended it, so the gate reads off after; a start refused (no such step) records no start and ends
# its stage too. `plan.sh change` in manual, with no stage open, records the owner's change with the trigger owner-answer, the
# evidence ticket:<n> of a published ticket and the owner's words as its why, in a stage of its own, ended after; a change
# refused (evidence naming no published ticket) ends its stage too. A caller that holds a stage open is left alone: S03's
# start inside an open planning sitting opens and ends no stage, the sitting still open after. Under breadth first, S04,
# building on the unclosed S02 and S03, is admitted past the graded gate, in a stage of its own. In GitHub auto, inside a
# planning sitting, with the plan as recorded, the same S05 is refused by the stage rule (refused by=stage) and no start is
# recorded; plan-admit-tickets proves each other hold in auto alone (rule B, the open-ticket limit, rule A, the graded gate).
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-admit-unheld: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
P() { RC=0; sh "$CHECKS/plan.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
at() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
ev() { printf '%s at=%s\n' "$1" "$(at)" >> .vid/metrics-events; }
starts() { grep -c "^step-start step=$1 " .vid/metrics-events || true; }
reps() { grep -c '^stage name=replan ' .vid/metrics-events || true; }
# ended: every replan stage opened since <count> has its end, of the same session, and the gate reads off
ended() { awk -v k="$1" '$1 == "stage" && / name=replan / { n++; if (n <= k) next; s = ""; for (i = 2; i <= NF; i++) if ($i ~ /^session=/) s = $i
    if (/ state=start /) o[s]++; else if (/ state=end /) o[s]-- } END { for (s in o) if (o[s]) exit 1; exit !(n > k) }' .vid/metrics-events || fail "$2: its own replan stage was not opened and ended"
  if sh "$CHECKS/plan.sh" gate > /dev/null 2>&1; then fail "$2: the gate reads on after the move"; fi; }
tw_toy "$T/toy"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # the stage rule reads them at the home
sed 's/^open-tickets: .*/open-tickets: 1/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
P start S01; [ "$RC" = 0 ] && [ "$(starts S01)" = 1 ] || fail 'the skeleton S01 was not started'
ev 'stage name=plan state=end session=S1'; cp .vid/metrics-events "$T/ev0"; cp .vid/RUN-STATE.md "$T/rs0"
git rev-parse HEAD > .vid/tw/applied
cp .vid/plan/setup "$T/setup0"
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
# manual: S05 admitted past its stage, its unclosed builds-on and the limit, in a stage of its own, ended after
K=$(reps); P start S05; [ "$RC" = 0 ] || fail "in manual S05 was refused ($RC)"
[ "$(starts S05)" = 1 ] || fail 'in manual S05 was not admitted: no step-start recorded'
grep -q 'admitted S05' "$T/out" || fail 'in manual the start does not say S05 is admitted'
ended "$K" 'the start of S05'
# a refused start records nothing, and ends its stage
K=$(reps); P start S99; [ "$RC" = 1 ] || fail "in manual a start of no step was not refused ($RC)"
[ "$(starts S99)" = 0 ] || fail 'a refused start recorded a start'; ended "$K" 'a refused start'
# a plan change in manual: owner-answer, ticket:<n>, the owner's words
printf 'published 7 kind=step step=S02 rows=ROW-001 plan=x base=none export=x parts=1 at=%s\n' "$(at)" >> .vid/tw/log
pt_rs 's/^\(step S05 | name: \)synonym-aware search/\1search by other names/'
K=$(reps); P change rows 'Yes, call it search by other names' --trigger owner-answer --evidence ticket:7 --expect 'the step named as the owner said'
[ "$RC" = 0 ] || fail "in manual the owner's plan change was refused ($RC)"
grep -q '^plan-change what=rows .* why="Yes, call it search by other names"' .vid/metrics-events || fail "the plan change is not recorded with the owner's words"
D=$(sed -n 's/.* decision=\([^ ]*\) why="Yes, call it search.*/\1/p' .vid/metrics-events | tail -n 1)
grep -qx 'trigger=owner-answer' ".vid/plans/decisions/$D.why" && grep -qx 'evidence=ticket:7' ".vid/plans/decisions/$D.why" || fail 'the change does not carry owner-answer and ticket:7'
ended "$K" 'the plan change'
pt_rs 's/^\(step S05 | name: \)search by other names/\1search by any name/'
K=$(reps); P change rows 'Yes, any name' --trigger owner-answer --evidence ticket:99 --expect 'the step named'
[ "$RC" = 1 ] || fail "a change naming no published ticket was not refused ($RC)"; ended "$K" 'a refused plan change'
pt_rs 's/^\(step S05 | name: \)search by any name/\1search by other names/'
# a caller that holds a stage open is left alone
ev 'stage name=plan state=start session=caller records=29'; K=$(reps)
P start S03; [ "$RC" = 0 ] && [ "$(starts S03)" = 1 ] || fail "in manual S03 was not admitted inside the caller's sitting"
[ "$(reps)" = "$K" ] || fail "a start inside the caller's open sitting opened a stage of its own"
sh "$CHECKS/plan.sh" gate > /dev/null 2>&1 || fail "the caller's sitting was ended by the start"
ev 'stage name=plan state=end session=caller'
# breadth first: S04, building on the unclosed S02 and S03, past the graded gate
pt_rs 's/^plan: required$/plan: required\nstrategy: breadth-first/'; grep -q '^strategy: breadth-first' .vid/RUN-STATE.md || fail 'the toy is not breadth first'
K=$(reps); P start S04; [ "$RC" = 0 ] && [ "$(starts S04)" = 1 ] || fail "in manual under breadth first S04 was not admitted ($RC)"
ended "$K" 'the start of S04 under breadth first'
# auto: inside a planning sitting, the same S05 refused, nothing recorded
cp "$T/ev0" .vid/metrics-events; cp "$T/setup0" .vid/plan/setup; cp "$T/rs0" .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="auto" words="DevAgent" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
ev 'stage name=plan state=start session=S2 records=29'
P start S05; [ "$RC" = 1 ] || fail "in auto S05 was not refused ($RC)"
[ "$(starts S05)" = 0 ] || fail 'in auto the refused S05 has a start recorded'
grep -q 'holds rows outside stages' "$T/out" || fail 'in auto S05 is not refused by the stage rule'
tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=stage .* step=S05 ' || fail 'in auto the refusal of S05 is not recorded by=stage'
exit 0

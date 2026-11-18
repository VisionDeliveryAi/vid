#!/bin/sh
# Purpose: selftest case — the owner's re-cut of the stages through the door in ticket mode (0.26.10.29.2, R2), checks/land.sh with
# the queue and the writer on the writer's toy and the fake gh. A re-cut moving the support address (REQ-012, its rows ROW-006 and
# ROW-019 of S03, whose ticket is open) to stage 2 is drafted in the working tree (STAGES.md, the owner's answer row in PRD.md, the plan
# block in a file with the rows in a new stage-2 step), commits nothing and is asked once; the owner's yes lands it through the hooks,
# its law commit citing the answer (commit-msg: checks/stages.sh msg), as a scope-change, with the stage-cut event; the writer's gate
# stays open and the open ticket is amended to drop the moved rows. The run's gate is on throughout and no stage event comes from the
# verb; the skill's ticket-mode branch says so. A stage 3 already empty in the base, which the re-cut never touches, does not
# block it. The skill never says STAGES.md's commit touches nothing else or is alone (0.26.10.29.4 phase 4 R5: INVENTORY.md may ride
# in the same law commit). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "recut-door: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
# the base cut already holds an empty stage 3, which the re-cut below never touches (it does not block the re-cut)
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Later | features: -" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; g add STAGES.md && g commit -qm 'the cut, with an empty stage 3'; tw_ratify 'Yes, publish it' || fail 'the toy was not ratified again'
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
LS=$CHECKS/land.sh; QS=$CHECKS/queue.sh
gate() { sh "$CHECKS/plan.sh" gate > "$T/g" 2>&1 || fail "the run's gate is off $1: $(cat "$T/g")"; }
tw_start S03 || fail "S03 was refused: $(cat "$T/start")"; tw_post step S03 || fail "S03's ticket: $(cat "$T/werr")"; N3=$TW_N
# the re-cut, in the working tree: REQ-012 split to stage 2, the owner's answer row, the plan block with ROW-006 and ROW-019 in S06
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-012 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md
{ cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-301 | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: the support address waits for stage 2 | settles: contract\n```\n'; } > "$T/p" && cp "$T/p" PRD.md
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | awk '/^step S03 / || /^needs ROW-006 / { gsub(/ ROW-006| ROW-019/, "") } { print }
  /^step S05 / { print "step S06 | name: the support address | modules: web mail | builds-on: S01 | rows: ROW-006 ROW-019 | lane: devagent" } /^needs ROW-017 / { print "needs ROW-006 ROW-019 | -" }' > "$T/plan"
printf 'none\n' > "$T/rv"; H0=$(git rev-parse HEAD); gate 'before the draft'
RC=0; sh "$LS" draft --review "$T/rv" --why "/vid stage: the support address moves to stage 2, in the owner's words" --plan "$T/plan" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && grep -qx 'draft 1' "$T/out" || fail "the re-cut was not drafted ($RC)"
[ "$(git rev-parse HEAD)" = "$H0" ] && [ -z "$(git status --porcelain -- STAGES.md PRD.md)" ] || fail 'the draft committed, or left the tree changed'; gate 'after the draft'
sh "$QS" ask draft 1 > "$T/out" 2>&1 || fail 'the draft was not asked'; QN=$(sed -n 's/^asked \(Q[0-9]*\) draft 1$/\1/p' "$T/out"); [ -n "$QN" ] || fail 'no Q line for the re-cut'; gate 'after the ask'
# the landing, through a commit-msg hook that refuses a membership change citing no owner answer
mkdir -p "$T/hk"; printf '#!/bin/sh\nexec sh "%s/stages.sh" msg "$1"\n' "$CHECKS" > "$T/hk/commit-msg"; chmod +x "$T/hk/commit-msg"; git config core.hooksPath "$T/hk"
RC=0; sh "$QS" answer "$QN" yes 'Yes, re-cut it' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut did not land ($RC)"; gate 'after the landing'
git log -1 --format=%B -- STAGES.md | grep -qx 'Answers: A-301' || fail "the law commit cites no answer: $(git log -1 --format=%B -- STAGES.md)"
git cat-file -e HEAD:STAGES.md && git show HEAD:STAGES.md | grep -qx 'split: REQ-012 -> STAGE-2' || fail 'the re-cut is not in HEAD'
D=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/.* decision=\([^ ]*\) .*/\1/p'); grep -qx 'trigger=scope-change' ".vid/plans/decisions/$D.why" || fail "the landing's plan change is not a scope-change: $(grep '^trigger=' ".vid/plans/decisions/$D.why")"
B=$(git rev-parse HEAD:STAGES.md); grep -q "^stage-cut n=4 answer=A-301 blob=$B " .vid/metrics-events || fail "no stage-cut event for the re-cut: $(grep '^stage-cut' .vid/metrics-events)"
! grep -q '^stage name=stage ' .vid/metrics-events || fail 'a stage event came from the re-cut'
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'not ratified after the re-cut'; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail "the writer's gate is shut after the re-cut"
# publishing goes on: S03's open ticket is amended to drop the rows the re-cut moved
sh "$CHECKS/github.sh" spec-export > /dev/null 2>&1; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'due failed'; grep -qx "amend $N3" "$T/out" || fail "S03's open ticket is not amended"
sh "$CHECKS/writer.sh" write amend "$N3" > "$T/out" 2>&1 || fail 'the amendment was refused'; M=$(sed -n 1p ".vid/tw/out/amend-$N3.meta")
case ",$(printf '%s' "$M" | tr ' ' '\n' | sed -n 's/^rows=//p')," in *,ROW-006,*|*,ROW-019,*) fail "the open ticket keeps a row moved to stage 2: $M" ;; esac
# the skill: in ticket mode the verb records no stage event and drafts through the door (a project's layout has no skills/)
SK=$CHECKS/../skills/vid-stage/SKILL.md; if [ -f "$SK" ]; then
  grep -q '^\*\*Ticket mode (0.26.10.29.2, R2)\.\*\*' "$SK" || fail 'the vid-stage skill has no ticket-mode branch'
  tr '\n' ' ' < "$SK" | grep -q 'records no stage event' && tr '\n' ' ' < "$SK" | grep -q 'land.sh draft --review' && tr '\n' ' ' < "$SK" | grep -q '/vid stage: ' || fail "the skill's ticket-mode branch does not say it records no stage event and drafts through land.sh"
  tr '\n' ' ' < "$SK" | grep -q 'Outside ticket mode, record `sh checks/event.sh "stage' || fail "the skill's stage events are not left out in ticket mode"
  # 0.26.10.29.4 (phase 4 R5): INVENTORY.md and STAGES.md may land in one law commit, so the skill never says STAGES.md's commit is alone
  ! tr '\n' ' ' < "$SK" | tr -s ' ' | grep -qE "STAGES\.md's commit touches nothing else|Commit STAGES\.md alone" || fail "the vid-stage skill still says STAGES.md's commit touches nothing else or is alone"; fi
exit 0

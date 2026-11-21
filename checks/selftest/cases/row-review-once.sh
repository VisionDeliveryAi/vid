#!/bin/sh
# Purpose: selftest case — the row review, one skill (GM-4 F12, A16). vid-row-review holds the fresh agent's review of the rows ViD
# adds, once: the reviewer spawned with the pass brief (skills/vid-plan/passes/row-review.md), PRD.md, PLAN.md and the rows verbatim
# and nothing else, in the foreground, its output saved for the caller's script. vid-plan, vid-mode and vid-replan invoke it where
# they review, and /vid next's implement-replan `--review` is made by it (the move's form is vid-replan's); none of them holds a
# copy: no spawn of its own, no pass brief named. Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-plan" ] || { echo 'row-review-once: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "row-review-once: $*" >&2; exit 1; }
V=$S/vid-row-review/SKILL.md; [ -f "$V" ] || fail 'there is no vid-row-review skill'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
one() { tr '\n' ' ' < "$1" | tr -s ' '; }
one "$V" > "$T/v"
grep -q '^name: vid-row-review$' "$V" || fail 'vid-row-review does not name itself'
for p in 'Spawn a fresh agent' 'skills/vid-plan/passes/row-review.md, PRD.md, PLAN.md' 'verbatim, and nothing else' 'run_in_background: false' 'planner.sh rows --added' 'planner.sh rows --added --at HEAD'; do
  grep -qF -- "$p" "$T/v" || fail "vid-row-review lacks: $p"; done
[ -f "$S/vid-plan/passes/row-review.md" ] || fail 'the pass brief skills/vid-plan/passes/row-review.md is gone'
# each caller invokes it, and holds no copy
for k in vid-plan vid-mode vid-replan; do G=$S/$k/SKILL.md; [ -f "$G" ] || fail "there is no $k skill"
  one "$G" | grep -qF 'Invoke the `vid-row-review` skill' || fail "$k does not invoke the vid-row-review skill"
  for p in 'Spawn a fresh agent' 'spawn a fresh agent' 'passes/row-review.md' 'as /vid plan does' "as \`skills/vid-mode/SKILL.md\`'s step 2 does"; do
    ! one "$G" | grep -qF -- "$p" || fail "$k still holds the review's text: $p"; done; done
N=$S/vid-next/SKILL.md
for p in 'passes/row-review.md' "as the \`vid-replan\` skill's step 3 makes it" 'spawn a fresh agent'; do ! one "$N" | grep -qF -- "$p" || fail "vid-next still holds the review's text: $p"; done
awk '/^## GitHub manual/ { on = 1 } on' "$S/vid-replan/SKILL.md" | tr '\n' ' ' | tr -s ' ' | grep -F -- '--review "<file>"' | grep -qF 'vid-row-review' || fail "implement-replan's --review is not made by the vid-row-review skill"
echo 'row-review-once: ok'

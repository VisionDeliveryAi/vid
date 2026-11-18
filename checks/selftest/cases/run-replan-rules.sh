#!/bin/sh
# Purpose: selftest case — the run re-plans by develop's planning rules (0.26.10.29.2, R5, C1). The run skill's re-plan
# step points to develop's planning paragraph (as /vid plan adapts it), to the side-by-side sentence and to the
# pull-forward rule, with its trigger discovered-dependency and its pull-forward event naming the decision; a
# pull-forward the owner must see is asked as a door draft while the run goes on, never waited on; and no skill sends
# the owner to /vid replan, a verb that no longer exists.
# Skips where skills/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
[ -d "$R/skills/vid-run" ] || { echo 'needs skills/'; exit 77; }
fail() { echo "run-replan-rules: $*" >&2; exit 1; }
F=$R/skills/vid-run/SKILL.md
S=$(awk '/^3\. \*\*Re-plan\*\*/ { on = 1 } on && /^4\. / { exit } on' "$F")
[ -n "$S" ] || fail 'the run skill has no re-plan step'
printf '%s\n' "$S" | grep -qF '§ "Plan, decompose, and sequence the PRD"' || fail "the re-plan step does not point to develop's planning paragraph"
printf '%s\n' "$S" | grep -qF 'skills/vid-plan/SKILL.md' || fail "the re-plan step does not name /vid plan's adaptation"
printf '%s\n' "$S" | grep -qF 'the side-by-side sentence of skills/vid-develop/SKILL.md § "The plan is a record", whenever a change admits steps to run at once' || fail 'the re-plan step does not point to the side-by-side sentence'
printf '%s\n' "$S" | grep -qF '§ "The pull-forward rule"' || fail 'the re-plan step does not point to the pull-forward rule'
printf '%s\n' "$S" | grep -qF -- '--trigger discovered-dependency' || fail 'the pull-forward in the run names no discovered-dependency trigger'
printf '%s\n' "$S" | grep -qF "event.sh 'pull-forward step=<id> decision=<D-id>'" || fail 'the pull-forward in the run records no pull-forward event naming its decision'
printf '%s\n' "$S" | grep -qF 'while the run goes on' || fail 'the pull-forward ask does not say the run goes on'
printf '%s\n' "$S" | grep -qF 'Never wait on the owner for a pull-forward while other work is admissible.' || fail 'the pull-forward ask does not say never to wait on the owner'
H=$(grep -rnE '/vid replan|\(vid-replan\)|/vid:vid-replan' "$R/skills" || true)
[ -z "$H" ] || fail "a skill sends the owner to /vid replan: $H"
exit 0

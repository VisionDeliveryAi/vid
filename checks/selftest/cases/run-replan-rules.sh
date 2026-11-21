#!/bin/sh
# Purpose: selftest case — the run re-plans by develop's planning rules (0.26.10.29.2, R5, C1). GM-4 K7: the run skill's re-plan
# step names the vid-replan skill, whose rules (read in both modes) and GitHub auto paragraph point to develop's planning paragraph (as /vid plan adapts it), to the side-by-side sentence and to the
# pull-forward rule, with its trigger discovered-dependency and its pull-forward event naming the decision; a
# pull-forward the owner must see is asked as a door draft while the run goes on, never waited on; and no skill sends
# the owner to a bare /vid replan (GM-4 F14 makes /vid:vid-replan a command again: its full name is allowed).
# Skips where skills/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
[ -d "$R/skills/vid-run" ] || { echo 'needs skills/'; exit 77; }
fail() { echo "run-replan-rules: $*" >&2; exit 1; }
F=$R/skills/vid-run/SKILL.md
grep '^3\. \*\*Re-plan\*\*' "$F" | grep -q '`vid-replan`' || fail "the run skill's re-plan step does not name the vid-replan skill"
S=$(awk '/^## The rules, in both modes/ { on = 1 } on && /^## GitHub manual/ { exit } on' "$R/skills/vid-replan/SKILL.md")
[ -n "$S" ] || fail 'vid-replan has no rules for both modes and no GitHub auto paragraph'
printf '%s\n' "$S" | grep -qF '§ "Plan, decompose, and sequence the PRD"' || fail "the re-plan step does not point to develop's planning paragraph"
printf '%s\n' "$S" | grep -qF 'skills/vid-plan/SKILL.md' || fail "the re-plan step does not name /vid plan's adaptation"
printf '%s\n' "$S" | grep -qF 'the side-by-side sentence of skills/vid-develop/SKILL.md § "The plan is a record", whenever a change admits steps to run at once' || fail 'the re-plan step does not point to the side-by-side sentence'
printf '%s\n' "$S" | grep -qF '§ "The pull-forward rule"' || fail 'the re-plan step does not point to the pull-forward rule'
printf '%s\n' "$S" | grep -qF -- '--trigger discovered-dependency' || fail 'the pull-forward in the run names no discovered-dependency trigger'
printf '%s\n' "$S" | grep -qF "event.sh 'pull-forward step=<id> decision=<D-id>'" || fail 'the pull-forward in the run records no pull-forward event naming its decision'
printf '%s\n' "$S" | grep -qF 'while the run goes on' || fail 'the pull-forward ask does not say the run goes on'
printf '%s\n' "$S" | grep -qF 'Never wait on the owner for a pull-forward while other work is admissible.' || fail 'the pull-forward ask does not say never to wait on the owner'
H=$(grep -rnE '/vid replan|\(vid-replan\)' "$R/skills" || true)
[ -z "$H" ] || fail "a skill sends the owner to /vid replan: $H"
exit 0

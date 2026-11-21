#!/bin/sh
# Purpose: selftest case — re-planning, one skill in both GitHub modes (GM-4 K7, S0). vid-replan is a verb, `/vid:vid-replan`, its
# description naming both modes; it holds one paragraph per mode where GM's rulings differ (`## GitHub auto`, the run manager's
# `plan.sh change`; `## GitHub manual`, the analysis that waits for the owner's implement-replan, GM-3 U4), and the rules both read
# where they stand (develop's planning paragraph as vid-plan adapts it, the side-by-side sentence, the pull-forward rule). The run
# skill's re-planning (the re-plan step's rules, the rules every change is made by, breadth first, the reading order, the stage
# planned in detail, a refusal) is in vid-replan once and gone from the run skill, which names vid-replan in its re-plan step and in
# the plan-stage, plan-refused and refused rows (plan-refused's plan change, with its trigger, in vid-replan's round lines once); the candidate's own copy of the rules is cut (its forms stay replan.sh's); /vid next's
# implement-replan form is vid-replan's. GitHub auto's re-plan cases run unchanged (run-replan-rules reads the rules where they now
# stand). Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-replan" ] && [ -d "$S/vid-run" ] || { echo 'replan-shared: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "replan-shared: $*" >&2; exit 1; }
P=$S/vid-replan/SKILL.md; R=$S/vid-run/SKILL.md; N=$S/vid-next/SKILL.md
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$P" > "$T/fm"
! grep -q '^user-invocable: false' "$T/fm" || fail 'vid-replan is not a command'
grep '^description:' "$T/fm" | grep -q 'GitHub auto' && grep '^description:' "$T/fm" | grep -q 'GitHub manual' || fail "vid-replan's description does not name both GitHub modes"
grep -qF '/vid:vid-replan' "$P" || fail 'vid-replan does not name its command'
# one paragraph per mode, each naming its ruling
sec() { awk -v h="$1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$P" | tr '\n' ' ' | tr -s ' '; }
A=$(sec '## GitHub auto'); M=$(sec '## GitHub manual')
[ -n "$A" ] && [ -n "$M" ] || fail 'vid-replan has no paragraph for each GitHub mode (## GitHub auto, ## GitHub manual)'
printf '%s' "$A" | grep -qF 'sh checks/plan.sh change' || fail "vid-replan's GitHub auto paragraph does not change the plan through plan.sh change"
printf '%s' "$M" | grep -qF 'GM-3 U4' && printf '%s' "$M" | grep -qF 'implement-replan' || fail "vid-replan's GitHub manual paragraph does not wait for the owner's implement-replan (GM-3 U4)"
printf '%s' "$M" | grep -qF 'replan.sh" scope' && printf '%s' "$M" | grep -qF 'replan.sh" analyse' || fail "vid-replan's GitHub manual paragraph does not run the analysis"
# the rules both modes read, where they stand, once
for p in '§ "Plan, decompose, and sequence the PRD"' 'the side-by-side sentence of skills/vid-develop/SKILL.md § "The plan is a record"' '§ "The pull-forward rule"'; do
  [ "$(grep -cF -- "$p" "$P")" = 1 ] || fail "vid-replan does not read, once: $p"; ! grep -qF -- "$p" "$R" || fail "the run skill still reads: $p"; done
# the run skill's re-planning lines: in vid-replan once, gone from the run skill
for p in "A re-plan is \`sh checks/plan.sh change <what>" 'The rules every change is made by' '**Breadth first**' '**Reading order, when you plan:**' 'plan it in detail as a recorded change' 'Never wait on the owner for a pull-forward while other work is admissible.'; do
  ! grep -qF -- "$p" "$R" || fail "the run skill still holds: $p"; [ "$(grep -cF -- "$p" "$P")" = 1 ] || fail "vid-replan does not hold once: $p"; done
grep '^3\. \*\*Re-plan\*\*' "$R" | grep -q '`vid-replan`' || fail "the run skill's re-plan step does not name the vid-replan skill"
for r in '| `plan-stage <N>` |' '| `plan-refused <step>: <why>` |' '| `refused <what>: <why>` |'; do [ "$(grep -cF -- "$r" "$R")" = 1 ] || fail "the run skill has no one row $r"
  grep -F -- "$r" "$R" | grep -q 'vid-replan' || fail "the run skill's row $r does not name vid-replan"; done
# GM-4 K7: plan-refused's plan change in vid-replan's round lines once, with its trigger, none of it in the run skill's row
[ "$(grep -cF -- '| `plan-refused <step>: <why>` |' "$P")" = 1 ] && grep -F -- '| `plan-refused <step>: <why>` |' "$P" | grep -q 'test-evidence' || fail "vid-replan's round lines do not hold plan-refused's plan change once, with its trigger"
! grep -F -- '| `plan-refused <step>: <why>` |' "$R" | grep -q 'plan.sh change' || fail "the run skill's plan-refused row still holds a plan change"
# the candidate's copy of the rules cut: its forms are replan.sh's, the rules read above
! grep -qF 'topped up only where the ticket already builds what the test checks' "$P" || fail "vid-replan's candidate still copies the re-plan rules"
[ "$(grep -cF 'A published ticket is only topped up' "$P")" = 1 ] || fail 'vid-replan does not hold GM M10 rule 2 once'
# implement-replan's form is vid-replan's, not /vid next's
grep -qF 'implement-replan "<words>"' "$P" || fail "vid-replan does not hold the implement-replan move's form"
! grep -qF 'implement-replan "<words>"' "$N" || fail "vid-next still holds the implement-replan move's form"
echo 'replan-shared: ok'

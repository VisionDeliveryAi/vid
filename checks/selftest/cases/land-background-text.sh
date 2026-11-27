#!/bin/sh
# Purpose: selftest case — a landing is never left to a caller's time limit (FIX-BATCH-T2 §12, OW-5). vid-answer's step 3 says
# an answer that lands a draft (the yes of a draft's Q line, which runs land.sh) is started with run_in_background: true,
# under no timeout of the caller's own, and waited on until its task ends; vid-next's step 6 says the same of a call holding
# one, and of a call holding implement-replan (whose apply lands
# through land.sh's step); and vid-run's loop goes on at no step while that landing runs. Needs the skills beside checks/ (exit 77 without them). Env: CHECKS.
set -eu
fail() { echo "land-background-text: $*" >&2; exit 1; }
K=$CHECKS/../skills; [ -f "$K/vid-answer/SKILL.md" ] || { echo 'land-background-text: needs the skills beside checks/'; exit 77; }
flat() { tr '\n' ' ' | tr -s ' '; }
A=$(awk '/^3\. \*\*The answer\.\*\*/ { on = 1 } on && /^4\. / { exit } on' "$K/vid-answer/SKILL.md" | flat)
[ -n "$A" ] || fail "no step 3 in vid-answer"
for w in 'land.sh' 'run_in_background: true' 'timeout' 'ends'; do printf '%s' "$A" | grep -qF "$w" || fail "vid-answer's step 3 does not say: $w"; done
N=$(awk '/^6\. / { on = 1 } on && /^7\. / { exit } on' "$K/vid-next/SKILL.md" | flat)
[ -n "$N" ] || fail "no step 6 in vid-next"
printf '%s' "$N" | grep -qF 'run_in_background: true' || fail "vid-next's step 6 does not run a landing call in the background"
# implement-replan lands its plan change through land.sh's step (replan.sh apply), so its call runs so too
printf '%s' "$N" | sed 's/run_in_background: true.*//' | grep -qF 'implement-replan' || fail "vid-next's step 6 leaves implement-replan's landing to the caller's time limit"
R=$(awk '/^\*\*After any owner message\*\*/ { on = 1 } on && /^$/ { exit } on' "$K/vid-run/SKILL.md" | flat)
printf '%s' "$R" | grep -q 'lands a draft runs in the background' && printf '%s' "$R" | grep -qF 'go on at nothing' || fail "vid-run's loop does not wait on a background landing before its next step"
# and the loop's own rules agree: its background rule names the landing's wait, and the wait is the one turn's end beside the stops
L=$(awk '/^## The loop/ { on = 1; next } on && /^1\. / { exit } on' "$K/vid-run/SKILL.md" | flat)
printf '%s' "$L" | grep -qF 'A landing in the background alone is waited on' || fail "vid-run's rule for a command in the background sends a landing's run on at 1"
printf '%s' "$R" | grep -qF 'That wait ends your turn with nothing else run, the lock kept' && printf '%s' "$R" | grep -qF 'Only the stops below, and that wait, end it' || fail "vid-run does not say how a landing is waited on without a stop"
echo 'land-background-text: ok'

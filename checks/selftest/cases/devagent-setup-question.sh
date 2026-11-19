#!/bin/sh
# Purpose: selftest case — a dev-side setup question reaches the ticket (0.26.11.1.2, R4, GA-15). The dev manager's Questions table has a row
# for a question left for whoever runs the dev side (a setup pass's return, an analyst's limit, the test manager's open point): a `Question:` comment
# on the ticket naming the step, the blocked label only when the work cannot go on without the answer, else no label and the default it goes on with.
# Its hand-back list has a line for a setup return's questions; the roles that ask gain TM and AN. setup.md no longer tells the setup pass to ask
# whoever runs the dev side: it puts what looking could not settle in its return, a line each with its default. Skips where devagent/ is absent
# (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$(cd "$CHECKS/.." && pwd -P); DM=$R/devagent/agents/dev-manager.md; SU=$R/devagent/test-manager/setup.md
fail() { echo "devagent-setup-question: $*" >&2; exit 1; }
# the Questions table's row: its first cell names the question left for whoever runs the dev side and its three sources
Q=$(awk '/^## Questions/ { s = 1; next } s && /^## / { exit } s' "$DM")
ROW=$(printf '%s\n' "$Q" | grep -F '| A question left for whoever runs the dev side' || true)
[ -n "$ROW" ] || fail "the Questions table has no row for a question left for whoever runs the dev side"
for w in "a setup pass's return" "an analyst's limit" "the test manager's open point"; do printf '%s\n' "$ROW" | grep -qF "$w" || fail "the row does not name $w"; done
printf '%s\n' "$ROW" | grep -qF 'A `Question:` comment on the ticket naming the step' || fail "the row's route is not a Question: comment on the ticket naming the step"
printf '%s\n' "$ROW" | grep -qF 'the *blocked* label only when the work cannot go on without the answer' || fail "the row puts the blocked label on a question the work can go on without"
printf '%s\n' "$ROW" | grep -qF 'else no label and the default the work goes on with' || fail "the row does not say no label and the default otherwise"
# the asking roles
printf '%s\n' "$Q" | grep -qF 'then the role that asked (TA, BU, FX, TM, AN)' || fail "the asking roles lack TM or AN"
# the hand-back list's line
H=$(awk '/^\*\*Hand-backs \(R\)\.\*\*/ { s = 1 } s && /^## / { exit } s' "$DM")
printf '%s\n' "$H" | grep -qF "**A setup's open questions,**" || fail "the hand-back list has no line for a setup return's questions"
printf '%s\n' "$H" | grep -F "**A setup's open questions,**" | grep -qF 'a question left for whoever runs the dev side' || fail "the hand-back line does not send them by that row"
# setup.md: no direct ask; the return carries each question with its default
! grep -qiF 'ask once' "$SU" || fail "setup.md still tells the setup pass to ask once"
! grep -qiE 'ask[^.]*whoever runs the dev side' "$SU" || fail "setup.md still tells the setup pass to ask whoever runs the dev side"
grep -qF 'Put what looking could not settle in the return,** one line each with the default you go on with (no other place to ask)' "$SU" || fail "setup.md's step 4 does not put the questions in the return with their defaults"
exit 0

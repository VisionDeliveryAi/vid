#!/bin/sh
# Purpose: selftest case — DevAgent sorts before it asks (0.26.11.1.4, R7). The test manager's sort step comes before its ask
# step, at the first head once the head grade holds a line left to sort, and no line has the sort wait for a decision's
# `sort evidence missing`; its `test it` lines keep the decision's one test-author pass. The dev manager's ask waits for the
# sort report when the grade holds a line to sort; its merge first sends each `test it` line no test author has taken to a
# test author, then the head report alone at the new head, back to asking, and merges only on that head's decision; the
# not-yet route for `sort evidence missing` stays. The results format's sort paragraph says the sort runs at the ticket's
# first head, and keeps its `finding: real` lines. Skips where devagent/ or docs/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
TM=$R/devagent/test-manager/SKILL.md; DM=$R/devagent/agents/dev-manager.md; RF=$R/docs/RESULTS-FORMAT.md
[ -f "$TM" ] && [ -f "$DM" ] && [ -f "$RF" ] || { echo 'needs devagent/ and docs/RESULTS-FORMAT.md'; exit 77; }
fail() { echo "devagent-sort-before-ask: $*" >&2; exit 1; }
# the test manager: the sort's step before the ask's
s=$(grep -n '^[0-9][0-9]*\. \*\*The sort,\*\*' "$TM" | cut -d: -f1); a=$(grep -n '^[0-9][0-9]*\. \*\*The ask\.\*\*' "$TM" | cut -d: -f1)
[ -n "$s" ] && [ -n "$a" ] || fail "the test manager lacks a sort step or an ask step"
[ "$s" -lt "$a" ] || fail "the test manager's sort step comes after its ask"
S=$(sed -n "${s}p" "$TM")
! printf '%s' "$S" | grep -qF 'sort evidence missing' || fail "the sort step still waits for a decision's sort evidence missing"
! grep -qF "when a decision's \`sort evidence missing\` line names the sort" "$TM" || fail 'a line has the sort wait for sort evidence missing'
for w in 'at the first head, once the head grade holds a line left to sort' 'before the ask' "wait for the decision's one test author's pass"; do
  printf '%s' "$S" | grep -qF -- "$w" || fail "the sort step lacks: $w"; done
# the dev manager: the ask's precondition, the merge's step, the not-yet route kept
A=$(grep '^\*\*The reached rows,\*\*' "$DM" || true)
printf '%s' "$A" | grep -qF 'and its sort report, when the grade holds a line to sort' || fail "the ask's precondition lacks the sort report"
M=$(awk '/^\*\*The merge,\*\*/ { on = 1 } on && /^$/ { exit } on' "$DM" | tr '\n' ' ')
for w in 'each `test it` line no test author has taken' 'then the head report alone at the new head' 'the ticket goes back to asking' 'it merges only on the decision of that head'; do
  printf '%s' "$M" | grep -qF -- "$w" || fail "the merge lacks: $w"; done
grep -q '^- `sort evidence missing`: ' "$DM" || fail 'the not-yet route for sort evidence missing is gone'
# the results format's sort paragraph
! grep -qF "After the ticket's first decision" "$RF" || fail 'the format still sorts after the first decision'
grep -qF "At the ticket's first head, once its grade holds a \`breached\` or \`unclear\` line, SR" "$RF" || fail 'the format does not sort at the first head'
grep -qF 'finding: real' "$RF" || fail "the format lost its finding: real lines"
echo 'devagent-sort-before-ask: ok'

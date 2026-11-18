#!/bin/sh
# Purpose: selftest case — the status says what each plan change was (0.26.10.29.2, R8), checks/queue.sh on the writer's toy. After the
# last update, two changes recorded (`other`, the second's why holding `what=rows` and a semicolon) and one refused (a row no
# inventory holds): the status's plan-change line counts the two, each with its kind and its why as it stands, as develop's progress
# prints them; the refused one is not listed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "status-plan-changes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; mkdir -p .vid/decide/queue; date +%s > .vid/decide/queue/updated; sleep 1
sh "$CHECKS/plan.sh" change other 'the digest step waits for the feeds' --trigger discovered-dependency --evidence step:S04 --expect 'S04 after S02' > "$T/out" 2>&1 || fail 'the change was refused'
sh "$CHECKS/plan.sh" change other 'S02 needs what=rows; after the scope change' --trigger discovered-dependency --evidence step:S02 --expect 'S02 first' > "$T/out" 2>&1 || fail 'the second change was refused'   # a why holding a field's form and a semicolon
cp .vid/RUN-STATE.md "$T/rs"; pt_rs 's/^\(step S05 .*rows: ROW-017\) /\1 ROW-999 /'; grep -q 'ROW-017 ROW-999 ' .vid/RUN-STATE.md || fail 'the refused change was not drafted (the case is wrong)'
! sh "$CHECKS/plan.sh" change rows 'a row no inventory holds' --trigger unknown --expect 'nothing' > "$T/out" 2>&1 || fail 'a change naming a row no inventory holds was accepted (the case is wrong)'
cat "$T/rs" > .vid/RUN-STATE.md; grep -q '^result=refused' .vid/plans/decisions/*.why || fail 'no refused decision (the case is wrong)'
VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'status failed'
L=$(grep '^plan changes since the last update: ' "$T/out") || fail 'no plan-change line'
[ "$L" = 'plan changes since the last update: 2 · other — "the digest step waits for the feeds"; other — "S02 needs what=rows; after the scope change"' ] || fail "the line does not name the change, its kind and its why: $L"
exit 0

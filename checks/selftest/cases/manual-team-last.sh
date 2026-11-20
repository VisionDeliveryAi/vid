#!/bin/sh
# Purpose: selftest case — a yes to the team taking out a ticket's last test withdraws the ticket in the same call (GM-2 T7; its case
# manual-team-last). The move is lane E's; this case calls checks/team-change.sh as the move will. On the form fixture's toy
# (fixtures/form.sh), S05 posted, its one test ROW-017. The team takes ROW-017 out of its body. next.sh triggers lists the move
# `team-change #<n> ROW-017` with its `withdraw` warning. The yes: S05 is gone from the plan's block, and from S04's fakes:; ROW-017
# stands on .vid/tw/to-place as no-step with the owner's words, in no step; the ticket is closed, its `withdrawn` line ending with
# the words; the yes recorded. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-team-last: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S05 || { cp "$T/post" "$T/out"; fail 'S05 was not posted in manual'; }; N=$FM_N
fm_team_edit "$N" '/^ROW-017$/d'; ! grep -q 'ROW-017' "$FAKEGH/issues/$N/body" || fail 'the team edit did not take'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
awk -F'\t' -v n="$N" '$1 == "dropped" && $2 == n && $3 == "ROW-017"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-017 is not listed as dropped'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^move${TB}team-change${TB}#$N ROW-017${TB}" "$T/tr" && grep -q "^warning${TB}team-change${TB}#$N ROW-017${TB}withdraw${TB}" "$T/tr" || { grep '^move\|^warning' "$T/tr" > "$T/out"; fail 'the move and its withdraw warning are not listed first'; }
sh "$CHECKS/team-change.sh" "$N" ROW-017 yes "Yes, S05 is out for now" > "$T/out" 2>&1 || fail 'the yes was refused'
! grep -q '^step S05 ' .vid/RUN-STATE.md || fail 'S05 is still a step of the plan'
! grep -q 'fakes: S05' .vid/RUN-STATE.md || fail "S04 still fakes S05"
! grep -q '^\(step\|needs\) .*ROW-017' .vid/RUN-STATE.md || fail 'ROW-017 is still in a step or a needs line'
grep -qx "ROW-017${TB}no-step${TB}[^$TB]*${TB}Yes, S05 is out for now" .vid/tw/to-place || { cat .vid/tw/to-place > "$T/out" 2>/dev/null; fail 'ROW-017 is not on the to-place list, no-step, with the words'; }
[ "$(cat "$FAKEGH/issues/$N/state")" = CLOSED ] || fail "#$N is not closed"
grep -q "^withdrawn $N .* words=\"Yes, S05 is out for now\"\$" .vid/tw/log || fail "#$N's withdrawn line does not end with the words"
grep -q "^$N${TB}dropped${TB}ROW-017${TB}[0-9a-f]*${TB}yes${TB}" .vid/next/team-answers || fail 'the yes is not recorded'
exit 0

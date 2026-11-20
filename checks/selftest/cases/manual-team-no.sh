#!/bin/sh
# Purpose: selftest case — a no to a test the team added to a ticket (GM-2 T7; its case manual-team-no). The move is lane E's; this
# case calls checks/team-change.sh as the move will. On the form fixture's toy (fixtures/form.sh), S02 posted; the team adds a line
# naming ROW-007 to its body. The no: exactly one comment written to GitHub, on the ticket, saying the test stays as the ticket had
# it; the no recorded in .vid/next/team-answers with the change's evidence hash; the plan unchanged. At the next call ROW-007 is not
# listed; once the team changes the body line naming it, it is listed again. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-team-no: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
printf 'Also ROW-007, the team adds it.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
EV=$(awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-007" { print $5 }' "$T/ch"); [ -n "$EV" ] || { cp "$T/ch" "$T/out"; fail 'ROW-007 is not listed as added'; }
cp .vid/RUN-STATE.md "$T/rs0"; P0=$(grep -c '^plan-change ' .vid/metrics-events); C0=$(ls "$FAKEGH/issues/$N/comments" | grep -c .); gh_wclear
sh "$CHECKS/team-change.sh" "$N" ROW-007 no "No, ROW-007 stays out of #$N" > "$T/out" 2>&1 || fail 'the no was refused'
[ "$(cat "$FAKEGH/writes")" = "owner/code comment $N" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the no wrote other than one comment on the ticket'; }
[ "$(ls "$FAKEGH/issues/$N/comments" | grep -c .)" = $((C0 + 1)) ] || fail 'the ticket did not gain exactly one comment'
am_comment "$N" 'vid: ' | grep -q 'ROW-007' || fail 'the comment does not name ROW-007'
grep -qx "$N${TB}added${TB}ROW-007${TB}$EV${TB}no${TB}[^$TB]*${TB}No, ROW-007 stays out of #$N" .vid/next/team-answers || { cat .vid/next/team-answers > "$T/out" 2>/dev/null; fail 'the no is not recorded with its evidence'; }
cmp -s "$T/rs0" .vid/RUN-STATE.md && [ "$(grep -c '^plan-change ' .vid/metrics-events)" = "$P0" ] || fail 'the no changed the plan'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed at the next call'; }
! awk -F'\t' -v n="$N" '$2 == n && $3 == "ROW-007"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-007 is offered again with its evidence unchanged'; }
fm_team_edit "$N" 's/^Also ROW-007, the team adds it\.$/Also ROW-007, the team adds it, and asks again./'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the body changed'; }
awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-007"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-007 is not offered again once the body line naming it changed'; }
exit 0

#!/bin/sh
# Purpose: selftest case — a yes to a test the team added to a ticket (GM-2 T7; its case manual-team-yes). The move
# `/vid next team-change #<n> <id> yes "<words>"` is lane E's; this case calls checks/team-change.sh as the move will. On the form
# fixture's toy (fixtures/form.sh), with S01's close taken back (its `closed` line out of the handed record), S03 posted: it builds
# on S01, unclosed, so the publish was over an unclosed builds-on. The team adds two lines to S03's body on GitHub, one naming
# ROW-002 (a test of S04, unpublished, of S03's stage), one naming ROW-009 (S04's too). next.sh changes lists both as added. The yes
# to ROW-002: one plan change recorded (trigger owner-answer, evidence ticket:<n>), no rule refusing the row added to the started
# S03; ROW-002 in S03's rows and in a needs line naming S01, S03's builds-on (made, as none did); S04 without it; S03's ticket
# amended in the same call, its line holding added=ROW-002 and the words, its notice naming ROW-002 as the team's own addition; the
# yes recorded in .vid/next/team-answers with the change's evidence hash. At the next call (next.sh read, next.sh changes) ROW-009,
# unanswered, is still listed, and ROW-002 is not. A yes with no words, and one whose words are a
# carriage return alone, are each refused with nothing recorded and nothing written to GitHub; rule A's ceiling is 12, so the
# yes that brings S03 to 13 tests shows the planner's size flag as a warning and still amends S03 in the same call; then ROW-017,
# a test of stage 2, sits in S04 (stage 1) on .vid/tw/to-place as other-stage; the team adds it to S03's ticket (stage 1) and the
# yes keeps its other-stage line, so the writer's gate stays open and S03 is amended in the same call. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-team-yes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^closed S01 ' .vid/tw/handed > "$T/h" && cat "$T/h" > .vid/tw/handed
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted over its unclosed builds-on'; }; N=$FM_N
printf 'Also ROW-002, the team adds it.\nAlso ROW-009, the team adds it too.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
EV=$(awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-002" && $4 == "S04" { print $5 }' "$T/ch")
[ -n "$EV" ] && awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-009"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'the two team additions are not listed'; }
P0=$(grep -c '^plan-change ' .vid/metrics-events)
# no words, and a carriage return alone: refused, nothing recorded, nothing written
for w in '' "$(printf '\r')"; do gh_wclear; RC=0; sh "$CHECKS/team-change.sh" "$N" ROW-002 yes "$w" > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 1 ] || fail "a yes with the words '$w' exited $RC, not a refusal"
  [ "$(grep -c '^plan-change ' .vid/metrics-events)" = "$P0" ] && [ ! -s .vid/next/team-answers ] && [ ! -s "$FAKEGH/writes" ] || fail "a yes with no words recorded or wrote something"; done
# rule A's ceiling at 12: S03, 12 tests, takes a thirteenth
printf 'unverified-rows=12\n' >> .vid/budget
sh "$CHECKS/team-change.sh" "$N" ROW-002 yes "Yes, take ROW-002 into #$N" > "$T/out" 2>&1 || fail 'the yes was refused'
grep -q 'warning.*size' "$T/out" || fail "the planner's size flag is not shown as a warning"
[ "$(grep -c '^plan-change ' .vid/metrics-events)" = $((P0 + 1)) ] || fail 'the yes did not record exactly one plan change'
grep '^plan-change ' .vid/metrics-events | tail -n 1 > "$T/pc"; D=$(sed -n 's/.* decision=\([^ ]*\) .*/\1/p' "$T/pc")
grep -q '^trigger=owner-answer$' ".vid/plans/decisions/$D.why" && grep -q "^evidence=ticket:$N\$" ".vid/plans/decisions/$D.why" || fail 'the plan change does not carry the trigger owner-answer and the evidence ticket:<n>'
grep -q "^step S03 .*rows:.* ROW-002[ |]" .vid/RUN-STATE.md || grep -q "^step S03 .*rows:.* ROW-002\$" .vid/RUN-STATE.md || fail 'ROW-002 is not in S03'
! grep -q '^step S04 .*ROW-002' .vid/RUN-STATE.md || fail 'ROW-002 is still in S04'
grep -E '^needs ' .vid/RUN-STATE.md | grep -E '(^needs | )ROW-002 ' | grep -qE '\| S01$' || { grep '^needs' .vid/RUN-STATE.md > "$T/out"; fail 'ROW-002 is not in a needs line naming S01'; }
[ "$(grep -c 'ROW-002' .vid/RUN-STATE.md)" = 2 ] || fail 'ROW-002 is in the block other than once in a step and once in a needs line'
grep -qE "^amended $N .* added=ROW-002 words=\"Yes, take ROW-002 into #$N\"\$" .vid/tw/log || { grep "^amended $N " .vid/tw/log > "$T/out"; fail "#$N was not amended in the same call, added=ROW-002 with the words"; }
am_comment "$N" 'vid: amended' | grep -q "^- added: ROW-002 .*the team's own addition" || fail "the notice does not name ROW-002 as the team's own addition"
grep -qx "$N${TB}added${TB}ROW-002${TB}$EV${TB}yes${TB}[^$TB]*${TB}Yes, take ROW-002 into #$N" .vid/next/team-answers || { cat .vid/next/team-answers > "$T/out" 2>/dev/null; fail 'the yes is not recorded with its evidence'; }
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed at the next call'; }
awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-009"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-009, unanswered, is no longer listed'; }
! awk -F'\t' -v n="$N" '$2 == n && $3 == "ROW-002"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-002 is listed again after its yes'; }
# ROW-017 (stage 2) placed in S04 (stage 1) as other-stage, S05 gone; the team adds it to S03's ticket
grep -v '^step S05 \|^needs ROW-017 ' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; pt_rs 's/ | fakes: S05//'
pt_rs 's/^\(step S04 .*rows:\) /\1 ROW-017 /'; awk '/^needs / && !d { print "needs ROW-017 | -"; d = 1 } { print }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
printf 'ROW-017\tother-stage\t2026-11-19T12:00:00Z\tsearch is built beside the limits, the owner says\n' >> .vid/tw/to-place
am_change "$N" 'ROW-017 is built in S04' || { cp "$T/chg" "$T/out"; fail 'the plan change placing ROW-017 was refused'; }
printf 'Also ROW-017, the team builds it here.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed before the other-stage yes'; }
awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-017"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-017 is not listed as added'; }
A0=$(grep -c "^amended $N " .vid/tw/log)
sh "$CHECKS/team-change.sh" "$N" ROW-017 yes "Yes, S03 builds ROW-017" > "$T/out" 2>&1 || fail 'the yes to the other-stage test failed'
grep -qx "ROW-017${TB}other-stage${TB}.*" .vid/tw/to-place || { cat .vid/tw/to-place > "$T/out"; fail "ROW-017's other-stage line was taken off the to-place list"; }
[ "$(grep -c "^amended $N " .vid/tw/log)" = $((A0 + 1)) ] || fail "#$N was not amended in the same call as the other-stage yes"
exit 0

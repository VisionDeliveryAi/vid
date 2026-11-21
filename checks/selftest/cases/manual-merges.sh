#!/bin/sh
# Purpose: selftest case — merges, and the ticket's acceptance as its merge (GM-4 E4), in GitHub manual on the toy and the fake gh
# (fixtures/accept.sh). Two unit pull requests merge under the step ticket, one naming the ticket, one a sub-issue of it: round.sh
# step closes nothing and decides nothing, both are in .vid/decide/unit-merges (none in merges or merged-prs), no close is owed, and
# their Decisions lines are recorded against the ticket, with no export. A unit merged with no Decisions section records nothing and
# no event, and is recorded once its description gains one. The ticket accepted at a later commit is in merges, its close owed at
# that commit; its `step-` line makes decisions.sh record print nothing for it. A unit naming an issue no published ticket's tree
# holds is listed once, `context no-ticket #<p>`, records nothing and is tried again, and is recorded against the ticket once the
# read's sub lines put the issue under it. The accepted ticket, its issue still open, is out of tw-sync's open list, and a change
# to one of its rows, applied, owes it no amendment but the follow-up. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-merges: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail "the plan could not be recorded"
NS=$(gh_issue 'A unit of S02'); gh_sub "$AC_N" "$NS"
ac_unit unit-a "$(printf 'ticket: #%s\n\nDecisions:\n- one cache for the digest | why: speed\n' "$AC_N")"; PA=$AC_P
ac_unit unit-b "$(printf 'ticket: #%s\n\nDecisions:\n- the digest in plain text | why: every mail client\n' "$NS")"; PB=$AC_P
gh_wclear; ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"
grep -qx "unit-merged $PA $AC_N" "$T/out" && grep -qx "unit-merged $PB $NS" "$T/out" || fail 'the two merges are not unit-merged lines'
[ "$(cut -f1 .vid/decide/unit-merges | sort | paste -sd ' ' -)" = "$(printf '%s\n%s\n' "$PA" "$PB" | sort | paste -sd ' ' -)" ] || fail 'unit-merges does not hold both units'
[ ! -s .vid/decide/merges ] && ! grep -q . .vid/decide/merged-prs || fail 'a unit merge reached merges or merged-prs'
[ "$(cat "$FAKEGH/issues/$AC_N/state")" = OPEN ] || fail 'a unit merge closed the ticket'; [ ! -s .vid/decide/state ] || fail 'a unit merge decided a row'
! grep -q '^close S02' "$T/out" && [ -z "$(sh "$CHECKS/close.sh" owed 2>/dev/null | grep '^close S02')" ] || fail 'a unit merge made the close owed'
grep -q "^decisions recorded pr=$PA " "$T/out" && grep -q "^decisions recorded pr=$PB " "$T/out" || fail "the units' decisions were not recorded"
[ "$(grep -c "| enforced: ticket $AC_N |" DECISIONS.md)" = 2 ] || { cp DECISIONS.md "$T/out"; fail 'the decisions are not recorded against the ticket'; }
! grep -q 'owner/code-spec push' "$FAKEGH/writes" || fail 'the record exported in GitHub manual'
# a unit with no Decisions section: nothing recorded, no event, until its description gains one
ac_unit unit-c "$(printf 'ticket: #%s\n\nNo section yet.\n' "$AC_N")"; PC=$AC_P; ac_round step
! grep -q "pr=$PC" "$T/out" && ! grep -q "decisions-recorded pr=$PC " .vid/metrics-events || fail 'a unit with no section was recorded'
ac_round step; ! grep -q "pr=$PC" "$T/out" || fail 'a unit with no section was recorded on the next call'
printf 'ticket: #%s\n\nDecisions:\n- the digest at seven | why: before work\n' "$AC_N" > "$FAKEGH/prs/$PC/body"; ac_round step
grep -q "^decisions recorded pr=$PC " "$T/out" || fail 'the section added after the merge was not recorded'
# a unit naming an issue no published ticket's tree holds: `context no-ticket #<p>` once, nothing recorded, tried again at each call;
# once the read's sub lines put that issue under the ticket, its decisions recorded against the ticket
NX=$(gh_issue 'A stray issue'); ac_unit unit-d "$(printf 'ticket: #%s\n\nDecisions:\n- the digest signed by the board | why: trust\n' "$NX")"; PD=$AC_P
K0=$(grep -c "| enforced: ticket $AC_N |" DECISIONS.md || true); ac_round step
[ "$(grep -c "^context no-ticket #$PD\$" "$T/out")" = 1 ] || fail "a unit mapping to no published ticket is not listed once as context no-ticket #$PD"
! grep -q "pr=$PD" "$T/out" && ! grep -q "decisions-recorded pr=$PD " .vid/metrics-events || fail 'a unit mapping to no published ticket was recorded'
ac_round step; ! grep -q "no-ticket #$PD" "$T/out" || fail 'the no-ticket line was listed again on the next call'
! grep -q "pr=$PD" "$T/out" && ! grep -q "decisions-recorded pr=$PD " .vid/metrics-events || fail 'a unit mapping to no published ticket was recorded on the next call'
gh_sub "$AC_N" "$NX"; ac_round step
grep -q "^decisions recorded pr=$PD " "$T/out" || fail 'the unit, its issue now under the ticket, was not recorded'
[ "$(grep -c "| enforced: ticket $AC_N |" DECISIONS.md)" = $((K0 + 1)) ] || { cp DECISIONS.md "$T/out"; fail 'the unit placed by the sub lines is not recorded against the ticket'; }
# the ticket accepted at a later commit: in merges, its close owed there; the step- line records nothing
ac_good "$AC_M"; ac_ask "$AC_M"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $(printf %s "$AC_M" | cut -c1-12)" "$T/out" || fail 'the ticket was not accepted'
grep -q "^step-$AC_N-$(printf %s "$AC_M" | cut -c1-12)	$AC_N	$AC_M	$AC_M\$" .vid/decide/merges || fail 'the acceptance is not in merges'
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; grep -q '^close S02' "$T/out" || fail 'the accepted ticket made no close owed'
sh "$CHECKS/decisions.sh" record > "$T/out" 2>&1 || fail 'decisions.sh record failed'; ! grep -q 'step-' "$T/out" && ! grep -q 'decisions-recorded pr=step-' .vid/metrics-events || fail "the acceptance's step- line was read as a pull request"
# the accepted ticket, its issue still open until the step's close, reads as closed to the writer: out of the sync's open list, and a
# change to one of its rows applied owes it no amendment, the follow-up instead
[ "$(cat "$FAKEGH/issues/$AC_N/state")" = OPEN ] || fail "the accepted ticket's issue is not open"
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
OL=$(awk '$1 == "sync" { for (i = 2; i <= NF; i++) if ($i ~ /^open=/) o = substr($i, 6) } END { print o }' .vid/tw/log)
case ",$OL," in *",$AC_N,"*) fail "the accepted ticket #$AC_N is in the sync's open list ($OL)" ;; esac
A0=$(cat .vid/tw/applied); sed 's/^\(ROW-012 | behavior | listings | anonymous | n\/a | \)The listings at the stated size/\1The listings, at the stated size,/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
grep -q '^ROW-012 .*The listings, at the stated size,' INVENTORY.md || fail "the toy did not change ROW-012's promise"
git add INVENTORY.md; git commit -qm "ROW-012's promise reworded"; A1=$(git rev-parse HEAD)
printf '%s\t2026-11-17T09:00:00Z\tseed\n%s\t2026-11-20T09:00:00Z\tapply\n' "$A0" "$A1" >> .vid/tw/applied.log; echo "$A1" > .vid/tw/applied   # as an apply leaves them
sh "$CHECKS/writer.sh" due --why > "$T/out" 2>&1 || fail 'writer.sh due failed'
! grep -qx "amend $AC_N" "$T/out" || fail "the accepted ticket #$AC_N is owed an amendment"
grep -qx 'new step S02' "$T/out" && grep -q '^followup S02 ROW-012' "$T/out" || fail "the changed row of the accepted ticket is owed no follow-up"
exit 0

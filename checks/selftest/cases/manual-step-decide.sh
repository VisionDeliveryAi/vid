#!/bin/sh
# Purpose: selftest case — the decision at a ticket's end (GM-4 E2, with E12; GM M8: by the existing decision rules, unchanged), through
# round.sh accept on GitHub manual's toy and the fake gh (fixtures/accept.sh). A ticket in accepted-at with no merge on record is
# decided at the commit asked; a unit merged under it with no Decisions section makes it `not yet`, naming the pull request, beside a
# row whose head report misses a caught break, named; a row held at the next asked commit is a Q line in RUN-STATE before the answer, and still after a switch to GitHub auto (F13);
# the owner's answer `a` re-decides that commit and posts once; once the unit's description has `Decisions: none` the ticket asked
# again is accepted, its acceptance in merges; asked again, the one line `ticket: accepted at <c12>; its close runs there` and no row
# moved; a ruling on a row no decision holds, an amend or more of a row not held and an unknown answer are refused, nothing
# recorded. A second ticket, decided directly: a test it lists marked retired is not decided, nor read through a retested: line or a fault folder, and (E12) a weak test's siblings are read at
# the applied commit, so a pending row of the same requirement is not named. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-step-decide: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
mkdir -p .vid/decide; printf '9 %s 0123456789ab at=2026-11-01T00:00:00Z\n' "$AC_N" > .vid/decide/accepted-at   # accepted at a pull request in GitHub auto
ac_unit unit-1 "$(printf 'ticket: #%s\n\nThe first unit.' "$AC_N")"; UP=$AC_P; C1=$AC_M
ac_round step; grep -qx "unit-merged $UP $AC_N" "$T/out" || fail 'the unit merge was not recorded'
# C1: ROW-001's head report fails (a break caught), ROW-012 has no red; the unit has no Decisions section
_i=red-$AC_N-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001' "$AC_RED")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=fail:no\ digest)"; ac_send "$_i"
ac_head "$C1" 1 ROW-001=fail:a\ second\ digest ROW-012=pass; ac_grade "$C1"; ac_ask "$C1"; n0=$(ac_comments)
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"; [ "$(ac_comments)" = $((n0 + 1)) ] || fail 'the decision at C1 was not posted once'
ac_last > "$T/d1"; grep -qx 'ticket: not yet' "$T/d1" || { cp "$T/d1" "$T/out"; fail 'the ticket in accepted-at with no merge was not decided at the commit asked'; }
grep -q '^ROW-001 failing, a product failure' "$T/d1" && grep -qx "no Decisions section — #$UP" "$T/d1" || { cp "$T/d1" "$T/out"; fail 'the not yet names neither the caught break nor the unit with no Decisions section'; }
# C2: ROW-001 passes, ROW-012 still has no red: held, a Q line before any answer
tk_dev 'the fix'; C2=$(git -C "$T/dev" rev-parse HEAD); ac_head "$C2" 1; ac_ask "$C2"; ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept at C2 exited $RC"
ac_last | grep -q '^ROW-012 held' || { ac_last > "$T/out"; fail 'ROW-012 is not held at C2'; }
grep -q 'held ROW-012' .vid/RUN-STATE.md || { cp .vid/RUN-STATE.md "$T/out"; fail 'the held row is no Q line in RUN-STATE before the answer'; }
# F13 (L3): switched to GitHub auto, the queue still reads the step- decision: the held row stays a Q line; then back to manual
cp .vid/plan/setup "$T/setup0"; printf 'setup-answered key=github-mode value="auto" words="auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'the queue did not sync in GitHub auto'; grep -q 'held ROW-012' .vid/RUN-STATE.md || { cp .vid/RUN-STATE.md "$T/out"; fail 'after the switch to auto the held row of a step- decision is no Q line'; }
cp "$T/setup0" .vid/plan/setup
QA=$(sh "$CHECKS/queue.sh" list 2>/dev/null | awk -F'\t' '$2 == "held:ROW-012" { print $1; exit }'); [ -n "$QA" ] || fail 'no Q line for the held row'
sh "$CHECKS/queue.sh" answer "$QA" a 'Yes, accept it' > "$T/out" 2>&1 || fail 'the owner could not answer the held row'
ac_round step; grep -qx "decide #$AC_N $C2" "$T/out" || fail 'the answer did not make the ticket owed a decision'
n0=$(ac_comments); ac_round accept "$AC_N" "$C2"; [ "$(ac_comments)" = $((n0 + 1)) ] || fail 'the re-decision was not posted once'
ac_last | grep -q '^ROW-012 accepted by ruling' || { ac_last > "$T/out"; fail 'the re-decision does not read the ruling'; }
ac_round accept "$AC_N" "$C2"; [ "$(ac_comments)" = $((n0 + 1)) ] || fail 'an unchanged re-decision was posted again'
# the unit's description gains Decisions: none; asked again, accepted, its acceptance its merge
printf 'ticket: #%s\n\nDecisions: none\n' "$AC_N" > "$FAKEGH/prs/$UP/body"; ac_ask "$C2"; ac_round accept "$AC_N"
ac_last | grep -qx 'ticket: accepted' || { ac_last > "$T/out"; fail 'the ticket was not accepted once the section was there'; }
h2=$(printf %s "$C2" | cut -c1-12); grep -q "^step-$AC_N-$h2	$AC_N	$C2	$C2\$" .vid/decide/merges || fail 'the acceptance is not in merges'
# asked again after its acceptance: the one line, no row moved
s0=$(cksum < .vid/decide/state); tk_dev 'later'; C3=$(git -C "$T/dev" rev-parse HEAD); ac_head "$C3" 1; ac_ask "$C3"; ac_round accept "$AC_N"
[ "$(ac_last | sed -n 2p)" = "ticket: accepted at $h2; its close runs there" ] || { ac_last > "$T/out"; fail 'an accepted ticket asked again did not get the one line'; }
[ "$(cksum < .vid/decide/state)" = "$s0" ] || fail "an accepted ticket's later ask moved a row"
# a ruling the rules refuse, in both modes: on a row no decision holds, amend or more on a row not held, an unknown answer
r0=$(cksum < .vid/decide/rulings); for a in 'ROW-777 limit' 'ROW-001 amend' 'ROW-001 more 2' 'ROW-001 maybe'; do set -- $a
  ! sh "$CHECKS/decide.sh" rule "$@" > "$T/out" 2>&1 || fail "the ruling $a was taken"; done; [ "$(cksum < .vid/decide/rulings)" = "$r0" ] || fail 'a refused ruling was recorded'
# a second ticket: its retired test not decided; E12, a pending row of ROW-001's requirement is no sibling of its weak test
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-001 ROW-006 | sed 's/^- ROW-006 marks: none$/- ROW-006 marks: retired; the spec no longer holds this test: it stays listed in this ticket, and nothing is built or run for it/'; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-001 retired=ROW-006 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log
awk '{ print } index($0, "ROW-020 ") == 1 { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A digest names its saved search. Fails if a digest names none. | REQ-001 | owed: spec-only — first stage | origin: REQ-001" }' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; git commit -qam 'ROW-021 pending'
_i=red-$N2-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001' "$AC_RED")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=fail:no\ digest)"; ac_send "$_i"
_i=step-$N2-$(printf %s "$C3" | cut -c1-12)-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha' "$C3")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=pass)"
rr_put "$_i" faults/ROW-001/control.txt ROW-001; rr_put "$_i" faults/ROW-001/cases-alpha.xml "$(rr_cases ROW-001=pass)"
rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nretested: ROW-006' "$C3")"; rr_put "$_i" faults/ROW-006/control.txt ROW-006; rr_put "$_i" faults/ROW-006/cases-alpha.xml "$(rr_cases ROW-006=fail:gone)"; ac_send "$_i"
sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'
sh "$CHECKS/results.sh" read --ticket "$N2" --at "$C3" > "$T/out" 2>&1 || fail 'the read of the second ticket failed'; ! grep -q '^ROW-006' "$T/out" && ! grep -q 'fault folder for no row: ROW-006' "$T/out" || fail 'a retired test is read as a row, or through its retested: line or fault folder'
sh "$CHECKS/decide.sh" decide --ticket "$N2" --at "$C3" > "$T/out" 2>&1 || fail 'the decision of the second ticket failed'
! grep -q '^ROW-006 ' "$T/out" || fail 'a retired test was decided'; grep -q '^ROW-001 failing, a weak test.* — siblings: ' "$T/out" || fail 'no weak test with its siblings to read'
! grep -q 'ROW-021' "$T/out" || fail 'the decision names a pending row the applied commit lacks (E12)'
exit 0

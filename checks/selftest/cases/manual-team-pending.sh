#!/bin/sh
# Purpose: selftest case — a test the team added that is in the pending spec alone is listed for phase 3 and its yes refused (GM-2
# T7; its case manual-team-pending). The move is lane E's; this case calls checks/team-change.sh as the move will. On the form
# fixture's toy (fixtures/form.sh), S02 posted; ROW-021 added to the working tree's INVENTORY.md after the applied commit; the team
# adds a line naming ROW-021 to S02's body. next.sh changes lists it `pending-only`; next.sh triggers lists its move as the
# re-plan's: a yes comes in through planning-analysis and implement-replan. The yes is refused, naming the pending spec: nothing written to GitHub, the plan unchanged, no answer
# recorded. GM-3 U5 (the case extended): ROW-021 then committed, as a landing leaves it, and still pending-only; its yes still refused,
# pointing to the apply move. The analysis (`replan.sh analyse`) takes it into S02's step by default: a candidate leaving it out with
# no `without` is refused, naming it; a candidate holding it in S02 gives a proposal topping up #N with ROW-021 and taking it in
# (team-in, with its evidence); with `without #N ROW-021` and the candidate leaving it in no step, with why, the proposal leaves it
# out in those words and takes nothing in. Its no works as any team change's: exit 0, one comment written to GitHub, on #N, the no
# recorded with the change's evidence, and next.sh changes no longer lists it. Its taking in by the apply is the apply's case
# (GM-3 U4, manual-team-pending's last part, with the apply). With #N's body unread in the call's read (its body
# lines gone, an `unread body` line in their place), the analysis is refused, naming the unread read, and writes nothing, so the
# addition the body held is never left out unseen. With no read kept (.vid/round/read moved aside), refused, naming
# `unread read`, nothing written; with #N closed (CLOSED in the read, so no open ticket maps ROW-021 to a step), a candidate leaving
# ROW-021 in no step with no `without` is refused, naming it, nothing written. GM-3 U4 (lane C), the taking in by the apply: the team
# adds ROW-022, landed after the applied commit, to #N's body; the analysis takes it into S02 (ROW-021, answered no, left in no step
# with why), and `replan.sh apply --words` records its yes in .vid/next/team-answers in the apply's words, with its evidence, and
# amends #N with it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-team-pending: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
grep -q '^ROW-021 ' INVENTORY.md && ! git show "$(cat .vid/tw/applied):INVENTORY.md" | grep -q '^ROW-021 ' || fail 'ROW-021 is not in the working tree alone'
printf 'Also ROW-021, the team adds it.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-021" && $4 == "pending-only"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-021 is not listed pending-only'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^move${TB}team-change${TB}#$N ROW-021${TB}.*needs no, and your words\$" "$T/tr" || { grep '^move' "$T/tr" > "$T/out"; fail "ROW-021's move does not read needs no, and your words"; }
cp .vid/RUN-STATE.md "$T/rs0"; P0=$(grep -c '^plan-change ' .vid/metrics-events); gh_wclear
RC=0; sh "$CHECKS/team-change.sh" "$N" ROW-021 yes "Yes, take ROW-021" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'pending spec' "$T/out" || fail "the yes to a pending-only test exited $RC, not a refusal naming the pending spec"
[ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the refused yes wrote to GitHub'; }
cmp -s "$T/rs0" .vid/RUN-STATE.md && [ "$(grep -c '^plan-change ' .vid/metrics-events)" = "$P0" ] || fail 'the refused yes changed the plan'
[ ! -s .vid/next/team-answers ] || { cp .vid/next/team-answers "$T/out"; fail 'the refused yes recorded an answer'; }

# GM-3 U5: ROW-021 committed (a landing), still pending-only; its yes still refused, pointing to the apply move
g commit -qam 'ROW-021 landed'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the landing'; }
EVD=$(awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-021" && $4 == "pending-only" { print $5 }' "$T/ch")
[ -n "$EVD" ] || { cp "$T/ch" "$T/out"; fail 'ROW-021 is not listed pending-only once landed'; }
RC=0; sh "$CHECKS/team-change.sh" "$N" ROW-021 yes "Yes, take ROW-021" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'pending spec' "$T/out" && grep -q 'implement-replan' "$T/out" || fail "the yes to a landed pending-only test exited $RC, not a refusal naming the pending spec and the apply move"
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
# the analysis: ROW-021 in S02's step by default
for c in with without; do mkdir -p "$T/$c"; printf 'none\n' > "$T/$c/review"; done
blk | sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;}' > "$T/with/block"
printf 'S02\towner-answer\tticket:%s\tROW-021 joins S02, as the team added it to #%s\n' "$N" "$N" > "$T/with/changes"
blk > "$T/without/block"
printf 'no-step\tROW-021\tthe owner leaves it out of #%s for now\n' "$N" > "$T/without/left"
RC=0; pt_placed "$T/without/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$T/without" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "ROW-021" "$T/out" && grep -q 'without' "$T/out" || fail "a candidate leaving ROW-021 out of #$N with no without exited $RC, or did not name it"
[ ! -e .vid/next/proposal ] || fail 'the refused analysis wrote a proposal'
# a read that could not read #N's body: refused, naming it, nothing written
cp .vid/round/read "$T/read0"
awk -F'\t' -v n="$N" '$1 == "body" && $2 == n { next } { print } $1 == "ticket" && $2 == n { print "unread\tbody\t" n "\tgh could not read it" }' "$T/read0" > .vid/round/read
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/without" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'unread' "$T/out" && grep -q "body" "$T/out" || fail "the analysis with #$N's body unread exited $RC, or did not name the unread read"
[ ! -e .vid/next/proposal ] || fail 'the analysis with a body unread wrote a proposal'
cp "$T/read0" .vid/round/read
# no read kept: refused, naming it, nothing written
mv .vid/round/read "$T/read1"
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/without" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'unread read' "$T/out" || fail "the analysis with no read kept exited $RC, or did not name unread read"
[ ! -e .vid/next/proposal ] || fail 'the analysis with no read kept wrote a proposal'
mv "$T/read1" .vid/round/read
# #N closed: the addition maps to no open step; left in no step with no without, refused, naming it
echo CLOSED > "$FAKEGH/issues/$N/state"; am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed with #N closed'; }
awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-021" && $4 == "pending-only"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'with #N closed, ROW-021 is not listed pending-only'; }
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/without" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "team #$N ROW-021" "$T/out" || fail "with #$N closed, a candidate leaving ROW-021 in no step with no without exited $RC, or did not name it"
[ ! -e .vid/next/proposal ] || fail 'the analysis with #N closed wrote a proposal'
echo OPEN > "$FAKEGH/issues/$N/state"; am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed with #N open again'; }
RC=0; pt_placed "$T/with/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$T/with" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the analysis with ROW-021 in S02 exited $RC"
grep -q "^$N${TB}added${TB}ROW-021\$" .vid/next/proposal/amend || { cat .vid/next/proposal/amend > "$T/out" 2>&1; fail "the proposal does not top #$N up with ROW-021"; }
grep -q "^$N${TB}ROW-021${TB}$EVD\$" .vid/next/proposal/team-in || { cat .vid/next/proposal/team-in > "$T/out" 2>&1; fail 'the proposal does not take ROW-021 in with its evidence'; }
grep -q ROW-021 .vid/pages/REPLAN-PAGE.html || fail 'the page does not name ROW-021'
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/without" without "#$N" ROW-021 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the analysis without #$N ROW-021 exited $RC"
grep -q "^team${TB}#$N ROW-021${TB}.*without #$N ROW-021" .vid/next/proposal/left || { cat .vid/next/proposal/left > "$T/out" 2>&1; fail "the proposal does not leave ROW-021 out in the owner's words"; }
[ ! -s .vid/next/proposal/team-in ] || { cp .vid/next/proposal/team-in "$T/out"; fail 'the proposal without ROW-021 takes a team addition in'; }
! grep -q "^$N${TB}added${TB}ROW-021" .vid/next/proposal/amend || fail "the proposal without ROW-021 still tops #$N up with it"
# the no, as any team change's
cp .vid/RUN-STATE.md "$T/rs0"; gh_wclear
RC=0; sh "$CHECKS/team-change.sh" "$N" ROW-021 no "No, ROW-021 stays out of the ticket" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the no to a pending-only test exited $RC"
[ "$(cat "$FAKEGH/writes")" = "owner/code comment $N" ] || { cp "$FAKEGH/writes" "$T/out"; fail "the no did not write exactly one comment on #$N"; }
grep -q "^$N${TB}added${TB}ROW-021${TB}$EVD${TB}no${TB}.*${TB}No, ROW-021 stays out of the ticket\$" .vid/next/team-answers || { cp .vid/next/team-answers "$T/out"; fail 'the no is not recorded with its evidence and words'; }
cmp -s "$T/rs0" .vid/RUN-STATE.md || fail 'the no changed the plan'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the no'; }
! awk -F'\t' -v n="$N" '$2 == n && $3 == "ROW-021"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail 'ROW-021 is listed again after the no'; }
# GM-3 U4 (lane C): the apply takes a pending-only addition in, recorded as a yes in the apply's words. The team adds ROW-022, landed
# after the applied commit, to #N's body; the analysis takes it into S02 (ROW-021, answered no, left in no step with why); the apply
# records `<N> added ROW-022 <evidence> yes <at> <the apply's words>` in .vid/next/team-answers, and #N is amended with it
awk '{ print } /^ROW-020 / && !d { print "ROW-022 | behavior | REQ-001 | anonymous | n/a | A saved search shows how many jobs its last digest held. Fails if the count is missing. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-022 landed'
printf 'Also ROW-022, the team adds it.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after ROW-022'; }
EV2=$(awk -F'\t' -v n="$N" '$1 == "added" && $2 == n && $3 == "ROW-022" && $4 == "pending-only" { print $5 }' "$T/ch")
[ -n "$EV2" ] || { cp "$T/ch" "$T/out"; fail 'ROW-022 is not listed pending-only'; }
mkdir -p "$T/ap"; printf 'none\n' > "$T/ap/review"
blk | sed -e 's/^\(step S02 .*rows:\) /\1 ROW-022 /' -e '/^needs ROW-017 /{p;s/.*/needs ROW-022 | -/;}' > "$T/ap/block"
printf 'S02\towner-answer\tticket:%s\tROW-022 joins S02, as the team added it to #%s\n' "$N" "$N" > "$T/ap/changes"
printf 'no-step\tROW-021\tthe owner said no to it on #%s; it waits to be placed\n' "$N" > "$T/ap/left"
RC=0; pt_placed "$T/ap/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$T/ap" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && grep -q "^$N${TB}ROW-022${TB}$EV2\$" .vid/next/proposal/team-in || fail "the analysis taking ROW-022 in exited $RC, or does not take it in"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, take the team addition in' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply exited $RC"
grep -q "^$N${TB}added${TB}ROW-022${TB}$EV2${TB}yes${TB}[^$TB]*${TB}Yes, take the team addition in\$" .vid/next/team-answers || { cp .vid/next/team-answers "$T/out"; fail "the apply did not record ROW-022's yes in its words"; }
grep -q "^amended $N .*rows=[^ ]*ROW-022" .vid/tw/log || fail "#$N was not amended with ROW-022"
exit 0

#!/bin/sh
# Purpose: selftest case — a test the team added that is in the pending spec alone is listed for phase 3 and its yes refused (GM-2
# T7; its case manual-team-pending). The move is lane E's; this case calls checks/team-change.sh as the move will. On the form
# fixture's toy (fixtures/form.sh), S02 posted; ROW-021 added to the working tree's INVENTORY.md after the applied commit; the team
# adds a line naming ROW-021 to S02's body. next.sh changes lists it `pending-only`; next.sh triggers lists its move as the apply
# move's, done from phase 3. The yes is refused, naming the pending spec: nothing written to GitHub, the plan unchanged, no answer
# recorded. Env: CHECKS.
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
grep -q "^move${TB}team-change${TB}#$N ROW-021${TB}.*done from phase 3\$" "$T/tr" || { grep '^move' "$T/tr" > "$T/out"; fail "ROW-021's move is not left to phase 3"; }
cp .vid/RUN-STATE.md "$T/rs0"; P0=$(grep -c '^plan-change ' .vid/metrics-events); gh_wclear
RC=0; sh "$CHECKS/team-change.sh" "$N" ROW-021 yes "Yes, take ROW-021" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'pending spec' "$T/out" || fail "the yes to a pending-only test exited $RC, not a refusal naming the pending spec"
[ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the refused yes wrote to GitHub'; }
cmp -s "$T/rs0" .vid/RUN-STATE.md && [ "$(grep -c '^plan-change ' .vid/metrics-events)" = "$P0" ] || fail 'the refused yes changed the plan'
[ ! -s .vid/next/team-answers ] || { cp .vid/next/team-answers "$T/out"; fail 'the refused yes recorded an answer'; }
exit 0

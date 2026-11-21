#!/bin/sh
# Purpose: selftest case — implement-replan listed with its own proposal and done from the call (GM-3 U6, with U4's apply). On the
# form fixture's toy (fixtures/form.sh) in GitHub manual, S02 posted as #N2, then ROW-012 reworded and committed as a landing leaves
# it (a reset in #N2, nothing that adds a test). `next.sh triggers` lists `implement-replan -` with its own proposal, naming the
# pending reset and the fresh agent's review the rows ViD's planner adds need, and `planning-analysis -` with the pending change,
# saying no wait. The call's listing (next-move.sh call, no move named) makes that own proposal and its page before the owner names
# it (replan.sh own: .vid/next/proposal made own, .vid/pages/REPLAN-PAGE.html), and says so. After the listing ROW-013 is reworded too: `implement-replan "<words>" --review <file>` is shown again, nothing
# applied. Then only what the proposal reads changes (the team adds a line of its own to #N2's body on GitHub):
# named, it is shown again, nothing posted, since its line carries the fingerprint of the proposal it would apply. Then:
# a lower open-tickets limit (a setting outside HEAD that changes the proposal's warnings) shows it again, nothing applied; and
# implement-replan named twice in one call is a usage error (exit 2), nothing done, the proposal's review as it was. Named again as
# just shown, it is done: the applied commit is HEAD, #N2 amended once, its to-do logged done, and the
# lines after the moves list no implement-replan. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-replan-own: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'none\n' > "$T/none"   # the fresh agent's review of the rows ViD's planner adds, as the call makes it
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
reword() { sed "s/$1/$2/" INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; ! git diff --quiet -- INVENTORY.md || fail "the row could not be reworded ($1)"; g commit -qam "$3"; }
reword 'at the stated size of 10,000 active jobs' 'at the stated size of 20,000 active jobs' 'ROW-012 reworded'
CLAUDE_CODE_SESSION_ID=replan-own-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
HOME=$T/home; export HOME; mkdir -p "$HOME"
A0=$(cat .vid/tw/applied)
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
# the listing
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/tr" "$T/out"
grep -q "^move${TB}implement-replan${TB}-${TB}[0-9a-f]*${TB}applies the pending changes with its own proposal [0-9a-f]\{12\}, nothing in them adding a test: reset ROW-012; the rows ViD's planner adds need a fresh agent's review first; needs your words\$" "$T/tr" ||
  fail 'implement-replan is not listed with its own proposal, the pending reset and the review it needs'
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}proposes how the plan takes in the pending changes, 1 rows, 0 spec files" "$T/tr" || fail 'planning-analysis is not listed with the pending change'
! grep -q 'implement-replan needs it first' "$T/tr" || fail 'planning-analysis says implement-replan waits for it, with nothing pending that adds a test'
# the listing the owner sees: the own proposal and its page made before implement-replan can be named
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
grep -q '^proposal: implement-replan.s own proposal made, its page \.vid/pages/REPLAN-PAGE\.html' "$T/out" || fail 'the call does not say it made the own proposal and its page'
[ "$(cat .vid/next/proposal/made 2>/dev/null)" = own ] && [ -f .vid/pages/REPLAN-PAGE.html ] || fail 'the own proposal and its page were not made before implement-replan was named'
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail 'the listing applied something'
# changed since the listing: shown again, nothing applied
reword 'leaves the listings as one read does' 'leaves the listings just as one read does' 'ROW-013 reworded'
call implement-replan 'Yes, apply the reset' --review "$T/none"
[ "$RC" = 0 ] && grep -q '^again implement-replan -: what it would do, or its warnings, changed since the listing; shown again, not done' "$T/out" || fail 'implement-replan, changed since the listing, is not shown again'
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail 'implement-replan shown again applied something'
# only what the proposal reads changed since the listing (the team edits #N2's body): shown again, nothing posted
gh_wclear; printf "The team's own note: the feed is read at six.\n" >> "$FAKEGH/issues/$N2/body"
call implement-replan 'Yes, apply the two resets' --review "$T/none"
[ "$RC" = 0 ] && grep -q '^again implement-replan -: what it would do, or its warnings, changed since the listing; shown again, not done' "$T/out" || fail 'implement-replan, its proposal reading a changed ticket since the listing, is not shown again'
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail 'implement-replan shown again after the body edit applied something'
! grep -v '^owner/vid-state ' "$FAKEGH/writes" | grep -q . || { cp "$FAKEGH/writes" "$T/out"; fail "implement-replan shown again reached the team's repositories"; }
# the open-tickets limit lowered since the listing: shown again, nothing applied
sed 's/^open-tickets: .*/open-tickets: 1/' .vid/tw/settings > "$T/st" && cat "$T/st" > .vid/tw/settings; grep -qx 'open-tickets: 1' .vid/tw/settings || fail 'the limit could not be lowered'
call implement-replan 'Yes, apply the two resets' --review "$T/none"
[ "$RC" = 0 ] && grep -q '^again implement-replan -: what it would do, or its warnings, changed since the listing; shown again, not done' "$T/out" || fail 'implement-replan, the open-tickets limit lowered since the listing, is not shown again'
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail 'implement-replan shown again after the limit changed applied something'
# implement-replan named twice in one call: a usage error, nothing done
printf 'finding RULE-004 | vague\n' > "$T/hit"; cp .vid/next/proposal/review "$T/rv0"
call implement-replan 'Yes' --review "$T/hit" -- implement-replan 'Yes'
[ "$RC" = 2 ] || fail "implement-replan named twice in one call exited $RC, not 2"
[ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log && cmp -s .vid/next/proposal/review "$T/rv0" || fail 'implement-replan named twice did something'
# named again as just shown: done
call implement-replan 'Yes, apply the two resets' --review "$T/none"
[ "$RC" = 0 ] && grep -q '^done implement-replan -: applied in the owner'"'"'s words$' "$T/out" || fail 'implement-replan named as shown was not done'
[ "$(cat .vid/tw/applied)" = "$(git rev-parse HEAD)" ] || fail 'the applied commit is not HEAD after implement-replan'
[ "$(grep -c "^amended $N2 " .vid/tw/log)" = 1 ] || fail "#$N2 was not amended once"
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
! grep -q "${TB}move:implement-replan:" "$T/ql" || fail "implement-replan's to-do is still on the list after it was done (GM-4 F4)"
sed -n '/^after the moves:/,$p' "$T/out" > "$T/after"; ! grep -q "^move${TB}implement-replan${TB}" "$T/after" || fail 'implement-replan is still listed after the apply'
exit 0

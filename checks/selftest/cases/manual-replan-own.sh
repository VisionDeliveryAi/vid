#!/bin/sh
# Purpose: selftest case — implement-replan listed with its own proposal and done from the call (GM-3 U6, with U4's apply). On the
# form fixture's toy (fixtures/form.sh) in GitHub manual, S02 posted as #N2, then ROW-012 reworded and committed as a landing leaves
# it (a reset in #N2, nothing that adds a test). `next.sh triggers` lists `implement-replan -` as making its own proposal,
# and `planning-analysis -` with the pending change, saying no wait. FB-3 C5 (g): the call's listing (next-move.sh call, no move named)
# makes nothing and asks (`proposal due`); named, it makes the own proposal and its page (.vid/next/proposal made own,
# .vid/pages/REPLAN-PAGE.html), shows it and applies nothing, and the lines then list it as applying that proposal, naming the pending
# reset and the fresh agent's review the rows ViD's planner adds need. Then ROW-013 is reworded too: `implement-replan "<words>" --review <file>`
# named once makes the proposal again and shows it, nothing applied. Then only what the proposal reads changes (the team adds a line of its
# own to #N2's body on GitHub): named once, with a proposal gone stale, it is made again and shown, nothing posted. Then:
# a lower open-tickets limit (a setting outside HEAD that changes the proposal's warnings) shows it again, nothing applied; and
# implement-replan named twice in one call is a usage error (exit 2), nothing done, the proposal's review as it was. Named again as
# just shown, it is done: the applied commit is HEAD, #N2 amended once, its to-do logged done, and the
# lines after the moves list no implement-replan. Env: CHECKS.
# selftest-limit: 1800 s
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
grep -q "^move${TB}implement-replan${TB}-${TB}[0-9a-f]*${TB}makes its own proposal for the pending changes, nothing in them adding a test, shows its page and applies nothing; named again, it applies what was shown; needs your words\$" "$T/tr" ||
  fail 'implement-replan is not listed as making its own proposal'
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}proposes how the plan takes in the pending changes, 1 rows, 0 spec files" "$T/tr" || fail 'planning-analysis is not listed with the pending change'
! grep -q 'implement-replan needs it first' "$T/tr" || fail 'planning-analysis says implement-replan waits for it, with nothing pending that adds a test'
# the listing the owner sees: nothing made, the question asked; named, the own proposal and its page are made and shown
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
grep -q '^proposal due: ' "$T/out" && [ ! -d .vid/next/proposal ] || fail 'the call made the own proposal, or did not ask'
made() { call implement-replan "$@"
  [ "$RC" = 0 ] && grep -q "^again implement-replan -: the apply's own proposal is made and its page written" "$T/out" || fail "implement-replan, its proposal due ($1), did not make and show it"
  [ "$(cat .vid/next/proposal/made 2>/dev/null)" = own ] && [ "$(cat .vid/next/proposal/target)" = "$(git rev-parse HEAD)" ] && [ -f .vid/pages/REPLAN-PAGE.html ] || fail "the own proposal and its page were not made ($1)"
  [ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail "making the proposal applied something ($1)"; }
made 'Yes, make it'
grep -q "^move${TB}implement-replan${TB}-${TB}[0-9a-f]*${TB}applies the pending changes with its own proposal [0-9a-f]\{12\}, nothing in them adding a test: reset ROW-012; the rows ViD's planner adds need a fresh agent's review first; needs your words\$" "$T/out" ||
  fail 'implement-replan is not listed with the proposal made, the pending reset and the review it needs'
# changed since the listing, the proposal stale: one naming makes it again and shows it, nothing applied
reword 'leaves the listings as one read does' 'leaves the listings just as one read does' 'ROW-013 reworded'
made 'Yes, apply the reset' --review "$T/none"
# only what the proposal reads changed since the listing (the team edits #N2's body): made again and shown, nothing posted
gh_wclear; H0=$(cat .vid/next/proposal/hash); printf "The team's own note: the feed is read at six.\n" >> "$FAKEGH/issues/$N2/body"
made 'Yes, apply the two resets' --review "$T/none"; [ "$(cat .vid/next/proposal/hash)" != "$H0" ] || fail 'the stale proposal was not made again'
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

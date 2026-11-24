#!/bin/sh
# Purpose: selftest case — a call asks before it makes the re-plan's proposal (FB-3 C5 g). On the form fixture's toy in GitHub manual,
# S02 posted as #N2, ROW-012 reworded and committed (a reset, nothing that adds a test): `implement-replan` is listed; no call makes the
# proposal or its page; each prints one `proposal due` line, saying what it would cover, by count, and how long it takes, "some
# minutes" while none was made. Over two calls, the team editing #N2's body between them, the queue keeps one line of it, its number and
# key the same, and its move is raised as new once. Named, the proposal is made and shown, nothing applied or posted, the seconds it
# took kept; the next call finds it fresh: no `proposal due`, nothing made again. Stale again (ROW-013 reworded): due again, the line
# saying the seconds; named: made and shown again; named again: applied. Env: CHECKS.
# selftest-limit: 1800 s
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-own-asked: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'; printf 'none\n' > "$T/none"
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
reword() { sed "s/$1/$2/" INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; ! git diff --quiet -- INVENTORY.md || fail "the row could not be reworded ($1)"; g commit -qam "$3"; }
reword 'at the stated size of 10,000 active jobs' 'at the stated size of 20,000 active jobs' 'ROW-012 reworded'
CLAUDE_CODE_SESSION_ID=own-asked-case; export CLAUDE_CODE_SESSION_ID; HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
A0=$(cat .vid/tw/applied)
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the call exited $RC"; }
still() { [ "$(cat .vid/tw/applied)" = "$A0" ] && ! grep -q '^amended ' .vid/tw/log || fail "$1 applied something"; }
noprop() { [ ! -d .vid/next/proposal ] && [ ! -f .vid/pages/REPLAN-PAGE.html ] || fail "$1 made the proposal"; still "$1"; }
due() { [ "$(grep -c '^proposal due' "$T/out")" = "$1" ] || fail "$2 printed $(grep -c '^proposal due' "$T/out") proposal due lines, not $1"; }
mvk() { awk -F'\t' '$1 ~ /^move:implement-replan:/ { print $1 "\t" $2 }' .vid/decide/queue/raised; }
ql() { sh "$CHECKS/queue.sh" list 2>/dev/null | awk -F'\t' '$2 ~ /^move:implement-replan:/ { print $1 "\t" $2 }'; }
call; noprop 'the first call'; due 1 'the first call'; cp "$T/out" "$T/c1"
grep -q '^proposal due: .*Make it now?' "$T/c1" && grep '^proposal due' "$T/c1" | grep -q 'the pending changes, 1 rows, 0 spec files' && grep '^proposal due' "$T/c1" | grep -q '1 of 1 open tickets and 1 row' && grep '^proposal due' "$T/c1" | grep -q 'some minutes' || { cp "$T/c1" "$T/out"; fail 'the line does not say what it covers, the tickets and rows it touches, and how long it takes'; }
grep '^proposal due' "$T/c1" | grep -q 'implement-replan' || fail 'the line does not name its move'
K1=$(mvk); Q1=$(ql); [ -n "$K1" ] && [ "$(printf '%s\n' "$Q1" | grep -c .)" = 1 ] || fail 'the queue does not hold one line of implement-replan'
printf "The team's own note: the feed is read at six.\n" >> "$FAKEGH/issues/$N2/body"
call; noprop 'the second call'; due 1 'the second call'
[ "$(mvk)" = "$K1" ] && [ "$(ql)" = "$Q1" ] || fail "the second call raised implement-replan as new: $(mvk), $(ql)"

# named: made and shown, nothing applied, the review not asked of it
gh_wclear; call implement-replan 'Yes, make it'
grep -q '^again implement-replan -: ' "$T/out" && ! grep -q '^done implement-replan' "$T/out" || fail 'named first, implement-replan was not shown, not done'
[ "$(cat .vid/next/proposal/made 2>/dev/null)" = own ] && [ -f .vid/pages/REPLAN-PAGE.html ] || fail 'named first, the proposal or its page was not made'
grep -qE '^[0-9]+$' .vid/next/proposal/took || fail 'the seconds it took are not kept'
still 'the first naming'; due 0 'the call that made it'; ! grep -v '^owner/vid-state ' "$FAKEGH/writes" | grep -q . || { cp "$FAKEGH/writes" "$T/out"; fail 'the first naming reached the team'; }
cp -R .vid/next/proposal "$T/p1"; call; due 0 'the call with a fresh proposal'; diff -r .vid/next/proposal "$T/p1" > "$T/d" || fail 'a fresh proposal was made again'
grep -q "^move${TB}implement-replan${TB}" "$T/out" || sh "$CHECKS/next.sh" triggers | grep -q "^move${TB}implement-replan${TB}-${TB}[0-9a-f]*${TB}applies the pending changes with its own proposal" || fail 'a fresh proposal is not listed as it stands'
K2=$(ql); [ "$(printf '%s\n' "$K2" | grep -c .)" = 1 ] || fail 'the queue holds more than one line of implement-replan'

# stale: due again, the seconds said; named: made and shown again; named again: applied
echo 373 > .vid/next/proposal/took; reword 'leaves the listings as one read does' 'leaves the listings just as one read does' 'ROW-013 reworded'
call; due 1 'the call with a stale proposal'; grep '^proposal due' "$T/out" | grep -q '373 seconds' || fail 'the line does not say the seconds the last one took'
[ "$(cat .vid/next/proposal/target)" != "$(git rev-parse HEAD)" ] || fail 'the call made the proposal again'
call implement-replan 'Yes, make it again'; still 'the second making'; [ "$(cat .vid/next/proposal/target)" = "$(git rev-parse HEAD)" ] || fail 'named with a stale proposal, it was not made again'
call implement-replan 'Yes, apply it' --review "$T/none"
grep -q '^done implement-replan -: applied in the owner'"'"'s words' "$T/out" && [ "$(cat .vid/tw/applied)" = "$(git rev-parse HEAD)" ] && [ "$(grep -c "^amended $N2 " .vid/tw/log)" = 1 ] || fail 'named again as shown, it was not applied'
due 0 'the call that applied it'
echo 'manual-own-asked: ok'

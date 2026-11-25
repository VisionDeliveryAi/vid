#!/bin/sh
# Purpose: selftest case — what the apply's posts need is said before the owner's yes, and first by the apply, and refuses nothing
# (FB-4 A3). On the form fixture's toy in GitHub manual, S02 posted as #N2, ROW-012 reworded and committed, no engines line on record and
# no labels-prefix: in the settings: `replan.sh ready` prints a `needs` line for each, `next.sh triggers`' implement-replan move, the
# call's `proposal due` question, its queue line and the line kept for the owner's list each say them with their commands, and the read writes no .git/index.
# Named: the own proposal is made and shown, the missing lines first, as today. The words are outside the
# move's hash: the making listed with them missing and with all met carries one hash, and an implement-replan listed with the settings
# missing is not refused as changed once they are whole. Missing again, the apply prints
# the lines first and applies as today: its records stand and its post is owed, exit 3. With all met neither ready nor the move says
# any, and with nothing pending nothing is said. Env: CHECKS.
# selftest-limit: 1800 s
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-apply-needs: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); E='/vid:vid-accept-step engines "<primary> <other>…" "<words>"'
fm_toy "$T/toy" || fail 'the toy could not be made'; printf 'none\n' > "$T/none"
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
cp .vid/tw/handed "$T/handed"; cp .vid/tw/settings "$T/settings"
out() { sed '/^engines /d' "$T/handed" > .vid/tw/handed; sed '/^labels-prefix:/d' "$T/settings" > .vid/tw/settings; }; whole() { cp "$T/handed" .vid/tw/handed; cp "$T/settings" .vid/tw/settings; }
reword() { sed "s/$1/$2/" INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; ! git diff --quiet -- INVENTORY.md || fail "the row could not be reworded ($1)"; g commit -qam "$3"; }
CLAUDE_CODE_SESSION_ID=apply-needs-case; export CLAUDE_CODE_SESSION_ID; HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
rd() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; }
call() { RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the call exited $RC"; }
mv_() { sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; grep "^move${TB}implement-replan$TB" "$T/tr" > "$T/mv" || { cp "$T/tr" "$T/out"; fail 'implement-replan is not listed'; }; }
says() { cp "$2" "$T/out"; grep -qF "$E" "$2" && grep -q 'labels-prefix' "$2" && grep -qF 'sh checks/planner.sh setup' "$2" || fail "$1 does not say the two missing needs with their commands"; }
quiet() { cp "$2" "$T/out"; ! grep -q 'engines not named\|labels-prefix' "$2" || fail "$1 says a need with all met"; }
# nothing pending: nothing said
out; rd; sh "$CHECKS/replan.sh" ready > "$T/rdy" 2>&1 || fail 'ready failed'; ! grep -q '^needs' "$T/rdy" || { cp "$T/rdy" "$T/out"; fail 'with nothing to apply ready asks what an apply needs'; }
reword 'at the stated size of 10,000 active jobs' 'at the stated size of 20,000 active jobs' 'ROW-012 reworded'; rd
# named before the yes, on a path that writes nothing
sh "$CHECKS/replan.sh" ready > "$T/rdy" 2>&1 || { cp "$T/rdy" "$T/out"; fail 'ready failed'; }
[ "$(grep -c '^needs' "$T/rdy")" = 2 ] && grep -q "^needs${TB}engines${TB}missing${TB}apply${TB}owner$TB" "$T/rdy" && grep -q "^needs${TB}settings${TB}missing${TB}apply${TB}owner$TB" "$T/rdy" || { cp "$T/rdy" "$T/out"; fail 'ready does not print its missing engines and settings lines, and only them'; }
touch -t 202601010000 INVENTORY.md PLAN.md; I0=$(git hash-object .git/index); mv_; [ "$(git hash-object .git/index)" = "$I0" ] || fail 'the read wrote .git/index'
says 'the listed implement-replan' "$T/mv"; HM=$(cut -f4 "$T/mv")
# the words are outside the move's hash: with all met, the same making listed the same
whole; mv_; quiet 'the listed making' "$T/mv"; [ "$(cut -f4 "$T/mv")" = "$HM" ] || fail 'the needs change the hash of the move that makes the proposal'; out
call; cp "$T/out" "$T/c1"; grep '^proposal due' "$T/c1" > "$T/pd" || fail 'the call asks no own proposal'; says 'the question of the own proposal' "$T/pd"
sh "$CHECKS/queue.sh" list > "$T/ql" 2>/dev/null; grep 'implement-replan' "$T/ql" > "$T/qi" || true; says 'the queue line' "$T/qi"
grep "^move${TB}implement-replan${TB}" .vid/next/lines > "$T/pg" || true; says 'the line kept for the owner'"'"'s list' "$T/pg"
# named: made and shown, the missing lines first
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, make it' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 4 ] && [ "$(cat .vid/next/proposal/made)" = own ] || fail "the apply with no proposal shown exited $RC"
sed -n 1,2p "$T/out" > "$T/l2"; grep -q "^needs${TB}engines${TB}missing" "$T/l2" && grep -q "^needs${TB}settings${TB}missing" "$T/l2" || fail 'the apply does not print the missing lines first'; rm -rf .vid/next/proposal
call implement-replan 'Yes, make it'; grep -q '^again implement-replan -: ' "$T/out" || fail 'named first, the proposal was not made and shown'
# listed with them missing; then the engines named (the proposal's fingerprint holds the handed record, so it is listed again, as before
# this batch), the settings whole only after the listing: the same hash, not refused as changed
call; mv_; says 'the listed own proposal' "$T/mv"; cp "$T/handed" .vid/tw/handed; call; mv_; grep -q 'labels-prefix' "$T/mv" && ! grep -q 'engines not named' "$T/mv" || { cp "$T/mv" "$T/out"; fail 'with the engines named the listing does not say the settings alone'; }; H1=$(cut -f4 "$T/mv"); whole; mv_; quiet 'the listed own proposal' "$T/mv"; [ "$(cut -f4 "$T/mv")" = "$H1" ] || fail 'the needs change the hash of the move, so a cure refuses it as changed'
sh "$CHECKS/replan.sh" ready > "$T/rdy" 2>&1; ! grep -q '^needs' "$T/rdy" || { cp "$T/rdy" "$T/out"; fail 'with all met ready says a need'; }
call implement-replan 'Yes, apply it' --review "$T/none"; grep -q "^done implement-replan -: applied in the owner's words\$" "$T/out" && grep -q "^amended $N2 " .vid/tw/log || fail 'listed with the needs missing and named with them met, it was not applied'
# missing again: said first, applied as today, its post owed
reword 'leaves the listings as one read does' 'leaves the listings just as one read does' 'ROW-013 reworded'; rd; out
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, make it again' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 4 ] || fail "the second making exited $RC"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' --review "$T/none" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] && grep -q "owed amend #$N2" "$T/out" && [ "$(sed -n 1p .vid/tw/applied)" = "$(git rev-parse HEAD)" ] || fail "the apply with needs missing exited $RC, or did not apply and owe its post, as it did"
sed -n 1,2p "$T/out" | grep -c "^needs${TB}\(engines\|settings\)${TB}missing" | grep -qx 2 || fail 'the second apply does not print the missing lines first'
echo 'replan-apply-needs: ok'

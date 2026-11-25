#!/bin/sh
# Purpose: selftest case — the ticket asks for the data store its step is the first to set up (FB-4 A5, writer.sh), on TW's
# toy (fixtures/tw-toy.sh). The skeleton's ticket (digest owns the saved searches) and S02's (ingest owns the listings) hold
# the line in their Asks, naming no module; S03's, whose modules own nothing, and the fix ticket of S02 hold none. The line
# is outside what a ticket is amended for: the same ticket without it has the same hash, and no published ticket is due.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-sets-up: $*" >&2; cat "$T/out" "$T/werr" "$T/post" >&2 2>/dev/null; exit 1; }
L='- Set up the data its modules own, as their rows above say, where no earlier ticket has.'
asks() { awk '$0 == "## Asks" { on = 1; next } on && /^## / { exit } on' "$1"; }
tw_toy "$T/toy"; printf 'open-tickets: 5\n' > "$T/s"; grep -v '^open-tickets' .vid/tw/settings > "$T/s2"; cat "$T/s2" "$T/s" > .vid/tw/settings
tw_skel || fail 'the skeleton round failed'
asks .vid/tw/out/issue-1.md | grep -qxF -- "$L" || fail "the skeleton's ticket does not ask for the store its digest module owns"
tw_start S02 && tw_post step S02 || fail 'S02 was not posted'; N2=$TW_N; F2=$TW_F; [ -f "$F2" ] || F2=.vid/tw/out/issue-$N2.md
asks "$F2" | grep -qxF -- "$L" || fail "S02's ticket does not ask for the store its ingest module owns"
tw_start S03 && tw_post step S03 || fail 'S03 was not posted'
! asks "$TW_F" | grep -qF 'Set up the data' || fail "S03's ticket asks for a store none of its modules owns"
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
# the hash is the same without the line, and nothing is due
eval "$(grep '^qhash()' "$CHECKS/writer.sh")"; grep -vxF -- "$L" "$F2" > "$T/without"; ! cmp -s "$F2" "$T/without" || fail 'the line was not taken out'
[ "$(qhash "$F2")" = "$(qhash "$T/without")" ] || fail 'the line changes what a ticket is amended for'
sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || true; ! grep -q "^amend" "$T/out" || fail 'a published ticket is due an amendment'
# a fix ticket of S02, its ticket merged: none
tw_hand 'row ROW-001 accepted'; tw_close "$N2"; sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
tw_hand 'fix ROW-001 | its digest held a job it had sent the day before | decision on pull request 7, close run 4123'
tw_post fix ROW-001 || fail 'the fix ticket was refused'; ! asks "$TW_F" | grep -qF 'Set up the data' || fail 'a fix ticket asks for the store'
exit 0

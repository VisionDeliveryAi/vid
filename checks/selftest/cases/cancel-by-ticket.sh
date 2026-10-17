#!/bin/sh
# Purpose: selftest case — cancel one request by its ticket id (v0.9.8.1 R28, F-17). The gated-run fixture: a full
# request with no --try, held running, is cancelled by `cancel --ticket <id>`: the mark and one `ticket-cancelled
# ticket=<id> try= by=<who>` event are written, TERM reaches its run, and it ends `cancelled`, exit 77; a second
# cancel of it is a no-op; an unknown id is answered, exit 0, marking nothing; and both flags at once are refused.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cancel-by-ticket: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
g add -A && g commit -qm 'one row'; gate_on
touch "$T/hold"
STUB_HOLD="$T/hold" STUB_ENTER="$T/up" sh checks/test.sh request --type full --role orchestrator --why 'a full run, cancelled' > "$T/out" 2>&1 || fail 'the full request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); [ -n "$TK" ] || fail 'no ticket'
grep -qx 'try=' ".vid/requests/$TK/request" || fail 'the full request carries an attempt id'
waitfor "$T/up" 120 || fail 'the full run did not start'
sh checks/test.sh cancel --ticket "$TK" --by owner > "$T/out" 2>&1 || fail 'cancel --ticket failed'
grep -q "^$TK: running — cancel marked, TERM sent to its run" "$T/out" || fail "the cancel did not mark and signal the run: $(cat "$T/out")"
grep -q "^ticket-cancelled ticket=$TK try= by=owner at=" .vid/metrics-events || fail 'no ticket-cancelled event with an empty try='
VID_WAIT_MAX=120 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
[ "$(cat ".vid/requests/$TK/state")" = cancelled ] && [ "$(cat ".vid/requests/$TK/exit")" = 77 ] || fail "the run did not end cancelled, exit 77: $(cat ".vid/requests/$TK/state") $(cat ".vid/requests/$TK/exit" 2>/dev/null)"
sh checks/test.sh cancel --ticket "$TK" > "$T/out" 2>&1 || fail 'the second cancel failed'
grep -q "^$TK: cancelled — left alone" "$T/out" && [ "$(grep -c '^ticket-cancelled ' .vid/metrics-events)" = 1 ] || fail 'the second cancel was not a no-op'
sh checks/test.sh cancel --ticket 20990101T000000Z-dead > "$T/out" 2>&1 || fail 'cancel of an unknown ticket failed'
grep -q 'no ticket 20990101T000000Z-dead at ' "$T/out" || fail 'an unknown ticket is not answered'
if sh checks/test.sh cancel --try t1 --ticket "$TK" > "$T/out" 2>&1; then fail 'both flags at once were taken'; fi
exit 0

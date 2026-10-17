#!/bin/sh
# Purpose: selftest case — the cap trigger (v0.9.7.0.3 spec 3.1, R1, R2;
# §6 A-1). A request stopped at its cap (VID_CAP_SCALE, the test-only
# factor, makes the cap 4 s) ends with `analyst due: cap request=<ticket>`
# in its result, and exactly one `analyst-due request=<ticket>
# reason=cap` event at the home, written before the final state. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "analyst-cap: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
g add -A && g commit -qm 'one row'
gate_on
export VID_CAP_SCALE=0.02 STUB_DOWN_ENDS=1
touch "$T/hold"
STUB_HOLD="$T/hold" sh checks/test.sh request --type full --role orchestrator --why 'a close too slow for its cap' > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
RC=0; VID_WAIT_MAX=40 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 130 ] && [ "$(cat "$TD/state")" = capped ] || fail "the run was not capped (wait exit $RC)"
grep -qx "analyst due: cap request=$TK" "$T/out" || fail 'the result says no analyst due: cap'
[ "$(grep -c "^analyst-due request=$TK reason=cap at=" .vid/metrics-events)" -eq 1 ] || fail 'not exactly one analyst-due reason=cap event'
[ "$(grep -c '^analyst-due ' .vid/metrics-events)" -eq 1 ] || fail 'another trigger fired on a capped run'
exit 0

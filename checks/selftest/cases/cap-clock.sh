#!/bin/sh
# Purpose: selftest case — the cap's clock starts at the slot (v0.9.7.0.2
# spec 3.1, R9; §6 C-2). A request queued behind a held slot for longer
# than its cap (4 s, scaled) is not stopped: its clock starts when it
# takes the slot (`running`), and it ends done, uncapped. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; kill "$H" 2>/dev/null || true; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-clock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
sleep 120 & H=$!
mkdir -p "$T/run/vid-host/stack.1"; printf '%s\n/elsewhere\nother-project\n%s\n' "$H" "$(date +%s)" > "$T/run/vid-host/stack.1/holder"
VID_CAP_SCALE=0.02 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'queued behind another run' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
grep -q ' · cap 4s ' "$T/out" || fail 'the scaled cap is not 4 s'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
sleep 9
[ "$(cat "$TD/state")" = queued ] && [ ! -f "$TD/cap-hit" ] || fail 'the queued request was not queued, or was capped while queued'
kill "$H"; rm -rf "$T/run/vid-host/stack.1"
VID_WAIT_MAX=40 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the request did not end green once the slot was free'
[ "$(cat "$TD/state")" = done ] && [ ! -f "$TD/cap-hit" ] || fail 'the time queued counted against the cap'
[ $(( $(cat "$TD/running-at") - $(sed -n 's/^created=//p' "$TD/request") )) -ge 8 ] || fail 'the run did not wait for the slot'
exit 0

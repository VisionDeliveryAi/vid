#!/bin/sh
# Purpose: selftest case — the run limit (v0.26.10.4 spec R2, R3, R4; §5
# limit-stops). A chatty runner that never ends — a line each second, so
# never silent — is stopped once its awake time reaches the run limit, 15 s
# (VID_RUN_LIMIT_SECONDS): reason=limit, the result's first line `stopped
# at the run limit (15 s awake)`, the event `capped=yes stop=limit`. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "limit-stops: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"
VID_RUN_LIMIT_SECONDS=15 STUB_CHATTY=1 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'chatty and endless' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/cap-hit" 60 || fail 'an endless chatty run was not stopped'
grep -qx 'reason=limit' "$TD/cap-hit" || fail "the stop's reason is not limit: $(cat "$TD/cap-hit")"
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 130 ] || fail "the stopped run's wait exited $RC, not 130"
head -n 1 "$T/out" | grep -qx 'stopped at the run limit (15 s awake)' || fail "the result's first line does not say why"
[ "$(cat "$TD/state")" = capped ] || fail 'the final state is not capped'
grep -q "^ledger-run .* request=$TK .* capped=yes stop=limit " .vid/metrics-events || fail 'the event does not carry capped=yes stop=limit'
exit 0

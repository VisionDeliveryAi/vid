#!/bin/sh
# Purpose: selftest case — a chatty run is never stopped for its length
# (v0.26.10.4 spec R1, R5; §5 silence-chatty-runs-long; the F-10 class). The
# home's history makes the estimate 2 s (start-up 1 s from three inline
# overhead= events, cases 1 s from --expect); a runner that prints a line each
# second runs 20 s, ten times its estimate, with the silence limit at 6 s: it
# runs to its end — state `done`, no cap-hit, a receipt kept. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "silence-chatty-runs-long: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
for _i in 1 2 3; do printf 'ledger-run seconds=2 kind=scoped report=old%s.xml status=0 overhead=1 at=%s\n' "$_i" "$(utcnow)" >> .vid/metrics-events; done
touch "$T/hold"
VID_SILENCE_SECONDS=6 STUB_CHATTY=1 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --expect 1 --why 'a long chatty run' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
grep -q '^estimate 2s ' "$T/out" || fail "the estimate is not 2 s: $(grep '^estimate' "$T/out")"
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/running-at" 30 || fail 'the run did not start'
sleep 20; rm -f "$T/hold"
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 0 ] || fail "the chatty run's wait exited $RC"
[ "$(cat "$TD/state")" = done ] && [ ! -f "$TD/cap-hit" ] || fail "a chatty run at ten times its estimate was stopped (state $(cat "$TD/state"))"
grep -q '^status=0 ran-to-end=yes capped=no report=' "$T/out" || fail 'the result is not a run to its end'
[ -n "$(kept)" ] || fail 'the chatty run kept no receipt'
exit 0

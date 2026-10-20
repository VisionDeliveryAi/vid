#!/bin/sh
# Purpose: selftest case — `wait` reads the watcher's own counts (v0.26.10.4
# spec R3, R4; §5 wait-watch). A held request whose estimate is 2 s (three
# inline overhead= events, --expect 1) runs 15 s: `wait` prints `running
# <awake>s of estimate 2s, silent <s>s of 600s` with the awake and silent
# counts of the ticket's `watch` file, and exits 75 — never `overdue`, though
# the run is far past twice its estimate. With the watcher's process gone,
# `wait` reports `overdue` (exit 76). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "wait-watch: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
for _i in 1 2 3; do printf 'ledger-run seconds=2 kind=scoped report=old%s.xml status=0 overhead=1 at=%s\n' "$_i" "$(utcnow)" >> .vid/metrics-events; done
touch "$T/hold"
VID_SILENCE_SECONDS=600 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --expect 1 --why 'a long held run' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/running-at" 30 || fail 'the run did not start'
sleep 15
W1=$(cat "$TD/watch")
RC=0; VID_WAIT_MAX=1 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
W2=$(cat "$TD/watch")
[ "$RC" -eq 75 ] || fail "a held run's wait exited $RC, not 75"
_ok=no; for _w in "$W1" "$W2"; do
  _a=$(printf '%s\n' "$_w" | sed -n 's/^awake=\([0-9]*\) silent=\([0-9]*\) .*/\1/p'); _s=$(printf '%s\n' "$_w" | sed -n 's/^awake=\([0-9]*\) silent=\([0-9]*\) .*/\2/p')
  grep -qx "running ${_a}s of estimate 2s, silent ${_s}s of 600s" "$T/out" && _ok=yes; done
[ "$_ok" = yes ] || fail "wait's line is not the watch file's counts ($W1 / $W2)"
kill "$(cat "$TD/watcher")"
RC=0; VID_WAIT_MAX=10 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 76 ] && grep -q '^overdue ' "$T/out" || fail "a run whose watcher is gone was not reported overdue (exit $RC)"
rm -f "$T/hold"; _i=0; while ! grep -qxE 'done|capped|stopped|failed-to-start' "$TD/state" 2>/dev/null && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
exit 0

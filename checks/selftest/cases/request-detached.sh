#!/bin/sh
# Purpose: selftest case — a request outlives its caller (v0.9.7.0.2 spec
# 3.1; §6 B-4, round 2 finding 2). The shell that made the request exits
# and its process group is then killed; the run and its watcher go on,
# the run ends and writes `result`, and the final state is done. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-detached: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
set -m   # the caller in its own process group, as an agent's tool call is
sh -c 'sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "the caller ends" -- tests/x > "$0"; sleep 60' "$T/out" &
CP=$!
set +m
waitfor "$T/entered" || fail 'the run did not start'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
kill -TERM -- "-$CP" 2>/dev/null || true; sleep 1; kill -KILL -- "-$CP" 2>/dev/null || true
wait "$CP" 2>/dev/null || true
kill -0 "$CP" 2>/dev/null && fail 'the caller is still alive'
sleep 1
kill -0 "$(cat "$TD/supervisor")" 2>/dev/null || fail 'the run died with its caller'
kill -0 "$(cat "$TD/watcher")" 2>/dev/null || fail "the run's watcher died with its caller"
[ "$(cat "$TD/state")" = running ] || fail 'the run is not running'
rm -f "$T/hold"
VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not end green'
[ -f "$TD/result" ] && [ "$(cat "$TD/state")" = done ] || fail 'no result or final state'
exit 0

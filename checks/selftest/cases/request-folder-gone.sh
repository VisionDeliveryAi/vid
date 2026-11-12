#!/bin/sh
# Purpose: selftest case — a queued request whose ticket folder is gone ends (v0.26.10.12 H3). The gated-run fixture,
# one slot. Ticket A holds the slot; ticket B queues behind it. B's ticket folder is removed, as a self-test's scratch
# or a trashed copy is. Convicts unless B's detached run and its queued checks/test.sh both end within 30 s while A
# still holds the slot. Before the fix such a run waited out its 4-hour queue with no slot it could ever take: the
# orphaned `checks/test.sh serve` processes, one for each case whose scratch went while a
# request was queued. Env: CHECKS.
set -eu
T=$(mktemp -d); SV=''; RP=''
# the case stops only the two pids it recorded, and only when the run under test failed to end them
trap 'set +e; rm -f "$T/hold"; for _p in $SV $RP; do kill -0 "$_p" 2>/dev/null && kill -TERM "$_p"; done; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-folder-gone: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'A holds the slot' -- tests/a > "$T/out" 2>&1 || fail 'A was refused'
waitfor "$T/entered" || fail 'A did not start'
sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'B queues' -- tests/b > "$T/out" 2>&1 || fail 'B was refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
_i=0; while [ ! -s ".vid/requests/$B/pid" ] && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
SV=$(cat ".vid/requests/$B/supervisor" 2>/dev/null || true); RP=$(cat ".vid/requests/$B/pid" 2>/dev/null || true)
[ -n "$SV" ] && [ -n "$RP" ] || fail 'B has no detached run'
sleep 2; [ "$(cat ".vid/requests/$B/state")" = queued ] || fail 'B is not queued'
rm -rf ".vid/requests/$B"
_i=0; while { kill -0 "$SV" 2>/dev/null || kill -0 "$RP" 2>/dev/null; } && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
kill -0 "$RP" 2>/dev/null && fail "B's queued run is still waiting $_i s after its ticket folder went"
kill -0 "$SV" 2>/dev/null && fail "B's detached run is still alive $_i s after its ticket folder went"
grep -q 'tests/b' "$STUB_LOG" && fail 'B reached the harness'
exit 0

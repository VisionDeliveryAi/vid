#!/bin/sh
# Purpose: selftest case — a cancel landing while the run starts (v0.9.7.1 spec 3.6, R6). The gated-run fixture,
# one slot held by A; B (try t2) waits for it. The cancel mark is written into B's ticket and the slot released at
# once, so B's run may take the slot before it reads the mark. Convicts unless B ends cancelled (exit 77) without
# its selection ever reaching the harness, and the slot is free afterwards (a third request runs). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cancel-race: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'A' -- tests/a > "$T/out" 2>&1 || fail 'A refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); waitfor "$T/entered" || fail 'A did not start'
sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'B' -- tests/b > "$T/out" 2>&1 || fail 'B refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); sleep 2
printf 'by=race\nat=x\n' > .vid/requests/$B/cancel; rm -f "$T/hold"
RC=0; VID_WAIT_MAX=40 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 77 ] || fail "B exited $RC, not 77 (state $(cat .vid/requests/$B/state))"
grep -q 'tests/b' "$STUB_LOG" && fail 'B'"'"'s selection reached the harness'
VID_WAIT_MAX=30 sh checks/test.sh wait "$A" > /dev/null 2>&1 || fail 'A did not end'
unset STUB_HOLD
sh checks/test.sh request --type iterate --role builder --try t3 --rows ROW-001 --why 'C' -- tests/c > "$T/out" 2>&1 || fail 'C refused'
C=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=40 sh checks/test.sh wait "$C" > "$T/out" 2>&1 || fail 'the slot was not freed: C did not run'
exit 0

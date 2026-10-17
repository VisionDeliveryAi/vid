#!/bin/sh
# Purpose: selftest case — a running ticket is cancelled through the stop path (v0.9.7.1 spec 3.6, R6). The
# gated-run fixture; ticket A (try t7) running, held by the stub. Convicts unless `cancel --try t7 --by job.sh`
# says `TERM sent`, the stub's `up` ends by the TERM, the stack is brought down, A ends `cancelled` (exit 77,
# `cancelled by job.sh`) with a `ledger-run … report=none … cancelled=yes` event and no receipt, and the slot is
# free afterwards. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cancel-running: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t7 --rows ROW-001 --why 'A' -- tests/a > "$T/out" 2>&1 || fail 'A refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); waitfor "$T/entered" || fail 'A did not start'
[ "$(cat .vid/requests/$A/state)" = running ] || fail 'A is not running'
[ -s .vid/requests/$A/pid-start ] || fail 'serve recorded no pid-start'
sh checks/test.sh cancel --try t7 --by job.sh > "$T/out" 2>&1 || fail 'cancel failed'
grep -q 'TERM sent' "$T/out" || fail "no TERM: $(cat "$T/out")"
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 77 ] || fail "A exited $RC, not 77"
sed -n 1p "$T/out" | grep -qx 'cancelled by job.sh' || fail 'the result does not say cancelled by job.sh'
grep -q '^ledger-run .*report=none .*cancelled=yes' .vid/metrics-events || fail 'no ledger-run cancelled=yes event'
grep -q '|down' "$STUB_LOG" || grep -q ' down' "$STUB_LOG" || fail 'the stack was not brought down'
[ -z "$(ls .vid/ledger-results/*.run-*.xml 2>/dev/null)" ] || fail 'a receipt was kept'
unset STUB_HOLD
sh checks/test.sh request --type iterate --role builder --try t8 --rows ROW-001 --why 'after' -- tests/c > "$T/out" 2>&1 || fail 'C refused'
C=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=40 sh checks/test.sh wait "$C" > /dev/null 2>&1 || fail 'the slot was not freed'
exit 0

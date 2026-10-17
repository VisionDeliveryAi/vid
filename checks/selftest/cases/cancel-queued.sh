#!/bin/sh
# Purpose: selftest case — a queued ticket is cancelled by its attempt id and never starts (v0.9.7.1 spec 3.6, R6).
# The gated-run fixture, one slot. A builder's request without --try is refused. Ticket A (try t1) holds the slot;
# ticket B (try t2) queues behind it. Convicts unless `cancel --try t2` marks B, records `ticket-cancelled
# ticket=<B> try=t2 by=run-manager`, and leaves A running; B never reaches `up`; `wait <B>` exits 77 with
# `cancelled by run-manager` first; and A, released, ends done. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cancel-queued: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
if sh checks/test.sh request --type iterate --role builder --rows ROW-001 --why 'no try' -- tests/x > "$T/out" 2>&1; then fail 'a builder request without --try was taken'; fi
grep -qF -- '--try <id>' "$T/out" || fail 'the refusal does not name --try'
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'A holds the slot' -- tests/a > "$T/out" 2>&1 || fail 'A was refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); waitfor "$T/entered" || fail 'A did not start'
sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'B queues' -- tests/b > "$T/out" 2>&1 || fail 'B was refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
sleep 2; [ "$(cat .vid/requests/$B/state)" = queued ] || fail 'B is not queued'
sh checks/test.sh cancel --try t2 > "$T/out" 2>&1 || fail 'cancel failed'
grep -q "^$B: queued — cancel marked" "$T/out" || fail "cancel did not mark B: $(cat "$T/out")"
grep -q "^ticket-cancelled ticket=$B try=t2 by=run-manager " .vid/metrics-events || fail 'no ticket-cancelled event'
RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 77 ] || fail "wait on B exited $RC, not 77"
sed -n 1p "$T/out" | grep -qx 'cancelled by run-manager' || fail 'the result does not begin cancelled by run-manager'
[ "$(cat .vid/requests/$A/state)" = running ] || fail 'A was touched'
grep -q 'tests/b' "$STUB_LOG" && fail 'B reached the harness'
rm -f "$T/hold"; VID_WAIT_MAX=30 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || fail 'A did not end green'
exit 0

#!/bin/sh
# Purpose: selftest case — a repeated cancel is a no-op (v0.9.7.1 spec 3.6, R6). The gated-run fixture: a queued
# ticket of try t2 behind a held one. Convicts unless a second `cancel --try t2` writes no second
# ticket-cancelled event and says the mark is there (or the ticket left alone, once it ended); and a try no ticket
# carries is answered, exit 0, without any mark. v0.9.7.4: the wait for the first request to start reads its
# ticket's state. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cancel-repeat: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'A' -- tests/a > "$T/out" 2>&1 || fail 'A refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
[ -n "$A" ] || fail 'A has no ticket'
# v0.9.7.4 (the owner's corrections): the wait for A to start is on its ticket's state, not a timer — repeated while
# A is queued or running and its run has not yet entered the held stub (a loaded host took past the old 20 s once)
_i=0; until [ -e "$T/entered" ]; do
  case "$(cat ".vid/requests/$A/state" 2>/dev/null)" in ''|queued|running) ;; *) fail "A ended without starting: $(cat ".vid/requests/$A/state")" ;; esac
  [ "$_i" -lt 600 ] || fail 'A did not start in 600 s'; sleep 1; _i=$((_i + 1)); done
sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'B' -- tests/b > "$T/out" 2>&1 || fail 'B refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
sh checks/test.sh cancel --try t2 > "$T/out" 2>&1 || fail 'cancel failed'
sh checks/test.sh cancel --try t2 > "$T/out" 2>&1 || fail 'the second cancel failed'
grep -q "^$B: \(cancel already marked\|cancelled — left alone\)" "$T/out" || fail "the second cancel is not a no-op: $(cat "$T/out")"
[ "$(grep -c '^ticket-cancelled ' .vid/metrics-events)" = 1 ] || fail 'a second ticket-cancelled was recorded'
sh checks/test.sh cancel --try nobody > "$T/out" 2>&1 || fail 'cancel of an unknown try failed'
grep -q 'no ticket carries try=nobody' "$T/out" || fail 'an unknown try is not answered'
exit 0

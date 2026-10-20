#!/bin/sh
# Purpose: selftest case — a wait never blocks past its bound (v0.9.7.0.2
# spec 3.2, R2; §6 B-2). With the fake compose holding the run, `wait`
# returns in 200 ±5 s (v0.9.7.1 3.5a, R5; 240 before) with exit 75 and one status line (`running <n>s of
# estimate <e>s, silent <s>s of <limit>s` — v0.26.10.4 R4; `cap <c>s` before); under VID_WAIT_MAX=3, the test-only override,
# in about 3 s. Once the hold is released, the next wait prints the result
# and exits 0. A ticket that does not exist exits 2. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "wait-bounded: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --expect 300 --why 'a held run, running well past the wait' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
waitfor "$T/entered" || fail 'the run did not start'
S0=$(date +%s); RC=0
sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
D=$(( $(date +%s) - S0 ))
[ "$RC" -eq 75 ] || fail "wait exited $RC, not 75"
[ "$D" -ge 195 ] && [ "$D" -le 205 ] || fail "wait returned after ${D}s, not 200 ±5"
[ "$(grep -c . "$T/out")" -eq 1 ] || fail 'wait printed more than one line'
grep -qE '^running [0-9]+s of estimate [0-9]+s, silent [0-9]+s of 1200s$' "$T/out" || fail 'the status line is not the stated form'
S0=$(date +%s); RC=0
VID_WAIT_MAX=3 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
D=$(( $(date +%s) - S0 ))
[ "$RC" -eq 75 ] && [ "$D" -ge 2 ] && [ "$D" -le 5 ] || fail "VID_WAIT_MAX=3: exit $RC after ${D}s"
rm -f "$T/hold"
VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the released run did not end green'
grep -q '^status=0 ran-to-end=yes capped=no report=' "$T/out" || fail 'the result has no status line'
RC=0; sh checks/test.sh wait 20000101T000000Z-0000 > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] || fail "a missing ticket exited $RC, not 2"
exit 0

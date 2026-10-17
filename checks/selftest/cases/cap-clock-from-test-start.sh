#!/bin/sh
# Purpose: selftest case — the cap counts from when the tests start (v0.9.8.1 R40, F-32). A held request with a
# 20 s cap whose tests container is first seen running 10 s after it took its slot, its run released at 24 s: it is
# not capped (its deadline 30 s), and tests-at is written; a cap counted from the slot would have stopped it at 20 s.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-clock-from-test-start: $*" >&2; cat "$Q/result" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/cap-clock.sh"
gated_repo "$T/repo"; gate_on
cc_req 0.1
grep -qx 'cap=20' "$Q/request" || fail "the cap is not 20 s: $(grep '^cap=' "$Q/request")"
cc_at 10; cc_tests
_i=0; until [ -s "$Q/tests-at" ] || [ "$_i" -ge 30 ]; do sleep 1; _i=$((_i + 1)); done; [ -s "$Q/tests-at" ] || fail 'no tests-at was written'
cc_at 24; [ ! -f "$Q/cap-hit" ] || fail 'the cap counted from the slot, not from the tests'"'"' start'
rm -f "$T/hold"
VID_WAIT_MAX=120 sh checks/test.sh wait "${Q##*/}" > /dev/null 2>&1 || true
grep -q 'capped=no' "$Q/result" || fail 'the run was capped'
exit 0

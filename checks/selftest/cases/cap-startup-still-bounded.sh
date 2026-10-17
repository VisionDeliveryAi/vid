#!/bin/sh
# Purpose: selftest case — a stack that never comes up still ends (v0.9.8.1 R40). A held request with a 20 s cap whose
# tests container is never seen running is capped, counted from when it took its slot: cap-hit within 60 s, the result
# capped. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-startup-still-bounded: $*" >&2; cat "$Q/result" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/cap-clock.sh"
gated_repo "$T/repo"; gate_on
cc_req 0.1
_i=0; until [ -f "$Q/cap-hit" ] || [ "$_i" -ge 60 ]; do sleep 1; _i=$((_i + 1)); done
[ -f "$Q/cap-hit" ] || fail 'a stack whose tests never started was not capped'
[ ! -f "$Q/tests-at" ] || fail 'tests-at was written though the tests never ran'
rm -f "$T/hold"
VID_WAIT_MAX=120 sh checks/test.sh wait "${Q##*/}" > /dev/null 2>&1 || true
grep -q 'capped=yes' "$Q/result" || fail 'the result does not say capped'
exit 0

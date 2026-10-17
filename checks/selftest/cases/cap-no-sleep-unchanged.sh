#!/bin/sh
# Purpose: selftest case — with no host sleep the cap is unchanged (v0.9.8.1 R43, F-34; the control). A held request
# with a 4 s cap and no clock jump is capped as before: no `slept` file, no sleep line, no slept= in its request, and
# an analyst due for the cap. A held request with a 20 s cap whose clock jumps 20 s at 3 s (a tick gap under twice the
# tick plus 30 s) is capped then: the jump counts against the cap, as time. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-no-sleep-unchanged: $*" >&2; cat "$Q/result" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/cap-clock.sh"
gated_repo "$T/repo"; gate_on
cc_req 0.02
VID_WAIT_MAX=60 sh checks/test.sh wait "${Q##*/}" > /dev/null 2>&1 || true
[ -f "$Q/cap-hit" ] || fail 'the run was not capped'
[ ! -e "$Q/slept" ] || fail 'a sleep was recorded with no tick gap'
grep -q '^host slept' "$Q/result" && fail 'the result says the host slept'
grep -q '^slept=' "$Q/request" && fail 'the request records slept='
grep -q "^analyst-due request=${Q##*/} reason=cap " .vid/metrics-events || fail 'no analyst is due for the cap'
cc_clock; cc_req 0.1; PATH=$CC_PATH
cc_at 3; cc_jump 20
_i=0; until [ -f "$Q/cap-hit" ] || [ "$_i" -ge 12 ]; do sleep 1; _i=$((_i + 1)); done
[ -f "$Q/cap-hit" ] || fail 'a 20 s jump under the sleep threshold did not count against the cap'
[ ! -e "$Q/slept" ] || fail 'a gap under the threshold was taken as sleep'
exit 0

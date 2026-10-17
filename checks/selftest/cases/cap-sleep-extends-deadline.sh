#!/bin/sh
# Purpose: selftest case — host sleep doesn't count against the cap (v0.9.8.1 R43, F-34). A held request with a 20 s
# cap; 3 s after it took its slot the run's clock jumps 100 s while its cap watcher sleeps (a simulated tick gap). The
# watcher takes the gap as host sleep and moves its deadline: released at 11 s, the run is not capped; its result says
# `host slept <n> s during this run` and its request records `slept=<n>`. A second held request whose clock jumps the
# same way, never released, is capped at its cap — with the sleep line and no analyst due for the cap. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-sleep-extends-deadline: $*" >&2; cat "$Q/result" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/cap-clock.sh"
gated_repo "$T/repo"; gate_on
cc_clock; cc_req 0.1; PATH=$CC_PATH
grep -qx 'cap=20' "$Q/request" || fail "the cap is not 20 s: $(grep '^cap=' "$Q/request")"
cc_at 3; cc_jump 100
cc_at 11; [ ! -f "$Q/cap-hit" ] || fail 'the host'"'"'s sleep counted against the cap'
rm -f "$T/hold"
VID_WAIT_MAX=120 sh checks/test.sh wait "${Q##*/}" > /dev/null 2>&1 || true
grep -q 'capped=no' "$Q/result" || fail 'the run was capped'
N=$(sed -n 's/^host slept \([0-9][0-9]*\) s during this run$/\1/p' "$Q/result")
[ -n "$N" ] && [ "$N" -ge 90 ] && [ "$N" -le 110 ] || fail "the result does not say the host slept about 100 s: ${N:-none}"
grep -qx "slept=$N" "$Q/request" || fail 'the request does not record slept='
# never released: capped at its cap, the sleep said, no analyst for the cap
cc_jump 0; PATH="$T/bin:$PATH"; cc_req 0.1; PATH=$CC_PATH
cc_at 3; cc_jump 100
VID_WAIT_MAX=120 sh checks/test.sh wait "${Q##*/}" > /dev/null 2>&1 || true
[ -f "$Q/cap-hit" ] || fail 'a run held past its cap was not capped'
grep -q '^host slept [0-9]* s during this run$' "$Q/result" || fail 'the capped run does not say the host slept'
grep -q "^analyst-due request=${Q##*/} reason=cap " .vid/metrics-events && fail 'an analyst is due for a cap the sleep explains'
exit 0

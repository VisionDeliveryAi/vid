#!/bin/sh
# Purpose: selftest case — with no completed: key the status is classified
# as in 0.9.6.2, and only the wrapper's own signal stops later passes
# (v0.9.7.0.1 spec 3.3, R8; §6 C-4). A selected close inside the gate,
# under a harness contract without completed:: an inline pass exiting 2
# says the 0.9.3 note, is published with status=2, and its deployed pass
# runs (exit 2). SIGINT to test.sh during a held inline pass: exit 130,
# no deployed pass. Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'set +e; [ -n "$P" ] && kill "$P" 2>/dev/null; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "no-completed-key: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  deployed-selector: sel-dep
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
SHA=$(git rev-parse --short=12 HEAD)
RC=0; STUB_STATUS=2 sh checks/test.sh --role close -- 'tests/sel' --deployed-selection 'tests/dep' > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] || fail "exited $RC, not 2"
grep -q 'declares no completed: statuses' "$T/out" || fail 'the note is not said'
[ -f ".vid/ledger-results/$SHA.close.xml" ] || fail 'the inline report was not published as in 0.9.6.2'
grep -q 'profile deployed up --exit-code-from tests tests' "$STUB_LOG" || fail 'the deployed pass did not run'
# the wrapper's own signal still stops the deployed pass
: > "$STUB_LOG"; touch "$T/hold"
set -m
STUB_HOLD="$T/hold" STUB_ENTER="$T/in" STUB_DOWN_ENDS=1 sh checks/test.sh --role close -- 'tests/sel' --deployed-selection 'tests/dep' > "$T/out" 2>&1 &
P=$!
set +m
waitfor "$T/in" 120 || fail 'the held inline pass never came up'
kill -INT "$P"
# v0.9.8.1 (R2): 30 s, not 10 — a loaded host took longer in a full run; a run that waits for the held pass never exits
S=$(date +%s); while kill -0 "$P" 2>/dev/null && [ $(( $(date +%s) - S )) -lt 30 ]; do sleep 1; done
if kill -0 "$P" 2>/dev/null; then rm -f "$T/hold"; wait "$P" || true; P=''; fail 'test.sh did not exit within 30 s of SIGINT'; fi
RC=0; wait "$P" || RC=$?; P=''
[ "$RC" -eq 130 ] || fail "the signalled run exited $RC, not 130"
grep -q 'profile deployed' "$STUB_LOG" && fail 'the deployed pass started after the signal'
exit 0

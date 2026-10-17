#!/bin/sh
# Purpose: selftest case — a completed red inline pass keeps its deployed
# pass (v0.9.7.0.1 spec 3.3, R7; §6 C-3, the expected-unchanged control).
# A selected close inside the gate whose inline pass exits 1 (in completed:)
# with a failing case: its inline receipt is published, the deployed pass
# runs and publishes, and the exit is 1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "red-keeps-deployed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
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
RC=0; STUB_STATUS=1 STUB_CASE=failed sh checks/test.sh --role close -- 'tests/sel' --deployed-selection 'tests/dep' > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "exited $RC, not 1"
[ -f ".vid/ledger-results/$SHA.close.xml" ] || fail 'the red inline receipt was not published'
grep -q 'profile deployed up --exit-code-from tests tests' "$STUB_LOG" || fail 'the deployed pass did not run'
[ -f ".vid/ledger-results/$SHA.close.deployed.xml" ] || fail 'the deployed receipt was not published'
grep -q '^ledger-run .* kind=close report=[^ ]*\.close\.xml status=1 ' .vid/metrics-events && grep -q '^ledger-run .* kind=deployed report=[^ ]*\.close\.deployed\.xml status=1 ' .vid/metrics-events || fail 'the two events are not both there'
exit 0

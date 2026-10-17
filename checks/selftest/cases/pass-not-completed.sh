#!/bin/sh
# Purpose: selftest case — a pass that did not run to its end runs no later
# pass (v0.9.7.0.1 spec 3.3, R7; §6 C-1). The fake Compose's inline pass
# exits 2, outside the harness contract's completed: [0, 1]. On each
# two-pass path — the selected close and the full run inside the gate, the
# full run outside it — no deployed pass starts, no receipt is written,
# the run's one `ledger-run` event says report=none, and the exit is
# non-zero. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "pass-not-completed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
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
gated_repo "$T/repo"
check() { # <label> <test.sh args…>
  _l=$1; shift; : > "$STUB_LOG"; rm -rf .vid/ledger-results; _n=$(grep -c '^ledger-run ' .vid/metrics-events 2>/dev/null || true)
  RC=0; STUB_STATUS=2 sh checks/test.sh "$@" > "$T/out" 2>&1 || RC=$?
  [ "$RC" -ne 0 ] || fail "$_l: exited 0"
  grep -q 'profile deployed' "$STUB_LOG" && fail "$_l: the deployed pass started"
  [ -z "$(ls .vid/ledger-results 2>/dev/null)" ] || fail "$_l: a receipt was written: $(ls .vid/ledger-results)"
  [ "$(grep -c '^ledger-run ' .vid/metrics-events)" -eq $((${_n:-0} + 1)) ] || fail "$_l: not exactly one ledger-run event"
  grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -q '^ledger-run .* report=none status=2 ' || fail "$_l: the event does not say report=none status=2"
  grep -q 'no later pass starts' "$T/out" || fail "$_l: the stop is not said"
}
check 'ungated full run' --role close
gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
check 'gated full run' --role close
check 'gated selected close' --role close -- 'tests/sel' --deployed-selection 'tests/dep'
[ "$(nruns)" -eq 0 ] && [ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null)" ] || fail 'a run folder or a slot outlived the runs'
exit 0

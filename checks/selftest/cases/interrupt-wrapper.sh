#!/bin/sh
# Purpose: selftest case — a signal to the wrapper acts during a pass and
# stops the run (v0.9.7.0.1 spec 3.3, R7; §6 C-2; the measured F-005 path).
# A selected close with its deployed selection, inside the gate; the fake
# Compose's inline pass is held running and ends only when its own
# project's `down` comes ($STUB_DOWN_ENDS), then writes its report late.
# SIGINT is sent to test.sh's own process while that child runs: test.sh
# exits 130 within 30 s (v0.9.8.1: 10 s before); the child had ended while the slot and the run
# folder were still held; no receipt is written and the run folder is not
# recreated by the late write; the slot is released; the deployed pass
# never starts. Fails against 0.9.6.2's test.sh, whose trap waited for the
# foreground pass. v0.9.7.0.12 (3.9, R9): the child is ended by the TERM the
# signal path sends it, before the down (`ended-by-term`), the slot and the
# run folder still held. Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'set +e; [ -n "$P" ] && kill "$P" 2>/dev/null; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "interrupt-wrapper: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
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
touch "$T/hold"
set -m   # job control: the background run does not start with SIGINT ignored
STUB_HOLD="$T/hold" STUB_ENTER="$T/in" STUB_DOWN_ENDS=1 sh checks/test.sh --role close -- 'tests/sel' --deployed-selection 'tests/dep' > "$T/out" 2>&1 &
P=$!
set +m
waitfor "$T/in" || fail 'the inline pass never came up'
kill -INT "$P"
# v0.9.8.1 (R2): 30 s, not 10 — a loaded host took longer in a full run; a test.sh whose trap waits for the held pass never exits
S=$(date +%s); while kill -0 "$P" 2>/dev/null && [ $(( $(date +%s) - S )) -lt 30 ]; do sleep 1; done
if kill -0 "$P" 2>/dev/null; then rm -f "$T/hold"; wait "$P" || true; P=''; fail 'test.sh did not exit within 30 s of SIGINT — the signal waited for the pass'; fi
RC=0; wait "$P" || RC=$?; P=''
[ "$RC" -eq 130 ] || fail "test.sh exited $RC, not 130"
grep -qx 'ended-by-term lease=held folder=exists' "$STUB_LOG" || fail 'the held child had not ended before the slot or the run folder was released'
sleep 2   # room for a late write
[ "$(nruns)" -eq 0 ] || fail 'the run folder is still there, or was recreated'
[ -z "$(ls .vid/ledger-results 2>/dev/null)" ] || fail "a report was written: $(ls .vid/ledger-results)"
[ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null)" ] || fail 'the slot was not released'
grep -q 'profile deployed' "$STUB_LOG" && fail 'the deployed pass started'
grep -q 'interrupted — no report written' "$T/out" || fail 'the wrapper did not say it was interrupted'
exit 0

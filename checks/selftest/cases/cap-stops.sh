#!/bin/sh
# Purpose: selftest case — the watcher stops a run (v0.9.7.0.2 spec 3.1, 3.2,
# R9; §6 C-1; v0.26.10.4 R1, R4: on silence, not at a cap). A `full` request
# whose inline pass goes silent (VID_SILENCE_SECONDS, the test-only override,
# makes the silence limit 5 s), with a teardown that takes 4 s: the watcher
# writes cap-hit and stops the run — no deployed pass, no receipt; a `wait`
# landing during the teardown prints `stopping (silent)` and does not end;
# the next prints the result, the state is `capped` and the event carries
# `capped=yes stop=silent`; no watchdog operation is left. With the
# watcher's process gone, `wait` reports `overdue` at once — no margin.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold" "$T/hold2"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-stops: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
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
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
g add -A && g commit -qm 'one row'
gate_on
export VID_SILENCE_SECONDS=5 STUB_DOWN_ENDS=1
touch "$T/hold"
STUB_HOLD="$T/hold" STUB_DOWN_SLEEP=4 sh checks/test.sh request --type full --role orchestrator --why 'the last close, too slow' > "$T/out" 2>&1 || fail 'the request was refused'
grep -q ' · stops after 5 s with no output, ' "$T/out" || fail 'the silence limit is not 5 s'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/cap-hit" 15 || fail 'the watcher wrote no cap-hit'
sleep 1
RC=0; VID_WAIT_MAX=1 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 75 ] && grep -q '^stopping (silent) ' "$T/out" || fail "a wait during the teardown ended or did not say stopping (silent) (exit $RC)"
[ ! -f "$TD/result" ] || fail 'the result was written before the teardown ended'
RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 130 ] || fail "the capped run's wait exited $RC, not 130"
grep -q '^status=130 ran-to-end=no capped=yes report=none$' "$T/out" || fail 'the result does not say capped'
[ "$(cat "$TD/state")" = capped ] || fail 'the final state is not capped'
grep -q '^ledger-run .* report=none status=130 role=close .* capped=yes stop=silent ' .vid/metrics-events || fail 'the event does not carry capped=yes stop=silent'
[ -z "$(kept)" ] || fail 'a capped run kept a receipt'
grep -q 'profile deployed' "$STUB_LOG" && fail 'the deployed pass ran after the cap'
[ "$(nruns)" -eq 0 ] && [ -z "$(ls "$T/run/vid-host")" ] || fail 'the capped run left its run folder or slot'
[ ! -d .vid/watchdog ] || [ -z "$(ls .vid/watchdog)" ] || fail 'a watchdog operation was left behind'
# the watcher's process gone: overdue at once
touch "$T/hold2"
VID_SILENCE_SECONDS=600 STUB_HOLD="$T/hold2" sh checks/test.sh request --type full --role orchestrator --why 'a run whose watcher dies' > "$T/out" 2>&1 || fail 'the second request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/running-at" 10 || fail 'the second run did not start'
kill "$(cat "$TD/watcher")"
RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 76 ] && grep -q '^overdue ' "$T/out" || fail "a run whose watcher is gone was not reported overdue (exit $RC)"
[ ! -f "$TD/cap-hit" ] || fail 'a dead watcher wrote cap-hit'
# cleanup: `wait` would answer overdue again at once; wait for the run's own final state before $T goes (v0.9.7.0.3)
rm -f "$T/hold2"; _i=0; while ! grep -qxE 'done|capped|stopped|failed-to-start' "$TD/state" 2>/dev/null && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
exit 0

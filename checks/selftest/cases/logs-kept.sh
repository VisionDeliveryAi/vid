#!/bin/sh
# Purpose: selftest case — each gated pass keeps its timeline (v0.9.7.0.11
# spec 3.7, R7). A request carrying both passes keeps the stack's own
# lines (Compose `logs --timestamps --tail 20000`) in the ticket's
# timeline.inline.log and timeline.deployed.log — the deployed one read in
# the deployed profile — each taken before that pass's `down`, the last
# one after the request's result is written; a fast one-pass request keeps
# timeline.inline.log too (no threshold). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "logs-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$STUB_LOG" >&2 2>/dev/null; exit 1; }
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
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
: > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'both passes' -- tests/x --deployed-selection sel-dep > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not pass'
waitfor ".vid/requests/$TK/timeline.deployed.log" || fail 'no timeline.deployed.log'
D=.vid/requests/$TK
grep -qx 'stub-logs vid-s1-repo' "$D/timeline.inline.log" || fail 'timeline.inline.log does not hold the stack lines'
grep -qx 'stub-logs vid-s1-repo' "$D/timeline.deployed.log" || fail 'timeline.deployed.log does not hold the stack lines'
grep -E ' logs | down ' "$STUB_LOG" | awk '{ print ($0 ~ / logs /) ? "L" : "D" }' | paste -sd ' ' - | grep -qx 'L D L D' || fail 'each pass did not take its logs before its down'
grep ' logs ' "$STUB_LOG" | tail -n 1 | grep -q -- '--profile deployed logs --timestamps --tail 20000$' || fail 'the deployed pass did not read its logs in the deployed profile, bounded'
grep '^logs-at ' "$STUB_LOG" | tail -n 1 | grep -qx 'logs-at results=1' || fail 'the last pass took its logs before the result was written'
: > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'one pass, fast' -- tests/x > "$T/out" 2>&1 || fail 'the one-pass request was refused'
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the one-pass run did not pass'
waitfor ".vid/requests/$TK/timeline.inline.log" || fail 'a fast one-pass request kept no timeline.inline.log'
[ ! -f ".vid/requests/$TK/timeline.deployed.log" ] || fail 'a one-pass request kept a deployed timeline'
exit 0

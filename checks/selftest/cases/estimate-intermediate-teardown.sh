#!/bin/sh
# Purpose: selftest case — a request with two passes counts the teardown
# between them once (v0.9.7.0.10 spec 3.1, R10). With `teardown` events at
# the home (seconds 7, 9, 30, and an older 500 outside the newest 20), an
# iterate request carrying --deployed-selection is estimated with the
# start-up twice, the cases once and the median teardown, 9 s, once —
# named on its estimate line and recorded `teardown=9` in its ticket — and
# its cap is twice that; then a request with one pass adds no teardown;
# and a full request under a harness declaring deployed-selector: (two
# passes) adds it too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate-intermediate-teardown: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-declared
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
gated_repo "$T/r"; gate_on
{ printf 'teardown seconds=500 report=old.xml at=%s\n' "$(utcnow)"
  i=0; while [ "$i" -lt 17 ]; do printf 'teardown seconds=9 report=x%s.xml at=%s\n' "$i" "$(utcnow)"; i=$((i + 1)); done
  printf 'teardown seconds=7 report=a.xml at=%s\nteardown seconds=30 report=b.xml at=%s\nteardown seconds=30 report=c.xml at=%s\n' "$(utcnow)" "$(utcnow)" "$(utcnow)"; } >> .vid/metrics-events
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'both passes' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the request with both passes was refused'
grep -q '^estimate 199s (start-up 2 × 90s + cases 10s + teardown between the passes 9s) · stops after ' "$T/out" || fail "the teardown between the passes is not counted once: $(grep '^estimate' "$T/out")"
TK=$(tk); grep -qx 'teardown=9' ".vid/requests/$TK/request" || fail 'the ticket does not record teardown=9'
VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > /dev/null 2>&1 || true
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'one pass' -- tests/x > "$T/out" 2>&1 || fail 'the one-pass request was refused'
grep '^estimate' "$T/out" | grep -v teardown | grep -qE '^estimate [0-9]+s \(start-up [0-9]+s \+ cases [0-9]+s\) · stops after ' || fail "a one-pass request counts a teardown: $(grep '^estimate' "$T/out")"
TK=$(tk); grep -qx 'teardown=0' ".vid/requests/$TK/request" || fail 'the one-pass ticket does not record teardown=0'
VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > /dev/null 2>&1 || true
# a full request (outside the run, so no rows are needed) under the deployed-selector harness: two passes
gated_repo "$T/full"
{ printf 'teardown seconds=7 report=a.xml at=%s\nteardown seconds=9 report=b.xml at=%s\n' "$(utcnow)" "$(utcnow)"; } > .vid/metrics-events
sh checks/test.sh request --type full --role orchestrator --why 'the whole ledger' > "$T/out" 2>&1 || fail 'the full request was refused'
grep -q '^estimate 98s (start-up 90s + cases 0s + teardown between the passes 8s) · stops after ' "$T/out" || fail "a full request with two passes does not count the teardown: $(grep '^estimate' "$T/out")"
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > /dev/null 2>&1 || true
exit 0

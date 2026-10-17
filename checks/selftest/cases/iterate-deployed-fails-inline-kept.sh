#!/bin/sh
# Purpose: selftest case — an iterate whose deployed pass alone ends outside
# completed keeps its inline receipt (v0.9.8.1 spec R41, F-29). One request
# with both passes; the inline pass runs to its end and publishes; the
# deployed pass exits 5 (outside completed: [0, 1]). The inline receipt is
# kept and named in the result, which says `deployed pass: ended outside
# completed (exit 5), no receipt` and never that whatever the runner wrote is
# discarded. The control: a request whose inline pass itself ends outside
# completed still says it has no report. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "iterate-deployed-fails-inline-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
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
SHA=$(git rev-parse --short=12 HEAD)
STUB_DEPLOYED_STATUS=5 sh checks/test.sh request --type iterate --role fixer --try t1 --rows ROW-001 --why 'deployed fails' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
STUB_DEPLOYED_STATUS=5 VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
H1=$(printf '%s' tests/x | cksum | cut -d' ' -f1)
R1=$(kept | grep -E "^$SHA\.live\.sel-$H1\.run-[0-9TZ]+-[0-9]+\.xml\$" || true)
[ -n "$R1" ] || fail "the inline receipt was not kept: $(kept)"
kept | grep -q '\.live\.deployed\.' && fail 'a deployed receipt was kept for a pass outside completed'
grep -q "report=$R1\$" "$T/out" || fail 'the result does not name the inline receipt'
grep -qx 'deployed pass: ended outside completed (exit 5), no receipt — the inline pass'"'"'s receipt is kept' "$T/out" || fail 'the result does not say the deployed pass alone ended outside completed'
grep -q 'whatever the runner wrote is discarded' "$T/out" && fail 'the result says the inline receipt is discarded'
# the control: the inline pass itself outside completed still has no report
STUB_STATUS=5 sh checks/test.sh request --type iterate --role fixer --try t1 --rows ROW-001 --why 'inline fails' -- tests/y --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the second request was refused'
TK2=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
STUB_STATUS=5 VID_WAIT_MAX=60 sh checks/test.sh wait "$TK2" > "$T/out" 2>&1 || true
grep -q '^why: no report' "$T/out" || fail 'an inline pass outside completed no longer says it has no report'
grep -q '^deployed pass: ended outside completed' "$T/out" && fail 'an inline pass outside completed was read as the deployed pass alone'
exit 0

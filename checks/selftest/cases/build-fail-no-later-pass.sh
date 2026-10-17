#!/bin/sh
# Purpose: selftest case — a failed image build ends the request (v0.9.7.3 spec 3.9, R9; the 0.9.7.2 rehearsal's
# batch 20261013T100824Z-031d and the live run of 2026-10-13: the deployed pass started after a failed build and hung
# past its cap). The fake Compose fails the inline pass's `up --build` with a failed build, exit 1 — inside the
# harness contract's completed: [0, 1]. A builder's request carrying a deployed selection: no deployed pass starts,
# no receipt is written, and the result's first line says `build failed: no test ran — ` with the build's last error
# line; the same holds for a run outside the gate (the full run with its deployed pass). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "build-fail-no-later-pass: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
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
export STUB_BUILD_FAIL=1
# outside the gate: the full run and its deployed pass
: > "$STUB_LOG"; RC=0; sh checks/test.sh --role close > "$T/out" 2>&1 || RC=$?
[ "$RC" -ne 0 ] || fail 'ungated: exited 0'
grep -q 'profile deployed' "$STUB_LOG" && fail 'ungated: the deployed pass started after a failed build'
grep -q 'ViD test: build failed: no test ran — target tests: failed to solve: DeadlineExceeded' "$T/out" || fail 'ungated: the failed build is not said'
[ -z "$(ls .vid/ledger-results 2>/dev/null)" ] || fail 'ungated: a receipt was written'
# inside the gate: a builder's request with its deployed pass
gate_on; : > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a build that fails' -- tests/x --deployed-selection tests/dep > "$T/out" 2>&1 || fail 'the request was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out" 2>&1 || true
grep -q 'profile deployed' "$STUB_LOG" && fail 'gated: the deployed pass started after a failed build'
head -n 1 ".vid/requests/$K/result" | grep -q '^build failed: no test ran — target tests: failed to solve: DeadlineExceeded: failed to fetch the base image$' || fail "gated: the result does not open with the failed build: $(head -n 1 ".vid/requests/$K/result")"
grep -q 'build failed: no test ran' "$T/out" || fail 'gated: wait does not show the failed build'
[ -z "$(ls .vid/ledger-results 2>/dev/null | grep -v '^\.')" ] || fail "gated: a receipt was written: $(ls .vid/ledger-results)"
exit 0

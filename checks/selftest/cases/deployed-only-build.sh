#!/bin/sh
# Purpose: selftest case — a deployed-only request builds what it runs
# (v0.9.7.0.10 spec 3.8, R15, Codex 9). Inside a develop run, with a
# harness declaring the deployed shape: `request --type deployed` brings
# the product and the profile's services up with --build, then the tests
# with `--profile deployed up --build --exit-code-from tests tests`, from
# the request's frozen checkout (its run folder's ctx) — so a change
# committed since the last run (here app/main.py, standing for a changed
# test dependency) is in what the build sees. A request with both passes
# keeps its deployed pass unbuilt: its inline pass built the same
# checkout. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "deployed-only-build: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
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
    build:
      context: ${VID_TEST_CONTEXT:-.}
      target: tests
'
gated_repo "$T/r"; gate_on
# req <args…>: one request, waited on to its end
req() { sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"
  TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail "the run did not pass: $*"; }
req --type deployed --role builder --try t1 --rows ROW-001 --why 'deployed only' -- tests/d
printf 'main v2\n' > app/main.py; g add -A && g commit -qm 'a changed dependency'
: > "$STUB_LOG"
req --type deployed --role builder --try t1 --rows ROW-001 --why 'deployed only, changed' -- tests/d
grep -q -- '--profile deployed up -d --build product worker$' "$STUB_LOG" || fail 'the product and the profile were not built first'
L=$(grep -- '--profile deployed up --build --exit-code-from tests tests$' "$STUB_LOG") || fail 'the tests were not built for a deployed-only request'
printf '%s\n' "$L" | cut -d'|' -f3 | grep -q '/\.vid/runs/[^/]*/ctx$' || fail "the build is not from the request's frozen checkout: $L"
grep -qx 'ctx-main=main v2 ' "$STUB_LOG" || fail 'the change committed since the last run is not in what the build sees'
: > "$STUB_LOG"
req --type iterate --role builder --try t1 --rows ROW-001 --why 'both passes' -- tests/x --deployed-selection tests/d
grep -q -- '--profile deployed up --exit-code-from tests tests$' "$STUB_LOG" || fail 'the deployed pass of a two-pass request changed'
exit 0

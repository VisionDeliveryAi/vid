#!/bin/sh
# Purpose: selftest case — the selected close's refusals (v0.9.6.1 spec 3.1,
# R1; §6 case 2). Inside a toy develop run under a 0.9.6 plan whose harness
# declares a deployed selector, a selected close without
# --deployed-selection is refused naming it; --deployed-selection with a
# grader's scoped run (a builder's, fixer's or test-author's may carry its
# deployed pass since v0.9.7.0.9, R6 — request-both-passes), and with a whole-ledger close (no selection), is
# refused; under a harness that declares no deployed selector,
# --deployed-selection is refused. Every refusal publishes nothing, leaves
# no run folder and holds no slot. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "close-refusals: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
PLAIN=$COMPOSEFILE
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-declared
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  tests:
    image: runner
'
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
clean() { [ -z "$(ls .vid/ledger-results 2>/dev/null)" ] || fail "$1 published something"; [ "$(nruns)" -eq 0 ] || fail "$1 left a run folder"
  [ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null)" ] || fail "$1 holds a slot"; }
if sh checks/test.sh --role close -- 'sel-inline' > "$T/out" 2>&1; then fail 'a selected close ran without --deployed-selection'; fi
grep -q -- '--deployed-selection' "$T/out" || fail 'the refusal does not name --deployed-selection'
clean 'the close without a deployed selection'
if sh checks/test.sh --role grader -- 'sel' --deployed-selection 'sel-dep' > "$T/out" 2>&1; then fail '--deployed-selection was taken by a grader run'; fi
grep -q 'belongs to a selected close' "$T/out" || fail 'the grader refusal does not say why'
clean 'the grader run'
if sh checks/test.sh --role close --deployed-selection 'sel-dep' > "$T/out" 2>&1; then fail '--deployed-selection was taken by a whole-ledger close'; fi
grep -q 'belongs to a selected close' "$T/out" || fail 'the whole-ledger refusal does not say why'
clean 'the whole-ledger close'
# a harness with no deployed selector
printf '%s' "$PLAIN" > docker-compose.test.yml; g add -A && g commit -qm 'no deployed shape'
if sh checks/test.sh --role close -- 'sel-inline' --deployed-selection 'sel-dep' > "$T/out" 2>&1; then fail '--deployed-selection was taken with no deployed selector declared'; fi
grep -q 'declares no deployed-selector' "$T/out" || fail 'the refusal does not name the missing declaration'
clean 'the close with an undeclared deployed shape'
exit 0

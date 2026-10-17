#!/bin/sh
# Purpose: selftest case — core rows are never deferred (v0.9.7.2 spec 3.7, R11). Under breadth first a feature-step
# row with a product BREACHED is refused, naming its step; so is a row in no step. Nothing is recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "defer-core-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
rows h 13 13; commit_all 'a row in no step'
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
rcpt r1 HEAD inline ROW-002=passed
verdict ROW-002 BREACHED product; verdict ROW-013 BREACHED product
if sh checks/metrics.sh defer --kind product --row ROW-002 --why 'later' --from receipt:r1 > "$T/out" 2>&1; then fail 'a core row was deferred'; fi
grep -q 'ROW-002 sits in feature step S1: a core row is never deferred' "$T/out" || fail 'the refusal does not name the step'
if sh checks/metrics.sh defer --kind product --row ROW-013 --why 'later' --from receipt:r1 > "$T/out" 2>&1; then fail 'a row in no step was deferred'; fi
grep -q '^deferred ' .vid/metrics-events && fail 'a refusal was recorded'
exit 0

#!/bin/sh
# Purpose: selftest case — rule A replaces the claims-per-slice FLAG under
# the gate (v0.9.6 spec 3.5; §7 case 30). A slice tally `verdict slice=1
# claimed=80 breached=0` over the default budget of 60: inside a 0.9.6
# develop run metrics.sh prints no `cost FLAG claims-per-slice`; with the
# gate off it prints it as before; `wall-per-slice` is unchanged either
# way. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "tripwire-gated: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
sh checks/event.sh 'verdict slice=1 claimed=80 breached=0'
sh checks/event.sh 'wall-clock slice=1 seconds=36000'
sh checks/metrics.sh > "$T/out" 2>&1
grep -q 'cost FLAG claims-per-slice' "$T/out" && fail 'the FLAG printed under the gate'
grep -q 'cost FLAG wall-per-slice slice=1' "$T/out" || fail 'wall-per-slice changed under the gate'
sed '/^plan:/d' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md
sh checks/metrics.sh > "$T/out" 2>&1
grep -q 'cost FLAG claims-per-slice slice=1 n=80 budget=60' "$T/out" || fail 'with the gate off the FLAG no longer prints'
grep -q 'cost FLAG wall-per-slice slice=1' "$T/out" || fail 'wall-per-slice changed with the gate off'
exit 0

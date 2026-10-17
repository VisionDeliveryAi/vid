#!/bin/sh
# Purpose: selftest case — switching strategy on one plan (v0.9.7.2 spec 3.1, R1). A breadth-first plan with a
# hardening step; switched to depth first, its markers are inert: `check` accepts a step building on the hardening
# step, a plan change makes it so, and the plan stays valid. Switched back to breadth first, the strategy is refused
# while a step builds on hardening (the line keeps depth-first), and set once the plan holds again. Every switch is
# the owner's, recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "strategy-switch: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null || fail 'the plan was refused'
sh checks/plan.sh strategy depth-first --by owner --words 'depth first for now' > "$T/out" 2>&1 || fail 'depth first was refused'
grep -qx 'strategy: depth-first' .vid/RUN-STATE.md || fail 'the line does not say depth-first'
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 H1 | rows: ROW-005..ROW-008' "$H1L"
chg reorder 'S2 after the hardening' > "$T/out" 2>&1 || fail 'under depth first a step could not build on a kind: hardening step'
sh checks/plan.sh check > "$T/out" 2>&1 || fail 'the plan is invalid under depth first'
if sh checks/plan.sh strategy breadth-first --by owner --words 'breadth again' > "$T/out" 2>&1; then fail 'breadth first was set over a step building on hardening'; fi
grep -q 'S2 builds on H1' "$T/out" || fail 'the refusal does not name the step'
grep -qx 'strategy: depth-first' .vid/RUN-STATE.md || fail 'the refused switch changed the line'
replan "$S1L" "$S2L" "$H1L"; chg reorder 'S2 back on S1' > /dev/null || fail 'the plan change back was refused'
sh checks/plan.sh strategy breadth-first --by owner --words 'breadth again' > "$T/out" 2>&1 || fail 'breadth first was refused on a plan that holds'
grep -qx 'strategy: breadth-first' .vid/RUN-STATE.md || fail 'the line does not say breadth-first'
[ "$(grep -c '^strategy set=' .vid/metrics-events)" -eq 3 ] || fail 'not three recorded switches'
exit 0

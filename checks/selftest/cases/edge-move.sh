#!/bin/sh
# Purpose: selftest case — a move into hardening is its own recorded change (v0.9.7.2 spec 3.2, R3). Under breadth
# first, moving ROW-008 from S2 to the hardening step H1 as `what=edge` is accepted: `plan-change what=edge`, its
# decision kept. A row new to the plan placed straight in hardening is a move too (edge accepted). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "edge-move: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
rows h 13 13; commit_all 'a thirteenth row'
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-007' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-008..ROW-012 | kind: hardening'
chg edge 'ROW-008 is an edge case of the second module' > "$T/out" 2>&1 || fail 'the edge move was refused'
E=$(grep '^plan-change what=edge ' .vid/metrics-events | tail -n 1) || fail 'no plan-change what=edge'
D=$(printf '%s\n' "$E" | sed -n 's/.* decision=\([^ ]*\) .*/\1/p'); grep -qx 'what=edge' ".vid/plans/decisions/$D.why" || fail 'the decision does not say edge'
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-007' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-008..ROW-013 | kind: hardening'
if chg add 'a new row' > "$T/out" 2>&1; then fail 'a new row placed in hardening by add was accepted'; fi
grep -q 'places rows in a hardening step: ROW-013' "$T/out" || fail 'the refusal does not name the new row'
chg edge 'a new edge row' > "$T/out" 2>&1 || fail 'the new row placed by edge was refused'
exit 0

#!/bin/sh
# Purpose: selftest case — the plan block's grammar (v0.9.6 spec 3.1, R1;
# §7 case 20). A toy develop run under a 0.9.6 plan: `plan.sh check`
# accepts a well-formed block, overlapping module prefixes included, and
# refuses, each on its own and naming it: a line that does not parse; a
# step without name:, without modules:, without rows:; an unknown id in
# builds-on:; a cycle; a row in two steps; a row not in INVENTORY.md
# (through a range too); no shared: line. A range expands to its rows.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-grammar: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 4; rows s2 5 6; commit_all rows
S1='step S1 | name: first | modules: app/s1 app/shared | builds-on: - | rows: ROW-001..ROW-004 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 app/shared | builds-on: S1 | rows: ROW-005 ROW-006 | lane: builder'
SH="shared: $PLANS_SHARED"
ok() { sh checks/plan.sh check > "$T/out" 2>&1 || fail "refused: $1"; }
no() { if sh checks/plan.sh check > "$T/out" 2>&1; then fail "accepted: $1"; fi; grep -qF -- "$2" "$T/out" || fail "the refusal of $1 does not say: $2"; }
plan "$S1" "$S2" "$SH"; ok 'a well-formed block with overlapping modules (app/shared in both)'
grep -q '4 steps\|2 steps, 6 rows' "$T/out" || fail 'the range did not expand to its rows'
plan "$S1" 'this is prose' "$S2" "$SH"; no 'an unparsed line' 'line 2: does not parse'
plan 'step S1 | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004' "$S2" "$SH"; no 'no name:' 'step S1 has no name:'
plan 'step S1 | name: first | builds-on: - | rows: ROW-001..ROW-004' "$S2" "$SH"; no 'no modules:' 'step S1 has no modules:'
plan 'step S1 | name: first | modules: app/s1 | builds-on: -' "$S2" "$SH"; no 'no rows:' 'step S1 has no rows:'
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: S9 | rows: ROW-005 ROW-006' "$SH"; no 'an unknown builds-on' 'step S2 builds on S9, which is no step of the plan'
plan 'step S1 | name: first | modules: app/s1 | builds-on: S2 | rows: ROW-001..ROW-004' "$S2" "$SH"; no 'a cycle' 'builds-on: has a cycle'
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-004 ROW-005 ROW-006' "$SH"; no 'a row in two steps' 'ROW-004 is in two steps: S1 and S2'
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-009' "$SH"; no 'a range past INVENTORY' 'ROW-007 (step S2) is not a row of INVENTORY.md'
plan "$S1" "$S2"; no 'no shared: line' 'no shared: line'
exit 0

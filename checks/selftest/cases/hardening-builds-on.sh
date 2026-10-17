#!/bin/sh
# Purpose: selftest case — nothing builds on a hardening step (v0.9.7.2 spec 3.2, R2). Under breadth first, `check`
# and `change` refuse a step whose builds-on names a hardening step, naming both; the refused change keeps the
# recorded plan. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "hardening-builds-on: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
H0=$(grep '^plan-change' .vid/metrics-events | tail -n 1)
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 H1 | rows: ROW-005..ROW-008' "$H1L"
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'check accepted a build on hardening'; fi
grep -q 'step S2 builds on H1, a hardening step' "$T/out" || fail 'check does not name the steps'
if chg reorder 'S2 on H1' > "$T/out" 2>&1; then fail 'change accepted a build on hardening'; fi
grep -q 'nothing builds on a hardening step' "$T/out" || fail 'change does not say why'
[ "$(grep '^plan-change' .vid/metrics-events | tail -n 1)" = "$H0" ] || fail 'the refused change was recorded'
exit 0

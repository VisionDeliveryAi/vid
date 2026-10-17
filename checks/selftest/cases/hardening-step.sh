#!/bin/sh
# Purpose: selftest case — hardening steps (v0.9.7.2 spec 3.2, R2). `kind: hardening` parses after lane: as the
# step line's 7th column (`-` for a feature step, so every reader keeps its columns); any other kind is refused,
# naming the step. A hardening step closes like any step: close-rows lists its rows as set 1, the same eligibility.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "hardening-step: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null
replan "$S1L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-009..ROW-012 | kind: edgy'
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'kind: edgy was accepted'; fi
grep -q 'step H1: kind is hardening, or absent' "$T/out" || fail 'the refusal does not name the step and the kinds'
bf_plan "$S1L" "$S2L" "$H1L" > /dev/null || fail 'the plan was refused'
sh checks/plan.sh parse > "$T/out"
grep -qx "$(printf 'step\tH1\tharden\tapp/s3\tS1\t-\thardening')" "$T/out" || fail 'the hardening step does not parse as its 7th column'
grep -qx "$(printf 'step\tS1\tfirst\tapp/s1\t-\t-\t-')" "$T/out" || fail 'a feature step does not read -'
sh checks/plan.sh start S1 > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null || fail 'S1 did not close'
sh checks/plan.sh start H1 > "$T/out" 2>&1 || fail 'the hardening step was not admitted after S1 was graded'
sh checks/metrics.sh close-rows --steps H1 > "$T/out" 2>&1 || fail 'close-rows refused the hardening step'
for r in 09 10 11 12; do grep -q "^required row=ROW-0$r sets=1" "$T/out" || fail "close-rows does not require ROW-0$r"; done
exit 0

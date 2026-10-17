#!/bin/sh
# Purpose: selftest case — the dependency safeguard (v0.9.7.2 spec 3.4, R5). ROW-003 (S1) holds an open product
# BREACHED; S2 builds on S1 and S3 builds on S1 too, neither done. Moving ROW-003 to the hardening step H1 by edge is
# refused naming each such step; a --not-needed-by naming only S2 is refused (a partial list), naming S3 as missing;
# naming both, with the why, it is accepted, and the decision and the event carry not-needed-by=. A row whose open
# breach is test-class moves freely; a breach with no class reads as product. The dependents come from the last
# recorded plan: they are not looked for in the candidate, where the row's step is already the hardening step.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "dependency-safeguard: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null
S3L='step S3 | name: third | modules: app/s3 | builds-on: S1 | rows: ROW-013'
rows s3 13 13; commit_all 'S3 row'
bf_plan "$S1L" "$S2L" "$S3L" "$H1L" > /dev/null
verdict ROW-003 BREACHED; verdict ROW-004 BREACHED test
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-003' "$S2L" "$S3L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-004 ROW-009..ROW-012 | kind: hardening'
chg edge 'ROW-004: a weak test, edge' > "$T/out" 2>&1 || fail 'a row with a test-class breach was held by the safeguard'
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "$S2L" "$S3L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-003 ROW-004 ROW-009..ROW-012 | kind: hardening'
if chg edge 'ROW-003 later' > "$T/out" 2>&1; then fail 'a product breach moved to hardening with its dependents not done'; fi
grep -q 'ROW-003, needed by S2 (not done)' "$T/out" && grep -q 'ROW-003, needed by S3 (not done)' "$T/out" || fail 'the refusal does not name both steps'
if chg edge 'ROW-003 later' --not-needed-by S2 'S2 reads none of it' > "$T/out" 2>&1; then fail 'a partial --not-needed-by was accepted'; fi
grep -q 'not every such step: S3 is missing' "$T/out" || fail 'the partial refusal does not name the missing step'
chg edge 'ROW-003 later' --not-needed-by S2,S3 'neither reads the export ROW-003 checks' > "$T/out" 2>&1 || fail 'the full --not-needed-by was refused'
grep -q '^plan-change what=edge .* not-needed-by=S2,S3 why=' .vid/metrics-events || fail 'the event does not carry not-needed-by='
D=$(grep '^plan-change what=edge' .vid/metrics-events | tail -n 1 | sed -n 's/.* decision=\([^ ]*\) .*/\1/p')
grep -qx 'not-needed-by=S2,S3' ".vid/plans/decisions/$D.why" && grep -qx 'not-needed-why=neither reads the export ROW-003 checks' ".vid/plans/decisions/$D.why" || fail 'the decision does not keep the steps and the why'
exit 0

#!/bin/sh
# Purpose: selftest case — under depth first every breadth-first marker is inert (v0.9.7.2 spec 3.1, 3.2; R2). With
# no strategy line (depth first): a step may build on a kind: hardening step; a step building on an unclosed,
# ungraded step is admitted under rule B as before (no graded gate); a protected row may sit in a hardening step;
# rows move into one by any change label; step-state reads the step as a feature step; a deferral is refused.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "hardening-inert-depth: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
derive ROW-009 REQ-002; commit_all protected
bf_plan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 H1 | rows: ROW-005..ROW-008' "$H1L" > "$T/out" 2>&1 || fail 'the plan was refused under depth first'
sh checks/plan.sh start S1 > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-009=passed ROW-010=passed ROW-011=passed ROW-012=passed
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'rule B alone did not admit S2 (a graded gate ran under depth first)'
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-003' 'step S2 | name: second | modules: app/s2 | builds-on: S1 H1 | rows: ROW-005..ROW-008' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-004 ROW-009..ROW-012 | kind: hardening'
chg split 'ROW-004 to H1' > "$T/out" 2>&1 || fail 'a split into a hardening step was refused under depth first'
ss H1 > "$T/out" 2>&1; grep -q '^step-state step=H1 kind=feature ' "$T/out" || fail 'step-state reads a hardening step under depth first'
verdict ROW-010 BREACHED product
if sh checks/metrics.sh defer --kind product --row ROW-010 --why 'edge' --from receipt:r1 > "$T/out" 2>&1; then fail 'a deferral was recorded under depth first'; fi
grep -q "breadth first's" "$T/out" || fail 'the refusal does not say deferrals are breadth first'"'"'s'
exit 0

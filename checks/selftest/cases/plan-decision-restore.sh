#!/bin/sh
# Purpose: selftest case — a plan restored to an earlier hash (v0.9.6.2 spec
# 3.3, R3; §6 case 14). Under the gate, plan A, then plan B, then plan A
# again, each recorded: three accepted records, two of them with
# candidate= A's hash and different ids, both kept; the third has prev= B.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-restore: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
bhash() { sed -n "/^## The plan/,\$p" .vid/RUN-STATE.md | sed -n "/^\`\`\`vid-plan/,/^\`\`\`\$/p" | sed "1d;\$d" | sed "s/[[:space:]]*\$//" | { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recs() { ls .vid/plans/decisions/*.why 2>/dev/null || true; }
nrec() { recs | grep -c . || true; }
fld() { sed -n "s/^$1=//p" "$2" | head -n 1; }
lasthash() { grep "^plan-change " .vid/metrics-events | tail -n 1 | sed "s/.* hash=\([0-9a-f]*\) .*/\1/"; }
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 | lane: builder'
SH="shared: $PLANS_SHARED"
OK="--expect"
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; commit_all rows
A1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002'
A2='step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004'
plan "$A1" "$A2" "$SH"; HA=$(bhash)
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'both build' > "$T/out" 2>&1 || fail 'plan A was refused'
plan "$A2" "$A1" "$SH"; HB=$(bhash)
sh checks/plan.sh change reorder 'S2 first' --trigger unknown --expect 'S2 sooner' > "$T/out" 2>&1 || fail 'plan B was refused'
plan "$A1" "$A2" "$SH"
sh checks/plan.sh change reorder 'S1 first again' --trigger unknown --expect 'S1 sooner' > "$T/out" 2>&1 || fail 'plan A restored was refused'
[ "$(nrec)" -eq 3 ] || fail "not three records ($(nrec))"
[ "$(grep -l "^candidate=$HA\$" $(recs) | grep -c .)" -eq 2 ] || fail 'the restored plan does not have two records'
L=$(grep -l "^candidate=$HA\$" $(recs) | xargs grep -l "^prev=$HB\$")
[ -n "$L" ] && [ "$(fld result "$L")" = accepted ] || fail 'the restoring record does not name prev= B'
[ "$(ls .vid/plans/decisions/*.plan | grep -c .)" -eq 3 ] || fail 'not three kept blocks'
exit 0

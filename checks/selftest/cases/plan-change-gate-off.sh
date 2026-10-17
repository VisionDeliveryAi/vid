#!/bin/sh
# Purpose: selftest case — outside the gate, plan.sh change is 0.9.6.1's
# (v0.9.6.2 spec 3.9, R9; §6 case 23). With the run stopped (the gate
# off), `plan.sh change` with its two arguments alone, and with the new
# ones, prints the note and exits 0, writing no event, no kept plan and no
# decision record — as in 0.9.6.1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-change-gate-off: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
bhash() { sed -n "/^## The plan/,\$p" .vid/RUN-STATE.md | sed -n "/^\`\`\`vid-plan/,/^\`\`\`\$/p" | sed "1d;\$d" | sed "s/[[:space:]]*\$//" | { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recs() { ls .vid/plans/decisions/*.why 2>/dev/null || true; }
nrec() { recs | grep -c . || true; }
fld() { sed -n "s/^$1=//p" "$2" | head -n 1; }
lasthash() { grep "^plan-change " .vid/metrics-events | tail -n 1 | sed "s/.* hash=\([0-9a-f]*\) .*/\1/"; }
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 | lane: builder'
SH="shared: $PLANS_SHARED"
OK="--expect"
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan "$S1" "$SH"
gate_on stopped
NE=$(grep -c . .vid/metrics-events)
sh checks/plan.sh change create 'one step' > "$T/out" 2>&1 || fail 'two arguments outside the gate failed'
grep -q 'note' "$T/out" || fail 'no note outside the gate'
sh checks/plan.sh change create 'one step' --trigger initial --expect 'x' > "$T/out" 2>&1 || fail 'the new arguments outside the gate failed'
[ "$(grep -c . .vid/metrics-events)" -eq "$NE" ] || fail 'an event was written outside the gate'
[ ! -d .vid/plans ] || fail 'a plan or a decision was kept outside the gate'
exit 0

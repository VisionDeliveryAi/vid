#!/bin/sh
# Purpose: selftest case — a plan change refused by rule B (v0.9.6.2 spec
# 3.3, R3; §6 case 13). Under the gate: S2 builds on S1 and is started
# while S1 passes; a newer receipt shows ROW-001 failing; a change adding
# a row to the started S2 is refused by rule B. The decision record has
# result=refused with refusal= naming rule B, the candidate block is kept,
# and no plan-change event is written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-rule-b: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
bhash() { sed -n "/^## The plan/,\$p" .vid/RUN-STATE.md | sed -n "/^\`\`\`vid-plan/,/^\`\`\`\$/p" | sed "1d;\$d" | sed "s/[[:space:]]*\$//" | { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recs() { ls .vid/plans/decisions/*.why 2>/dev/null || true; }
nrec() { recs | grep -c . || true; }
fld() { sed -n "s/^$1=//p" "$2" | head -n 1; }
lasthash() { grep "^plan-change " .vid/metrics-events | tail -n 1 | sed "s/.* hash=\([0-9a-f]*\) .*/\1/"; }
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 | lane: builder'
SH="shared: $PLANS_SHARED"
OK="--expect"
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 5; commit_all rows
plan "$S1" "$S2" "$SH"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'S1 then S2' > "$T/out" 2>&1 || fail 'the first plan was refused'
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused'
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'S2 was refused while S1 passes'
rcpt r2 HEAD inline ROW-001=failed ROW-002=passed
NE=$(grep -c '^plan-change ' .vid/metrics-events)
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 ROW-005 | lane: builder' "$SH"; HB=$(bhash)
if sh checks/plan.sh change rows 'ROW-005 joins S2' --trigger scope-change --evidence step:S2 --expect 'S2 covers ROW-005' > "$T/out" 2>&1; then fail 'rows added to S2 on a red S1 were accepted'; fi
grep -q 'rule B' "$T/out" || fail 'the refusal is not rule B'
F=$(grep -l "^candidate=$HB\$" $(recs))
[ -n "$F" ] && [ "$(fld result "$F")" = refused ] || fail 'no refused record for the candidate'
fld refusal "$F" | grep -q 'rule B' || fail 'refusal= does not name rule B'
grep -q 'ROW-005' "${F%.why}.plan" || fail 'the candidate block was not kept'
[ "$(grep -c '^plan-change ' .vid/metrics-events)" -eq "$NE" ] || fail 'a refused change wrote a plan-change event'
exit 0

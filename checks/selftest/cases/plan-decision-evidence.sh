#!/bin/sh
# Purpose: selftest case — evidence references are checked (v0.9.6.2 spec
# 3.3, R3; §6 case 10). Under the gate: a change naming an unknown
# `receipt:` is refused like a missing argument (the hash kept, no event, a
# result=refused record with its block); so are a receipt whose named case
# is not in its .cases, a trigger needing evidence given none, and a word
# that is no trigger. The same change naming a real receipt and its case,
# a step of the plan and HEAD's commit is accepted, its record carrying
# trigger=, evidence= and expect= as given. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-evidence: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
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
plan "$S1" "$SH"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'S1 builds first' > "$T/out" 2>&1 || fail 'the first plan was refused'
H1=$(lasthash)
rcpt r1 HEAD inline ROW-001=failed ROW-002=passed
CASE=$(awk '$1 == "case" { print $2; exit }' .vid/ledger-results/r1.cases)
plan "$S1" "$S2" "$SH"; HB=$(bhash); NE=$(grep -c . .vid/metrics-events)
for args in 'receipt:nope' "receipt:r1#no-such-case" ''; do
  if [ -n "$args" ]; then set -- --evidence "$args"; else set --; fi
  if sh checks/plan.sh change add 'S2 joins' --trigger test-evidence "$@" --expect 'S2 follows S1' > "$T/out" 2>&1; then fail "the change was accepted with evidence '$args'"; fi
done
if sh checks/plan.sh change add 'S2 joins' --trigger hunch --expect 'S2 follows S1' > "$T/out" 2>&1; then fail 'an unknown trigger was accepted'; fi
[ "$(lasthash)" = "$H1" ] && [ "$(grep -c . .vid/metrics-events)" -eq "$NE" ] || fail 'a refused change moved the hash or wrote an event'
[ "$(grep -l '^result=refused' $(recs) | grep -c .)" -eq 4 ] || fail 'not four refused records'
for f in $(grep -l '^result=refused' $(recs)); do [ "$(fld candidate "$f")" = "$HB" ] && [ -f "${f%.why}.plan" ] || fail 'a refused record lacks its candidate'; done
grep -l '^evidence=receipt:nope$' $(recs) | grep -q . || fail 'the refused record does not keep the evidence given'
sh checks/plan.sh change add 'S2 joins' --trigger test-evidence,discovered-dependency --evidence "receipt:r1#$CASE,step:S1,commit:$(git rev-parse --short=12 HEAD)" --expect 'S2 follows S1' --alternatives 'S2 inside S1' > "$T/out" 2>&1 || fail 'the change with real references was refused'
F=$(grep -l '^result=accepted' $(recs) | xargs grep -l "^candidate=$HB\$")
[ -n "$F" ] || fail 'no accepted record for the change'
[ "$(fld trigger "$F")" = test-evidence,discovered-dependency ] && [ "$(fld expect "$F")" = 'S2 follows S1' ] && [ "$(fld alternatives "$F")" = 'S2 inside S1' ] || fail 'the accepted record does not keep the declared fields'
fld evidence "$F" | grep -q "^receipt:r1#" || fail 'the accepted record does not keep its evidence'
exit 0

#!/bin/sh
# Purpose: selftest case — an accepted plan change (v0.9.6.2 spec 3.3,
# R3; §6 case 12). Under the gate, the first `change create` writes a
# result=accepted record with prev=none, what=create, candidate= the
# block's hash, commit= HEAD, trigger= and expect=; its block is kept as
# <id>.plan and as .vid/plans/<hash>.plan; the plan-change event names
# decision=<id>. A second `create` (a new plan written from scratch) has
# prev= the first plan's hash, not none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-accepted: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
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
plan "$S1" "$SH"; HA=$(bhash)
sh checks/plan.sh change create 'one step' --trigger initial --expect 'S1 builds first' > "$T/out" 2>&1 || fail 'the first plan was refused'
[ "$(nrec)" -eq 1 ] || fail 'not one record'
F=$(recs); ID=$(basename "$F" .why)
[ "$(fld id "$F")" = "$ID" ] && [ "$(fld result "$F")" = accepted ] && [ "$(fld what "$F")" = create ] && [ "$(fld prev "$F")" = none ] || fail 'the record is not accepted/create/prev=none'
[ "$(fld candidate "$F")" = "$HA" ] && [ "$(fld commit "$F")" = "$(git rev-parse --short=12 HEAD)" ] || fail 'candidate= or commit= is wrong'
[ "$(fld trigger "$F")" = initial ] && [ "$(fld expect "$F")" = 'S1 builds first' ] && grep -q '^at=' "$F" || fail 'trigger=, expect= or at= is wrong'
cmp -s "${F%.why}.plan" ".vid/plans/$HA.plan" || fail 'the kept candidate is not the accepted plan'
tail -n 1 .vid/metrics-events | grep -qE "^plan-change what=create hash=$HA decision=$ID why=\"one step\" at=" || fail 'plan-change does not name its decision'
plan "$S2" 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "$SH"; HB=$(bhash)
sleep 1
sh checks/plan.sh change create 'the plan rewritten' --trigger scope-change --evidence step:S1 --expect 'S2 now' > "$T/out" 2>&1 || fail 'the second create was refused'
G=$(grep -l "^candidate=$HB\$" $(recs))
[ "$(fld prev "$G")" = "$HA" ] || fail "a second create has prev=$(fld prev "$G"), not the first plan"
exit 0

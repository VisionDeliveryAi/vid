#!/bin/sh
# Purpose: selftest case — a checkpoint's one population (v0.9.7.0.12 spec 3.7; R7; §6 E). S1 is closed (ROW-001,
# ROW-002), S2 started and not closed (ROW-003, ROW-004), S3 not started (ROW-005); HOS-001 is a materialised probe.
# `metrics.sh checkpoint --population` lists ROW-001, ROW-002 and HOS-001, nothing else; `test.sh request --type
# checkpoint` asks for exactly those (a row of a step not started, or not closed, is never in it, so admission never
# refuses it) and its receipt's .rows carries them; recording judges completeness over them: a selection leaving out
# the probe's case is refused naming it, `not-run row=HOS-001`; the whole population's is recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "checkpoint-population: $*" >&2; cat "$T/out" >&2 || true; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 5
awk '/^```$/ && !d { print "hostility | HOS-001 | send another tenant'"'"'s id; expect not-found | protects: ROW-001 | disable: drop the tenant check | tests/invariants/test_hos.py | proved-red: abc123"; d = 1 } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
printf '# Purpose: probes\n' > tests/invariants/test_hos.py; commit_all rows
plan 'step S1 | name: a | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: b | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' \
  'step S3 | name: c | modules: app/s3 | builds-on: S2 | rows: ROW-005' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
_ph=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); _h0=$(git rev-parse --short=12 HEAD)
for _st in S1 S2; do printf 'step-start step=%s plan=%s base=%s at=%s\n' "$_st" "$_ph" "$_h0" "$(utcnow)" >> .vid/metrics-events; done
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
printf 'step-closed step=S1 report=r1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
export STUB_BYSEL=1
sh checks/metrics.sh checkpoint --population > "$T/out" 2>&1 || fail 'no population'
[ "$(sort "$T/out" | paste -sd , -)" = HOS-001,ROW-001,ROW-002 ] || fail "the population: $(paste -sd , "$T/out")"
H='tests/invariants/test_hos.py::test_hos[HOS-001]'
ask() { sh checks/test.sh request --type checkpoint --role orchestrator --why 'checkpoint 1' -- "$@" > "$T/out" 2>&1 || fail 'the checkpoint request was refused'
  TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); bwait || fail "the checkpoint did not end: $(cat "$T/wait")"
  K=$(awk -F'\t' '$1 != "none" { print $1 }' ".vid/requests/$TK/passes" | head -n 1); [ -n "$K" ] || fail 'the checkpoint kept no receipt'; }
ask "$(w 1 1)" "$(w 1 2)"
[ "$(paste -sd , ".vid/requests/$TK/rows")" = HOS-001,ROW-001,ROW-002 ] || fail "the ticket's rows: $(paste -sd , ".vid/requests/$TK/rows")"
[ "$(sort ".vid/ledger-results/$K.rows" | paste -sd , -)" = HOS-001,ROW-001,ROW-002 ] || fail "the receipt's frozen rows"
rc=0; sh checks/metrics.sh checkpoint --n 1 --to ".vid/ledger-results/$K" > "$T/out" 2>&1 || rc=$?
[ "$rc" -eq 2 ] && grep -q '^not-run row=HOS-001 ' "$T/out" || fail "a checkpoint without the probe's case was recorded ($rc)"
ask "$(w 1 1)" "$(w 1 2)" "$H"
sh checks/metrics.sh checkpoint --n 1 --to ".vid/ledger-results/$K" > "$T/out" 2>&1 || fail 'the whole population was not recorded'
grep -q "^checkpoint n=1 report=$K built=2 regressions=0 " .vid/metrics-events || fail 'no checkpoint record'
exit 0

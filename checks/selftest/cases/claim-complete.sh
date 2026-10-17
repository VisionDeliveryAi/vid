#!/bin/sh
# Purpose: selftest case — a complete selected close is claimed (v0.9.6.1
# spec 3.3, R3; §6 case 8). S1 (two rows, one with two variants) is
# closing; the newest checkpoint ran them all. A close whose receipt holds
# every expected case, passed, claims both rows (unverdicted), prints no
# provisional line, exits 0 and writes `step-closed step=S1 report=<the
# kept close receipt>` — named by the kept receipt or by its copy
# <head>.close.xml alike. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "claim-complete: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null
H=$(git rev-parse --short=12 HEAD)
RCPT_KIND=checkpoint rcpt "$H.run-20260101T000000Z-1.checkpoint.xml" HEAD inline ROW-001=failed ROW-001~engine2=failed ROW-002=failed
mkdir -p .vid/close; : > .vid/close/1.rows
K="$H.run-20260101T000100Z-2.close.xml"
RCPT_KIND=close rcpt "$K" HEAD inline ROW-001=passed ROW-001~engine2=passed ROW-002=passed
cp ".vid/ledger-results/$K" ".vid/ledger-results/$H.close.xml"
sh checks/metrics.sh claim --to ".vid/ledger-results/$H.close.xml" --steps S1 > "$T/out" 2>&1 || fail 'a complete close was refused'
grep -qx 'claim row=ROW-001 why=unverdicted' "$T/out" && grep -qx 'claim row=ROW-002 why=unverdicted' "$T/out" || fail 'the closed rows were not claimed'
grep -q '^provisional' "$T/out" && fail 'a row with a population was claimed provisionally'
grep -q '^claim rows=2 held=0 provisional=0 ' "$T/out" || fail 'the summary line'
grep -qE "^step-closed step=S1 report=$K at=" .vid/metrics-events || fail 'no step-closed event naming the kept receipt'
sh checks/metrics.sh claim --to ".vid/ledger-results/$K" --steps S1 > "$T/out" 2>&1 || fail 'the kept name was refused'
grep -q '^claim rows=2 ' "$T/out" || fail 'the kept name did not claim the same rows'
if sh checks/metrics.sh claim --to ".vid/ledger-results/$K" > "$T/out" 2>&1; then fail 'a close was claimed without --steps'; fi
grep -q -- '--steps' "$T/out" || fail 'the refusal does not name --steps'
exit 0

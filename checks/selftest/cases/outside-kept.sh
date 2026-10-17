#!/bin/sh
# Purpose: selftest case — a kept report credits only its frozen rows
# (v0.9.7.0.11 spec 3.1, R1). S1 (ROW-001, ROW-002) is closed and passing;
# S2 (ROW-003) is closing. A close of S2 whose receipt carries `.rows`
# (ROW-003, its request's frozen rows) and whose cases also reach ROW-001 —
# passing there, after an older red receipt of ROW-001 — credits ROW-003
# only: checks/evidence.sh's rows read ROW-001 as red still (the outside
# pass is not credited) and ROW-003 as pass; `metrics.sh claim` claims
# ROW-003 and not ROW-001. The control: the same receipt with no `.rows`
# (a full run's, or one published before 0.9.7.0.11) credits every row it
# reaches — ROW-001 passes and is claimed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "outside-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 3; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null && sh checks/plan.sh start S2 > /dev/null || fail 'the steps did not start'
H=$(git rev-parse --short=12 HEAD)
RCPT_KIND=checkpoint rcpt "$H.run-20260101T000000Z-1.checkpoint.xml" HEAD inline ROW-001=passed ROW-002=passed ROW-003=failed
printf 'step-closed step=S1 report=%s.run-20260101T000000Z-1.checkpoint.xml at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
rcpt "$H.run-20260101T000100Z-2.live.sel-1.xml" HEAD inline ROW-001=failed
[ "$(state ROW-001)" = red ] || fail 'the fixture: ROW-001 is not red before the close'
mkdir -p .vid/close; : > .vid/close/1.rows
K="$H.run-20260101T000200Z-3.close.xml"
RCPT_KIND=close rcpt "$K" HEAD inline ROW-001=passed ROW-003=passed
printf 'ROW-003\n' > ".vid/ledger-results/$K.rows"
[ "$(sh checks/evidence.sh credit "$K")" = ROW-003 ] || fail 'credit is not the frozen rows'
[ "$(state ROW-003)" = pass ] || fail 'the frozen row is not credited'
[ "$(state ROW-001)" = red ] || fail "the outside row was credited: ROW-001 reads $(state ROW-001)"
sh checks/metrics.sh claim --to ".vid/ledger-results/$K" --steps S2 > "$T/out" 2>&1 || fail 'the close was refused'
grep -qx 'claim row=ROW-003 why=unverdicted' "$T/out" || fail 'the frozen row was not claimed'
grep -q '^claim row=ROW-001 ' "$T/out" && fail 'the outside row was claimed'
# the control: no .rows — every row reached is credited
rm -f ".vid/ledger-results/$K.rows"
[ "$(sh checks/evidence.sh credit "$K" | paste -sd ',' -)" = ROW-001,ROW-003 ] || fail 'control: credit is not every row reached'
[ "$(state ROW-001)" = pass ] || fail 'control: a report with no .rows does not credit the row it reached'
sh checks/metrics.sh claim --to ".vid/ledger-results/$K" --steps S2 > "$T/out" 2>&1 || fail 'control: the close was refused'
grep -q '^claim row=ROW-001 ' "$T/out" || fail 'control: the reached row was not claimed'
exit 0

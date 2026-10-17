#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/metrics.sh (v0.9.8 spec 3.4, R15). Claims: a claim
# to a proof receipt (its name carries .proof.) is refused, and a claim from one resolves to no valid receipt. Close
# sets: a closed step's row red on an ordinary receipt and passing on a newer proof receipt is still required at the
# next close (set 4); the control — the same pass on an ordinary receipt — leaves it out. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-receipt-ineligible-metrics: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 3; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'they build' > /dev/null
PH=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); H=$(git rev-parse --short=12 HEAD)
for s in S1 S2; do printf 'step-start step=%s plan=%s base=%s at=%s\n' "$s" "$PH" "$H" "$(utcnow)" >> .vid/metrics-events; done
rcpt "$H.run-r1.close.xml" HEAD inline ROW-001=failed ROW-002=failed
printf 'step-closed step=S1 report=%s.run-r1.close.xml at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
P="$H.proof.sel-9.run-p1.xml"; rcpt "$P" HEAD inline ROW-001=passed
mkdir -p .vid/close; : > .vid/close/1.rows
sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || fail 'close-rows refused'
grep -q '^required row=ROW-001 sets=4 ' "$T/out" || fail 'a row passing only on a proof receipt left the close set'
# the control: an ordinary pass takes ROW-002 out
rcpt "$H.live.sel-8.run-o1.xml" HEAD inline ROW-002=passed
sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || fail 'close-rows refused (control)'
grep -q '^required row=ROW-002 ' "$T/out" && fail 'the control: a row passing on an ordinary receipt is still required'
# claims
if sh checks/metrics.sh claim --to ".vid/ledger-results/$P" > "$T/out" 2>&1; then fail 'a claim to a proof receipt was accepted'; fi
grep -q 'is a proof receipt' "$T/out" || fail 'the refusal does not say proof receipt'
rcpt "$H.run-r2.close.xml" HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed
cp ".vid/ledger-results/$H.run-r2.close.xml" ".vid/ledger-results/$H.close.xml"
if sh checks/metrics.sh claim --from ".vid/ledger-results/$P" --to ".vid/ledger-results/$H.close.xml" --steps S1 > "$T/out" 2>&1; then fail 'a claim from a proof receipt was accepted'; fi
grep -q "names no valid published receipt" "$T/out" || fail 'a proof receipt resolved as a valid published receipt'
sh checks/metrics.sh claim --from ".vid/ledger-results/$H.run-r1.close.xml" --to ".vid/ledger-results/$H.close.xml" --steps S1 > "$T/out" 2>&1 || fail 'the control: a claim from an ordinary receipt was refused'
exit 0

#!/bin/sh
# Purpose: selftest case — not selected is not failed (v0.9.6.1 spec 3.3, R3,
# review finding 5; §6 case 10). ROW-001 is KEPT and passed on an earlier
# receipt; the sparse close named as --from held only ROW-002. A close
# holding both, and then the final whole-ledger full receipt, as --to: the
# before state is every row's state as of --from's publication, so ROW-001
# is not claimed re-paid, while unverdicted ROW-002 is claimed; the full
# close with --steps writes step-closed too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "claim-sparse-from: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null
H=$(git rev-parse --short=12 HEAD); mkdir -p .vid/close; : > .vid/close/1.rows
RCPT_KIND=checkpoint rcpt "$H.run-20260101T000000Z-1.checkpoint.xml" HEAD inline ROW-001=passed ROW-002=failed
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
RCPT_KIND=close rcpt "$H.run-20260101T000100Z-2.close.xml" HEAD inline ROW-002=failed
RCPT_KIND=close rcpt "$H.run-20260101T000200Z-3.close.xml" HEAD inline ROW-001=passed ROW-002=passed
sh checks/metrics.sh claim --from ".vid/ledger-results/$H.run-20260101T000100Z-2.close.xml" --to ".vid/ledger-results/$H.run-20260101T000200Z-3.close.xml" --steps S1 > "$T/out" 2>&1 || fail 'the close was refused'
grep -q 'row=ROW-001' "$T/out" && fail 'a KEPT row absent from the sparse --from was claimed'
grep -qx 'claim row=ROW-002 why=unverdicted' "$T/out" || fail 'the unverdicted row was not claimed'
# the final full close, --from the same sparse receipt
RCPT_KIND=full rcpt "$H.run-20260101T000300Z-4.full.xml" HEAD inline ROW-001=passed ROW-002=passed
cp ".vid/ledger-results/$H.run-20260101T000300Z-4.full.xml" ".vid/ledger-results/$H.full.xml"
sh checks/metrics.sh claim --from ".vid/ledger-results/$H.run-20260101T000100Z-2.close.xml" --to ".vid/ledger-results/$H.full.xml" --steps S1 > "$T/out" 2>&1 || fail 'the full close was refused'
grep -q 'row=ROW-001' "$T/out" && fail 'the full close claimed the KEPT row absent from the sparse --from'
grep -qx 'claim row=ROW-002 why=unverdicted' "$T/out" || fail 'the full close did not claim the unverdicted row'
grep -qE "^step-closed step=S1 report=$H.run-20260101T000300Z-4.full.xml at=" .vid/metrics-events || fail 'the full close wrote no step-closed'
exit 0

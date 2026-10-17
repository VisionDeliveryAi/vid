#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/progress.sh (v0.9.8 spec 3.4, R15). With one
# ordinary receipt and one proof receipt (its name carries .proof.) the estimate is "no estimate yet — fewer than two
# valid receipts": the proof receipt is no receipt the rate reads; the control — a second ordinary receipt — leaves
# that line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-receipt-ineligible-progress: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 4; commit_all rows
plan 'step S1 | name: tenants and feeds | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the step builds' > /dev/null
H=$(git rev-parse --short=12 HEAD)
rcpt "$H.live.sel-1.run-a.xml" HEAD inline ROW-001=failed
rcpt "$H.proof.sel-2.run-b.xml" HEAD inline ROW-001=passed ROW-002=passed
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -q '^| Estimate | no estimate yet — fewer than two valid receipts' "$T/out" || fail 'a proof receipt was counted as a valid receipt'
rcpt "$H.live.sel-3.run-c.xml" HEAD inline ROW-001=failed
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed (control)'
grep -q '^| Estimate | no estimate yet — fewer than two valid receipts' "$T/out" && fail 'the control: two ordinary receipts still read as fewer than two'
exit 0

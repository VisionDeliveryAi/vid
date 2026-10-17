#!/bin/sh
# Purpose: selftest case — a close never supplies its own denominator
# (v0.9.6.1 spec 3.3, R3, review rounds 1–2; §6 case 9). The newest
# checkpoint ran ROW-003 in two variants. A close holding only its first
# variant prints `not-run row=ROW-003 case=…-engine2]`, exits 2, prints no
# `claim` line and closes no step. A failing case prints `failed row=…`
# and refuses alike. ROW-004's test changed after the checkpoint: a close
# passing it claims it and prints `provisional row=ROW-004`, and the
# progress update counts it apart; with a KEPT verdict it is still not
# kept — completion reads only a whole-ledger full receipt (R6). Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "claim-variant: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s2 3 3; rows s2b 4 4; commit_all rows
plan 'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S2 > /dev/null
H0=$(git rev-parse --short=12 HEAD)
RCPT_KIND=checkpoint rcpt "$H0.run-20260101T000000Z-1.checkpoint.xml" HEAD inline ROW-003=passed ROW-003~engine2=passed ROW-004=passed
printf '# a stronger check\n' >> tests/invariants/test_s2b.py; commit_all 'ROW-004 test changed'
H=$(git rev-parse --short=12 HEAD); mkdir -p .vid/close; : > .vid/close/1.rows
RCPT_KIND=close rcpt "$H.run-20260101T000100Z-2.close.xml" HEAD inline ROW-003=passed ROW-004=passed
if sh checks/metrics.sh claim --to ".vid/ledger-results/$H.run-20260101T000100Z-2.close.xml" --steps S2 > "$T/out" 2>&1; then fail 'a close missing a variant was claimed'; fi
grep -q '^not-run row=ROW-003 case=tests/invariants/test_s2.py::test_003\[ROW-003-engine2\]$' "$T/out" || fail 'the missing variant was not named'
grep -q '^claim row=' "$T/out" && fail 'a refused claim printed claim lines'
grep -q '^step-closed' .vid/metrics-events && fail 'a refused claim closed a step'
RCPT_KIND=close rcpt "$H.run-20260101T000200Z-3.close.xml" HEAD inline ROW-003=passed ROW-003~engine2=failed ROW-004=passed
if sh checks/metrics.sh claim --to ".vid/ledger-results/$H.run-20260101T000200Z-3.close.xml" --steps S2 > "$T/out" 2>&1; then fail 'a close failing a variant was claimed'; fi
grep -q '^failed row=ROW-003 case=tests/invariants/test_s2.py::test_003\[ROW-003-engine2\]$' "$T/out" || fail 'the failing variant was not named'
RCPT_KIND=close rcpt "$H.run-20260101T000300Z-4.close.xml" HEAD inline ROW-003=passed ROW-003~engine2=passed ROW-004=passed
sh checks/metrics.sh claim --to ".vid/ledger-results/$H.run-20260101T000300Z-4.close.xml" --steps S2 > "$T/out" 2>&1 || fail 'a complete close was refused'
grep -qx 'claim row=ROW-004 why=unverdicted' "$T/out" && grep -qx 'provisional row=ROW-004' "$T/out" || fail 'ROW-004 was not claimed provisionally'
grep -qx 'provisional row=ROW-003' "$T/out" && fail 'ROW-003, with a population, was claimed provisionally'
sh checks/progress.sh > "$T/out" 2>&1
grep -q '^| Passing | .* rows passing (1 provisional: ' "$T/out" || fail 'the progress update does not count the provisional row apart'
printf 'verdict slice=1 row=ROW-004 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
sh checks/metrics.sh row-state ROW-004 > "$T/out" 2>&1
grep -q '^ROW-004: kept' "$T/out" && fail 'a provisional row counts KEPT for completion without a full receipt'
grep -q 'receipt: none' "$T/out" || fail 'the row state does not say completion has no full receipt'
exit 0

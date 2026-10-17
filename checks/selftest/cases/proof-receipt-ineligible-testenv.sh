#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/testenv.sh's heaviest case (v0.9.8 spec 3.4, R15).
# A proof receipt's case (its name carries .proof.), the slowest on record, is never the heaviest case: `heaviest`
# names the ordinary receipts' slowest; the control — the same case in an ordinary receipt — is named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-receipt-ineligible-testenv: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
cp "$CHECKS/testenv.sh" checks/; commit_all testenv
mkdir -p .vid/ledger-results
printf 'case tests/invariants/test_s1.py::test_a[ROW-001] passed 40\n' > .vid/ledger-results/abc.live.sel-1.run-a.xml.cases; sleep 1
printf 'case tests/invariants/test_s1.py::test_fault[ROW-001] failed 900\n' > .vid/ledger-results/abc.proof.sel-2.run-b.xml.cases
sh checks/testenv.sh heaviest > "$T/out" 2>&1
grep -qxF 'heaviest case=tests/invariants/test_s1.py::test_a[ROW-001] seconds=40 receipt=abc.live.sel-1.run-a.xml' "$T/out" || fail 'a proof receipt'"'"'s case was taken as the heaviest'
cp .vid/ledger-results/abc.proof.sel-2.run-b.xml.cases .vid/ledger-results/abc.live.sel-3.run-c.xml.cases
sh checks/testenv.sh heaviest > "$T/out" 2>&1
grep -qxF 'heaviest case=tests/invariants/test_s1.py::test_fault[ROW-001] seconds=900 receipt=abc.live.sel-3.run-c.xml' "$T/out" || fail 'the control: an ordinary receipt'"'"'s slowest case is not the heaviest'
exit 0

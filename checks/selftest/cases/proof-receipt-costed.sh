#!/bin/sh
# Purpose: selftest case — a proof's receipts are kept for cost and export (v0.9.8 spec 3.4, R15). A proof request
# (--purpose proof) publishes its receipt under a .proof. name with `purpose=proof` in its .tree, its `ledger-run`
# event carries purpose=proof and its seconds, no ordinary copy or alias is written, metrics.sh's cost line reads the
# event, and the run export carries the receipt and its .tree. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "proof-receipt-costed: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; cp "$CHECKS/export.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/; commit_all rows
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1[ROW-001]=failed:2"
K=$(ask "$T/r" --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the fault proof of ROW-001' -- "$TF") || fail 'the proof request was refused'
grep -qx 'purpose=proof' ".vid/requests/$K/request" || fail 'the ticket carries no purpose=proof'
N=$(ls .vid/ledger-results | grep -E '\.xml$' | head -n 1)
case "$N" in *.proof.sel-*.run-*.xml) ;; *) fail "the receipt is not named .proof. ($N)" ;; esac
[ "$(ls .vid/ledger-results | grep -cE '\.xml$')" -eq 1 ] || fail "an ordinary copy or alias was written: $(ls .vid/ledger-results | tr '\n' ' ')"
grep -qx 'purpose=proof' ".vid/ledger-results/$N.tree" || fail 'the .tree carries no purpose=proof'
L=$(grep "^ledger-run .*report=$N " .vid/metrics-events) || fail 'no ledger-run event names the proof receipt'
printf '%s\n' "$L" | grep -q ' purpose=proof' || fail 'the ledger-run event carries no purpose=proof'
S=$(printf '%s\n' "$L" | tr ' ' '\n' | sed -n 's/^seconds=//p')
[ -n "$S" ] || fail 'the ledger-run event carries no seconds'
sh checks/metrics.sh > "$T/m" 2>&1 || true
grep -q "^cost ledger-run-seconds last=$S " "$T/m" || { cat "$T/m" >&2; fail 'the cost line does not read the proof run'"'"'s seconds'; }
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR"
sh checks/export.sh --out "$T/x" > "$T/xo" 2>&1 || { cat "$T/xo" >&2; fail 'the export failed'; }
find "$T/x" -path "*/vid/home/ledger-results/$N" | grep -q . && find "$T/x" -path "*/vid/home/ledger-results/$N.tree" | grep -q . || fail 'the export does not carry the proof receipt and its .tree'
exit 0

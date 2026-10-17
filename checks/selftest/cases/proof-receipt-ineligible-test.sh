#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/test.sh (v0.9.8 spec 3.4, R15). A proof request
# (--purpose proof, the orchestrator's prove-red) whose run has five slow red cases and one over 240 s fires no
# analyst trigger — no analyst-due event, no `analyst due` line; and its receipt is no history for an estimate: an
# ordinary request on the same row after it counts the row as having no history (10 s). The control: the same run as
# an ordinary request fires setup and slow, and after it the row's history is read. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "proof-receipt-ineligible-test: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1a[ROW-001]=failed:70" "$TF::test_1b[ROW-001]=failed:70" "$TF::test_1c[ROW-001]=failed:70" "$TF::test_1d[ROW-001]=failed:70" "$TF::test_1e[ROW-001]=failed:300"
K=$(ask "$T/r" --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the fault proof of ROW-001' -- "$TF") || fail 'the proof request was refused'
[ -z "$(due "$K")" ] || fail 'a proof request wrote an analyst-due event'
grep -q '^analyst due' "$T/res" && fail 'a proof request said analyst due'
ls .vid/ledger-results | grep -q '\.proof\.sel-.*\.run-.*\.xml$' || fail 'the proof receipt is not named .proof.'
# an ordinary request on ROW-001 now: the proof receipt is no history
sh checks/test.sh request --type iterate --role test-author --rows ROW-001 --why 'after the proof' -- "$TF" > "$T/ask2" 2>&1 || fail 'the ordinary request was refused'
grep -q '^no-history 1: ROW-001' "$T/ask2" || { cat "$T/ask2" >&2; fail 'the estimate read the proof receipt as the row'"'"'s history'; }
K2=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/ask2"); VID_WAIT_MAX=60 sh checks/test.sh wait "$K2" > /dev/null 2>&1 || true
# the control: the same run as an ordinary request fires setup and slow; after it the row has history
K3=$(ask "$T/r" --type prove-red --role test-author --rows ROW-001 --why 'an ordinary red' -- "$TF") || fail 'the ordinary prove-red was refused'
due "$K3" | grep -q ' reason=setup ' && due "$K3" | grep -q ' reason=slow ' || fail 'the control: an ordinary request fired no setup and slow triggers'
sh checks/test.sh request --type iterate --role test-author --rows ROW-001 --why 'after the ordinary red' -- "$TF" > "$T/ask4" 2>&1 || fail 'the last request was refused'
grep -q '^no-history' "$T/ask4" && fail 'the control: an ordinary receipt is not read as the row'"'"'s history'
exit 0

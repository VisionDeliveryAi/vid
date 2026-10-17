#!/bin/sh
# Purpose: selftest case — one fault at a time (v0.9.8 spec 3.4, R4). While a proof request (--purpose proof, the
# orchestrator's prove-red) is open, a second proof request is refused, naming the open one; an ordinary request is
# accepted meanwhile (the control); once the first has ended, the next proof request is accepted. A proof request
# asked by any role but the orchestrator, or on an iterate, is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-serial: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
TF=tests/invariants/test_s1.py
rq() { sh checks/test.sh request "$@" > "$T/out" 2>&1; }
if rq --type prove-red --role test-author --purpose proof --rows ROW-001 --why 'x' -- "$TF"; then fail 'a test-author'"'"'s proof request was accepted'; fi
if rq --type iterate --role orchestrator --purpose proof --rows ROW-001 --why 'x' -- "$TF"; then fail 'a proof iterate was accepted'; fi
: > "$T/hold"; STUB_HOLD=$T/hold; STUB_ENTER=$T/entered; export STUB_HOLD STUB_ENTER
rq --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the baseline' -- "$TF" || fail 'the first proof request was refused'
K1=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
waitfor "$T/entered" 30 || fail 'the first proof run never started'
if rq --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the faulted run' -- "$TF"; then fail 'a second proof request was accepted while the first is open'; fi
grep -q "one fault at a time: the proof request $K1 is still open" "$T/out" || fail 'the refusal does not name the open request'
rq --type prove-red --role orchestrator --rows ROW-002 --why 'an ordinary red' -- "$TF" || fail 'the control: an ordinary request was refused'
K2=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
rm -f "$T/hold"
VID_WAIT_MAX=60 sh checks/test.sh wait "$K1" > /dev/null 2>&1 || true
VID_WAIT_MAX=60 sh checks/test.sh wait "$K2" > /dev/null 2>&1 || true
rq --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the faulted run' -- "$TF" || fail 'the next proof request was refused after the first ended'
K3=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=60 sh checks/test.sh wait "$K3" > /dev/null 2>&1 || true
exit 0

#!/bin/sh
# Purpose: selftest case — a proof is conclusive on its target and its control (v0.9.8 spec 3.4, R4). With a clean
# baseline (Q's tree, both cases passed): a faulted run (Q plus exactly the patch) where the target failed and the
# control failed too is inconclusive (control-failed); where the target failed and the control passed it is
# `test-proven result=proven`, and test-state reads ROW-001 proven=yes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-target-control: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"; FT=$(pf_fault)
H=$(git rev-parse --short=12 HEAD)
pf_rcpt "$H.proof.sel-1.run-c.xml" HEAD inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r1.xml" "$FT" inline ROW-001=failed ROW-002=failed
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r1.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=control-failed' ] || fail "a failed control: $(pf_last)"
pf_rcpt "$H.proof.sel-2.run-r2.xml" "$FT" inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r2.xml" > "$T/out"
[ "$(pf_last)" = 'result=proven why=-' ] || fail "target failed, control passed: $(pf_last)"
L=$(grep '^test-proven row=ROW-001 result=proven ' .vid/metrics-events)
for k in " target=$TGT " " control=$CTL " " commit=$(printf '%.12s' "$Q") " ' file=tests/invariants/test_s1.py ' " clean=$H.proof.sel-1.run-c.xml " " red=$H.proof.sel-2.run-r2.xml "; do printf '%s\n' "$L" | grep -qF -- "$k" || fail "the record lacks$k: $L"; done
grep -q '^verdict ' .vid/metrics-events && fail 'a proof wrote a verdict'
printf 'ROW-001\tpass\tr\n' > "$T/states"; VID_EVIDENCE_STATES=$T/states sh checks/metrics.sh test-state --rows ROW-001 | grep -q ' proven=yes' || fail 'test-state does not read the proof'
exit 0

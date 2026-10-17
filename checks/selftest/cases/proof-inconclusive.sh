#!/bin/sh
# Purpose: selftest case — anything short of conclusive is inconclusive, never a verdict (v0.9.8 spec 3.4, R4). A patch
# that does not apply at the quoted commit (unappliable), a faulted run that published nothing (no-fault-run), a target
# case absent from the receipts (missing-case) each record `test-proven … result=inconclusive why=<…>` and no verdict;
# an ordinary receipt named as a proof run is refused and records nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-inconclusive: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"; FT=$(pf_fault); H=$(git rev-parse --short=12 HEAD)
pf_rcpt "$H.proof.sel-1.run-c.xml" HEAD inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r.xml" "$FT" inline ROW-001=failed ROW-002=passed
pf_rcpt "$H.live.sel-3.run-o.xml" "$FT" inline ROW-001=failed ROW-002=passed
cp "$T/fault.patch" "$T/good.patch"
sed 's/^ # Purpose: toy module s1$/ # Purpose: a module that is not there/' "$T/good.patch" > "$T/fault.patch"
cmp -s "$T/fault.patch" "$T/good.patch" && fail 'the fixture edit did not change the patch'
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=unappliable' ] || fail "a patch that does not apply: $(pf_last)"
cp "$T/good.patch" "$T/fault.patch"
pf_proof "$H.proof.sel-1.run-c.xml" none > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=no-fault-run' ] || fail "no faulted receipt: $(pf_last)"
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r.xml" 'tests/invariants/test_s1.py::test_nothing[ROW-001]' > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=missing-case' ] || fail "an absent target: $(pf_last)"
N=$(grep -c '^test-proven ' .vid/metrics-events)
if pf_proof "$H.proof.sel-1.run-c.xml" "$H.live.sel-3.run-o.xml" > "$T/out"; then :; fi
grep -q 'is an ordinary receipt' "$T/out" || fail 'an ordinary receipt was not refused as one'
[ "$(grep -c '^test-proven ' .vid/metrics-events)" -eq "$N" ] || fail 'a refused proof recorded something'
grep -q '^verdict ' .vid/metrics-events && fail 'an inconclusive proof wrote a verdict'
exit 0

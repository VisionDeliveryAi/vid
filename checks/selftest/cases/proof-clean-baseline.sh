#!/bin/sh
# Purpose: selftest case — a proof needs a clean baseline (v0.9.8 spec 3.4, R4). A baseline receipt whose tree is not
# the quoted commit's is inconclusive (baseline-tree); one where the target or the control did not pass is inconclusive
# (baseline-failed); a faulted receipt whose tree is not the commit plus exactly the patch is inconclusive (fault-tree);
# none is a verdict. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-clean-baseline: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"; FT=$(pf_fault); H=$(git rev-parse --short=12 HEAD)
# a tree that is neither Q's nor Q plus the patch: the fault and one more change
printf '# Purpose: toy module s2\nextra = 1\n' > app/s2/main.py; GIT_INDEX_FILE=$T/x git read-tree "$FT"; git hash-object -w app/s2/main.py > /dev/null
GIT_INDEX_FILE=$T/x git update-index --add --cacheinfo "100644,$(git hash-object -w app/s2/main.py),app/s2/main.py"; OT=$(GIT_INDEX_FILE=$T/x git write-tree); git checkout -q -- app/s2/main.py
pf_rcpt "$H.proof.sel-1.run-c1.xml" "$FT" inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r.xml" "$FT" inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c1.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=baseline-tree' ] || fail "a baseline on another tree: $(pf_last)"
pf_rcpt "$H.proof.sel-1.run-c2.xml" HEAD inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c2.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=baseline-failed' ] || fail "a baseline whose target failed: $(pf_last)"
pf_rcpt "$H.proof.sel-1.run-c3.xml" HEAD inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r2.xml" "$OT" inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c3.xml" "$H.proof.sel-2.run-r2.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=fault-tree' ] || fail "a faulted run with more than the patch: $(pf_last)"
pf_proof "$H.proof.sel-1.run-c3.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
[ "$(pf_last)" = 'result=proven why=-' ] || fail "the control: a clean baseline and the exact fault: $(pf_last)"
grep -q '^verdict ' .vid/metrics-events && fail 'an inconclusive proof wrote a verdict'
exit 0

#!/bin/sh
# Purpose: selftest case — a conclusive failed proof is a test breach (v0.9.8 spec 3.4, R4). On a clean baseline, a
# faulted run where the target still passed (and the control passed) records `verdict … result=BREACHED class=test
# proof=<the faulted receipt> brief=<the grader brief> quoted-at=<Q>` and no test-proven; test-state reads proven=failed.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-failed-is-test-breach: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"; FT=$(pf_fault); H=$(git rev-parse --short=12 HEAD)
pf_rcpt "$H.proof.sel-1.run-c.xml" HEAD inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r.xml" "$FT" inline ROW-001=passed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
grep -qE "^verdict slice=1 row=ROW-001 result=BREACHED class=test proof=$H.proof.sel-2.run-r.xml brief=$T/grader.md quoted-at=$Q at=" .vid/metrics-events || fail 'no BREACHED class=test verdict naming the proof'
grep -q '^test-proven ' .vid/metrics-events && fail 'a failed proof was recorded proven or inconclusive'
printf 'ROW-001\tpass\tr\n' > "$T/states"; VID_EVIDENCE_STATES=$T/states sh checks/metrics.sh test-state --rows ROW-001 | grep -q ' proven=failed' || fail 'test-state does not read the failed proof'
exit 0

#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/brief.sh (v0.9.8 spec 3.4, R15). A grader brief
# naming a proof receipt (its name carries .proof.) as its --receipt is refused; a hand-back's pass on a proof
# receipt — published by a ledger-run event, present with its .tree, every case passed — is refused as no valid
# receipt of the run, while the same pass on the ordinary GREEN receipt is accepted (the control). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "proof-receipt-ineligible-brief: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
S=${GREEN%%.*}; PR=$S.proof.sel-7.run-PROOF.xml
for x in '' .tree .cases; do cp ".vid/ledger-results/$GREEN$x" ".vid/ledger-results/$PR$x"; done
printf 'purpose=proof\n' >> ".vid/ledger-results/$PR.tree"
printf 'ledger-run seconds=3 kind=scoped report=%s status=0 role=orchestrator purpose=proof at=2026-10-02T11:02:00Z\n' "$PR" >> .vid/metrics-events
RF=.vid/briefs/1/builder-1.return.md
blk() { printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$(git rev-parse HEAD)" "$1" > "$RF"; }
blk "$PR"; if sh checks/brief.sh return "$RF" > "$T/out" 2>&1; then fail 'a pass on a proof receipt was accepted'; fi
grep -qF 'line 5: ROW-101' "$T/out" && grep -qF 'is not a valid receipt' "$T/out" || fail 'the refusal does not name the line and say it is no valid receipt'
blk "$GREEN"; sh checks/brief.sh return "$RF" > "$T/out" 2>&1 || fail 'the control: a pass on GREEN was refused'
if CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role grader --slice 1 --rows ROW-101 --receipt "$PR" > "$T/out" 2>&1; then fail 'a grader brief on a proof receipt was written'; fi
grep -qF 'is a proof receipt' "$T/out" || fail 'the grader refusal does not say proof receipt'
CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role grader --slice 1 --rows ROW-101 --receipt "$GREEN" > "$T/out" 2>&1 || fail 'the control: a grader brief on GREEN was refused'
exit 0

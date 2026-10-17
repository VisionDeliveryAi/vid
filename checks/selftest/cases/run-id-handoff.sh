#!/bin/sh
# Purpose: selftest case — the run id survives a handoff (v0.9.6.2 spec
# 3.1, R1; §6 case 2). A second develop start in the same folder (a
# takeover, a refresh of checks/ between them) keeps the id: .vid/run is
# unchanged, no .vid/run.parent appears, and both stage lines carry the same
# run=. A `stage … state=end` line carries none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "run-id-handoff: $*" >&2; cat .vid/metrics-events .vid/run >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
sh checks/event.sh 'stage name=develop state=start session=S1 records=4'
[ -f .vid/run ] || fail 'no .vid/run'
cp .vid/run "$T/run.1"
sh checks/event.sh 'stage name=develop state=end session=S1'
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/   # a refresh of checks/
sh checks/event.sh 'stage name=develop state=start session=S2 records=4'
cmp -s .vid/run "$T/run.1" || fail '.vid/run changed at the handoff'
[ ! -f .vid/run.parent ] || fail 'a handoff was taken for a copy'
ID=$(sed -n 's/^id=//p' .vid/run)
[ "$(grep -c " run=$ID at=" .vid/metrics-events)" -eq 2 ] || fail 'the two starts do not carry the same run='
grep 'state=end' .vid/metrics-events | grep -q ' run=' && fail 'a stage end carries run='
exit 0

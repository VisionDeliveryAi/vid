#!/bin/sh
# Purpose: selftest case — a cost from outside the project's session is recorded as reported (v0.9.8.1 R15). The
# brief-write fixture: `cost <grader brief> --agent g9 --tokens 41000 --source agent-tool`, with no agent-start for g9
# (no transcript), records `build-cost role=grader … total=41000 … source=agent-tool`, never `total=unknown`; with
# the agent's transcript found, its figures win and no source= is written; --tokens without --source agent-tool, or
# not a number, is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "cost-reported: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep '^build-cost' .vid/metrics-events >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'bw_return'
mkdir -p .vid/ledger-results
bw_write --role grader --slice 1 --rows ROW-101 --receipt "$GREEN" || fail 'grader brief'; G=$(bw_out)
sh checks/brief.sh cost "$G" --agent g9 --tokens 41000 --source agent-tool > "$T/out" 2>&1 || fail 'the reported cost was refused'
grep -q "^build-cost role=grader slice=1 step=- brief=$G rows=1 rows-passed=- peak=unknown total=41000 before-change=unknown source=agent-tool tool=claude " .vid/metrics-events || fail 'the reported total is not recorded as reported'
grep "brief=$G " .vid/metrics-events | grep -q 'total=unknown' && fail 'a reported total was recorded unknown'
bw_write --role grader --slice 1 --rows ROW-101 --receipt "$GREEN" || fail 'second grader brief'; G2=$(bw_out)
bw_agent g2 edit
sh checks/brief.sh cost "$G2" --agent g2 --tokens 41000 --source agent-tool > "$T/out" 2>&1 || fail 'the cost with a transcript was refused'
grep "^build-cost .*brief=$G2 " .vid/metrics-events | grep -q ' peak=5000 total=13502 before-change=unknown tool=claude ' || fail 'the transcript did not win over the reported total'
grep "^build-cost .*brief=$G2 " .vid/metrics-events | grep -q 'source=' && fail 'a transcript cost carries source='
bw_write --role grader --slice 1 --rows ROW-101 --receipt "$GREEN" || fail 'third grader brief'; G3=$(bw_out)
if sh checks/brief.sh cost "$G3" --agent g3 --tokens 41000 > "$T/out" 2>&1; then fail '--tokens without --source agent-tool was taken'; fi
if sh checks/brief.sh cost "$G3" --agent g3 --tokens many --source agent-tool > "$T/out" 2>&1; then fail 'a --tokens that is not a number was taken'; fi
exit 0

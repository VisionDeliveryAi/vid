#!/bin/sh
# Purpose: selftest case — build-cost from the agent's transcript (v0.9.7.0.7 spec 3.3, R7; §6 C-4).
# The brief-write fixture with bw_builder, bw_return and bw_agent. Convicts unless the build-cost
# event reads: for kind edit, peak=5000 total=13502 before-change=5000 — the failed Edit (context
# 3000) not counted, the second line of one message counted once, the escaped usage in a tool's
# text never read, the Write outside the modules not counted; for kind shell, before-change=2500
# shell; for kind none, before-change=unknown; and with no agent-start for the agent (no
# transcript), peak, total and before-change all unknown. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-return-cost: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep '^build-cost' .vid/metrics-events >&2; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
n=1
cost() { # $1=agent $2=kind (or '' for no transcript) $3=expected tail of the event
  [ $n -gt 1 ] && { bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'the writer refused a brief'; }
  [ -n "$2" ] && bw_agent "$1" "$2"
  printf 'brief: .vid/briefs/1/builder-%s.md\nagent: %s\nbranch: b\ncommit: '"$(git rev-parse HEAD)"'\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$n" "$1" "$GREEN" > .vid/briefs/1/builder-$n.return.md
  sh checks/brief.sh return .vid/briefs/1/builder-$n.return.md > "$T/out" 2>&1 || fail "the hand-back for $1 was refused"
  grep "^build-cost .* brief=.vid/briefs/1/builder-$n.md " .vid/metrics-events | grep -q " $3 tool=" || fail "kind '${2:-no transcript}': the event does not end '$3'"
  n=$((n + 1)); }
cost a1 edit 'peak=5000 total=13502 before-change=5000'
cost a2 shell 'peak=5000 total=16002 before-change=2500 shell'
cost a3 none 'peak=5000 total=13502 before-change=unknown'
cost a4 '' 'peak=unknown total=unknown before-change=unknown'
exit 0

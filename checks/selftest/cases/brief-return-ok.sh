#!/bin/sh
# Purpose: selftest case — a complete hand-back passes and records its build-cost once (v0.9.7.0.7
# spec 3.3, R7, R12; §6 C-1). The brief-write fixture with bw_builder and bw_return, and an agent
# transcript (bw_agent, kind edit). Convicts unless `sh checks/brief.sh return` says ok on a block
# with the four headers and both rows (ROW-101 pass on the GREEN receipt, ROW-102 not, with a
# reason), prints `1 of 2 rows pass`, and appends exactly one `build-cost role=builder slice=1
# step=S1 brief=.vid/briefs/1/builder-1.md rows=2 rows-passed=1 peak=5000 total=13502
# before-change=5000` event; and a second check of the same file still says ok and records nothing.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-return-ok: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/the repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
bw_agent a1 edit
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: worktree-agent-a1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | its case needs the preview route, not built in this step\n' "$(git rev-parse HEAD)" "$GREEN" > .vid/briefs/1/builder-1.return.md
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md > "$T/out" 2>&1 || fail 'a complete hand-back was refused'
grep -qF '1 of 2 rows pass' "$T/out" || fail 'the ok line does not count the passing rows'
[ "$(grep -c '^build-cost ' .vid/metrics-events)" = 1 ] || fail 'not exactly one build-cost event'
grep '^build-cost ' .vid/metrics-events | grep -q '^build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-1.md rows=2 rows-passed=1 peak=5000 total=13502 before-change=5000 tool=claude model=m effort=unknown brief-bytes=[0-9]* agent=a1 at=' || fail "the build-cost event is not as computed (v0.9.7.1 adds tool=, model=, effort=, brief-bytes=; v0.9.8.1 agent=): $(grep '^build-cost' .vid/metrics-events)"
grep -q '^agent-returned role=builder n=1 try=[^ ]* agent=a1 at=' .vid/metrics-events || fail "agent-returned does not carry agent=a1 (v0.9.8.1 R9): $(grep '^agent-returned' .vid/metrics-events)"
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md > "$T/out" 2>&1 || fail 'the re-check was refused'
[ "$(grep -c '^build-cost ' .vid/metrics-events)" = 1 ] || fail 'a re-check recorded build-cost again'
exit 0

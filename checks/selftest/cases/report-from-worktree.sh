#!/bin/sh
# Purpose: selftest case — a report written inside the builder's worktree reaches the run's home (v0.9.7.3 spec 3.9,
# R9; a builder wrote its report with Write in its worktree). The brief-write fixture with bw_builder and bw_return;
# the builder's worktree holds branch vid/1-builder-1. A return whose `not` reason points at the report, the report
# only at the worktree's .vid/briefs/1/builder-1.report.md: `return` copies it to the home's path, says so, and is
# accepted; with no report anywhere it is still refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "report-from-worktree: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
H=$(git rev-parse HEAD); RF=.vid/briefs/1/builder-1.return.md; RP=.vid/briefs/1/builder-1.report.md
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | blocked — see the report\n' "$H" "$GREEN" > "$RF"
git worktree add -q "$T/wt" -b vid/1-builder-1 2>/dev/null
if sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1; then fail 'a reason pointing at a report nowhere was accepted'; fi
mkdir -p "$T/wt/.vid/briefs/1"; printf 'the cause, in detail\n' > "$T/wt/$RP"
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'the report in the worktree was not found'
cmp -s "$T/wt/$RP" "$RP" || fail 'the report was not copied to the run'"'"'s home'
grep -q 'the report was in the worktree' "$T/out" || fail 'the copy is not said'
exit 0

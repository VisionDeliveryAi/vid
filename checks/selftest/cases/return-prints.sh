#!/bin/sh
# Purpose: selftest case — the hand-off in one command (v0.9.7.1 spec 3.7, R7). The brief-write fixture with
# bw_builder and bw_return (brief 1-builder-1). The builder's branch vid/1-builder-1 is a worktree holding a
# commit and an uncommitted file; a continuation package of the try exists. Convicts unless `return … --agent
# a1` says ok and prints each row's cases from the receipts the return names (ROW-101 passed on GREEN, ROW-102
# failed on RED), `merge probe: clean`, the worktree's uncommitted file, the package, and the `law-needed:` line
# verbatim; records `agent-returned role=builder n=1 try=1-builder-1` once; and, the branch's commit changed to
# conflict with HEAD, prints `merge probe: conflicts` naming the path. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-prints: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
B=$(bw_out); grep -qx 'try: 1-builder-1' "$B" || fail 'the fixture brief is not 1-builder-1'
WT=$T/wt; g worktree add -q -b vid/1-builder-1 "$WT" HEAD
( cd "$WT" && printf 'built\n' > notes.txt && g add notes.txt && g commit -qm built && printf 'wip\n' > wip.txt ) || fail 'worktree setup'
C=$(git -C "$WT" rev-parse HEAD)
mkdir -p .vid/continuations/S1/1-builder-1; printf 'schema=1\ntry=1-builder-1\n' > .vid/continuations/S1/1-builder-1/manifest
L='ROW-102 | not | '"$RED"' | law-needed: a seam row for the preview route (ARCHITECTURE.md)'
printf 'brief: %s\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | pass | %s\n%s\n' "$B" "$C" "$GREEN" "$L" > .vid/briefs/1/builder-1.return.md
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md --agent a1 > "$T/out" 2>&1 || fail 'the return was refused'
grep -qF "    ROW-101 tests/invariants/links.sh::test_row101[ROW-101] passed ($GREEN)" "$T/out" || fail 'ROW-101'"'"'s case on GREEN is not printed'
grep -qF "    ROW-102 tests/invariants/links.sh::test_row102[ROW-102] passed ($RED)" "$T/out" || fail 'ROW-102'"'"'s case on RED is not printed'
grep -qF "    ROW-101 tests/invariants/links.sh::test_row101[ROW-101] passed ($GREEN)" "$T/out" && grep -q '^merge probe: clean' "$T/out" || fail 'no clean merge probe'
grep -qF '?? wip.txt' "$T/out" || fail 'the uncommitted file is not printed'
grep -qx 'continuation package: .vid/continuations/S1/1-builder-1' "$T/out" || fail 'the package is not printed'
grep -qxF "$L" "$T/out" || fail 'the law-needed line is not printed verbatim'
[ "$(grep -c '^agent-returned role=builder n=1 try=1-builder-1 ' .vid/metrics-events)" = 1 ] || fail 'agent-returned is not recorded once'
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md > "$T/out" 2>&1 || fail 're-check refused'
[ "$(grep -c '^agent-returned ' .vid/metrics-events)" = 1 ] || fail 'a re-check recorded agent-returned again'
# a conflict: HEAD and the branch change the same line
printf 'one side\n' > notes.txt; g add notes.txt; g commit -qm 'head side'
( cd "$WT" && rm -f wip.txt && printf 'other side\n' > notes.txt && g commit -qam 'branch side' ) || fail 'conflict setup'
sed -i.bak "s/^commit: .*/commit: $(git -C "$WT" rev-parse HEAD)/" .vid/briefs/1/builder-1.return.md
sh checks/brief.sh return .vid/briefs/1/builder-1.return.md > "$T/out" 2>&1 || fail 'the conflicting return was refused'
grep -q '^merge probe: conflicts .*notes.txt' "$T/out" || fail "the conflict is not probed: $(grep 'merge probe' "$T/out")"
grep -q '^uncommitted: none' "$T/out" || fail 'a clean worktree is not said clean'
exit 0

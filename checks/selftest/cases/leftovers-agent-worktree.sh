#!/bin/sh
# Purpose: selftest case — leftovers list an agent's worktree whose return is recorded (v0.9.8.1 R10, F-7). Three
# unmerged linked worktrees: one whose hand-back names its branch and whose brief's build-cost is recorded (by an
# absolute brief path, as an older record has it), one whose hand-back is there but never passed the check (no
# build-cost), one with no hand-back. Convicts unless `testenv.sh leftovers` lists the first, naming its return, and
# neither of the others. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "leftovers-agent-worktree: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/; g add -A && g commit -qm 'the reader'
H=$(pwd -P)
for b in returned unchecked working; do
  g worktree add -q "$T/$b" -b "agent-$b" 2>/dev/null
  ( cd "$T/$b" && printf 'x\n' > "app/$b.txt" && g add "app/$b.txt" && g commit -qm "work of $b" )
done
mkdir -p .vid/briefs/2
for b in returned unchecked; do printf 'brief: .vid/briefs/2/builder-%s.md\nagent: a-%s\nbranch: agent-%s\ncommit: x\n' "$b" "$b" "$b" > ".vid/briefs/2/builder-$b.return.md"; done
printf 'build-cost role=builder slice=2 step=S1 brief=%s/.vid/briefs/2/builder-returned.md rows=1 rows-passed=1 peak=1 total=1 before-change=unknown agent=a-returned at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
sh checks/testenv.sh leftovers > "$T/out" 2>&1
grep -qF "leftover worktree $(cd "$T/returned" && pwd -P) (branch agent-returned, not merged; its agent's return is recorded, .vid/briefs/2/builder-returned.return.md;" "$T/out" || fail 'the worktree of a recorded return is not listed'
grep -q 'agent-unchecked' "$T/out" && fail 'a worktree whose return never passed the check was listed'
grep -q 'agent-working' "$T/out" && fail 'a worktree with no return was listed'
grep -qx 'leftovers n=1' "$T/out" || fail 'not one leftover'
exit 0

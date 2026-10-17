#!/bin/sh
# Purpose: selftest case — a worktree in use is never a leftover (v0.9.8.1 R39, F-33, safety). Linked worktrees whose
# tip is still their base: one an agent started and has not stopped, returned or been costed for (branch
# worktree-agent-<id>), one a Codex job started and has not ended (vid/<try>), and one no agent owns. Convicts unless
# leftovers lists the first two as `in use` and none of the three as a leftover — a fresh worktree is never offered for
# removal; and once the agent stops, its worktree, still fresh, is not offered either. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "leftovers-fresh-worktree-in-use: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/; g add -A && g commit -qm 'the reader'
g worktree add -q "$T/agent-a7" -b worktree-agent-a7 2>/dev/null
g worktree add -q "$T/job" -b vid/1-builder-4 2>/dev/null
g worktree add -q "$T/nobody" -b fresh-nobody 2>/dev/null
printf 'agent-start session=S1 agent=a7 type=vid:builder transcript=- at=%s\n' "$(utcnow)" >> .vid/metrics-events
printf 'job-start try=1-builder-4 step=S1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/testenv.sh leftovers > "$T/out" 2>&1
grep -qF "in use: worktree $(cd "$T/agent-a7" && pwd -P) (branch worktree-agent-a7, agent a7 still working)" "$T/out" || fail 'the live agent'"'"'s worktree is not in use'
grep -qF "in use: worktree $(cd "$T/job" && pwd -P) (branch vid/1-builder-4, Codex job 1-builder-4 still working)" "$T/out" || fail 'the live job'"'"'s worktree is not in use'
grep '^leftover ' "$T/out" | grep -q 'worktree' && fail 'a fresh worktree was offered for removal'
grep -qx 'leftovers n=0' "$T/out" || fail 'not zero leftovers'
printf 'agent-stop session=S1 agent=a7 type=vid:builder transcript=- at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/testenv.sh leftovers > "$T/out" 2>&1
grep -q 'worktree-agent-a7' "$T/out" && fail 'a stopped agent'"'"'s fresh worktree was offered or still shown in use'
exit 0

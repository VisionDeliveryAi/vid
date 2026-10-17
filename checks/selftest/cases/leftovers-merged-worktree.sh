#!/bin/sh
# Purpose: selftest case — merged means commits beyond its base, in main (v0.9.8.1 R39). A worktree whose branch has a
# commit and was merged into the home's branch is listed merged; one whose commit is not merged is not; a fresh one
# (its tip its base) is not; and a merged one whose agent is still working is listed in use, not as a leftover.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "leftovers-merged-worktree: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/; g add -A && g commit -qm 'the reader'
for b in done open fresh worktree-agent-b2; do g worktree add -q "$T/$b" -b "$b" 2>/dev/null; done
for b in done open worktree-agent-b2; do ( cd "$T/$b" && printf '%s\n' "$b" > "app/$b.txt" && g add "app/$b.txt" && g commit -qm "work of $b" ); done
g merge -q --ff-only done; g merge -q --no-edit worktree-agent-b2
printf 'agent-start session=S1 agent=b2 type=vid:builder transcript=- at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/testenv.sh leftovers > "$T/out" 2>&1
grep -qF "leftover worktree $(cd "$T/done" && pwd -P) (branch done, merged into " "$T/out" || fail 'the merged worktree is not listed'
grep '^leftover ' "$T/out" | grep -q 'branch open,\|branch fresh,' && fail 'an unmerged or fresh worktree was listed'
grep -q '^in use: worktree .*(branch worktree-agent-b2, agent b2 still working)' "$T/out" || fail 'a merged worktree whose agent works is not in use'
grep '^leftover ' "$T/out" | grep -q 'worktree-agent-b2' && fail 'a worktree in use was offered'
grep -qx 'leftovers n=1' "$T/out" || fail 'not one leftover'
exit 0

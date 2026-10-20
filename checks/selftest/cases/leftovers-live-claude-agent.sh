#!/bin/sh
# Purpose: selftest case — a live Claude agent's worktree is never a leftover (v0.26.10.3 R10; §5
# leftovers-live-claude-agent). Two linked worktrees, each with a commit merged into the home's branch: one on vid/t1,
# bound to agent a1 by its recorded brief (agent-brief → a brief whose branch: is vid/t1), one on worktree-agent-a2,
# bound to agent a2 by the platform's name. Convicts unless `testenv.sh leftovers` offers neither while both agents are
# live (each `in use`), and offers both once each agent's build-cost is recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "leftovers-live-claude-agent: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
utcnow() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
mkdir -p "$T/home/checks" && cd "$T/home" && git init -q
cp "$CHECKS/plan.sh" "$CHECKS/testenv.sh" checks/
printf '.vid/\n' > .gitignore; g add -A; g commit -qm root
mkdir -p .vid/briefs/1
printf 'role: builder    slice: 1\nquoted-at: x\ntry: 1-builder-1\nbranch: vid/t1\n' > .vid/briefs/1/builder-1.md
{ printf 'agent-start session=S1 agent=a1 type=vid:builder transcript=- at=%s\n' "$(utcnow)"
  printf 'agent-brief agent=a1 brief=.vid/briefs/1/builder-1.md at=%s\n' "$(utcnow)"
  printf 'agent-start session=S1 agent=a2 type=vid:builder transcript=- at=%s\n' "$(utcnow)"; } > .vid/metrics-events
for b in vid/t1 worktree-agent-a2; do
  w="$T/wt-${b##*/}"; g worktree add -q "$w" -b "$b" 2>/dev/null
  (cd "$w" && printf 'work\n' > "work-${b##*/}" && g add -A && g commit -qm "work on $b")
  g merge -q --ff-only "$b" 2>/dev/null || g merge -q --no-edit "$b" > /dev/null 2>&1 || fail "$b did not merge"
done
VID_DOCKER=true sh checks/testenv.sh leftovers > "$T/out" 2>&1
grep -q '^leftover worktree ' "$T/out" && fail 'a live agent'"'"'s merged worktree was offered'
grep -q 'branch vid/t1, agent a1 still working' "$T/out" || fail 'the worktree bound by its brief is not in use'
grep -q 'branch worktree-agent-a2, agent a2 still working' "$T/out" || fail 'the worktree bound by its name is not in use'
{ printf 'build-cost role=builder agent=a1 brief=.vid/briefs/1/builder-1.md at=%s\n' "$(utcnow)"
  printf 'build-cost role=builder agent=a2 brief=.vid/briefs/1/builder-2.md at=%s\n' "$(utcnow)"; } >> .vid/metrics-events
VID_DOCKER=true sh checks/testenv.sh leftovers > "$T/out" 2>&1
[ "$(grep -c '^leftover worktree .*merged into' "$T/out")" -eq 2 ] || fail 'after their build-cost the two merged worktrees are not both offered'
exit 0

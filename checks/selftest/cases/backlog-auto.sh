#!/bin/sh
# Purpose: selftest case — the backlog is kept in GitHub auto too, and nowhere else (FB-3 D1). On the writer's toy in GitHub auto,
# the round's sync (`queue.sh sync`, as round.sh step runs it) adds the compaction question's line, no issue assigned to the owner
# among them; round.sh's step runs that sync. In a develop project (no .vid/tw/settings) a sync writes no backlog. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "backlog-auto: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; B=.vid/decide/queue/backlog; TB=$(printf '\t')
printf 'setup-answered key=github-mode value="auto" words="ViD builds it" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round; printf 'assigned\t7\t-\t-\tAn issue of the owner\n' > .vid/round/read
grep -v '^context-window ' .vid/metrics-events > "$T/m" || true; cat "$T/m" > .vid/metrics-events
sh "$QS" sync > "$T/out" 2>&1 || fail 'sync failed in GitHub auto'
[ -f "$B" ] && grep -q "^Q[0-9]*${TB}context:window${TB}to do${TB}you${TB}" "$B" || fail 'GitHub auto keeps no backlog line of its question'
! grep -q 'assigned:' "$B" || fail 'GitHub auto took an assigned issue as an item'
grep -qE 'queue\.sh"? sync' "$CHECKS/round.sh" || fail 'round.sh runs no queue sync'
mkdir -p "$T/dev/.vid"; cd "$T/dev"; git init -q; printf 'mode: develop\nrun: active\n' > .vid/RUN-STATE.md
sh "$QS" sync > "$T/out" 2>&1 || fail 'sync failed in a develop project'; [ ! -e "$B" ] && [ ! -e .vid/face ] || fail 'a develop project got a backlog or a panel folder'
exit 0

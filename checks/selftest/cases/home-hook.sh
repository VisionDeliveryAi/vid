#!/bin/sh
# Purpose: selftest case — the agent hook finds the home through the
# project's own resolver (v0.9.7.0.1 spec 3.1, R4; §6 A-6). Needs the
# plugin's hooks/ beside checks/, so in a project it proves nothing and
# passes. hooks/record.sh fed a SubagentStart whose `cwd` is an unlinked
# worktree with no .vid/ writes its `agent-start` at the one live run among
# the checkouts, nothing in the worktree. Against a checks/plan.sh that
# predates home-of it behaves as in 0.9.6.2: no .vid/ found, nothing
# written. Env: CHECKS.
set -eu
HD="$CHECKS/../hooks"
[ -f "$HD/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "home-hook: $*" >&2; cat "$HOMEP/.vid/metrics-events" >&2 2>/dev/null || true; exit 1; }
gated_repo "$T/main"; gate_on; HOMEP=$(pwd -P)
g worktree add -q "$T/X" -b x 2>/dev/null
XP=$(cd "$T/X" && pwd -P)
hook() { printf '%s' "$1" | ( cd "$T" && env -u CLAUDE_PROJECT_DIR sh "$HD/record.sh" ); }
hook "{\"session_id\":\"S1\",\"cwd\":\"$XP\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":\"a1\",\"agent_type\":\"general-purpose\"}" || fail 'the hook exited non-zero'
grep -q '^agent-start session=S1 agent=a1 type=general-purpose transcript=- at=' .vid/metrics-events || fail 'the agent-start is not at the home'
[ ! -e "$XP/.vid" ] || fail 'the hook wrote into the worktree'
# a checks/plan.sh that predates home-of: today's result, nothing found
printf '#!/bin/sh\necho "ViD plan: usage — sh checks/plan.sh gate | home --brief <f>" >&2; exit 2\n' > "$XP/checks/plan.sh"
N=$(grep -c . .vid/metrics-events)
hook "{\"session_id\":\"S1\",\"cwd\":\"$XP\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":\"a2\",\"agent_type\":\"general-purpose\"}" || fail 'the hook exited non-zero against an older plan.sh'
[ "$(grep -c . .vid/metrics-events)" -eq "$N" ] || fail 'against an older plan.sh the hook wrote at the home'
[ ! -e "$XP/.vid" ] || fail 'against an older plan.sh the hook wrote into the worktree'
exit 0

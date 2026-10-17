#!/bin/sh
# Purpose: selftest case — the agent hooks (v0.9.6.2 spec 3.2, R2; §6 case
# 7). Needs the plugin's hooks/ beside checks/, so in a project it proves
# nothing and passes. Convicts unless hooks.json registers hooks/record.sh
# for SubagentStart and SubagentStop; a SubagentStart input appends
# `agent-start session= agent= type= transcript=` (v0.9.7.0.6 3.1, R1: the
# parent transcript the hook receives; a value with a space quoted; §6 A-1)
# and a SubagentStop input appends
# `agent-stop session= agent= type= transcript=` (the agent's own
# transcript) to the run's events; a resumed agent writes a second
# agent-start under the same id; and input that does not parse, an agent
# input without an agent_id, and another hook event write nothing and exit
# 0. Env: CHECKS.
set -eu
HD="$CHECKS/../hooks"
[ -f "$HD/stop-failure.sh" ] || exit 0
fail() { echo "record-agents: $*" >&2; cat "${R:-.}/.vid/metrics-events" >&2 2>/dev/null || true; exit 1; }
[ -f "$HD/record.sh" ] || fail 'no hooks/record.sh'
for e in SubagentStart SubagentStop; do
  tr -d ' \n' < "$HD/hooks.json" | grep -q "\"$e\":\\[{\"hooks\":\\[{\"type\":\"command\",\"command\":\"sh\\\\\"\${CLAUDE_PLUGIN_ROOT}/hooks/record.sh\\\\\"\"" || fail "hooks.json does not register record.sh for $e"
done
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
R="$T/run"; mkdir -p "$R/.vid"; cd "$R"; git init -q
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
hook() { printf '%s' "$1" | ( cd "$T" && sh "$HD/record.sh" ); }
n() { [ -f .vid/metrics-events ] && grep -c . .vid/metrics-events || echo 0; }
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
hook "{\"session_id\":\"S1\",\"transcript_path\":\"/t/S1.jsonl\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":\"a1b2\",\"agent_type\":\"general-purpose\"}" || fail 'the start hook exited non-zero'
grep -qxE "agent-start session=S1 agent=a1b2 type=general-purpose transcript=/t/S1.jsonl $ATRE" .vid/metrics-events || fail 'the agent-start line is not in its form'
hook "{\"session_id\":\"S1\",\"transcript_path\":\"/t/my project/S1.jsonl\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":\"c3d4\",\"agent_type\":\"general-purpose\"}"
tail -n 1 .vid/metrics-events | grep -qxE "agent-start session=S1 agent=c3d4 type=general-purpose transcript=\"/t/my project/S1.jsonl\" $ATRE" || fail 'a transcript path with a space is not quoted'
hook "{\"session_id\":\"S1\",\"transcript_path\":\"/t/S1.jsonl\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStop\",\"agent_id\":\"a1b2\",\"agent_type\":\"general-purpose\",\"agent_transcript_path\":\"/t/S1/subagents/agent-a1b2.jsonl\",\"stop_hook_active\":false}" || fail 'the stop hook exited non-zero'
tail -n 1 .vid/metrics-events | grep -qxE "agent-stop session=S1 agent=a1b2 type=general-purpose transcript=/t/S1/subagents/agent-a1b2.jsonl $ATRE" || fail 'the agent-stop line is not in its form'
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":\"a1b2\",\"agent_type\":\"general-purpose\"}"
[ "$(grep -c '^agent-start session=S1 agent=a1b2 ' .vid/metrics-events)" -eq 2 ] || fail 'a resumed agent did not write a second agent-start under its id'
N=$(n)
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStart\",\"agent_id\":" || fail 'malformed input exited non-zero'
hook 'not json at all' || fail 'text input exited non-zero'
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStop\",\"agent_type\":\"x\"}" || fail 'an input without agent_id exited non-zero'
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"PreToolUse\",\"agent_id\":\"a9\"}" || fail 'another event exited non-zero'
[ "$(n)" -eq "$N" ] || fail 'malformed input, a missing agent_id or another event wrote something'
exit 0

#!/bin/sh
# Purpose: ViD's session and agent record (v0.9.6.2 spec 3.2, R2) — the
# plugin's SessionStart, SubagentStart and SubagentStop hook, so Claude Code
# itself reports sessions and agents and the model never has to. It only
# records: it never changes the session and always exits 0. In order:
#   1. find the run (v0.9.7.0.6: the code is hooks/home.sh's vid_home, which
#      the re-entry page and the re-read hook share): from the input's `cwd`, the nearest directory holding
#      .vid/, walking up no further than that directory's git toplevel
#      (outside a repository, `cwd` alone); then $CLAUDE_PROJECT_DIR; then
#      through that .vid/home to the run's home, when the path it names
#      holds .vid/RUN-STATE.md. v0.9.7.0.1 (3.1, R4): then, when that
#      directory's git top level (with no .vid/ found: the cwd's) has
#      checks/plan.sh, its `home-of` answer, when it prints one — so an
#      agent's fresh worktree is recorded at the one live run; any failure,
#      or a plan.sh older than home-of, keeps the result above. No .vid/ →
#      nothing: a session outside a ViD
#      project is not recorded (nor the session that creates a project — it
#      starts before .vid/ exists; the export recovers it, nothing is
#      backdated);
#   2. append to the home's .vid/metrics-events, by hook_event_name:
#        session id=<session_id> source=<as given> [model=<when given>] transcript=<transcript_path> vid=<plugin version> at=<UTC>
#        agent-start session=<session_id> agent=<agent_id> type=<agent_type> transcript=<transcript_path> at=<UTC>
#        agent-stop session=<session_id> agent=<agent_id> type=<agent_type> transcript=<agent_transcript_path> at=<UTC>
#      A value carrying a space is written in double quotes; a missing one
#      as `-`. `source=` is kept as given (its list is not fixed). `vid=` is
#      the version in the plugin's .claude-plugin/plugin.json. v0.9.7.0.6
#      (3.1, R1): agent-start's `transcript=` is the PARENT session's
#      transcript, as the hook receives it; the agent's own is then
#      <it without .jsonl>/subagents/agent-<agent_id>.jsonl. A resumed
#      agent writes a new agent-start under the same id. The agent's prompt
#      is not in these inputs: brief, role and step are joined at export.
# Input without a session_id, an agent event without an agent_id, and input
# that does not parse write nothing. The input is read by hooks/json.sh.
IN=$(cat 2>/dev/null) || exit 0
HD=$(dirname "$0"); [ -f "$HD/json.sh" ] && [ -f "$HD/home.sh" ] || exit 0
. "$HD/json.sh"; . "$HD/home.sh"
# v <value>: one event token — `-` when empty, double-quoted when it carries a space
v() { case "$1" in '') printf '%s' - ;; *[[:space:]]*) printf '"%s"' "$(printf '%s' "$1" | tr '"\t' "' ")" ;; *) printf '%s' "$1" ;; esac; }
main() {
  F=$(printf '%s' "$IN" | json_fields) || return 0
  SID=$(jget session_id); [ -n "$SID" ] || return 0
  EVN=$(jget hook_event_name)
  case "$EVN" in
    SessionStart) ;;
    SubagentStart|SubagentStop) [ -n "$(jget agent_id)" ] || return 0 ;;
    *) return 0 ;;
  esac
  # 1. the run (hooks/home.sh, v0.9.7.0.6)
  D=$(vid_home "$(jget cwd)")
  [ -n "$D" ] || return 0
  EV="$D/.vid/metrics-events"
  AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  # 2. the record
  case "$EVN" in
    SessionStart)
      PJ="${CLAUDE_PLUGIN_ROOT:-$HD/..}/.claude-plugin/plugin.json"
      VER=$( [ -f "$PJ" ] && F=$(json_fields < "$PJ") && jget version )
      MD=''; jhas model && [ -n "$(jget model)" ] && MD=" model=$(v "$(jget model)")"
      printf 'session id=%s source=%s%s transcript=%s vid=%s at=%s\n' "$(v "$SID")" "$(v "$(jget source)")" "$MD" "$(v "$(jget transcript_path)")" "$(v "$VER")" "$AT" >> "$EV" ;;
    SubagentStart)
      printf 'agent-start session=%s agent=%s type=%s transcript=%s at=%s\n' "$(v "$SID")" "$(v "$(jget agent_id)")" "$(v "$(jget agent_type)")" "$(v "$(jget transcript_path)")" "$AT" >> "$EV" ;;
    SubagentStop)
      printf 'agent-stop session=%s agent=%s type=%s transcript=%s at=%s\n' "$(v "$SID")" "$(v "$(jget agent_id)")" "$(v "$(jget agent_type)")" "$(v "$(jget agent_transcript_path)")" "$AT" >> "$EV" ;;
  esac
}
main 2>/dev/null
exit 0

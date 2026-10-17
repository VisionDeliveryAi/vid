#!/bin/sh
# Purpose: ViD's context net for a builder or fixer (v0.9.7.0.7 spec 3.7, R11) — the plugin's
# PostToolUse hook (every tool). For a call carrying `agent_id`, with a resolved home (hooks/home.sh)
# and a brief of role builder or fixer (hooks/agent.sh), it reads the
# agent's latest API context from its own transcript — derived from the session's agent-start
# record, never from the input's transcript_path — and, at or above `.vid/budget
# builder-context-tokens` (default 400000), once per agent (the marker <home>/.vid/net.<agent_id>),
# returns additionalContext: "Your context is past <the budget> tokens. Finish at your next legal
# commit point — a green iterate run and the gates passing — write your hand-back block, and stop.
# Do not start new work." Fast exits first: no agent_id, not a ViD project, the marker. Missing
# usage: nothing. It fails open and always exits 0. v0.9.8.1 (R14): before the net's own exits, every
# agent's first call records its brief (vid_brief_record, below), whatever its role.
IN=$(cat 2>/dev/null) || exit 0
case "$IN" in *'"agent_id"'*) ;; *) exit 0 ;; esac
HD=$(dirname "$0"); [ -f "$HD/home.sh" ] && [ -f "$HD/agent.sh" ] || exit 0
. "$HD/home.sh"; . "$HD/agent.sh"
# v0.9.8.1 (R14): vid_brief_record <home> <agent id> — on the agent's first tool call, for every role, once (the
# marker <home>/.vid/agents/<id>.brief, made exclusively): `agent-brief agent=<id> brief=<path relative to the home>`,
# its brief read as vid_agent_brief reads it without the role gate; `brief=unavailable` when none is found
vid_brief_record() {
  _m="$1/.vid/agents/$2.brief"; [ -e "$_m" ] && return 0
  mkdir -p "$1/.vid/agents" 2>/dev/null || return 0
  ( set -C; : > "$_m" ) 2>/dev/null || return 0
  _t=$(vid_agent_transcript "$1" "$2"); _b=''; [ -n "$_t" ] && _b=$(vid_brief_path "$1" "$_t")
  printf 'agent-brief agent=%s brief=%s at=%s\n' "$2" "${_b:-unavailable}" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$1/.vid/metrics-events"
}
main() {
  KV=$(keys hook_event_name session_id cwd agent_id) || return 0
  [ "$(kv hook_event_name)" = PostToolUse ] || return 0
  AID=$(kv agent_id); case "$AID" in ''|*[!A-Za-z0-9._-]*) return 0 ;; esac
  CWD=$(kv cwd); vid_near "$CWD" || return 0
  H=$(vid_home "$CWD"); [ -n "$H" ] || return 0
  vid_brief_record "$H" "$AID"   # before the net's own early exits
  [ -e "$H/.vid/net.$AID" ] && return 0
  TR=$(vid_agent_transcript "$H" "$AID"); [ -n "$TR" ] || return 0
  [ -n "$(vid_agent_brief "$H" "$TR")" ] || return 0
  N=$( [ -f "$H/.vid/budget" ] && sed -n 's/^builder-context-tokens=\([0-9][0-9]*\).*/\1/p' "$H/.vid/budget" | tail -n 1); N=${N:-400000}
  C=$(vid_context "$TR"); [ -n "$C" ] || return 0
  [ "$C" -ge "$N" ] || return 0
  : > "$H/.vid/net.$AID" || return 0
  MSG="Your context is past $N tokens. Finish at your next legal commit point — a green iterate run and the gates passing — write your hand-back block, and stop. Do not start new work."
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(jesc "$MSG")"
}
IFS='
'
main 2>/dev/null
exit 0

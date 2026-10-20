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
#   3. v0.26.10.6 (R17a): at SubagentStop, after agent-stop, the agent's usage
#      in four kinds from its own transcript (agent_transcript_path), once:
#        usage agent=<agent_id> session=<session_id> tool=claude model=<m|mixed|unknown> effort=<e|unknown> calls=<n> input=<n> cache-read=<n> cache-write=<n> cache-write-1h=<n> output=<n> scope=agent at=<UTC>
#      every API call of the whole transcript once, by its message id, its
#      last entry's usage (a streamed message's earlier entries hold partial
#      output); `<synthetic>` entries skipped; `mixed` when the calls name
#      more than one model. A call's 1-hour part is never more than its
#      cache write (a transcript once held a call whose totals were 0 and
#      whose 1-hour part was not). Cumulative: a resumed agent's later record covers
#      its earlier runs. A transcript not found writes no record.
# Input without a session_id, an agent event without an agent_id, and input
# that does not parse write nothing. The input is read by hooks/json.sh.
IN=$(cat 2>/dev/null) || exit 0
HD=$(dirname "$0"); [ -f "$HD/json.sh" ] && [ -f "$HD/home.sh" ] || exit 0
. "$HD/json.sh"; . "$HD/home.sh"
# v0.26.10.6 (R17a): a Claude transcript's usage in four kinds — the last usage object of each assistant line (the
# message's own; a tool's input holds its quotes escaped), bounded by its braces; each message id's last entry wins
USAGE='function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
  index($0, "\"effort\":\"") && match($0, /"effort":"[^"]*"/) { ef = substr($0, RSTART + 10, RLENGTH - 11) }
  index($0, "\"usage\":{\"input_tokens\":") && !index($0, "\"type\":\"progress\"") {
    s = $0; u = 0; while ((i = index(s, "\"usage\":{\"input_tokens\":")) > 0) { u += i; s = substr(s, i + 1) }
    s = substr($0, u + 8); d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "{") d++; else if (c == "}" && --d == 0) break } s = substr(s, 1, i)
    m = ""; if (match($0, /"model":"[^"]*"/)) m = substr($0, RSTART + 9, RLENGTH - 10); if (m == "<synthetic>") next
    id = ""; if (match($0, /"id":"msg_[^"]*"/)) id = substr($0, RSTART, RLENGTH); if (id == "") id = "line" NR
    if (!(id in IN)) ID[++n] = id; IN[id] = num(s, "input_tokens"); CR[id] = num(s, "cache_read_input_tokens"); CW[id] = num(s, "cache_creation_input_tokens")
    C1[id] = num(s, "ephemeral_1h_input_tokens"); if (C1[id] > CW[id]) C1[id] = CW[id]; OU[id] = num(s, "output_tokens"); MO[id] = m }
  END { for (k = 1; k <= n; k++) { x = ID[k]; a += IN[x]; b += CR[x]; c += CW[x]; e += C1[x]; o += OU[x]; if (MO[x] != "" && !(MO[x] in MS)) { MS[MO[x]] = 1; nm++; md = MO[x] } }
    if (nm > 1) md = "mixed"; if (md == "") md = "unknown"; if (ef == "") ef = "unknown"
    printf "model=%s effort=%s calls=%d input=%d cache-read=%d cache-write=%d cache-write-1h=%d output=%d\n", md, ef, n, a, b, c, e, o }'
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
      printf 'agent-stop session=%s agent=%s type=%s transcript=%s at=%s\n' "$(v "$SID")" "$(v "$(jget agent_id)")" "$(v "$(jget agent_type)")" "$(v "$(jget agent_transcript_path)")" "$AT" >> "$EV"
      # 3. v0.26.10.6 (R17a): the agent's usage, after agent-stop
      TR=$(jget agent_transcript_path)
      if [ -n "$TR" ] && [ -f "$TR" ] && [ -r "$TR" ]; then
        UK=$(awk "$USAGE" "$TR") && [ -n "$UK" ] && \
          printf 'usage agent=%s session=%s tool=claude %s scope=agent at=%s\n' "$(v "$(jget agent_id)")" "$(v "$SID")" "$UK" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
      fi ;;
  esac
}
main 2>/dev/null
exit 0

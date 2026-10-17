# Purpose: selftest fixture — toy agent transcripts for the watcher's agent
# cases (v0.9.7.0.6 spec 3.2, §6 A-2…A-5). Sourced after observer-lib.sh
# (it uses `ago`). The parent transcript is "$TR/S1.jsonl" (a directory with
# a space, so the events carry it quoted); an agent's own is
# "$TR/S1/subagents/agent-<id>.jsonl", shaped as Claude Code writes them:
#   start <id> <secs ago> [session] [no-transcript]  an agent-start event
#   stop <id> <secs ago>                             an agent-stop event
#   entry <id> <secs ago>                            a plain transcript entry
#   endturn <id> <secs ago>                          a bare end of turn
#   handback <id> <secs ago> [true|false]            a SubagentHandback call and its result
#   task <id> <text>                                 the agent's meta.json description
#   snapshot <id> <secs ago>                         a prompt snapshot listing the SubagentHandback tool,
#                                                    an earlier "id" before it, and a success result for that id
# Env: T.
TR="$T/transcripts dir"; mkdir -p "$TR/S1/subagents" "$TR/S2/subagents"
af() { printf '%s/%s/subagents/agent-%s.jsonl' "$TR" "${2:-S1}" "$1"; }
ts() { ago "$1" | sed 's/Z$/.123Z/'; }
start() { if [ "${4:-}" = no-transcript ]; then printf 'agent-start session=%s agent=%s type=general-purpose at=%s\n' "${3:-S1}" "$1" "$(ago "$2")"
  else printf 'agent-start session=%s agent=%s type=general-purpose transcript="%s/%s.jsonl" at=%s\n' "${3:-S1}" "$1" "$TR" "${3:-S1}" "$(ago "$2")"; fi >> .vid/metrics-events; }
stop() { printf 'agent-stop session=S1 agent=%s type=general-purpose transcript="%s" at=%s\n' "$1" "$(af "$1")" "$(ago "$2")" >> .vid/metrics-events; }
entry() { printf '{"parentUuid":"p","isSidechain":true,"agentId":"%s","type":"user","message":{"role":"user","content":"a step"},"uuid":"u","timestamp":"%s","sessionId":"S1"}\n' "$1" "$(ts "$2")" >> "$(af "$1")"; }
endturn() { printf '{"isSidechain":true,"agentId":"%s","message":{"model":"m","id":"msg_e","type":"message","role":"assistant","content":[{"type":"text","text":"I wait for the test result."}],"stop_reason":"end_turn"},"type":"assistant","timestamp":"%s"}\n' "$1" "$(ts "$2")" >> "$(af "$1")"; }
handback() { _n=$(date +%s)$$; printf '{"isSidechain":true,"agentId":"%s","message":{"model":"m","id":"msg_h","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_%s","name":"SubagentHandback","input":{"message":"ROW-1 | KEPT | done"}}]},"type":"assistant","timestamp":"%s"}\n' "$1" "$_n$2" "$(ts "$2")" >> "$(af "$1")"
  printf '{"isSidechain":true,"agentId":"%s","type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_%s","type":"tool_result","content":[{"type":"text","text":"{\\"success\\":%s,\\"message\\":\\"Report delivered to your caller.\\"}"}]}]},"timestamp":"%s"}\n' "$1" "$_n$2" "${3:-true}" "$(ts "$2")" >> "$(af "$1")"; }
task() { printf '{"agentType":"general-purpose","description":"%s","toolUseId":"toolu_x","spawnDepth":1}\n' "$(printf '%s' "$2" | sed 's/"/\\"/g')" > "$(af "$1" | sed 's/\.jsonl$//').meta.json"; }
session() { printf 'session id=%s source=startup transcript="%s/%s.jsonl" vid=0.9.7.0.6 at=%s\n' "$1" "$TR" "$1" "$(ago "$2")" >> .vid/metrics-events; }
snapshot() { printf '{"isSidechain":true,"agentId":"%s","attachment":{"type":"prompt_snapshot","tools":[{"id":"toolu_snap%s","kind":"x"},{"name":"SubagentHandback","description":"Deliver your final report"}]},"type":"attachment","timestamp":"%s"}\n' "$1" "$2" "$(ts "$2")" >> "$(af "$1")"
  printf '{"isSidechain":true,"agentId":"%s","type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_snap%s","type":"tool_result","content":[{"type":"text","text":"{\\"success\\":true}"}]}]},"timestamp":"%s"}\n' "$1" "$2" "$(ts "$2")" >> "$(af "$1")"; }

#!/bin/sh
# Purpose: ViD's bounded waits for builders and fixers (v0.9.7.1 spec 3.5b, R5) — the plugin's PreToolUse hook
# on Bash. It acts only when the call's `agent_type` is `vid:builder` or `vid:fixer` and the call is not
# `run_in_background`; the run manager's and the owner's commands are never touched. It refuses, with the
# documented deny output:
#   - a `while` or `until` loop holding `sleep`, or a repeated `test.sh`, `git` or `docker` status probe;
#   - a `sleep` over 200 seconds, or one whose duration it can't read (whole or decimal seconds, or with an
#     s, m or h suffix).
# Its reason names `sh checks/test.sh wait <ticket>` and the bounded form. It reads the command's shape only — its
# words — claims no more, and names no language or framework: an unbounded program it can't see is not caught.
# Fast exits first; malformed input, or any error, allows the call. It always exits 0.
IN=$(cat 2>/dev/null) || exit 0
case "$IN" in *'"vid:builder"'*|*'"vid:fixer"'*) ;; *) exit 0 ;; esac
HD=$(dirname "$0"); [ -f "$HD/agent.sh" ] || exit 0
. "$HD/agent.sh"
main() {
  KV=$(keys hook_event_name tool_name agent_type run_in_background command) || return 0
  [ "$(kv hook_event_name)" = PreToolUse ] && [ "$(kv tool_name)" = Bash ] || return 0
  case "$(kv agent_type)" in vid:builder|vid:fixer) ;; *) return 0 ;; esac
  [ "$(kv run_in_background)" = true ] && return 0
  C=$(kv command); [ -n "$C" ] || return 0
  W=$(printf '%s\n' "$C" | tr ';|&()`' '      ' | tr -s ' \t' '  ')
  WHY=''
  if printf ' %s \n' "$W" | grep -qE ' (while|until) '; then
    if printf ' %s \n' "$W" | grep -qE ' sleep '; then WHY='a loop that sleeps'
    elif printf '%s\n' "$C" | grep -qE '(^|[^A-Za-z0-9_./-])(checks/test\.sh|test\.sh|git|docker)([^A-Za-z0-9_.-]|$)'; then WHY='a loop that repeats a status probe'; fi
  fi
  if [ -z "$WHY" ]; then
    WHY=$(printf ' %s \n' "$W" | awk '{ for (i = 1; i < NF; i++) if ($i == "sleep") { d = $(i + 1)
        if (d !~ /^[0-9]+(\.[0-9]+)?[smh]?$/) { print "a sleep whose duration can'"'"'t be read (" d ")"; exit }
        u = substr(d, length(d)); v = d + 0; if (u == "m") v *= 60; else if (u == "h") v *= 3600
        if (v > 200) { print "a sleep of " d ", over 200 seconds"; exit } } }')
  fi
  [ -n "$WHY" ] || return 0
  MSG="ViD: refused — $WHY. A builder or fixer waits in bounded calls: for a test request, sh checks/test.sh wait <ticket> (it returns within 200 s; call it again until it ends); for a command you started in the background, one sleep of at most 200 s, then Read its output file. Never a loop."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(jesc "$MSG")"
}
IFS='
'
main 2>/dev/null
exit 0

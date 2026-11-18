#!/bin/sh
# Purpose: ViD's face (0.26.10.29) — the plugin's hook after Bash, Write and Edit, and (usability, P4) at
# UserPromptSubmit, Stop and StopFailure. Where the project holds .vid/face/standing.json (a panel reads it):
#   - it keeps .vid/face/run.<session id>, one line, `<running|stopped> <since, UTC> <last step, UTC|->`, written
#     whole by rename, so any face can tell whether the session runs: a prompt writes running (the last step kept);
#     a step sets the last step, and turns a stopped or missing file to running begun now; Stop and StopFailure
#     write stopped (the last step kept); a helper's events (an agent_id) never write it;
#   - after a step and at Stop it recomputes the standing with checks/face.sh, so the map follows stops 6 to 9 (the
#     technical hints, the design, the test list, the releases), which no sitting writes.
# An input with no event name is a step (as before). Elsewhere it does nothing. It only rewrites those
# work-in-progress files; it fails open and always exits 0.
IN=$(cat 2>/dev/null || true)
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
[ -f "$TOP/.vid/face/standing.json" ] || exit 0
R=${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd -P)}
ev=''; sid=''; agent=''
if [ -f "$R/hooks/json.sh" ]; then
  . "$R/hooks/json.sh"
  F=$(printf '%s' "$IN" | json_fields 2>/dev/null) || F=''
  ev=$(jget hook_event_name); sid=$(jget session_id); agent=$(jget agent_id)
fi
case $sid in *[!A-Za-z0-9_-]*) sid='' ;; esac
RUN=$TOP/.vid/face/run.$sid
now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
state=''; since=''; last=''
[ -n "$sid" ] && [ -f "$RUN" ] && read -r state since last < "$RUN" 2>/dev/null
put() { [ -n "$sid" ] || return 0; printf '%s %s %s\n' "$1" "$2" "${3:--}" > "$RUN.$$" 2>/dev/null && mv -f "$RUN.$$" "$RUN" 2>/dev/null; return 0; }
standing() { (cd "$TOP" && sh "$R/checks/face.sh" standing > /dev/null 2>&1) || true; }
# a helper (an agent_id in the input) never writes the session's file: a write of its own could land after the
# session's Stop and undo it. Its step still recomputes the standing; the wait's last step does not move for it.
if [ -n "$agent" ]; then
  case $ev in
    StopFailure) ;;
    *) standing ;;
  esac
  exit 0
fi
case $ev in
  UserPromptSubmit) put running "$now" "$last" ;;
  Stop) put stopped "$now" "$last"; standing ;;
  StopFailure) put stopped "$now" "$last" ;;
  *) [ "$state" = running ] || since=$now; put running "$since" "$now"; standing ;;
esac
exit 0

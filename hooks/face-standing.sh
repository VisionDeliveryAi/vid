#!/bin/sh
# Purpose: ViD's face (0.26.10.29) — the plugin's hook after Bash, Write and Edit, and (usability, P4) at
# UserPromptSubmit, Stop and StopFailure. Where the project holds .vid/face/standing.json (a panel reads it):
#   - it keeps .vid/face/run.<session id>, one line, `<running|stopped> <since, UTC> <last step, UTC|->`, written
#     whole by rename, so any face can tell whether the session runs: a prompt writes running (the last step kept);
#     a step sets the last step, and turns a stopped or missing file to running begun now; Stop and StopFailure
#     write stopped (the last step kept); a helper's events (an agent_id) never write it;
#   - at Stop, the end of a turn, it recomputes the standing with checks/face.sh, so the map follows stops 6 to 9 (the
#     technical hints, the design, the test list, the releases), which no sitting writes. From 0.26.11.1.3 (R1) a step,
#     a helper's included, no longer recomputes it: the step only writes the run file.
# Its three fields (the event, the session, the helper) are taken in one pass of hooks/agent.sh's reader, whose time
# grows in step with the input (a Write's whole text is in it); key order does not matter to it.
#   - FB-3 D1: where .vid/tw/settings is (ticket mode) and no standing yet, it makes the folder and the standing first.
# An input with no event name is a step (as before). Elsewhere it does nothing. It only rewrites those
# work-in-progress files; it fails open and always exits 0.
IN=$(cat 2>/dev/null || true)
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
NEW=''   # FB-3 D1: a ticket-mode project's first event makes the standing, so its backlog is in the panel from the first turn
if [ ! -f "$TOP/.vid/face/standing.json" ]; then
  [ -f "$TOP/.vid/tw/settings" ] && mkdir -p "$TOP/.vid/face" 2>/dev/null || exit 0
  NEW=1
fi
case $0 in */*) HD=${0%/*} ;; *) HD=. ;; esac
R=${CLAUDE_PLUGIN_ROOT:-$(cd "$HD/.." && pwd -P)}
ev=''; sid=''; agent=''
if [ -f "$R/hooks/agent.sh" ]; then
  . "$R/hooks/agent.sh"
  kread hook_event_name session_id agent_id 2>/dev/null && { ev=${J_hook_event_name:-}; sid=${J_session_id:-}; agent=${J_agent_id:-}; }
fi
# a helper (an agent_id in the input) never writes the session's file: a write of its own could land after the
# session's Stop and undo it. Nor (0.26.11.1.3, R1) does its step recompute the standing; the session's Stop does.
[ -n "$agent" ] && exit 0
case $sid in *[!A-Za-z0-9_-]*) sid='' ;; esac
RUN=$TOP/.vid/face/run.$sid
now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
state=''; since=''; last=''
[ -n "$sid" ] && [ -f "$RUN" ] && read -r state since last < "$RUN" 2>/dev/null
put() { [ -n "$sid" ] || return 0; printf '%s %s %s\n' "$1" "$2" "${3:--}" > "$RUN.$$" 2>/dev/null && mv -f "$RUN.$$" "$RUN" 2>/dev/null; return 0; }
standing() { (cd "$TOP" && sh "$R/checks/face.sh" standing > /dev/null 2>&1) || true; }
[ -z "$NEW" ] || standing
case $ev in
  UserPromptSubmit) put running "$now" "$last" ;;
  Stop) put stopped "$now" "$last"; standing ;;
  StopFailure) put stopped "$now" "$last" ;;
  *) [ "$state" = running ] || since=$now; put running "$since" "$now" ;;
esac
exit 0

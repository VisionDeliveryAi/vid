#!/bin/sh
# Purpose: ViD's death record (v0.9.5 spec 3.4, R4; owner ruling 9.1) — the
# plugin's StopFailure hook, and its Notification hook for a usage-limit
# pause left waiting (`quota_auto_resume_stale`, `quota_auto_resume_disabled`).
# It only records: it never changes how the session ends, never restarts
# it, and always exits 0. In order:
#   1. find the run: walk up from the input's `cwd` to the nearest directory
#      holding .vid/RUN-STATE.md, stopping at that directory's git toplevel
#      (outside a repository, `cwd` alone); then $CLAUDE_PROJECT_DIR; no run
#      → nothing;
#   2. the project's version: no checks/records-version → nothing (its
#      checks/ predates 0.9.5);
#   3. the run's session only: the input's `session_id` must equal
#      RUN-STATE's `session:` (an empty `session:` matches nothing);
#   4. never a subagent: an input carrying `agent_id` → nothing;
#   5. append to that run's .vid/metrics-events
#        died reason=<error> session=<session_id> [details="<error_details, 200 characters at most>"] at=<UTC>
#      or, for the Notification, `died reason=usage-limit-waiting …` with the
#      notification type as its details.
# The input is read by hooks/json.sh, the plugin's shared JSON reader (v0.9.6.2
# spec 3.2: moved there unchanged from this script).
IN=$(cat 2>/dev/null) || exit 0
J="$(dirname "$0")/json.sh"; [ -f "$J" ] || exit 0
. "$J"
main() {
  F=$(printf '%s' "$IN" | json_fields) || return 0
  get() { jget "$1"; }
  has() { jhas "$1"; }
  SID=$(get session_id); [ -n "$SID" ] || return 0
  EVN=$(get hook_event_name)
  if [ "$EVN" = Notification ]; then
    NT=$(get notification_type)
    case "$NT" in quota_auto_resume_stale|quota_auto_resume_disabled) ;; *) return 0 ;; esac
    REASON=usage-limit-waiting; DET=$NT
  else
    REASON=$(get error | tr -c 'A-Za-z0-9_.-' '_' | sed 's/_*$//'); [ -n "$REASON" ] || REASON=unknown
    DET=$(get error_details)
  fi
  # 1. the run
  CWD=$(get cwd); RUN=''
  if [ -n "$CWD" ] && [ -d "$CWD" ]; then
    TOP=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)
    d=$(cd "$CWD" && pwd -P); [ -n "$TOP" ] && TOP=$(cd "$TOP" && pwd -P)
    while [ -n "$d" ]; do
      if [ -f "$d/.vid/RUN-STATE.md" ]; then RUN=$d; break; fi
      { [ -z "$TOP" ] || [ "$d" = "$TOP" ] || [ "$d" = / ]; } && break
      d=$(dirname "$d")
    done
  fi
  if [ -z "$RUN" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/.vid/RUN-STATE.md" ]; then RUN=$CLAUDE_PROJECT_DIR; fi
  [ -n "$RUN" ] || return 0
  # 2. the project's version
  [ -f "$RUN/checks/records-version" ] || return 0
  # 3. the run's own session
  RS=$(sed -n 's/^session:[[:space:]]*//p' "$RUN/.vid/RUN-STATE.md" | head -n 1 | sed 's/[[:space:]]*$//')
  [ -n "$RS" ] && [ "$RS" = "$SID" ] || return 0
  # 4. never a subagent
  has agent_id && return 0
  # 5. the record
  EV="$RUN/.vid/metrics-events"
  DQ=''
  if [ -n "$DET" ]; then DQ=$(printf '%s' "$DET" | tr '"' "'" | awk '{ s = $0; if (length(s) > 200) s = substr(s, 1, 200); printf "%s", s }'); DQ=" details=\"$DQ\""; fi
  printf 'died reason=%s session=%s%s at=%s\n' "$REASON" "$SID" "$DQ" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
}
main 2>/dev/null
exit 0

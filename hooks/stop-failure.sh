#!/bin/sh
# Purpose: ViD's death record (v0.9.5 spec 3.4, R4) — the
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
# From 0.26.11.1.3 (R1) the input's fields are taken in one pass of hooks/agent.sh's
# reader (kread), whose time grows in step with the input, and no git runs
# before hooks/home.sh's vid_near has found a .vid/ (the walk-up to the root, or
# $CLAUDE_PROJECT_DIR): a death is recorded well inside the hook's 10 s.
IN=$(cat 2>/dev/null) || exit 0
case $0 in */*) HD=${0%/*} ;; *) HD=. ;; esac
[ -f "$HD/agent.sh" ] && [ -f "$HD/home.sh" ] || exit 0
. "$HD/agent.sh"; . "$HD/home.sh"
main() {
  kread session_id hook_event_name notification_type error error_details cwd agent_id || return 0
  SID=${J_session_id:-}; [ -n "$SID" ] || return 0
  EVN=${J_hook_event_name:-}
  if [ "$EVN" = Notification ]; then
    NT=${J_notification_type:-}
    case "$NT" in quota_auto_resume_stale|quota_auto_resume_disabled) ;; *) return 0 ;; esac
  fi
  # 1. the run
  CWD=${J_cwd:-}; RUN=''
  vid_near "$CWD" || return 0
  if [ -n "$VID_CW" ]; then
    TOP=$(git -C "$VID_CW" rev-parse --show-toplevel 2>/dev/null || true)
    d=$VID_CW; [ -n "$TOP" ] && TOP=$(cd "$TOP" && pwd -P)
    while [ -n "$d" ]; do
      if [ -f "$d/.vid/RUN-STATE.md" ]; then RUN=$d; break; fi
      { [ -z "$TOP" ] || [ "$d" = "$TOP" ] || [ "$d" = / ]; } && break
      d=${d%/*}; [ -n "$d" ] || d=/
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
  [ -n "${J_agent_id+x}" ] && return 0
  # 5. the record
  if [ "$EVN" = Notification ]; then
    REASON=usage-limit-waiting; DET=$NT
  else
    REASON=$(printf '%s' "${J_error:-}" | tr -c 'A-Za-z0-9_.-' '_' | sed 's/_*$//'); [ -n "$REASON" ] || REASON=unknown
    DET=${J_error_details:-}
  fi
  EV="$RUN/.vid/metrics-events"
  DQ=''
  if [ -n "$DET" ]; then DQ=$(printf '%s' "$DET" | tr '"' "'" | awk '{ s = $0; if (length(s) > 200) s = substr(s, 1, 200); printf "%s", s }'); DQ=" details=\"$DQ\""; fi
  printf 'died reason=%s session=%s%s at=%s\n' "$REASON" "$SID" "$DQ" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"   # fields: details=
}
main 2>/dev/null
exit 0

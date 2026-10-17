#!/bin/sh
# Purpose: ViD's re-entry page (v0.9.7.0.6 spec 3.4, R8; 3.8, R11) — the
# plugin's SessionStart hook for source `compact` or `resume`. In a live run
# (the home's RUN-STATE says `run: active` or `run: waiting`; the home found
# by hooks/home.sh, as record.sh finds it) it prints one page, under 10,000
# characters, into the session; anywhere else, and for `startup` and
# `clear`, nothing. The parts that must survive come first and are never cut:
#   1. "ViD re-entry — your memory of this run was compacted or resumed;
#      continue from these records";
#   2. "Re-read these in full now, with the Read tool:" and the absolute
#      paths of the open verb's skill and the internal skills it uses (the
#      verb: the latest `stage name=<verb> state=start` with no `end` after
#      it; develop and fix use vid-test-manager, vid-verify and, from
#      v0.9.7.0.7 3.1, vid-build), with the
#      debt file's path and how the owner lifts it;
#   3. `sh checks/observe.sh alive`'s lines — only when the project's
#      checks/records-version is 9 or more (an older observe.sh takes an
#      unknown mode for a tick, which writes); from records 12 (v0.9.7.0.9)
#      a watcher not running is answered by the line `watcher: start it: sh
#      checks/observe.sh start`, which develop's resume runs;
#   3a. v0.9.7.1 (3.8, 3.9; R8, R9): the open Codex jobs (`sh checks/job.sh open`, at most 20 lines) and the
#      last `agent-returned` event — never cut;
#   4. last, bounded: `sh checks/observe.sh resume`, run in the home — at
#      most 40 lines, each cut to 300 characters, and the whole cut to what
#      keeps the page under 9,000 characters, ending "(+N more: sh
#      checks/observe.sh resume)".
# v0.9.8.1 (R31): only for `compact`; a `resume` writes no debt and prints the page at most once per 30 minutes per
# session (<home>/.vid/reentry-shown.<session_id>, the UTC time it was shown), else nothing.
# It writes one file, the session's re-read debt,
# <home>/.vid/reread-owed.<session_id>: `since <UTC>` and one `file <path>`
# line per path on the list, replacing that session's earlier debt; another
# session's is never touched. hooks/reread.sh pays and enforces it. It always
# exits 0. The input is read by hooks/json.sh.
IN=$(cat 2>/dev/null) || exit 0
HD=$(dirname "$0"); [ -f "$HD/json.sh" ] && [ -f "$HD/home.sh" ] || exit 0
. "$HD/json.sh"; . "$HD/home.sh"
main() {
  F=$(printf '%s' "$IN" | json_fields) || return 0
  [ "$(jget hook_event_name)" = SessionStart ] || return 0
  case "$(jget source)" in compact|resume) ;; *) return 0 ;; esac
  SID=$(jget session_id); case "$SID" in ''|*[!A-Za-z0-9._-]*) return 0 ;; esac
  H=$(vid_home "$(jget cwd)"); [ -n "$H" ] && [ -f "$H/.vid/RUN-STATE.md" ] || return 0
  RUN=$(sed -n 's/^run:[[:space:]]*//p' "$H/.vid/RUN-STATE.md" | head -n 1 | awk '{ print $1 }')
  case "$RUN" in active|waiting) ;; *) return 0 ;; esac
  # the open verb and its skills
  VERB=$( [ -f "$H/.vid/metrics-events" ] && awk '$1 == "stage" { n = ""; s = ""; for (i = 2; i <= NF; i++) { if (index($i, "name=") == 1) n = substr($i, 6); if (index($i, "state=") == 1) s = substr($i, 7) }
      if (s == "start") v = n; else if (s == "end" && n == v) v = "" } END { print v }' "$H/.vid/metrics-events")
  PR=$(cd "${CLAUDE_PLUGIN_ROOT:-$HD/..}" 2>/dev/null && pwd -P) || return 0
  case "$VERB" in ''|develop) SK='vid-develop vid-test-manager vid-verify vid-build' ;; fix) SK='vid-fix vid-test-manager vid-verify vid-build' ;; *) SK="vid-$VERB" ;; esac
  LIST=''; for k in $SK; do [ -f "$PR/skills/$k/SKILL.md" ] && LIST="$LIST$PR/skills/$k/SKILL.md
"; done
  OWED="$H/.vid/reread-owed.$SID"
  # v0.9.8.1 (R31, F-20): the debt is armed only for `compact`. A `resume` — in the desktop app every turn a
  # background hand-back, a task notification or another session's message starts, with nothing cut — writes no debt
  # and prints the page at most once per 30 minutes per session (<home>/.vid/reentry-shown.<session>, its UTC time)
  SRC=$(jget source)
  if [ "$SRC" = resume ]; then
    SHOWN="$H/.vid/reentry-shown.$SID"
    [ -n "$(find "$SHOWN" -mmin -30 2>/dev/null)" ] && return 0
    date -u '+%Y-%m-%dT%H:%M:%SZ' > "$SHOWN.tmp.$$" 2>/dev/null && mv "$SHOWN.tmp.$$" "$SHOWN"
  elif [ -n "$LIST" ]; then
    { printf 'since %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; printf '%s' "$LIST" | sed 's/^/file /'; } > "$OWED.tmp.$$" && mv "$OWED.tmp.$$" "$OWED"
  fi
  P1="ViD re-entry — your memory of this run was compacted or resumed; continue from these records"
  if [ -n "$LIST" ] && [ "$SRC" = resume ]; then
    P2="Re-read these in full, with the Read tool, if your memory of the run is thin (a resume, nothing cut: no re-read is enforced):
$(printf '%s' "$LIST" | sed 's/^/- /')"
  elif [ -n "$LIST" ]; then
    P2="Re-read these in full now, with the Read tool:
$(printf '%s' "$LIST" | sed 's/^/- /')
Until each is read in full, every tool but Read is refused. The owner can delete $OWED from another terminal to lift this."
  else P2="Re-read: no ViD skill file found under $PR"; fi
  P3=''
  RV=$(sed -n 's/^records:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$H/checks/records-version" 2>/dev/null | head -n 1)
  if [ -n "$RV" ] && [ "$RV" -ge 9 ] && [ -f "$H/checks/observe.sh" ]; then P3=$(cd "$H" && sh checks/observe.sh alive 2>&1); fi
  # v0.9.7.1 (3.8, 3.9; R8, R9): every open job (checks/job.sh open), and the last return processed — before the bounded part
  if [ -f "$H/checks/job.sh" ]; then
    _jo=$(cd "$H" && sh checks/job.sh open 2>/dev/null | head -n 20)
    [ -n "$_jo" ] && P3="${P3:+$P3
}Open Codex jobs (sh checks/job.sh status <try>; wait, collect, clean or stop each — never launch a try twice):
$_jo"
  fi
  _lr=$(grep '^agent-returned ' "$H/.vid/metrics-events" 2>/dev/null | tail -n 1)
  [ -n "$_lr" ] && P3="${P3:+$P3
}Last return processed: ${_lr#agent-returned }"
  HEAD1="$P1

$P2
${P3:+
$P3
}"
  R=''; [ -f "$H/checks/observe.sh" ] && R=$(cd "$H" && sh checks/observe.sh resume 2>/dev/null)
  printf '%s\n' "$HEAD1"
  printf '%s\n' "$R" | awk -v used="$(printf '%s\n' "$HEAD1" | wc -c)" '
    NF { L[++n] = (length($0) > 300) ? substr($0, 1, 297) "..." : $0 }
    END { budget = 9000 - used - 60; shown = 0
      for (i = 1; i <= n && i <= 40; i++) { if (length(L[i]) + 1 > budget) break; print L[i]; budget -= length(L[i]) + 1; shown++ }
      if (shown < n) printf "(+%d more: sh checks/observe.sh resume)\n", n - shown }'
}
main 2>/dev/null
exit 0

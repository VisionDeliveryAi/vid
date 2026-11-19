#!/bin/sh
# Purpose: ViD's compulsory re-read (v0.9.7.0.6 spec 3.8, R11) — the
# plugin's PreToolUse hook (every tool) and PostToolUse hook (Read). After a
# compaction or a resume in a live run, hooks/reentry.sh writes the session's
# debt, <home>/.vid/reread-owed.<session_id>: `since <UTC>` and one `file
# <absolute path>` line per ViD skill file to re-read.
#   PostToolUse (Read) pays it, from what the read RETURNED (tool_response's
#     filePath, startLine, numLines, totalLines, truncatedByTokenCap): each
#     main-session read of a listed path appends `cover <path> <first line>
#     <last line> <total lines>` (one short append, so parallel reads lose
#     nothing). From v0.26.10.10 (R1) a truncated read pays too, but not its
#     last returned line, which may be partial; a truncated read that
#     returned one line or none pays nothing. A file is paid when its cover
#     lines together span 1 to its total; when every listed file is paid,
#     the debt file is removed. A failed read never fires PostToolUse, and
#     an agent's read never pays: the debt is the main session's.
#   PreToolUse enforces it: while the debt file stands, a main-session call
#     to any tool but Read is refused with the documented deny output, its
#     reason naming what is left of each unpaid path and how to read it in
#     windows (v0.26.10.10, R2) — never the debt file.
# For the owner only (v0.26.10.10, R4): the owner may delete
# <home>/.vid/reread-owed.<session> from another terminal to lift the block.
# No agent-facing text and no skill file says so.
# Fast exits, in order, before any resolver work: an `agent_id` in the input
# (an agent's call) is allowed at once; no .vid/ walking up from `cwd` and
# none at $CLAUDE_PROJECT_DIR is not a ViD project, allowed; otherwise the
# home is found as the page finds it (hooks/home.sh) — from 0.26.11.1.3 (R1), when
# the home is plain (vid_plain), by the shell's built-ins alone, with no git
# and no nested plan.sh, and the full resolver only otherwise. The input's
# fields are taken in one reader pass (kread). It fails open:
# malformed input, an unreadable debt file or any error allows the call, and
# so does a timeout. It always exits 0.
# The input is read with a key-anchored scanner, not hooks/json.sh: a tool's
# input or a read's response can be hundreds of kilobytes, and json.sh walks
# every character. A key is taken only where it follows `{` or `,`, which
# text inside a JSON string can never show unescaped; the first such
# occurrence wins (hooks/agent.sh's `keys`, moved there in v0.9.7.0.7).
IN=$(cat 2>/dev/null) || exit 0
case $0 in */*) HD=${0%/*} ;; *) HD=. ;; esac; [ -f "$HD/home.sh" ] && [ -f "$HD/agent.sh" ] || exit 0
. "$HD/home.sh"; . "$HD/agent.sh"
real() { _rd=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) && printf '%s/%s\n' "$_rd" "${1##*/}" || printf '%s\n' "$1"; }
# unpaid <debt file> [say]: the listed paths not yet covered 1…total by its cover lines. With `say` (v0.26.10.10,
# R2) each is named as the refusal names it: `<path> lines <a>–<b>, … of <N>` (N from a cover's total, the ranges
# no cover spans), `<path>, all of it` with no cover, or `<path> cannot be read: …` when it can't be opened.
unpaid() {
  awk -v say="${2:-}" '/^file / { f[++n] = substr($0, 6) }
    /^cover / { s = substr($0, 7); p = s; sub(/ [0-9]+ [0-9]+ [0-9]+$/, "", p); if (p == s) next
      split(substr(s, length(p) + 2), x, " "); nc[p]++; a[p, nc[p]] = x[1] + 0; b[p, nc[p]] = x[2] + 0; tot[p] = x[3] + 0 }
    END { for (i = 1; i <= n; i++) { p = f[i]; ok = 0; split("", cov)
        if (nc[p] > 0) { for (j = 1; j <= nc[p]; j++) for (l = a[p, j]; l <= b[p, j]; l++) cov[l] = 1
          ok = 1; for (l = 1; l <= tot[p]; l++) if (!(l in cov)) { ok = 0; break } }
        if (ok) continue
        if (say == "") { print p; continue }
        if ((getline _x < p) < 0) { print p " cannot be read: tell the owner the re-read is stuck"; continue }
        close(p)
        if (nc[p] == 0) { print p ", all of it"; continue }
        r = ""; for (l = 1; l <= tot[p]; l++) if (!(l in cov)) { s = l; while (l < tot[p] && !((l + 1) in cov)) l++; r = r (r == "" ? "" : ", ") s "–" l }
        print p " lines " r " of " tot[p] } }' "$1"
}
main() {
  kread hook_event_name session_id cwd agent_id tool_name filePath startLine numLines totalLines truncatedByTokenCap || return 0
  [ -n "${J_agent_id:-}" ] && return 0                      # 1. an agent's call
  EVN=${J_hook_event_name:-}; case "$EVN" in PreToolUse|PostToolUse) ;; *) return 0 ;; esac
  CWD=${J_cwd:-}; vid_near "$CWD" || return 0               # 2. not a ViD project
  SID=${J_session_id:-}; case "$SID" in ''|*[!A-Za-z0-9._-]*) return 0 ;; esac
  if vid_plain; then H=$VID_H; else H=$(vid_home "$CWD"); fi   # 3. a plain home (0.26.11.1.3, R1), else the resolver
  [ -n "$H" ] || return 0
  OWED="$H/.vid/reread-owed.$SID"
  [ -f "$OWED" ] || return 0
  [ -r "$OWED" ] || return 0
  TOOL=${J_tool_name:-}
  if [ "$EVN" = PostToolUse ]; then
    [ "$TOOL" = Read ] || return 0
    FP=${J_filePath:-}; SL=${J_startLine:-}; NL=${J_numLines:-}; TL=${J_totalLines:-}
    case "$SL$NL$TL" in ''|*[!0-9]*) return 0 ;; esac
    [ -n "$FP" ] && [ "$NL" -gt 0 ] || return 0
    # v0.26.10.10 (R1, F-71): a truncated read pays what it returned but its last line, which may be partial
    LL=$((SL + NL - 1)); [ "${J_truncatedByTokenCap:-}" = true ] && LL=$((LL - 1))
    [ "$LL" -ge "$SL" ] || return 0
    RF=$(real "$FP")
    for p in $(sed -n 's/^file //p' "$OWED"); do
      if [ "$p" = "$FP" ] || [ "$(real "$p")" = "$RF" ]; then
        printf 'cover %s %s %s %s\n' "$p" "$SL" "$LL" "$TL" >> "$OWED"
        [ -z "$(unpaid "$OWED")" ] && rm -f "$OWED"
        return 0
      fi
    done
    return 0
  fi
  [ "$TOOL" = Read ] && return 0
  U=$(unpaid "$OWED") || return 0
  [ -n "$U" ] || return 0
  _since=$(sed -n 's/^since //p' "$OWED" | head -n 1)   # v0.9.8.1 (R31): the deny names when the debt was armed
  # v0.26.10.10 (R2, F-71): what is left of each file and how to read it in windows; no word of the debt file
  MSG="ViD: your copy of this run's rules was cut at compaction (re-read owed since ${_since:-unknown}). Re-read these with the Read tool before anything else: $(unpaid "$OWED" say | awk 'NF { printf "%s%s", (n++ ? "; " : ""), $0 }'). Read long files in windows with offset and limit, at most 400 lines a call (for example offset 1 limit 400, then offset 400 limit 400). Each window counts; the block lifts when every line is covered."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(jesc "$MSG")"
}
IFS='
'
main 2>/dev/null
exit 0

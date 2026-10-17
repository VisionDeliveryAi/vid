#!/bin/sh
# Purpose: ViD's compulsory re-read (v0.9.7.0.6 spec 3.8, R11) — the
# plugin's PreToolUse hook (every tool) and PostToolUse hook (Read). After a
# compaction or a resume in a live run, hooks/reentry.sh writes the session's
# debt, <home>/.vid/reread-owed.<session_id>: `since <UTC>` and one `file
# <absolute path>` line per ViD skill file to re-read.
#   PostToolUse (Read) pays it, from what the read RETURNED (tool_response's
#     filePath, startLine, numLines, totalLines, truncatedByTokenCap): each
#     main-session read of a listed path that was not truncated appends
#     `cover <path> <first line> <last line> <total lines>` (one short
#     append, so parallel reads lose nothing). A file is paid when its cover
#     lines together span 1 to its total; when every listed file is paid,
#     the debt file is removed. A failed read never fires PostToolUse, and
#     an agent's read never pays: the debt is the main session's.
#   PreToolUse enforces it: while the debt file stands, a main-session call
#     to any tool but Read is refused with the documented deny output, its
#     reason naming the unpaid paths and the debt file, which the owner can
#     delete from another terminal to lift it.
# Fast exits, in order, before any resolver work: an `agent_id` in the input
# (an agent's call) is allowed at once; no .vid/ walking up from `cwd` and
# none at $CLAUDE_PROJECT_DIR is not a ViD project, allowed; otherwise the
# home is found as the page finds it (hooks/home.sh). It fails open:
# malformed input, an unreadable debt file or any error allows the call, and
# so does a timeout. It always exits 0.
# The input is read with a key-anchored scanner, not hooks/json.sh: a tool's
# input or a read's response can be hundreds of kilobytes, and json.sh walks
# every character. A key is taken only where it follows `{` or `,`, which
# text inside a JSON string can never show unescaped; the first such
# occurrence wins (hooks/agent.sh's `keys`, moved there in v0.9.7.0.7).
IN=$(cat 2>/dev/null) || exit 0
HD=$(dirname "$0"); [ -f "$HD/home.sh" ] && [ -f "$HD/agent.sh" ] || exit 0
. "$HD/home.sh"; . "$HD/agent.sh"
real() { _rd=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) && printf '%s/%s\n' "$_rd" "${1##*/}" || printf '%s\n' "$1"; }
# unpaid <debt file>: the listed paths not yet covered 1…total by its cover lines
unpaid() {
  awk '/^file / { f[++n] = substr($0, 6) }
    /^cover / { s = substr($0, 7); p = s; sub(/ [0-9]+ [0-9]+ [0-9]+$/, "", p); if (p == s) next
      split(substr(s, length(p) + 2), x, " "); nc[p]++; a[p, nc[p]] = x[1] + 0; b[p, nc[p]] = x[2] + 0; tot[p] = x[3] + 0 }
    END { for (i = 1; i <= n; i++) { p = f[i]; ok = 0
        if (nc[p] > 0) { split("", cov); for (j = 1; j <= nc[p]; j++) for (l = a[p, j]; l <= b[p, j]; l++) cov[l] = 1
          ok = 1; for (l = 1; l <= tot[p]; l++) if (!(l in cov)) { ok = 0; break } }
        if (!ok) print p } }' "$1"
}
main() {
  KV=$(keys hook_event_name session_id cwd agent_id tool_name filePath startLine numLines totalLines truncatedByTokenCap) || return 0
  [ -n "$(kv agent_id)" ] && return 0                       # 1. an agent's call
  EVN=$(kv hook_event_name); case "$EVN" in PreToolUse|PostToolUse) ;; *) return 0 ;; esac
  CWD=$(kv cwd); vid_near "$CWD" || return 0                 # 2. not a ViD project
  SID=$(kv session_id); case "$SID" in ''|*[!A-Za-z0-9._-]*) return 0 ;; esac
  H=$(vid_home "$CWD"); [ -n "$H" ] || return 0              # 3. the resolver
  OWED="$H/.vid/reread-owed.$SID"
  [ -f "$OWED" ] || return 0
  [ -r "$OWED" ] || return 0
  TOOL=$(kv tool_name)
  if [ "$EVN" = PostToolUse ]; then
    [ "$TOOL" = Read ] || return 0
    [ "$(kv truncatedByTokenCap)" = true ] && return 0
    FP=$(kv filePath); SL=$(kv startLine); NL=$(kv numLines); TL=$(kv totalLines)
    case "$SL$NL$TL" in ''|*[!0-9]*) return 0 ;; esac
    [ -n "$FP" ] && [ "$NL" -gt 0 ] || return 0
    RF=$(real "$FP")
    for p in $(sed -n 's/^file //p' "$OWED"); do
      if [ "$p" = "$FP" ] || [ "$(real "$p")" = "$RF" ]; then
        printf 'cover %s %s %s %s\n' "$p" "$SL" "$((SL + NL - 1))" "$TL" >> "$OWED"
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
  MSG="ViD: your copy of this run's rules was cut at compaction (re-read owed since ${_since:-unknown}). Read these in full first, with the Read tool: $(printf '%s\n' "$U" | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $0 }'). The owner can delete $OWED from another terminal to lift this."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(jesc "$MSG")"
}
IFS='
'
main 2>/dev/null
exit 0

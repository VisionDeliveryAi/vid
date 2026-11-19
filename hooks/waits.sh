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
# v0.26.10.4 (R8, F-38, F-52): it reads shell syntax only. Literal prose is removed first — single- and
# double-quoted strings and here-document bodies — while what a shell runs is kept and read: a command
# substitution inside double quotes ($(…) and backticks), the argument of `-c` to sh, bash, zsh or dash and of
# `eval`, and a here-document fed to one of those shells. `while` or `until` counts only as a command's first
# word: at the start, or after ; && || | & ! a newline ( { $( a backtick, do, then, elif or else. The sleep and
# the probe checks read the same stripped text.
# Fast exits first, the last of them (0.26.11.1.3, R1) a cwd outside any ViD project; malformed input, or any error,
# allows the call. It always exits 0.
IN=$(cat 2>/dev/null) || exit 0
case "$IN" in *'"vid:builder"'*|*'"vid:fixer"'*) ;; *) exit 0 ;; esac
case $0 in */*) HD=${0%/*} ;; *) HD=. ;; esac; [ -f "$HD/agent.sh" ] && [ -f "$HD/home.sh" ] || exit 0
. "$HD/agent.sh"; . "$HD/home.sh"
main() {
  kread hook_event_name tool_name agent_type run_in_background command cwd || return 0   # 0.26.11.1.3 (R1): one reader pass
  [ "${J_hook_event_name:-}" = PreToolUse ] && [ "${J_tool_name:-}" = Bash ] || return 0
  case "${J_agent_type:-}" in vid:builder|vid:fixer) ;; *) return 0 ;; esac
  [ "${J_run_in_background:-}" = true ] && return 0
  # 0.26.11.1.3 (R1): a call whose cwd has no .vid/ up to the root, and none at $CLAUDE_PROJECT_DIR, is no ViD
  # run's: allowed before the command is read (hooks/home.sh's vid_near, no process). An input with no cwd: as before.
  [ -z "${J_cwd:-}" ] || vid_near "$J_cwd" || return 0
  [ -n "${J_command:-}" ] || return 0
  # the command with its newlines (keys reads them as spaces), then its shell syntax alone: S
  C=$(printf '%s' "$IN" | awk 'BEGIN { RS = "\001" } { if (!match($0, /[{,][ \t\r\n]*"command"[ \t\r\n]*:[ \t\r\n]*"/)) exit
      r = substr($0, RSTART + RLENGTH); v = ""; j = 1
      while (1) { ch = substr(r, j, 1); if (ch == "" || ch == "\"") break
        if (ch == "\\") { e = substr(r, j + 1, 1); if (e == "n") v = v "\n"; else if (e == "t") v = v "\t"; else if (e == "r") v = v ""; else v = v e; j += 2; continue }
        v = v ch; j++ }
      printf "%s", v }')
  [ -n "$C" ] || return 0
  S=$(printf '%s' "$C" | awk "$STRIP")
  W=$(printf '%s\n' "$S" | tr ';|&()`{}\n' '         ' | tr -s ' \t' '  ')
  WHY=''
  if printf '%s\n' "$S" | awk "$LOOPW"; then
    if printf ' %s \n' "$W" | grep -qE ' sleep '; then WHY='a loop that sleeps'
    elif printf '%s\n' "$S" | grep -qE '(^|[^A-Za-z0-9_./-])(checks/test\.sh|test\.sh|git|docker)([^A-Za-z0-9_.-]|$)'; then WHY='a loop that repeats a status probe'; fi
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
# STRIP: the awk program that keeps a command's shell syntax (R8). A quoted string becomes the word Q; the code a
# shell runs from a string or a here-document — a substitution in double quotes, `-c`'s or `eval`'s argument, a
# here-document fed to sh, bash, zsh or dash — is read the same way and added after the command, a line of its own.
STRIP='
function bn(w) { sub(/.*\//, "", w); return w }
function isshell(w) { w = bn(w); return w == "sh" || w == "bash" || w == "zsh" || w == "dash" }
function runs(cw, pw) { return (isshell(cw) && pw ~ /^-[A-Za-z]*c$/) || bn(cw) == "eval" }
function lead(w) { return w == "" || w ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || w == "!" || w == "{" || w == "}" || w == "do" || w == "then" || w == "else" || w == "elif" || w == "time" || w == "exec" || w == "nohup" || w == "command" }
function close_paren(s, i,   d, c, n) { d = 1; n = length(s); while (i <= n) { c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue } if (c == "(") d++; else if (c == ")") { d--; if (!d) return i } i++ } return n + 1 }
function code(s,   o, x, i, n, c, j, k, w, cw, pw, nh, H, HT, HK, inner, d, line, ln, body, t, p, q) {
  o = ""; x = ""; n = length(s); i = 1; w = ""; cw = ""; pw = ""; nh = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { o = o substr(s, i, 2); w = w substr(s, i + 1, 1); i += 2; continue }
    if (c == "\047") { j = index(substr(s, i + 1), "\047"); if (!j) j = n - i + 1; inner = substr(s, i + 1, j - 1); i += j + 1
      if (runs(cw, pw)) x = x "\n" code(inner); o = o "Q"; w = w "Q"; continue }
    if (c == "\"") { j = i + 1; inner = ""
      while (j <= n) { d = substr(s, j, 1)
        if (d == "\\") { inner = inner substr(s, j + 1, 1); j += 2; continue }
        if (d == "\"") break
        if (d == "$" && substr(s, j + 1, 1) == "(") { k = close_paren(s, j + 2); x = x "\n" code(substr(s, j + 2, k - j - 2)); inner = inner substr(s, j, k - j + 1); j = k + 1; continue }
        if (d == "`") { k = index(substr(s, j + 1), "`"); if (!k) k = n - j + 1; x = x "\n" code(substr(s, j + 1, k - 1)); inner = inner substr(s, j, k + 1); j += k + 1; continue }
        inner = inner d; j++ }
      i = j + 1; if (runs(cw, pw)) x = x "\n" code(inner); o = o "Q"; w = w "Q"; continue }
    if (c == "<" && substr(s, i, 2) == "<<" && substr(s, i, 3) != "<<<") { i += 2; t = 0; if (substr(s, i, 1) == "-") { t = 1; i++ }
      while (substr(s, i, 1) ~ /[ \t]/) i++
      q = substr(s, i, 1); d = ""
      if (q == "\047" || q == "\"") { j = index(substr(s, i + 1), q); if (!j) j = n - i + 1; d = substr(s, i + 1, j - 1); i += j + 1 }
      else { while (i <= n && substr(s, i, 1) !~ /[ \t\n;&|()<>]/) { c = substr(s, i, 1); if (c != "\\") d = d c; i++ } }
      H[++nh] = d; HT[nh] = t; HK[nh] = isshell(cw); o = o "<< "; continue }
    if (c == "\n") {
      if (w != "") { if (cw == "" && !lead(w)) cw = w; pw = w; w = "" }
      o = o "\n"
      for (k = 1; k <= nh; k++) { body = ""
        while (i < n) { p = index(substr(s, i + 1), "\n"); if (p) line = substr(s, i + 1, p - 1); else line = substr(s, i + 1)
          i += (p ? p : length(line) + 1); ln = line; if (HT[k]) sub(/^\t+/, "", ln)
          if (ln == H[k]) break
          body = body line "\n" }
        if (HK[k]) x = x "\n" code(body) }
      nh = 0; cw = ""; pw = ""; i++; continue }
    if (c ~ /[;&|()`]/) { if (w != "") { if (cw == "" && !lead(w)) cw = w; pw = w; w = "" } o = o c; cw = ""; pw = ""; i++; continue }
    if (c == "$" && substr(s, i + 1, 1) == "(") { if (w != "") { if (cw == "" && !lead(w)) cw = w; pw = w; w = "" } o = o "$("; cw = ""; pw = ""; i += 2; continue }
    if (c ~ /[ \t]/) { if (w != "") { if (cw == "" && !lead(w)) cw = w; pw = w; w = "" } o = o c; i++; continue }
    w = w c; o = o c; i++ }
  return o x }
BEGIN { RS = "\001" } { printf "%s\n", code($0) }'
# LOOPW: exit 0 when `while` or `until` is a command's first word in the stripped text (R8)
LOOPW='BEGIN { RS = "\001" } { t = $0; gsub(/\$\(/, "\n", t); gsub(/&&|\|\|/, "\n", t); gsub(/[;&|()`]/, "\n", t); n = split(t, L, "\n")
  for (i = 1; i <= n; i++) { k = split(L[i], A, /[ \t]+/); for (j = 1; j <= k; j++) { a = A[j]; if (a == "" || a == "!" || a == "{" || a == "}" || a == "do" || a == "then" || a == "elif" || a == "else") continue
      if (a == "while" || a == "until") f = 1; break } } }
  END { exit !f }'
IFS='
'
main 2>/dev/null
exit 0

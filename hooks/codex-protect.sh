#!/bin/sh
# Purpose: ViD's protected paths for a Codex builder (v0.9.7.1 spec 3.9, R9) — a Codex PreToolUse hook that
# checks/job.sh gives each launch (`-c hooks.PreToolUse=…`), with the job's protected-path list as its argument
# (.vid/jobs/<try>.protected: the one set of checks/brief.sh `protected`, a directory ending `/`). Measured in
# rehearsal R-6: a Codex permission profile makes the set read-only but also every git folder, so the builder
# could not commit its own work; `--sandbox workspace-write` lets it commit and protects no path. So the sandbox is
# workspace-write and this hook refuses, with Codex's documented deny output:
#   - a patch (apply_patch) adding, updating, deleting or moving a protected path;
#   - a shell command whose write target is a protected path: the target of `>`/`>>`, each file operand of tee,
#     the file operands of sed -i, cp's and install's and ln's last operand, every operand of mv, rm, touch,
#     truncate, chmod, `git checkout`, `git restore` and `git rm`, dd's of=;
#   - a shell command running an embedded script (a here-document, or a script after -c or -e) that names a
#     protected path, and `git apply` or `patch` naming one.
# It reads the command's words only; nothing parses a programming language, and it claims no more: the backstop
# is `checks/brief.sh return`, which refuses a pass whose receipt tested other protected content. It fails open
# on input it can't read and always exits 0.
IN=$(cat 2>/dev/null) || exit 0
PL=${1:-}; [ -n "$PL" ] && [ -r "$PL" ] || exit 0
HD=$(dirname "$0"); [ -f "$HD/agent.sh" ] || exit 0
. "$HD/agent.sh"
deny() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(jesc "ViD: refused — $1 is protected (law, tests, checks, design or the harness). A builder lands no law: hand it back as a not line whose reason begins law-needed:.")"; exit 0; }
main() {
  KV=$(keys tool_name command cwd) || return 0
  T=$(kv tool_name); C=$(kv command); CWD=$(kv cwd)
  [ -n "$C" ] || return 0
  # isp <path>: the path, relative to the worktree, is in the protected set
  isp() { _p=$1; [ -n "$CWD" ] && case "$_p" in "$CWD"/*) _p=${_p#"$CWD"/} ;; esac
    while case "$_p" in ./*) true ;; *) false ;; esac; do _p=${_p#./}; done
    awk -v p="$_p" '{ if ((substr($0, length($0)) == "/" && (index(p, $0) == 1 || p "/" == $0)) || p == $0) f = 1 } END { exit f ? 0 : 1 }' "$PL"; }
  case "$T" in
    apply_patch|Edit|Write)
      # the patch's headers (the input's line breaks arrive as spaces): a path runs to the next blank
      for f in $(printf '%s\n' "$C" | grep -oE '\*\*\* (Add File|Update File|Delete File|Move to): [^ ]+' | sed -E 's/^\*\*\* [A-Za-z ]+: //'); do isp "$f" && deny "$f"; done
      return 0 ;;
    Bash) ;;
    *) return 0 ;;
  esac
  # an embedded script, git apply or patch naming a protected path
  for p in $(cat "$PL"); do
    case "$C" in *"$p"*)
      if printf '%s\n' "$C" | grep -qE '<<|[[:space:]]-[ce][[:space:]]|(^|[;&|[:space:]])(patch|git[[:space:]]+apply)([[:space:]]|$)'; then deny "$p"; fi ;;
    esac
  done
  # the write targets, by words
  W=$(printf '%s\n' "$C" | awk '
    function unq(c,   o, i, ch, q) { o = ""; q = ""
      for (i = 1; i <= length(c); i++) { ch = substr(c, i, 1)
        if (q != "") { if (ch == q) { q = ""; continue } if (ch == " " || ch == "\t") ch = "\004"; else if (index("<>|&;()", ch)) ch = "\005"; o = o ch; continue }
        if (ch == "\"" || ch == "\047") { q = ch; continue } o = o ch }
      return o }
    function emit(x) { gsub("\004", " ", x); print x }
    function seg(cmd, n, OP, si, sx, sub_,   k) {
      if (cmd == "tee" || cmd == "mv" || cmd == "rm" || cmd == "touch" || cmd == "truncate" || cmd == "chmod") { for (k = 1; k <= n; k++) emit(OP[k]); return }
      if (cmd == "sed" && si) { for (k = (sx ? 1 : 2); k <= n; k++) emit(OP[k]); return }
      if ((cmd == "cp" || cmd == "install" || cmd == "ln") && n >= 1) { emit(OP[n]); return }
      if (cmd == "dd") { for (k = 1; k <= n; k++) if (index(OP[k], "of=") == 1) emit(substr(OP[k], 4)); return }
      if (cmd == "git" && (OP[1] == "checkout" || OP[1] == "restore" || OP[1] == "rm")) { for (k = 2; k <= n; k++) emit(OP[k]); return } }
    { d = unq($0); gsub(/[0-9]*>&[0-9-]*/, " ", d); gsub(/&>/, " > ", d); gsub(/>>/, " \002 ", d); gsub(/>/, " > ", d); gsub("\002", ">>", d)
      gsub(/\|\||&&/, " \003 ", d); gsub(/[|&;()]/, " \003 ", d)
      n = split(d, w, /[ \t]+/); cmd = ""; m = 0; si = 0; sx = 0; split("", OP)
      for (i = 1; i <= n + 1; i++) {
        if (i > n || w[i] == "\003") { seg(cmd, m, OP, si, sx); cmd = ""; m = 0; si = 0; sx = 0; split("", OP); continue }
        x = w[i]; if (x == "") continue
        if (x == ">" || x == ">>") { i++; if (i <= n && w[i] != "\003") emit(w[i]); continue }
        if (x ~ /^</) { if (x == "<" || x == "<<" || x == "<<-" || x == "<<<") i++; continue }
        if (cmd == "") { if (x ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue; cmd = x; sub(/.*\//, "", cmd); continue }
        if (cmd == "sed" && (x ~ /^-[A-Za-z]*i/ || x ~ /^--in-place/)) { si = 1; continue }
        if (cmd == "sed" && (x == "-e" || x == "-f" || x == "--expression" || x == "--file")) { sx = 1; i++; continue }
        if (x == "--") continue
        if (x ~ /^-/ && cmd != "dd") continue
        OP[++m] = x } }')
  for f in $W; do isp "$f" && deny "$f"; done
  return 0
}
IFS='
'
main 2>/dev/null
exit 0

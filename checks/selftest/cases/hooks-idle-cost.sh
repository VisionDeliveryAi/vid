#!/bin/sh
# Purpose: selftest case — a hook with nothing to do costs next to nothing (0.26.11.1.3, R1). Every external command a hook
# starts is counted through a shim on the PATH, as prd-court-forks-constant.sh counts the PRD court's. Convicts unless
# each hook hooks.json names, fed a sample input of each event it is registered for, in a folder with no .vid/ up to
# the root and no CLAUDE_PROJECT_DIR, starts three external commands or fewer, each sample fed on its own (a builder's
# and a fixer's Bash call among them); unless, in a ViD project whose home is plain (its .vid/ holds RUN-STATE.md)
# with no re-read owed, hooks/reread.sh on a main-session PreToolUse call starts four or fewer, none of them git or
# sh — from the home and from a folder inside it; and unless a builder's sleep 300 from inside that project is still
# refused. A hook named in hooks.json with no sample, or a sample holding two inputs, convicts too. Gated on the plugin's hooks/. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
HD=$CHECKS/../hooks
[ -f "$HD/reread.sh" ] && [ -f "$HD/hooks.json" ] || { echo 'needs the plugin'"'"'s hooks/'; exit 77; }
HD=$(cd "$HD" && pwd -P)
fail() { echo "hooks-idle-cost: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; T=$(cd "$T" && pwd -P)
SH=$(command -v sh)
mkdir -p "$T/shim"
for c in awk sed grep cut tr head tail sort uniq cksum dirname basename cat wc date mktemp rm mv cp mkdir touch \
  env expr uname git ls find tee xargs od paste comm cmp diff printf echo test sh bash dash pwd sleep python3 perl; do
  p=$(command -v "$c" 2>/dev/null || true); case "$p" in /*) ;; *) continue ;; esac
  printf '#!%s\nprintf "%%s\\n" %s >> "$SHIMLOG"\nexec "%s" "$@"\n' "$SH" "$c" "$p" > "$T/shim/$c"; chmod +x "$T/shim/$c"
done
# count <hook> <dir> <input>: the external commands the hook starts, run in <dir>; their names in $T/log
count() {
  : > "$T/log"
  printf '%s' "$3" | ( cd "$2" && env -u CLAUDE_PROJECT_DIR SHIMLOG="$T/log" PATH="$T/shim:$PATH" CLAUDE_PLUGIN_ROOT="$HD/.." "$SH" "$HD/$1" ) > "$T/out" 2>&1 || true
  grep -c . "$T/log" || true
}
# the shim sees a hook's commands at all
: > "$T/log"; printf '{}' | ( env SHIMLOG="$T/log" PATH="$T/shim:$PATH" "$SH" -c 'cat > /dev/null' ); [ "$(grep -c . "$T/log")" = 1 ] || fail 'the shim does not count a command'
# a folder with no .vid/ up to the root, seven levels below the case's folder
N="$T/none/a/b/c/d/e/f"; mkdir -p "$N"
d=$N; while :; do [ -d "$d/.vid" ] && { echo "a .vid/ sits above the case's folder ($d), so no folder here is outside a ViD project"; exit 77; }; [ "$d" = / ] && break; d=$(dirname "$d"); done
TI='"tool_input":{"command":"ls"}'
s() { printf '{"session_id":"S1","transcript_path":"/t/S1.jsonl","cwd":"%s","hook_event_name":"%s"%s}\n' "$N" "$1" "${2:+,$2}"; }
samples() { # <hook>: one input a line, each event the hook is registered for, the main session's and a helper's
  case $1 in
    reread.sh) s PreToolUse "\"tool_name\":\"Bash\",$TI"; s PreToolUse "\"tool_name\":\"Bash\",$TI,\"agent_id\":\"a1\",\"agent_type\":\"general-purpose\""
      s PostToolUse '"tool_name":"Read","tool_input":{"file_path":"/x"},"tool_response":{"type":"text","file":{"filePath":"/x","content":"a","numLines":1,"startLine":1,"totalLines":1}}' ;;
    waits.sh) s PreToolUse "\"tool_name\":\"Bash\",$TI"
      s PreToolUse "\"tool_name\":\"Bash\",$TI,\"agent_id\":\"a1\",\"agent_type\":\"vid:builder\""
      s PreToolUse "\"tool_name\":\"Bash\",$TI,\"agent_id\":\"a2\",\"agent_type\":\"vid:fixer\"" ;;
    face-standing.sh) s UserPromptSubmit '"prompt":"hi"'; s Stop '"stop_hook_active":false'; s StopFailure '"error":"authentication_failed"'
      s PostToolUse '"tool_name":"Write","tool_input":{"file_path":"/x","content":"a"},"tool_response":{"type":"create"}'
      s PostToolUse "\"tool_name\":\"Bash\",$TI,\"tool_response\":{\"stdout\":\"x\"},\"agent_id\":\"a1\",\"agent_type\":\"general-purpose\"" ;;
    net.sh) s PostToolUse "\"tool_name\":\"Bash\",$TI,\"tool_response\":{\"stdout\":\"x\"}"
      s PostToolUse "\"tool_name\":\"Bash\",$TI,\"tool_response\":{\"stdout\":\"x\"},\"agent_id\":\"a1\",\"agent_type\":\"vid:builder\"" ;;
    stop-failure.sh) s StopFailure '"error":"authentication_failed","error_details":"401"'; s Notification '"notification_type":"quota_auto_resume_stale","message":"m"' ;;
    record.sh) s SessionStart '"source":"startup","model":"m"'; s SubagentStart '"agent_id":"a1","agent_type":"general-purpose"'
      s SubagentStop '"agent_id":"a1","agent_type":"general-purpose","agent_transcript_path":"/t/a1.jsonl"' ;;
    reentry.sh) s SessionStart '"source":"compact"'; s SessionStart '"source":"resume"' ;;
  esac
}
IFS='
'
HOOKS=$(grep -o 'hooks/[a-z-]*\.sh' "$HD/hooks.json" | sed 's|^hooks/||' | sort -u)
[ -n "$HOOKS" ] || fail 'hooks.json names no hook'
RAN=0
for h in $HOOKS; do
  [ -n "$(samples "$h")" ] || fail "hooks.json names $h, which has no sample here"
  for i in $(samples "$h"); do
    case $i in *'"hook_event_name"'*'"hook_event_name"'*) fail "a sample for $h holds two inputs: $i" ;; esac
    RAN=$((RAN + 1))
    n=$(count "$h" "$N" "$i")
    [ "$n" -le 3 ] || fail "outside a ViD project $h started $n external commands (over 3): $(tr '\n' ' ' < "$T/log")— fed $i"
  done
done
# a ViD project whose home is plain, no re-read owed: reread.sh on a main-session PreToolUse call
P="$T/home"; mkdir -p "$P/.vid" "$P/src/deep"; mkdir -p "$P/checks"; cp "$CHECKS/plan.sh" "$P/checks/"
( cd "$P" && git init -q && printf '.vid/\n' > .gitignore && git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root )
printf 'run: active\nsession: S1\n' > "$P/.vid/RUN-STATE.md"
printf 'stage name=develop state=start session=S1 records=8 at=2026-10-02T10:00:00Z\n' > "$P/.vid/metrics-events"
for c in "$P" "$P/src/deep"; do
  i=$(printf '{"session_id":"S1","transcript_path":"/t/S1.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash",%s,"tool_use_id":"t1"}' "$c" "$TI")
  n=$(count reread.sh "$c" "$i")
  [ "$n" -le 4 ] || fail "in a plain home with no debt reread.sh started $n external commands (over 4) from $c: $(tr '\n' ' ' < "$T/log")"
  grep -qxE 'git|sh|bash|dash' "$T/log" && fail "in a plain home with no debt reread.sh ran git or sh from $c: $(tr '\n' ' ' < "$T/log")"
  [ ! -s "$T/out" ] || fail "with no debt reread.sh printed something from $c: $(cat "$T/out")"
done
# the outside-project exit swallows no real call: a builder's long sleep from inside the project is still refused
i=$(printf '{"session_id":"S1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"sleep 300"},"agent_id":"a1","agent_type":"vid:builder"}' "$P/src/deep")
count waits.sh "$P" "$i" > /dev/null
grep -q '"permissionDecision":"deny"' "$T/out" || fail "a builder's sleep 300 from inside the project was not refused: $(cat "$T/out")"
echo "hooks-idle-cost: ok — $RAN inputs outside a project"
exit 0

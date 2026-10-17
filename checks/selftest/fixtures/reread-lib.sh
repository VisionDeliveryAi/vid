# Purpose: selftest fixture — a toy plugin root and a toy run for the
# re-entry page and the re-read hook (v0.9.7.0.6 spec 3.4, 3.8; §6 C-1…C-5).
# Sourced after the case has made and entered $T. The plugin root
# "$T/plugin root" (a space in it) holds the hooks under test and the toy
# skills of fixed lengths — vid-develop 814 lines, vid-test-manager 300,
# vid-verify 120, vid-fix 200, vid-build 150 — and $CLAUDE_PLUGIN_ROOT names it. The run's
# home $H is a git repository with .vid/RUN-STATE.md (`run: active`), a
# `stage name=develop state=start` event, the observer and records-version 9.
#   page <source> [session] [cwd]   feeds reentry.sh a SessionStart input; stdout to $T/page.out
#   pre <tool> [session] [cwd] [agent]   feeds reread.sh a PreToolUse input; stdout to $T/pre.out
#   rd <path> <start> <num> [session] [cwd] [agent] [truncated]   feeds reread.sh a Read's PostToolUse
#   denied / allowed   asserts on $T/pre.out
# Env: CHECKS, T.
HD="$CHECKS/../hooks"
PR="$T/plugin root"; mkdir -p "$PR/hooks"; cp "$HD"/*.sh "$HD/hooks.json" "$PR/hooks/"
mkdir -p "$PR/.claude-plugin"; printf '{"name":"vid","version":"0.9.7.0.6"}\n' > "$PR/.claude-plugin/plugin.json"
for s in vid-develop:814 vid-test-manager:300 vid-verify:120 vid-fix:200 vid-build:150; do
  mkdir -p "$PR/skills/${s%%:*}"; awk -v n="${s##*:}" 'BEGIN { for (i = 1; i <= n; i++) print "line " i }' > "$PR/skills/${s%%:*}/SKILL.md"
done
PR=$(cd "$PR" && pwd -P); CLAUDE_PLUGIN_ROOT=$PR; export CLAUDE_PLUGIN_ROOT
DV="$PR/skills/vid-develop/SKILL.md"; TM="$PR/skills/vid-test-manager/SKILL.md"; VV="$PR/skills/vid-verify/SKILL.md"; FX="$PR/skills/vid-fix/SKILL.md"; VB="$PR/skills/vid-build/SKILL.md"
H="$T/home"; mkdir -p "$H/.vid" "$H/checks"; H=$(cd "$H" && pwd -P)
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" "$H/checks/"
printf '# Purpose: toy\nrecords: 9\n' > "$H/checks/records-version"
( cd "$H" && git init -q && printf '.vid/\n' > .gitignore && git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root )
printf 'run: active\nsession: S1\nslice: 3 open\nclaims: ROW-1 ROW-2\n' > "$H/.vid/RUN-STATE.md"
printf 'stage name=develop state=start session=S1 records=8 at=2026-10-02T10:00:00Z\n' > "$H/.vid/metrics-events"
unset CLAUDE_PROJECT_DIR
page() { printf '{"session_id":"%s","transcript_path":"/t/%s.jsonl","cwd":"%s","hook_event_name":"SessionStart","source":"%s"}' "${2:-S1}" "${2:-S1}" "${3:-$H}" "$1" | sh "$PR/hooks/reentry.sh" > "$T/page.out"; }
pre() { _ag=''; [ -n "${4:-}" ] && _ag=",\"agent_id\":\"$4\",\"agent_type\":\"general-purpose\""
  printf '{"session_id":"%s","transcript_path":"/t/%s.jsonl","cwd":"%s","permission_mode":"bypassPermissions","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"command":"ls"}%s,"tool_use_id":"toolu_1"}' "${2:-S1}" "${2:-S1}" "${3:-$H}" "$1" "$_ag" | sh "$PR/hooks/reread.sh" > "$T/pre.out"; }
rd() { _ag=''; [ -n "${6:-}" ] && _ag=",\"agent_id\":\"$6\",\"agent_type\":\"general-purpose\""; _tr=''; [ -n "${7:-}" ] && _tr=',"truncatedByTokenCap":true'
  _tl=$(grep -c '' "$1")
  printf '{"session_id":"%s","transcript_path":"/t/%s.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"Read","tool_input":{"file_path":"%s"},"tool_response":{"type":"text","file":{"filePath":"%s","content":"line \\"1\\",\\n{\\"numLines\\":1}","numLines":%s,"startLine":%s,"totalLines":%s%s}}%s,"tool_use_id":"toolu_2"}' "${4:-S1}" "${4:-S1}" "${5:-$H}" "$1" "$1" "$3" "$2" "$_tl" "$_tr" "$_ag" | sh "$PR/hooks/reread.sh" > /dev/null; }
denied() { grep -q '"permissionDecision":"deny"' "$T/pre.out" || fail "not denied: $1"; }
allowed() { [ ! -s "$T/pre.out" ] || fail "not allowed: $1"; }
fail() { echo "${CASE:-reread}: $*" >&2; cat "$T/page.out" "$T/pre.out" >&2 2>/dev/null; ls -la "$H/.vid" >&2; exit 1; }
# v0.9.7.0.7 (3.7; §6 E-3): an agent in the toy run.
#   ag_setup <agent> <brief> <context>   writes the brief file <H>/<brief> (when it is under .vid/briefs/),
#        the agent's own transcript (its first user entry naming <brief>; two calls, the latest of
#        context <context>) under a parent path with a space, and the home's agent-start naming it
#   net <agent> [session] [cwd]   feeds hooks/net.sh a PostToolUse input; stdout to $T/net.out
ag_setup() {
  case "$2" in .vid/briefs/*) mkdir -p "$H/$(dirname "$2")"; printf 'role: builder    slice: 2\n' > "$H/$2" ;; esac
  _pp="$T/projects/the session.jsonl"; mkdir -p "${_pp%.jsonl}/subagents"; : > "$_pp"
  { printf '{"parentUuid":null,"isSidechain":true,"type":"user","message":{"role":"user","content":"Repository: %s. Your brief: %s — read it first."},"cwd":"%s"}\n' "$H" "$2" "$H"
    printf '{"message":{"model":"m","id":"msg_1","role":"assistant","content":[],"usage":{"input_tokens":2,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000,"output_tokens":5}},"type":"assistant","cwd":"%s"}\n' "$H"
    printf '{"message":{"model":"m","id":"msg_2","role":"assistant","content":[],"usage":{"input_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":5}},"type":"assistant","cwd":"%s"}\n' "$3" "$H"; } > "${_pp%.jsonl}/subagents/agent-$1.jsonl"
  printf 'agent-start session=S1 agent=%s type=general-purpose transcript="%s" at=2026-10-02T10:01:00Z\n' "$1" "$_pp" >> "$H/.vid/metrics-events"
}
net() { _ag=''; [ -n "$1" ] && _ag=",\"agent_id\":\"$1\",\"agent_type\":\"general-purpose\""
  printf '{"session_id":"%s","transcript_path":"/t/%s.jsonl","cwd":"%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"x"}%s,"tool_use_id":"toolu_9"}' "${2:-S1}" "${2:-S1}" "${3:-$H}" "$_ag" | sh "$PR/hooks/net.sh" > "$T/net.out"; }

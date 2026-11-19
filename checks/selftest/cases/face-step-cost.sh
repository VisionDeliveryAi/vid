#!/bin/sh
# Purpose: selftest case — the face's hook after a step costs next to nothing (0.26.11.1.3, R1). hooks/face-standing.sh runs
# in a project holding .vid/face/standing.json, from a toy plugin root whose checks/face.sh only logs that it ran.
# Convicts unless a PostToolUse step (the main session's or a helper's) and a prompt run no checks/face.sh, and a Stop
# does; unless, fed a PostToolUse Write of 200 KB, the hook ends inside 1 s; and unless, in that input, an agent_id
# after tool_input still marks a helper's step (the session's run file left as it was), while text in the Write's
# content that reads like an agent_id never does (the session's last step moves). Gated on the plugin's hooks/; the
# clock needs python3 or perl. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
HD=$CHECKS/../hooks
[ -f "$HD/face-standing.sh" ] || { echo 'needs the plugin'"'"'s hooks/face-standing.sh'; exit 77; }
if command -v python3 > /dev/null 2>&1; then ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }
elif command -v perl > /dev/null 2>&1; then ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }
else echo 'needs python3 or perl for the clock'; exit 77; fi
fail() { echo "face-step-cost: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; T=$(cd "$T" && pwd -P)
PR="$T/plugin"; mkdir -p "$PR/hooks" "$PR/checks"; cp "$HD"/*.sh "$PR/hooks/"
printf '#!/bin/sh\nprintf "face %%s\\n" "$*" >> "%s/face.log"\n' "$T" > "$PR/checks/face.sh"
P="$T/project"; mkdir -p "$P/.vid/face"; ( cd "$P" && git init -q ); printf '{"stops":[]}\n' > "$P/.vid/face/standing.json"
hook() { printf '%s' "$1" | ( cd "$P" && CLAUDE_PLUGIN_ROOT="$PR" sh "$PR/hooks/face-standing.sh" ) || fail "the hook failed on $2"; }
ran() { [ -f "$T/face.log" ] && grep -c . "$T/face.log" || echo 0; }
ev() { printf '{"session_id":"S1","transcript_path":"/t/S1.jsonl","cwd":"%s","hook_event_name":"%s"%s}' "$P" "$1" "${2:+,$2}"; }
hook "$(ev UserPromptSubmit '"prompt":"hi"')" 'a prompt'
hook "$(ev PostToolUse '"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"x"}')" 'a step'
hook "$(ev PostToolUse '"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"x"},"agent_id":"a1","agent_type":"general-purpose"')" "a helper's step"
[ "$(ran)" = 0 ] || fail "a prompt or a step ran checks/face.sh: $(cat "$T/face.log")"
[ "$(awk '{ print $1 }' "$P/.vid/face/run.S1")" = running ] || fail "the step did not write the run file: $(cat "$P/.vid/face/run.S1")"
hook "$(ev Stop '"stop_hook_active":false')" 'Stop'
[ "$(ran)" = 1 ] && grep -qx 'face standing' "$T/face.log" || fail "Stop did not run checks/face.sh standing once: $(cat "$T/face.log" 2>/dev/null)"
# a Write of 200 KB, its content escaped as Claude Code sends it, with text that reads like a key in it
big() { # <content key text> <tail after tool_input>
  K=$1 TL=$2 awk -v cwd="$P" 'BEGIN { k = ENVIRON["K"]; t = ENVIRON["TL"]; printf "{\"session_id\":\"S1\",\"transcript_path\":\"/t/S1.jsonl\",\"cwd\":\"%s\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/x/y.txt\",\"content\":\"%s", cwd, k
    while (n < 200000) { l = sprintf("line %d says \\\"hi\\\", {a: [1, 2]}, back\\\\slash\\n", ++i); printf "%s", l; n += length(l) }
    printf "\"},\"tool_response\":{\"type\":\"create\",\"filePath\":\"/x/y.txt\"}%s}", t }'
}
big 'x' ',"agent_id":"a9","agent_type":"general-purpose"' > "$T/helper.json"
big ',\"agent_id\":\"fake\",' '' > "$T/main.json"
[ "$(wc -c < "$T/helper.json")" -ge 200000 ] || fail 'the 200 KB input was not made'
hook "$(ev UserPromptSubmit '"prompt":"hi"')" 'a prompt'
cp "$P/.vid/face/run.S1" "$T/before"; sleep 1
a=$(ms); hook "$(cat "$T/helper.json")" "a helper's 200 KB Write"; b=$(ms)
[ $((b - a)) -lt 1000 ] || fail "the hook took $((b - a)) ms on a PostToolUse Write of 200 KB (1 s at most)"
cmp -s "$T/before" "$P/.vid/face/run.S1" || fail "an agent_id after tool_input was not read: the helper's step wrote the session's file ($(cat "$P/.vid/face/run.S1"))"
a=$(ms); hook "$(cat "$T/main.json")" "the session's 200 KB Write"; b=$(ms)
[ $((b - a)) -lt 1000 ] || fail "the hook took $((b - a)) ms on a PostToolUse Write of 200 KB (1 s at most)"
[ "$(awk '{ print $3 }' "$P/.vid/face/run.S1")" != "$(awk '{ print $3 }' "$T/before")" ] || fail "text in the Write's content was taken for an agent_id: the session's step did not move its last step"
[ "$(ran)" = 1 ] || fail "a 200 KB step ran checks/face.sh: $(cat "$T/face.log")"
echo 'face-step-cost: ok'
exit 0

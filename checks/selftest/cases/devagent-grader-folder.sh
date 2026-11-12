#!/bin/sh
# Purpose: selftest case — the grader still finds its pass (0.26.10.28.8, R1). The frozen grader.md names skills/vid-verify/passes/grader.md
# by the folder the dev side used to be in, so dm.sh's start of the role grader and of the stage grader puts, in the agent's own copy of its
# job note and never in the prompt, the plugin folder that holds skills/vid-verify/passes/grader.md and skills/vid-grade/GRADING.md, with
# a space in that folder's path; a builder's copy gets no such line; the two frozen files are unchanged. On a fake claude. Skips where
# devagent/ or skills/ is absent (a project's layout). Env: CHECKS.
set -eu
RT=$(cd "$CHECKS/.." && pwd -P); [ -d "$RT/devagent" ] && [ -d "$RT/skills/vid-verify" ] || { echo 'needs devagent/ and skills/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "devagent-grader-folder: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
P="$T/the plugin"; mkdir -p "$P/skills/vid-verify/passes" "$P/skills/vid-grade"; cp -R "$RT/devagent" "$P/devagent"
cp "$RT/skills/vid-verify/passes/grader.md" "$P/skills/vid-verify/passes/"; cp "$RT/skills/vid-grade/GRADING.md" "$P/skills/vid-grade/"; P=$(cd "$P" && pwd -P)
DM=$P/devagent/dev-manager/dm.sh; W="$T/work folder"; mkdir -p "$W/c1" "$W/c2" "$W/c3" "$T/bin"; DM_WORK=$W; export DM_WORK
M=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/fc"\nprintf "{\\"type\\":\\"system\\",\\"subtype\\":\\"init\\",\\"model\\":\\"%s\\"}\\n"\nprintf "{\\"type\\":\\"result\\",\\"subtype\\":\\"success\\",\\"is_error\\":false,\\"num_turns\\":1,\\"result\\":\\"done\\"}\\n"\n' "$T" "$M" > "$T/bin/claude"; chmod +x "$T/bin/claude"
printf 'ticket: 7\nthe job\n' > "$W/job"; L='The plugin folder, the one your role file means by the folder that holds the dev side'
for r in grader stage-grader builder; do c=c1; [ "$r" = stage-grader ] && c=c2; [ "$r" = builder ] && c=c3
  A=$(DM_AGENT_CLAUDE="$T/bin/claude" sh "$DM" start "$r" "$W/job" "$W/$c" 2> "$T/out") || fail "the $r did not start"
  N="$W/agents/$A/note"; if [ "$r" = builder ]; then ! grep -qF "$L" "$N" || fail "the builder's note names the plugin folder"; continue; fi
  grep -qxF "$L, and which holds skills/vid-verify/passes/grader.md and skills/vid-grade/GRADING.md: $P" "$N" || { cp "$N" "$T/out"; fail "the $r's own note does not name the plugin folder, $P"; }
  [ -f "$(sed -n 's/^.*GRADING.md: //p' "$N")/skills/vid-grade/GRADING.md" ] || fail "the folder the $r's note names does not hold GRADING.md"
  ! grep -qF "$L" "$T/fc" || { cp "$T/fc" "$T/out"; fail "the plugin folder line reached the $r's prompt"; }
  sh "$DM" wait "$A" > /dev/null 2>&1 || true; sh "$DM" take "$A" > /dev/null 2>&1 || true; done
[ "$(git -C "$RT" hash-object devagent/agents/grader.md)" = 01f37dead8eded63140b5fe2ac9e765991b2e9e7 ] && [ "$(git -C "$RT" hash-object devagent/agents/second-reviewer.md)" = d31079e4f468d8a2a9afac2858c47201acf6ca27 ] || fail 'a frozen file changed'
echo 'devagent-grader-folder: ok'

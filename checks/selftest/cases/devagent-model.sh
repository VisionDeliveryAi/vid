#!/bin/sh
# Purpose: selftest case — the dev side's model in one place (v0.26.10.28.3 R4). Of devagent/, only dm.sh's default line, MODEL0=, and the two frozen files,
# agents/grader.md and agents/second-reviewer.md, name dm.sh's default model; any other file, or a second line of dm.sh, fails. A job note's model: is what
# start passes as --model and what the agent's first message must show: an agent on it starts and its line in agents.txt names it; one that shows the default
# under it is stopped by its pid. 0.26.10.28.8 (R6): check refuses a model: no first message can show (a short name, no claude- prefix), naming
# MODEL0's form; at the loop's first dev manager on another model, one halt whose words, in dm-report.txt and the stopped report, name both
# models and the line to write, and no second agent. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "devagent-model: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
M=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); [ -n "$M" ] || fail 'dm.sh has no default model line, MODEL0='
# the name: dm.sh's default line, and the two frozen files, alone
(cd "$RT" && grep -rlF -- "$M" devagent | sort) > "$T/names"
printf 'devagent/agents/grader.md\ndevagent/agents/second-reviewer.md\ndevagent/dev-manager/dm.sh\n' > "$T/allowed"
comm -23 "$T/names" "$T/allowed" > "$T/out"; [ ! -s "$T/out" ] || fail "the model's name outside dm.sh's default and the two frozen files"
[ "$(grep -cF -- "$M" "$DM")" = 1 ] || { grep -nF -- "$M" "$DM" > "$T/out"; fail 'dm.sh names the model beyond its default line'; }
# a note's model: passed as --model and checked against the first message
W=$T/work; mkdir -p "$W/c1" "$T/bin"; DM_WORK=$W; export DM_WORK; O=claude-other-model-1
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\nmodel: %s\n' "$W" "$O" > "$W/dm-note.txt"
cat > "$T/bin/claude" <<'C'
#!/bin/sh
printf '%s\n' "$*" >> "$FC_LOG"; echo "$$" >> "$FC_LOG.pids"
printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_MODEL"
[ "${FC_MODE:-}" != hang ] || exec sleep 60
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"done"}\n'
C
chmod +x "$T/bin/claude"; FC_LOG=$T/fc; DM_AGENT_CLAUDE=$T/bin/claude; export FC_LOG DM_AGENT_CLAUDE; : > "$FC_LOG"; printf 'ticket: 3\nthe job\n' > "$W/job"
A=$(FC_MODEL=$O sh "$DM" start builder "$W/job" "$W/c1" 2> "$T/out") || fail "an agent on the note's model did not start"
grep -q -- "--model $O " "$FC_LOG" || { cp "$FC_LOG" "$T/out"; fail "the start did not pass the note's model"; }
sh "$DM" wait "$A" > "$T/out" 2>&1 || fail "wait on an agent on the note's model"; [ "$(cut -f3 "$W/agents.txt")" = "$O" ] || fail "agents.txt: $(cat "$W/agents.txt")"; sh "$DM" take "$A" > /dev/null
RC=0; FC_MODEL=$M FC_MODE=hang sh "$DM" start builder "$W/job" "$W/c1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "showed $M, not $O" "$T/out" || fail "the default model was not refused under the note's model"
p=$(tail -n 1 "$FC_LOG.pids"); ! kill -0 "$p" 2>/dev/null || fail 'the refused agent still runs'
# 0.26.10.28.8 (R6): check refuses a model: no first message can show, naming MODEL0's form, and takes MODEL0 itself; the fake gh first, so check reaches no real GitHub
. "$CHECKS/selftest/fixtures/tickets.sh"; gh_fake
for v in opus opus-5-5 sonnet 'Claude-Opus'; do printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\nmodel: %s\n' "$W" "$v" > "$T/n1"
  sh "$DM" check "$T/n1" > "$T/out" 2>&1 || true; grep -qF "missing: the job note's model:, the exact name a first message shows, as $M (not '$v')" "$T/out" || fail "check took model: $v"; done
sed "s/^model: .*/model: $M/" "$T/n1" > "$T/n2"; sh "$DM" check "$T/n2" > "$T/out" 2>&1 || true; ! grep -q "the job note's model:" "$T/out" || fail "check refused model: $M"
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\nmodel: %s \n' "$W" "$O" > "$W/dm-note.txt"; : > "$FC_LOG"
A=$(FC_MODEL=$O sh "$DM" start builder "$W/job" "$W/c1" 2> "$T/out") || fail "an agent on the note's model, written with a trailing space, did not start"; grep -qF -- "--model $O --settings" "$FC_LOG" || fail 'start passed the model with its trailing space'; sh "$DM" wait "$A" > /dev/null 2>&1 || true; sh "$DM" take "$A" > /dev/null 2>&1 || true
# the loop's first dev manager on a model the note does not name: one halt, its words naming both models and the line to write, no second agent
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
W2=$T/w2; mkdir -p "$W2/tickets"; gh issue create -R owner/code --title t1 --body x --label ticket > /dev/null
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 300\nagent-time-limit: 600\nagent-turn-limit: 40\nmodel: %s\n' "$W2" "$O" > "$W2/note.txt"
cp "$T/bin/claude" "$T/bin/claude.dm"; : > "$FC_LOG.pids"; mkdir -p "$W2/agents/dev-manager-0"; echo claude-stale-0 > "$W2/agents/dev-manager-0/refused"; touch -t 203001010000 "$W2/agents/dev-manager-0/refused"   # a stale refusal, newer than any, never named
( cd "$W2" && DM_WORK=$W2 DM_TICK=1 DM_FIRST=5 FC_MODEL=$M FC_MODE=hang sh "$DM" loop "$W2/note.txt" ) > "$T/out" 2>&1 || true
W3="its first message showed the model $M, not the job note's $O; write the line model: $M in the job note"
grep -qF "$W3" "$W2/dm-report.txt" || { cat "$W2/dm-report.txt" >> "$T/out" 2>/dev/null; fail "the halt does not name both models and the line to write"; }
git -C "$T/code.git" show refs/heads/vid-results/stopped-1:stopped-1/results.txt 2> /dev/null | grep -qF "$W3" || fail 'the stopped report does not carry those words'
! grep -q claude-stale-0 "$W2/dm-report.txt" || fail "the halt names an earlier dev manager's refused model"
[ "$(grep -c 'the loop stopped' "$W2/dm-report.txt")" = 1 ] && [ "$(ls "$W2/agents" | grep -c .)" = 2 ] || fail "not one halt and one agent: $(ls "$W2/agents" | tr '\n' ' ')"
for p in $(cat "$FC_LOG.pids"); do ! kill -0 "$p" 2>/dev/null || fail 'a refused dev manager still runs'; done
exit 0

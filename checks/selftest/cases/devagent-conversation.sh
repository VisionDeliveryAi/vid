#!/bin/sh
# Purpose: selftest case — DevAgent's agents run in its own conversation (0.26.11.1.3, R5): the job note's `agents: conversation`. On the fake gh, a
# claude signed out that records every run, and a docker stub. check reads `ready` with no line about claude, where `agents: command` (or no
# agents: line, as before) names claude's sign-in, and another word is named; up and loop refuse, starting nothing, no pid, no loop file;
# here, on an empty work folder with the note outside it, copies the note to dm-note.txt and prints the DM_WORK line, and next then reads
# the note's keys; here refuses a work folder in ViD's records and a dollar key. start makes the folder and the job note, writes `mode`,
# prints the id, the prompt (the role file and the job note), the model and the hand-back path, and starts nothing; wait before done prints
# `running` alone, list names it alive, take refuses it; done writes done/ and the agent's agents.txt line (role, ticket, the note's model,
# the seconds, `-`); take prints the hand-back file alone; a second done is refused; stop on a folder not done writes done/ with an empty
# hand-back. Reopened after a close with a helper not done, here again writes it up ended with no hand-back: list names it ended, wait says
# `ended: no hand-back`, agents.txt has its line, and a fresh start on its clone is taken. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
TAB=$(printf '\t')
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(cd "$(mktemp -d)" && pwd -P)
# a loop a failure left is stopped by its recorded pid alone
trap 'p=$(sed -n 1p "$T/work/dm-loop.pid" 2>/dev/null || true); [ -z "$p" ] || kill -TERM "$p" 2>/dev/null || true; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-conversation: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W"
# claude signed out; any run but its sign-in's is recorded
cat > "$T/bin/claude" <<C
#!/bin/sh
case "\$1 \${2:-}" in
  'auth --help') printf 'Commands:\n  status [options]  Show authentication status\n'; exit 0 ;;
  'auth status') echo '{"loggedIn": false}'; exit 0 ;;
esac
printf '%s\n' "\$*" >> "$T/claude-runs"; exit 1
C
printf '#!/bin/sh\necho stub\n' > "$T/bin/docker"; chmod +x "$T/bin/claude" "$T/bin/docker"
DM_AGENT_CLAUDE=$T/bin/claude; export DM_AGENT_CLAUDE
NT=$T/note.txt; printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 3600\nagent-time-limit: 600\nagent-turn-limit: 40\nagents: conversation\n' "$W" > "$NT"
ck() { RC=0; sh "$DM" check "$1" > "$T/out" 2>&1 || RC=$?; }
# check: in conversation mode claude is not needed; in command mode, or with no agents: line, its sign-in is
ck "$NT"; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = ready ] || fail "check with agents: conversation and claude signed out ($RC)"
sed 's/^agents: .*/agents: command/' "$NT" > "$T/nc"; ck "$T/nc"; [ "$RC" = 1 ] && grep -qx 'missing: claude signed in (claude auth status)' "$T/out" || fail 'check with agents: command did not name claude signed out'
grep -v '^agents:' "$NT" > "$T/n0"; ck "$T/n0"; [ "$RC" = 1 ] && grep -qx 'missing: claude signed in (claude auth status)' "$T/out" || fail 'check with no agents: line did not name claude signed out'
sed 's/^agents: .*/agents: both/' "$NT" > "$T/nb"; ck "$T/nb"; [ "$RC" = 1 ] && grep -q "^missing: the job note's agents:, conversation or command" "$T/out" || fail 'check took agents: both'
# up and loop refuse, starting nothing
RC=0; sh "$DM" up "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'agents: conversation' "$T/out" && grep -q 'the conversation runs the passes' "$T/out" || fail "up in conversation mode ($RC)"
[ ! -e "$W/dm-loop.pid" ] && [ ! -e "$W/dm-loop.log" ] && [ ! -e "$W/dm-loop.start" ] || fail 'up left a loop file'
RC=0; sh "$DM" loop "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'the conversation runs the passes' "$T/out" || fail "loop in conversation mode ($RC)"
[ ! -e "$W/dm-loop.start" ] && [ ! -e "$W/clones" ] && [ ! -e "$W/dm-note.txt" ] || fail 'loop began in conversation mode'
[ -z "$(ls -A "$W")" ] || fail "up or loop wrote in the work folder: $(ls -A "$W")"
# here: its refusals first, then the work folder set up; next reads the note's keys
mkdir -p "$T/p/.vid" "$T/p/w"; sed "s|^work: .*|work: $T/p/w|" "$NT" > "$T/n2"; RC=0; sh "$DM" here "$T/n2" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "a folder of ViD's records" "$T/out" && [ ! -e "$T/p/w/dm-note.txt" ] || fail 'here took a work folder in ViD records'
cp "$NT" "$T/n3"; echo 'spend-limit: 5' >> "$T/n3"; RC=0; sh "$DM" here "$T/n3" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'spend-limit:, read no longer' "$T/out" && [ ! -e "$W/dm-note.txt" ] || fail 'here took a dollar key'
RC=0; sh "$DM" here "$T/nc" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ ! -e "$W/dm-note.txt" ] || fail 'here set up a note of agents: command'
RC=0; (cd "$T" && sh "$DM" here "$NT") > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "here ($RC)"
cmp -s "$NT" "$W/dm-note.txt" || fail 'here left no copy of the note, dm-note.txt, in the work folder'
L=$(grep '^DM_WORK=' "$T/out" | head -n 1); [ -n "$L" ] || fail 'here printed no DM_WORK line'
[ "$(sh -c "$L; printf %s \"\$DM_WORK\"")" = "$W" ] || fail "here's DM_WORK line does not give the work folder: $L"
RC=0; (cd "$T" && DM_WORK=$W sh "$DM" next) > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = none ] || fail "next after here ($RC)"
DM_WORK=$W; export DM_WORK
# start: the job made, nothing started
mkdir -p "$W/clones/test-author-5-1"; printf 'ticket: 5\nthe job\n' > "$W/job"
s=$(date +%s); RC=0; sh "$DM" start test-author "$W/job" "$W/clones/test-author-5-1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "start in conversation mode ($RC)"
[ $(($(date +%s) - s)) -le 5 ] || fail 'start waited, as for a process'
ID=$(sed -n 1p "$T/out"); A=$W/agents/$ID; [ -d "$A" ] || fail "start's first line names no agent folder: $ID"
[ -f "$A/note" ] && cmp -s "$W/job" "$A/note" && [ "$(cat "$A/mode")" = conversation ] || fail 'start made no job note or no mode file'
[ ! -e "$A/pid" ] && [ ! -s "$T/claude-runs" ] || fail 'start in conversation mode started a process'
grep -q "^prompt: .*$RT/devagent/agents/test-author.md.*$A/note" "$T/out" || fail "start printed no prompt naming the role file and the job note: $(cat "$T/out")"
grep -qx "model: $(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM")" "$T/out" || fail 'start printed no model'
grep -qx "hand-back: $A/handback" "$T/out" || fail 'start printed no hand-back path'
grep -qF "dm.sh done $ID <seconds>" "$T/out" || fail 'start did not say to run done'
# before done: wait says running alone, list names it alive, take refuses
RC=0; sh "$DM" wait "$ID" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 75 ] && [ "$(cat "$T/out")" = running ] || fail "wait before done ($RC)"
sh "$DM" list > "$T/out" 2>&1 || fail 'list'; grep -q "^alive $ID ticket 5 " "$T/out" && ! grep -q "^ended $ID" "$T/out" || fail 'list did not name the agent alive'
RC=0; sh "$DM" take "$ID" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ ! -e "$A/taken" ] || fail 'take before done'
# a second start on the same clone is refused while the first is not done
RC=0; sh "$DM" start test-author "$W/job" "$W/clones/test-author-5-1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'holds a live agent' "$T/out" || fail 'a second start on a clone not done'
# the hand-back written, done: done/, the line in agents.txt; take prints the file alone
printf 'Wrote the tests.\nPushed ticket-5.\n' > "$A/handback"; RC=0; sh "$DM" done "$ID" 42 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && [ -d "$A/done" ] || fail "done ($RC)"
[ "$(cat "$W/agents.txt")" = "$(printf 'TA\t5\t%s\t42\t-' "$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM")")" ] || fail "agents.txt: $(cat "$W/agents.txt")"
RC=0; sh "$DM" done "$ID" 43 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ "$(wc -l < "$W/agents.txt" | tr -d ' ')" = 1 ] || fail 'a second done was taken'
RC=0; sh "$DM" wait "$ID" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && cmp -s "$A/handback" "$T/out" || fail "wait after done ($RC)"
sh "$DM" take "$ID" > "$T/out" 2>&1 || fail 'take after done'; cmp -s "$A/handback" "$T/out" && [ -f "$A/taken" ] || fail "take printed more than the hand-back: $(cat "$T/out")"
RC=0; sh "$DM" done nobody 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'done on no agent'
# stop on one not done: done/, an empty hand-back
mkdir -p "$W/clones/builder-5-1"; sh "$DM" start builder "$W/job" "$W/clones/builder-5-1" > "$T/out" 2>&1 || fail 'a second start'; I2=$(sed -n 1p "$T/out")
echo 'half a message' > "$W/agents/$I2/handback"; sh "$DM" stop "$I2" > "$T/out" 2>&1 || fail 'stop'
[ -d "$W/agents/$I2/done" ] && [ -f "$W/agents/$I2/handback" ] && [ ! -s "$W/agents/$I2/handback" ] && [ -f "$W/agents/$I2/taken" ] || fail 'stop did not write done/ with an empty hand-back'
RC=0; sh "$DM" done "$I2" 5 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'done after stop'
sh "$DM" list > "$T/out" 2>&1 || fail 'list at the end'; [ "$(cat "$T/out")" = "$(printf 'loop: not running\nnone')" ] || fail "list at the end: $(cat "$T/out")"
# the conversation closed while a helper ran, then reopened: here again writes that agent up, ended with no hand-back (lane review)
mkdir -p "$W/clones/c3"; sh "$DM" start test-author "$W/job" "$W/clones/c3" > "$T/out" 2>&1 || fail 'a start before the close'; I3=$(sed -n 1p "$T/out")
echo 'half a message' > "$W/agents/$I3/handback"; RC=0; (cd "$T" && sh "$DM" here "$NT") > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "here, reopened ($RC)"
sh "$DM" list > "$T/out" 2>&1 || fail 'list, reopened'; grep -qx "ended $I3 ticket 5 no hand-back" "$T/out" && ! grep -q "^alive $I3 " "$T/out" || fail "after here again, the helper the close left is not ended with no hand-back: $(cat "$T/out")"
RC=0; sh "$DM" wait "$I3" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && grep -qx 'ended: no hand-back' "$T/out" || fail "wait on the helper the close left ($RC)"
[ "$(grep -c "^TA${TAB}5${TAB}" "$W/agents.txt")" = 2 ] || fail "agents.txt has no line for the helper the close left: $(cat "$W/agents.txt")"
sh "$DM" start test-author "$W/job" "$W/clones/c3" > "$T/out" 2>&1 || fail 'a fresh agent on the clone the close left was refused'
[ ! -s "$T/claude-runs" ] || { cp "$T/claude-runs" "$T/out"; fail 'a model was run'; }
echo 'devagent-conversation: ok'

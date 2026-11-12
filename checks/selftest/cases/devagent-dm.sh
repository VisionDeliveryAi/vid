#!/bin/sh
# Purpose: selftest case — DevAgent's dev manager script (v0.26.10.24.7 R2, R3), on the fake gh and a fake claude of its own, on shortened times. next prints each
# of its lines from the right state, lowest first: a ticket labelled blocked prints blocked and nothing else, left from the record, claim, work, wait while a decide is
# newer than any decision for that head, not-yet, merge, a decision for an old head no answer, a merged ticket nothing, none with no line. loop starts one dev manager,
# never a second while one runs, none for a blocked ticket, and stops on the stop file, on the same line twice, and not behind a lower wait or blocked while a higher ticket
# moves. start: another model stops that agent; a clone with a live agent is refused; quiet comes after the silence; stop stops only that pid; agents.txt gets its line,
# role, ticket, model, seconds, turns, no cost; the turn limit, as --max-turns, and the role's file reach the agent, no dollar flag (v0.26.10.28.3 R3). An agent past the
# note's agent-time-limit is stopped by its pid at wait and at the loop's tick, its line marked time-limit; `used` gives the seconds and turns; a note holding the
# dollar keys is refused by start and loop, naming the new keys; no file of devagent/ names usd, spend-limit, agent-budget, dm.sh spend or --max-budget.
# Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
DM=$CHECKS/../devagent/dev-manager/dm.sh; FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_MODEL0   # dm.sh's default model (R4)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-dm: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W/tickets" "$W/c1" "$W/c2"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/note.txt"; cp "$W/note.txt" "$W/dm-note.txt"
# a fake claude: FC_MODEL its model, FC_MODE hang (a line, then quiet) or else a hand-back; it records its arguments
cat > "$T/bin/claude" <<'C'
#!/bin/sh
printf '%s\n' "$*" >> "$FC_LOG"; echo "$$" >> "$FC_LOG.pids"
printf '{"type":"system","subtype":"init","model":"%s"}\n' "${FC_MODEL:-$FC_MODEL0}"
[ ! -f "$FC_LOG.script" ] || sh "$FC_LOG.script"
[ "${FC_MODE:-}" = hang ] && exec sleep 300
[ "${FC_MODE:-}" != two ] || printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":2000,"num_turns":2,"result":"a first end"}\n'
sleep "${FC_SLEEP:-0}"
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":7000,"num_turns":3,"result":"done\\nthe \\"second\\" line"}\n'
C
chmod +x "$T/bin/claude"; FC_LOG=$T/fc; export FC_LOG; : > "$FC_LOG"
g() { gh "$@" > /dev/null; }
tk() { g issue create -R owner/code --title "t$1" --body x --label ticket; }
tk 1; tk 2; tk 3; tk 4
nx() { sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; }
is() { nx; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
is 'claim 1
claim 2
claim 3
claim 4'
g issue edit 2 -R owner/code --add-label blocked; echo 'left: a stopped agent, twice' > "$W/tickets/3.txt"; g issue comment 1 -R owner/code --body 'vid: claimed'; g issue comment 2 -R owner/code --body 'vid: claimed'; g issue comment 4 -R owner/code --body 'vid: claimed'
is 'work 1
blocked 2
left 3
work 4'
: > "$W/tickets/3.txt"; g issue comment 3 -R owner/code --body 'vid: claimed'
br() { git -C "$T/s" checkout -q -B "$1" "${2:-main}" 2>/dev/null || true; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m "$1"; git -C "$T/s" push -q -f "$T/code.git" "HEAD:refs/heads/$1"; git -C "$T/s" rev-parse HEAD; }
rm -rf "$T/s"; git clone -q "$T/code.git" "$T/s" 2>/dev/null; H1=$(br t-1 origin/main); H3=$(br t-3 origin/main); H4=$(br t-4 origin/main)
for k in 1 3 4; do g pr create -R owner/code --head "t-$k" --base main --title x --body "ticket: #$k"; done; P1=5; P3=6; P4=7
is 'work 1
blocked 2
work 3
work 4'
g pr comment $P1 -R owner/code --body "vid: decide $H1"; printf 'vid: decide %s\nby: MR\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"
printf 'vid: decision %s\nticket: not yet\nROW-1 held — failing, a weak test\nROW-2 question open\nROW-3 not accepted, by a transition above\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"
printf 'vid: decide %s\n' "$H4" > "$T/b"; g pr comment $P4 -R owner/code --body-file "$T/b"; printf 'vid: decision %s\nticket: not yet\nROW-9 failing, a product failure — the grader\n' "$H4" > "$T/b"; g pr comment $P4 -R owner/code --body-file "$T/b"
is 'wait 1
blocked 2
wait 3
not-yet 4'
for w in 'evidence missing — no fault folder'; do g pr comment $P3 -R owner/code --body "vid: decide $H3"; printf 'vid: decision %s\nticket: not yet\nROW-1 %s\n' "$H3" "$w" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"; nx; grep -qx 'not-yet 3' "$T/out" || fail "a line reading $w"; done
printf 'vid: decision %s\nticket: not yet\nROW-1 failing, a weak test\nROW-2 held — it did not shrink — failing\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"; nx; grep -qx 'not-yet 3' "$T/out" || fail 'a held row closed another row route'; printf 'vid: decision %s\nticket: not yet\nROW-2 held — it did not shrink — failing\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"; nx; grep -qx 'wait 3' "$T/out" || fail 'a held row alone called for work'; printf 'vid: decision %s\nticket: not yet\nsort evidence missing — no sort report\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"; nx; grep -qx 'not-yet 3' "$T/out" || fail 'the sort line called for no work'
printf 'vid: decision %s\nticket: accepted\n' "$H3" > "$T/b"; g pr comment $P3 -R owner/code --body-file "$T/b"; nx; grep -qx 'merge 3' "$T/out" || fail 'accepted is no merge line'
H1B=$(cd "$T/s" && git checkout -q t-1 && git -c user.email=a@b -c user.name=a commit -q --allow-empty -m new && git push -q -f origin t-1 && git rev-parse HEAD)
printf 'vid: decision %s\nticket: accepted\n' "$H1" > "$T/b"; g pr comment $P1 -R owner/code --body-file "$T/b"; nx; grep -qx 'work 1' "$T/out" || fail 'a decision for an old head was read as an answer'
g pr ready $P3 -R owner/code; g pr merge $P3 -R owner/code --merge --match-head-commit "$H3" --body 'Role: MR'; nx; grep -q ' 3$' "$T/out" && fail 'a merged ticket printed a line'
g pr edit $P4 -R owner/code --body 'ticket: #4'; g pr ready $P1 -R owner/code; g pr ready $P4 -R owner/code; printf 'vid: decide %s\n' "$H1B" > "$T/b"; g pr comment $P1 -R owner/code --body-file "$T/b"; g pr merge $P1 -R owner/code --merge --body x; g pr merge $P4 -R owner/code --merge --body x; g issue edit 2 -R owner/code --remove-label blocked; echo 'left: x' > "$W/tickets/2.txt"; nx; [ "$(cat "$T/out")" = 'left 2' ] || fail "only the left ticket: $(cat "$T/out")"
g issue close 2 -R owner/code; is none
# v0.26.10.25.3 R8: a close run, an issue labelled run, is work while a chunk of its body has no report, or a vid: again newer than its newest report; a chunk lost since its last again waits; blocked by its label
printf 'close: S01\ncommit: %s\nengines: alpha beta\n\nRun each chunk at the commit.\n\n- chunk p1c1, alpha: ROW-001 ROW-002\n- chunk p1c10, alpha: ROW-003\n- chunk p2c1, beta: ROW-001 ROW-002 ROW-003\n' "$H1" > "$T/b"
RN=$(gh issue create -R owner/code --title 'Close run: S01' --body-file "$T/b" --label run); RN=${RN##*/}; cm() { printf '%s\n' "$1" > "$T/b"; g issue comment "$RN" -R owner/code --body-file "$T/b"; }; is "work $RN"
cm 'vid: started
by: DM'; cm 'vid: reported p1c10-1'; is "work $RN"
for c in p1c1 p2c1; do cm "vid: reported $c-1"; done; is "wait $RN"
cm 'vid: again p1c1'; is "work $RN"
echo 'lost p1c1 1' > "$W/tickets/$RN.txt"; is "work $RN"   # v0.26.10.28.2 (R2): a loss not yet said is work, every chunk else waiting
echo 'said lost p1c1 1' >> "$W/tickets/$RN.txt"; is "wait $RN"   # said once, it waits
cm 'vid: again p1c1'; is "work $RN"
cm 'vid: reported p1c1-2'; is "wait $RN"
g issue edit "$RN" -R owner/code --add-label blocked; cm 'vid: again p2c1'; is "blocked $RN"
g issue close "$RN" -R owner/code; rm -f "$W/tickets/$RN.txt"; is none
# start, wait, take, list, stop, the limit
printf 'ticket: 9\nyour job\n' > "$W/job"; A=$(sh "$DM" start builder "$W/job" "$W/c1"); grep -qF 'devagent/agents/builder.md' "$FC_LOG" && grep -q -- "--model $FC_MODEL0 " "$FC_LOG" && grep -q -- '--max-turns 40 ' "$FC_LOG" && ! grep -q -- '--max-budget' "$FC_LOG" && grep -qF '"vid@vid":false' "$FC_LOG" && grep -qF "$W/agents/$A/note" "$FC_LOG" || fail "the agent's start: $(cat "$FC_LOG")"
sh "$DM" wait "$A" > "$T/out" 2>&1 || fail 'wait on an ended agent'; [ "$(sed -n 2p "$T/out")" = 'the "second" line' ] || fail 'the hand-back'
[ "$(cat "$W/agents.txt")" = "BU	9	$FC_MODEL0	7	3" ] || fail "agents.txt: $(cat "$W/agents.txt")"; sh "$DM" list | grep -q "^ended $A ticket 9 hand-back" || fail 'an untaken hand-back is not listed'; sh "$DM" take "$A" > /dev/null; [ "$(sh "$DM" list | grep -v "^loop: ")" = none ] || fail 'a taken hand-back is listed'
# an agent that ends twice: its seconds and turns add up
: > "$W/agents.txt"; A=$(FC_MODE=two sh "$DM" start builder "$W/job" "$W/c1"); sh "$DM" wait "$A" > /dev/null 2>&1 || fail 'wait on an agent with two ends'; [ "$(cat "$W/agents.txt")" = "BU	9	$FC_MODEL0	9	5" ] || fail "agents.txt, two ends: $(cat "$W/agents.txt")"; sh "$DM" take "$A" > /dev/null
# the agent's commits carry DevAgent's name, by its clone
git init -q "$W/c3"; A=$(sh "$DM" start builder "$W/job" "$W/c3"); sh "$DM" wait "$A" > /dev/null 2>&1; sh "$DM" take "$A" > /dev/null; [ "$(git -C "$W/c3" config user.name)" = 'DevAgent BU' ] || fail 'the clone has no name'
# a report line of row ids holds row ids alone: prose is refused before it reaches a report
RM=$(dirname "$DM")/../test-manager/run.sh; RC=0; sh "$RM" run --line 'retested: ROW-1 — now reads the file whole' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q 'row ids alone' "$T/out" || fail "prose on a retested line: $(cat "$T/out")"; sh "$RM" run --line 'retested: ROW-1 ROW-2-T1' 2>&1 | grep -q 'no dev setup record' || fail 'ids on a retested line were refused'
RC=0; FC_MODEL=claude-other sh "$DM" start builder "$W/job" "$W/c1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'showed claude-other' "$T/out" || fail 'another model was not refused'; p=$(tail -n 1 "$FC_LOG.pids"); kill -0 "$p" 2>/dev/null && fail 'another model is still running'
FC_MODE=hang sh "$DM" start test-author "$W/job" "$W/c1" > "$T/a2"; A2=$(cat "$T/a2"); RC=0; sh "$DM" start builder "$W/job" "$W/c1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'holds a live agent' "$T/out" || fail 'a clone with a live agent was taken'
FC_MODE=hang sh "$DM" start grader "$W/job" "$W/c2" > "$T/a3"; A3=$(cat "$T/a3"); P2=$(cat "$W/agents/$A2/pid"); P3P=$(cat "$W/agents/$A3/pid")
RC=0; DM_WAIT=2 sh "$DM" wait "$A2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 75 ] && grep -qx running "$T/out" || fail 'a live agent is not running'
sleep 3; RC=0; DM_QUIET=2 sh "$DM" wait "$A2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 4 ] && grep -qx quiet "$T/out" || fail 'no quiet after the silence'
sh "$DM" list | grep -q "^alive $A2 ticket 9 clone" || fail 'a live agent is not listed'; sh "$DM" stop "$A2"; grep -q "stopped $A2" "$W/dm-report.txt" || fail 'dm-report.txt does not name a stopped agent'; tail -n 1 "$W/agents.txt" | awk -F'\t' 'NF == 5 && $1 == "TA" && $2 == 9 && $4 ~ /^[0-9]+$/ { f = 1 } END { exit !f }' || fail "a killed agent's line: $(tail -n 1 "$W/agents.txt")"; kill -0 "$P2" 2>/dev/null && fail 'stop left it'; kill -0 "$P3P" 2>/dev/null || fail 'stop reached another agent'
RC=0; sh "$DM" wait "$A2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && grep -qx 'ended: no hand-back' "$T/out" || fail 'a stopped agent has a hand-back'
sh "$DM" stop "$A3"; tail -n 1 "$W/agents.txt" | grep -q '^GR	9	' || fail 'a killed agent with no line'
# used: no loop yet, the ended agents' seconds and turns (R3)
S=$(awk -F'\t' '{ s += $4; u += $5 } END { printf "%d s, %d turns; %d ended", s, u, NR }' "$W/agents.txt"); [ "$(sh "$DM" used)" = "loop: - s of 600 s
agents: $S, 0 running" ] || fail "used: $(sh "$DM" used)"
# the dollar keys refused, the new keys named, by start and by loop; a start with no turn limit refused
cp "$W/dm-note.txt" "$T/dn"; printf 'spend-limit: 5\n' >> "$W/dm-note.txt"; RC=0; sh "$DM" start builder "$W/job" "$W/c1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'spend-limit:, read no longer' "$T/out" && grep -q 'agent-turn-limit:' "$T/out" || fail 'a start under a dollar key'
printf 'agent-budget: 3\n' >> "$T/n4"; cat "$W/note.txt" >> "$T/n4"; RC=0; sh "$DM" loop "$T/n4" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'agent-budget:, read no longer' "$T/out" && [ ! -f "$W/dm-loop.start" ] || fail 'a loop under a dollar key'
grep -v '^agent-turn-limit:' "$T/dn" > "$W/dm-note.txt"; RC=0; sh "$DM" start builder "$W/job" "$W/c1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'no agent-turn-limit:' "$T/out" || fail 'a start with no turn limit'
# an agent past its time limit, stopped by its pid at wait, its line marked
sed 's/^agent-time-limit: .*/agent-time-limit: 2/' "$T/dn" > "$W/dm-note.txt"; rm -f "$W/agents.txt"; A=$(FC_MODE=hang sh "$DM" start test-author "$W/job" "$W/c1"); PT=$(cat "$W/agents/$A/pid")
RC=0; DM_WAIT=20 sh "$DM" wait "$A" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && grep -qx 'ended: no hand-back' "$T/out" && grep -qx 'stopped at its time limit, 2 s' "$T/out" || fail "wait past the time limit: $RC"
kill -0 "$PT" 2>/dev/null && fail 'the agent past its time limit still runs'; tail -n 1 "$W/agents.txt" | grep -q '^TA	9	.*	time-limit$' || fail "the line of an agent past its time limit: $(cat "$W/agents.txt")"; cp "$T/dn" "$W/dm-note.txt"; rm -f "$W/agents.txt"; rm -rf "$W/agents"
# an agent outlives the dev manager that started it: a signal to that one's process group does not reach it
set -m; sh -c 'A=$(FC_MODE=hang sh "$1" start builder "$2" "$3"); echo "$A" > "$4"; exec sleep 30' sh "$DM" "$W/job" "$W/c1" "$T/a9" & G=$!; set +m; n=0; while [ ! -s "$T/a9" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; A=$(cat "$T/a9"); P9=$(cat "$W/agents/$A/pid"); kill -TERM -- "-$G"; sleep 1; kill -0 "$P9" 2>/dev/null || fail 'the agent went with its dev manager'; sh "$DM" stop "$A"; sh "$DM" take "$A" > /dev/null 2>&1 || true
rm -f "$W/agents.txt"; rm -rf "$W/agents"
# the loop: one dev manager at a time; none for a blocked ticket; the stop file; the same line twice; a higher ticket behind a lower wait
DM_TICK=1; DM_IDLE=4; DM_FIRST=5; export DM_TICK DM_IDLE DM_FIRST; rm -f "$T/gh/next"; rm -rf "$T/gh/issues" "$T/gh/prs" "$W/tickets" "$W/clones" "$W/dm-report.txt"; mkdir -p "$W/tickets"; : > "$FC_LOG"; tk 1; g issue edit 1 -R owner/code --add-label blocked
DM_IDLE_TICK=2; export DM_IDLE_TICK   # v0.26.10.28.6 (R3): an idle loop stays, so this one ends at its time limit, never for idleness
sed 's/^time-limit: .*/time-limit: 8/' "$W/note.txt" > "$W/n6"; sh "$DM" loop "$W/n6"; [ ! -s "$FC_LOG" ] || fail 'an agent for a blocked ticket'; grep -q 'the loop stopped: the time limit: 8s' "$W/dm-report.txt" && ! grep -q 'nothing to do or to wait for' "$W/dm-report.txt" || fail "the blocked loop's stop: $(cat "$W/dm-report.txt")"
g issue edit 1 -R owner/code --remove-label blocked; rm -f "$W/dm-report.txt"; rm -rf "$W/agents"; FC_SLEEP=3 sh "$DM" loop "$W/note.txt"; [ "$(grep -c 'devagent/agents/dev-manager.md' "$FC_LOG")" = 2 ] || fail "not two passes, one at a time: $(cat "$FC_LOG")"; grep -q 'twice with the line it began with: claim 1' "$W/dm-report.txt" || fail "the same line: $(cat "$W/dm-report.txt")"
[ "$(awk -F'\t' '$1 == "DM"' "$W/agents.txt" | wc -l | tr -d ' ')" = 2 ] || fail 'the dev manager has no line in agents.txt'; rm -f "$W/agents.txt" "$W/dm-report.txt"; rm -rf "$W/agents"; : > "$FC_LOG"
FC_MODE=hang; export FC_MODE; sh "$DM" loop "$W/note.txt" & LP=$!; n=0; while [ ! -s "$FC_LOG" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; sleep 3; echo 'row ROW-7 unanswered' > "$W/dm-stop"; wait "$LP"; grep -q 'the stop file: row ROW-7' "$W/dm-report.txt" || fail 'no stop on the stop file'
unset FC_MODE; [ "$(wc -l < "$FC_LOG" | tr -d ' ')" = 1 ] || fail 'a second dev manager while one ran'; for p in $(cat "$FC_LOG.pids"); do kill -0 "$p" 2>/dev/null && fail 'the stop left a dev manager running'; done; rm -f "$W/dm-stop" "$W/dm-report.txt"; rm -rf "$W/agents"; : > "$FC_LOG"
# a dev manager gone quiet is stopped by the loop itself, and its pass counts as ended
cp "$W/note.txt" "$W/n2"; DM_QUIET=2 FC_MODE=hang sh "$DM" loop "$W/n2"; grep -q 'twice with the line it began with' "$W/dm-report.txt" || fail "a quiet dev manager: $(cat "$W/dm-report.txt")"; for p in $(cat "$FC_LOG.pids"); do kill -0 "$p" 2>/dev/null && fail 'a quiet dev manager left running'; done; rm -f "$W/dm-report.txt" "$W/agents.txt"; rm -rf "$W/agents"; : > "$FC_LOG"
# a dev manager past its time limit is stopped at the loop's tick, its line marked; `used` gives the loop's seconds, to its halt
sed 's/^agent-time-limit: .*/agent-time-limit: 2/' "$W/note.txt" > "$W/n5"; FC_MODE=hang sh "$DM" loop "$W/n5"; grep -q 'twice with the line it began with' "$W/dm-report.txt" || fail "a dev manager past its time limit: $(cat "$W/dm-report.txt")"
for p in $(cat "$FC_LOG.pids"); do kill -0 "$p" 2>/dev/null && fail 'a dev manager past its time limit left running'; done; [ "$(grep -c '^DM	-	.*	time-limit$' "$W/agents.txt")" = 2 ] || fail "the loop's time limit lines: $(cat "$W/agents.txt")"
[ "$(sed -n 1p "$W/dm-loop.start")" -le "$(sed -n 2p "$W/dm-loop.start")" ] && sh "$DM" used | grep -q '^loop: [0-9][0-9]* s of 600 s$' || fail "used after a loop: $(sh "$DM" used)"; cp "$W/note.txt" "$W/dm-note.txt"; rm -f "$W/dm-report.txt" "$W/agents.txt"; rm -rf "$W/agents"; : > "$FC_LOG"
# a lower wait and a higher ticket that moves: the script moves it by a claim, so the first calling line changes and the loop goes on
g issue comment 1 -R owner/code --body 'vid: claimed'; (cd "$T/s" && git checkout -q -B t-1 origin/main && git -c user.email=a@b -c user.name=a commit -q --allow-empty -m a && git push -q -f origin t-1); H=$(git -C "$T/s" rev-parse HEAD); g pr create -R owner/code --head t-1 --base main --title x --body 'ticket: #1'; g pr comment 2 -R owner/code --body "vid: decide $H"; tk 3; tk 4
cat > "$FC_LOG.script" <<'S'
n=$(wc -l < "$FC_LOG" | tr -d ' '); gh issue comment $((n + 2)) -R owner/code --body 'vid: claimed' > /dev/null; [ "$n" != 2 ] || echo 'done' > "$DM_WORK/dm-stop"
S
sh "$DM" loop "$W/note.txt"; grep -q 'the stop file' "$W/dm-report.txt" || fail "it stopped behind a lower wait: $(cat "$W/dm-report.txt")"; [ "$(wc -l < "$FC_LOG" | tr -d ' ')" = 2 ] || fail 'not one pass for each moved ticket'
# the same line, with the records moved: no stop, however often it comes back
rm -f "$W/dm-stop" "$W/dm-report.txt" "$W/agents.txt"; rm -rf "$W/agents"; : > "$FC_LOG"; cat > "$FC_LOG.script" <<'S'
n=$(wc -l < "$FC_LOG" | tr -d ' '); echo "step $n" >> "$DM_WORK/tickets/3.txt"; [ "$n" != 3 ] || echo 'done' > "$DM_WORK/dm-stop"
S
sh "$DM" loop "$W/note.txt"; grep -q 'the stop file' "$W/dm-report.txt" && [ "$(wc -l < "$FC_LOG" | tr -d ' ')" = 3 ] || fail "it stopped on a line that moved: $(cat "$W/dm-report.txt")"
# v0.26.10.25.1 R9: a pass's end saves the work folder less what is rebuilt on vid-dev/notes, and the loop puts it back in an empty folder
git -C "$T/code.git" rev-parse -q --verify refs/heads/vid-dev/notes > /dev/null || fail 'no notes branch'; ! git -C "$T/code.git" ls-tree -r --name-only refs/heads/vid-dev/notes | grep -qE '^(agents|clones|runs|blind)/' || fail 'the notes hold what is rebuilt'; git -C "$T/code.git" ls-tree -r --name-only refs/heads/vid-dev/notes | grep -qx agents.txt || fail 'the notes lost the record'
cp "$W/note.txt" "$T/nt"; rm -rf "$W"; mkdir -p "$W"; cp "$T/nt" "$W/note.txt"; echo x > "$W/dm-stop"; sh "$DM" loop "$W/note.txt"; [ -f "$W/agents.txt" ] && grep -q 'came back from vid-dev/notes' "$W/dm-report.txt" || fail 'the notes did not come back'; rm -f "$W/dm-stop"
n0=$(git -C "$T/code.git" rev-list --count refs/heads/vid-dev/notes); rm -f "$FC_LOG.script"; cp "$W/note.txt" "$W/n3"; DM_TICK=1 sh "$DM" loop "$W/n3"; [ "$(git -C "$T/code.git" rev-list --count refs/heads/vid-dev/notes)" -gt "$n0" ] || fail 'the notes did not go on from their history'
# saved while a pass runs, and at a halt: a pass that is killed loses a tick at most
rm -f "$W/dm-stop"; cat > "$FC_LOG.script" <<S
echo mid > "\$DM_WORK/tickets/mid.txt"; n=0; until git -C "$T/code.git" ls-tree -r --name-only refs/heads/vid-dev/notes | grep -q tickets/mid.txt || [ "\$n" -ge 15 ]; do n=\$((n + 1)); sleep 1; done; echo "seen \$n" > "\$DM_WORK/mid-seen"; echo stop > "\$DM_WORK/dm-stop"
S
DM_TICK=1 sh "$DM" loop "$W/n3"; [ -f "$W/mid-seen" ] && ! grep -q 'seen 15' "$W/mid-seen" || fail 'the notes were not saved while the pass ran'; git -C "$T/code.git" show refs/heads/vid-dev/notes:mid-seen 2>/dev/null | grep -q seen || fail 'the notes were not saved at the halt'; rm -f "$W/dm-stop" "$FC_LOG.script" "$W/mid-seen"
# R3: 3 calls a tick at 5 open and 50 merged
for i in 1 2 3 4 5; do d=$T/gh/prs/$((900 + i)); mkdir -p "$d/comments"; echo OPEN > "$d/state"; echo false > "$d/draft"; printf 'ticket-x' > "$d/head"; printf 'ticket: #%s\n' "$i" > "$d/body"; done
i=0; while [ "$i" -lt 50 ]; do i=$((i + 1)); d=$T/gh/prs/$((1000 + i)); mkdir -p "$d/comments"; echo MERGED > "$d/state"; echo false > "$d/draft"; printf 'ticket-y' > "$d/head"; printf 'ticket: #%s\n' "$((5000 + i))" > "$d/body"; done
: > "$T/gh/log"; nx; [ "$(wc -l < "$T/gh/log" | tr -d ' ')" -le 3 ] || { cat "$T/gh/log" > "$T/out"; fail 'next is more than 3 calls a tick'; }
# v0.26.10.28.3 R3: no file of the dev side names its dollar interface
H=$(grep -rn -i -e 'usd' -e 'spend-limit' -e 'agent-budget' -e 'dm.sh spend' -e '--max-budget' "$CHECKS/../devagent" || true); [ -z "$H" ] || { echo "$H" > "$T/out"; fail 'the dev side names its dollar interface'; }
exit 0

#!/bin/sh
# Purpose: selftest case — the dev side in a conversation of its own (0.26.10.28.8, R12), devagent/dev-manager/dm.sh on the fake
# gh and a fake claude, on short times, and skills/vid-devagent/SKILL.md's text. The skill runs only dm.sh's subcommands (check, up, follow,
# list, down; 0.26.11.1.3 R5: here, next, start, done, take for agents: conversation), and, in its agents: command part alone, starts the loop
# through up and follows a loop already running; its agents: conversation part reads the dev manager file at each pass and runs no loop; it
# asks the mode only when the note has none, and says what closing the conversation does in each way; dm.sh starts a dev manager in one place, cmd_loop. With a loop
# started by up, `follow` with no mark prints the mark and returns; `follow <mark>` returns within a tick of a pass ending, naming its ticket,
# the hand-back's first three lines (not its fourth) and the report branch it pushed; with nothing new it returns at its bound, under 10
# minutes by default; a signal to it leaves the loop alive; a planted stop file shows at once with its words; with the loop gone it says so;
# it leaves the work folder byte-identical; a second up while the loop runs is refused. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$(cd "$CHECKS/.." && pwd -P); DM=$R/devagent/dev-manager/dm.sh; S=$R/skills/vid-devagent/SKILL.md
FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_MODEL0
T=$(cd "$(mktemp -d)" && pwd -P); FP=''
# the loop up started, and a following call, are stopped by their recorded pids alone
trap '[ -z "$FP" ] || kill "$FP" 2>/dev/null || true; p=$(sed -n 1p "$T/work/dm-loop.pid" 2>/dev/null || true); [ -z "$p" ] || kill -TERM "$p" 2>/dev/null || true; sleep 1; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-verb: $*" >&2; cat "$T/out" >&2 2>/dev/null; tail -n 3 "$W/dm-report.txt" >&2 2>/dev/null; exit 1; }
# the skill's text
[ -f "$S" ] || fail 'no skills/vid-devagent/SKILL.md: no verb starts the dev side in a conversation'
x=$(grep -oE '[A-Za-z0-9_.-]+\.sh' "$S" | sort -u | grep -vx 'dm.sh' || true); [ -z "$x" ] || fail "the skill names a script but dm.sh: $x"
# 0.26.11.1.3 (R5): conversation mode's own commands too (here, next, start, done, take); the loop's start and follow in the agents: command part alone
x=$(grep -oE 'dm\.sh"? [a-z]+' "$S" | awk '{ print $2 }' | sort -u | grep -vxE 'check|up|follow|list|down|here|next|start|done|take' || true); [ -z "$x" ] || fail "the skill runs a subcommand of dm.sh it may not: $x"
CM=$(awk '/^## With `agents: command`/ { f = 1; next } /^## With `agents: conversation`/ { f = 0 } f' "$S"); CV=$(awk '/^## With `agents: conversation`/ { f = 1; next } /^## / { f = 0 } f' "$S")
[ -n "$CM" ] && [ -n "$CV" ] || fail 'the skill has no part for agents: command and one for agents: conversation'
printf '%s\n' "$CM" | grep -q 'dm\.sh"* up ' && printf '%s\n' "$CM" | grep -q 'dm\.sh"* follow' || fail 'the skill does not start the loop through up and follow it, with agents: command'
printf '%s\n' "$CM" | grep -q 'loop: alive' || fail 'the skill does not follow a loop already running, with agents: command'
! printf '%s\n' "$CV" | grep -qE 'dm\.sh"? (up|follow)' || fail 'the skill starts or follows a loop with agents: conversation'
for c in here next start done take; do printf '%s\n' "$CV" | grep -qE "dm\\.sh\"? $c" || fail "the skill's agents: conversation part does not run dm.sh $c"; done
printf '%s\n' "$CV" | grep -q 'devagent/agents/dev-manager\.md' && printf '%s\n' "$CV" | grep -q 'in the foreground' || fail 'with agents: conversation the skill does not read the dev manager file at each pass, or run its helpers in the foreground'
# the one question: asked when the note has no agents: line, never when it has one; the recommendation by claude's sign-in
Q=$(grep -n '\*\*The mode\.\*\*' "$S" | head -n 1 | cut -d: -f1); [ -n "$Q" ] || fail 'the skill has no step for the mode'
q=$(sed -n "${Q}p" "$S"); for w in 'has `agents: conversation` or `agents: command`: ask nothing' 'has neither' 'ask once' '`claude auth status`' 'recommend `conversation`'; do printf '%s\n' "$q" | grep -qF "$w" || fail "the mode step does not say: $w"; done
# what closing the conversation does, said for each way
grep -qF 'With `agents: command`, closing this conversation' "$S" && grep -qF 'With `agents: conversation`, this conversation is DevAgent: closing it stops DevAgent until the conversation is opened again' "$S" || fail 'the skill does not say what closing the conversation does in each way'
[ "$(grep -c 'cmd_start dev-manager' "$DM")" = 1 ] && sed -n '/^cmd_loop() {/,/^# check/p' "$DM" | grep -q 'cmd_start dev-manager' || fail 'dm.sh starts a dev manager outside cmd_loop'
# the default bound: under the 10 minutes a conversation's call may take
b=$(sed -n 's/.*DM_FOLLOW:-\([0-9][0-9]*\).*/\1/p' "$DM" | head -n 1); [ -n "$b" ] && [ "$b" -lt 600 ] || fail "follow's default bound is not under 600 s: ${b:-none}"
# the repository, the fakes, the note; the loop started by up
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"
cat > "$T/bin/claude" <<'C'
#!/bin/sh
case "$1 ${2:-}" in 'auth --help') printf 'Commands:\n  status [options]  Show authentication status\n'; exit 0 ;; 'auth status') echo '{"loggedIn": true}'; exit 0 ;; esac
printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_MODEL0"
if [ ! -f "$DM_WORK/tickets/1.txt" ]; then gh issue comment 1 -R owner/code --body 'vid: claimed' > /dev/null; echo 'claimed' > "$DM_WORK/tickets/1.txt"
  # the role file read whole, its report forms in the log; the pass's own section of dm-report.txt, as the role file has each pass write
  printf '{"type":"user","message":{"content":[{"type":"tool_result","content":"4. Pushed: a comment, <k> from pushed vid-results/req-<n>-<chunk>-<k>, and pushed vid-results/grade-<n>-<k>"}]}}\n'
  printf '2026-11-12T10:00:00Z the pass\nticket #1: claimed\nnext: work 1\nused: 1 s\nfree memory: fine\nlist: none\n' >> "$DM_WORK/dm-report.txt"
  r='Claimed ticket #1.\nStarted its test author.\nThe third line.\nThe fourth line, never shown.'
elif ! grep -q closed "$DM_WORK/tickets/1.txt"; then gh issue close 1 -R owner/code > /dev/null; echo 'closed' >> "$DM_WORK/tickets/1.txt"; r='Ran the close of #1: pushed vid-results/req-1-p1c1-1\nClosed it.'
else exec sleep 30; fi   # a third pass, cut off by the halt
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"%s"}\n' "$r"
C
printf '#!/bin/sh\necho stub\n' > "$T/bin/docker"; chmod +x "$T/bin/claude" "$T/bin/docker"
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 300\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$T/note.txt"
DM_TICK=1; DM_IDLE=600; DM_FIRST=5; DM_FOLLOW_TICK=1; export DM_TICK DM_IDLE DM_FIRST DM_FOLLOW_TICK
sh "$DM" up "$T/note.txt" > "$T/out" 2>&1 || fail 'up refused'
fo() { ( cd "$W" && sh "$DM" follow "$@" ); }
mk() { sed -n 's/^mark: //p' "$T/out" | tail -n 1; }
# no mark: the mark, at once
RC=0; fo > "$T/out" 2>&1 || RC=$?; M=$(mk); [ "$RC" = 0 ] && [ -n "$M" ] || fail "follow with no mark ($RC)"
# a pass ends: the call returns within a tick, with its ticket, three hand-back lines and no fourth
fo "$M" > "$T/out" 2>&1 & FP=$!; sleep 1; gh issue create -R owner/code --title t1 --body x --label ticket > /dev/null
n=0; while kill -0 "$FP" 2>/dev/null && [ "$n" -lt 30 ]; do sleep 1; n=$((n + 1)); done; ! kill -0 "$FP" 2>/dev/null || fail 'follow did not return once a pass ended'; FP=''
grep -q '^pass dev-manager-[0-9]* ended: ticket #1$' "$T/out" || fail "no pass line naming ticket #1: $(head -n 2 "$T/out")"
grep -qx '  Claimed ticket #1.' "$T/out" && grep -qx '  The third line.' "$T/out" && ! grep -q 'fourth line' "$T/out" || fail 'the hand-back is not its first three lines'
M=$(mk); [ -n "$M" ] || fail 'no mark after a pass'; cp "$T/out" "$T/all"
# the next pass (it may have ended in the same tick, and be in the first call's lines): the report it pushed
grep -q '^  pushed: vid-results/req-1-p1c1-1$' "$T/all" || { DM_FOLLOW=30 fo "$M" > "$T/out" 2>&1 || true; cat "$T/out" >> "$T/all"; M=$(mk); }
grep -q '^  pushed: vid-results/req-1-p1c1-1$' "$T/all" || fail "the report pushed is not named: $(cat "$T/all")"
[ "$(grep -c '^pass dev-manager-' "$T/all")" = 2 ] || fail "not two passes, each once: $(grep '^pass' "$T/all")"
# the role file's report forms are no report pushed; a pass's own section of dm-report.txt is no stop
[ "$(grep -c '^  pushed: nothing$' "$T/all")" = 1 ] && ! grep -qE 'vid-results/(req|grade)-[^0-9]' "$T/all" || fail "the role file's forms read as reports pushed: $(grep pushed "$T/all")"
! grep -q '^stop:' "$T/all" || fail "a pass's report section shown as a stop: $(grep '^stop:' "$T/all" | head -n 2)"
# nothing new: it returns at its bound
s=$(date +%s); DM_FOLLOW=3 fo "$M" > "$T/out" 2>&1 || true; e=$(( $(date +%s) - s )); [ "$e" -ge 2 ] && [ "$e" -le 8 ] && grep -q '^nothing new' "$T/out" || fail "with nothing new it returned after ${e}s: $(cat "$T/out")"
# a signal to the call leaves the loop alive
LP=$(sed -n 1p "$W/dm-loop.pid"); fo "$M" > "$T/out" 2>&1 & FP=$!; sleep 2; kill -TERM "$FP" 2>/dev/null || true; wait "$FP" 2>/dev/null || true; FP=''; sleep 2
kill -0 "$LP" 2>/dev/null || fail 'a signal to the following call ended the loop'
# a second up while the loop runs: refused, still one loop
! sh "$DM" up "$T/note.txt" > "$T/out" 2>&1 && grep -q 'a loop runs already' "$T/out" || fail 'a second up was not refused'
# a stop file planted while a third pass runs: the halt shows at once, with its words
gh issue create -R owner/code --title t2 --body x --label ticket > /dev/null; n=0; while [ ! -d "$W/agents/dev-manager-3" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; [ -d "$W/agents/dev-manager-3" ] || fail 'no third pass started'
fo "$M" > "$T/out" 2>&1 & FP=$!; sleep 1; echo 'enough for today' > "$W/dm-stop"
n=0; while kill -0 "$FP" 2>/dev/null && [ "$n" -lt 30 ]; do sleep 1; n=$((n + 1)); done; ! kill -0 "$FP" 2>/dev/null || fail 'follow did not return at the halt'; FP=''
grep -q '^stop: .*the loop stopped: the stop file: enough for today$' "$T/out" || fail "the halt's words are not shown: $(cat "$T/out")"
n=0; while kill -0 "$LP" 2>/dev/null && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; ! kill -0 "$LP" 2>/dev/null || fail 'the loop did not stop'
# the loop gone: said; the work folder byte-identical before and after the call
snap() { find "$W" -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; }
snap > "$T/s0"; RC=0; fo "$M" > "$T/out" 2>&1 || RC=$?; snap > "$T/s1"
grep -qx 'loop: not running' "$T/out" || fail "the loop gone is not said: $(cat "$T/out")"; cmp -s "$T/s0" "$T/s1" || fail "follow wrote in the work folder: $(diff "$T/s0" "$T/s1" | head -n 3)"
# the pass the halt cut off is shown, once the loop is gone
grep -q '^pass dev-manager-3 cut off by the stop: ' "$T/out" || fail "the pass the halt cut off is not shown: $(grep '^pass' "$T/out")"
# an error the loop recovered from, its log's last line, is no reason given beside the loop's real stop
echo 'dm.sh: the repository could not be read' >> "$W/dm-loop.log"; fo "$M" > "$T/out" 2>&1 || true
grep -q '^stop: .*the stop file: enough for today$' "$T/out" && ! grep -q 'last words of its log' "$T/out" || fail "a stale log line beside the real stop: $(cat "$T/out")"
# the mark taken before up (the skill's order) shows a stop written at the loop's very start
grep -n 'follow`, in the work folder, before anything is started' "$S" > /dev/null || fail 'the skill does not take its mark before up'
fo > "$T/out" 2>&1; M0=$(mk); sed 's/^time-limit: .*/time-limit: 0/' "$T/note.txt" > "$T/note0.txt"; sh "$DM" up "$T/note0.txt" > /dev/null 2>&1 || fail 'up refused the second time'
DM_FOLLOW=30 fo "$M0" > "$T/out" 2>&1 || true; grep -q '^stop: .*the loop stopped: the time limit: 0s$' "$T/out" || fail "a stop at the loop's start is missed: $(cat "$T/out")"
! grep -q '^pass dev-manager-3 ' "$T/out" || fail "the earlier loop's cut-off pass is shown again under the new loop's stop"
# a planted work folder, no loop: six passes ended; a call shows five and holds the rest, saying so and not yet that the loop is gone;
# the next shows the sixth, then that the loop is gone. A hand-back's ticket, not its pull request's number
W2=$T/w2; for k in 1 2 3 4 5 6; do a=$W2/agents/dev-manager-$k; mkdir -p "$a"; : > "$a/start"; echo "pass $k" > "$a/handback"; : > "$a/log"; done
echo 'Ticket #7 is waiting on PR #42.' > "$W2/agents/dev-manager-1/handback"; sleep 1; for k in 1 2 3 4 5 6; do : > "$W2/agents/dev-manager-$k/taken"; done
( cd "$W2" && sh "$DM" follow 0:0:2000-01-01T00:00:00Z ) > "$T/out" 2>&1 || true
[ "$(grep -c '^pass dev-manager-' "$T/out")" = 5 ] && grep -qx 'and more passes: the next call shows them' "$T/out" && ! grep -q '^loop: not running' "$T/out" || fail "the cap at five: $(cat "$T/out")"
grep -qx 'pass dev-manager-1 ended: ticket #7' "$T/out" || fail "a hand-back's ticket: $(grep '^pass dev-manager-1 ' "$T/out")"
M2=$(mk); ( cd "$W2" && sh "$DM" follow "$M2" ) > "$T/out" 2>&1 || true
grep -q '^pass dev-manager-6 ended: ' "$T/out" && [ "$(grep -c '^pass ' "$T/out")" = 1 ] && grep -qx 'loop: not running' "$T/out" || fail "the pass held back: $(cat "$T/out")"
# a pass that ended on its own, written up by the halt before the loop took it, is ended, not cut off
a=$W2/agents/dev-manager-7; mkdir -p "$a"; : > "$a/start"; echo 'Finished #9.' > "$a/handback"; : > "$a/log"; sleep 1; mkdir "$a/done"
M2=$(mk); ( cd "$W2" && sh "$DM" follow "$M2" ) > "$T/out" 2>&1 || true; grep -q '^pass dev-manager-7 ended: ' "$T/out" || fail "a pass that ended on its own is shown cut off: $(grep '^pass' "$T/out")"
# a fresh folder's loop brings back the saved report after the mark: its old stop is not this loop's
( cd "$W2" && sh "$DM" follow ) > "$T/out" 2>&1; M2=$(mk); printf '2026-11-01T09:00:00Z the loop stopped: the time limit: 3600s\n' > "$W2/dm-report.txt"
( cd "$W2" && sh "$DM" follow "$M2" ) > "$T/out" 2>&1 || true; ! grep -q '^stop: ' "$T/out" || fail "an earlier loop's stop shown as this one's: $(grep '^stop' "$T/out")"
# a loop that ended on dm.sh's own refusal writes no stop: its log's last line is shown
echo 'dm.sh: the repository could not be cloned' > "$W2/dm-loop.log"; ( cd "$W2" && sh "$DM" follow "$M2" ) > "$T/out" 2>&1 || true
grep -qx '  last words of its log: dm.sh: the repository could not be cloned' "$T/out" || fail "the loop's own last words are not shown: $(cat "$T/out")"
echo 'devagent-verb: ok'

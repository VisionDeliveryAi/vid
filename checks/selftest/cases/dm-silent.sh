#!/bin/sh
# Purpose: selftest case — the dev side says when ViD is silent (FB-7 B4), devagent/dev-manager/dm.sh on the fake gh. `next` adds, after its
# other lines, `vid-silent <n> <minutes>` for a ticket whose `vid: decide` at its pull request's head has had no decision for over 30 minutes,
# by that ask's own comment's time: not at 29; by the first ask since the newest decision, so asking again does not start the time over; not
# for one answered, for an ask at an older head, a blocked ticket or a run issue; the other lines stay as they are. With agents: command the
# loop writes `ViD has not answered #<n> for <m> minutes: …` to dm-report.txt once while it stands, a pass running or not, once again for a
# later ask, and `follow` shows it beside the stops, as no stop of the loop's. With agents: conversation the skill and the dev manager file
# say it, once. Skips where devagent/ or skills/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] && [ -d "$CHECKS/../skills" ] || { echo 'needs devagent/ and skills/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh; FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_MODEL0
T=$(cd "$(mktemp -d)" && pwd -P); LP=''; trap '[ -z "$LP" ] || kill "$LP" 2>/dev/null || true; rm -rf "$T"' EXIT
HOME=$T/home; mkdir -p "$HOME"; export HOME
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "dm-silent: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$T/work/dm-report.txt" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; git -C "$T/s" remote add origin "$T/code.git"; git -C "$T/s" fetch -q origin; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
cat > "$T/bin/claude" <<'C'
#!/bin/sh
printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_MODEL0"; [ -z "${FC_SLEEP:-}" ] || sleep "$FC_SLEEP"
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"done"}\n'
C
chmod +x "$T/bin/claude"
note() { printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: %s\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" "$1" > "$W/dm-note.txt"; }
note 600
g() { gh "$@" > /dev/null; }
ago() { _e=$(($(date +%s) - $1 * 60 - 5)); date -u -r "$_e" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$_e" '+%Y-%m-%dT%H:%M:%SZ'; }
# ask <pull request> <body> <minutes ago>: a comment, made that long ago
ask() { printf '%s\n' "$2" > "$T/b"; g pr comment "$1" -R owner/code --body-file "$T/b"; _k=$(ls "$T/gh/prs/$1/comments" | wc -l | tr -d ' '); mkdir -p "$T/gh/prs/$1/cat"; ago "$3" > "$T/gh/prs/$1/cat/$_k"; }
nx() { sh "$DM" next > "$T/out" 2>&1 || fail 'next'; }
is() { nx; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
# pr <ticket>: claimed, its branch pushed, its pull request; PRN its number, H its head
pr() { g issue create -R owner/code --title "t$1" --body x --label ticket; printf 'vid: claimed\nby: DM\n' > "$T/b"; g issue comment "$1" -R owner/code --body-file "$T/b"; ( cd "$T/s" && git checkout -q -B "t-$1" origin/main && git -c user.email=a@b -c user.name=a commit -q --allow-empty -m "t$1" && git push -q -f origin "t-$1" ); }
for n in 1 2 3; do pr "$n"; done
for n in 1 2 3; do g pr create -R owner/code --head "t-$n" --base main --title x --body "ticket: #$n"; done; P1=4; P2=5; P3=6
h() { git -C "$T/s" rev-parse "t-$1"; }
# 29 minutes: nothing; 41: the line, after the others, in their order
ask "$P1" "vid: decide $(h 1)" 29; ask "$P2" "vid: decide $(h 2)" 41
is 'wait 1
wait 2
work 3
vid-silent 2 41'
# asked again since: the time is the first ask's
ask "$P2" "vid: decide $(h 2)" 2; is 'wait 1
wait 2
work 3
vid-silent 2 41'
# answered, and asked again 5 minutes ago: the earlier ask had its answer
ask "$P2" "vid: decision $(h 2)
ticket: not yet
ROW-001 held, a limit" 10; ask "$P2" "vid: decide $(h 2)" 5; is 'wait 1
wait 2
work 3'
# an ask at an older head is another's: that head is work, and nothing is silent
ask "$P3" "vid: decide 1111111111111111111111111111111111111111" 90; is 'wait 1
wait 2
work 3'
# a blocked ticket waits on the owner; a run issue's time is not an ask for a decision
g issue edit 2 -R owner/code --add-label blocked; ask "$P2" "vid: decide $(h 2)" 100; g issue create -R owner/code --title run --body '- chunk c1, all' --label run; g issue comment 7 -R owner/code --body 'vid: reported c1-1'
is 'wait 7
wait 1
blocked 2
work 3'
# the loop: the words written once while the ask stands, said again for a later ask; a pass running or not
g issue close 3 -R owner/code; g issue close 7 -R owner/code; DM_TICK=1; DM_IDLE=600; DM_IDLE_TICK=2; DM_FIRST=5; DM_FOLLOW_TICK=1; export DM_TICK DM_IDLE DM_IDLE_TICK DM_FIRST DM_FOLLOW_TICK
ask "$P1" "vid: decision $(h 1)
ticket: not yet
ROW-001 held, a limit" 28; ask "$P1" "vid: decide $(h 1)" 35
mk() { sed -n 's/^mark: //p' "$T/out" | tail -n 1; }
( cd "$W" && sh "$DM" follow ) > "$T/out" 2>&1; M=$(mk); [ -n "$M" ] || fail 'follow gave no mark'
note 60; cp "$W/dm-note.txt" "$T/note.txt"
sh "$DM" loop "$T/note.txt" > "$T/lout" 2>&1 & LP=$!
said() { cat "$W/dm-report.txt" 2>/dev/null | grep -cE "^[0-9TZ:-]+ ViD has not answered #1 for $1 minutes: its session may have stopped\. Look at the conversation that runs /vid run\.\$" || true; }
n=0; while [ "$(said 35)" = 0 ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; sleep 4
[ "$(said 35)" = 1 ] || fail "with agents: command the loop did not write ViD's silence once: $(said 35)"
# a decision, then a later ask, 50 minutes old, made while a pass runs: said then, once
ask "$P1" "vid: decision $(h 1)
ticket: not yet
ROW-001 held, a limit" 60; sleep 4
FC_SLEEP=12; export FC_SLEEP; kill "$LP"; wait "$LP" 2>/dev/null || true; LP=''; rm -f "$W/dm-report.txt"; rm -f "$W/dm-stop"
g issue create -R owner/code --title t8 --body x --label ticket
sh "$DM" loop "$T/note.txt" > "$T/lout" 2>&1 & LP=$!
n=0; while [ ! -s "$W/agents/dev-manager-1/log" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; [ -d "$W/agents/dev-manager-1" ] || fail 'no pass started'
ask "$P1" "vid: decide $(h 1)" 50; n=0; while [ "$(said 50)" = 0 ] && [ "$n" -lt 9 ]; do sleep 1; n=$((n + 1)); done
[ "$(said 50)" = 1 ] && [ ! -e "$W/agents/dev-manager-1/taken" ] || fail 'ViD silent while a pass runs was not written'
echo 'enough' > "$W/dm-stop"; wait "$LP" || true; LP=''; [ "$(said 50)" = 1 ] || fail 'the line was written twice'
# follow shows it beside the stops, as no stop; a loop that ended with no stop of its own still has its last words shown
( cd "$W" && sh "$DM" follow "${M%%:*}:0:${M#*:*:}" ) > "$T/out" 2>&1
grep -q '^vid-silent: .* ViD has not answered #1 for 50 minutes: its session may have stopped\. Look at the conversation that runs /vid run\.$' "$T/out" || fail "follow does not show ViD's silence"
[ "$(grep -c '^stop: ' "$T/out")" = 1 ] && grep -q '^stop: .* the loop stopped: the stop file: enough$' "$T/out" || fail 'follow shows the silence as a stop, or not the stop'
W2=$T/w2; mkdir -p "$W2"; ( cd "$W2" && sh "$DM" follow ) > "$T/out" 2>&1; M=$(mk); u=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); printf '%s ViD has not answered #1 for 40 minutes: its session may have stopped. Look at the conversation that runs /vid run.\n' "$u" > "$W2/dm-report.txt"; echo 'dm.sh: the repository could not be cloned' > "$W2/dm-loop.log"
( cd "$W2" && DM_WORK=$W2 sh "$DM" follow "$M" ) > "$T/out" 2>&1; grep -qx '  last words of its log: dm.sh: the repository could not be cloned' "$T/out" || fail "a silence hides the loop's own last words"
# the words for the two ways
S=$RT/skills/vid-devagent/SKILL.md; awk '/^## With `agents: command`/ { f = 1; next } /^## With `agents: conversation`/ { f = 0 } f' "$S" | grep -q 'vid-silent:' || fail 'the skill does not show the silence, with agents: command'
awk '/^## With `agents: conversation`/ { f = 1; next } /^## / { f = 0 } f' "$S" | grep -F 'vid-silent' | grep -qF 'once' || fail 'the skill does not say the silence once, with agents: conversation'
grep -F 'vid-silent <n> <m>' "$RT/devagent/agents/dev-manager.md" | grep -qF 'ViD has not answered #<n>' || fail 'the dev manager file does not name vid-silent'
echo 'dm-silent: ok'

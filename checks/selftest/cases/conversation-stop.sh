#!/bin/sh
# Purpose: selftest case — a dev side in a conversation says its stop and keeps its notes (FB-7 B5), devagent/dev-manager/dm.sh on the fake gh,
# with agents: conversation. `here` makes clones/dm, and in an emptied work folder brings the notes back from vid-dev/notes, the job note it
# was given kept; `next`, `done` and `take` each save the work folder there, less what is rebuilt; `stopped "<why>"` pushes the stopped report
# (by: DM, its words), comments `vid: stopped <why>` on the issue it holds work for alone, writes the stop in dm-report.txt and saves; a second
# one is stopped-2; no why, or no clone, is refused or said. With agents: command `stopped` is refused and `next`, `done` and `take` save
# nothing, as before. The skill runs it at the user's stop and at the time limit. Skips where devagent/ or skills/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] && [ -d "$CHECKS/../skills" ] || { echo 'needs devagent/ and skills/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
HOME=$T/home; mkdir -p "$HOME"; export HOME
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "conversation-stop: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$T/work/dm-report.txt" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W"; NT=$T/note.txt
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 3600\nagent-time-limit: 600\nagent-turn-limit: 40\nagents: conversation\n' "$W" > "$NT"
g() { gh "$@" > /dev/null; }
notes() { git -C "$T/code.git" show "refs/heads/vid-dev/notes:$1" 2>/dev/null; }
heads() { ls "$T/gh/issues/$1/comments" 2>/dev/null | while read -r c; do awk 'NR == 1' "$T/gh/issues/$1/comments/$c"; done; }
res() { git -C "$T/code.git" show "refs/heads/vid-results/stopped-$1:stopped-$1/results.txt" 2>/dev/null; }
DM_WORK=$W; export DM_WORK
g issue create -R owner/code --title t1 --body x --label ticket; printf 'vid: claimed\nby: DM\n' > "$T/b"; g issue comment 1 -R owner/code --body-file "$T/b"; g issue create -R owner/code --title t2 --body x --label ticket
# here: clones/dm, the DM_WORK line as before
(cd "$T" && sh "$DM" here "$NT") > "$T/out" 2>&1 || fail 'here'
git -C "$W/clones/dm" remote get-url origin > /dev/null 2>&1 || fail 'here made no clones/dm'
[ "$(grep -c '^DM_WORK=' "$T/out")" = 1 ] || fail 'here printed no DM_WORK line'
# next saves the work folder, and prints what it printed
sh "$DM" next > "$T/out" 2>&1 || fail 'next'; [ "$(cat "$T/out")" = 'work 1
claim 2' ] || fail "next's lines changed"
[ "$(notes dm-note.txt)" = "$(cat "$NT")" ] || fail 'next did not save the work folder on vid-dev/notes'
# done and take save it
mkdir -p "$W/tickets" "$W/clones/c1"; printf 'ticket: 1\nthe job\n' > "$W/job"; A=$(sh "$DM" start builder "$W/job" "$W/clones/c1" | sed -n 1p)
echo 'Built it.' > "$W/agents/$A/handback"; echo 'one' > "$W/tickets/1.txt"; sh "$DM" done "$A" 9 > "$T/out" 2>&1 || fail 'done'; [ "$(notes tickets/1.txt)" = one ] || fail 'done did not save the work folder'
echo 'two' > "$W/tickets/1.txt"; sh "$DM" take "$A" > "$T/out" 2>&1 || fail 'take'; [ "$(cat "$T/out")" = 'Built it.' ] || fail "take's lines changed"; [ "$(notes tickets/1.txt)" = two ] || fail 'take did not save the work folder'
! git -C "$T/code.git" ls-tree -r --name-only refs/heads/vid-dev/notes | grep -qE '^(agents|clones|runs|blind|captures)/' || fail 'the notes hold what is rebuilt'
# stopped: the report, the comment on the issue it holds work for alone, dm-report.txt, the notes
echo 'three' > "$W/tickets/1.txt"; sh "$DM" stopped "the user's stop" > "$T/out" 2>&1 || fail 'stopped'; grep -qx "the stop is said: the user's stop" "$T/out" || fail 'a stop that went out is not said'
res 1 > "$T/r" ; head -n 1 "$T/r" | grep -qx 'by: DM' && grep -qx "stopped: the user's stop" "$T/r" || fail "no stopped report, or not its words: $(cat "$T/r")"
[ "$(heads 1 | grep -cx "vid: stopped the user's stop")" = 1 ] && ! heads 2 | grep -q '^vid: stopped' || fail 'the stop was not said on the issue it holds work for alone'
grep -qE "^[0-9TZ:-]+ the conversation stopped: the user's stop\$" "$W/dm-report.txt" || fail 'dm-report.txt does not hold the stop'
[ "$(notes tickets/1.txt)" = three ] && notes dm-report.txt | grep -q "the user's stop" || fail 'stopped did not save the work folder'
sh "$DM" stopped 'the time limit: 3600s' > "$T/out" 2>&1 || fail 'a second stopped'; res 2 | grep -qx 'stopped: the time limit: 3600s' || fail 'the second stop is not stopped-2'
RC=0; sh "$DM" stopped > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ -z "$(res 3)" ] || fail 'stopped with no why was taken'
# a stop that could not be said: what failed is printed, exit 1, never that it is said; the report's push, then an issue's comment
printf '#!/bin/sh\nexit 1\n' > "$T/code.git/hooks/pre-receive"; chmod +x "$T/code.git/hooks/pre-receive"; RC=0; sh "$DM" stopped 'no push' > "$T/out" 2>&1 || RC=$?; rm -f "$T/code.git/hooks/pre-receive"
[ "$RC" = 1 ] && grep -q 'the stopped report could not be pushed' "$T/out" && ! grep -q 'the stop is said' "$T/out" || fail "a stopped report not pushed ($RC)"
mkdir -p "$T/shim"; RH=$(command -v gh); printf '#!/bin/sh\ncase "$1 $2" in "issue comment") echo refused >&2; exit 1 ;; esac\nexec "%s" "$@"\n' "$RH" > "$T/shim/gh"; chmod +x "$T/shim/gh"; RC=0; PATH="$T/shim:$PATH" sh "$DM" stopped 'no comment' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'the stop could not be said on #1' "$T/out" && ! grep -q 'the stop is said' "$T/out" || fail "a stop not said on its issue ($RC)"
# the work folder lost: here brings the notes back, the note it was given kept
sed 's/^time-limit: .*/time-limit: 7200/' "$NT" > "$T/n2"; rm -rf "$W"; mkdir -p "$W"; (cd "$T" && sh "$DM" here "$T/n2") > "$T/out" 2>&1 || fail 'here in an emptied folder'
[ "$(cat "$W/tickets/1.txt" 2>/dev/null)" = three ] && grep -q 'came back from vid-dev/notes' "$W/dm-report.txt" || fail 'the notes did not come back'
cmp -s "$T/n2" "$W/dm-note.txt" || fail 'the notes brought back an older job note over the one here was given'
# the same with the note in the work folder itself
cp "$T/n2" "$T/keep"; rm -rf "$W"; mkdir -p "$W"; cp "$T/keep" "$W/dm-note.txt"; (cd "$T" && sh "$DM" here "$W/dm-note.txt") > "$T/out" 2>&1 || fail 'here on dm-note.txt'; cmp -s "$T/keep" "$W/dm-note.txt" || fail 'dm-note.txt, given itself, came back older'
# a repository that cannot be cloned: here refuses, naming it
rm -rf "$T/w3"; mkdir -p "$T/w3"; sed "s|^work: .*|work: $T/w3|" "$NT" > "$T/n3"; mv "$T/code.git" "$T/code.away"; RC=0; (cd "$T" && sh "$DM" here "$T/n3") > "$T/out" 2>&1 || RC=$?; mv "$T/code.away" "$T/code.git"
[ "$RC" = 1 ] && grep -q 'the repository could not be cloned' "$T/out" || fail "here with no repository ($RC)"
# agents: command: nothing of this, though a clone stands there
sed 's/^agents: .*/agents: command/' "$NT" > "$W/dm-note.txt"; echo 'four' > "$W/tickets/1.txt"
RC=0; sh "$DM" stopped 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'agents: conversation' "$T/out" && [ -z "$(res 4)" ] || fail "stopped with agents: command ($RC)"
sh "$DM" next > /dev/null 2>&1 || fail 'next with agents: command'; mkdir -p "$W/agents/x/done"; echo h > "$W/agents/x/handback"; sh "$DM" take x > /dev/null 2>&1 || fail 'take with agents: command'
[ "$(notes tickets/1.txt)" = three ] || fail 'with agents: command next or take saved the notes'
# the skill runs it at the user's stop and at the time limit
S=$RT/skills/vid-devagent/SKILL.md; CV=$(awk '/^## With `agents: conversation`/ { f = 1; next } /^## / { f = 0 } f' "$S")
printf '%s\n' "$CV" | grep -F 'time-limit:' | grep -qE 'dm\.sh"? stopped "the time limit' || fail 'the skill does not say the stop at the time limit'
printf '%s\n' "$CV" | grep -F 'word "stop"' | grep -qE "dm\\.sh\"? stopped \"the user's stop\"" || fail "the skill does not say the user's stop"
echo 'conversation-stop: ok'

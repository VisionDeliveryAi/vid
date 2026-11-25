#!/bin/sh
# Purpose: selftest case — DevAgent's work folder has a compaction point (FB-8 E4). The first command checks/devagent-start.sh prints, run, makes
# the folder and its .claude/settings.json with autoCompactWindow 300000, the folder's paths holding a space; run again, or over a settings file
# already there, it changes none. dm.sh here does the same for a folder made before and says it takes effect when the conversation is opened
# again; a settings file there is left as it is, and nothing is said. The notes hold no .claude/: not a new one, not one the notes repository
# tracked before, nor one a save cut off had staged; a save that cannot take it out stops and says so; and notes that hold an old one bring it back neither over the folder's own nor into a folder with none. A folder a loop
# works (agents: command) gets none. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
HOME=$T/home; mkdir -p "$HOME"; export HOME
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "devagent-start-compact: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
win() { [ ! -f "$1" ] || tr -d " \t\r\n" < "$1"; }
# the start's first command
mkdir "$T/a folder"; tw_toy "$T/a folder/p"; sh "$CHECKS/planner.sh" setup github-mode auto --words 'your own DevAgent, please' > /dev/null 2>&1 || fail 'setup github-mode auto'
sh "$RT/checks/devagent-start.sh" > "$T/out" 2>&1 || fail 'the start was not printed'; cp "$T/out" "$T/print"
L=$(awk '/^1\. / { on = 1; next } /^2\. / { exit } on && NF' "$T/print"); [ "$(printf '%s\n' "$L" | grep -c .)" = 1 ] || fail "step 1 is not one command: $L"
WK=$(sed -n 's/^work: *//p' "$T/print" | head -n 1); ST=$WK/.claude/settings.json; [ ! -e "$WK" ] || fail 'the print made the work folder'
case $L in "mkdir -p "*) ;; *) fail "the first command does not begin with the folder: $L" ;; esac
sh -c "$L" > "$T/out" 2>&1 || fail 'the first command failed'
[ "$(win "$ST")" = '{"autoCompactWindow":300000}' ] || fail "the new work folder's settings: $(cat "$ST" 2>/dev/null)"
printf '{ "permissions": {} }\n' > "$ST"; cp "$ST" "$T/own"; sh -c "$L" > "$T/out" 2>&1 || fail 'the first command, run again, failed'; cmp -s "$ST" "$T/own" || fail 'the start changed a settings file already there'
rm -rf "$WK/.claude"; sh -c "$L" > "$T/out" 2>&1 || fail 'the first command, on a folder made before'; [ "$(win "$ST")" = '{"autoCompactWindow":300000}' ] || fail 'a folder made before got no compaction point'
# here
{ git init -q --bare "$T/code2.git"; git -C "$T/code2.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code2.git" HEAD:refs/heads/main; }
mv "$T/code.git" "$T/toy.git" 2>/dev/null || true; mv "$T/code2.git" "$T/code.git"; gh_fake
W="$T/a folder/w"; mkdir -p "$W"; NT=$T/note.txt; printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 3600\nagent-time-limit: 600\nagent-turn-limit: 40\nagents: conversation\n' "$W" > "$NT"
SAY='^the work folder.s compaction point is set (autoCompactWindow 300000, .*settings\.json): it takes effect when this conversation is opened again'
hr() { RC=0; (cd "$T" && sh "$DM" here "$NT") > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && grep -q '^DM_WORK=' "$T/out" || fail "here ($RC)"; }
hr; [ "$(win "$W/.claude/settings.json")" = '{"autoCompactWindow":300000}' ] || fail 'here set no compaction point in a folder made before'; grep -q "$SAY" "$T/out" || fail 'here did not say when it takes effect'
hr; ! grep -q 'compaction point' "$T/out" || fail 'here said it again'
printf '{ "permissions": {} }\n' > "$W/.claude/settings.json"; hr; cmp -s "$W/.claude/settings.json" "$T/own" && ! grep -q 'compaction point' "$T/out" || fail 'here changed a settings file already there, or said it did'
# the notes: a loop's save and its start (agents: command), on the fake gh
tree() { git -C "$T/code.git" ls-tree -r --name-only refs/heads/vid-dev/notes; }
sed 's/^agents: .*/agents: command/' "$NT" > "$T/nc"; lp() { echo x > "$W/dm-stop"; DM_TICK=1 sh "$DM" loop "$T/nc" > "$T/out" 2>&1 || fail 'the loop'; rm -f "$W/dm-stop"; }
mkdir -p "$W/tickets"; echo one > "$W/tickets/1.txt"; lp; tree | grep -qx tickets/1.txt || fail 'the notes were not saved'; ! tree | grep -q '^\.claude/' || fail 'the notes hold .claude/'
N() { git --git-dir="$W/.notes.git" --work-tree="$W" -c user.name=t -c user.email=t@t "$@"; }
N add -f .claude/settings.json && N commit -qm 'a tracked settings file' && N push -q "$T/code.git" HEAD:refs/heads/vid-dev/notes || fail 'the settings file could not be tracked'; tree | grep -qx .claude/settings.json || fail 'the scene: not on the branch'
git clone -q -b vid-dev/notes "$T/code.git" "$T/old" 2>/dev/null; lp; ! tree | grep -q '^\.claude/' || fail 'the notes hold a .claude/ tracked before'; [ -f "$W/.claude/settings.json" ] || fail "the save took the folder's own settings"
# a settings file staged by a save cut off, and changed again since: it is dropped all the same; a removal that fails stops the save and is said
N reset -q --hard; rm -rf "$W/.claude"; mkdir "$W/.claude"; echo '{ "a": 1 }' > "$W/.claude/settings.json"; N add -f .claude/settings.json && N commit -qm 'tracked' && N push -q "$T/code.git" HEAD:refs/heads/vid-dev/notes || fail 'the scene: tracked'
echo '{ "b": 1 }' > "$W/.claude/settings.json"; N add -f .claude/settings.json; echo '{ "c": 1 }' > "$W/.claude/settings.json"; P0=$PWD; cd "$W"; lp; cd "$P0"; ! tree | grep -q '^\.claude/' || fail 'the notes hold a .claude/ staged by a save cut off'   # from the work folder, where git compares the file
GIT=$(command -v git); printf '#!/bin/sh\ncase " $* " in *" rm "*".claude"*) exit 1 ;; esac\nexec "%s" "$@"\n' "$GIT" > "$T/bin/git"; chmod +x "$T/bin/git"
h0=$("$GIT" -C "$T/code.git" rev-parse refs/heads/vid-dev/notes); echo two > "$W/tickets/1.txt"; lp; rm -f "$T/bin/git"; [ "$(git -C "$T/code.git" rev-parse refs/heads/vid-dev/notes)" = "$h0" ] || fail 'a save whose removal of .claude/ failed went on'
grep -q 'the notes could not be saved' "$W/dm-report.txt" || fail 'a save that stopped is not said'; echo one > "$W/tickets/1.txt"; lp
# notes that hold an old one, brought back: the folder's own stays, and a folder with none gets none
printf '{ "old": 1 }\n' > "$T/old/.claude/settings.json"; git -C "$T/old" -c user.name=t -c user.email=t@t commit -qam old; git -C "$T/old" push -q -f "$T/code.git" HEAD:refs/heads/vid-dev/notes || fail 'the scene: the old notes'
for k in own none; do git -C "$T/old" push -q -f "$T/code.git" HEAD:refs/heads/vid-dev/notes; rm -rf "$W"; mkdir -p "$W"; [ $k = none ] || { mkdir "$W/.claude"; cp "$T/own" "$W/.claude/settings.json"; }; lp
  [ "$(cat "$W/tickets/1.txt" 2>/dev/null)" = one ] || fail "$k: the notes did not come back"
  if [ $k = own ]; then cmp -s "$W/.claude/settings.json" "$T/own" || fail "the notes wrote over the folder's settings: $(cat "$W/.claude/settings.json")"; else [ ! -e "$W/.claude" ] || fail 'the notes brought a settings file back, or a loop made one'; fi
  ! tree | grep -q '^\.claude/' || fail "$k: the notes still hold .claude/"; done
echo 'devagent-start-compact: ok'

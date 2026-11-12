#!/bin/sh
# Purpose: selftest case — the dev side started in one command (v0.26.10.28.3 R2), on stubs alone: the fake gh serving a local repository, and a claude and a
# docker of its own that run no model and no container. check prints `ready` when nothing is missing, and names each of a gh signed out, a read-only repo:, no
# Docker, claude signed out, a dollar key and a work folder inside ViD's records, one at a time, then `1 missing`, exit 1; a claude with no sign-in command is
# said, not counted. up refuses on a miss, starts nothing; else starts dm.sh loop on the note, detached in its own process group, and returns at once, its pid and
# start stamp in dm-loop.pid; a second up is refused, naming the pid. down writes dm-stop and waits for that pid alone: the loop ends, another process is left.
# up after down clears the stop file and leaves a loop running. dm.sh sets no environment cap of the machine's. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(cd "$(mktemp -d)" && pwd -P)
# a loop left by a failure is stopped by its recorded pid alone
trap 'for p in $(cat "$T/loops" 2>/dev/null); do kill -TERM "$p" 2>/dev/null || true; done; [ -z "${SP:-}" ] || kill "$SP" 2>/dev/null || true; sleep 1; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-up: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W"
cat > "$T/bin/claude" <<C
#!/bin/sh
case "\$1 \${2:-}" in
  'auth --help') [ -f "$T/claude-old" ] && exit 1; printf 'Commands:\n  status [options]  Show authentication status\n'; exit 0 ;;
  'auth status') [ -f "$T/claude-out" ] && echo '{"loggedIn": false}' || echo '{"loggedIn": true}'; exit 0 ;;
esac
printf '%s\n' "\$*" >> "$T/claude-runs"; exit 1
C
printf '#!/bin/sh\n[ ! -f "%s/docker-down" ] || exit 1\necho stub\n' "$T" > "$T/bin/docker"; chmod +x "$T/bin/claude" "$T/bin/docker"
NT=$T/note.txt; printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 3600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$NT"
ck() { RC=0; sh "$DM" check "$1" > "$T/out" 2>&1 || RC=$?; }
one() { [ "$RC" = 1 ] && [ "$(sed -n 1p "$T/out")" = "missing: $1" ] && [ "$(sed -n 2p "$T/out")" = '1 missing' ] && [ "$(wc -l < "$T/out" | tr -d ' ')" = 2 ] || fail "check did not name: $1"; }
# check: ready, then each miss alone
ck "$NT"; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = ready ] || fail 'check on a ready dev side'
: > "$T/gh/auth-fail"; ck "$NT"; one 'gh signed in (gh auth status)'; rm "$T/gh/auth-fail"
echo READ > "$T/gh/perm"; ck "$NT"; one "write access to owner/code, the note's repo: (gh gives READ)"; rm "$T/gh/perm"
: > "$T/docker-down"; ck "$NT"; one 'Docker answering (docker info)'; rm "$T/docker-down"
: > "$T/claude-out"; ck "$NT"; one 'claude signed in (claude auth status)'; rm "$T/claude-out"
cp "$NT" "$T/n2"; echo 'spend-limit: 5' >> "$T/n2"; ck "$T/n2"; [ "$RC" = 1 ] && grep -q '^missing: the job note holds spend-limit:, read no longer: give time-limit: .*agent-time-limit: .*agent-turn-limit: ' "$T/out" && grep -qx '1 missing' "$T/out" || fail 'check did not name the dollar key'
grep -v '^agent-turn-limit:' "$NT" > "$T/n2"; ck "$T/n2"; one "the job note's agent-turn-limit:, a whole number"
mkdir -p "$T/p/.vid" "$T/p/w"; sed "s|^work: .*|work: $T/p/w|" "$NT" > "$T/n2"; ck "$T/n2"; one "a work folder outside ViD's records: $T/p/w is in $T/p"
: > "$T/claude-old"; ck "$NT"; [ "$RC" = 0 ] && grep -q "^unchecked: claude's sign-in" "$T/out" && grep -qx ready "$T/out" || fail 'a claude with no sign-in command'; rm "$T/claude-old"
# up on a miss: refused, nothing started
: > "$T/docker-down"; RC=0; sh "$DM" up "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'not started' "$T/out" && [ ! -f "$W/dm-loop.pid" ] || fail 'up on a miss'; rm "$T/docker-down"
# up: detached, at once, its own process group, the loop as dm.sh loop runs it
DM_TICK=1; DM_IDLE=3600; export DM_TICK DM_IDLE
t0=$(date +%s); sh "$DM" up "$NT" > "$T/out" 2>&1 || fail 'up failed'; t1=$(date +%s); [ $((t1 - t0)) -le 15 ] || fail "up did not return at once: $((t1 - t0)) s"
P=$(sed -n 1p "$W/dm-loop.pid"); echo "$P" >> "$T/loops"; grep -q "^the loop runs, pid $P, its output in $W/dm-loop.log" "$T/out" && grep -q "dm.sh down $NT" "$T/out" || fail 'up did not say how to stop it'
kill -0 "$P" 2>/dev/null || fail 'the loop up started is not running'; [ "$(ps -o pgid= -p "$P" | tr -d ' ')" = "$P" ] || fail 'the loop is not in a process group of its own'
sed 1d "$W/dm-loop.pid" > "$T/st"; sh "$RT/devagent/test-manager/run.sh" is "$P" "$T/st" || fail "dm-loop.pid's stamp is not the loop's"
ps -o command= -p "$P" | grep -qF "dm.sh loop $NT" || fail "the loop's command: $(ps -o command= -p "$P")"
sleep 3; kill -0 "$P" 2>/dev/null || { cp "$W/dm-loop.log" "$T/out"; fail 'the loop did not go on'; }; [ ! -s "$T/claude-runs" ] || fail 'a model was run'
# a second up: refused, naming the pid; the first goes on
RC=0; sh "$DM" up "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "a loop runs already in $W, pid $P" "$T/out" && kill -0 "$P" 2>/dev/null || fail 'a second up'
# a standing .up.lock (another up starting, or one stopped midway) is never removed by another up: refused, named
mkdir "$W/.up.lock"; RC=0; sh "$DM" up "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "remove $W/.up.lock if no dm.sh up runs" "$T/out" && [ -d "$W/.up.lock" ] || fail 'a standing .up.lock was not refused, or was removed'; rmdir "$W/.up.lock"
# down: the stop file, that pid waited for; another process is left alone
sleep 60 & SP=$!; RC=0; sh "$DM" down "$NT" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && grep -qx "the loop, pid $P, ended" "$T/out" || fail 'down'
! kill -0 "$P" 2>/dev/null || fail 'the loop outlived down'; kill -0 "$SP" 2>/dev/null || fail 'down reached another process'; kill "$SP"; wait "$SP" 2>/dev/null || true; SP=''
grep -q 'the loop stopped: the stop file: down at ' "$W/dm-report.txt" || fail "the loop's report: $(cat "$W/dm-report.txt")"; [ -f "$W/dm-stop" ] || fail 'down left no stop file'
# up again: the stop file cleared, a loop left running; then down
sh "$DM" up "$NT" > "$T/out" 2>&1 || fail 'up after down'; P2=$(sed -n 1p "$W/dm-loop.pid"); echo "$P2" >> "$T/loops"; [ "$P2" != "$P" ] && [ ! -f "$W/dm-stop" ] || fail 'up after down kept the stop file'
sleep 3; kill -0 "$P2" 2>/dev/null || { cp "$W/dm-loop.log" "$T/out"; fail 'up after down left no loop running'; }
(cd "$W" && sh "$DM" down) > "$T/out" 2>&1 || fail 'down, from the work folder'; grep -qx "the loop, pid $P2, ended" "$T/out" && ! kill -0 "$P2" 2>/dev/null || fail 'the second down'
RC=0; (cd "$W" && sh "$DM" down) > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && grep -q 'no loop dm.sh up recorded runs' "$T/out" || fail 'down with no loop'
# 9.1.1's cap is the machine's: dm.sh neither sets nor passes one
! grep -n -e 'DEVAGENT_ENVIRONMENTS' -e 'max-environments' "$DM" > "$T/out" || fail 'dm.sh touches the environment cap'
[ ! -s "$T/claude-runs" ] || { cp "$T/claude-runs" "$T/out"; fail 'a model was run'; }
exit 0

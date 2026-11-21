#!/bin/sh
# Purpose: selftest case — dm.sh reads its agents by their ids (low-1, R6): with DM_WORK under a folder whose name has a space and one
# live agent folder (a process this case starts and stamps as start does), `list` names it alive, `next` (the fake gh) gives its ticket
# `work` where a decide waits, and `used` counts it running, each with no error line. Skips where devagent/ is absent. Env: CHECKS.
set -eu
RT=$(cd "$CHECKS/.." && pwd -P); [ -d "$RT/devagent" ] || { echo 'needs devagent/'; exit 77; }
DM=$RT/devagent/dev-manager/dm.sh; RUN=$RT/devagent/test-manager/run.sh
T=$(mktemp -d); P1=''; trap '[ -z "$P1" ] || kill "$P1" 2>/dev/null || true; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-dm-space: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W="$T/a b/work"; mkdir -p "$W/tickets" "$W/c1"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
# ticket 1, claimed, its pull request asked to decide at its head: wait, unless a live agent works it
g() { gh "$@" > /dev/null; }
g issue create -R owner/code --title t1 --body x --label ticket; g issue comment 1 -R owner/code --body 'vid: claimed'
git -C "$T/s" checkout -q -B t-1; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m t-1; git -C "$T/s" push -q -f "$T/code.git" HEAD:refs/heads/t-1; H=$(git -C "$T/s" rev-parse HEAD)
g pr create -R owner/code --head t-1 --base main --title x --body 'ticket: #1'; g pr comment 2 -R owner/code --body "vid: decide $H"
# one live agent on ticket 1, recorded as start records it
sleep 120 & P1=$!; A=$W/agents/builder-1; mkdir -p "$A"; echo "$P1" > "$A/pid"; sh "$RUN" stamp "$P1" > "$A/lstart"; echo $(($(date +%s) - 60)) > "$A/start"
: > "$A/log"; echo BU > "$A/role"; echo 1 > "$A/ticket"; echo "$W/c1" > "$A/clone"
run() { sh "$DM" "$1" > "$T/out" 2> "$T/err" || fail "$1 failed: $(cat "$T/err")"; [ ! -s "$T/err" ] || fail "$1 wrote error lines: $(cat "$T/err")"; }
run list; grep -qx "alive builder-1 ticket 1 clone $W/c1" "$T/out" || fail 'list left the agent out'
run next; [ "$(cat "$T/out")" = 'work 1' ] || fail 'next left the live agent out'
run used; grep -qx 'agents: 60 s, 0 turns; 0 ended, 1 running' "$T/out" || grep -qx 'agents: 61 s, 0 turns; 0 ended, 1 running' "$T/out" || fail 'used left the agent out'
kill "$P1" 2>/dev/null || true; P1=''
echo 'devagent-dm-space: ok'

#!/bin/sh
# Purpose: selftest case — a project in ticket mode whose panel has no list yet gets one at the end of a turn (FB-5 A1). Such a project
# (an upgraded one: a standing and a backlog, no .vid/face/list.json) holds the list after the hook's Stop, its state none and every
# open item in its holds; a Stop with a list there leaves it as it is; a project in no ticket mode gets none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
H=$CHECKS/../hooks; [ -f "$H/face-standing.sh" ] || { echo 'needs the plugin'"'"'s hooks/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME="$T/home"; export HOME; mkdir -p "$HOME"
fail() { echo "face-list-first: $*" >&2; exit 1; }
stop() { printf '{"hook_event_name":"Stop","session_id":"s1"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail 'the hook failed'; }
mkdir "$T/p" "$T/q"; cd "$T/p"; git init -q .; mkdir -p .vid/tw; printf 'repo: owner/code\n' > .vid/tw/settings; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md; printf '# PRD\n' > PRD.md
sh "$CHECKS/queue.sh" backlog add 'push the branch' > /dev/null 2>&1 || fail 'backlog add failed'
rm -f .vid/face/list.json; stop
[ -f .vid/face/list.json ] || fail 'a Stop made no list'
[ "$(python3 -c "import json; d=json.load(open('.vid/face/list.json')); print(d['state'], [h['id'] for h in d['rest']['holds']])")" = "none ['B1']" ] || fail "the list is $(cat .vid/face/list.json)"
printf '{"kept":1}\n' > .vid/face/list.json; stop; [ "$(cat .vid/face/list.json)" = '{"kept":1}' ] || fail 'a Stop wrote over a list that was there'
cd "$T/q"; git init -q .; mkdir -p .vid/face; printf 'mode: develop\n' > .vid/RUN-STATE.md; printf '{}\n' > .vid/face/standing.json; stop
[ ! -e .vid/face/list.json ] || fail 'a project in no ticket mode got a list'
echo 'face-list-first: ok'

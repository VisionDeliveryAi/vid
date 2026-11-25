#!/bin/sh
# Purpose: selftest case — the panel's standing carries the backlog (FB-3 D1). In a ticket-mode project whose stop 6 left no mark,
# `face.sh standing` holds `backlog`: the open items in the file's order, each with its id, state, who, words, next action, note and
# times, a `-` an empty one; the newest ten done, the newest first, and how many are done; format 2. With .vid/tw/settings and no
# backlog yet it is empty; where there is none of them it is null. A write of the backlog recomputes the standing, with no hook; a
# sync that changes nothing leaves it. Where hooks/ is beside checks/: the hook makes the standing and the run file at a first turn
# of a ticket-mode project with no .vid/face, and none in a project with neither; the panel reads the backlog and the owner's list
# made from it (FB-5 A1: hooks/face, face-sections'). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-backlog: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st() { python3 -c "import json; d=json.load(open('.vid/face/standing.json')); b=d['backlog']; print($1)"; }
git init -q .; mkdir -p .vid; printf 'mode: develop\nrun: active\n' > .vid/RUN-STATE.md; printf '# PRD\n' > PRD.md
sh "$CHECKS/face.sh" standing > "$T/out" 2>&1 || fail 'the standing failed'
grep -q '"backlog"' .vid/face/standing.json || fail 'the standing carries no backlog'
[ "$(st 'b is None')" = True ] || fail 'a develop project has a backlog'
mkdir -p .vid/tw; printf 'repo: owner/code\n' > .vid/tw/settings; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md; printf 'stage-cut n=1 at=2026-11-19T09:00:00Z\n' > .vid/metrics-events
sh "$CHECKS/face.sh" standing > "$T/out" 2>&1 || fail 'the standing failed'
[ "$(st 'b')" = "{'items': [], 'done': [], 'doneCount': 0}" ] || fail "a ticket-mode project with no backlog yet gives $(st b)"
rm .vid/face/standing.json; sh "$CHECKS/queue.sh" backlog add 'push the "branch"' --note 'a\b' > "$T/out" 2>&1 || fail 'backlog add failed'
[ -f .vid/face/standing.json ] || fail 'a write of the backlog made no standing'
sh "$CHECKS/queue.sh" backlog add 'wait for Ann' --who Ann --next 'ask again' > "$T/out" 2>&1 || fail 'backlog add failed'
sh "$CHECKS/queue.sh" backlog set B2 --state waiting --place top > "$T/out" 2>&1 || fail 'backlog set failed'
[ "$(st "d['format']")" = 2 ] || fail 'the format moved'
[ "$(st "[(i['id'], i['state'], i['who'], i['words'], i['next'], i['note'], i['ended']) for i in b['items']]")" = "[('B2', 'waiting', 'Ann', 'wait for Ann', 'ask again', '', ''), ('B1', 'to do', 'you', 'push the \"branch\"', '', 'a\\\\b', '')]" ] || fail "the items are $(st "b['items']")"
[ "$(st "b['items'][0]['since'][:2]")" = 20 ] || fail 'an item has no since'
[ "$(st "b['items'][0]['key'] if 'key' in b['items'][0] else 'none'")" = none ] || fail 'an item shows its key'
i=3; while [ $i -le 14 ]; do sh "$CHECKS/queue.sh" backlog add "item $i" > /dev/null 2>&1; i=$((i + 1)); done
awk -F'\t' -v OFS='\t' '$1 ~ /^B([3-9]|1[0-4])$/ { n = substr($1, 2); $3 = "done"; $9 = sprintf("2026-11-20T09:%02d:00Z", (n * 7) % 60) } { print }' .vid/decide/queue/backlog > "$T/x"; cat "$T/x" > .vid/decide/queue/backlog
sh "$CHECKS/face.sh" standing > "$T/out" 2>&1 || fail 'the standing failed'
[ "$(st "b['doneCount']")" = 12 ] && [ "$(st "len(b['done'])")" = 10 ] || fail "the done are $(st "len(b['done'])") of $(st "b['doneCount']")"
[ "$(st "[i['ended'] for i in b['done']] == sorted([i['ended'] for i in b['done']], reverse=True) and min(i['ended'] for i in b['done']) > '2026-11-20T09:03'")" = True ] || fail "the done are not the newest ten, newest first: $(st "[i['ended'] for i in b['done']]")"
[ "$(st "len(b['items'])")" = 2 ] || fail 'a done item is among the open ones'
sh "$CHECKS/queue.sh" sync > /dev/null 2>&1 || true   # its own question of GitHub auto's, if any, is in the backlog from here
touch -t 202601010000 .vid/face/standing.json; sh "$CHECKS/queue.sh" sync > /dev/null 2>&1 || true; [ -z "$(find .vid/face/standing.json -newermt 2026-06-01 2>/dev/null)" ] || fail 'a sync that changed nothing wrote the standing again'
# the hook
H=$CHECKS/../hooks; [ -f "$H/face-standing.sh" ] || { echo 'face-backlog: ok (no hooks/ here)'; exit 0; }
mkdir "$T/p" "$T/q"; cd "$T/q"; git init -q .; mkdir .vid; printf '{"hook_event_name":"UserPromptSubmit","session_id":"s1"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail 'the hook failed'
[ ! -e .vid/face ] || fail 'the hook wrote in a project with no standing and no ticket mode'
cd "$T/p"; git init -q .; mkdir -p .vid/tw; printf 'repo: owner/code\n' > .vid/tw/settings
printf '{"hook_event_name":"UserPromptSubmit","session_id":"s1"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail 'the hook failed'
grep -q '^running ' .vid/face/run.s1 2>/dev/null || fail 'a ticket-mode project'"'"'s first prompt left no run file'
[ -f .vid/face/standing.json ] || fail 'a ticket-mode project'"'"'s first prompt left no standing'
grep -q 'backlog' "$H/face/model.ts" && grep -q 'backlog' "$H/face/register.tsx" || fail 'the panel does not read the backlog'
grep -q 'list\.json' "$H/face/register.tsx" || fail 'the panel does not read the list made from the backlog'
exit 0

#!/bin/sh
# Purpose: selftest case — the panel's list is written again at each call (FB-5 A1, S5). On the board's toy (fixtures/plan-page.sh) in
# GitHub manual, a call's lines raised and sorted: the list holds the sort, what is new and what changed, and a card with one of its two
# pieces done. Before the next call the second piece is done: the call raises the same lines, the backlog stays byte for byte, nothing is
# sorted, and the list's card says two, with no `new` and no Changed line. A list that cannot be written fails no raise. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-refresh: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene; QS=$CHECKS/queue.sh; B=.vid/decide/queue/backlog; SO=.vid/decide/queue/sorted; TB=$(printf '\t'); : > "$T/out"
printf 'mode: tickets\nplan: required\nrun: waiting\n' > "$T/rs"; [ -f .vid/RUN-STATE.md ] || cat "$T/rs" > .vid/RUN-STATE.md
call() { mkdir -p .vid/next; cp "$T/trig" .vid/next/lines; so_ok raise "$T/trig"; }
pj() { python3 -c 'import json,sys
d=json.load(open(sys.argv[1])); cs=[x for t in d["teams"] for r in t["releases"] for k in r["tracks"] for x in k["cards"]]; c=lambda i:[x for x in cs if x["id"]==i][0]
print(json.dumps(eval(sys.argv[2])))' "$LJ" "$1" 2> "$T/out" || fail "the list cannot be read: $1"; }
call; I=$(awk -F'\t' '$3 != "done" { print $1 }' "$B"); set -- $I; [ $# -ge 2 ] || fail 'the toy raised fewer than two lines'
one=$1; shift; { so_todo "$one" 'Ask who takes it' | sed 's/^what/new Ana, Monday\nwhat/'; printf 'line changed -\nwhat a piece moved\n\nline vid %s\nwhat ViD sends the steps\n' "$(printf '%s\n' "$@" | paste -sd ',' -)"; } > "$T/s"; so_ok sort "$T/s"
[ "$(pj "[d['todo'][0]['isNew'], d['changed'], c('S02')['done']]")" = '[true, ["a piece moved"], 1]' ] || fail "after the sort the list says $(pj "[d['todo'][0]['isNew'], d['changed'], c('S02')['done']]")"
cp "$B" "$T/b"; cp "$SO" "$T/so"
awk -F'\t' -v OFS='\t' '$1 == "sub" && $4 == 7 { $5 = "CLOSED" } { print }' .vid/round/read > "$T/rd"; cat "$T/rd" > .vid/round/read
call; cmp -s "$T/b" "$B" && cmp -s "$T/so" "$SO" || fail 'the toy changed an item, or the call sorted'
[ "$(pj "c('S02')['done']")" = 2 ] || fail "with nothing raised the card still says $(pj "c('S02')['done']")"
[ "$(pj "[d['todo'][0]['isNew'], d['todo'][0]['new'], d['changed']]")" = '[false, "", []]' ] || fail 'what is new or changed is in the list after the next call'
mkdir "$T/c"; cp "$CHECKS"/*.sh "$T/c/"; printf '#!/bin/sh\nexit 1\n' > "$T/c/next-page.sh"; QS=$T/c/queue.sh; call
echo 'sort-refresh: ok'

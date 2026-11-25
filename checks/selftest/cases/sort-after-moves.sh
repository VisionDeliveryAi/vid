#!/bin/sh
# Purpose: selftest case — a call's moves are in its sort (FB-5 A1, S5). On the form fixture's toy in GitHub manual, /vid next's call
# with a move: the call ends after its raise, its last lines, made after the move, kept in .vid/next/lines; it prints no page and no
# queue line and writes no page; `queue.sh open` gives the list as the move left it. A call with no move keeps its lines too. The
# vid-next skill sorts after the moves and the analysis's listing and before the save, in a call with moves or without. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "sort-after-moves: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); fm_toy "$T/toy" || fail 'the toy could not be made'
CLAUDE_CODE_SESSION_ID=sam-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call failed'
end_() { ! grep -qE "^page |^Q[0-9]+$TB" "$T/out" || fail 'the call still ends with a page or the queue'; [ -s .vid/next/lines ] && grep -q "^count${TB}total$TB" .vid/next/lines || fail 'the call kept no lines'; [ ! -e "$HOME/ViD Viewer" ] || fail 'the call wrote a page'; }
end_; sh "$CHECKS/next.sh" triggers > "$T/L" 2> /dev/null; cmp -s "$T/L" .vid/next/lines || fail 'the lines kept are not the call'"'"'s'
M=$(awk -F'\t' '$1 == "move" && $2 == "publish" { print $3; exit }' .vid/next/lines); [ -n "$M" ] || fail 'the toy offers no publish move'
sh "$CHECKS/queue.sh" open > "$T/out" 2>&1 || fail 'queue.sh open failed'; grep -q "publish:.*:$M@" "$T/out" || fail 'the publish move is not open before it is done'
sh "$CHECKS/next-move.sh" call 'done' "publish $M" 'not now' > "$T/out" 2>&1 || fail 'the call with a move failed'
grep -q "^done done publish $M" "$T/out" || fail 'the move was not done'; end_
sh "$CHECKS/queue.sh" open > "$T/out" 2>&1 || fail 'queue.sh open failed'; ! grep -q "publish:.*:$M@" "$T/out" || fail 'the move done is still open after the call'
N=$CHECKS/../skills/vid-next/SKILL.md; [ -f "$N" ] || { echo 'sort-after-moves: ok (a project layout: no skills)'; exit 0; }
l() { grep -nF -- "$1" "$N" | tail -n 1 | cut -d: -f1; }
a=$(l 'next-move.sh" call <move>'); r=$(l 'Invoke the `vid-replan` skill'); s=$(l 'Invoke the `vid-sort` skill'); b=$(grep -n '^[0-9]\. \*\*Save\.' "$N" | cut -d: -f1)
[ -n "$a" ] && [ -n "$r" ] && [ -n "$s" ] && [ -n "$b" ] && [ "$a" -lt "$r" ] && [ "$r" -lt "$s" ] && [ "$s" -lt "$b" ] || fail 'vid-next does not sort after the moves and the analysis and before the save'
grep -F 'Invoke the `vid-sort` skill' "$N" | grep -q . && awk '/^[0-9]\. \*\*Sort/ { on = 1 } on && /^[0-9]\. \*\*Save/ { exit } on' "$N" | grep -q 'with moves or without' || fail 'the sort is not a step of its own, in every call'
echo 'sort-after-moves: ok'

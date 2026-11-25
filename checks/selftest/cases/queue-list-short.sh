#!/bin/sh
# Purpose: selftest case — the queue's open lines shown one line a kind (FB-3 C5). On the toy in GitHub manual, a raise of three
# important triggers of one kind, one of another, a critical one and three publish moves: `queue.sh list` holds each `Q<n>` line
# as before; `queue.sh list --short` shows one line a kind with its count, its Q numbers, its subjects and evidence and the one
# answer it takes, a kind of one line as `list` prints it; every Q number of `list` is in it; a declined one is in neither; and (FB-5
# A1) next-move.sh's call prints neither it nor a page: the owner's list is the vid-sort skill's. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "queue-list-short: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); l() { printf '%s' "$1" | tr '~' '\t'; echo; }
fm_toy "$T/toy" || fail 'the toy could not be made'
H=0123456789abcdef0123456789abcdef0123456; { l 'trigger~critical~blocked~#9~label vid:blocked'; l 'trigger~important~not-taken~#3~created 9 days ago'; l 'trigger~important~not-taken~#4~created 9 days ago'; l 'quiet~important~not-taken~#5~created 12 days ago~unchanged'; l 'trigger~important~step-slow~S02~#3 out 20 days; the median 4'
  l "move~publish~S04~${H}1~publishes S04"; l "move~publish~S05~${H}2~publishes S05"; l "move~publish~S06~${H}3~publishes S06"; l "move~withdraw~#7~${H}4~withdraws #7"; } > "$T/L"
sh "$CHECKS/queue.sh" raise "$T/L" > "$T/out" 2>&1 || fail 'queue.sh raise failed'
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
[ "$(grep -c "${TB}\(trigger\|move\):" "$T/ql")" = 9 ] || { cp "$T/ql" "$T/out"; fail 'the list does not hold the nine lines'; }
short() { sh "$CHECKS/queue.sh" list --short > "$T/qs" 2> "$T/out" || fail 'queue.sh list --short failed'; cp "$T/qs" "$T/out"; }
qn() { awk -F'\t' -v k="$1" -v s=":$2@" 'index($2, k) == 1 && index($2, s) { print $1 }' "$T/ql"; }
short
[ "$(grep -c "${TB}trigger:not-taken${TB}" "$T/qs")" = 1 ] || fail 'the three not-taken lines are not one'
W=$(grep "${TB}trigger:not-taken${TB}" "$T/qs"); A=$(qn trigger:not-taken '#3'); B=$(qn trigger:not-taken '#4'); C=$(qn trigger:not-taken '#5')
for w in "$A $B $C$TB" "${TB}decline not-taken \"<words>\"$TB" '3: ' "$A #3, $B #4: created 9 days ago" "$C #5: created 12 days ago"; do case "$W" in *"$w"*) ;; *) fail "the not-taken line lacks: $w" ;; esac; done; case $W in *answer*) fail 'the answer is said again in the words' ;; esac
W=$(grep "${TB}move:publish${TB}" "$T/qs"); case $W in *'the move'*|*'name it'*) fail 'the publish line says each its answer' ;; esac; for w in '3: ' 'S04: publishes S04' 'S05: publishes S05' 'S06: publishes S06' 'done "publish <subject>" "<words>"'; do case "$W" in *"$w"*) ;; *) fail "the publish line lacks: $w" ;; esac; done
for k in trigger:blocked: trigger:step-slow: move:withdraw:; do x=$(grep "${TB}$k" "$T/ql"); grep -qxF "$x" "$T/qs" || fail "a kind of one line is not as list prints it: $k"; done
for q in $(cut -f1 "$T/ql"); do grep -qE "(^|[ $TB])$q([ ,:$TB]|\$)" "$T/qs" || fail "$q of the list is in no line of it"; done
[ "$(grep -c . "$T/qs")" -lt "$(grep -c . "$T/ql")" ] || fail 'the short list is no shorter'
# declined: in neither; the rest of its kind still one line
sh "$CHECKS/queue.sh" answer "$C" decline 'no, it is fine' > "$T/out" 2>&1 || fail "$C was not declined"
short; grep -qE "(^|[ $TB])$C([ ,:$TB]|\$)" "$T/qs" && fail 'a declined line is shown'; grep -q "^$A $B${TB}trigger:not-taken${TB}" "$T/qs" || fail 'the two left are not one line'
RC=0; sh "$CHECKS/queue.sh" list --long > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'an unknown argument of list was taken'
# the call prints none of it
CLAUDE_CODE_SESSION_ID=qls-case; export CLAUDE_CODE_SESSION_ID; HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call failed'; sh "$CHECKS/queue.sh" list --short > "$T/qs" 2>/dev/null || fail 'list --short failed after the call'
grep -q "${TB}move:publish" "$T/qs" || fail 'the list holds no publish move after the call'; ! grep -qE "^page |${TB}(move|trigger):" "$T/out" || fail 'the call still prints the page or the list'
echo 'queue-list-short: ok'

#!/bin/sh
# Purpose: selftest case — the call's lines as shown, one line a kind (FB-3 C5). `next.sh short` of a lines file holding several
# counted lines of two kinds, triggers of two tiers and whats, quiet lines of two states, sub-issues of two tickets and warnings of two
# moves: one line each, its count, every subject and every evidence in it, the subjects of one evidence said once with it; the moves, the
# count, the tiers and every other line as they stand, the warnings after the moves. On the toy, `triggers --short` is `short` of
# `triggers`, whose own lines stay line for line; and next-move.sh's lines after the moves are grouped. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "next-short: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
l() { printf '%s' "$1" | tr '~' '\t'; echo; }
{ l 'count~total~5'; l 'count~to-place~3'; l 'counted~to-place~ROW-001~to-place no-step'; l 'counted~unpublished~ROW-005~step S04'; l 'counted~to-place~ROW-002~to-place no-step'; l 'counted~to-place~ROW-003~to-place other-stage'; l 'counted~unpublished~ROW-006~in no step'
  l 'trigger~critical~reset-taken~ROW-010~pending reset; in #2 (assignee ana)'; l 'trigger~important~not-taken~#3~created 9 days ago'; l 'trigger~important~not-taken~#4~created 9 days ago'; l 'trigger~important~not-taken~#5~created 12 days ago'
  l 'quiet~minor~to-place-active~ROW-001~to-place no-step; stage 1~minor'; l 'quiet~minor~to-place-active~ROW-002~to-place no-step; stage 1~minor'; l 'quiet~important~not-taken~#6~created 8 days ago~unchanged'
  l 'tiers~critical=1 important=3 unchanged=1 minor=2 declined=0'; l 'withdrawn~#9~the landing withdrew it'
  l 'context~sub~#2~#2~#21~OPEN~ana~The form'; l 'context~sub~#3~#3~#31~OPEN~-~The list'; l 'context~sub~#2~#21~#22~CLOSED~-~Its button'; l 'context~own-work~off~own-work on'
  l 'move~publish~S04~aaaa~publishes S04'; l 'warning~publish~S04~limit~3 open of 2~too many open'; l 'warning~publish~S04~stage-ahead~stage 0 open~stage 0 is not accepted'; l 'move~publish~S05~bbbb~publishes S05'; l 'warning~publish~S05~limit~3 open of 2~too many open'; l 'warning~publish~S05~limit~4 open of 2~too many open'; l 'move~withdraw~#7~cccc~withdraws #7'; } > "$T/L"
sh "$CHECKS/next.sh" short "$T/L" > "$T/out" 2>&1 || fail 'next.sh short refused'
one() { [ "$(grep -c "^$(l "$1")$TB" "$T/out")" = 1 ] || fail "not one line of: $1"; W=$(grep "^$(l "$1")$TB" "$T/out"); shift; for w; do case "$W" in *"$w"*) ;; *) fail "the line of $W lacks $w" ;; esac; done; }
one 'counted~to-place~3' 'ROW-001, ROW-002: to-place no-step' 'ROW-003: to-place other-stage'
one 'counted~unpublished~2' 'ROW-005: step S04' 'ROW-006: in no step'
one 'trigger~critical~reset-taken~1' 'ROW-010: pending reset; in #2 (assignee ana)'
one 'trigger~important~not-taken~3' '#3, #4: created 9 days ago' '#5: created 12 days ago'
one 'quiet~minor~to-place-active~minor~2' 'ROW-001, ROW-002: to-place no-step; stage 1'
one 'quiet~important~not-taken~unchanged~1' '#6: created 8 days ago'
one 'context~sub~#2~2' '#21 The form: OPEN, ana' '#22 Its button: CLOSED, under #21'
one 'context~sub~#3~1' '#31 The list: OPEN'
one 'warning~publish~limit~3' 'S04, S05: 3 open of 2; too many open' 'S05: 4 open of 2; too many open'
one 'warning~publish~stage-ahead~1' 'S04: stage 0 open; stage 0 is not accepted'
for x in 'count~total~5' 'count~to-place~3' 'tiers~critical=1 important=3 unchanged=1 minor=2 declined=0' 'withdrawn~#9~the landing withdrew it' 'context~own-work~off~own-work on' 'move~publish~S04~aaaa~publishes S04' 'move~publish~S05~bbbb~publishes S05' 'move~withdraw~#7~cccc~withdraws #7'; do grep -qxF "$(l "$x")" "$T/out" || fail "a line that stands alone was changed: $x"; done
[ "$(awk -F'\t' '{ print ($1 == "quiet" ? $1 " " $2 " " $3 " " $4 : $1 == "context" && $2 == "sub" ? $1 " " $2 " " $3 : $1 ~ /^(counted|trigger|warning)$/ ? $1 " " $2 " " ($1 == "counted" ? "" : $3) : NR) }' "$T/out" | sort | uniq -d | grep -c . || :)" = 0 ] || fail 'two lines of one kind are shown'
[ "$(awk -F'\t' '$1 == "move" { m = NR } $1 == "warning" && !w { w = NR } END { print (w > m) }' "$T/out")" = 1 ] || fail 'a warning stands between the moves'

# on the toy: triggers --short is short of triggers, every subject of the lines in it; the lines after a move grouped
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
CLAUDE_CODE_SESSION_ID=next-short-case; export CLAUDE_CODE_SESSION_ID; HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; sh "$CHECKS/next.sh" short "$T/L" > "$T/s1" 2> "$T/out" || fail 'short failed'
sh "$CHECKS/next.sh" triggers --short > "$T/s2" 2> "$T/out" || fail 'triggers --short failed'; cmp -s "$T/s1" "$T/s2" || { diff "$T/s1" "$T/s2" > "$T/out" || true; fail 'triggers --short is not short of triggers'; }
[ "$(grep -c "^counted$TB" "$T/L")" -gt 3 ] && [ "$(grep -c "^counted$TB" "$T/s1")" -le 2 ] || { cp "$T/s1" "$T/out"; fail 'the counted lines are not grouped'; }
for i in $(awk -F'\t' '$1 == "counted" { print $3 }' "$T/L"); do grep "^counted$TB" "$T/s1" | grep -qE "[ $TB]$i[,:]" || { cp "$T/s1" "$T/out"; fail "$i is in no shown line"; }; done
sh "$CHECKS/next-move.sh" call own-work on 'yes, on' > "$T/out" 2>&1 || fail 'the call failed'
sed -n '/^after the moves:/,$p' "$T/out" > "$T/af"; grep -q "^warning$TB" "$T/L" || fail 'the toy raises no warning'
[ "$(grep "^warning$TB" "$T/af" | cut -f1-3 | sort | uniq -d | grep -c . || :)" = 0 ] && grep -q "^move${TB}publish${TB}" "$T/af" || fail 'the lines after the moves are not grouped'
echo 'next-short: ok'

#!/bin/sh
# Purpose: selftest case — the words of the sort are flagged, never refused (FB-5 A1, S2). A shown part with an id of the inventory, an
# open item's number, a commit hash of 12 or more or a /vid command draws a flag (a `release` line's words too) that names the part and the word; `message` and
# `details` draw none; an id that is not the inventory's, a closed item's number, a shorter hash or a path draws none. Too long a title,
# do, what, ask or then, a third ask, a fourth choice, more than seven `todo` lines, an unknown section or part draw one; the sort is
# written all the same. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
so_ok backlog add 'the first'; so_ok backlog add 'the second'; so_ok backlog set B2 --state 'done'
grep -q '^ROW-001 ' INVENTORY.md || fail 'the toy inventory has no ROW-001'
H=0123456789abcdef0123
s() { so_todo B1 'Pick one'; }
fl() { grep '^flag: ' "$T/out" > "$T/fl" || : > "$T/fl"; }
has() { grep -F -- "$1" "$T/fl" | grep -qF -- "$2" || { cp "$T/fl" "$T/out"; fail "no flag on the $1 for $2"; }; }
s > "$T/s"; so_ok sort "$T/s"; fl; [ ! -s "$T/fl" ] || fail 'plain words draw a flag'
# the words ViD's own names stand in
s | sed -e "s/^title .*/title ROW-001 of the list/" -e "s/^do .*/do answer B1 now/" -e "s/^what .*/what it is at $H/" -e 's/^then .*/then say \/vid:vid-next/' -e 's/^choice The second/choice ROW-001-T1 again/' > "$T/s"
so_ok sort "$T/s"; fl; has title ROW-001; has 'do' B1; has what "$H"; has then /vid; has choice ROW-001; [ "$(grep -c . "$T/fl")" = 5 ] || { cp "$T/fl" "$T/out"; fail 'other than the five parts draw a flag'; }
grep -q "^what it is at $H" "$SO" || fail 'a flagged sort was not written'
{ printf 'release 1 ROW-001 is nearly in\nrelease 2 nearly in\n'; s; } > "$T/s"; so_ok sort "$T/s"; fl; has release ROW-001; [ "$(grep -c . "$T/fl")" = 1 ] || { cp "$T/fl" "$T/out"; fail 'other than the one release line draws a flag'; }
# free: message and details; and what is none of them
{ s; printf 'line changed -\nwhat ROW-999 and B2, abcdef012345xyz, 0123456789a, src/vid and the Q8 plan\n'; } | sed "s/^then .*/message ROW-001, B1, $H and \/vid next\nthen It is sent.\ndetails ROW-001, B1, $H, \/vid:vid-next/" > "$T/s"
so_ok sort "$T/s"; fl; [ ! -s "$T/fl" ] || { cp "$T/fl" "$T/out"; fail 'a message, details or a word that is none of them draws a flag'; }
# lengths
w() { i=0; o=''; while [ $i -lt "$1" ]; do i=$((i + 1)); o="$o word"; done; echo "${o# }"; }
len() { s | sed -e "s/^title .*/title $(w "$1")/" -e "s/^do .*/do $(w "$1")/" -e "s/^what .*/what $(w "$2")/" -e "s/^ask .*/ask $(w "$3")/" -e "s/^then .*/then $(w "$4")/" > "$T/s"; so_ok sort "$T/s"; fl; }
len 10 55 20 35; [ ! -s "$T/fl" ] || { cp "$T/fl" "$T/out"; fail 'parts at their lengths draw a flag'; }
len 11 56 21 36; for p in title 'do' what ask then; do has "$p" words; done
{ s; printf 'ask b\nchoice 1\nchoice 2\nchoice 3\nchoice 4\nask c\nmessage m\n'; } > "$T/s"; so_ok sort "$T/s"; fl; has B1 'three asks'; has B1 'four choices'
# an unknown section or part
{ s; printf 'colour red\nline maybe -\nwhat x\n'; } > "$T/s"; so_ok sort "$T/s"; fl; grep -q colour "$T/fl" && grep -q maybe "$T/fl" || fail 'an unknown part or section draws no flag'; ! grep -qE '^(colour|line maybe|what x)' "$SO" || fail 'an unknown part or section was kept'
# more than seven
i=3; : > "$T/s8"; while [ $i -le 9 ]; do so_ok backlog add "item $i"; so_todo "B$i" "Thing $i" >> "$T/s8"; i=$((i + 1)); done
{ printf 'line later B1\nwhat the first\nthen in spring\n\n'; cat "$T/s8"; } > "$T/s"; so_ok sort "$T/s"; fl; [ ! -s "$T/fl" ] || fail 'seven to do draw a flag'
{ s; cat "$T/s8"; } > "$T/s"; so_ok sort "$T/s"; fl; grep -q '8' "$T/fl" || fail 'eight to do draw no flag'; [ "$(grep -c '^line todo' "$SO")" = 8 ] || fail 'eight to do were not written'
echo 'sort-words: ok'

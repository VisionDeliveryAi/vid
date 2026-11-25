#!/bin/sh
# Purpose: selftest case — a sort made from the last one (FB-5 A1, S2). A state set again counts as set since the sort, the same one too:
# put off, sorted to do, put off again leaves My to do, and a waiting line's item set to do is `moved`; `queue.sh open` counts the moved
# and the next sort takes the mark away. A to-do's block copied unchanged, its items all put off or waiting since, is written where it is
# drawn, yours later or Waiting; one whose words are written again is a to-do. A placed line submitted lower is written in its place,
# and flagged. What was new, and a Changed line, said at the last sort is left out when the same words come again for the same ids, its
# item still under Changed; said in other words, or at a sort corrected with nothing raised, changed or called between, it stays. `queue.sh
# sorted --line` prints the call's one line alone, and writes nothing. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-again: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
for i in 1 2 3 4; do so_ok backlog add "item $i"; done
at() { so_now; awk -v i="$1" '$1 == "unsorted" && $2 == i { print "unsorted"; exit } $1 == "line" { n = split($4, a, ","); for (j = 1; j <= n; j++) if (a[j] == i) { print $2 " " $3; exit } }' "$T/now"; }
is() { [ "$(at "$1")" = "$2" ] || { cp "$T/now" "$T/out"; fail "$1 is at '$(at "$1")', not $2: $3"; }; }
mk() { sh "$QS" open 2> /dev/null | awk -F'\t' -v i="$1" '$1 == i { print $2 }'; }
moved() { sh "$QS" open > "$T/op" 2> "$T/out" || fail 'queue.sh open failed'; tail -n 1 "$T/op" | grep -qx "open 4 · 0 not sorted · $1 moved" || { cp "$T/op" "$T/out"; fail "open does not count $1 moved: $2"; }; }
wl() { printf 'line waiting B3\nwho Ann\nwhat the logo\nsince Monday\n\n'; }; ch() { printf 'line later B4\nwhat four\nthen in spring\n\n'; }
# the same state set again
so_ok backlog set B1 --state aside; { so_todo B1 'One'; so_todo B2 'Two'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; is B1 'todo 1.1' 'sorted to do while aside'; moved 0 'none was set since'
so_ok backlog set B1 --state aside; is B1 'later -' 'put off again'; [ "$(mk B1)" = moved ] || fail 'put off again is not moved'; moved 1 'put off again'
so_ok backlog set B3 --state waiting; { so_todo B1 'One, now'; so_todo B2 'Two'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; moved 0 'a sort takes the marks away'
so_ok backlog set B3 --state 'to do'; [ "$(mk B3)" = moved ] || fail 'a waiting line set to do is not moved'; moved 1 'a waiting line set to do'
so_ok backlog set B4 --next 'ask again'; moved 1 'a next action is no state'
# a block copied unchanged, put off or waiting since: written where it is drawn
so_ok backlog set B1 --state 'to do'; { so_todo B1,B2 'Pick the day'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; cp "$SO" "$T/kept"
so_ok backlog set B1 --state aside; so_ok backlog set B2 --state aside --note 'until the fair'; is B1 'later -' 'put off since'
so_ok sort "$T/kept"; tail -n 1 "$T/out" | grep -qx 'nothing is yours now' || fail 'a copied block put off since is said as a to-do'; is B1 'later -' 'copied unchanged, it came back'; is B2 'later -' 'copied unchanged, it came back'; grep -qx 'line later B1,B2' "$SO" && grep -qx 'what Pick the day' "$SO" && grep -qx 'then put off: until the fair' "$SO" || fail 'a copied block put off since is not written as yours later'
{ so_todo B1,B2 'Pick the day'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; is B1 'todo 1.1' 'put back in other words'
so_ok backlog set B1 --state waiting --who Ben; so_ok backlog set B2 --state waiting; cp "$SO" "$T/kept"; so_ok sort "$T/kept"; is B2 'waiting -' 'copied unchanged, waiting since'; grep -qx 'who Ben' "$SO" || fail 'a copied block waiting since does not say on whom'
{ so_todo B1,B2 'Pick the day'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; so_ok backlog set B1 --state aside; so_ok backlog set B2 --state aside; { so_todo B1,B2 'The fair is over: pick the day'; wl; ch; } > "$T/s"; so_ok sort "$T/s"; is B1 'todo 1.1' 'its time has come, in other words'
so_ok backlog set B1 --state 'to do'; so_ok backlog set B2 --state 'to do'
# a placed line submitted lower: written in its place
{ so_todo B1 'One'; so_todo B2 'Two'; so_todo B3 'Three'; ch; } > "$T/s"; so_ok sort "$T/s"; so_ok backlog set B2 --place top
ord() { so_now; awk '$1 == "line" && $2 == "todo" { print $4 }' "$T/now" | paste -sd ' ' -; }
{ ch; so_todo B3 'Three'; so_todo B1 'One'; so_todo B2 'Two'; } > "$T/s"; so_ok sort "$T/s"; grep '^flag: ' "$T/out" | grep -q 'Two' || fail 'a placed line submitted lower is not flagged'
[ "$(ord)" = 'B2 B3 B1' ] || fail "a placed line submitted lower stands $(ord)"; awk '/^line todo B2/ { on = 1; next } /^line / { on = 0 } on' "$SO" | grep -qx placed || fail 'the placed line lost its mark'
so_ok backlog set B1 --place after B2; { so_todo B1 'One'; so_todo B3 'Three'; so_todo B2 'Two'; ch; } > "$T/s"; so_ok sort "$T/s"; [ "$(ord)" = 'B2 B1 B3' ] || fail "two placed lines, the second submitted first, stand $(ord)"
# said once: the same words again for the same ids
said() { { so_todo B1 'One' | sed "s/^what/new $1\nwhat/"; so_todo B2 'Two'; so_todo B3 'Three'; printf 'line changed B4\nwhat %s\n\nline changed -\nwhat a page moved\n' "$2"; } > "$T/s"; so_ok sort "$T/s"; so_now; }
said 'Ann, Monday' 'the bank wrote'; said 'Ann, Monday' 'the bank wrote'; grep -qx 'new Ann, Monday' "$T/now" && grep -qx 'what the bank wrote' "$T/now" && grep -qx 'what a page moved' "$T/now" || fail 'a sort corrected at once lost what is new or changed'
so_raise < /dev/null; said 'Ann, Monday' 'the bank wrote'; ! grep -q '^new \|the bank wrote\|a page moved' "$T/now" || fail 'what the last sort said is said again after a call'; is B4 'changed -' 'its changed line was said'
! grep -q 'a page moved\|^new ' "$SO" || fail 'the sort kept what was said'
so_raise < /dev/null; said 'Ann, Tuesday' 'the bank wrote again'; grep -qx 'new Ann, Tuesday' "$T/now" && grep -qx 'what the bank wrote again' "$T/now" || fail 'other words were left out'
so_ok backlog set B3 --state waiting; said 'Ann, Tuesday' 'the bank wrote again'; ! grep -q '^new \|the bank wrote' "$T/now" || fail 'with no call between, what the last sort said is said again at a sort of something moved'
# the one line
cp "$SO" "$T/k"; so_ok sorted --line; [ "$(cat "$T/out")" = '2 things for you; first: Two' ] || fail 'sorted --line is not the one line alone'; [ "$(grep -c . "$T/out")" = 1 ] && cmp -s "$T/k" "$SO" || fail 'sorted --line prints more, or writes'
so_qs sorted --all; [ "$RC" != 0 ] || fail 'an unknown option of sorted was taken'
echo 'sort-again: ok'

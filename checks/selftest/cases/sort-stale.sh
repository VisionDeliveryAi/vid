#!/bin/sh
# Purpose: selftest case — what moved since the sort stands where it should (FB-5 A1, S2). An item raised since is not sorted, in no line;
# one whose words changed leaves its line and is not sorted, though its id is followed; a change of a count of days alone changes
# nothing; in a todo line of two, one changed takes the whole line. A closed item's line goes, and the same thing raised again is not
# sorted. A todo line whose open items were all set aside since is under the rest, yours later, all set waiting under Waiting, with who
# and since when, and is not the next one; one the sort itself put there, knowing the state, stays. An item given a new id with the same
# words keeps its line. A refused sort, twice, keeps the last one and counts what is not sorted. `queue.sh open` marks each item new,
# changed, moved or as it was, with its line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-stale: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
call() { { so_l trigger critical blocked '#4' "${1:-label vid:blocked}"; so_l trigger important step-slow S02 "out ${2:-9 days}; the median 4 days"; so_l move publish S03 "${3:-0123456789abcdef}" 'publishes the ticket of S03'; [ -z "${4:-}" ] || so_l move publish S04 2123456789abcdef 'publishes the ticket of S04'; } | so_raise; }
call; for i in 1 2 3 4; do so_ok backlog add "item $i"; done; QA=$(so_id '#4'); QB=$(so_id S02); QC=$(so_id S03)
full() { so_todo "$QA,B1" 'Unblock it'; so_todo B2 'Two'; so_todo B3,B4 'Three'; printf 'line vid %s\nwhat ViD publishes it\n\nline waiting %s\nwho Ann\nwhat the step\nsince Monday\n' "$QC" "$QB"; }
full > "$T/s"; so_ok sort "$T/s"; cp "$SO" "$T/k"
at() { so_now; awk -v i="$1" '$1 == "unsorted" && $2 == i { print "unsorted"; exit } $1 == "line" { n = split($4, a, ","); for (j = 1; j <= n; j++) if (a[j] == i) { print $2 " " $3; exit } }' "$T/now"; }
is() { [ "$(at "$1")" = "$2" ] || { cp "$T/now" "$T/out"; fail "$1 is at '$(at "$1")', not $2: $3"; }; }
is "$QA" 'todo 1.1' 'as sorted'; is "$QB" 'waiting -' 'as sorted'
# a count of days alone
call 'label vid:blocked' '12 days'; is "$QB" 'waiting -' 'a count of days changed alone'; so_now; grep -qx 'state sorted' "$T/now" || fail 'a count of days made the sort stale'
# raised since, a new id with the same words
call 'label vid:blocked' '12 days' 1123456789abcdef y; QN=$(so_id S04); QC2=$(so_id S03); [ "$QC2" != "$QC" ] || fail 'the toy gave no new id'; is "$QN" unsorted 'raised since the sort'; is "$QC2" 'vid -' 'a new id, the same words'
so_now; grep -qx 'state stale' "$T/now" && ! grep -qF "$QC " "$T/now" || fail 'the sort is not stale, or holds the old id'
# what open says
sh "$QS" open > "$T/out" 2>&1 || fail 'queue.sh open failed'; [ "$(awk -F'\t' -v q="$QN" '$1 == q { print $2 "|" $9 }' "$T/out")" = 'new|-' ] && [ "$(awk -F'\t' '$1 == "B2" { print $2 "|" $3 "|" $4 "|" $5 }' "$T/out")" = 'same|to do|you|item 2' ] || fail 'open does not mark the new one and the one as it was'
awk -F'\t' '$1 == "B2" { print $9 }' "$T/out" | grep -q '^todo 1\.2 .*Two' && tail -n 1 "$T/out" | grep -qx 'open 8 · 1 not sorted · 0 moved' || fail 'open does not give the line of the last sort, or the count'
# its words changed: out of its line, and the whole todo line with it
call 'label vid:blocked, again' '12 days' 1123456789abcdef y; QA2=$(so_id '#4'); is "$QA2" unsorted 'its words changed'; is B1 unsorted 'a todo line counts whole'; is B2 'todo 1.2' 'another line'; ! grep -q 'Unblock it' "$T/now" || fail 'a line whose item changed is still shown'
grep -q "^line todo $QA2,B1\$" "$SO" || fail 'the sort did not follow the new id'; sh "$QS" open > "$T/out" 2>&1; [ "$(awk -F'\t' -v q="$QA2" '$1 == q { print $2 }' "$T/out")" = changed ] || fail 'open does not mark a changed one'
# one of two in a line that is no todo: it alone leaves
{ so_todo "$QA2" 'Unblock it'; so_todo B2 'Two'; so_todo B3,B4 'Three'; printf 'line vid %s,%s\nwhat ViD publishes them\n\nline waiting %s\nwho Ann\nwhat the step\nsince Monday\n\nline later B1\nwhat one\nthen in spring\n' "$QC2" "$QN" "$QB"; } > "$T/s"; so_ok sort "$T/s"
{ so_l trigger critical blocked '#4' 'label vid:blocked, again'; so_l trigger important step-slow S02 'out 12 days; the median 4 days'; so_l move publish S03 1123456789abcdef 'publishes the ticket of S03'; so_l move publish S04 3123456789abcdef 'publishes the ticket of S04, all of it'; } | so_raise; QN2=$(so_id S04); is "$QN2" unsorted 'one of two changed'; is "$QC2" 'vid -' 'the other of the two'
# closed: its line goes; raised again, it is not sorted
so_ok answer "$QA2" decline 'not now'; so_ok list; so_now; ! grep -q 'Unblock it' "$T/now" && grep -qxF 'line todo 1.2 B2' "$T/now" || fail 'a closed item'"'"'s line still shows'
so_ok backlog set B2 --state 'done'; so_now; ! grep -qxF 'line todo 1.2 B2' "$T/now" || fail 'a done item'"'"'s line still shows'
# aside and waiting since
so_ok backlog set B3 --state aside; is B3 'todo 1.3' 'one of two set aside'; so_ok backlog set B4 --state aside --note 'after the fair'; is B3 'later -' 'all set aside'; is B4 'later -' 'all set aside'; awk '/^line later - B3,B4/ { on = 1; next } /^line / { on = 0 } on' "$T/now" > "$T/x"; grep -qx 'what Three' "$T/x" && grep -q '^then .*after the fair' "$T/x" || fail 'a line set aside does not say what and what brings it up'
sh "$QS" backlog > "$T/out"; grep '^next: ' "$T/out" | grep -q 'Three' && fail 'a line set aside is the next one'; sh "$QS" open > "$T/out"; [ "$(awk -F'\t' '$1 == "B4" { print $2 }' "$T/out")" = moved ] || fail 'open does not mark one set aside since'
so_ok backlog set B3 --state waiting --who Ben --note 'asked on Friday'; so_ok backlog set B4 --state waiting; is B3 'waiting -' 'all set waiting'; awk '/^line waiting - B3,B4/ { on = 1; next } /^line / { on = 0 } on' "$T/now" > "$T/x"; for l in 'who Ben' 'what Three' 'since asked on Friday'; do grep -qx "$l" "$T/x" || fail "a line set waiting does not say: $l"; done
so_ok backlog set B3 --state 'to do'; is B3 'todo 1.3' 'one of the two is to do again'
# the sort puts it there knowing the state: it stays
so_ok backlog set B3 --state aside; so_ok backlog set B4 --state waiting
{ so_todo B3 'Its time has come'; so_todo B4 'Chase it'; printf 'line vid %s,%s\nwhat ViD publishes them\n\nline waiting %s\nwho Ann\nwhat the step\nsince Monday\n\nline later B1\nwhat one\nthen in spring\n' "$QC2" "$QN2" "$QB"; } > "$T/s"; so_ok sort "$T/s"; is B3 'todo 1.1' 'sorted there while aside'; is B4 'todo 1.2' 'sorted there while waiting'
so_ok backlog set B3 --state waiting; is B3 'waiting -' 'set waiting since the sort'
# refused twice: the last sort kept, what is not sorted counted
so_ok backlog add 'item 5'; cp "$SO" "$T/k"; for x in 1 2; do printf 'line todo B5\n' > "$T/s"; so_qs sort "$T/s"; [ "$RC" != 0 ] || fail 'half a sort was taken'; tail -n 1 "$T/out" | grep -qx '1 thing for you; first: Chase it; not sorted: 1' || fail "a refused sort's line is wrong"; done
cmp -s "$T/k" "$SO" || fail 'a refused sort changed the last one'; is B5 unsorted 'added since'
echo 'sort-stale: ok'

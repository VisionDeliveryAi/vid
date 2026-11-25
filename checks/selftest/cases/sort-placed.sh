#!/bin/sh
# Purpose: selftest case — a line the owner placed stays where it was put (FB-5 A1, S2). `backlog set <id> --place top|after <id>` moves
# the line of that item in the sort, whole, among the lines of its section, and marks it `placed`, at once; its new id is followed; the
# next sort keeps the mark though the sort given lost it, and a line put before it that was not there, a new one too, is flagged and
# written after it; once it closes the mark is gone with it. With no sort, and for an item in no line, only the backlog's order changes.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-placed: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
ord() { awk '$1 == "line" { p = $2 ":" $3 } $1 == "line" { print p } $1 == "placed" { print "placed" }' "$SO" | paste -sd ' ' -; }
for i in 1 2 3 4; do so_ok backlog add "item $i"; done
so_ok backlog set B4 --place top; [ ! -e "$SO" ] || fail 'a placing with no sort made one'
{ so_todo B1 'One'; so_todo B2,B3 'Two'; printf 'line later B4\nwhat four\nthen in spring\n'; } > "$T/s"; so_ok sort "$T/s"
[ "$(ord)" = 'todo:B1 todo:B2,B3 later:B4' ] || fail "the sort stands $(ord)"
so_ok backlog set B3 --place top; [ "$(ord)" = 'todo:B2,B3 placed todo:B1 later:B4' ] || fail "B3 on top gives $(ord)"
tail -n 1 "$T/out" | grep -q '^next: 1\.1 · Two · ' || fail 'the placed line is not the next one'
so_now; grep -qxF 'line todo 1.1 B2,B3' "$T/now" && grep -qxF 'line todo 1.2 B1' "$T/now" && grep -qx placed "$T/now" || fail 'the sort as it stands does not show the place'
awk '/^line todo B2,B3/ { on = 1; next } /^line / { on = 0 } on' "$SO" | grep -qx 'title Two' || fail 'the line moved without its parts'
so_ok backlog set B2 --place after B1; [ "$(ord)" = 'todo:B1 todo:B2,B3 placed later:B4' ] || fail "B2 after B1 gives $(ord)"
so_ok backlog set B1 --place after B4; [ "$(ord)" = 'todo:B1 placed todo:B2,B3 placed later:B4' ] || fail "after an item of another section the line moved: $(ord)"
so_ok backlog set B4 --state waiting; so_ok backlog set B4 --state 'to do'; [ "$(ord)" = 'todo:B1 placed todo:B2,B3 placed later:B4' ] || fail 'a set with no place moved a line'
# the next sort: the mark carried, a line newly before it flagged
so_ok backlog set B2 --place top; cp "$SO" "$T/kept"; so_ok backlog add 'item 5'
awk '$1 == "placed" { next } { print }' "$T/kept" > "$T/s"; so_todo B5 'Five' >> "$T/s"; so_ok sort "$T/s"; ! grep -q '^flag: ' "$T/out" || fail 'the placed lines kept where they were draw a flag'
[ "$(ord)" = 'todo:B2,B3 placed todo:B1 placed later:B4 todo:B5' ] || fail "the mark was not carried: $(ord)"
{ so_todo B5 'Five'; so_todo B2,B3 'Two'; so_todo B1 'One'; printf 'line later B4\nwhat four\nthen in spring\n'; } > "$T/s"; so_ok sort "$T/s"; grep '^flag: ' "$T/out" | grep -q 'Five' || fail 'a line put before a placed one draws no flag'; [ "$(ord)" = 'todo:B2,B3 placed todo:B1 placed todo:B5 later:B4' ] || fail "a new line put first stands $(ord)"
# a line of the queue's: its new id followed, its place and mark kept
{ so_l move publish S03 0123456789abcdef 'publishes the ticket of S03'; } | so_raise; Q1=$(so_id S03)
{ so_todo B2,B3 'Two'; so_todo B1 'One'; so_todo "$Q1" 'Publish it'; printf 'line later B4,B5\nwhat four\nthen in spring\n'; } > "$T/s"; so_ok sort "$T/s"; so_ok backlog set "$Q1" --place top
{ so_l move publish S03 1123456789abcdef 'publishes the ticket of S03'; } | so_raise; Q2=$(so_id S03); [ "$Q1" != "$Q2" ] || fail 'the toy gave no new id'
[ "$(ord)" = "todo:$Q2 placed todo:B2,B3 placed todo:B1 placed later:B4,B5" ] || fail "the new id lost its line or its place: $(ord)"; so_now; grep -qxF "line todo 1.1 $Q2" "$T/now" || fail 'the item with a new id is not where it was'
# closed, the mark goes with it
so_ok backlog set B1 --state 'done'; so_ok backlog add 'item 6'; { so_todo B6 'Six'; so_todo "$Q2" 'Publish it'; so_todo B2,B3 'Two'; printf 'line later B4,B5\nwhat four\nthen in spring\n'; } > "$T/s"; so_ok sort "$T/s"
[ "$(grep -c '^placed$' "$SO")" = 2 ] && [ "$(ord)" = "todo:$Q2 placed todo:B2,B3 placed todo:B6 later:B4,B5" ] || fail "a closed item's mark stayed, or another's went: $(ord)"
# an item in no line: the backlog's order alone
so_ok backlog add 'item 7'; cp "$SO" "$T/was"; so_ok backlog set B7 --place top; cmp -s "$T/was" "$SO" || fail 'an item in no line changed the sort'; [ "$(sed -n 1p "$B" | cut -f1)" = B7 ] || fail 'the backlog did not take the place'
echo 'sort-placed: ok'

#!/bin/sh
# Purpose: selftest case — the sort holds every open item once (FB-5 A1, S2). `queue.sh sort` refuses a sort, whole, each reason named,
# that leaves an open item out, holds one in two lines, names one that is not open or closed, or has a line with no item where one is
# owed (`todo` never; `changed` and `vid` may have none); the sort before stays byte for byte, and its line says it is not sorted. A
# whole one is written with its time, the sort before kept as sorted.prev, its ids and parts as given, a file or the standard input
# alike, a tab or an empty line in it no harm; a project with no ticket mode has none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-coverage: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
{ so_l trigger critical blocked '#4' 'label vid:blocked'; so_l move publish S03 0123456789abcdef 'publishes the ticket of S03'; } | so_raise
so_ok backlog add 'wait for the bank'; so_ok backlog add 'a thing done'; so_ok backlog set B2 --state 'done'
Q1=$(so_id blocked); Q2=$(so_id S03); [ -n "$Q1" ] && [ -n "$Q2" ] || fail 'the toy raised no two lines'
no() { so_qs sort "$T/s"; [ "$RC" != 0 ] || fail "a sort was taken: $1"; shift; for w; do grep -qF -- "$w" "$T/out" || fail "the refusal does not name: $w"; done; }
rest() { printf 'line waiting B1\nwho the bank\nwhat the answer\nsince Monday\n\nline suggested %s\nwhat a ticket can go out\n\n' "$Q2"; }
# nothing sorted yet
so_now; grep -qx 'state none' "$T/now" && [ "$(grep -c '^unsorted ' "$T/now")" = 3 ] || fail 'with no sort the state is not none, or an open item is not unsorted'
{ so_todo "$Q1" 'Unblock the ticket'; printf 'line waiting B1\nwho the bank\nwhat the answer\n'; } > "$T/s"; no 'an item in no line' "$Q2 is in no line"; [ ! -e "$SO" ] || fail 'a refused sort left a file'
{ so_todo "$Q1,$Q2" 'Unblock the ticket'; rest; } > "$T/s"; no 'an item in two lines' "$Q2 is in two lines"
{ so_todo "$Q1,Q99" 'Unblock the ticket'; rest; printf 'line changed B2\nwhat it is over\n'; } > "$T/s"; no 'ids not open' 'Q99 is not open' 'B2 is not open'
{ so_todo "$Q1" 'Unblock the ticket'; rest; so_todo - 'No item'; printf 'line later -\nwhat some day\n'; } > "$T/s"; no 'a todo and a later with none' 'a todo line holds no item' 'a later line holds no item'
# every reason in one refusal
{ so_todo "Q98" 'Unblock the ticket'; so_todo "$Q2" 'Publish it'; rest; } > "$T/s"; no 'three faults' "$Q1 is in no line" "$Q2 is in two lines" 'Q98 is not open'; grep -q 'not sorted: 3' "$T/out" || fail 'a refused first sort does not say not sorted'
# a whole one
{ printf '\nrelease 1 the first release is nearly in\n'; so_todo "$Q1" 'Unblock the ticket'; rest; printf 'line changed -\nwhat The bank\twrote back\n\nline vid -\nwhat ViD reads the report\n\nname ana-l Ana\n'; } > "$T/s"
so_ok sort "$T/s"; tail -n 1 "$T/out" | grep -qx '1 thing for you; first: Unblock the ticket' || fail 'the sort does not end with its line'
sed -n 1p "$SO" | grep -qE '^sorted 20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' || fail 'the sort has no time'
for l in "line todo $Q1" 'line waiting B1' "line suggested $Q2" 'line changed -' 'line vid -' 'what The bank wrote back' 'release 1 the first release is nearly in' 'name ana-l Ana' 'choose 1 it is the smaller change'; do grep -qxF -- "$l" "$SO" || fail "the sort lacks: $l"; done
[ ! -e "$SO.prev" ] || fail 'a first sort kept one before it'
so_now; grep -qx 'state sorted' "$T/now" && ! grep -q '^unsorted' "$T/now" && grep -qxF "line todo 1.1 $Q1" "$T/now" && ! grep -q '^sum ' "$T/now" || fail 'queue.sh sorted does not give the sort as it stands'
# a refused one after it changes nothing
cp "$SO" "$T/was"; printf 'line todo %s\n' "$Q1" > "$T/s"; no 'half a sort' "$Q2 is in no line"; cmp -s "$T/was" "$SO" || fail 'a refused sort changed the one kept'
# the file itself, sorted again from the standard input, is taken; the one before is kept
cp "$SO" "$T/was"; RC=0; sh "$QS" sort - < "$T/was" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail 'the sort kept is not taken again from the standard input'
cmp -s "$T/was" "$SO.prev" || fail 'the sort before is not kept'; sed 1d "$T/was" > "$T/a"; sed 1d "$SO" > "$T/b"; cmp -s "$T/a" "$T/b" || fail 'the same sort, sorted again, is another'
# the backlog is untouched by a sort; nothing in develop
[ "$(awk -F'\t' '$3 != "done"' "$B" | grep -c .)" = 3 ] || fail 'a sort changed the backlog'
mkdir -p "$T/plain/.vid/decide/queue"; cd "$T/plain"; git init -q; printf 'mode: develop\nrun: active\n' > .vid/RUN-STATE.md; so_qs sort "$T/s"; [ "$RC" != 0 ] && [ ! -e "$SO" ] || fail 'a develop project took a sort'
echo 'sort-coverage: ok'

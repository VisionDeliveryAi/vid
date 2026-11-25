#!/bin/sh
# Purpose: selftest case — a number means one line (FB-5 A1, S2). A todo line's number is its place at the sort, 1.1, 1.2, …; one that
# closed leaves its number unused, and the others keep theirs until the next sort, which numbers again from 1.1; a line of several ids
# stands, with those still open, until the last closes; `next:` is the first that stands, and the list is written again once an item closes.
# A line the last sort put under Changed is said once: after the owner's next call its words are gone, its item still where it was, and
# so is a line's `new`. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-numbers: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
for i in 1 2 3 4 5; do so_ok backlog add "item $i"; done
{ so_todo B1 'One'; so_todo B2,B3 'Two' | sed 's/^what/new Ann, Monday\nwhat/'; so_todo B4 'Three'; printf 'line changed B5\nwhat the bank wrote\n\nline changed -\nwhat a page moved\n'; } > "$T/s"; so_ok sort "$T/s"
nums() { so_now; awk '$1 == "line" && $2 == "todo" { print $3 ":" $4 }' "$T/now" | paste -sd ' ' -; }
nx() { sh "$QS" backlog > "$T/out" 2>&1 || fail 'queue.sh backlog failed'; grep '^next: ' "$T/out"; }
[ "$(nums)" = '1.1:B1 1.2:B2,B3 1.3:B4' ] || fail "the numbers are $(nums)"; nx | grep -q '^next: 1\.1 · One · Say which' || fail "the next line is $(nx)"
so_ok backlog set B1 --state 'done'; [ "$(nums)" = '1.2:B2,B3 1.3:B4' ] || fail "with 1.1 closed the numbers are $(nums)"; nx | grep -q '^next: 1\.2 · Two' || fail "with 1.1 closed the next is $(nx)"
so_ok backlog set B2 --state 'done'; [ "$(nums)" = '1.2:B3 1.3:B4' ] || fail "a line with one of two closed stands as $(nums)"
so_ok backlog set B3 --state 'done'; [ "$(nums)" = '1.3:B4' ] || fail "with 1.2 closed the numbers are $(nums)"
so_now; ! grep -q '^unsorted' "$T/now" || fail 'a closed item counts as not sorted'
# said once
so_raise < /dev/null; so_now; ! grep -q 'the bank wrote\|a page moved' "$T/now" || fail 'a changed line is shown after the next call'; grep -qxF 'line changed - B5' "$T/now" || fail 'the changed line'"'"'s open item is nowhere'
{ so_todo B4 'Three' | sed 's/^what/new Ann, Monday\nwhat/'; printf 'line changed B5\nwhat the bank wrote back\n'; } > "$T/s"; so_ok sort "$T/s"; [ "$(nums)" = '1.1:B4' ] || fail "the next sort numbers $(nums)"; grep -qx 'new Ann, Monday' "$T/now" && grep -q 'the bank wrote back' "$T/now" || fail 'what is new or changed is not shown after its sort'
so_raise < /dev/null; so_now; ! grep -q '^new ' "$T/now" && grep -qxF 'line todo 1.1 B4' "$T/now" || fail 'what is new is still said after the next call'
# nothing left
so_ok backlog set B4 --state 'done'; nx | grep -qx 'next: none · nothing is yours now' || fail "with none left the next is $(nx)"
# the list is written wherever the backlog is, and after a sort or a placing, by next-page.sh beside the script
mkdir "$T/c"; cp "$CHECKS"/*.sh "$T/c/"; printf '#!/bin/sh\necho "$*" >> "%s/calls"\nexit 1\n' "$T" > "$T/c/next-page.sh"; QS=$T/c/queue.sh; : > "$T/calls"
so_ok backlog add 'item 6'; [ "$(cat "$T/calls")" = write ] || fail 'the list is not written with the backlog'
: > "$T/calls"; so_ok sync; [ ! -s "$T/calls" ] || fail 'a sync that changed nothing wrote the list'
{ printf 'line later B5\nwhat five\nthen in spring\n'; so_todo B6 'Six'; } > "$T/s"; so_ok sort "$T/s"; [ "$(cat "$T/calls")" = write ] || fail 'a sort does not write the list'
: > "$T/calls"; so_ok backlog set B6 --state 'done'; [ "$(cat "$T/calls")" = write ] || fail 'a closed item does not write the list'
: > "$T/calls"; so_ok backlog set B5 --place top; [ "$(cat "$T/calls")" = write ] || fail 'a placing does not write the list'
echo 'sort-numbers: ok'

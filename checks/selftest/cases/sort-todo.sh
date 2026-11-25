#!/bin/sh
# Purpose: selftest case — a todo line is whole (FB-5 A1, S2). A todo line without its title, do, what or then, or with no ask that has a
# choice or a message, is refused, each part it lacks named, with its ids; another section owes none of them. Its one line: `1 thing
# for you`, `<n> things for you; first: <title>`, `nothing is yours now` with no item unsorted, and `not sorted` when one is. Env:
# CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-todo: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
so_ok backlog add 'the first'; so_ok backlog add 'the second'
two() { printf 'line later B2\nwhat the second\nthen in spring\n'; }
try() { so_todo B1 'Pick one' | grep -v "^$1" > "$T/s"; two >> "$T/s"; so_qs sort "$T/s"; }
for p in title 'do' what then; do try "$p "; [ "$RC" != 0 ] || fail "a todo with no $p was taken"; grep -qF "the todo line B1 lacks $p" "$T/out" || fail "the refusal does not say it lacks $p"; done
try 'ask'; [ "$RC" != 0 ] && grep -q 'lacks an ask' "$T/out" || fail 'a todo with no ask was taken, or not said'
try 'choice'; [ "$RC" != 0 ] && grep -q 'lacks an ask' "$T/out" || fail 'a todo whose ask has no choice and no message was taken'
{ printf 'line todo B1\ntitle\ndo\n'; two; } > "$T/s"; so_qs sort "$T/s"; [ "$RC" != 0 ] && grep -q 'lacks title, do, what, then, an ask' "$T/out" || fail 'a bare todo is not told all it lacks'
{ so_todo B1 'Send it' | grep -v '^choice\|^choose' | sed 's/^ask .*/ask Send this?\nmessage Hello, the page is ready./'; two; } > "$T/s"; so_ok sort "$T/s"
tail -n 1 "$T/out" | grep -qx '1 thing for you; first: Send it' || fail 'one thing is not said as one'
{ so_todo B1 'Send it'; so_todo B2 'Pick the day'; } > "$T/s"; so_ok sort "$T/s"; tail -n 1 "$T/out" | grep -qx '2 things for you; first: Send it' || fail 'two things are not said'
{ printf 'line waiting B1\nwho Ann\nwhat the day\nsince Monday\n'; two; } > "$T/s"; so_ok sort "$T/s"; tail -n 1 "$T/out" | grep -qx 'nothing is yours now' || fail 'with none it does not say nothing is yours now'
so_ok backlog add 'the third'; printf 'line todo B1\n' > "$T/s"; so_qs sort "$T/s"; [ "$RC" != 0 ] && tail -n 1 "$T/out" | grep -qx 'not sorted: 1' || fail 'a refused sort with an item unsorted does not say not sorted'
! grep -q 'nothing is yours now' "$T/out" || fail 'nothing is yours now, with an item unsorted'
echo 'sort-todo: ok'

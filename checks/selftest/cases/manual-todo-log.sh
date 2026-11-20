#!/bin/sh
# Purpose: selftest case — the to-do list and its log, .vid/next/todo (GM-2 T12, §5). On the toy (fixtures/plan-page.sh), call 1's
# lines raise three to-dos: the critical trigger blocked #3 (first, as a critical trigger), the answer move answer #2:1 and the
# publish move publish S04; each is logged `appeared` and is on the page's list. Then the answer move's done is written by calling
# `next-page.sh todo-done answer #2:1 move`, as the move runner (GM-2 T10, built in its own lane) calls it after each move it does;
# publish S04 is marked done in the owner's words (a " in them kept as '); a to-do not on the list is refused in words. Call 2's
# lines no longer raise the question or the trigger (the label taken off) and still raise publish S04 unchanged: the list is
# empty, and the trigger is logged done by `records`. Call 3, the same lines: nothing comes back, and the log gains no line. Call
# 4: S04's move changed (a new hash) comes back, `appeared` again. Call 5: with a part of the read unread, a to-do the lines no
# longer raise stays on the list. Call 6, call 1's lines again: the trigger and the answer, which left because nothing raised
# them, are raised again unchanged and are back on the list. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-todo-log: $*" >&2; cat "$T/pw" >&2 2>/dev/null; cat .vid/next/todo >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
pp_toy "$T/toy"; pp_scene
printf 'issue\t3\tvid:blocked\t-\t2026-11-18T09:00:00Z\n' >> .vid/next/read
pp_trig "$T/base"
{ cat "$T/base"; printf 'trigger\tcritical\tblocked\t#3\tlabel vid:blocked\n'
  printf 'question\t#2:1\tQuestion: may the limit be twenty?\n'
  printf 'move\tpublish\tS04\th-s04\tpublish step S04\nmove\tanswer\t#2:1\th-q1\tan answer, or there\n'; } > "$T/c1"
{ cat "$T/base"; printf 'move\tpublish\tS04\th-s04\tpublish step S04\n'; } > "$T/c2"
{ cat "$T/base"; printf 'move\tpublish\tS04\th-s04b\tpublish step S04\n'; } > "$T/c4"
{ cat "$T/base"; printf 'unread\tticket\t2\tgh failed\n'; } > "$T/c5"
todo() { grep -o 'data-todo="[^"]*"' "$PG" | sed 's/^data-todo="//; s/"$//' | paste -sd ',' -; }
# call 1
pp_write "$T/c1"; [ "$PP_RC" = 0 ] || fail "call 1's write failed ($PP_RC)"
[ "$(todo)" = 'blocked #3,publish S04,answer #2:1' ] || fail "call 1's to-do list is '$(todo)', not the trigger first, then the two moves"
[ "$(awk -F'\t' '$2 == "appeared" { print $3 "|" $4 }' .vid/next/todo | paste -sd ',' -)" = "blocked #3|$(printf 'trigger\tcritical\tblocked\t#3\tlabel vid:blocked\n' | git hash-object --stdin),publish S04|h-s04,answer #2:1|h-q1" ] || fail 'call 1 did not log each to-do appeared, with its hash'
grep -q 'may the limit be twenty' "$PG" || fail "the answer's to-do does not show the question"
# the answer move done, as the move runner calls it; S04 done in words; one not on the list refused
sh "$CHECKS/next-page.sh" todo-done answer '#2:1' move > "$T/pw" 2>&1 || fail 'todo-done of the answer move failed'
sh "$CHECKS/next-page.sh" todo-done publish S04 words 'the team asked to wait, "for now"' > "$T/pw" 2>&1 || fail 'todo-done in words failed'
if sh "$CHECKS/next-page.sh" todo-done publish S05 words 'no such to-do' > "$T/pw" 2>&1; then fail 'a to-do not on the list was marked done'; fi
grep -q 'refused' "$T/pw" || fail 'the refusal does not say so'
grep -q "${TB}done${TB}answer #2:1${TB}h-q1${TB}move${TB}-\$" .vid/next/todo || fail "the answer's done line is not the move's"
grep -q "${TB}done${TB}publish S04${TB}h-s04${TB}words${TB}the team asked to wait, 'for now'\$" .vid/next/todo || fail "S04's done line does not hold the owner's words"
# call 2: the question answered, the label off, S04 raised unchanged
pp_write "$T/c2"; [ "$PP_RC" = 0 ] || fail "call 2's write failed ($PP_RC)"
[ -z "$(todo)" ] || fail "call 2's list holds '$(todo)'"
grep -q "${TB}done${TB}blocked #3${TB}.*${TB}records${TB}-\$" .vid/next/todo || fail 'the trigger the lines no longer raise is not logged done by records'
n=$(grep -c . .vid/next/todo)
# call 3: the same lines; nothing comes back
pp_write "$T/c2"; [ "$PP_RC" = 0 ] || fail "call 3's write failed ($PP_RC)"
[ -z "$(todo)" ] && [ "$(grep -c . .vid/next/todo)" = "$n" ] || fail "a done to-do came back at call 3 ('$(todo)')"
# call 4: S04's move changed comes back
pp_write "$T/c4"; [ "$PP_RC" = 0 ] || fail "call 4's write failed ($PP_RC)"
[ "$(todo)" = 'publish S04' ] && tail -n 1 .vid/next/todo | grep -q "${TB}appeared${TB}publish S04${TB}h-s04b${TB}" || fail "S04's changed move did not come back ('$(todo)')"
# call 5: a read in part unread marks nothing done by the records
pp_write "$T/c5"; [ "$PP_RC" = 0 ] || fail "call 5's write failed ($PP_RC)"
[ "$(todo)" = 'publish S04' ] && ! tail -n 1 .vid/next/todo | grep -q "${TB}records${TB}" || fail 'a to-do was marked done by the records with the read unread in part'
# call 6: call 1's lines again; what left because nothing raised it comes back, raised again unchanged
pp_write "$T/c1"; [ "$PP_RC" = 0 ] || fail "call 6's write failed ($PP_RC)"
case ",$(todo)," in *',blocked #3,'*',answer #2:1,'*) ;; *) fail "call 6's list is '$(todo)': a to-do raised again after it left is not back" ;; esac
exit 0

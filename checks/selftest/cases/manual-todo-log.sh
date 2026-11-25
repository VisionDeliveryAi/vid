#!/bin/sh
# Purpose: selftest case — the to-do list (GM-2 T12, onto GM-4 F4: the owner's queue holds it; no .vid/next/todo; FB-5 A1: what is open
# is `queue.sh open`, no page). On the toy (fixtures/plan-page.sh), call 1's lines raise two to-dos: the critical trigger blocked #3 and
# the publish move publish S04; the call's raise (queue.sh raise) makes each a `Q<n>` line, and the list holds both.
# publish S04 is taken off the list in the owner's words (`queue.sh answer Q<n> done "<words>"`, recorded in the queue's answers); one
# with no words is refused. Call 2's lines no longer raise the trigger (the label taken off) and raise publish S04 unchanged: the list is
# empty. Call 3, the same lines: nothing comes back. Call 4: S04's move changed (a new hash) comes back. Call 5: with a part of the read
# unread, a to-do the lines no longer raise stays on the list. Call 6, call 1's lines again: the trigger, and S04 at its first hash, which
# left because nothing raised them, are raised anew and back on the list. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-todo-log: $*" >&2; cat "$T/pw" >&2 2>/dev/null; cat .vid/decide/queue/raised >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
pp_toy "$T/toy"; pp_scene
printf 'issue\t3\tvid:blocked\t-\t2026-11-18T09:00:00Z\n' >> .vid/round/read
pp_trig "$T/base"
{ cat "$T/base"; printf 'trigger\tcritical\tblocked\t#3\tlabel vid:blocked\n'
  printf 'move\tpublish\tS04\th-s04\tpublish step S04\n'; } > "$T/c1"
{ cat "$T/base"; printf 'move\tpublish\tS04\th-s04\tpublish step S04\n'; } > "$T/c2"
{ cat "$T/base"; printf 'move\tpublish\tS04\th-s04b\tpublish step S04\n'; } > "$T/c4"
{ cat "$T/base"; printf 'unread\tticket\t2\tgh failed\n'; } > "$T/c5"
todo() { sh "$CHECKS/queue.sh" open 2> "$T/pw" | awk -F'\t' 'NF > 5 { n = split($6, a, ":"); s = a[n]; sub(/@[0-9]+$/, "", s); print a[2] " " s }' | sort | paste -sd ',' -; }
call() { sh "$CHECKS/queue.sh" raise "$1" > "$T/pw" 2>&1 || fail "the raise of $1 failed"; }
qof() { sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/pw" || fail 'queue.sh list failed'; awk -F'\t' -v p="$1" 'index($2, p) == 1 { print $1; exit }' "$T/ql"; }
# call 1
call "$T/c1"
[ "$(todo)" = 'blocked #3,publish S04' ] || fail "call 1's to-do list is '$(todo)', not the trigger and the move"
QS4=$(qof move:publish:); [ -n "$QS4" ] || fail "publish S04 is no Q line: $(cat "$T/ql")"
# S04 off the list in the owner's words; none without words
RC=0; sh "$CHECKS/queue.sh" answer "$QS4" done '' > "$T/pw" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a done with no words was taken'
sh "$CHECKS/queue.sh" answer "$QS4" done 'the team asked to wait, "for now"' > "$T/pw" 2>&1 || fail 'the done in words failed'
grep -q "${TB}move:publish:h-s04:S04@[0-9]*${TB}done${TB}the team asked to wait, \"for now\"${TB}owner${TB}done\$" .vid/decide/queue/answers || fail "S04's done does not hold the words given, as recorded: $(cat .vid/decide/queue/answers)"
[ ! -e .vid/next/todo ] || fail 'a to-do log was kept beside the queue'
# call 2: the label off, S04 raised unchanged
call "$T/c2"; [ -z "$(todo)" ] || fail "call 2's list holds '$(todo)'"
# call 3: the same lines; nothing comes back
call "$T/c2"; [ -z "$(todo)" ] || fail "a done to-do came back at call 3 ('$(todo)')"
# call 4: S04's move changed comes back
call "$T/c4"; [ "$(todo)" = 'publish S04' ] || fail "S04's changed move did not come back ('$(todo)')"
# call 5: a read in part unread drops nothing
call "$T/c5"; [ "$(todo)" = 'publish S04' ] || fail "a to-do left the list with the read unread in part ('$(todo)')"
# call 6: call 1's lines again; what left because nothing raised it comes back
call "$T/c1"
[ "$(todo)" = 'blocked #3,publish S04' ] || fail "call 6's list is '$(todo)': a to-do raised again after it left is not back"
[ ! -e .vid/next/todo ] || fail 'a to-do log was kept beside the queue'
exit 0

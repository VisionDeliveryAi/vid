#!/bin/sh
# Purpose: selftest case — the owner's and the session's own backlog items, and the marks (FB-3 D1). `queue.sh backlog add "<words>"
# [--who --next --note]` is a B<n> at the end, in no RUN-STATE line and not in its count; `backlog set <id>` changes its state, who,
# next action, note and place (top, after <id>); one item at most is doing, setting one puts the other back to do; `done` ends a
# B<n>, kept; `done` on a Q<n> is refused, its answer named; no sync loses a set; a plan with no step is said as 0 steps; an unknown state, id or option, an item with no
# words, and a project with no ticket mode are refused, the file byte for byte as it was. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "backlog-own: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/backlog >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
B=.vid/decide/queue/backlog; QS=$CHECKS/queue.sh
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "queue.sh $* exited $RC"; }
no() { cp "$B" "$T/was"; RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "queue.sh $* was taken"; cmp -s "$T/was" "$B" || fail "a refused queue.sh $* changed the backlog"; }
ids() { awk -F'\t' '$3 != "done" { print $1 }' "$B" | paste -sd ' ' -; }
v() { awk -F'\t' -v i="$1" -v n="$2" '$1 == i { print $n; exit }' "$B"; }
qs ask own 'Which colour is the footer?'; [ "$(ids)" = Q1 ] || fail "ViD's own question is not the backlog's first line"
qs backlog add 'push the branch'; qs backlog add 'wait for Ann' --who Ann --next 'ask again on Friday' --note 'asked on Monday'
qs backlog add 'decide the export'
[ "$(ids)" = 'Q1 B1 B2 B3' ] || fail "the items are $(ids), not in the order they came"
[ "$(v B1 4)|$(v B1 6)|$(v B1 7)" = 'you|-|-' ] && [ "$(v B2 4)|$(v B2 6)|$(v B2 7)" = 'Ann|ask again on Friday|asked on Monday' ] || fail 'the who, the next action or the note is not as given'
! grep -q 'push the branch' .vid/RUN-STATE.md && grep -q '^questions: 1 open' .vid/RUN-STATE.md || fail 'an own item is in RUN-STATE or its count'
# order and marks
qs backlog set B3 --place top; [ "$(ids)" = 'B3 Q1 B1 B2' ] || fail "B3 on top gives $(ids)"
qs backlog set Q1 --place after B2; [ "$(ids)" = 'B3 B1 B2 Q1' ] || fail "Q1 after B2 gives $(ids)"
qs backlog set B1 --state doing; qs backlog set Q1 --state doing
[ "$(v B1 3)|$(v Q1 3)" = 'to do|doing' ] && [ "$(awk -F'\t' '$3 == "doing"' "$B" | grep -c .)" = 1 ] || fail 'two items are doing, or the one before was not put back'
qs backlog set B3 --state waiting --note 'on the bank, asked on Tuesday' --who 'the bank'; qs backlog set B1 --state aside
cp "$B" "$T/b"; qs sync; qs list; cmp -s "$T/b" "$B" || fail 'a sync lost a set'
sh "$QS" backlog > "$T/out" 2>&1 || fail 'queue.sh backlog failed'
[ "$(grep '^[QB][0-9]' "$T/out" | cut -f1 | paste -sd ' ' -)" = 'B3 B1 B2 Q1' ] && grep '^next: ' "$T/out" | grep -qx 'next: B2 · wait for Ann · ask again on Friday · Ann' || fail 'the list or its next: is not the top open item neither waiting nor aside'
grep '^5\. The plan: ' "$T/out" | grep -q ', 0 steps, ' || fail 'a plan with no step is not said as 0 steps'
# done
qs backlog set B2 --state 'done' --note 'she answered'; [ "$(v B2 3)|$(v B2 7)" = 'done|she answered' ] && [ "$(v B2 9)" != - ] && [ "$(ids)" = 'B3 B1 Q1' ] || fail 'B2, done, is open, gone or has no end'
no backlog set Q1 --state 'done'; grep -q 'answer Q1' "$T/out" || fail 'done on a Q line does not name its answer'
no backlog set B1 --state maybe; no backlog set B9 --state doing; no backlog set B1 --colour red; no backlog set B1 --place after B9; no backlog set B1 --place after B1; no backlog set B1; no backlog add ''; no backlog add '  '; no backlog frob
qs backlog add "$(printf 'two\tlines\nof words')"; [ "$(v B4 5)" = 'two lines of words' ] || fail 'a tab or a new line in the words broke the line'
# no ticket mode: none
mkdir "$T/plain"; cd "$T/plain"; git init -q; mkdir -p .vid; printf 'mode: develop\nrun: active\n' > .vid/RUN-STATE.md; mkdir -p .vid/decide/queue; : > "$B"
no backlog add 'x'; no backlog
exit 0

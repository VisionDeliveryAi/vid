#!/bin/sh
# Purpose: selftest case — a question the owner answered on GitHub himself (GM-2 T8). On GitHub manual's toy and the fake
# gh, published ticket #A holds the team's question, a `Q` line after `queue.sh sync`. `queue.sh answer <A>:1 there "<words>"`
# posts nothing to GitHub (the fake's write log stays empty) and records `there` in the queue's answers (GM-4 F4: one answer
# record, every question the owner's by the `owner-questions: all` setting); at the next call, the question still on the issue
# with no RM: answer, it is neither listed by `queue.sh list` nor a `Q` line, and next.sh lists no question of its own. A `there` with no words, or with none after it, is refused, posting nothing. A second
# question, whose line holds backslashes, is answered there too, and is not listed at the next call. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-there: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
A=$(gh_issue 'Step S02'); printf 'Question: ROW-001, is a digest sent on a public holiday?\n' > "$T/c"; gh issue comment "$A" -R $R --body-file "$T/c" > /dev/null
printf '%s\n' 'Question: ROW-005, is the feed read from C:\feeds\daily?' > "$T/c"; gh issue comment "$A" -R $R --body-file "$T/c" > /dev/null
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'queue.sh sync failed'
  sh "$CHECKS/queue.sh" list > "$T/tr" 2> "$T/out" || fail 'queue.sh list failed'; }
qline() { awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md | grep -F "$1"; }
call; qline "gates #$A · Question: ROW-001, is a digest sent on a public holiday?" > /dev/null || fail "#$A's question is no Q line"
grep -q "^Q[0-9]*${TB}question:$A:1${TB}" "$T/tr" || { cat "$T/tr" >&2; fail "#$A's question is not listed"; }
gh_wclear
RC=0; sh "$CHECKS/queue.sh" answer "$A:1" there > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a there with nothing after it was taken'
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'a there with nothing after it posted to GitHub'; }
RC=0; sh "$CHECKS/queue.sh" answer "$A:1" there '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a there with no words was taken'
sh "$CHECKS/queue.sh" answer "$A:1" there 'I answered it in the thread: yes, every day' > "$T/out" 2>&1 || fail 'the there answer was refused'
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'an answer given there posted to GitHub'; }
grep -q "^Q[0-9]*${TB}question:$A:2${TB}.*${TB}Question: ROW-005, is the feed read from C:" "$T/tr" || fail "#$A's question with backslashes is not listed as $A:2"
sh "$CHECKS/queue.sh" answer "$A:2" there 'Answered in the thread: no, from the drop folder' > "$T/out" 2>&1 || fail "#$A:2, its line holding backslashes, could not be answered: $(cat "$T/out")"
grep -q "^[^$TB]*${TB}question:$A:2${TB}there${TB}" .vid/decide/queue/answers || fail "#$A:2's answer is not recorded"
grep -q "^[^$TB]*${TB}question:$A:1${TB}there${TB}I answered it in the thread: yes, every day${TB}owner${TB}answered there\$" .vid/decide/queue/answers || fail "the answer is not recorded there: $(cat .vid/decide/queue/answers 2>/dev/null)"
[ ! -e .vid/next/questions ] || fail 'a second answer record, .vid/next/questions, was written'
call
! grep -q "${TB}question:$A:[12]${TB}" "$T/tr" || { cat "$T/tr" >&2; fail 'a question answered there is listed again'; }
sh "$CHECKS/next.sh" triggers > "$T/nt" 2> "$T/out" || fail 'next.sh triggers failed'
! grep -q "^question${TB}\|^move${TB}answer${TB}" "$T/nt" || fail 'next.sh lists questions of its own'
! qline 'is a digest sent on a public holiday' > /dev/null || fail 'a question answered there is still a Q line'
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'the next call posted to GitHub'; }
exit 0

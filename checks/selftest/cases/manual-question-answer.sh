#!/bin/sh
# Purpose: selftest case — the team's questions answered (GM-2 T8). On GitHub manual's toy and the fake gh, ticket #A
# published with a sub-issue #U, labelled vid:blocked, holding the team's question; #A holds two questions of its own, the
# second in a role's form. After `next.sh read`, `queue.sh sync` makes each question a `Q` line, posting nothing (no
# waits-on-the-lead comment); `next.sh triggers` lists each as `question #<n>:<k>`, k its place among the issue's questions,
# with its `answer` move. `queue.sh answer <U>:1 "<words>"` posts one `RM:` comment quoting the question, then the words,
# takes the blocked label off and records `posted` in .vid/next/questions; the same answer again is refused, posting nothing;
# an answer with no words is refused. The second question on #A is answered by its own place, quoting it. At the next call the
# answers are not questions, the answered ones are neither listed nor `Q` lines, and #A's first stays. #A's
# questions sit at comments 2 and 4, and a record kept from GitHub auto holds key <A>:2 for the first (its comment place), so
# the second, #A:2 by its place among the questions, is still a `Q` line and its answer quotes it; issue #B holds a question,
# a longer one beginning with its words, and an RM: answer quoting the longer: the shorter is a `Q` line and listed, the
# longer neither. The second question on #A, recorded <A>:q2, is answered by its `Q` line's name and quotes
# itself; at the end the first, held by the GitHub auto record <A>:2, is answered by its `Q` name too, quoting ROW-005, its
# place #A:1 recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-answer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
A=$(gh_issue 'Step S02'); U=$(gh_issue 'a unit of S02'); gh_sub "$A" "$U"
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$U" 'vid: claimed'; cm "$U" 'Question: ROW-001, may a digest with no new job be sent? Default: none is sent.'; gh issue edit "$U" -R $R --add-label vid:blocked > /dev/null
cm "$A" 'a note on the plan'; cm "$A" 'Question: ROW-005, which feed is read first?'; cm "$A" 'a second note'; cm "$A" 'TL: question on ROW-001, are the newest jobs first?'
# a record kept from GitHub auto, keyed by the comment's place: <A>:2 is #A's first question there
mkdir -p .vid/decide/queue; printf '%s:2\t%s\tQuestion: ROW-005, which feed is read first?\tseen\n' "$A" "$A" > .vid/decide/queue/questions
B=$(gh_issue 'Step S04'); cm "$B" 'Question: ROW-008, is the trigger daily?'; cm "$B" 'Question: ROW-008, is the trigger daily? If so, at what hour?'
printf 'RM: Question: ROW-008, is the trigger daily? If so, at what hour?\n\nAt six.\n' > "$T/c"; gh issue comment "$B" -R $R --body-file "$T/c" > /dev/null
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'queue.sh sync failed'
  sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; }
qline() { awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md | grep -F "$1"; }
ncom() { ls "$FAKEGH/issues/$1/comments" | grep -c .; }
gh_wclear; call
# every question a Q line, nothing posted
qline "gates #$U · Question: ROW-001, may a digest with no new job be sent?" > /dev/null || fail "#$U's question is no Q line: $(qline ' · ')"
qline "gates #$A · Question: ROW-005, which feed is read first?" > /dev/null || fail "#$A's first question is no Q line"
qline "gates #$A · TL: question on ROW-001, are the newest jobs first?" > /dev/null || fail "#$A's role-form question is no Q line"
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'the scan posted to GitHub'; }
# a question and a longer one beginning with its words, the longer answered: the shorter stays open
qline "gates #$B · Question: ROW-008, is the trigger daily?" | grep -q 'daily?$' || fail "#$B's open question, whose words begin an answered one, is no Q line"
! qline 'at what hour?' > /dev/null || fail "#$B's answered question is a Q line"
grep -qxF "question${TB}#$B:1${TB}Question: ROW-008, is the trigger daily?" "$T/tr" || { cat "$T/tr" >&2; fail "#$B's open question is not listed"; }
! grep -q "^question${TB}#$B:2${TB}" "$T/tr" || fail "#$B's answered question is listed"
# the listing: each question by its place among its issue's questions, with its answer move
grep -qxF "question${TB}#$U:1${TB}Question: ROW-001, may a digest with no new job be sent? Default: none is sent." "$T/tr" || { cat "$T/tr" >&2; fail "#$U's question is not listed as #$U:1"; }
grep -qxF "question${TB}#$A:2${TB}TL: question on ROW-001, are the newest jobs first?" "$T/tr" || { cat "$T/tr" >&2; fail "#$A's second question is not listed as #$A:2"; }
grep -q "^move${TB}answer${TB}#$U:1${TB}[0-9a-f]\{40\}${TB}" "$T/tr" || { cat "$T/tr" >&2; fail "no answer move named #$U:1, with its hash"; }
# the answer: one RM: comment, the label off, the record kept
C0=$(ncom "$U"); sh "$CHECKS/queue.sh" answer "$U:1" 'No: a digest with no new job is not sent' > "$T/out" 2>&1 || fail 'the answer was refused'
[ "$(ncom "$U")" = $((C0 + 1)) ] || fail "the answer did not post exactly one comment on #$U"
L=$FAKEGH/issues/$U/comments/$(ls "$FAKEGH/issues/$U/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: ROW-001, may a digest with no new job be sent? Default: none is sent.' ] || fail "the answer does not open RM: and the question: $(sed -n 1p "$L")"
grep -qxF 'No: a digest with no new job is not sent' "$L" || fail 'the answer does not hold the words'
! grep -qx 'vid:blocked' "$FAKEGH/issues/$U/labels" 2>/dev/null || fail "the blocked label stayed on #$U with no question open"
grep -q "^$U:1${TB}posted${TB}[0-9T:Z-]*${TB}No: a digest with no new job is not sent\$" .vid/next/questions || fail "the answer is not recorded posted: $(cat .vid/next/questions 2>/dev/null)"
# once only, and never unnamed
RC=0; sh "$CHECKS/queue.sh" answer "$U:1" 'again' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'the same question was answered twice'
[ "$(ncom "$U")" = $((C0 + 1)) ] || fail 'a second answer was posted'
C1=$(ncom "$A"); RC=0; sh "$CHECKS/queue.sh" answer "$A:1" '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'an answer with no words was taken'
[ "$(ncom "$A")" = "$C1" ] || fail 'an answer with no words was posted'
# the second question on #A, by its place
QTL=$(sed -n 's/^- \(Q[0-9]*\) · .*are the newest jobs first.*/\1/p' .vid/RUN-STATE.md); [ -n "$QTL" ] || fail "#$A's second question has no Q name"
sh "$CHECKS/queue.sh" answer "$QTL" 'Yes, newest first' > "$T/out" 2>&1 || fail "the answer to #$A's second question by its name $QTL was refused"
L=$FAKEGH/issues/$A/comments/$(ls "$FAKEGH/issues/$A/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: TL: question on ROW-001, are the newest jobs first?' ] || fail "#$A:2's answer does not quote its question: $(sed -n 1p "$L")"
# the next call: the answers are no questions; the answered ones gone, #A's first stays
call
! grep -q "^question${TB}#$U:" "$T/tr" || { cat "$T/tr" >&2; fail "#$U's answered question, or its answer, is listed"; }
! grep -q "^question${TB}#$A:[23]${TB}" "$T/tr" && ! grep -q "^question${TB}[^${TB}]*${TB}RM: " "$T/tr" || { cat "$T/tr" >&2; fail 'an answered question, or an RM: answer, is listed'; }
grep -q "^question${TB}#$A:1${TB}Question: ROW-005" "$T/tr" || fail "#$A's unanswered question is not listed"
! grep -q "^move${TB}answer${TB}#$U:1${TB}" "$T/tr" || fail "#$U:1 still has an answer move"
! qline 'may a digest with no new job be sent' > /dev/null || fail "#$U's answered question is still a Q line"
! qline 'are the newest jobs first' > /dev/null || fail "#$A's answered question is still a Q line"
qline 'which feed is read first' > /dev/null || fail "#$A's open question left the queue"
grep -q "^$A:2${TB}posted${TB}" .vid/next/questions || fail "the answer by $QTL is not recorded at #$A:2"
# the question the GitHub auto record <A>:2 holds, answered by its Q name: it quotes ROW-005, at its place #A:1
QF=$(sed -n 's/^- \(Q[0-9]*\) · .*which feed is read first.*/\1/p' .vid/RUN-STATE.md); [ -n "$QF" ] || fail "#$A's first question has no Q name"
sh "$CHECKS/queue.sh" answer "$QF" 'The listed feed first' > "$T/out" 2>&1 || fail "the answer by $QF was refused"
L=$FAKEGH/issues/$A/comments/$(ls "$FAKEGH/issues/$A/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: ROW-005, which feed is read first?' ] || fail "the answer by $QF does not quote ROW-005's question: $(sed -n 1p "$L")"
grep -q "^$A:1${TB}posted${TB}" .vid/next/questions || fail "the answer by $QF is not recorded at #$A:1"
exit 0

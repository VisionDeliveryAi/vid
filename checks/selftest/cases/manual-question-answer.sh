#!/bin/sh
# Purpose: selftest case — the team's questions answered (GM-2 T8, onto GM-4 F4's one queue). On GitHub manual's toy and the fake
# gh, with every question the owner's (`owner-questions: all`, the setting the switch writes), ticket #A published with a
# sub-issue #U, labelled vid:blocked, holding the team's question at its comment 2; #A holds two questions of its own, at
# comments 2 and 4, the second in a role's form. After `next.sh read`, `queue.sh sync` makes each question a `Q` line keyed
# <n>:<k>, k the comment's place (one key form in every mode), posting nothing (no waits-on-the-lead comment); `queue.sh list`
# lists each with its answers, and next.sh lists no question of its own. `queue.sh answer <U>:2 "<words>"` posts one `RM:`
# comment quoting the question, then the words, takes the blocked label off and records it in the queue's answers (no
# .vid/next/questions); the same answer again is refused, posting nothing; an answer with no words is refused. #A's second is
# answered by its `Q` name, quoting itself. Issue #B holds a question, a longer one beginning with its words, and an RM: answer
# quoting the longer whole: the shorter is a `Q` line, the longer not. At the next call the answered ones are neither listed
# nor `Q` lines, and #A's first stays. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-answer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
A=$(gh_issue 'Step S02'); U=$(gh_issue 'a unit of S02'); gh_sub "$A" "$U"
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$U" 'vid: claimed'; cm "$U" 'Question: ROW-001, may a digest with no new job be sent? Default: none is sent.'; gh issue edit "$U" -R $R --add-label vid:blocked > /dev/null
cm "$A" 'a note on the plan'; cm "$A" 'Question: ROW-005, which feed is read first?'; cm "$A" 'a second note'; cm "$A" 'TL: question on ROW-001, are the newest jobs first?'
B=$(gh_issue 'Step S04'); cm "$B" 'Question: ROW-008, is the trigger daily?'; cm "$B" 'Question: ROW-008, is the trigger daily? If so, at what hour?'
printf 'RM: Question: ROW-008, is the trigger daily? If so, at what hour?\n\nAt six.\n' > "$T/c"; gh issue comment "$B" -R $R --body-file "$T/c" > /dev/null
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'queue.sh sync failed'
  sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; }
qline() { awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md | grep -F "$1"; }
listed() { grep -q "^Q[0-9]*${TB}question:$1${TB}\"<words>\" | there \"<words>\"${TB}$2" "$T/ql"; }
ncom() { ls "$FAKEGH/issues/$1/comments" | grep -c .; }
gh_wclear; call
qline "gates #$U · Question: ROW-001, may a digest with no new job be sent?" > /dev/null || fail "#$U's question is no Q line: $(qline ' · ')"
qline "gates #$A · Question: ROW-005, which feed is read first?" > /dev/null || fail "#$A's first question is no Q line"
qline "gates #$A · TL: question on ROW-001, are the newest jobs first?" > /dev/null || fail "#$A's role-form question is no Q line"
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'the scan posted to GitHub'; }
qline "gates #$B · Question: ROW-008, is the trigger daily?" | grep -q 'daily?$' || fail "#$B's open question, whose words begin an answered one, is no Q line"
! qline 'at what hour?' > /dev/null || fail "#$B's answered question is a Q line"
listed "$U:2" 'Question: ROW-001, may a digest' && listed "$A:2" 'Question: ROW-005' && listed "$A:4" 'TL: question on ROW-001' && listed "$B:1" 'Question: ROW-008, is the trigger daily?$' || { cat "$T/ql" >&2; fail 'a question is not listed by its place with its answers'; }
! grep -q "^question${TB}\|^move${TB}answer${TB}" "$T/tr" || fail 'next.sh lists questions of its own'
# the answer: one RM: comment, the label off, the record kept in the queue
C0=$(ncom "$U"); sh "$CHECKS/queue.sh" answer "$U:2" 'No: a digest with no new job is not sent' > "$T/out" 2>&1 || fail 'the answer was refused'
[ "$(ncom "$U")" = $((C0 + 1)) ] || fail "the answer did not post exactly one comment on #$U"
L=$FAKEGH/issues/$U/comments/$(ls "$FAKEGH/issues/$U/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: ROW-001, may a digest with no new job be sent? Default: none is sent.' ] || fail "the answer does not open RM: and the question: $(sed -n 1p "$L")"
grep -qxF 'No: a digest with no new job is not sent' "$L" || fail 'the answer does not hold the words'
! grep -qx 'vid:blocked' "$FAKEGH/issues/$U/labels" 2>/dev/null || fail "the blocked label stayed on #$U with no question open"
grep -q "^[^$TB]*${TB}question:$U:2${TB}-${TB}No: a digest with no new job is not sent${TB}owner${TB}answered\$" .vid/decide/queue/answers || fail "the answer is not recorded: $(cat .vid/decide/queue/answers)"
[ ! -e .vid/next/questions ] || fail 'a second answer record, .vid/next/questions, was written'
# once only, and never with no words
RC=0; sh "$CHECKS/queue.sh" answer "$U:2" 'again' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'the same question was answered twice'
[ "$(ncom "$U")" = $((C0 + 1)) ] || fail 'a second answer was posted'
C1=$(ncom "$A"); RC=0; sh "$CHECKS/queue.sh" answer "$A:2" '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'an answer with no words was taken'
[ "$(ncom "$A")" = "$C1" ] || fail 'an answer with no words was posted'
# the second question on #A, by its Q name
QTL=$(sed -n 's/^- \(Q[0-9]*\) · .*are the newest jobs first.*/\1/p' .vid/RUN-STATE.md); [ -n "$QTL" ] || fail "#$A's second question has no Q name"
sh "$CHECKS/queue.sh" answer "$QTL" 'Yes, newest first' > "$T/out" 2>&1 || fail "the answer to #$A's second question by its name $QTL was refused"
L=$FAKEGH/issues/$A/comments/$(ls "$FAKEGH/issues/$A/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: TL: question on ROW-001, are the newest jobs first?' ] || fail "#$A:4's answer does not quote its question: $(sed -n 1p "$L")"
# the next call: the answers are no questions; the answered ones gone, #A's first stays
call
! grep -q "${TB}question:$U:\|${TB}question:$A:4${TB}" "$T/ql" || { cat "$T/ql" >&2; fail 'an answered question is listed'; }
! grep -q "${TB}RM: " "$T/ql" || fail 'an RM: answer is listed as a question'
listed "$A:2" 'Question: ROW-005' || fail "#$A's unanswered question is not listed"
! qline 'may a digest with no new job be sent' > /dev/null || fail "#$U's answered question is still a Q line"
! qline 'are the newest jobs first' > /dev/null || fail "#$A's answered question is still a Q line"
qline 'which feed is read first' > /dev/null || fail "#$A's open question left the queue"
exit 0

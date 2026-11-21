#!/bin/sh
# Purpose: selftest case — an answer never goes out against a question that changed (GM-4 F4, K6; GM M16: a named move whose
# content changed since the listing is shown again, not done). On GitHub manual's toy and the fake gh, every question the owner's:
# #A holds two team questions, at comments 1 and 2. After a call's read and listing, the team edits the first and deletes the
# second. At the next call's read, `queue.sh answer` of the first, by its Q name, is refused, nothing posted and nothing recorded;
# the listing then shows it with its new words (the scan compares a known key's words), and the answer posts quoting them. The
# second, deleted, is refused a posted answer, nothing posted, the refusal naming `there`; answered `there`, it is recorded and
# its line leaves. A question on #B, closed since its listing (the read holds no line for #B), is answered and posted as before.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-changed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
A=$(gh_issue 'Step S02')
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$A" 'Question: ROW-005, which feed is read first?'; cm "$A" 'Question: ROW-008, is the trigger daily?'
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
B=$(gh_issue 'a team question'); cm "$B" 'Question: is the footer shown on every digest?'
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; }
ncom() { ls "$FAKEGH/issues/$1/comments" | grep -c .; }
qof() { awk -F'\t' -v k="question:$1" '$2 == k { print $1; exit }' "$T/ql"; }
call; Q1=$(qof "$A:1"); Q2=$(qof "$A:2"); QB=$(qof "$B:1"); [ -n "$Q1" ] && [ -n "$Q2" ] && [ -n "$QB" ] || { cp "$T/ql" "$T/out"; fail 'the three questions are not Q lines'; }
# the team edits the first and deletes the second, and closes #B; the next call's read
printf 'Question: ROW-005, which feed is read first, the new one or the old one?\n' > "$FAKEGH/issues/$A/comments/1"; rm "$FAKEGH/issues/$A/comments/2"; gh_attr "$B" state CLOSED
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
C0=$(ncom "$A"); RC=0; sh "$CHECKS/queue.sh" answer "$Q1" 'The new one first' > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'an answer to a question the team changed since its listing was taken'
[ "$(ncom "$A")" = "$C0" ] || fail 'an answer to a changed question was posted'
! grep -q "${TB}question:$A:1${TB}" .vid/decide/queue/answers || fail 'an answer to a changed question was recorded'
RC=0; sh "$CHECKS/queue.sh" answer "$Q2" 'Daily, at six' > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] && [ "$(ncom "$A")" = "$C0" ] || fail 'an answer to a question gone from the read was taken, or posted'
! grep -q "${TB}question:$A:2${TB}" .vid/decide/queue/answers || fail 'an answer to a question gone from the read was recorded'
grep -q 'there' "$T/out" || fail "the refusal of a posted answer to a deleted question does not name there: $(cat "$T/out")"
# the deleted one closed by there, nothing posted; the one on #B, closed since its listing, answered as before
sh "$CHECKS/queue.sh" answer "$Q2" there 'Answered on the thread, daily' > "$T/out" 2>&1 || fail "the deleted question answered there was refused: $(cat "$T/out")"
[ "$(ncom "$A")" = "$C0" ] && grep -q "${TB}question:$A:2${TB}there${TB}" .vid/decide/queue/answers || fail 'the deleted question answered there posted, or was not recorded'
CB=$(ncom "$B"); sh "$CHECKS/queue.sh" answer "$QB" 'Yes, on every digest' > "$T/out" 2>&1 || fail "the question on #B, closed since its listing, was refused: $(cat "$T/out")"
[ "$(ncom "$B")" = $((CB + 1)) ] && grep -q "${TB}question:$B:1${TB}" .vid/decide/queue/answers || fail 'the question on the closed issue was not posted and recorded'
# shown again with its new words, then answered
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
grep -q "${TB}question:$A:1${TB}.*the new one or the old one?\$" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the changed question is not listed with its new words'; }
! grep -q "${TB}question:$A:2${TB}" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the deleted question answered there is still listed'; }
sh "$CHECKS/queue.sh" answer "$Q1" 'The new one first' > "$T/out" 2>&1 || fail 'the answer to the question shown again was refused'
L=$FAKEGH/issues/$A/comments/$(ls "$FAKEGH/issues/$A/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: ROW-005, which feed is read first, the new one or the old one?' ] || fail "the answer does not quote the question's new words: $(sed -n 1p "$L")"
exit 0

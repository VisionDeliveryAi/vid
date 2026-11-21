#!/bin/sh
# Purpose: selftest case — GitHub manual's question records from before the one scan, moved to the one key form once (GM-4 F4;
# §5 4a: /vid next works as today). Before GM-4, GitHub manual keyed a question <n>:<k> by its place among the issue's questions;
# the one scan keys it by its comment's place. On GitHub manual's toy and the fake gh, #A's comments are a note, `Question: A?`
# and `Question: B?`, recorded the old way: A? as #A:1 (Q1), B? as #A:2 (Q2), B? answered `there`. At the next call's read and
# listing the records move together, once: Q1 names A? at #A:2, open, its line A?'s words; B? at #A:3 stays answered, no line;
# no line points at the note; answered by Q1, the answer posts quoting A?. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-upgrade: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
A=$(gh_issue 'Step S02')
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$A" 'a note on the plan'; cm "$A" 'Question: ROW-005, which feed is read first?'; cm "$A" 'Question: ROW-008, is the trigger daily?'
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
# the records as GitHub manual kept them before the one scan
Q=.vid/decide/queue; mkdir -p "$Q"
printf '%s:1\t%s\tQuestion: ROW-005, which feed is read first?\tasked\n%s:2\t%s\tQuestion: ROW-008, is the trigger daily?\tasked\n' "$A" "$A" "$A" "$A" > "$Q/questions"
printf 'question:%s:1\tQ1\t2026-11-18T10:00:00Z\nquestion:%s:2\tQ2\t2026-11-18T10:00:00Z\n' "$A" "$A" > "$Q/ids"
printf '2026-11-18T11:00:00Z\tquestion:%s:2\tthere\tAnswered on the thread: daily\towner\tanswered there\n' "$A" > "$Q/answers"
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
grep -q "^Q1${TB}question:$A:2${TB}.*${TB}Question: ROW-005, which feed is read first?\$" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'Q1 does not name A? at its comment place, open'; }
! grep -q "${TB}question:$A:[13]${TB}" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the note, or the answered B?, is an open line'; }
grep -q "${TB}question:$A:3${TB}there${TB}" "$Q/answers" || { cp "$Q/answers" "$T/out"; fail "B?'s answer did not move with it to #$A:3"; }
sh "$CHECKS/queue.sh" list > "$T/ql2" 2> "$T/out" && cmp -s "$T/ql" "$T/ql2" || fail 'a second listing moved the records again'
sh "$CHECKS/queue.sh" answer Q1 'The new feed first' > "$T/out" 2>&1 || fail "Q1's answer was refused: $(cat "$T/out")"
L=$FAKEGH/issues/$A/comments/$(ls "$FAKEGH/issues/$A/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: ROW-005, which feed is read first?' ] || fail "Q1's answer does not quote A?: $(sed -n 1p "$L")"
exit 0

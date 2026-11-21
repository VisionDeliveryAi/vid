#!/bin/sh
# Purpose: selftest case — a question the read holds only in an `assigned` line is a Q line (GM-4 F4; GM-2 T8). On GitHub manual's
# toy and the fake gh, an issue assigned to the owner holds a team question; its `issue` line taken out of the call's read, as when
# the issue query's limit or failure leaves it out and the assigned read holds it: the listing makes it a Q line, and its answer
# posts once, quoting it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-assigned: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
I=$(gh_issue 'A question for the owner'); gh_attr "$I" assignees toy
printf 'Question: may the digest go out on a holiday?\n' > "$T/c"; gh issue comment "$I" -R $R --body-file "$T/c" > /dev/null
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
grep -q "^assigned${TB}$I${TB}" .vid/round/read || { cp .vid/round/read "$T/out"; fail 'the read holds no assigned line for the issue'; }
awk -F'\t' -v n="$I" '!($1 == "issue" && $2 == n)' .vid/round/read > "$T/rd" && cat "$T/rd" > .vid/round/read
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
Q=$(awk -F'\t' -v k="question:$I:1" '$2 == k { print $1; exit }' "$T/ql"); [ -n "$Q" ] || { cp "$T/ql" "$T/out"; fail 'the question only in an assigned line is no Q line'; }
sh "$CHECKS/queue.sh" answer "$Q" 'Yes, holidays too' > "$T/out" 2>&1 || fail "its answer was refused: $(cat "$T/out")"
L=$FAKEGH/issues/$I/comments/$(ls "$FAKEGH/issues/$I/comments" | sort -n | tail -n 1)
[ "$(sed -n 1p "$L")" = 'RM: Question: may the digest go out on a holiday?' ] || fail "the answer does not quote the question: $(sed -n 1p "$L")"
exit 0

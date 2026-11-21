#!/bin/sh
# Purpose: selftest case — every question is the owner's in GitHub manual, on a project switched before the setting was written
# (GM-4 F4, D6; GM-2 T8). On GitHub manual's toy and the fake gh, .vid/tw/settings holding no `owner-questions:` line: a team
# question on a published ticket is a `Q<n>` line after the call's read and listing, and sync prints no `question <n> <k>` line for
# it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-question-unset: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; ! grep -q '^owner-questions:' .vid/tw/settings || fail 'the toy holds an owner-questions: line'
A=$(gh_issue 'Step S02'); printf 'Question: ROW-005, which feed is read first?\n' > "$T/c"; gh issue comment "$A" -R $R --body-file "$T/c" > /dev/null
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/queue.sh" sync > "$T/sy" 2> "$T/out" || fail 'queue.sh sync failed'
! grep -q "^question $A " "$T/sy" || { cp "$T/sy" "$T/out"; fail 'sync told the question as the lead'"'"'s to wait on, not a Q line'; }
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
grep -q "^Q[0-9]*${TB}question:$A:1${TB}" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'with no owner-questions: line, the team question is no Q line'; }
exit 0

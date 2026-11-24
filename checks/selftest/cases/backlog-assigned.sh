#!/bin/sh
# Purpose: selftest case — in GitHub manual each issue assigned to the owner with no question is a backlog item (FB-3 D1). On GitHub
# manual's toy a read holding two assigned issues, one with a team question: the other is a B<n>, its words the issue's number and
# title, the one with a question its Q line alone. A whole read without the issue closes it; one with an `unread` line keeps it. One
# the owner marked done is not added again while it stays assigned, and is added afresh once a whole read lacked it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "backlog-assigned: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/backlog >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings; mkdir -p .vid/round
B=.vid/decide/queue/backlog; QS=$CHECKS/queue.sh
rd() { printf 'ticket\t3\tOPEN\t-\t2026-11-19T09:00:00Z\n' > .vid/round/read; for x; do printf "$x\n" >> .vid/round/read; done; sh "$QS" list > "$T/out" 2>&1 || fail 'queue.sh list failed'; }
op() { awk -F'\t' '$3 != "done" { print $1 ":" $2 }' "$B" | paste -sd ' ' -; }
A7='assigned\t7\t-\t-\tThe owner reads the terms'; A8='assigned\t8\t-\tQuestion: may it be blue?\tA colour'
rd "$A7" "$A8"; op | grep -qE '(^| )B1:assigned:7( |$)' && op | grep -qE 'Q1:question:8:1' && ! op | grep -q 'assigned:8' || fail "the open items are $(op)"
awk -F'\t' '$1 == "B1" && $5 == "#7 The owner reads the terms" && $4 == "you" { f = 1 } END { exit !f }' "$B" || fail 'the item does not name its issue'
rd "$A8" 'unread\tassigned\t-\tthe list failed'; op | grep -q 'B1:assigned:7' || fail 'a read in part closed the assigned issue'
rd "$A8"; ! op | grep -q 'assigned:7' || fail 'a whole read without the issue left it open'
awk -F'\t' '$1 == "B1" && $3 == "done" && $7 == "no longer assigned to you" { f = 1 } END { exit !f }' "$B" || fail 'the closed issue does not say why'
rd "$A7" "$A8"; op | grep -q 'B2:assigned:7' || fail 'an issue assigned again is not an item again'
sh "$QS" backlog set B2 --state 'done' > "$T/out" 2>&1 || fail 'the owner could not mark it done'
rd "$A7" "$A8"; ! op | grep -q 'assigned:7' || fail 'an issue the owner marked done came back while it stayed assigned'
rd "$A8"; rd "$A7" "$A8"; op | grep -q 'B3:assigned:7' || fail 'an issue marked done, then assigned afresh, is not an item'
exit 0

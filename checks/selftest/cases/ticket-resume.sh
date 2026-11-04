#!/bin/sh
# Purpose: selftest case — an unblocked ticket resumes on the code repository's latest main (v0.26.10.9 spec R16, R22;
# §5 ticket-resume). Worker 1 claims the skeleton ticket, commits once on vid/<n>, opens a draft pull request and the
# ticket is labelled blocked; another clone then merges a commit X on origin/main, and the planner clears blocked, sets
# ready and comments the answer. Merging the worker's stale local main into the branch does not hold X; after
# `github.sh next-ticket --worker 1` — which answers `resume <n> unblocked`, having fetched and fast-forwarded main and
# saved the ticket with the answer — merging main into the branch holds X. A sent-back draft resumes likewise.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ticket-resume: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; V=$(pwd -P)
sh checks/ticket.sh skeleton-body --req REQ-001 > /dev/null 2>&1 && sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > /dev/null 2>&1 || fail 'the ticket was not published'
N=$(awk '$1 == "ticket" { sub(/number=/, "", $2); print $2 }' .vid/tickets/map)
gh_worker "$T/w1" || fail 'the clone failed'; cd "$T/w1"
[ "$(sh "$CHECKS/github.sh" next-ticket --worker 1)" = "next $N" ] || fail 'the ticket is not next'
sh "$CHECKS/github.sh" claim "$N" --worker 1 > "$T/out" 2>&1 || fail 'the claim failed'
git fetch -q origin; git checkout -q -b "vid/$N" "origin/vid/$N"; printf 'skeleton\n' > s.txt; git add s.txt; git commit -qm 'the skeleton, begun'
printf 'Blocked.\n\n```vid-return\nticket: #%s\nrows: none\nskeleton: test-framework: x\nskeleton: test-dir: tests/a\nskeleton: run-one: x\nskeleton: ci-workflow: CI\nskeleton: report: vid-junit-<run attempt>\ndecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - which port?\n```\n' "$N" > "$T/pr.md"
sh "$CHECKS/github.sh" push "vid/$N" --pr "$T/pr.md" --draft > "$T/out" 2>&1 || fail 'the draft pull request was not opened'
sh "$CHECKS/github.sh" label "$N" --add blocked > "$T/out" 2>&1 || fail 'the ticket was not labelled blocked'
tk_dev 'X: a change merged on main' app/x.txt 'x'; X=$(git -C "$T/code.git" rev-parse main)
( cd "$V" && sh checks/github.sh label "$N" --remove blocked > /dev/null && printf 'vid: answered — port 8080.\n' > "$T/ans" && sh checks/github.sh comment "$N" --body-file "$T/ans" > /dev/null ) || fail 'the planner could not unblock'
git branch -q stale "vid/$N"; git checkout -q stale; git merge -q --no-edit main 2>/dev/null || true
git merge-base --is-ancestor "$X" HEAD 2>/dev/null && fail 'merging the stale local main held X — the case proves nothing'
git checkout -q "vid/$N"
R=$(sh "$CHECKS/github.sh" next-ticket --worker 1 2> "$T/out") || fail 'next-ticket failed'
[ "$R" = "resume $N unblocked" ] || fail "next-ticket answered '$R'"
grep -q 'port 8080' .git/vid/tickets/"$N"/comment-*.md || fail "the planner's answer was not saved with the ticket"
git merge -q --no-edit main > /dev/null 2>&1 || fail 'the merge of main failed'
git merge-base --is-ancestor "$X" HEAD || fail 'after next-ticket the resumed branch does not hold X'
# sent back: the draft's last comment
( cd "$V" && sh checks/github.sh label "$N" --add blocked > /dev/null ) || true
P=$(ls "$T/gh/prs" | sort -n | tail -n 1)
mkdir -p "$T/gh/prs/$P/comments"; printf 'sent back\n\n- the port is not configurable\n' > "$T/gh/prs/$P/comments/1"
[ "$(sh "$CHECKS/github.sh" next-ticket --worker 1 2>/dev/null)" = "resume $N sent back" ] || fail 'a sent-back draft does not resume'
exit 0

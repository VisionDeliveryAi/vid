#!/bin/sh
# Purpose: selftest case — the staging okay reads a ticket's report (GM-4 E2: every reader of a decision's files reads the ticket's
# too): on the writer's toy and the fake gh (fixtures/tw-toy.sh), a step whose ticket's merge is a GitHub manual acceptance (its
# `step-<n>-<c12>` line in merges and merged-prs) and whose evidence .vid/results/step-<n>-<c12>.txt holds a `finding: real` line:
# stage 1's staging okay lists that real check, numbered, and records it in its ask. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "close-ticket-real: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TAB=$(printf '\t'); tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out .vid/results
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
{ printf '# t\n\n## Header\n\n- number: 2\n- kind: step\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n\n## Regression rows\n\n'; } > .vid/tw/out/issue-2.md
gh issue create -R $R --title t2 --body b --label ticket > /dev/null; printf 'published 2 kind=step step=S02 rows=ROW-003 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log
( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m 'm2' && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); M12=$(printf %.12s "$MC")
echo "step-2-$M12" >> .vid/decide/merged-prs; printf 'step-2-%s\t2\t%s\t%s\n' "$M12" "$MC" "$MC" >> .vid/decide/merges; tw_close 2
tw_hand 'row ROW-003 accepted'; tw_hand 'closed S02'; sh "$GS" tw-sync > /dev/null 2>&1
L='a real sign-in shows it — ROW-003 breached product — the sign-in fails on a phone'
printf 'ticket 2, at %s\nfinding: real — %s\n' "$MC" "$L" > ".vid/results/step-2-$M12.txt"
X=$MC; K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
RC=0; sh "$CHECKS/close.sh" okay --stage 1 > "$T/out" 2>&1 || RC=$?; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); [ -n "$O" ] || fail 'no staging okay was asked'
grep -qxF -- "- 1. $L" "$T/gh/issues/$O/body" || { cp "$T/gh/issues/$O/body" "$T/out"; fail "the okay does not list the ticket report's real check"; }
grep -qxF "real${TAB}1${TAB}$L" $K/d1/ask || { cp $K/d1/ask "$T/out"; fail "the okay's ask does not record the ticket's real check"; }
exit 0

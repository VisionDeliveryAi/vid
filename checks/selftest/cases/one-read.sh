#!/bin/sh
# Purpose: selftest case — GM-4 F3, one reader of GitHub: GitHub is read by one path into one file. On the fake gh, in GitHub
# manual: two published tickets, #A with three phase sub-issues, one of which holds two units of its own, and #B assigned; an open
# issue assigned to the owner; a third ticket the log publishes that GitHub does not hold. `round.sh read`, the one entry, writes
# .vid/round/read whole, holding the round read and, after it, the bodies, sub-issues and assignees (github.sh round-read
# --bodies); the ticket GitHub lacks is an `unread` line and the rest is read; nothing is written to GitHub and no .vid/next/read
# is written. `next-read` is gone (a usage error), and github.sh writes .vid/round/read nowhere itself: tw-hand reads through
# round.sh read, and so does next.sh read: its source names no round-read call of its own, and its read is round.sh read's,
# line for line; no script but github.sh and round.sh calls round-read, and none but round.sh writes .vid/round/read. In GitHub auto round.sh read is the round read alone, as the round reads it: no ticket, body or sub-issue line,
# and no issue view or sub-issue call. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "one-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
mn_body ROW-003 > "$T/b"; A=$(gh_issue 'Skeleton' "$T/b"); B=$(gh_issue 'Step S02'); gh_attr "$B" assignees 'ana'
P1=$(gh_issue 'Phase 1'); P2=$(gh_issue 'Phase 2'); P3=$(gh_issue 'Phase 3'); U1=$(gh_issue 'Unit 1'); U2=$(gh_issue 'Unit 2')
for p in "$P1" "$P2" "$P3"; do gh_sub "$A" "$p"; done; gh_sub "$P2" "$U1"; gh_sub "$P2" "$U2"; gh_attr "$U2" state CLOSED
printf 'Which address should the footer show?\n' > "$T/q"; Q=$(gh_issue 'A question for the owner' "$T/q"); gh_attr "$Q" assignees toy
printf 'published %s kind=skeleton step=S01 rows=ROW-003 at=2026-11-01T09:00:00Z\npublished %s kind=step step=S02 rows=ROW-001 at=2026-11-01T09:00:00Z\npublished 99 kind=step step=S03 rows=ROW-006 at=2026-11-01T09:00:00Z\n' "$A" "$B" > .vid/tw/log
gh_wclear; : > "$FAKEGH/log"
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'round.sh read failed in GitHub manual'
[ -f .vid/round/read ] || fail 'round.sh read wrote no .vid/round/read'
[ ! -e .vid/next/read ] || fail 'a second file, .vid/next/read, was written'
has() { grep -qxF "$(printf "$1")" .vid/round/read || { cat .vid/round/read >&2; fail "no line in .vid/round/read: $(printf "$1" | tr '\t' ' ')"; }; }
grep -q "^issue	$A	" .vid/round/read || fail 'the round read is not in .vid/round/read'
has "ticket\t$A\tOPEN\t-\t2026-11-01T09:00:00Z"; has "ticket\t$B\tOPEN\tana\t2026-11-01T09:00:00Z"; has "body\t$A\t- ROW-003"
for p in "$P1" "$P2" "$P3"; do grep -q "^sub	$A	$A	$p	OPEN	-	Phase " .vid/round/read || fail "phase sub-issue #$p is missing"; done
has "sub\t$A\t$P2\t$U2\tCLOSED\t-\tUnit 2"; has "assigned\t$Q\t-\t-\tA question for the owner"; has "abody\t$Q\tWhich address should the footer show?"
grep -q '^unread	ticket	99	' .vid/round/read || fail 'the ticket GitHub does not hold is not an unread line'
[ "$(awk -F'\t' '$1 == "issue" { i = NR } $1 == "ticket" && !t { t = NR } END { print (i < t) }' .vid/round/read)" = 1 ] || fail 'the bodies are not after the round read'
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'the read wrote to GitHub'; }
# next-read is gone, and github.sh puts nothing in .vid/round/read itself
rc=0; sh "$CHECKS/github.sh" next-read > "$T/out" 2>&1 || rc=$?; [ "$rc" = 2 ] || fail "github.sh next-read exited $rc, not the usage error"
! grep -q 'next-read' "$T/out" || fail 'the usage still names next-read'
! grep -n 'put \.vid/round/read' "$CHECKS/github.sh" > "$T/out" || fail 'github.sh writes .vid/round/read itself'
grep -q 'round\.sh" read' "$CHECKS/github.sh" || fail 'tw-hand does not read through round.sh read'
# next.sh read is round.sh read and nothing else: no round-read call of its own, the same lines in the one file
grep -n 'round-read' "$CHECKS/next.sh" | grep -v '^[0-9]*:[[:space:]]*#' > "$T/out" && fail 'next.sh calls round-read itself, a second path to the read'
grep -q 'round\.sh" read' "$CHECKS/next.sh" || fail 'next.sh read does not read through round.sh read'
# and in every script: no round-read call but github.sh's own and round.sh's, no write of .vid/round/read but round.sh's
for f in "$CHECKS"/*.sh; do case ${f##*/} in github.sh|round.sh) continue ;; esac
  grep -n 'round-read' "$f" | grep -v '^[0-9]*:[[:space:]]*#' | sed "s|^|${f##*/}:|"
  grep -nE '(put|>>?) *"?\.vid/round/read([^.a-z]|$)' "$f" | grep -v '^[0-9]*:[[:space:]]*#' | sed "s|^|${f##*/}:|"; done > "$T/out"
[ ! -s "$T/out" ] || fail 'a script reads GitHub, or writes the one read, outside round.sh read (above)'
# (the times left out: the fake gives an issue's updated time as the clock reads it, so two reads a second apart differ there alone)
nt() { sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/<t>/g' "$1"; }
nt .vid/round/read > "$T/r1"; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed in GitHub manual'
nt .vid/round/read > "$T/r2"; cmp -s "$T/r1" "$T/r2" || { diff "$T/r1" "$T/r2" > "$T/out" || :; fail "next.sh read's read is not round.sh read's"; }
# GitHub auto: the round read alone
grep -v '^setup-answered key=github-mode ' .vid/plan/setup > "$T/st" || true; cat "$T/st" > .vid/plan/setup; : > "$FAKEGH/log"
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'round.sh read failed in GitHub auto'
grep -q "^issue	$A	" .vid/round/read || fail 'the round read is not in .vid/round/read in GitHub auto'
! grep -qE '^(ticket|body|sub|assigned|abody|unread)	' .vid/round/read || fail 'GitHub auto read the bodies too'
! grep -qE 'issue view|sub_issues' "$FAKEGH/log" || fail 'GitHub auto made an issue view or sub-issue call'
echo 'one-read: ok'

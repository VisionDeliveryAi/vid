#!/bin/sh
# Purpose: selftest case — github.sh round-read --bodies, vid-read's GitHub reads (GM-1 S6, its case next-read; GM-4 F3 moved phase 1's
# next-read into the one read, round-read with --bodies). On the fake gh: two published
# tickets, #1 with three phase sub-issues, one of which holds two units of its own (one closed); two open issues assigned to the
# owner. round-read --bodies prints every part in its line form (the round read, each ticket and its body, each sub-issue at both depths with
# its parent, each assigned issue with its body), writes nothing to GitHub, and the allow-list refuses a POST, or a field, on an
# issue's sub-issues. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "next-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
mn_body ROW-003 > "$T/b"; A=$(gh_issue 'Skeleton' "$T/b"); B=$(gh_issue 'Step S02'); gh_attr "$B" assignees 'ana'; gh_attr "$B" created 2026-11-02T10:00:00Z
P1=$(gh_issue 'Phase 1'); P2=$(gh_issue 'Phase 2'); P3=$(gh_issue 'Phase 3'); U1=$(gh_issue 'Unit 1'); U2=$(gh_issue 'Unit 2')
for p in "$P1" "$P2" "$P3"; do gh_sub "$A" "$p"; done; gh_sub "$P2" "$U1"; gh_sub "$P2" "$U2"; gh_attr "$U2" state CLOSED; gh_attr "$U1" assignees 'bo'
printf 'Which address should the footer show?\n' > "$T/q"; Q1=$(gh_issue 'A question for the owner' "$T/q"); Q2=$(gh_issue 'A choice for the owner')
gh_attr "$Q1" assignees toy; gh_attr "$Q2" assignees toy; gh issue comment "$Q2" -R owner/code --body 'Question: may the limit be twenty?' > /dev/null
printf 'published %s kind=skeleton step=S01 rows=ROW-003 at=2026-11-01T09:00:00Z\npublished %s kind=step step=S02 rows=ROW-001 at=2026-11-01T09:00:00Z\n' "$A" "$B" > .vid/tw/log
gh_wclear
sh "$CHECKS/github.sh" round-read --bodies > "$T/out" 2> "$T/err" || { cat "$T/err" >&2; fail 'round-read --bodies failed'; }
has() { grep -qxF "$(printf "$1")" "$T/out" || fail "no line: $(printf "$1" | tr '\t' ' ')"; }
grep -q "^issue	$A	" "$T/out" || fail 'the round read is not in the output'
has "ticket\t$A\tOPEN\t-\t2026-11-01T09:00:00Z"; has "ticket\t$B\tOPEN\tana\t2026-11-02T10:00:00Z"
has "body\t$A\t## What this delivers"; has "body\t$A\t- ROW-003"
for p in "$P1" "$P2" "$P3"; do grep -q "^sub	$A	$A	$p	OPEN	-	Phase " "$T/out" || fail "phase sub-issue #$p is missing"; done
has "sub\t$A\t$P2\t$U1\tOPEN\tbo\tUnit 1"; has "sub\t$A\t$P2\t$U2\tCLOSED\t-\tUnit 2"
has "assigned\t$Q1\t-\t-\tA question for the owner"; has "abody\t$Q1\tWhich address should the footer show?"
has "assigned\t$Q2\t-\tQuestion: may the limit be twenty?\tA choice for the owner"
! grep -q '^unread' "$T/out" || fail "a read failed: $(grep '^unread' "$T/out" | head -n 1)"
[ ! -s "$FAKEGH/writes" ] || { cat "$FAKEGH/writes" >&2; fail 'round-read --bodies wrote to GitHub'; }
# a list of assigned issues as long as the limit may be cut, and says so
VID_ASSIGNED_LIMIT=2 sh "$CHECKS/github.sh" round-read --bodies > "$T/out" 2> "$T/err" || fail 'round-read --bodies failed at a limit of 2'
grep -q '^unread	assigned	-	2 or more open issues are assigned to the owner' "$T/out" || fail 'a list cut at the limit is not said'
# the allow-list: github.sh's own ghc, run alone
{ sed -n '/^gref() {/p' "$CHECKS/github.sh"; sed -n '/^ghc() {/,/^}/p' "$CHECKS/github.sh"; } > "$T/ghc.sh"
for x in "-X POST repos/owner/code/issues/$A/sub_issues" "repos/owner/code/issues/$A/sub_issues -f sub_issue_id=9" "-X DELETE repos/owner/code/issues/$A/sub_issues"; do
  if ( REPO=owner/code; SHARE=''; . "$T/ghc.sh"; IFS=' '; set -- api $x; ghc "$@" ) > "$T/out" 2>&1; then fail "the allow-list let gh api $x through"; fi
  grep -q 'refused' "$T/out" || fail "gh api $x failed but was not refused by the allow-list"; done
( REPO=owner/code; SHARE=''; . "$T/ghc.sh"; ghc api "repos/owner/code/issues/$A/sub_issues" --jq '.[] | [.number, .state, .title, ([.assignees[].login] | join(","))] | @tsv' ) > "$T/out" 2>&1 || fail 'the allow-list refused the GET'
echo 'next-read: ok'

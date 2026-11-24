#!/bin/sh
# Purpose: selftest case — GitHub auto's evidence, decisions and posts are as they were before GitHub manual's own reading (FB-3 A1): the
# whole text of each, on GitHub manual's toy switched to auto and the fake gh (fixtures/accept.sh), compared with the text the release
# before wrote, its commits by name. A pull request of a two-engine ticket: a red run, a head report with a split, a break caught and
# one missed, a rule row with no covers: line, an open grade line and no sort; then a refused head report; then a head that holds a row,
# its grade's line sorted, and that head accepted once the owner allows the row more. And a step close's ask. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "auto-unchanged: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'
printf 'setup-answered key=github-mode value="auto" words="auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
{ mn_ticket "$AC_N" S02 step ROW-001 ROW-012 RULE-001 | sed 's/^- RULE-001 marks: none$/- RULE-001 marks: rule/'; printf '\n## Engines\n\n- primary: alpha\n- also: beta\n\n## Regression rows\n\n- ROW-003\n\n## Faulted rows\n\n- ROW-012: make it fail\n'; } > ".vid/tw/out/issue-$AC_N.md"
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed
head_() { ( cd "$T/dev" && git checkout -q -B "ticket-$AC_N" "${2:-main}" && echo "$1" > "$1.txt" && git add "$1.txt" && g commit -q -m "$1" && git push -q -f origin "ticket-$AC_N" 2>/dev/null && git checkout -q main ); H=$(git -C "$T/dev" rev-parse "ticket-$AC_N"); h=$(printf %s "$H" | cut -c1-12); }
head_ one; H1=$H; h1=$h; P=$(gh pr create -R owner/code --head "ticket-$AC_N" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")" | sed 's#.*/##')
put() { rr_put "$1" "$2" "$3"; }
put red-$AC_N-1 results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 RULE-001' "$AC_RED")"; put red-$AC_N-1 cases-alpha.xml "$(rr_cases ROW-001=fail:no_digest RULE-001=fail:no_log)"; ac_send red-$AC_N-1
i=pr-$P-$h1-1; put $i results.txt "$(printf 'by: TM\ncommit: %s\nenvironments: 1\nstand-in: clock - a fake - the real one' "$H1")"; put $i cases-alpha.xml "$(rr_cases ROW-001=pass ROW-012=pass RULE-001=pass ROW-003=pass)"; put $i cases-beta.xml "$(rr_cases ROW-001=fail:two_digests ROW-012=pass RULE-001=pass ROW-003=pass)"
put $i faults/ROW-012/control.txt ROW-003; put $i faults/ROW-012/cases-alpha.xml "$(rr_cases ROW-012=pass ROW-003=pass)"; ac_send $i
put grade-$i grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept - seen\nROW-012 breached product — no page\nRULE-001 kept — seen\nfinding: bug high — a stray page' "$H1")"; mv "$T/r/grade-$i" "$T/r/grade-pr-$P-$h1-1" 2>/dev/null || true; ac_send "grade-pr-$P-$h1-1"
norm() { sed -e "s/$H1/<head one>/g; s/$h1/<one>/g; s/${H2:-@@}/<head two>/g; s/${h2:-@@}/<two>/g; s/${H3:-@@}/<head three>/g; s/${h3:-@@}/<three>/g; s/$AC_RED/<red>/g; s/pr-$P-/pr-P-/g; s/#$AC_N\\b/#N/g; s/red-$AC_N-/red-N-/g; s/^ticket $AC_N, pull request $P,/ticket N, pull request P,/; s/^decided $P /decided P /; s/at=[0-9TZ:-]*/at=T/" "$@"; }
cm() { cat "$FAKEGH/prs/$P/comments/$(ls "$FAKEGH/prs/$P/comments" | sort -n | tail -n 1)"; echo; }
shot() { ac_round accept "$AC_N"; echo "== $1 (exit $RC)"; norm "$T/out"; echo '-- evidence'; norm ".vid/results/pr-$P-$h.txt"; echo '-- the post'; cm | norm; echo '-- held and counts'; norm .vid/decide/counts; norm .vid/decide/halted; cut -f1,2,3 .vid/decide/state | sort | norm; }
{ H=$H1; h=$h1; shot one
  head_ two "ticket-$AC_N"; H2=$H; h2=$h; i=pr-$P-$h2-1; put $i results.txt "$(printf 'by: A. Person\ncommit: %s' "$H2")"; put $i suite.xml "$(rr_cases ROW-001=pass)"; ac_send $i; shot two
  head_ three "ticket-$AC_N"; H3=$H; h3=$h; i=pr-$P-$h3-1; put $i results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$H3")"; for e in alpha beta; do put $i cases-$e.xml "$(rr_cases ROW-001=pass ROW-012=pass RULE-001=pass ROW-003=pass)"; done
  put $i faults/ROW-012/control.txt ROW-003; put $i faults/ROW-012/cases-alpha.xml "$(rr_cases ROW-012=fail:it_breaks ROW-003=pass)"; ac_send $i
  put "sort-pr-$P-$h3-1" sorted.txt "$(printf 'by: SR\ncommit: %s\nROW-012 test it — a second page — ROW-012 breached product' "$H3")"; ac_send "sort-pr-$P-$h3-1"; shot three
  sh "$CHECKS/decide.sh" rule RULE-001 more 5; shot four
  gh pr merge "$P" -R owner/code --merge --match-head-commit "$H3" > /dev/null; M=$(git --git-dir="$T/code.git" rev-parse main); echo "$P" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$P" "$AC_N" "$H3" "$M" >> .vid/decide/merges
  echo '== the close ask'; sh "$CHECKS/close.sh" ask S02 > "$T/o2" 2>&1 || true; sed 's/asked [0-9]*/asked I/' "$T/o2"; I=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/o2"); sed "s/$M/<merge>/" "$FAKEGH/issues/${I:-0}/body" 2>/dev/null; } > "$T/got" 2> "$T/err"
[ -z "${AU_SHOW:-}" ] || { cat "$T/got" "$T/err"; exit 0; }
sed -n '/^: <<.GOLDEN.$/,/^GOLDEN$/p' "$CHECKS/selftest/cases/auto-unchanged.sh" | sed '1d;$d' > "$T/want"
cmp -s "$T/want" "$T/got" || { diff "$T/want" "$T/got" > "$T/out" || true; fail 'GitHub auto reads, decides or posts another text than the release before (< before, > now)'; }
exit 0
: <<'GOLDEN'
== one (exit 0)
decided P <one> ticket: not yet
weak ROW-012 2 <one> — failing, a weak test — its fault not proven, pr-P-<one>-1 — siblings: ROW-001, ROW-003, ROW-004, ROW-005, ROW-008, and any other test with the same data pattern
-- evidence
ticket N, pull request P, head <head one>
report T2 red-N-1 read: 0 passed, 2 failed, 0 errored, 0 skipped
report head pr-P-<one>-1 read: alpha 4 passed, 0 failed, 0 errored, 0 skipped; beta 3 passed, 1 failed, 0 errored, 0 skipped;
report grade grade-pr-P-<one>-1 read
report sort none
ROW-001	behavior	red	failed	n/a	two_digests
ROW-012	behavior	no-red	passed	not-proven	no T2 lists it; its test still passes under its fault; control ROW-003 passed
RULE-001	rule	red	missing	n/a	no covers: line
ROW-003	regression	n/a	passed	n/a	
split	ROW-001	alpha	beta
finding: bug high — a stray page
list: ROW-012
open grade line: ROW-012
environments: 1
-- the post
vid: decision <head one>
ticket: not yet
ROW-001 failing, a product failure — its test failed, pr-P-<one>-1
ROW-012 failing, a weak test — its fault not proven, pr-P-<one>-1 — siblings: ROW-001, ROW-003, ROW-004, ROW-005, ROW-008, and any other test with the same data pattern
RULE-001 evidence missing — no covers: line, pr-P-<one>-1
ROW-003 passing
split — every engine is now asked: alpha beta
sort evidence missing — no sort report
Fix the whole harm, not the instance named: name what must not happen, find every other way to it, and fix those too.

-- held and counts
ROW-001 <one>
ROW-012 <one>
RULE-001 pr-P-<one>-1
ROW-001	failing	failing
ROW-003	passing	passing
ROW-012	failing	failing
RULE-001	evidence missing	evidence missing
== two (exit 0)
decided P <two> ticket: not yet
-- evidence
ticket N, pull request P, head <head two>
report T2 red-N-1 read: 0 passed, 2 failed, 0 errored, 0 skipped
report head pr-P-<two>-1 refused the first line of results.txt is not by: TM: by: A. Person
report grade grade-pr-P-<one>-1 read
report sort none
ROW-001	behavior	red	missing	n/a	head report refused: the first line of results.txt is not by: TM: by: A. Person
ROW-012	behavior	no-red	missing	missing	no T2 lists it; head report refused: the first line of results.txt is not by: TM: by: A. Person; no fault folder
RULE-001	rule	red	missing	n/a	head report refused: the first line of results.txt is not by: TM: by: A. Person
ROW-003	regression	n/a	missing	n/a	head report refused: the first line of results.txt is not by: TM: by: A. Person
finding: bug high — a stray page
list: ROW-012
open grade line: ROW-012
-- the post
vid: decision <head two>
ticket: not yet
ROW-001 evidence missing — report refused, pr-P-<two>-1
ROW-012 evidence missing — report refused, pr-P-<two>-1; no fault folder, pr-P-<two>-1
RULE-001 held — evidence missing — report refused, pr-P-<two>-1
ROW-003 evidence missing — report refused, pr-P-<two>-1
sort evidence missing — no sort report

-- held and counts
ROW-001 <one>
ROW-012 <one>
RULE-001 pr-P-<one>-1
ROW-001 pr-P-<two>-1
ROW-012 pr-P-<two>-1
RULE-001 pr-P-<two>-1
ROW-003 pr-P-<two>-1
ROW-001	evidence missing	evidence missing
ROW-003	evidence missing	evidence missing
ROW-012	evidence missing	evidence missing
RULE-001	held	evidence missing
== three (exit 0)
decided P <three> ticket: not yet
-- evidence
ticket N, pull request P, head <head three>
report T2 red-N-1 read: 0 passed, 2 failed, 0 errored, 0 skipped
report head pr-P-<three>-1 read: alpha 4 passed, 0 failed, 0 errored, 0 skipped; beta 4 passed, 0 failed, 0 errored, 0 skipped;
report grade grade-pr-P-<one>-1 read
report sort sort-pr-P-<three>-1 read
ROW-001	behavior	red	passed	n/a	
ROW-012	behavior	no-red	passed	proven	no T2 lists it; it_breaks; control ROW-003 passed
RULE-001	rule	red	passed	n/a	covers 3
ROW-003	regression	n/a	passed	n/a	
finding: bug high — a stray page
list: ROW-012
open grade line: ROW-012
-- the post
vid: decision <head three>
ticket: not yet
ROW-001 accepted
ROW-012 accepted
RULE-001 held — it passes at this head, and waits on an answer
ROW-003 passing

-- held and counts
RULE-001 pr-P-<one>-1
RULE-001 pr-P-<two>-1
ROW-001	accepted	accepted
ROW-003	passing	passing
ROW-012	accepted	accepted
RULE-001	held	accepted
recorded: RULE-001 more 5, by owner
== four (exit 0)
decided P <three> ticket: accepted
-- evidence
ticket N, pull request P, head <head three>
report T2 red-N-1 read: 0 passed, 2 failed, 0 errored, 0 skipped
report head pr-P-<three>-1 read: alpha 4 passed, 0 failed, 0 errored, 0 skipped; beta 4 passed, 0 failed, 0 errored, 0 skipped;
report grade grade-pr-P-<one>-1 read
report sort sort-pr-P-<three>-1 read
ROW-001	behavior	red	passed	n/a	
ROW-012	behavior	no-red	passed	proven	no T2 lists it; it_breaks; control ROW-003 passed
RULE-001	rule	red	passed	n/a	covers 3
ROW-003	regression	n/a	passed	n/a	
finding: bug high — a stray page
list: ROW-012
open grade line: ROW-012
-- the post
vid: decision <head three>
ticket: accepted
ROW-001 accepted
ROW-012 accepted
RULE-001 accepted
ROW-003 passing

-- held and counts
ROW-001	accepted	accepted
ROW-003	passing	passing
ROW-012	accepted	accepted
RULE-001	accepted	accepted
== the close ask
asked I close S02
close: S02
commit: <merge>
engines: alpha beta

Run these rows at the commit above, chunk by chunk, in the engines each chunk names: phase 1, the primary engine, first, then phase 2. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`. A chunk may wait while a ticket's run needs the slot.

- chunk p1c1, alpha: ROW-001 ROW-012 RULE-001 ROW-003
- chunk p2c1, beta: ROW-001 ROW-012 RULE-001 ROW-003
GOLDEN

#!/bin/sh
# Purpose: selftest case — ViD's own review's record, checks/review.sh (FB-3 A1.4), on GitHub manual's toy and the fake gh
# (fixtures/accept.sh, review.sh). record refuses, writing nothing, a missing file, a row missing, twice, not the ticket's, a journey's
# row in place of its transitions, a word off the four, a line with no reason, a finding off its form, a review not prepared; it puts
# `by: GR` and `commit:` itself. With an open line it prints `to-sort <k>` and the second reviewer's brief; sorted refuses a line
# missing, added, out of order, changed, a word off the four and one with no reason, and puts `by: SR`. The records are the reports
# vid-results/grade-… and sort-… of .vid/code, read by results.sh's form, and made again when .vid/code is. A known limit's line is not
# sorted. A ticket has one review: prepare refuses a second, at another commit too. due lists what waits. With no pull request found,
# prepare says so, records it for the decision, and drops that once one is found. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
[ -f "$CHECKS/../skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "review-record: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rv() { RC=0; sh "$CHECKS/review.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
ac_project "$T/p" || fail 'the toy could not be made'; n=$AC_N; mkdir -p .vid/decide
# the ticket's rows: ROW-001, ROW-012 and a journey of two transitions, ROW-013
awk '{ print } /^- ROW-012 marks: / { print "> ROW-013 | journey | j | b | n/a | The visitor saves. transitions: 1. a at b · c · d · e · 2. f at g · h · i · j | REQ-001 | origin: REQ-001"; print "- ROW-013 marks: journey" }' ".vid/tw/out/issue-$n.md" > "$T/i" && cat "$T/i" > ".vid/tw/out/issue-$n.md"
fetch() { sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 && sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the fetch failed'; }
ac_head "$AC_C"; fetch; c=$(printf %s "$AC_C" | cut -c1-12)
rv prepare "step-$n" "$AC_C"; [ "$RC" = 0 ] && grep -qx "review #$n: no pull request of this ticket was found" "$T/out" || fail 'a ticket with no pull request was not said so'
[ "$(cat ".vid/decide/review/none-step-$n")" = "$AC_C" ] || fail 'no pull request found is not recorded for the decision'
rv due; grep -qx "review #$n $c" "$T/out" || fail 'a review with no pull request found is not due'
rv_pr merge b1 "ticket: #$n" app/a.txt a; C=$RV_M; h=$(printf %s "$C" | cut -c1-12); id=step-$n-$h; ac_head "$C"; fetch
rv record "$id" /dev/null; [ "$RC" != 0 ] || fail 'a review not prepared was recorded'
rv prepare "step-$n" "$C"; [ "$RC" = 0 ] || fail 'prepare failed'; [ ! -f ".vid/decide/review/none-step-$n" ] || fail 'the line of no pull request stayed once one was found'
R=.vid/decide/review; D=.vid/round/review/$id; rv due; grep -qx "review #$n $h" "$T/out" || fail 'a prepared review is not due'
good='ROW-001 kept — seen
ROW-012 breached test — it never looks at the page
ROW-013-T1 unclear — which page?
ROW-013-T2 breached product — the save is lost
finding: bug high — a stray route — the list — open it
finding: rule — every save is logged'
no() { printf '%s\n' "$2" > "$D/grade.txt"; rv record "$id" "$D/grade.txt"; [ "$RC" != 0 ] && grep -q -- "$3" "$T/out" || fail "$1"; [ ! -e "$R/grade-$id-1" ] || fail "$1: a record was left"; }
rv record "$id" "$D/none"; [ "$RC" != 0 ] && [ ! -e "$R/grade-$id-1" ] || fail 'a missing file was recorded'
no 'a row missing was taken' "$(printf '%s\n' "$good" | grep -v '^ROW-001 ')" 'ROW-001'
no 'a row twice was taken' "$(printf '%s\nROW-001 kept — again' "$good")" 'ROW-001'
no 'a row not of the ticket was taken' "$(printf '%s\nROW-099 kept — seen' "$good")" 'ROW-099'
no 'a journey row was taken for its transitions' "$(printf '%s\n' "$good" | sed 's/^ROW-013-T1 /ROW-013 /')" 'ROW-013'
no 'a fifth word was taken' "$(printf '%s\n' "$good" | sed 's/^ROW-001 kept/ROW-001 fine/')" 'ROW-001'
no 'a breached with no class was taken' "$(printf '%s\n' "$good" | sed 's/breached test/breached/')" 'ROW-012'
no 'a line with no reason was taken' "$(printf '%s\n' "$good" | sed 's/^ROW-001 .*/ROW-001 kept/')" 'ROW-001'
no 'a finding off its form was taken' "$(printf '%s\nfinding: odd — a thing' "$good")" 'finding'
# recorded, with three open lines: to sort
{ printf 'by: someone\ncommit: abc\n'; printf '%s\n' "$good"; } > "$D/grade.txt"; rv record "$id" "$D/grade.txt"; [ "$RC" = 0 ] && grep -q "^to-sort 3 $D/sort-brief.md$" "$T/out" || fail 'three open lines are not to sort'
[ "$(head -n 2 "$R/grade-$id-1/grade.txt")" = "$(printf 'by: GR\ncommit: %s' "$C")" ] && [ "$(grep -c . "$R/grade-$id-1/grade.txt")" = 8 ] || fail 'the record does not begin by: GR and its commit, or lost a line'
[ "$(grep -c 'ROW-01' "$D/to-sort.txt")" = 3 ] && grep -q 'test it' "$D/sort-brief.md" && grep -q 'ROW-013-T2 breached product' "$D/sort-brief.md" || fail 'the second reviewer'"'"'s brief lacks the lines or the words'
rv due; grep -qx "to-sort $id 3" "$T/out" && ! grep -q "^review #$n" "$T/out" || fail 'the sort is not due'
G() { git --git-dir=.vid/code "$@"; }; G cat-file -e "refs/heads/vid-results/grade-$id-1:grade-$id-1/grade.txt" 2>/dev/null || fail 'the record is no report of .vid/code'
sh "$CHECKS/results.sh" check "grade-$id-1" --ticket "$n" > "$T/out" 2>&1 || fail 'results.sh refuses the record'"'"'s form'
rm -rf "$D"; rv prepare "step-$n" "$C"; [ "$RC" = 0 ] && grep -qx "to-sort 3 $D/sort-brief.md" "$T/out" && grep -q 'ROW-013-T2 breached product' "$D/sort-brief.md" || fail 'the sort still due is not prepared again'; rv record "$id" "$D/grade.txt"; [ "$RC" != 0 ] || fail 'a second record was taken'
s='ROW-012 test it — a case can look — ROW-012 breached test — it never looks at the page
ROW-013-T1 drop it — no one can — ROW-013-T1 unclear — which page?
ROW-013-T2 note it — later — ROW-013-T2 breached product — the save is lost'
nos() { printf '%s\n' "$2" > "$D/sorted.txt"; rv sorted "$id" "$D/sorted.txt"; [ "$RC" != 0 ] && [ ! -e "$R/sort-$id-1" ] || fail "$1"; }
nos 'a sort with a line missing was taken' "$(printf '%s\n' "$s" | sed 1d)"; nos 'a sort with a line more was taken' "$(printf '%s\nROW-001 drop it — x — ROW-001 kept — seen' "$s")"
nos 'a sort out of order was taken' "$(printf '%s\n' "$s" | sort -r)"; nos 'a changed grade line was taken' "$(printf '%s\n' "$s" | sed 's/never looks/looks/')"
nos 'a fifth word was taken in the sort' "$(printf '%s\n' "$s" | sed 's/drop it/leave it/')"; nos 'a sort line with no reason was taken' "$(printf '%s\n' "$s" | sed 's/ — later — / — /')"
printf '%s\n' "$s" > "$D/sorted.txt"; rv sorted "$id" "$D/sorted.txt"; [ "$RC" = 0 ] && grep -qx "recorded $id" "$T/out" || fail 'the sort was not recorded'
[ "$(head -n 2 "$R/sort-$id-1/sorted.txt")" = "$(printf 'by: SR\ncommit: %s' "$C")" ] || fail 'the sort does not begin by: SR and its commit'
sh "$CHECKS/results.sh" check "sort-$id-1" --ticket "$n" > "$T/out" 2>&1 || fail 'results.sh refuses the sort'"'"'s form'
rv due; [ ! -s "$T/out" ] || fail 'something is due after the sort'
rm -rf .vid/code; fetch; G cat-file -e "refs/heads/vid-results/sort-$id-1:sort-$id-1/sorted.txt" 2>/dev/null || fail 'the records are not made again as reports'
# one review a ticket, at another commit too
rv_pr merge b2 "ticket: #$n" app/b.txt b; fetch; rv prepare "step-$n" "$RV_M"; [ "$RC" != 0 ] && grep -q 'reviewed already' "$T/out" || fail 'a second review at a later commit was prepared'
# another ticket: a known limit's line is not sorted, and with no other line open the review is whole
M=$(gh_issue 'Step S03'); { mn_ticket "$M" S03 step ROW-006; } > ".vid/tw/out/issue-$M.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$M" >> .vid/tw/log
printf '2026-11-18T10:00:00Z\tROW-006\tlimit\twords\towner\n' >> .vid/decide/rulings; rv_pr merge b3 "ticket: #$M" app/c.txt c; C=$RV_M; id=step-$M-$(printf %s "$C" | cut -c1-12); fetch
rv prepare "step-$M" "$C"; [ "$RC" = 0 ] || fail 'the second ticket was not prepared'; printf 'ROW-006 breached product — x\n' > "$T/g"; rv record "$id" "$T/g"; grep -qx "recorded $id" "$T/out" || fail 'a known limit'"'"'s line is to sort'
exit 0

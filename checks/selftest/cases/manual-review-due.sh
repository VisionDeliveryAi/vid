#!/bin/sh
# Purpose: selftest case — ViD's own review is due when a ticket's decision lacks it alone (FB-3 A1.3, A1.4), through round.sh accept on
# GitHub manual's toy and the fake gh (fixtures/accept.sh). The results in and no review: `review #<n> <c12>`, nothing decided, recorded
# or posted, and the ask still owed, called twice. A decision that is `not yet` for a failing row is posted and asks no review. With no
# pull request found (the review's none-step-<n>): posted `not yet`, `review missing — no merged pull request names this ticket`, once; the next
# ask says `review` again. A grade with an open line and no sort keeps the review due; a grade- or sort- branch of the team's is never
# read. With the records in, accepted; the records restored after .vid/decide and .vid/code were lost, the review still reads, through
# the refs github.sh own-refs and results-fetch put into .vid/code, each its one folder. A reached ticket, and one that follows
# another, ask no review. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-review-due: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; c12=$(printf %s "$AC_C" | cut -c1-12); RD=.vid/decide/review
ac_report unit-1 'A. Person' "$AC_C" 'u.xml=ROW-001=pass ROW-012=pass'; ac_ask "$AC_C"; c0=$(ac_comments)
# a branch of the team's in a grade's name is not ViD's review
rr_put "grade-step-$AC_N-$c12-1" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — seen\nROW-012 kept — seen' "$AC_C")"; ac_send "grade-step-$AC_N-$c12-1"
for x in 1 2; do ac_round accept "$AC_N"; [ "$RC" = 0 ] && grep -qx "review #$AC_N $c12" "$T/out" && ! grep -q '^decided\|^accepted' "$T/out" || fail "the review is not due ($x): exit $RC"; done
[ "$(ac_comments)" = "$c0" ] && [ ! -s .vid/decide/state ] && [ ! -s .vid/decide/log ] && [ -z "$(ls .vid/decide | grep '^step-\|^posted-step' || true)" ] || fail 'a decision that lacks the review was recorded or posted'
ac_round step; grep -qx "decide #$AC_N $AC_C" "$T/out" || fail 'the ask is no longer owed'
# no pull request found: the team is told once, and the next ask asks the review again
mkdir -p "$RD"; echo "$AC_C" > "$RD/none-step-$AC_N"; ac_round accept "$AC_N"; ac_last > "$T/out"
[ "$(ac_comments)" = $((c0 + 1)) ] && grep -qx 'ticket: not yet' "$T/out" && grep -qx 'review missing — no merged pull request names this ticket' "$T/out" && [ ! -f "$RD/none-step-$AC_N" ] || fail 'a ticket with no pull request was not answered so'
ac_ask "$AC_C"; c1=$(ac_comments); ac_round accept "$AC_N"; grep -qx "review #$AC_N $c12" "$T/out" && [ "$(ac_comments)" = "$c1" ] || fail 'the next ask did not ask the review again'
# an open line and no sort: still due; then sorted, and accepted, after a loss and a restore
ac_grade "$AC_C" 'ROW-001 breached test — it checks nothing' 'ROW-012 kept — seen' 'finding: bug — a stray page'; ac_round accept "$AC_N"; grep -qx "review #$AC_N $c12" "$T/out" || fail 'an open line with no sort does not keep the review due'
ac_sort "$AC_C" 'ROW-001 note it — a note — ROW-001 breached test'
sh "$CHECKS/github.sh" own-refs > "$T/out" 2>&1 || fail 'own-refs failed'
for i in "grade-step-$AC_N-$c12-1" "sort-step-$AC_N-$c12-1"; do [ "$(git --git-dir=.vid/code ls-tree --name-only "refs/heads/vid-results/$i")" = "$i" ] || fail "the record $i is not a ref of its one folder"; done
[ "$(git --git-dir=.vid/code show "refs/heads/vid-results/grade-step-$AC_N-$c12-1:grade-step-$AC_N-$c12-1/grade.txt" | sed -n 3p)" = 'ROW-001 breached test — it checks nothing' ] || fail "the team's branch stands in place of ViD's review"
sh "$CHECKS/github.sh" state-save > "$T/out" 2>&1 || fail 'the save failed'; rm -rf .vid/decide .vid/code .vid/state-at; sh "$CHECKS/github.sh" state-restore > "$T/out" 2>&1 || fail 'the restore failed'
[ -f "$RD/grade-step-$AC_N-$c12-1/grade.txt" ] && git --git-dir=.vid/code rev-parse -q --verify "refs/heads/vid-results/grade-step-$AC_N-$c12-1" > /dev/null || fail 'the review is lost with the restore'
ac_round accept "$AC_N"; [ "$RC" = 0 ] && grep -qx "accepted #$AC_N $c12" "$T/out" || fail 'with the review recorded the ticket was not accepted'
grep -q '^finding: note — a note' ".vid/results/step-$AC_N-$c12.txt" && grep -q '^finding: bug — a stray page' ".vid/results/step-$AC_N-$c12.txt" || fail "the review's note or finding is not in the evidence"
# a failing row: posted, and no review asked
N1=$AC_N; tkt() { { mn_ticket "$1" "$2" "$3" ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$1.md"; printf 'published %s kind=%s step=%s rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$1" "$3" "$2" >> .vid/tw/log; }
tk_dev 'a later one'; L=$(git -C "$T/dev" rev-parse HEAD); l12=$(printf %s "$L" | cut -c1-12); AC_N=$(gh_issue 'Step S03'); tkt "$AC_N" S03 step; ac_report unit-2 'A. Person' "$L" 'u.xml=ROW-006=fail:no_list'; ac_ask "$L"
ac_round accept "$AC_N"; grep -qx "decided #$AC_N $l12 ticket: not yet" "$T/out" && ! grep -q '^review ' "$T/out" && ! { ac_last | grep -q '^review missing'; } || fail 'a failing row asked the review, or was not decided'
# a ticket that follows another, and a reached one: no review
tk_dev 'a third'; L=$(git -C "$T/dev" rev-parse HEAD); l12=$(printf %s "$L" | cut -c1-12); ac_report unit-3 'A. Person' "$L" 'u.xml=ROW-006=pass'
AC_N=$(gh_issue 'Step S03 again'); tkt "$AC_N" S03 step; sed "s/^- kind: step\$/&\\
- follows: $N1/" ".vid/tw/out/issue-$AC_N.md" > "$T/f" && cat "$T/f" > ".vid/tw/out/issue-$AC_N.md"; ac_ask "$L"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $l12" "$T/out" || fail 'a ticket that follows another asked a review'
AC_N=$(gh_issue 'A reached row'); tkt "$AC_N" S03 reached; ac_ask "$L"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $l12" "$T/out" || fail 'a reached ticket asked a review'
exit 0

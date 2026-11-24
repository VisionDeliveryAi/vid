#!/bin/sh
# Purpose: selftest case — ViD's own review of a ticket in GitHub manual from end to end (FB-3 A1), through round.sh accept and
# checks/review.sh on GitHub manual's toy and the fake gh (fixtures/accept.sh, review.sh). The ticket's work is a pull request naming a
# sub-issue, squash-merged; its results are a person's, two suites sharing the rows out, at the commit of main the team asks about. accept
# prints `review #<n> <c12>` and posts nothing, the ask still owed; prepare, show and record, with open lines: to sort, and accept still
# waits; sorted, one line `test it`: accept posts `not yet` once, with that one request; the team's next ask, at a commit of main holding
# the added test, is accepted with no second review. A second ticket the same, every row kept: accepted at once. After show and after
# each decision no file or object of the code is anywhere under the project, but the test results' own words. The records saved, the
# folder lost, restored and fetched: both reviews read as they did, and accept answers `accepted at`. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
[ -f "$CHECKS/../skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "manual-review-whole: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rv() { RC=0; sh "$CHECKS/review.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
# clean <when>: no word of the code in any file of the project, nor in any blob or name of .vid/code
clean() { ! grep -rq zcodezz . || { grep -rl zcodezz . > "$T/out"; fail "$1: words of the code are in a file"; }
  git --git-dir=.vid/code cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' 2>/dev/null | while read -r o t; do case $t in blob) git --git-dir=.vid/code cat-file blob "$o" | grep -q zcodezz ;; tree) git --git-dir=.vid/code cat-file -p "$o" | grep -q zname ;; *) false ;; esac && echo "$t $o"; done > "$T/ob" || :
  [ ! -s "$T/ob" ] || { cp "$T/ob" "$T/out"; fail "$1: an object of the code is in .vid/code"; }; }
# work <branch>: the sub-issue's pull request of ticket AC_N, squash-merged, and the team's results at main; C, c12, P, id
work() { rv_pr squash "$1" "$(printf 'ticket: #%s\n\nDecisions: none' "$SUB")" "app/zname-$1.txt" "zcodezz the product $1" "tests/zname-$1.txt" "zcodezz a test $1"; P=$RV_P; C=$RV_M; c12=$(printf %s "$C" | cut -c1-12); id=step-$AC_N-$c12
  ac_report "ci-$1" 'A. Person' "$C" 'unit.xml=ROW-001=pass ROW-012=skip' 'screens.xml=ROW-012=pass a-case-of-nothing=pass'; }
# due_ <ask>: accept says the review is due, posts nothing, and the ask is owed still; then prepare and show, read only
due_() { ac_round step; grep -qx "decide #$AC_N $C" "$T/out" || fail 'the ask is no decide line'; c0=$(ac_comments); ac_round accept "$AC_N" "$C"; [ "$RC" = 0 ] && grep -qx "review #$AC_N $c12" "$T/out" && ! grep -q '^decided\|^accepted' "$T/out" || fail 'accept did not say the review is due'
  [ "$(ac_comments)" = "$c0" ] || fail 'a review due posted'; ac_round step; grep -qx "decide #$AC_N $C" "$T/out" || fail 'the ask is owed no more'
  rv prepare "step-$AC_N" "$c12"; [ "$RC" = 0 ] && grep -q "^brief $id " "$T/out" || fail 'prepare failed'; W=.vid/round/review/$id; grep -q "ci-.* screens.xml: ROW-012: passed" "$W/brief.md" && ! grep -q 'a-case-of-nothing' "$W/brief.md" || fail 'the brief lacks the cases of the rows, or holds another'
  rv show "$id"; grep -q "^pull request #$P (ticket #$AC_N) — 2 files" "$T/out" || fail 'the list'; rv show "$id" "$P" "app/zname-$1.txt"; grep -qx "+zcodezz the product $1" "$T/out" || fail 'the change is not shown'; clean "after show, $1"; }
ac_project "$T/p" || fail 'the toy could not be made'; N1=$AC_N; SUB=$(gh_issue 'a part of it'); gh_sub "$AC_N" "$SUB"
# open lines: sorted, one request, posted once; then the next ask is accepted
work one; ac_ask "$C"; due_ one
printf 'ROW-001 breached test — it would pass a second digest\nROW-012 unclear — which page?\n' > "$W/grade.txt"; rv record "$id" "$W/grade.txt"; grep -qx "to-sort 2 $W/sort-brief.md" "$T/out" || fail 'two open lines are not to sort'
ac_round accept "$AC_N" "$C"; grep -qx "review #$AC_N $c12" "$T/out" && [ "$(ac_comments)" = "$c0" ] || fail 'an unsorted review was decided on'; rv due; grep -qx "to-sort $id 2" "$T/out" || fail 'the sort is not due'
printf 'ROW-001 test it — a case that a second digest is refused — ROW-001 breached test — it would pass a second digest\nROW-012 drop it — no one reads it so — ROW-012 unclear — which page?\n' > "$W/sorted.txt"; rv sorted "$id" "$W/sorted.txt"; grep -qx "recorded $id" "$T/out" || fail 'the sort was not recorded'
ac_round accept "$AC_N" "$C"; grep -qx "decided #$AC_N $c12 ticket: not yet" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] || fail 'the request did not hold the decision, posted once'; ac_last > "$T/out"
grep -q '^request ROW-001 — a case that a second digest is refused' "$T/out" && [ "$(grep -c '^request ' "$T/out")" = 1 ] && grep -q '^requests open' "$T/out" && ! grep -q 'review missing' "$T/out" || fail 'the decision does not ask the one request'
ac_round accept "$AC_N" "$C"; [ "$(ac_comments)" = $((c0 + 1)) ] && ! grep -q '^accepted' "$T/out" || fail 'the same commit with no ask since was posted or accepted again'; rv due; [ ! -s "$T/out" ] || fail 'something is due after the sort'
G1=grade-$id-1; work two; ac_ask "$C"; c0=$(ac_comments); ac_round accept "$AC_N" "$C"; [ "$RC" = 0 ] && grep -qx "accepted #$AC_N $c12" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] && ! { ac_last | grep -q '^request'; } || fail 'the next ask is not accepted, with no second review'
A1=$c12; clean 'after the first ticket'
# a second ticket the same, every row kept: accepted at once
AC_N=$(gh_issue 'Step S03'); { mn_ticket "$AC_N" S03 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log
SUB=$(gh_issue 'a part of the second'); gh_sub "$AC_N" "$SUB"; work three; ac_ask "$C"; due_ three
printf 'ROW-001 kept — seen\nROW-012 kept — seen\n' > "$W/grade.txt"; rv record "$id" "$W/grade.txt"; grep -qx "recorded $id" "$T/out" || fail 'a whole review was not recorded'
ac_round accept "$AC_N" "$C"; grep -qx "accepted #$AC_N $c12" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] && [ "$(ac_last | head -n 2)" = "$(printf 'vid: decision %s\nticket: accepted' "$C")" ] || fail 'every row kept was not accepted at once'; clean 'after the second ticket'
G2=grade-$id-1; A2=$c12; C2=$C; N2=$AC_N
# saved, the folder lost, restored: the reviews read as they did, and nothing is decided again
grep -v '^report skipped' ".vid/results/step-$N2-$A2.txt" > "$T/ev0"; sh "$CHECKS/github.sh" state-save > "$T/out" 2>&1 || fail 'the save failed'; cp -R .vid/decide/review "$T/rv0"
mkdir "$T/new"; cd "$T/new"; rm -rf "$T/p"; sh "$CHECKS/github.sh" state-restore owner/vid-state > "$T/out" 2>&1 || fail 'the restore failed'; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'the fetch failed'
diff -r "$T/rv0" .vid/decide/review > "$T/out" 2>&1 || fail 'the reviews came back different'
for g in "$G1" "$G2"; do git --git-dir=.vid/code cat-file -e "refs/heads/vid-results/$g:$g/grade.txt" 2>/dev/null || fail "$g is no report of .vid/code after the restore"; done
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'; sh "$CHECKS/results.sh" read --ticket "$N2" --at "$C2" > "$T/out" 2>&1 || fail 'the results could not be read after the restore'; grep -v '^report skipped' "$T/out" | cmp -s - "$T/ev0" || { diff "$T/ev0" "$T/out" > "$T/d" || :; cp "$T/d" "$T/out"; fail 'the evidence reads another way after the restore'; }
grep -qx "report grade $G2 read" "$T/ev0" || { cp "$T/ev0" "$T/out"; fail 'the review is not in the evidence'; }
for x in "$N1 $A1" "$N2 $A2"; do AC_N=${x% *}; c0=$(ac_comments); ac_round accept "$AC_N"; grep -qx "accepted #$AC_N at ${x#* }; its close runs there" "$T/out" && [ "$(ac_comments)" = "$c0" ] || fail "#$AC_N, accepted, is not answered so after the restore"
  rv prepare "step-$AC_N" "${x#* }"; [ "$RC" != 0 ] && grep -q 'reviewed already' "$T/out" || fail "#$AC_N would be reviewed again after the restore"; done
rv due; [ ! -s "$T/out" ] || fail 'something is due after the restore'; clean 'after the restore'
exit 0

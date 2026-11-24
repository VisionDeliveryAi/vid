#!/bin/sh
# Purpose: selftest case — ViD's own review of a ticket in GitHub manual reads the ticket's pull requests' changes and nothing else of
# the code, and keeps none of it (FB-3 A1.4), checks/review.sh and checks/github.sh pr-files on GitHub manual's toy and the fake gh
# (fixtures/accept.sh, review.sh). The list: a merged pull request naming the ticket, one squash-merged naming its sub-issue, one known
# by GitHub's closing reference alone, one recorded merged in GitHub auto; never one of no ticket, one still open, one merged after the
# commit. `show` prints the list with counts, a file's change, a long one in parts of at most 20,000 characters that join to the whole,
# and names a file GitHub gives no change for; a pull request off the list, a file off its change and an id never prepared are refused.
# The brief holds the rows, the cases at the commit and no code. Nothing is written by `show`: no file of the project, no object of
# .vid/code; and after the review is recorded no word of the code is in any file or object here. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
[ -f "$CHECKS/../skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "manual-review-show: $*" >&2; tail -n 40 "$T/out" >&2 2>/dev/null; exit 1; }
rv() { RC=0; sh "$CHECKS/review.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
ac_project "$T/p" || fail 'the toy could not be made'; n=$AC_N; mkdir -p .vid/decide
SUB=$(gh_issue 'A part of it'); gh_sub "$n" "$SUB"
awk 'BEGIN { for (i = 1; i <= 900; i++) print "zlongzz line " i " of a file whose change is longer than one call may print" }' > "$T/long"
rv_pr merge b1 "ticket: #$n" app/digest.txt 'zcodezz the digest' tests/digest.txt 'zcodezz a test' app/long.txt "$(cat "$T/long")"; P1=$RV_P
rv_pr squash b2 "ticket: #$SUB" app/page.txt 'zcodezz the page'; P2=$RV_P
rv_pr squash b3 "Closes #$SUB" app/closing.txt 'zcodezz closing'; P3=$RV_P
rv_pr merge b4 'no ticket line' app/auto.txt 'zcodezz auto'; P4=$RV_P; printf '%s\t%s\t%s\t%s\n' "$P4" "$n" "$RV_H" "$RV_M" >> .vid/decide/merges
# a path of some 900 characters, its file one line longer than a part
LP=$(awk 'BEGIN { s = "app"; for (i = 1; i <= 12; i++) { s = s "/"; for (j = 1; j <= 75; j++) s = s "p" } print s }'); LL=$(awk 'BEGIN { for (i = 1; i <= 45000; i++) printf "%d", i % 10 }'); rv_pr merge b9 "ticket: #$n" "$LP" "$LL"; P9=$RV_P
rv_pr merge b5 'of no ticket' app/other.txt 'zcodezz other'; P5=$RV_P
( cd "$T/dev" && git checkout -q -B b6 main && printf 'a\000b' > pic.bin && git add pic.bin && g commit -qm pic && git push -q -f origin b6 2>/dev/null && git checkout -q main ); RV_H=$(git -C "$T/dev" rev-parse b6)
P6=$(gh pr create -R owner/code --head b6 --base main --title b6 --body "ticket: #$n" | sed 's#.*/##'); gh pr merge "$P6" -R owner/code --merge --match-head-commit "$RV_H" > /dev/null; ( cd "$T/dev" && git pull -q origin main 2>/dev/null ); C=$(git -C "$T/dev" rev-parse main)
rv_pr merge b7 "ticket: #$n" app/later.txt 'zcodezz later'; P7=$RV_P
rv_pr_open b8 "ticket: #$n" app/open.txt 'zcodezz open'; P8=$RV_P
ac_head "$C" 1 ROW-001_one_digest=pass ROW-012_the_page=fail:no\ page; h=$(printf %s "$C" | cut -c1-12); id=step-$n-$h
sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'the fetch failed'; sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'
rv show "$id"; [ "$RC" != 0 ] || fail 'a review never prepared was shown'
# a sub-issue the read names and GitHub has no issue of (deleted, or another repository's): the list is the same
printf 'sub\t%s\t%s\t99999\tOPEN\t-\tgone\n' "$n" "$n" >> .vid/round/read
rv prepare "step-$n" "$h"; [ "$RC" = 0 ] || fail "prepare exited $RC"; B=.vid/round/review/$id/brief.md
grep -qx "brief $id $B" "$T/out" && [ -s "$B" ] || fail 'prepare named no brief'
for w in 'ROW-001' 'ROW-012' 'ROW-001_one_digest' 'no page' "sh checks/review.sh show $id" 'breached test' "$C"; do grep -q -- "$w" "$B" || fail "the brief does not hold: $w"; done
! grep -rq zcodezz . || fail 'prepare kept words of the code'
# show: the list, read only
gh_wclear; find . -type f | sort | xargs cksum > "$T/f0"; rv_objects > "$T/o0"; rv show "$id"; cp "$T/out" "$T/list"; [ "$RC" = 0 ] || fail "show exited $RC"
[ "$(sed -n 's/^pull request #\([0-9]*\) .*/\1/p' "$T/list" | sort -n | paste -sd ' ' -)" = "$P1 $P2 $P3 $P4 $P9 $P6" ] || fail "the list is not #$P1 #$P2 #$P3 #$P4 #$P9 #$P6"
grep -q "^pull request #$P1 .*3 files" "$T/list" && grep -q 'app/digest.txt' "$T/list" && grep -q 'tests/digest.txt' "$T/list" && grep -q '+900' "$T/list" || fail 'the list gives no files or counts'
grep -q 'pic.bin.*not shown by GitHub' "$T/list" || fail 'a file GitHub gives no change for is not said so'
rv show "$id" "$P2" app/page.txt; [ "$RC" = 0 ] && grep -q '^+zcodezz the page$' "$T/out" || fail 'a file'"'"'s change is not shown'
rv show "$id" "$P6" pic.bin; grep -q 'not shown by GitHub' "$T/out" || fail 'a binary file is not said'
for p in "$P5" "$P7" "$P8"; do rv show "$id" "$p" app/other.txt; [ "$RC" != 0 ] && grep -q "#$p is not on" "$T/out" || fail "pull request #$p, off the list, was not refused"; done
rv show "$id" "$P1" app/page.txt; [ "$RC" != 0 ] && ! grep -q zcodezz "$T/out" || fail 'a file off the pull request was not refused'
rv show "$id" "$P1" '") | .patch, ("'; [ "$RC" != 0 ] && ! grep -q zcodezz "$T/out" || fail 'a path that is no path was not refused'
k=1; : > "$T/j"; while :; do rv show "$id" "$P1" app/long.txt $k; [ "$RC" = 0 ] || fail "part $k exited $RC"; [ "$(wc -c < "$T/out")" -le 20000 ] || fail "part $k is longer than 20,000 characters"
  m=$(sed -n '1s/.*part [0-9]* of \([0-9]*\).*/\1/p' "$T/out"); [ -n "$m" ] || fail 'no part number'; grep '^+zlongzz' "$T/out" | cut -c2- >> "$T/j"; [ "$k" -lt "$m" ] || break; k=$((k + 1)); done
[ "$k" -ge 4 ] && cmp -s "$T/long" "$T/j" || fail "the parts do not join to the file's change ($k parts)"
rv show "$id" "$P1" app/long.txt $((k + 1)); [ "$RC" != 0 ] || fail 'a part past the last was shown'
# the heading, the part's number and the line ends are within the 20,000 too
k=1; : > "$T/j9"; while :; do rv show "$id" "$P9" "$LP" $k; [ "$RC" = 0 ] || fail "part $k of the long path exited $RC"; [ "$(wc -c < "$T/out")" -le 20000 ] || { x=$(wc -c < "$T/out"); : > "$T/out"; fail "part $k, its heading and line ends counted, is $x characters"; }
  m=$(sed -n '1s/.*part [0-9]* of \([0-9]*\)$/\1/p' "$T/out"); sed 1d "$T/out" | grep -v '^@@' | tr -d '\n' >> "$T/j9"; [ "$k" -lt "${m:-0}" ] || break; k=$((k + 1)); done; [ "$(cat "$T/j9")" = "+$LL" ] || fail 'the parts of one long line do not join to it'
find . -type f | sort | xargs cksum > "$T/f1"; rv_objects > "$T/o1"; cmp -s "$T/f0" "$T/f1" || { diff "$T/f0" "$T/f1" > "$T/out"; fail 'show wrote a file of the project'; }
cmp -s "$T/o0" "$T/o1" || fail 'show changed the objects of .vid/code'; [ ! -s "$FAKEGH/writes" ] || fail 'show wrote to GitHub'
# recorded: nothing of the code here, in a file or an object
printf 'ROW-001 kept — seen\nROW-012 kept — seen\nfinding: bug low — a note\n' > ".vid/round/review/$id/grade.txt"; rv record "$id" ".vid/round/review/$id/grade.txt"; [ "$RC" = 0 ] && grep -qx "recorded $id" "$T/out" || fail 'the review was not recorded'
[ "$(cut -f1 ".vid/decide/review/grade-$id-1/prs" | sort -n | paste -sd ' ' -)" = "$P1 $P2 $P3 $P4 $P9 $P6" ] || fail 'the list is not in the record'
! grep -rqE 'zcodezz|zlongzz' . || fail 'words of the code are in a file here'
git --git-dir=.vid/code cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' | awk '$2 == "blob" { print $1 }' | while read -r o; do ! git --git-dir=.vid/code cat-file blob "$o" | grep -qE 'zcodezz|zlongzz' || echo "$o"; done > "$T/ob"; [ ! -s "$T/ob" ] || fail 'words of the code are in .vid/code'
exit 0

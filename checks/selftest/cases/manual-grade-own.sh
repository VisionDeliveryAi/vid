#!/bin/sh
# Purpose: selftest case — in GitHub manual `/vid grade` is made by ViD itself (FB-3 A1.6), checks/grade.sh, review.sh and queue.sh on
# GitHub manual's toy and the fake gh (fixtures/accept.sh, review.sh). An ask posts nothing, is numbered 0910000001 (the next
# 0910000002), prints `review grade-<n> <c12>` and what it does not read; a step says it again, never asks again and never loses it, the
# wait 0. A `--vs` ask lists the pull requests at each commit, and its record needs the second word; a robustify ask lists every
# ticket's and takes finding lines alone. A requirement with none to read is the script's line. Recorded, the next step reads it with its
# counts and its findings reach the owner's queue; a withdrawn ask posts nothing. An ask made before a switch to GitHub auto is prepared,
# recorded and read there too, while a ticket's review is not. Neither the ask nor its brief says where a report goes or asks a comment. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
[ -f "$CHECKS/../skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "manual-grade-own: $*" >&2; tail -n 30 "$T/out" >&2 2>/dev/null; exit 1; }
ga() { RC=0; sh "$CHECKS/grade.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; rv() { RC=0; sh "$CHECKS/review.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
ac_project "$T/p" || fail 'the toy could not be made'; n=$AC_N; printf 'close-wait-minutes: 0\n' >> .vid/tw/settings
rv_pr merge b1 "ticket: #$n" app/one.txt 'zcodezz one'; P1=$RV_P; V=$RV_M; rv_pr squash b2 "ticket: #$n" app/two.txt 'zcodezz two'; P2=$RV_P; C=$RV_M; h=$(printf %.12s "$C")
fetch() { sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 && sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the fetch failed'; }; fetch; gh_wclear; i0=$(ls "$FAKEGH/issues" | grep -c .)
lst() { rv show "$1"; sed -n 's/^pull request #\([0-9]*\) .*/\1/p' "$T/out" | sort -n | paste -sd ' ' -; }
# the ask: nothing posted; said again at each step
ga ask --reqs 'REQ-001 REQ-011' --focus 'the digest' --commit "$C"; [ "$RC" = 0 ] || fail "the ask exited $RC"; ok '^asked 0910000001 grade ask-0910000001$'; ok "^review grade-0910000001 $h\$"; ok 'code no ticket changed is not read'
[ ! -s "$FAKEGH/writes" ] && [ "$(ls "$FAKEGH/issues" | grep -c .)" = "$i0" ] || fail 'the ask wrote to GitHub'; ga step; ok "^review grade-0910000001 $h\$"; ga step; ok "^review grade-0910000001 $h\$"
X=.vid/decide/grade/0910000001; [ ! -s $X/again ] && [ ! -f $X/lost ] || fail 'the ask was asked again or lost'; ga out; ok '^0910000001$'; rv due; ok "^review grade-0910000001 $h\$"
# made and recorded: REQ-011's rows are in no ticket
rv prepare 0910000001; [ "$RC" = 0 ] || fail 'prepare failed'; B=.vid/round/review/0910000001/brief.md; grep -q 'Focus areas, graded first and deepest: the digest' $B || fail 'the focus is not in the brief'
for w in 'Report it as' 'vid: reported' 'vid: started'; do ! grep -q "$w" $B && ! grep -q "$w" $X/body || fail "the grade's brief or its ask says: $w"; done
[ "$(cat .vid/round/review/0910000001/unread)" = REQ-011 ] || fail 'REQ-011 is not the one unread'; [ "$(lst 0910000001)" = "$P1 $P2" ] || fail 'the list is not the two pull requests'
G=.vid/round/review/0910000001/grade.txt; printf 'REQ-001 partial — half\nREQ-011 pass — seen\n' > $G; rv record 0910000001 $G; [ "$RC" != 0 ] || fail 'a grade of the unread requirement was taken'
printf 'REQ-001 partial — half\nfinding: rule medium — every digest says its day\n' > $G; rv record 0910000001 $G; [ "$RC" = 0 ] || fail 'the grade was not recorded'
ga step; ok '^grade-ask 0910000001 read 1: 2 graded, 2 not pass, 1 findings$'; [ -f $X/done ] || fail 'the ask is not done'; [ ! -s "$FAKEGH/writes" ] || fail 'the read wrote to GitHub'
sh "$CHECKS/queue.sh" sync > "$T/out" 2>&1 || fail 'the queue failed'; grep -q 'grade ask #0910000001: REQ-001 partial — half' .vid/RUN-STATE.md && grep -q 'REQ-011 absent — unread: no pull request of its tickets could be found' .vid/RUN-STATE.md && grep -q 'every digest says its day' .vid/RUN-STATE.md || fail 'its findings are no lines of the owner'"'"'s queue'
# --vs: the changes at each commit
ga ask --reqs 'REQ-001' --commit "$C" --vs "$V"; ok '^asked 0910000002 grade ask-0910000002$'; rv prepare 0910000002; [ "$RC" = 0 ] || fail 'the vs ask was not prepared'
rv show 0910000002; grep -q "^pull request #$P1 .*and at vs" "$T/out" && ! grep "^pull request #$P2 " "$T/out" | grep -q 'vs' || fail 'the list does not say which pull requests the vs: commit holds'
G=.vid/round/review/0910000002/grade.txt; echo 'REQ-001 pass — seen' > $G; rv record 0910000002 $G; [ "$RC" != 0 ] || fail 'a vs grade with no second word was taken'
echo 'REQ-001 pass — seen — vs: partial — half' > $G; rv record 0910000002 $G; [ "$RC" = 0 ] || fail 'the vs grade was not recorded'; ga step; ok '^vs 0910000002 REQ-001 partial — half$'
# robustify: every ticket's changes, finding lines alone
ga ask --robustify 'sending; the feed; unsubscribe' --commit "$C"; ok '^asked 0910000003 '; rv prepare 0910000003; [ "$(lst 0910000003)" = "$P1 $P2" ] || fail 'the robustify list'
G=.vid/round/review/0910000003/grade.txt; echo 'finding: rule — a digest is sent once' > $G; rv record 0910000003 $G; [ "$RC" = 0 ] || fail 'the robustify grade was not recorded'; ga step; ok '^grade-ask 0910000003 read 1: 0 graded, 0 not pass, 1 findings$'
! grep -q 'pull requests:' .vid/round/review/0910000003/brief.md && ! grep -qE '^> *\|' .vid/round/review/0910000003/brief.md && grep -qx 'none: finding lines alone' .vid/round/review/0910000003/brief.md || fail 'a robustify brief names a requirement'
# withdrawn: nothing posted
ga ask --reqs REQ-001 --commit "$C"; ok '^asked 0910000004 '; ga withdraw 0910000004; ok '^withdrawn 0910000004$'; [ ! -s "$FAKEGH/writes" ] || fail 'the withdrawal wrote to GitHub'; rv prepare 0910000004; [ "$RC" != 0 ] || fail 'a withdrawn ask was prepared'
# asked in GitHub manual, then GitHub auto: the own ask is still ViD's to make; a ticket's review is GitHub manual's alone
ga ask --reqs REQ-001 --commit "$C"; ok '^asked 0910000005 '; printf 'setup-answered key=github-mode value="auto" words="auto now" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
ga step; ok "^review grade-0910000005 $h\$"; rv prepare 0910000005; [ "$RC" = 0 ] && grep -q '^brief 0910000005 ' "$T/out" || fail 'in GitHub auto an own ask on record is not prepared'
G=.vid/round/review/0910000005/grade.txt; echo 'REQ-001 pass — seen' > $G; rv record 0910000005 $G; [ "$RC" = 0 ] || fail 'in GitHub auto an own ask on record is not recorded'; ga step; ok '^grade-ask 0910000005 read 1: 1 graded, 0 not pass, 0 findings$'; [ ! -s "$FAKEGH/writes" ] || fail 'the read wrote to GitHub'
rv prepare "step-$n" "$C"; [ "$RC" != 0 ] && grep -q 'GitHub manual' "$T/out" || fail 'in GitHub auto a ticket'"'"'s review was prepared'
exit 0

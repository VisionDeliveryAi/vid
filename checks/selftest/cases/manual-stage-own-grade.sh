#!/bin/sh
# Purpose: selftest case — in GitHub manual ViD makes the stage's grade itself (FB-3 A1.6), checks/close-candidate.sh, review.sh and
# results.sh on the writer's toy and the fake gh, stage 1. With no engines named no candidate is due, and why says so (A1.5). The ask:
# C3 posted, its words any name's and any results files'; no S1 issue, the ask's record numbered 0900001001, `review stage-1 <c12>`
# printed, and again at each read until recorded, never asked again nor lost though the wait is 0. prepare's list: the pull requests of
# the tickets holding the requirements' rows, contained in the candidate; the brief asks each requirement with one to read. A
# requirement with none is written by the script, `absent — unread: …`. A grade off its form is refused and kept nowhere. Recorded, S1
# reads: the grades, the findings, nothing posted. With nothing to read at all, prepare records it alone. A step with no ticket whose
# rows are accepted outside ViD is in, and with no merge on record the candidate is main's newest (A4). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
[ -f "$CHECKS/../skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "manual-stage-own-grade: $*" >&2; tail -n 30 "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; rv() { RC=0; sh "$CHECKS/review.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
fetch() { sh "$GS" results-fetch > "$T/out" 2>&1 || fail 'the fetch failed'; sh "$GS" round-read > .vid/round/read 2>/dev/null || fail 'the read failed'; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk() { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s\n\n## Rows\n\n' "$1" "$2" "$3" "$5" > ".vid/tw/out/issue-$1.md"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done >> ".vid/tw/out/issue-$1.md"
  gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null; printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
acc() { P=step-$1-$(printf %.12s "$2"); echo "$P" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$P" "$1" "$2" "$2" >> .vid/decide/merges; }
# a step with no ticket, its rows accepted outside ViD, and no merge on record: in, its candidate main's newest (A4)
for r in $(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$5 == 0 || $5 == 1 { print $1 }'); do tw_hand "row $r accepted-by-ruling"; done; cp .vid/tw/handed "$T/handed0"; fetch
cs owed; no '^stage 1$'; cs stage 1; ok 'the handed record names no engines yet'; tw_hand 'engines alpha'; cp .vid/tw/handed "$T/handed1"
cs owed; ok '^stage 1$'; cp -R .vid/decide "$T/d0"; cs ask --stage 1; [ "$RC" = 0 ] || fail "the ask of a stage accepted outside failed ($RC)"; [ "$(cat .vid/decide/stage/1/1/commit)" = "$(git -C "$T/dev" rev-parse main)" ] || fail 'the candidate is not main'"'"'s newest commit'
# nothing to read at all: recorded by the script alone
rv prepare stage-1; [ "$RC" = 0 ] && grep -q '^recorded 0900001001' "$T/out" || fail 'a grade with nothing to read was not recorded by the script'
[ "$(grep -c '^REQ-.* absent — unread: no pull request of its tickets could be found$' .vid/decide/review/grade-0900001001-1/grade.txt)" = "$(sed -n 's/^reqs	//p' .vid/decide/stage/1/1/s1ask | wc -w | tr -d ' ')" ] || fail 'the unread requirements'
rm -rf .vid/decide; cp -R "$T/d0" .vid/decide; cp "$T/handed1" .vid/tw/handed; sed '/^row /d' .vid/tw/handed > "$T/h" && cat "$T/h" > .vid/tw/handed
rm -rf "$T"/gh/issues/[2-9]* ; echo 1 > "$T/gh/next"
# stage 1's tickets, their pull requests, and the acceptances
tk 2 skeleton S01 ROW-003,ROW-004 0; tk 3 step S02 ROW-001 1; tk 4 step S03 ROW-006,SEAM-001,RULE-001 1; tk 5 step S04 ROW-002 1
rv_pr squash p3 'ticket: #3' app/digest.txt 'zcodezz digest'; P3=$RV_P; rv_pr merge p5 'ticket: #5' app/limit.txt 'zcodezz limit'; P5=$RV_P; X=$RV_M; h=$(printf %.12s "$X")
for x in 2 3 4 5; do acc $x "$X"; done; rv_pr merge p6 'ticket: #3' app/later.txt 'zcodezz later'
for r in ROW-003 ROW-004 ROW-001 ROW-006 ROW-002 RULE-001 SEAM-001; do tw_hand "row $r accepted"; done; tw_hand 'closed S01'; fetch
# the ask: C3 posted, S1 ViD's own
gh_wclear; : > "$T/b4"; cs ask --stage 1; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); [ -n "$N" ] || fail 'C3 was not asked'
no 'grade stage-1'; ok "^review stage-1 $h\$"; ok '^candidate 1 1$'; K=.vid/decide/stage/1/1; ! grep -rq grade "$T"/gh/issues/*/labels || fail 'a grade issue was posted'
grep -q "^issue	0900001001\$" $K/s1ask && grep -qx "commit	$X" $K/s1ask || fail "the grade's record: $(cat $K/s1ask)"
B=$T/gh/issues/$N/body; ! grep -q 'by: TM' "$B" && grep -q 'one results file or more (.xml), of any name' "$B" && grep -q 'vid: reported <chunk>-<k>' "$B" || fail 'the full run'"'"'s words are not any name'"'"'s and any results files'"'"
# not recorded: said again at each read, never asked again, never lost
fetch; gh_wclear; cs decide --stage 1; ok "^review stage-1 $h\$"; no 's1'; cs decide --stage 1; ok "^review stage-1 $h\$"; ! grep -q '^lost s1' $K/items 2>/dev/null && ! grep -q "s1" $K/again 2>/dev/null || fail 'the grade was asked again or lost'
grep -q '090000' "$T/gh/writes" && fail 'something was posted to the grade'"'"'s number'; rv due; grep -qx "review stage-1 $h" "$T/out" || fail 'the grade is not due'
# after a switch to GitHub auto it is ViD's to make still
cp .vid/plan/setup "$T/setup"; printf 'setup-answered key=github-mode value="auto" words="auto now" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; cs decide --stage 1; ok "^review stage-1 $h\$"; rv prepare stage-1; [ "$RC" = 0 ] && grep -q '^brief 0900001001 ' "$T/out" || fail 'in GitHub auto the grade on record is not prepared'; cp "$T/setup" .vid/plan/setup
# the list and the brief
rv prepare stage-1; [ "$RC" = 0 ] || fail "prepare exited $RC"; B=.vid/round/review/0900001001/brief.md; grep -qx "brief 0900001001 $B" "$T/out" || fail 'no brief'
rv show 0900001001; [ "$(sed -n 's/^pull request #\([0-9]*\) .*/\1/p' "$T/out" | sort -n | paste -sd ' ' -)" = "$P3 $P5" ] || fail "the list is not #$P3 #$P5"
rv show 0900001001 "$P3" app/digest.txt; grep -q 'zcodezz digest' "$T/out" || fail 'a change is not shown'
RQ=$(sed -n 's/^reqs	//p' $K/s1ask); U=$(cat .vid/round/review/0900001001/unread | paste -sd ' ' -); case " $U " in *' REQ-001 '*) fail 'REQ-001, with a pull request, is unread' ;; esac
[ -n "$U" ] || fail 'no requirement is unread in this toy'; for r in $RQ; do case " $U " in *" $r "*) ;; *) RD="${RD:-}$r "; grep -q "^- $r\b\|^> $r \|$r |" "$B" || fail "the brief does not quote $r" ;; esac; done
case " $RD" in *' REQ-001 '*) ;; *) fail 'REQ-001 is not to be read' ;; esac; for w in 'Report it as' 'vid: reported' 'vid: started'; do ! grep -q "$w" "$B" && ! grep -q "$w" $K/s1body || fail "the grade's brief or its ask says: $w"; done; ! grep -q zcodezz "$B" || fail 'the brief holds code'; grep -q 'facade' "$B" || fail 'the brief has no words of the grade'
# refused, kept nowhere; then recorded and read
G=.vid/round/review/0900001001/grade.txt; for r in $RD; do echo "$r pass — seen"; done | sed 's/ pass/ fine/' > $G; rv record 0900001001 $G; [ "$RC" != 0 ] && [ ! -d .vid/decide/review/grade-0900001001-1 ] || fail 'a fifth word was recorded'
for r in $RD; do echo "$r pass — seen"; done | sed 1d > $G; rv record 0900001001 $G; [ "$RC" != 0 ] && [ ! -d .vid/decide/review/grade-0900001001-1 ] || fail 'a requirement missing was recorded'
{ for r in $RD; do echo "$r pass — seen"; done | sed 's/^REQ-001 pass — seen/REQ-001 partial — half/'; echo 'finding: bug high — a digest twice'; } > $G; rv record 0900001001 $G; [ "$RC" = 0 ] && grep -qx 'recorded 0900001001' "$T/out" || fail 'the grade was not recorded'
[ -s .vid/decide/review/grade-0900001001-1/prs ] || fail 'the list is not in the record'
gh_wclear; cs decide --stage 1; ok '^s1 1 read$'; no '^review '; ! grep -q '090000' "$T/gh/writes" || fail 'a write for the grade'"'"'s number'
grep -qx 'REQ-001	partial	1' .vid/decide/stage/1/s1 && grep -q 'finding: bug high — a digest twice' $K/findings || fail 'the grade and its finding are not read'
for r in $U; do grep -qx "grade $r absent — unread: no pull request of its tickets could be found" $K/findings || fail "$r, unread, is no finding"; done
rv due; ! grep -q 'stage-1' "$T/out" || fail 'the recorded grade is due'
exit 0

#!/bin/sh
# Purpose: selftest case — a stage's candidate and its full run, C3 (v0.26.10.26.1 R1, R2, R5), checks/close.sh on the writer's
# toy and the fake gh, stage 1 (S02, S03, S04). Not due with a row failing, held or undecided, a step unmerged, the writer owing
# a step a ticket, or a step close out; due with every row accepted; then no C1 owed for its steps. The ask names the candidate,
# main's newest merge, and writes the candidate line plan.sh's admission reads; C3's rows hold a fix ticket's and a regression row,
# and leave out a row whose newest ticket is open, a deploy-owed row (named in the rest chunk's line alone) and a known limit; the
# rest chunk p1cx. Red: the red row failing, one fix line, its link C3's, no step named, the writer's fix ticket in the row's own
# step; candidate 2 owed once that fix merges, whole; the row red again the owner's. A lost chunk asked again. Green: the steps
# closed by C3, a step closed before kept. A new candidate after a merge of a stage row, none after a later stage's merge alone.
# The status line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-stage: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; W=$CHECKS/writer.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"; : > "$T/werr"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'   # v0.26.10.26.5 (R5a): stages close in order
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
# tk <n> <kind> <step> <rows,> <regression rows>: a ticket published by hand; mg <pr> <n>: merged at a new main commit
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; for r in $5; do printf -- '- %s\n' "$r"; done; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1   # issue #1 a placeholder, so tickets begin at 2
tk 2 step S02 ROW-001,ROW-012 ROW-003; mg 20 2; tk 3 step S03 ROW-006 ''; mg 21 3; tk 4 step S04 ROW-002,DIF-001,ROW-013 ''; mg 22 4; tk 5 fix S02 ROW-005 ''; mg 23 5
tk 6 step S05 ROW-012 ''   # a stage 2 ticket still open holds ROW-012: its newest ticket is open
for r in ROW-001 ROW-012 ROW-003 ROW-006 ROW-002 ROW-005; do tw_hand "row $r accepted"; done; tw_hand 'row DIF-001 owed'; tw_hand 'row ROW-013 known-limit'
printf 'ROW-013\tknown limit\tknown limit\t22\tx\tx\nROW-001\taccepted\taccepted\t20\tx\tx\n' >> .vid/decide/state; sed 's/^- DIF-001 marks: none$/- DIF-001 marks: owed-staging/' .vid/tw/out/issue-4.md > "$T/i4" && cat "$T/i4" > .vid/tw/out/issue-4.md; sh "$GS" tw-sync > /dev/null 2>&1
# not due: a row failing, held, not yet decided; a step close out; the writer owing a step a ticket
tw_hand 'row ROW-006 failing'; cs owed; no '^stage 1$'; cs why; ok '^1: no candidate yet · rows failing 1$'
tw_hand 'row ROW-006 held'; cs why; ok 'rows held 1'; { grep -v '^row ROW-006 ' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed; cs why; ok 'rows not yet decided 1'
tw_hand 'row ROW-006 accepted'; mkdir -p .vid/decide/close/S03/1; printf 'issue\t9\ncommit\tx\nchunk\tp1c1\talpha\tROW-006\n' > .vid/decide/close/S03/1/ask; cs why; ok 'closes out 1'; rm -rf .vid/decide/close/S03
printf 'step-start step=S03 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events; cs why; ok 'steps owed a ticket 1'
grep -v 'step=S03 at=2026-11-09T09:00:00Z' .vid/metrics-events > "$T/m"; cat "$T/m" > .vid/metrics-events
# due: the stage line, and no C1 for its steps
cs owed; ok '^stage 1$'; no '^close S0[234]$'
# the ask: the candidate at main's newest merge, its line, C3's rows, the rest chunk, and S1
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; ok '^asked [0-9]* close stage-1$'; ok '^candidate 1 1$'; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out")
K=.vid/decide/stage/1/1; grep -qx "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1" .vid/tw/handed || fail "the candidate line: $(grep '^candidate' .vid/tw/handed)"
grep -q "^stage-candidate stage=1 commit=$X candidate=1 " .vid/metrics-events || fail 'no stage-candidate event'
[ "$(sed -n 's/^candidate[[:space:]][[:space:]]*//p' .vid/tw/handed | sed 's/[[:space:]]*|[[:space:]]*stand-in.*$//')" = 1 ] || fail "plan.sh's admission does not read the candidate line as stage 1"   # plan.sh hand candidate
B=$T/gh/issues/$N/body; grep -qx 'close: stage-1' "$B" && grep -qx "commit: $X" "$B" && grep -qx 'engines: alpha beta' "$B" || fail 'the C3 ask names no stage, commit or engines'
for r in ROW-001 ROW-003 ROW-006 ROW-002 ROW-005; do grep -q -- "^- chunk p1c[0-9]*, alpha: .*$r" "$B" && grep -q -- "^- chunk p2c[0-9]*, beta: .*$r" "$B" || fail "C3 leaves out $r"; done
for r in ROW-012 DIF-001 ROW-013; do ! grep -q -- "^- chunk p[12]c[0-9]*, [a-z ]*: .*$r" "$B" || fail "C3 runs $r"; done
grep -qx -- '- chunk p1cx, alpha: every other test case of the suite, but the cases of the deploy-owed rows DIF-001; when no case is left outside the rows, send the cases file with no test case and the line `none left` in results.txt' "$B" || fail "the rest chunk: $(grep p1cx "$B")"
grep -q "^chunk${TAB}p1cx${TAB}alpha${TAB}\$" $K/ask || fail 'the rest chunk holds a row in the record'
cs owed; no '^stage 1$'; no '^close S0'; cs out; ok '^out stage-1$'
# S1's report, so its grade is no item here (stage-grade.sh proves S1)
G=$(sed -n 's/^issue\t//p' $K/s1ask); { echo 'by: GR'; echo "commit: $X"; for q in $(sed -n 's/^reqs\t//p' $K/s1ask); do echo "$q pass — read"; done; } > "$T/g"; rm -rf "$T/r/grade-$G-1"; mkdir -p "$T/r/grade-$G-1"; cp "$T/g" "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"
# red: ROW-001 failing, one fix line with C3's link, the writer's fix ticket in S02; a lost chunk asked again
rq p1c1-1 "$X" alpha ROW-001=fail:broke ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass; rq p1cx-1 "$X" alpha test_other=pass; fetch
cs decide --stage 1; [ "$RC" = 0 ] || fail "decide failed ($RC)"; ok '^close-red stage-1 p1c1 alpha:ROW-001$'; ok '^close-again stage-1 p2c1$'; no '^failing '
rq p2c1-1 "$X" beta ROW-001=pass ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass; fetch; cs decide --stage 1; ok '^failing ROW-001$'; ok '^close-fix stage-1 ROW-001$'
grep -q "^fix ROW-001 | ROW-001: ROW-001 in alpha | C3 #$N of stage 1: req-$N-p1c1-1 | stand-in: RM" .vid/tw/handed || fail "the fix line: $(grep '^fix' .vid/tw/handed)"
grep -q "^row ROW-001 failing | stand-in: C3 #$N" .vid/tw/handed || fail 'ROW-001 does not read failing'; grep -q 'plan-change what=other .*a red close of stage-1' .vid/metrics-events || fail 'no plan change'
grep -q 'evidence=step:S02\|step:S02' .vid/plans/decisions/*.why 2>/dev/null || true
FL=$(sed -n 's/^\(fix ROW-001 .*\) | stand-in: RM$/\1/p' .vid/tw/handed); KF=$(printf '%s' "$FL" | cksum | cut -d' ' -f1); printf 'step-start step=S02 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events; sh "$GS" spec-export > /dev/null 2>&1
F=$(sh "$W" write fix "$KF" 2> "$T/werr") || fail 'the C3 fix ticket was refused'; grep -qx -- '- step: S02' "$F" || fail "the fix ticket's step: $(grep -- '- step:' "$F")"
# the fix merged: candidate 2 owed, whole, ROW-001 red again the owner's
printf 'published 7 kind=fix step=S02 rows=ROW-001 fix=%s at=2026-11-09T11:00:00Z\n' "$KF" >> .vid/tw/log; gh issue create -R $R --title t7 --body b --label ticket > /dev/null; mg 24 7; tw_hand 'row ROW-001 accepted'   # decide.sh merged's line, at the fix's merge
printf 'amended 6 kind=step step=S05 rows=ROW-017 at=2026-11-09T11:30:00Z\n' >> .vid/tw/log   # #6 amended to drop ROW-012: its newest ticket now is #2, merged
fetch; cs owed; grep -q '^stage 1$' "$T/out" || fail "candidate 2 not owed: $(cat "$T/out")"; cs ask --stage 1; ok '^candidate 1 2$'; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); X2=$(git --git-dir="$T/code.git" rev-parse main)
[ "$(cut -d' ' -f1 .vid/decide/stage/1/2/rows | sort | paste -sd ' ' -)" = 'ROW-001 ROW-002 ROW-003 ROW-005 ROW-006 ROW-012' ] || fail "candidate 2's rows: $(cat .vid/decide/stage/1/2/rows)"
rq p1c1-1 "$X2" alpha ROW-001=fail:still ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass ROW-012=pass; rq p2c1-1 "$X2" beta ROW-001=pass ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass ROW-012=pass; rq p1cx-1 "$X2" alpha; fetch   # v0.26.10.26.7 (R7): a rest chunk with no case, and no none left
sh "$CHECKS/results.sh" close --stage 1 > "$T/out" 2>&1 || true; ok "^refused${TAB}req-$N-p1cx-1${TAB}no test case, and results.txt has no line none left"; ok "^chunk${TAB}p1cx${TAB}absent"
Q=req-$N-p1cx-2; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nnone left' "$X2")"; rr_put "$Q" cases-alpha.xml "$(rr_cases)"; send "$Q"; fetch
sh "$CHECKS/results.sh" close --stage 1 > "$T/out" 2>&1 || true; ok "^chunk${TAB}p1cx${TAB}green${TAB}2$"
cs decide --stage 1; ok '^close-twice stage-1 ROW-001$'; sh "$QS" sync > /dev/null 2>&1; grep -q 'the close of stage-1, ROW-001 failed again after its fix' .vid/RUN-STATE.md || fail 'the twice item reached no Q line'
# green, after the owner's limit: the same C3 decided again leaves the limit out; the steps closed by C3, S04's own close line kept
tw_hand 'closed S04 | stand-in: close #1 at 000000000000'; QN=$(sed -n 's/^- \(Q[0-9]*\) · .*ROW-001 failed again.*/\1/p' .vid/RUN-STATE.md); sh "$QS" answer "$QN" limit 'a known limit' > "$T/out" 2>&1 || fail 'the limit was refused'
cs decide --stage 1; ok '^stage-c3 1 passed$'; ok '^closed S02$'; ok '^closed S03$'; no '^closed S04$'; grep -q "^closed S02 | stand-in: C3 #$N at $(printf %.12s "$X2")" .vid/tw/handed || fail 'S02 is not closed by C3'
grep -q '^closed S04 | stand-in: close #1' .vid/tw/handed || fail "S04's own close went"; [ -f .vid/decide/stage/1/2/passed ] || fail 'no passed'
# no new candidate after a later stage's merge alone; one after a merge holding a stage row
tk 8 step S05 ROW-017 ''; mg 26 8; tw_hand 'row ROW-017 accepted'; fetch; cs owed; no '^stage 1$'
tk 9 fix S03 ROW-006 ''; mg 27 9; fetch; cs owed; ok '^stage 1$'
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: candidate 2 at [0-9a-f]* · C3 green · S1 0 of [0-9]* graded, 0 pass · findings '
exit 0

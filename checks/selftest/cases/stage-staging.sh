#!/bin/sh
# Purpose: selftest case — staging in ticket mode (v0.26.10.26.2 R1–R7), checks/close.sh on the writer's toy and the fake gh,
# stage 1 (S01's skeleton ticket, S02, S03, S04). The okay: due only once the candidate's C3 passed, posted once, labelled
# deploy. The D1 report read on its form alone: a wrong commit, a passed one with no staging.txt, no differs: line, a failed one
# with no product change: line; a refused report posted back once, the second the owner's, whose again posts it back. A failed
# step with no product change asked again at k+1, the second at the same step the owner's; one with a product change closes the
# okay with a door line; its draft declined is the owner's, whose again okays the same commit again. A passed D1: staged, its new
# differences one door line. The setup hold: stage 2's S05 refused at the candidate, admitted after the owner's continue. CS:
# the golden path but a production-owed row, the seam and staging-owed rows, not the others; against D1's address and sign-ins;
# a rule row with no covers: line asked again; paid, failing, a fix line with CS's link, a row red at an earlier CS the owner's;
# a row whose newest ticket merged after the candidate left out; a refused report's quiet; stage 2's okay once stage 1's
# CS is done; stage 2's: a step with brackets, a retry's quiet, a started okay holding staging until lost, none under a
# later stage's candidate; paid only in every engine; the status line; the writer's CS fix ticket, with the staged line in the handed record.
# 0.26.11.1.1: its passed D1 reports carry duties.txt and seed: and seam: lines; one that says `stays: up` is up in `addresses` after its run (R1). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-staging: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"; COV=''
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'   # v0.26.10.26.5 (R5a): stages close in order
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s%s' "$C0" "${COV:+
$COV}")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
# dp <okay> <k> <report.txt lines> [<staging.txt lines>]: a D1 report
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)   # 0.26.11.1.1 (R3): a passed D1's duties, each done
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf '%s\ndecisions: none' "$3")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"; [ -z "${4:-}" ] || { rr_put "$Q" staging.txt "$(printf '%s\nseed: synthetic\nseam: SEAM-001 real\nseam: SEAM-002 real' "$4")"; rr_put "$Q" duties.txt "$DU"; }; send "$Q"; }   # 0.26.11.1.1 (R3, R4, R6): its seed, seam and duty lines
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | tr '+' ' ' | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003,ROW-004 'ROW-004=owed-production'; mg 20 2; tk 3 step S02 ROW-001,SEAM-002 'SEAM-002=seam'; mg 21 3
tk 4 step S03 ROW-006,SEAM-001,RULE-001,ROW-007 'SEAM-001=seam RULE-001=rule;+owed-staging ROW-007=owed-staging'; mg 22 4; tk 5 step S04 ROW-002,DIF-001 'DIF-001=owed-staging'; mg 23 5
for r in ROW-003 ROW-001 ROW-006 ROW-002; do tw_hand "row $r accepted"; done; for r in ROW-004 SEAM-001 SEAM-002 RULE-001 DIF-001 ROW-007; do tw_hand "row $r owed"; done
tw_closed S01; sh "$GS" tw-sync > /dev/null 2>&1
# C3 asked: no okay yet
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; ok '^candidate 1 1$'; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); K=.vid/decide/stage/1/1
cs owed; no '^okay staging'
# the setup hold: S05, stage 2, refused at the candidate
printf 'step-start step=S02 at=2026-11-09T09:00:00Z\nstep-start step=S03 at=2026-11-09T09:00:00Z\nstep-start step=S04 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events
mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/; sed 's/^stage: 0$/stage: 1/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
tw_closed S02; ! sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail 'S05 was admitted under the setup hold'; ok 'outside stages 0 to 1'
sh "$QS" status > "$T/out" 2>&1; ok '^setup hold: the next stage waits until staging has passed once'
mkdir -p .vid/decide/drafts/9; echo x > .vid/decide/drafts/9/base; echo w > .vid/decide/drafts/9/words; echo y > .vid/decide/drafts/9/why; sh "$QS" ask draft 9 > /dev/null 2>&1; touch .vid/decide/drafts/9/declined   # a silent sync first
sh "$QS" sync > "$T/out" 2>&1; ok '^hold 1 Q[0-9][0-9]*$'; QH=$(sed -n 's/^hold 1 \(Q[0-9]*\)$/\1/p' "$T/out")   # v0.26.10.26.7 (R2): the hold is a Q line, announced once
grep -q "^- $QH · asked .* · gates stage 2 · stage 2 waits until staging has passed once · answer continue to build on$" .vid/RUN-STATE.md || fail "no hold Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
sh "$QS" sync > "$T/out" 2>&1; no '^hold 1'
sed 's/^run:.*/run: stopped owner asked to pause/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; sh "$QS" control continue 'go on' > "$T/out" 2>&1; ok '^run: active$'
! grep -q '^setup-hold off' .vid/tw/handed || fail 'a continue ending a pause ended the hold'
sh "$QS" control continue 'build on, the owner' > "$T/out" 2>&1; ok '^setup hold: off$'; grep -q '^setup-hold off | stand-in: owner build on, the owner$' .vid/tw/handed || fail 'no setup-hold line'
sh "$QS" sync > "$T/out" 2>&1; ! grep -q "^- $QH " .vid/RUN-STATE.md || fail 'the hold Q line stayed after the continue'; no '^hold 1'
sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail "S05 refused after the continue: $(tail -n 2 "$T/out")"
{ grep -v '^setup-hold off' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed; grep -v 'step=S05' .vid/metrics-events > "$T/m"; cat "$T/m" > .vid/metrics-events   # the hold again, for the staged line below
sh "$QS" control pause 'wait' > /dev/null 2>&1; sh "$QS" answer "$QH" continue 'go on' > "$T/out" 2>&1; ok '^run: active$'; holdon=$(grep -c '^setup-hold off' .vid/tw/handed || true); [ "$holdon" = 0 ] || fail 'a continue ending a pause ended the hold'
sh "$QS" answer "$QH" continue 'build on' > "$T/out" 2>&1; ok '^setup hold: off$'; grep -q '^setup-hold off | stand-in: owner build on$' .vid/tw/handed || fail 'answer Q continue: no setup-hold line'
! sh "$QS" answer "$QH" continue 'again' > "$T/out" 2>&1 || fail 'a second continue answered a hold that is off'
{ grep -v '^setup-hold off' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed   # the hold again
# C3 green: the okay owed once
G=$(sed -n 's/^issue\t//p' $K/s1ask); { echo 'by: GR'; echo "commit: $X"; for q in $(sed -n 's/^reqs\t//p' $K/s1ask); do echo "$q pass — read"; done; } > "$T/g"; rm -rf "$T/r/grade-$G-1"; mkdir -p "$T/r/grade-$G-1"; cp "$T/g" "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"
C3R=$(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/ask); P=''; for r in $C3R; do P="$P $r=pass"; done
rq p1c1-1 "$X" alpha $P; rq p2c1-1 "$X" beta $P; rq p1cx-1 "$X" alpha test_other=pass; fetch; cs decide --stage 1; ok '^stage-c3 1 passed$'
cs owed; ok '^okay staging 1$'; [ "$(grep -c '^okay' "$T/out")" = 1 ] || fail 'more than one okay line'
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
grep -qx 'okay: staging' "$B" && grep -qx "commit: $X" "$B" && grep -qx 'seed: synthetic' "$B" || fail "the okay's body: $(head -n 3 "$B")"
grep -qx 'Until this deploy passes, or the owner says continue, no ticket of stage 2 is published.' "$B" || fail "the okay's body names no hold"   # R2
grep -q 'deploy' "$T/gh/issues/$O/labels" || fail 'the okay is not labelled deploy'; grep -q "^asked $O deploy stage=1" .vid/tw/log || fail 'no asked line'
cs owed; no '^okay staging'; cs out; ok '^out stage-1$'
sed 's/^close-wait-minutes: 0$/close-wait-minutes: 600/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
# the report, on its form: refused for each fault; posted back once, the second the owner's
GOOD=$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: VID_TEST — 1 — unset\ndiffers: the /_ops/ door — open — absent\nstays: up')   # 0.26.11.1.1 (R1): a staging that stays up
dp "$O" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$(git --git-dir="$T/code.git" rev-parse main~1)")" "$GOOD"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok 'refused.*is not the one asked for'
cs decide --stage 1; ok '^d1-refused 1 1$'; grep -q '^vid: refused d1-1' "$T/gh/issues/$O/comments/1" || fail 'the refusal was not posted'
cs decide --stage 1; no 'again'; sed 's/^close-wait-minutes: 600$/close-wait-minutes: 0/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
cs decide --stage 1; ok '^close-again staging-1 d1$'; sed 's/^close-wait-minutes: 0$/close-wait-minutes: 600/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings   # a refused report counts as none: its quiet runs on
dp "$O" 2 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")"; fetch; cs decide --stage 1; ok "^d1-item 1 refused d1 twice: a passed deploy has no staging.txt #$((O * 1000 + 2))\$"
QN=$(qn 'its report refused twice'); [ -n "$QN" ] || fail 'the second refusal reached no Q line'; sh "$QS" answer "$QN" again 'send it again' > "$T/out" 2>&1 || fail 'again was refused'
cs decide --stage 1; ok '^d1-refused 1 2$'
dp "$O" 3 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" "staging: http://127.0.0.1:5001"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok 'no differs: line, nor differs: none'
dp "$O" 3 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate' "$X")"; fetch; sh "$RS" deploy --stage 1 > "$T/out" 2>&1; ok 'no product change: yes or no line'
# a failed step, no product change: asked again at k+1; the second at the same step the owner's, whose again asks once more
dp "$O" 3 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: no' "$X")"; fetch; cs decide --stage 1; ok '^d1-failed 1 migrate$'
grep -rqx 'vid: failed at migrate: deploy again and report as attempt 4' "$T/gh/issues/$O/comments" || fail 'no k+1 comment'
cs decide --stage 1; no '^d1-failed'
dp "$O" 4 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: no' "$X")"; fetch; cs decide --stage 1; ok '^d1-item 1 failed d1 at migrate #[0-9]*$'
QN=$(qn 'failed twice at migrate'); [ -n "$QN" ] || fail 'the second failure reached no Q line'; sh "$QS" answer "$QN" again 'once more' > "$T/out" 2>&1 || fail 'again was refused'
cs decide --stage 1; ok '^d1-failed 1 migrate$'; grep -rqx 'vid: failed at migrate: deploy again and report as attempt 5' "$T/gh/issues/$O/comments" || fail 'no comment after again'
dp "$O" 5 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: no' "$X")"; fetch; cs decide --stage 1; ok '^d1-item 1 failed d1 at migrate #[0-9]*$'
QN=$(qn 'failed twice at migrate'); [ -n "$QN" ] || fail 'a later failure at the same step reached no Q line'; sh "$QS" answer "$QN" again 'and once more' > "$T/out" 2>&1 || fail 'again was refused'
cs decide --stage 1; grep -rqx 'vid: failed at migrate: deploy again and report as attempt 6' "$T/gh/issues/$O/comments" || fail 'no comment after the second again'
# a product change: the okay closed, a door line; its draft declined is the owner's, whose again okays the same commit again
dp "$O" 6 "$(printf 'by: DP\ncommit: %s\noutcome: failed db seed\nproduct change: yes' "$X")"; fetch; cs decide --stage 1; ok "^door d1-failed 1 #$O at db seed\$"
grep -qx CLOSED "$T/gh/issues/$O/state" || fail 'the failed okay is open'; cs owed; no '^okay staging'; : > $K/findings; sh "$QS" status > "$T/out" 2>&1; ok ' · findings 0 · D1 failed · paid '
mkdir -p .vid/decide/drafts/1; echo "D1 #$O failed: db seed" > .vid/decide/drafts/1/why; : > .vid/decide/drafts/1/declined
cs decide --stage 1; ok '^d1-item 1 declined d1 at db seed #[0-9]*$'; QN=$(qn 'its row was declined'); [ -n "$QN" ] || fail 'the declined draft reached no Q line'
sh "$QS" answer "$QN" again 'okay it again' > "$T/out" 2>&1 || fail 'again was refused'; cs decide --stage 1; ok '^d1-again 1$'; cs owed; ok '^okay staging 1$'
mv STAGES.md "$T/stages.md"   # v0.26.10.28.8 (R9): one stage, no STAGES.md — no place names a stage 2
cs okay --stage 1; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); grep -qx "commit: $X" "$T/gh/issues/$O/body" || fail 'the okay again is not at the same commit'
B=$T/gh/issues/$O/body; ! grep -q 'stage 2' "$B" && grep -qx 'Stage 1 is the last stage: no later stage waits on this deploy.' "$B" || fail "one stage: the okay's body: $(tail -n 2 "$B")"
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1; grep '^setup hold:' "$T/out" > "$T/sh" || fail 'one stage: no setup hold line'; ! grep -q 'next stage\|stage 2' "$T/sh" && grep -qx "setup hold: staging has not passed once yet; stage 1 is the last stage, so nothing waits on it; the owner's continue clears it" "$T/sh" || fail "one stage: $(cat "$T/sh")"
sh "$QS" keys > "$T/out" 2>&1; grep '^hold:' "$T/out" > "$T/hi" || fail 'one stage: no hold item'; ! grep -q 'stage 2' "$T/hi" && grep -q "^hold:1${TAB}[^${TAB}]*${TAB}staging has not passed once yet; stage 1 is the last stage, so nothing waits on it · answer continue to clear the hold\$" "$T/hi" || fail "one stage: the hold item: $(cat "$T/hi")"
S=$CHECKS/../skills/vid-deploy/SKILL.md; [ ! -f "$S" ] || grep -q 'When there is no stage <N+1> .*say instead: "Staging has not passed once yet. Stage <N> is the last stage, so nothing waits on it."' "$S" || fail "vid-deploy's hold words (GM-4 K5: carved from vid-run) are not conditioned on a next stage"
mv "$T/stages.md" STAGES.md; sh "$QS" keys > "$T/out" 2>&1; grep -q "^hold:1${TAB}[^${TAB}]*${TAB}stage 2 waits until staging has passed once · answer continue to build on\$" "$T/out" || fail "two stages: the hold item: $(grep '^hold:' "$T/out")"
# passed: staged, once; the new differences one door line
dp "$O" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" "$GOOD"; fetch; cs decide --stage 1; ok '^d1 1 passed$'; ok '^staged 1$'
ok "^door differs 1 #$O: VID_TEST (production: unset); the /_ops/ door (production: absent)\$"; grep -q "^staged 1 | stand-in: D1 #$O at $(printf %.12s "$X")" .vid/tw/handed || fail 'no staged line'
sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail "S05 refused once staged: $(tail -n 2 "$T/out")"
# CS: its rows, against staging; ROW-007's newest ticket merged after the candidate, so it waits for the next
I6=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); tk "$I6" fix S03 ROW-007 'ROW-007=owed-staging'; mg 30 "$I6"
cs owed; ok '^cs 1$'; cs ask --cs 1; ok '^asked [0-9]* cs stage-1$'; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$N/body
grep -qx 'close: staging-1' "$B" && grep -qx 'against: http://127.0.0.1:5001' "$B" && grep -qx 'signin: subscriber http://127.0.0.1:5001/signin' "$B" && grep -qx 'engines: alpha beta' "$B" || fail "the CS ask: $(head -n 5 "$B")"
for r in ROW-003 SEAM-001 SEAM-002 RULE-001 DIF-001; do grep -q -- "^- chunk p1c[0-9]*, alpha: .*$r" "$B" || fail "CS leaves out $r"; done
for r in ROW-004 ROW-001 ROW-006 ROW-002 ROW-007; do ! grep -q -- "$r" "$B" || fail "CS runs $r"; done; ! grep -q p1cx "$B" || fail 'CS has a rest chunk'
# an earlier CS of the stage found ROW-003 red (a plant: candidate 0's folder)
mkdir -p .vid/decide/stage/1/0/cs; printf 'issue\t1\ncommit\tx\nasked\t2026-11-09T00:00:00Z\n' > .vid/decide/stage/1/0/cs/ask; printf 'ROW-003\tits test in alpha\n' > .vid/decide/stage/1/0/cs/acted
# a rule row with no covers: line asked again; then red DIF-001 failing with a fix line, ROW-003 red again the owner's, the rest paid
P='ROW-003=fail:gone SEAM-001=pass RULE-001=pass DIF-001=fail:nope'; rq p1c1-1 "$X" alpha $P SEAM-002=pass; COV='covers: RULE-001 3'; rq p2c1-1 "$X" beta $P; COV=''; fetch
cs decide --stage 1; ok '^close-again staging-1 p1c1$'; no '^failing '
COV='covers: RULE-001 3'; rq p1c1-2 "$X" alpha $P SEAM-002=pass; fetch; cs decide --stage 1; ok '^failing DIF-001$'; ok '^paid SEAM-001$'; ok '^paid RULE-001$'; ok '^close-twice staging-1 ROW-003$'; no '^paid DIF-001$'
no '^paid SEAM-002$'   # passed in alpha, no case in beta: not paid
grep -q "^fix DIF-001 | DIF-001: DIF-001 in alpha, DIF-001 in beta | CS #$N of stage 1: req-$N-p1c1-2, req-$N-p2c1-1 | stand-in: RM" .vid/tw/handed || fail "the fix line: $(grep '^fix' .vid/tw/handed)"
grep -q "^row DIF-001 failing | stand-in: CS #$N" .vid/tw/handed && grep -q "^row SEAM-001 paid | stand-in: CS #$N" .vid/tw/handed || fail 'paid or failing lines'
# the status counts by the inventory's marks: of the toy's five seam and staging-owed rows of stages 0 and 1, SEAM-001 is paid
# (RULE-001 is staging-owed in its ticket alone)
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: candidate 1 at [0-9a-f]* · C3 green · .* · D1 passed · CS red · paid 1 of 5 · findings [0-9]* of [0-9]* ruled · the close waits on [0-9, ]* · test site: http://127.0.0.1:5001, up$'   # v0.26.10.28.8 (R7): a passed D1, its CS red
# 0.26.11.1.1 (R1): a staging that stays up is up after its run's issue closes, never taken down
: > $K/cs/issue-closed; sh "$QS" addresses 1 > "$T/out" 2>&1; ok '^test site: http://127.0.0.1:5001, up$'; no 'taken down'; rm -f $K/cs/issue-closed
# the writer reads the handed record with its staged line, and writes CS's fix ticket in the first red row's own step
FL=$(sed -n 's/^\(fix DIF-001 .*\) | stand-in: RM$/\1/p' .vid/tw/handed); KF=$(printf '%s' "$FL" | cksum | cut -d' ' -f1); sh "$GS" spec-export > /dev/null 2>&1
F=$(sh "$CHECKS/writer.sh" write fix "$KF" 2> "$T/out") || fail 'the CS fix ticket was refused'; grep -qx -- '- step: S04' "$F" || fail "the CS fix ticket's step: $(grep -- '- step:' "$F")"
# a rule row covering zero places fails at CS
COV='covers: RULE-001 0'; rq p1c1-2 "$X" alpha $P SEAM-002=pass; fetch; sh "$RS" close --cs 1 > "$T/out" 2>&1; ok "^row${TAB}p1c1${TAB}alpha${TAB}RULE-001${TAB}failed${TAB}covers 0"
# a rule row with no case in phase 2 and no covers: line reads not run there
COV=''; rq p2c1-1 "$X" beta ROW-003=pass SEAM-001=pass DIF-001=pass; fetch; sh "$RS" close --cs 1 > "$T/out" 2>&1; ok "^row${TAB}p2c1${TAB}beta${TAB}RULE-001${TAB}not run"
# stage 1's CS done: staging is free, and stage 2's okay is the one owed
mkdir -p .vid/decide/stage/2/1; cp $K/ask $K/commit .vid/decide/stage/2/1/; : > .vid/decide/stage/2/1/named; : > .vid/decide/stage/2/1/passed; cs owed; ok '^okay staging 2$'
# stage 2's okay: a step named with brackets read literally; a retry asked runs on to lateness; a second failure there the owner's
cs okay --stage 2; I2=$(sed -n 's/^asked \([0-9]*\) okay stage-2$/\1/p' "$T/out"); [ -n "$I2" ] || fail 'no okay for stage 2'
dp "$I2" 1 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate [tenant]\nproduct change: no' "$X")"; fetch; cs decide --stage 2; ok '^d1-failed 2 migrate \[tenant\]$'
cs decide --stage 2; no '^d1-failed'; sed 's/^close-wait-minutes: 600$/close-wait-minutes: 0/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
cs decide --stage 2; ok '^close-again staging-2 d1$'; sed 's/^close-wait-minutes: 0$/close-wait-minutes: 600/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
dp "$I2" 2 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate [tenant]\nproduct change: no' "$X")"; fetch; cs decide --stage 2; ok '^d1-item 2 failed d1 at migrate \[tenant\] #[0-9]*$'
# a started okay with a refused report holds staging; lost, it holds no more; a later stage's candidate takes the okay from stage 2
printf 'vid: started\nby: DP\n' > "$T/c"; gh issue comment "$I2" -R $R --body-file "$T/c" > /dev/null; dp "$I2" 3 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")"; fetch; cs decide --stage 2; ok '^d1-refused 2 3$'
mkdir -p .vid/decide/stage/3/1; cp $K/ask $K/commit .vid/decide/stage/3/1/; : > .vid/decide/stage/3/1/named; : > .vid/decide/stage/3/1/passed; tw_hand "candidate 3"; fetch; cs owed; no '^okay staging'
echo "lost d1 #$((I2 * 1000 + 1))" >> .vid/decide/stage/2/1/d1/items; cs owed; ok '^okay staging 3$'
{ grep -v '^candidate 3 ' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed; rm -rf .vid/decide/stage/2/1/d1; tw_hand 'candidate 3'; cs owed; no '^okay staging 2$'; cs okay --stage 2; [ "$RC" != 0 ] || fail 'stage 2 got an okay under stage 3'"'"'s candidate'
exit 0

#!/bin/sh
# Purpose: selftest case — production in ticket mode (v0.26.10.27.1 R1–R7), checks/close.sh, results.sh and queue.sh on the writer's
# toy and the fake gh. A closed stage is planted (stage 1 closed at candidate 1, its C3, D1 and CS passed), as a fixture; the
# integration test closes one through ViD's own conditions. No rehearsal for stage 0. The rehearsal okay after the close; its report
# refused without sealed: yes, without change.txt's lines; `no backup yet` before any production; the owner's yes asked, never
# RM's. The production okay only after the yes; D2 refused without a first `backup` step, and the first without `logs:`; passed:
# production's commit. CP against production, its production-owed row paid when green, and stage 1 in production. A second round
# at candidate 2: a sealed rehearsal whose change.txt drops a field, the yes naming it, `no backup yet` refused now, CR against
# the copy paying the rehearsal-owed row; a candidate not descending from production gets no okay; an earlier okay in hand holds
# the next; a failed D2 asks for recovery and `vid: recovered` settles it, closing the okay; a lost deploy is the owner's at once,
# settled by `known`. The status line. 0.26.11.1.1: its rehearsal reports carry kept: lines and the kept step, its production
# reports duties.txt, and the owner's yes names the records kept (R3, R5). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-production: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
# dp <okay> <k> <report.txt> [<change.txt>] [<steps>]: a deploy report
# 0.26.11.1.1: a rehearsal's report holds its kept: line and kept step (R5); a production deploy's its duties.txt, each done (R3)
PDU=$(for d in service-switch-on backups point-in-time-recovery storage-versioning dns https monitoring; do printf '%s: done — on the host\n' "$d"; done)
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; KL=''; case " ${5:-restore migrate kept boot} " in *' backup '*) rr_put "$Q" duties.txt "$PDU" ;; *' kept '*) KL='\nkept: none — the toy has no table it only adds to' ;; esac
  rr_put "$Q" report.txt "$(printf "%s$KL\ndecisions: none" "$3")"; [ -z "${4:-}" ] || rr_put "$Q" change.txt "$4"; P=''; for x in ${5:-restore migrate kept boot}; do P="$P $x=pass"; done; rr_put "$Q" deploy.xml "$(rr_cases $P)"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | tr '+' ' ' | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
nxi() { echo $(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); }
# plant <c>: stage 1's candidate c at main, its C3, D1 and CS passed, closed
plant() { X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/$1; mkdir -p "$F/d1" "$F/cs"; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"
  : > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; : > "$F/cs/passed"; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate $1"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003,ROW-004 'ROW-004=owed-production'; mg 20 2; tk 3 step S04 ROW-002,DIF-001 'DIF-001=owed-rehearsal'; mg 21 3
for r in ROW-003 ROW-002; do tw_hand "row $r accepted"; done; for r in ROW-004 DIF-001; do tw_hand "row $r owed"; done; sh "$GS" tw-sync > /dev/null 2>&1
# no rehearsal for stage 0, nor before any close
cs owed; no '^okay rehearsal'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'; cs owed; no '^okay rehearsal'
# stage 1 closed: the rehearsal okay
plant 1; K=.vid/decide/stage/1/1; cs owed; ok '^okay rehearsal 1$'; no '^okay production'
cs okay --rehearsal 1; ok '^asked [0-9]* okay rehearsal-1$'; H=$(sed -n 's/^asked \([0-9]*\) okay rehearsal-1$/\1/p' "$T/out"); grep -qx 'okay: rehearsal' "$T/gh/issues/$H/body" && grep -qx "commit: $X" "$T/gh/issues/$H/body" || fail 'the rehearsal okay body'
cs owed; no '^okay rehearsal'
CH=$(printf 'migrates: no\ndrops: none\nservices: none')
# the report's refusals: a passed one not sealed; no change.txt lines
dp "$H" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\ncopy: http://127.0.0.1:5101' "$X")" "$CH"; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok 'refused.*not sealed: yes'
dp "$H" 1 "$(printf 'by: DP\ncommit: %s\noutcome: no backup yet' "$X")" 'migrates: no'; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok 'refused.*change.txt has no drops: line'
# no backup yet, before any production: the owner's yes asked, never RM's
dp "$H" 1 "$(printf 'by: DP\ncommit: %s\noutcome: no backup yet' "$X")" "$CH" ''; fetch; cs decide --stage 1; ok '^rh 1 no backup yet$'; ok '^production-yes-asked 1 1$'; cs owed; no '^cr '; no '^okay production'
QY=$(qn 'Rehearsal of'); [ -n "$QY" ] || fail 'no yes item'; grep -q "^- $QY · .*no backup yet, the first deploy; migrates no; outside services changing: none; records kept: none. Deploy to production? yes or no" .vid/RUN-STATE.md || fail "the yes: $(grep "^- $QY" .vid/RUN-STATE.md)"
! sh "$QS" answer "$QY" --by RM yes 'on the owner'"'"'s behalf' > "$T/out" 2>&1 || fail 'RM gave the production yes'
# v0.26.10.27.4 (R4): the grade before the first go-live, offered on the item; grade the owner's alone; its hold on every yes, across items
grep -q "^- $QY · .* · A grade of the whole product is offered first: answer grade, or yes without it.$" .vid/RUN-STATE.md || fail "no offer on the item: $(grep "^- $QY" .vid/RUN-STATE.md)"
! sh "$QS" answer "$QY" --by RM grade 'for the owner' > "$T/out" 2>&1 || fail 'RM asked the offered grade'
mkdir -p .vid/decide/stage/1/9; git --git-dir="$T/code.git" rev-list --max-parents=0 main | head -n 1 > .vid/decide/stage/1/9/commit; : > .vid/decide/stage/1/9/named; printf 'issue\t999\ncommit\t%s\nasked\t2099-01-01T00:00:00Z\n' "$(cat .vid/decide/stage/1/9/commit)" > .vid/decide/stage/1/9/ask   # a newer named candidate at another commit
sh "$QS" answer "$QY" grade 'grade it first — the owner' > "$T/out" 2>&1 || fail "the offered grade was refused: $(cat "$T/out")"; GA=$(sed -n 's/^asked \([0-9]*\) grade before the first go-live$/\1/p' "$T/out"); [ -n "$GA" ] || fail 'no grade ask'
grep -qx "commit: $(cat .vid/decide/stage/1/1/commit)" "$T/gh/issues/$GA/body" || fail "the offered grade is not at the item's candidate: $(grep '^commit:' "$T/gh/issues/$GA/body")"; rm -rf .vid/decide/stage/1/9
grep -q '^grade: ask-' "$T/gh/issues/$GA/body" && grep -qx "grade $GA" .vid/decide/queue/offer || fail 'the grade ask or its record'
! sh "$QS" answer "$QY" yes 'yes — the owner' > "$T/out" 2>&1 && grep -q 'waits: the grade before the first go-live' "$T/out" || fail 'a yes was taken while the grade is out'
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1; grep -q "^offer: the grade before the first go-live, ask #$GA, holds every production yes$" "$T/out" || fail 'no offer line in the status'   # R7
YF=$(ls .vid/decide/stage/1/*/yes | tail -n 1); cp "$YF" "$T/yes0"; sed '1s/^production:\([0-9]*\):\([0-9]*\):[0-9]*/production:\1:\2:999/' "$T/yes0" > "$YF"; sh "$QS" sync > /dev/null 2>&1; QZ=$(qn 'Rehearsal of'); [ -n "$QZ" ] && [ "$QZ" != "$QY" ] || fail "no later item ($QZ)"
! sh "$QS" answer "$QZ" yes 'yes on the later one — the owner' > "$T/out" 2>&1 || fail 'a later item bypassed the hold'; ! grep -q "^- $QZ · .*offered first" .vid/RUN-STATE.md || fail 'the later item offers again'
cp "$T/yes0" "$YF"; printf 'ask\tread\nfinding\tfinding: bug high — the digest repeats a job\n' > .vid/decide/grade/$GA/read; : > .vid/decide/grade/$GA/done; sh "$QS" sync > /dev/null 2>&1   # read, one finding
QF=$(sed -n "s/^- \(Q[0-9]*\) · .*grade ask #$GA.*/\1/p;s/^- \(Q[0-9]*\) · .*digest repeats a job.*/\1/p" .vid/RUN-STATE.md | head -n 1); [ -n "$QF" ] || fail "no Q line for the grade's finding: $(grep '^- Q' .vid/RUN-STATE.md)"
! sh "$QS" answer "$QY" yes 'yes — the owner' > /dev/null 2>&1 || fail 'a yes was taken with the grade read and its finding unruled'
sh "$QS" answer "$QF" no 'not a bug — the owner' > "$T/out" 2>&1 || fail "the finding could not be ruled: $(cat "$T/out")"; sh "$QS" sync > /dev/null 2>&1   # ruled: the hold ends
sh "$QS" answer "$QY" yes 'yes, deploy — the owner' > "$T/out" 2>&1 || fail 'the yes was refused'; grep -q '^production-yes stage=1 candidate=1' .vid/metrics-events || fail 'no production-yes event'
# the production okay; D2 refused without its first backup step, and the first without logs:
cs owed; ok '^okay production 1$'; cs okay --production 1; ok '^asked [0-9]* okay production-1$'; P2=$(sed -n 's/^asked \([0-9]*\) okay production-1$/\1/p' "$T/out")
grep -q 'Back up production first' "$T/gh/issues/$P2/body" || fail 'the production okay body'
dp "$P2" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201\nlogs: docker logs prod' "$X")" '' 'deploy smoke'; fetch; sh "$RS" deploy --stage 1 --kind d2 > "$T/out" 2>&1; ok "refused.*first step is not backup"
dp "$P2" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201' "$X")" '' 'backup deploy'; fetch; sh "$RS" deploy --stage 1 --kind d2 > "$T/out" 2>&1; ok 'refused.*the first production deploy has no logs: line'
# a newer candidate of stage 1 named while D2 is out (a plant, taken away once CP is asked): the earlier okay is still read, CP at it
G2=.vid/decide/stage/1/2; mkdir -p $G2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $G2/ask; echo "$X" > $G2/commit; : > $G2/named
dp "$P2" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201\nlogs: docker logs prod' "$X")" '' 'backup deploy'; fetch; cs decide --stage 1; ok '^d2 1 passed$'; ok '^logs 1: docker logs prod$'
grep -q "^$X	D2 #$P2	" .vid/decide/production || fail "production's commit: $(cat .vid/decide/production 2>/dev/null)"
# CP: against production, its production-owed row paid when green, stage 1 in production
cs owed; ok '^cp 1$'; cs ask --cp 1; N=$(sed -n 's/^asked \([0-9]*\) cp stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$N/body; [ -f $K/cp/ask ] || fail 'CP not asked at the D2 candidate'
grep -qx 'close: production-1' "$B" && grep -qx 'against: http://127.0.0.1:5201' "$B" && grep -q 'your own production test accounts' "$B" || fail "the CP ask: $(head -n 5 "$B")"
grep -q -- '- chunk p1c1, alpha: .*ROW-004' "$B" && grep -q -- '- chunk p1c1, alpha: .*ROW-003' "$B" && ! grep -q 'DIF-001' "$B" || fail "CP's rows: $(grep chunk "$B")"
# a red CP at candidate 1, read at its own candidate though a newer one is named: recovery asked, nothing in production; DP recovers
# production to this very commit, which counts as its D2: a new CP is owed, and once green stage 1 is in production
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cp/ask); do P="$P $r=fail:boom"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; ok "^recovery-asked 1 #$P2\$"; no '^in production'
printf 'vid: recovered %s — fixed in place\nby: DP\n' "$(printf %.12s "$X")" > "$T/c"; gh issue comment "$P2" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P2 at "
cs owed; ok '^cp 1$'; cs ask --cp 1; N=$(sed -n 's/^asked \([0-9]*\) cp stage-1$/\1/p' "$T/out"); [ -n "$N" ] || fail "the second CP: $(cat "$T/out")"
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cp/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; ok '^paid ROW-004$'; ok '^in production 1 at '; rm -rf $G2
grep -q "^production 1 | stand-in: D2 #$P2 at $(printf %.12s "$X")" .vid/tw/handed && grep -q "^production stage=1 commit=$X" .vid/metrics-events || fail 'not in production'
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: .* · RH no backup · yes · D2 recovered · CP green · in production'
sh "$QS" addresses 1 > "$T/out" 2>&1; ok '^live copy: http://127.0.0.1:5201$'   # v0.26.10.28.8 (R7): the real D2 reads' production line, after a recovery
sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail "the writer refused the production line: $(tail -n 1 "$T/out")"   # 8.1b's real test: the handed line in the writer's allow-list
cs owed; no '^okay rehearsal'; no '^okay production'   # production runs this candidate: nothing more is owed for it
# a second round: candidate 2, a sealed rehearsal dropping a field; no backup yet refused now production exists
tk "$(nxi)" fix S04 ROW-002 ''; mg 22 "$(( $(nxi) - 1 ))"; plant 2; K=.vid/decide/stage/1/2; cs owed; ok '^okay rehearsal 1$'; cs okay --rehearsal 1; H=$(sed -n 's/^asked \([0-9]*\) okay rehearsal-1$/\1/p' "$T/out")
dp "$H" 1 "$(printf 'by: DP\ncommit: %s\noutcome: no backup yet' "$X")" "$CH" ''; fetch; sh "$RS" deploy --stage 1 --kind rh > "$T/out" 2>&1; ok 'refused.*no backup yet, though production runs'
dp "$H" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nsealed: yes\ncopy: http://127.0.0.1:5102\nsignin: subscriber http://127.0.0.1:5102/in' "$X")" "$(printf 'migrates: yes\ndrops: the sample nickname column\nrewrites: none\nservices: none')"; fetch
cs decide --stage 1; ok '^rh 1 passed$'; cs owed; ok '^cr 1$'; no '^okay production'
cs ask --cr 1; N=$(sed -n 's/^asked \([0-9]*\) cr stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$N/body
grep -qx 'close: rehearsal-1' "$B" && grep -qx 'against: http://127.0.0.1:5102' "$B" && grep -qx 'signin: subscriber http://127.0.0.1:5102/in' "$B" && grep -q 'DIF-001' "$B" && ! grep -q 'ROW-004' "$B" || fail "the CR ask: $(grep -E 'against|chunk' "$B")"
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cr/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; ok '^paid DIF-001$'; ok '^production-yes-asked 1 2$'
QY=$(qn "Rehearsal of $(printf %.12s "$X")"); grep -q "^- $QY · .*migrates yes; drops the sample nickname column — confirm; outside services changing: none" .vid/RUN-STATE.md || fail "the second yes: $(grep "^- $QY" .vid/RUN-STATE.md)"
cs owed; no '^okay production'; sh "$QS" answer "$QY" no 'not yet — the owner' > /dev/null 2>&1; [ -n "$(qn 'declined: the owner may still say yes')" ] || fail 'a no closed the item'
sh "$QS" answer "$QY" yes 'now yes — the owner' > /dev/null 2>&1; cs owed; ok '^okay production 1$'
# a failed D2: recovery asked; vid: recovered settles it, the okay closed; again re-arms it
cs okay --production 1; P3=$(sed -n 's/^asked \([0-9]*\) okay production-1$/\1/p' "$T/out")
dp "$P3" 1 "$(printf 'by: DP\ncommit: %s\noutcome: failed deploy\nproduction: http://127.0.0.1:5201' "$X")" '' 'backup deploy'; fetch; cs decide --stage 1; ok "^recovery-asked 1 #$P3\$"
grep -rq '^Production failed at deploy' "$T/gh/issues/$P3/comments" || fail 'no recovery asked'; cs owed; no '^okay production'
# after a failed report, a later passed attempt with no recovery reconciles nothing; a recovery comment naming no commit is not read
dp "$P3" 2 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201' "$X")" '' 'backup deploy'; fetch; cs decide --stage 1; no '^d2 1 passed'; cs owed; no '^okay production'; no '^cp '
P0=$(tail -n 1 .vid/decide/production); printf 'vid: recovered — rolled back by hand\nby: DP\n' > "$T/c"; gh issue comment "$P3" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered-unread 1 #$P3"; [ "$(tail -n 1 .vid/decide/production)" = "$P0" ] || fail 'an empty recovery recorded'

printf 'vid: recovered %s — rolled back to the previous release\nby: DP\n' "$(printf %.12s "$(cat .vid/decide/stage/1/1/commit)")" > "$T/c"; gh issue comment "$P3" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P3 at "
grep -qx CLOSED "$T/gh/issues/$P3/state" && grep -q '^recovered ' $K/d2/closed || fail 'the recovered okay not closed'; tail -n 1 .vid/decide/production | grep -q "recovered #$P3" || fail "production's commit after the recovery"
QA=$(qn 'reconciled at'); [ -n "$QA" ] || fail 'no again item'; sh "$QS" answer "$QA" again 'deploy it again — the owner' > /dev/null 2>&1; cs decide --stage 1; ok '^d2-again 1$'; cs owed; ok '^okay rehearsal 1$'; no '^okay production'   # the recovery moved production's commit: rehearse again
# a lost deploy: the owner's at once, settled by known; it holds the next meanwhile
P4=$(nxi); gh issue create -R $R --title "d2 lost" --body 'okay: production' --label deploy > /dev/null; mkdir -p $K/d2; printf 'issue\t%s\ncommit\t%s\nasked\t2026-01-01T00:00:00Z\n' "$P4" "$X" > $K/d2/ask   # an okay given long ago (a plant)
fetch; cs decide --stage 1; ok "^production-lost 1 #$P4\$"; cs owed; no '^okay production'; QL=$(qn "Production's deploy (#$P4"); [ -n "$QL" ] || fail 'no lost item'
! sh "$QS" answer "$QL" --by RM known none > "$T/out" 2>&1 || fail 'RM settled what production runs'
printf 'vid: started\nby: DP\n' > "$T/c"; gh issue comment "$P4" -R $R --body-file "$T/c" > /dev/null; fetch   # it started after the item was raised
! sh "$QS" answer "$QL" known none 'nothing ran there yet' > "$T/out" 2>&1 || fail 'known settled a deploy that started'; grep -q 'started: only DevAgent' "$T/out" || fail "known for a deploy that started was refused for another reason: $(cat "$T/out")"; rm -f "$T/gh/issues/$P4/comments/"*; fetch   # the plant taken back
! sh "$QS" answer "$QL" known none 'nothing ran there yet' > "$T/out" 2>&1 || fail 'known none accepted though a production exists'; grep -q 'known none is for a first deploy' "$T/out" || fail "known none was refused for another reason: $(cat "$T/out")"
sh "$QS" answer "$QL" known "$X" 'the rehearsed commit runs there' > "$T/out" 2>&1 || fail "known was refused: $(cat "$T/out")"; grep -q '^known ' $K/d2/closed || fail 'the lost okay not closed'
QK=$(qn 'reconciled at'); [ -n "$QK" ] || fail 'no again item after known, before any decide'; sh "$QS" answer "$QK" again 'deploy it again — the owner' > /dev/null 2>&1
sh "$CS" out > "$T/out" 2>&1; ok '^out stage-1$'; cs decide --stage 1; ok '^d2-again 1$'; cs owed; ok '^okay rehearsal 1$'   # known the okay's own commit: rehearse again
# a candidate not descending from production's commit gets no okay
git -C "$T/dev" checkout -q -b side "$(cat .vid/decide/stage/1/1/commit)~1" 2>/dev/null || git -C "$T/dev" checkout -q -b side; git -C "$T/dev" -c user.name=a -c user.email=a@b commit -q --allow-empty -m side; git -C "$T/dev" push -q origin side
S3=$(git --git-dir="$T/code.git" rev-parse side); printf '%s\tD2 #99\t%s\n' "$(git --git-dir="$T/code.git" rev-parse main)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/decide/production
mkdir -p .vid/decide/stage/1/3/d1 .vid/decide/stage/1/3/cs; F=.vid/decide/stage/1/3; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$S3" > $F/ask; echo "$S3" > $F/commit; : > $F/named; : > $F/passed; : > $F/d1/passed; : > $F/cs/passed
tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$S3") candidate 3"; mkdir -p $F/rh $F/cr; printf 'issue\t5\ncommit\t%s\nasked\t2099-01-01T00:00:00Z\n' "$S3" > $F/rh/ask; : > $F/rh/passed; : > $F/cr/passed
printf 'production:1:3:5\tRehearsal of side3. Deploy to production? yes or no\n' > $F/yes; [ -z "$(qn 'Rehearsal of side3')" ] || fail 'a yes item open for a candidate not descending from production'
printf '%s\tproduction:1:3:5\tyes\tyes\towner\tapproved\n' "2099-01-02T00:00:00Z" >> .vid/decide/queue/answers; cs owed; no '^okay production'
# the wait for a deploy that started runs 25 hours from its start comment, not from the okay (candidate 4, a plant)
P5=$(nxi); gh issue create -R $R --title "d2 started" --body 'okay: production' --label deploy > /dev/null; printf 'vid: started\nby: DP\n' > "$T/c"; gh issue comment "$P5" -R $R --body-file "$T/c" > /dev/null
F=.vid/decide/stage/1/4; mkdir -p $F/d2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$S3" > $F/ask; echo "$S3" > $F/commit; : > $F/named; : > $F/passed; printf 'issue\t%s\ncommit\t%s\nasked\t2026-01-01T00:00:00Z\n' "$P5" "$S3" > $F/d2/ask
fetch; cs decide --stage 1; no "^production-lost 1 #$P5"; touch -t 202601010000 $F/d2/started; cs decide --stage 1; ok "^production-lost 1 #$P5\$"; grep -q "^$P5	1	4	started$" .vid/decide/production-lost || fail 'not lost as started'
# a deploy lost as started, which then reports failed and leaves its recovery unanswered past the wait: a reported line, the item
# says so; DP recovers it late, elsewhere: settled, its again item at an older candidate; after again the lost item stays gone (candidate 5)
P6=$(nxi); gh issue create -R $R --title "d2 failed" --body 'okay: production' --label deploy > /dev/null; gh issue comment "$P6" -R $R --body-file "$T/c" > /dev/null
F=.vid/decide/stage/1/5; mkdir -p $F/d2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$S3" > $F/ask; echo "$S3" > $F/commit; : > $F/named; : > $F/passed; printf 'issue\t%s\ncommit\t%s\nasked\t2026-01-01T00:00:00Z\n' "$P6" "$S3" > $F/d2/ask
fetch; cs decide --stage 1; touch -t 202601010000 $F/d2/started; cs decide --stage 1; ok "^production-lost 1 #$P6\$"
dp "$P6" 1 "$(printf 'by: DP\ncommit: %s\noutcome: failed deploy\nproduction: http://127.0.0.1:5201' "$S3")" '' 'backup deploy'; fetch; cs decide --stage 1; ok "^recovery-asked 1 #$P6\$"
touch -t 202601010000 $F/d2/recovery-asked; cs decide --stage 1; ok "^production-lost 1 #$P6\$"; grep -q "^$P6	1	5	reported$" .vid/decide/production-lost || fail "no reported line: $(grep "^$P6	" .vid/decide/production-lost)"
[ -n "$(qn "#$P6, stage 1) failed, and no recovery was reported")" ] || fail "the reported item's words"
QR=$(qn "#$P6, stage 1) failed, and no recovery was reported"); ! sh "$QS" answer "$QR" known none 'nothing ran there yet' > "$T/out" 2>&1 || fail 'known settled a failed deploy that had started'; grep -q 'started: only DevAgent' "$T/out" || fail "known for a failed deploy that started was refused for another reason: $(cat "$T/out")"
# candidate 6 at production's commit, closed, rehearsed, CR green, the owner's yes given (a plant), so later okays can be seen held or not
X6=$(git --git-dir="$T/code.git" rev-parse main); F6=.vid/decide/stage/1/6; mkdir -p $F6/d1 $F6/cs $F6/rh $F6/cr; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X6" > $F6/ask; echo "$X6" > $F6/commit
: > $F6/named; : > $F6/passed; : > $F6/d1/passed; : > $F6/cs/passed; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X6") candidate 6"; printf 'issue\t7\ncommit\t%s\nasked\t2099-01-05T00:00:00Z\n' "$X6" > $F6/rh/ask; : > $F6/rh/passed; : > $F6/cr/passed
printf '%s\tproduction:1:6:7\tyes\tyes\towner\tapproved\n' "2099-01-06T00:00:00Z" >> .vid/decide/queue/answers
printf 'vid: recovered %s — rolled back late\nby: DP\n' "$(printf %.12s "$(cat .vid/decide/stage/1/1/commit)")" > "$T/c"; gh issue comment "$P6" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P6 at "
[ -z "$(qn "Production's deploy (#$P6")" ] || fail 'the lost item open once recovered'; Q6=$(qn "stage-1: $(printf %.12s "$S3") reconciled"); [ -n "$Q6" ] || fail 'no again item at an older candidate'
sh "$QS" answer "$Q6" again 'again — the owner' > /dev/null 2>&1; cs decide --stage 1; ok '^d2-again 1$'; [ -z "$(qn "Production's deploy (#$P6")" ] || fail 'the settled lost item came back after again'
# a recovery to the okay's own candidate: CP at it, production's address from an earlier report, and no later okay until CP is green
printf 'vid: recovered %s — the deploy finished by hand\nby: DP\n' "$(printf %.12s "$S3")" > "$T/c"; gh issue comment "$P5" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P5 at "
cs owed; ok '^cp 1$'; no '^okay production'; cs ask --cp 1; [ -f .vid/decide/stage/1/4/cp/ask ] && grep -qx 'against: http://127.0.0.1:5201' "$T/gh/issues/$(sed -n 's/^asked \([0-9]*\) cp stage-1$/\1/p' "$T/out")/body" || fail "CP after a recovery to its candidate: $(cat "$T/out")"
# while candidate 4's CP is out the next okay is held; a red CP, then DP recovers production elsewhere: settled, the okay owed again
N=$(sed -n 's/^asked \([0-9]*\) cp stage-1$/\1/p' "$T/out"); cs owed; no '^okay production'
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' .vid/decide/stage/1/4/cp/ask); do P="$P $r=fail:boom"; done; rq p1c1-1 "$S3" alpha $P; fetch; cs decide --stage 1; ok "^recovery-asked 1 #$P5\$"; cs owed; no '^okay production'
touch -t 202601010000 .vid/decide/stage/1/4/d2/recovery-asked; cs decide --stage 1; ok "^production-lost 1 #$P5\$"   # a lost line settled earlier hides no later unanswered recovery
printf 'vid: recovered %s — rolled back\nby: DP\n' "$(printf %.12s "$X6")" > "$T/c"; gh issue comment "$P5" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P5 at "; cs owed; ok '^okay production 1$'
# a superseded candidate's red CR keeps nothing out (candidate 3, a plant)
printf 'issue\t8\ncommit\t%s\nasked\t2099-01-01T00:00:00Z\n' "$S3" > .vid/decide/stage/1/3/cr/ask; rm -f .vid/decide/stage/1/3/cr/passed; : > .vid/decide/stage/1/3/cr/done; sh "$CS" out > "$T/out" 2>&1; no 'out stage-1'
# a recovery elsewhere withdraws an open CP: its late green report pays nothing and puts nothing in production (candidate 6)
cs okay --production 1; P7=$(sed -n 's/^asked \([0-9]*\) okay production-1$/\1/p' "$T/out"); dp "$P7" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201' "$X6")" '' 'backup deploy'; fetch; cs decide --stage 1; ok '^d2 1 passed$'
cs owed; ok '^cp 1$'; cs ask --cp 1; N=$(sed -n 's/^asked \([0-9]*\) cp stage-1$/\1/p' "$T/out"); [ -f $F6/cp/ask ] || fail 'CP not asked at candidate 6'
printf 'vid: recovered %s — rolled back\nby: DP\n' "$(printf %.12s "$(cat .vid/decide/stage/1/1/commit)")" > "$T/c"; gh issue comment "$P7" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P7 at "; [ -f $F6/cp/withdrawn ] || fail 'the open CP not withdrawn'
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $F6/cp/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X6" alpha $P; fetch; cs decide --stage 1; no '^in production'; no '^paid '
# a lost deploy that then reports passed: its lost item gone (candidate 7, a plant)
P8=$(nxi); gh issue create -R $R --title "d2 late" --body 'okay: production' --label deploy > /dev/null; F7=.vid/decide/stage/1/7; mkdir -p $F7/d2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X6" > $F7/ask; echo "$X6" > $F7/commit; : > $F7/named; : > $F7/passed
printf 'issue\t%s\ncommit\t%s\nasked\t2026-01-01T00:00:00Z\n' "$P8" "$X6" > $F7/d2/ask; fetch; cs decide --stage 1; ok "^production-lost 1 #$P8\$"
dp "$P8" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\nproduction: http://127.0.0.1:5201' "$X6")" '' 'backup deploy'; fetch; cs decide --stage 1; ok '^d2 1 passed$'; [ -z "$(qn "#$P8, stage 1) has not reported")" ] || fail 'a lost item open after its passed report'
# a recovery to the okay's own commit with no production address on record settles it (candidate 8; a plant hides every D2 read)
P9=$(nxi); gh issue create -R $R --title "d2 first" --body 'okay: production' --label deploy > /dev/null; F8=.vid/decide/stage/1/8; mkdir -p $F8/d2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X6" > $F8/ask; echo "$X6" > $F8/commit; : > $F8/named; : > $F8/passed
printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$P9" "$X6" > $F8/d2/ask; for f in .vid/decide/stage/*/*/d2*/read; do mv "$f" "$f.hid"; done
printf 'vid: recovered %s — deployed by hand\nby: DP\n' "$(printf %.12s "$X6")" > "$T/c"; gh issue comment "$P9" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok "^recovered 1 #$P9 at "
[ ! -f $F8/d2/atcand ] && grep -q '^recovered ' $F8/d2/closed || fail 'an own-commit recovery with no address left CP owed'; for f in .vid/decide/stage/*/*/d2*/read.hid; do mv "$f" "${f%.hid}"; done
# a failed deploy that never posted vid: started, its recovery unanswered past the wait: the owner's known settles it (candidate 9)
P10=$(nxi); gh issue create -R $R --title "d2 quiet" --body 'okay: production' --label deploy > /dev/null; F9=.vid/decide/stage/1/9; mkdir -p $F9/d2; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X6" > $F9/ask; echo "$X6" > $F9/commit; : > $F9/named; : > $F9/passed
printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$P10" "$X6" > $F9/d2/ask; dp "$P10" 1 "$(printf 'by: DP\ncommit: %s\noutcome: failed deploy\nproduction: http://127.0.0.1:5201' "$X6")" '' 'backup deploy'; fetch; cs decide --stage 1; ok "^recovery-asked 1 #$P10\$"
touch -t 202601010000 $F9/d2/recovery-asked; cs decide --stage 1; ok "^production-lost 1 #$P10\$"; QQ=$(qn "#$P10, stage 1) failed"); [ -n "$QQ" ] && [ -n "$(qn "#$P10, stage 1) failed.*answer known")" ] || fail 'the item for a deploy that never started'
sh "$QS" answer "$QQ" known "$X6" 'that commit runs there' > "$T/out" 2>&1 || fail "known refused for a deploy that never posted vid: started: $(cat "$T/out")"
exit 0

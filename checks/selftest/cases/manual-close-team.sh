#!/bin/sh
# Purpose: selftest case — a close reads a team's results by the form and the pool a ticket's are read by (FB-3 A1.5), in GitHub manual, by
# close.sh and results.sh on the writer's toy and the fake gh. While no engines are named no step's close is owed, `close.sh owed` and
# `round.sh asks` go on, and a direct call is refused with the reason. Named: the ask says the chunk's report is by anyone, its files of
# any name, and nothing else of it changes. A chunk reported by a person, in suite files that share the rows out: green, each engine of
# the chunk; a failed case red, a skipped one beside a pass nothing. The names of the accepted report's cases-<engine>.xml, found under
# any id at the ticket's commit, must be in that engine's chunk, else `not run`; with no such file the pool decides. The rest chunk with
# no case is whole with `none left` alone. A deploy report is by anyone, at the commit asked. The step closes on them. A staging run is asked and read the same. In GitHub auto the
# same reports are refused as before, and the ask's words are the dev side's. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "manual-close-team: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
# tm <id> <file>=<case words>…: a report by a person at main
tm() { _i=$1; shift; rm -rf "$T/r/$_i"; rr_put "$_i" results.txt "$(printf 'by: A. Person\ncommit: %s\n%s' "$M" "${NOTE:-}")"; for _f; do rr_put "$_i" "${_f%%=*}" "$(rr_cases ${_f#*=})"; done; send "$_i"; }
rd() { sh "$GS" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/results.sh" close --step S01 > "$T/out" 2>&1 || fail 'the close could not be read'; }
tw_toy "$T/p"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); M12=$(printf %.12s "$M"); printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
gh issue create -R $R --title 'Skeleton' --body 'the skeleton' > /dev/null
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n> ROW-001 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-001 marks: none\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-001 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log
printf 'step-1-%s\n' "$M12" > .vid/decide/merged-prs; printf 'step-1-%s\t1\t%s\t%s\n' "$M12" "$M" "$M" > .vid/decide/merges
for r in ROW-001 ROW-003; do printf '2026-11-09T11:00:00Z\tstep-1\t%s\t%s\taccepted\n' "$M12" "$r"; done > .vid/decide/log
# no engines named: nothing is owed, and nothing stops
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
cs owed; [ "$RC" = 0 ] && ! grep -q '^close S01' "$T/out" || fail 'a close is owed with no engines named'
sh "$CHECKS/round.sh" asks > "$T/out" 2>&1 || fail 'round.sh asks stopped with no engines named'
cs step S01; [ "$RC" = 1 ] || fail "a close with no engines exited $RC"; ok '^refused S01: the handed record names no engines yet$'
printf 'engines alpha beta | stand-in: owner at 2026-11-09T11:00:00Z, words "yes"\n' >> .vid/tw/handed; cs owed; ok '^close S01$'
# the ask's words
cs step S01; ok '^asked [0-9]* close S01$'; N=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out"); N1=$N; cp "$T/gh/issues/$N/body" "$T/out"
! grep -qE 'by: TM|cases-<engine>' "$T/out" || fail 'the ask asks for a role or an engine file'
ok "Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, its results.txt beginning by: and the name of whoever made it, its commit the one above, with one results file or more (.xml), of any name, then comment \`vid: reported <chunk>-<k>\` here. Comment \`vid: started\` when the first chunk starts."
# a person's chunk, its rows shared out over suites
tm "req-$N-p1c1-1" 'web.xml=ROW-003=pass ROW-001=skip' 'back.xml=ROW-001=fail:no_digest'; rd; ok "^chunk	p1c1	red	1$"; ok '^row	p1c1	alpha	ROW-001	failed	ROW-001$'; ok '^row	p1c1	alpha	ROW-003	passed$'; ok '^chunk	p2c1	absent	-$'
tm "req-$N-p1c1-2" 'web.xml=ROW-003=pass ROW-001=skip' 'back.xml=ROW-001=pass'; tm "req-$N-p2c1-1" 'all.xml=ROW-003=pass ROW-001=pass'; rd; ok "^chunk	p1c1	green	2$"; ok '^row	p1c1	alpha	ROW-001	passed$'; ok '^row	p2c1	beta	ROW-001	passed$'; ! grep -q '^refused\|^split' "$T/out" || fail 'a report is refused, or a split told'
# the accepted report's names, under any id, in its engine's chunk alone
tm ci-77 'cases-alpha.xml=ROW-003=pass ROW-003-second=pass ROW-001=pass' 'other.xml=ROW-001-third=pass'; rd; ok '^row	p1c1	alpha	ROW-003	not run$'; ok '^row	p1c1	alpha	ROW-001	passed$'; ok '^row	p2c1	beta	ROW-003	passed$'; ok '^chunk	p1c1	incomplete	2$'
# the rest chunk, and a deploy report by anyone
A=.vid/decide/close/S01/1/ask; cp "$A" "$T/ask0"; printf 'chunk\tp1cx\talpha\t\n' >> "$A"; tm "req-$N-p1cx-1" 'none.xml='; rd; ok '^chunk	p1cx	absent	1$'; NOTE='none left' tm "req-$N-p1cx-2" 'none.xml='; rd; ok '^chunk	p1cx	green	2$'
NOTE=''; tm "req-$N-p1cx-3" 'suite.xml=stray-case=pass'; rd; ok '^chunk	p1cx	green	3$'; ok '^unmatched	stray-case	passed$'; cp "$T/ask0" "$A"   # its cases, in a file of any name
rr_put deploy-9-1 report.txt "$(printf 'by: A. Person\ncommit: %s\noutcome: passed' "$M")"; send deploy-9-1; sh "$GS" results-fetch > /dev/null 2>&1; sh "$CHECKS/results.sh" check deploy-9-1 --ticket 1 --commit "$M" > "$T/out" 2>&1 || fail 'a deploy report by a person is refused'
! sh "$CHECKS/results.sh" check deploy-9-1 --ticket 1 --commit "$(git --git-dir="$T/code.git" rev-parse main^ 2>/dev/null || echo 0123456789abcdef0123456789abcdef01234567)" > "$T/out" 2>&1 || fail 'a deploy report at another commit is taken'
# the step closes on them
tm "req-$N-p1c1-3" 'web.xml=ROW-003=pass ROW-003-second=pass' 'back.xml=ROW-001=pass'; cs step S01; [ "$RC" = 0 ] || fail "the close exited $RC"; ok '^closed S01$'
# an ask number of ViD's own has no issue: nothing is sent for it, and the two exit 0
: > "$T/gh/writes"; echo words > "$T/w0"; for a in 'comment 0900001001 --body-file '"$T/w0" 'close 0910000001'; do sh "$GS" $a > "$T/out" 2>&1 || fail "github.sh $a exited $?"; done; [ ! -s "$T/gh/writes" ] && [ ! -s "$T/out" ] || fail "something was sent for an ask of ViD's own"
# the staging run's ask and read (CS, as CR and CP), by the same form and pool: a rule row is read by its covers: line only when there is one, and a
# row that could not run in an attempt stands on the attempt before it that passed
Z=.vid/decide/stage/0/1; mkdir -p "$Z/d1"; : > "$Z/named"; echo "$M" > "$Z/commit"; printf 'issue\t0\n' > "$Z/ask"; : > "$Z/d1/passed"; printf 'd1\tpassed\t1\nstaging\thttps://staging.invalid\n' > "$Z/d1/read"
cs ask --cs 0; ok '^asked [0-9]* '; N=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); cp "$T/gh/issues/$N/body" "$T/out"; ! grep -qE 'by: TM|cases-<engine>' "$T/out" || fail 'the staging run asks for a role or an engine file'
ok 'vid-results/req-<this issue>-<chunk>-<k>, its results.txt beginning by: and the name of whoever made it, .* of any name, and a covers: line for each rule row'
printf -- '- RULE-001 marks: rule\n' >> .vid/tw/out/issue-1.md; awk -F'\t' -v OFS='\t' '$1 == "chunk" { if ($2 != "p1c1") next; $4 = "ROW-003 RULE-001" } { print }' "$Z/cs/ask" > "$T/a" && cat "$T/a" > "$Z/cs/ask"
crd() { sh "$GS" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/results.sh" close --cs 0 > "$T/out" 2>&1 || fail 'the staging run could not be read'; }
tm "req-$N-p1c1-1" 'smoke.xml=ROW-003=pass ROW-003-second=pass RULE-001=pass'; crd; ok '^chunk	p1c1	green	1$'; ok '^row	p1c1	alpha	RULE-001	passed$'
NOTE='covers: RULE-001 0' tm "req-$N-p1c1-2" 'smoke.xml=ROW-003=err:setup:_no_host ROW-003-second=err:setup:_no_host RULE-001=pass'; crd; ok '^row	p1c1	alpha	RULE-001	failed	covers 0$'; ok '^row	p1c1	alpha	ROW-003	passed$'
# GitHub auto: the form as before
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; N=$N1; rd; ok "^refused	req-$N-p1c1-3	the first line of results.txt is not by: TM: by: A. Person$"
exit 0

#!/bin/sh
# Purpose: selftest case — a stage's staging run whose test cannot run there (PB-5), checks/close.sh, checks/queue.sh, checks/round.sh,
# checks/writer.sh, checks/results.sh and checks/decide.sh on the writer's toy and the fake gh (fixtures/closes.sh), GitHub auto. Lost twice
# alike in both engines, its rows could not run: one fix line in the fix lines' own words, both chunks waiting (`waits-fix`), two
# `close-unrun`, no question, no row's state, count or `acted` changed, the run not done, and the dev side owing nothing for it. Its
# ticket: the row `could not run there`, every engine asked, no Faulted row; at its head, passed is accepted, setup is evidence missing,
# failed is failing and counted. Merged: a new build; lost alike again: the owner's question, "after its fix"; passed: done; failed: a
# first red. Withdrawn by a plan change, or its line cut: the owner's question, keyed anew; then again and alike: the owner's, no second
# ticket. A held row or a red row in the run: the owner's, as today. Another chunk red while one waits: its red path, one fix; a late
# red of the waiting row: the unpublished line cut, one fix; published: it waits on the ticket. GitHub manual: as today. Env: CHECKS.
set -eu
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT; T=$B/t; mkdir -p "$T/home"; HOME=$T/home; export HOME; unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "cs-unrun-fix: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# snap <name>: the whole scene and the case's own values; back <name>: both as they were
snap() { ( cd "$T" && tar -cf "$B/$1.tar" . ); for v in X K N CSN ROWS CSR CN C3N; do eval "printf '%s=\"%s\"\n' $v \"\${$v:-}\""; done > "$B/$1.v"; }
back() { cd "$B"; rm -rf "$T"; mkdir -p "$T"; ( cd "$T" && tar -xf "$B/$1.tar" ); . "$B/$1.v"; cd "$T/toy"; }
U='err:setup:no-clock-at-/srv/a=1'; fixes() { grep -c '^fix ' .vid/tw/handed || true; }; hr() { grep '^row ROW-003 ' .vid/tw/handed || true; }
# rq2 <k> <alpha rows> -- <beta rows>: attempt k of both chunks, then decided
rq2() { k0=$1; shift; a0=''; while [ "$1" != -- ]; do a0="$a0 $1"; shift; done; shift; N=$CSN; rq "p1c1-$k0" "$X" alpha $(allof pass $a0); rq "p2c1-$k0" "$X" beta $(allof pass "$@"); fetch; cs decide --stage 1; [ "$RC" = 0 ] || fail "decide failed ($RC)"; }
qline() { sh "$QS" sync > /dev/null 2>&1; grep "^- Q[0-9]* · .*chunk $1, lost twice" .vid/RUN-STATE.md | tail -n 1; }
# a new build of stage 1: its candidate, full run, okay and staging run
nb() { X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; CN=$(sed -n 's/^candidate 1 //p' "$T/out"); [ -n "$CN" ] || fail 'no new candidate'
  N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); K=.vid/decide/stage/1/$CN; ROWS=$(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/ask); C3N=$N; cl_c3; cl_d1; cl_cs; }

cl_toy; printf 'ROW-001\taccepted\taccepted\t21\tx\tx\n' >> .vid/decide/state; cl_c3; cl_d1; cl_cs; H0=$(hr); K1=$K
case " $CSR " in *" ROW-003 "*) ;; *) fail "ROW-003 is not in the staging run's chunk: $CSR" ;; esac
snap s0; rq2 1 ROW-003="$U" -- ROW-003="$U"; ok '^close-again staging-1 p1c1$'; ok '^close-again staging-1 p2c1$'; snap s1

# (1) twice alike in both engines: one fix line, both chunks waiting, no question, nothing of the row changed, the run not done
rq2 2 ROW-003="$U" -- ROW-003="$U"
ok '^close-unrun staging-1 p1c1 ROW-003 #unpublished$'; ok '^close-unrun staging-1 p2c1 ROW-003 #unpublished$'; no 'close-lost'; no 'close-done'; no '^failing '
FX="fix ROW-003 | ROW-003: could not run there: its test in alpha, beta | CS #$CSN of stage 1: req-$CSN-p1c1-2, req-$CSN-p2c1-2 | stand-in: RM"
[ "$(fixes)" = 1 ] && grep -qxF "$FX" .vid/tw/handed || fail "not the one fix line: $(grep '^fix ' .vid/tw/handed)"
[ "$(sort -u $K/cs/waits-fix 2>/dev/null | grep -c .)" = 2 ] || fail "both chunks do not wait: $(cat $K/cs/waits-fix 2>/dev/null)"
[ "$(hr)" = "$H0" ] && ! grep -q ROW-003 .vid/decide/counts 2>/dev/null && [ ! -s $K/cs/acted ] && ! grep -q '^lost ' $K/cs/items || fail 'the row, its count, acted or the items changed'
[ ! -f $K/cs/done ] && [ ! -f $K/cs/passed ] || fail 'the run is done while a chunk waits'
[ -z "$(qline p1c1)$(qline p2c1)" ] || fail "a question about it: $(qline p1c1)"
cs decide --stage 1; no 'close-unrun'; no 'close-again'; no 'close-lost'; [ "$(fixes)" = 1 ] || fail 'a second decide wrote again'
snap s2
# the dev side owes nothing for it: the round's own step, its lock taken, computes what it owes
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'; sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || true
[ -s .vid/round/dev ] || fail 'the round computed nothing the dev side owes'; ! head -n 1 .vid/round/dev | cut -f2 | grep -qw "#$CSN" || fail "the dev side owes the waiting run: $(head -n 1 .vid/round/dev)"; back s2

# (2) its ticket and its head
printf 'step-start step=S01 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events; sh "$GS" spec-export > /dev/null 2>&1
KF=$(printf '%s' "${FX% | stand-in: RM}" | cksum | cut -d' ' -f1); tw_post fix "$KF" || fail "the fix ticket was refused: $(cat "$T/werr")"; FT=$TW_N; cp "$TW_F" "$T/ft"
grep -qxF -- '- ROW-003 could not run there: its test in alpha, beta; make its test run on the deployed test site' "$T/ft" || fail "the ticket's row line: $(grep -- '- ROW-003 ' "$T/ft")"
! grep -q -- '- ROW-003 failed:' "$T/ft" && grep -qx -- '- also: beta' "$T/ft" || fail 'the ticket says failed, or asks the primary engine alone'
awk '/^## Faulted rows/ { f = 1; next } /^## / { f = 0 } f && /ROW-003/ { e = 1 } END { exit e }' "$T/ft" || fail 'the ticket faults the row'
! grep -q '^- T2 ' "$T/ft" && ! grep -q '^- T4 ' "$T/ft" && grep -q 'Its rows could not run on the deployed test site' "$T/ft" || fail 'the ticket asks a red or a fault of a row that could not run'
# a journey's transitions get no Faulted line when it could not run there, and do when it failed (the check can fail)
cp .vid/tw/handed "$T/hj"; cp .vid/metrics-events "$T/mj"; for x in S02 S03 S04 S05 S06 S07; do printf 'step-start step=%s at=2026-11-09T09:00:00Z\n' $x >> .vid/metrics-events; done
echo "fix ROW-005 | ROW-005: could not run there: its test in alpha | CS #$CSN of stage 1: req-$CSN-p1c1-2 | stand-in: RM" >> .vid/tw/handed; F=$(sh "$CHECKS/writer.sh" write fix ROW-005 2> "$T/out") || fail 'the journey fix was refused'
! grep -q 'of the journey ROW-005' "$F" || fail 'a journey that could not run there is faulted'; cat "$T/hj" > .vid/tw/handed
echo 'fix ROW-005 | ROW-005: wrong total in alpha | close #9 of S04: req-9-p1c1-2 | stand-in: RM' >> .vid/tw/handed; F=$(sh "$CHECKS/writer.sh" write fix ROW-005 2> "$T/out") || fail 'the red journey fix was refused'
grep -q 'of the journey ROW-005' "$F" || fail 'the control: a red journey is not faulted'; cat "$T/hj" > .vid/tw/handed; cat "$T/mj" > .vid/metrics-events; rm -f .vid/tw/out/fix-ROW-005.md
cs decide --stage 1; no 'close-'; snap s2t
P=0; hd_() { P=$((P + 1)); git -C "$T/dev" checkout -q -B "t$FT" main; git -C "$T/dev" -c user.name=a -c user.email=a@b commit -q --allow-empty -m "h$P"; git -C "$T/dev" push -q -f origin "t$FT"; HD=$(git -C "$T/dev" rev-parse HEAD); h=$(printf %.12s "$HD")
  [ -n "${PR:-}" ] || PR=$(gh pr create -R $R --head "t$FT" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$FT")" | sed 's/.*\///')
  RG=$(awk '/^## / { x = substr($0, 4); next } x == "Regression rows" && /^- [A-Z]+-[0-9]/ { print $2 }' "$T/ft"); C=''; for r in $RG; do C="$C $r=pass"; done
  rr_put "pr-$PR-$h-1" results.txt "$(printf 'by: TM\ncommit: %s\nenvironments: 2%s' "$HD" "${3:+$(printf '\n%s' "$3")}")"; rr_put "pr-$PR-$h-1" cases-alpha.xml "$(rr_cases "ROW-003=$1" $C)"; rr_put "pr-$PR-$h-1" cases-beta.xml "$(rr_cases "ROW-003=$2" $C)"; send "pr-$PR-$h-1"
  [ "$P" != 1 ] || { rr_put "grade-pr-$PR-$h-1" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-003 kept — seen' "$HD")"; send "grade-pr-$PR-$h-1"; }; fetch
  sh "$RS" read --ticket "$FT" --pr "$PR" --head "$HD" > /dev/null 2>&1 || true; sh "$CHECKS/decide.sh" decide --ticket "$FT" --pr "$PR" --head "$HD" > "$T/out" 2>&1 || true; }
hd_ "$U" "$U"; grep -q '^ROW-003 evidence missing' "$T/out" || fail 'setup at the head is not evidence missing'
hd_ pass pass; grep -q '^ROW-003 accepted' "$T/out" || fail 'passed at the head is not accepted'
hd_ pass pass 'retested: ROW-003'; grep -q '^ROW-003 accepted' "$T/out" || fail 'a retested row that passed owes a fault'
back s2t; PR=''; P=0; hd_ pass fail:wrong_total; grep -q '^ROW-003 failing' "$T/out" && grep -q '^ROW-003 ' .vid/decide/counts || fail 'failed at the head is not failing and counted'

# (3) merged: a new build; lost alike again: the owner's, "after its fix"; passed: done; failed: a first red
back s2t; mg 40 "$FT"; cs owed; ok '^stage 1$'; nb; [ "$K" != "$K1" ] || fail 'no new candidate'
rq2 1 ROW-003="$U" -- ROW-003="$U"; ok '^close-again staging-1 p1c1$'; snap s3
rq2 2 ROW-003="$U" -- ROW-003="$U"; ok '^close-lost staging-1 p1c1$'; no 'close-unrun'; [ "$(fixes)" = 1 ] || fail 'a second could-not-run fix'
qline p1c1 | grep -q "ROW-003 still cannot run after its fix #$FT" || fail "the question does not say after its fix: $(qline p1c1)"
back s3; rq2 2 -- ; ok '^stage-cs 1 passed$'; no 'close-lost'
back s3; rq2 2 ROW-003=fail:wrong_total -- ROW-003="$U"; ok '^failing ROW-003$'; no 'close-twice'; no 'close-unrun'

# (4) withdrawn by a plan change, or the line cut: the owner's, keyed anew; then again and alike: the owner's, no second ticket
back s2t; printf 'withdrawn %s decision=plan-change at=2026-11-10T10:00:00Z\n' "$FT" >> .vid/tw/log; cs decide --stage 1; ok '^close-lost staging-1 p1c1$'
qline p1c1 | grep -q "its fix ticket #$FT was withdrawn" || fail "no withdrawn words: $(qline p1c1)"; cs decide --stage 1; [ "$(grep -c '^lost p1c1 ' $K/cs/items)" = 1 ] || fail "the question twice: $(grep '^lost p1c1 ' $K/cs/items)"; sh "$QS" keys > "$T/k" 2>&1; grep -q 'close:stage-1/1/cs:lost:p1c1' "$T/k" || fail 'its key is not in the queue'
Q=$(qline p1c1 | sed 's/^- \(Q[0-9]*\) .*/\1/'); sh "$QS" answer "$Q" again 'run it on the site' > "$T/out" 2>&1 || fail 'the again was refused'
cs decide --stage 1; ok '^close-again staging-1 p1c1$'; N=$CSN; rq p1c1-3 "$X" alpha $(allof pass ROW-003="$U"); fetch; cs decide --stage 1; ok '^close-lost staging-1 p1c1$'; no 'close-unrun'; [ "$(fixes)" = 1 ] || fail 'a second fix line after a withdrawal'
back s2; grep -vxF "$FX" .vid/tw/handed > "$T/h" || true; cat "$T/h" > .vid/tw/handed; cs decide --stage 1; ok '^close-lost staging-1 p1c1$'; qline p1c1 | grep -q 'its fix line was cut' || fail "no cut words: $(qline p1c1)"
cs decide --stage 1; ok '^close-lost staging-1 p1c1$'; no 'close-unrun'; [ "$(fixes)" = 0 ] && [ -n "$(qline p1c1)" ] || fail 'the next decide wrote the cut line again, or dropped the question'

back s2t; printf 'amended %s kind=fix step=S01 rows=ROW-007 at=2026-11-10T10:00:00Z\n' "$FT" >> .vid/tw/log; cs decide --stage 1; ok '^close-lost staging-1 p1c1$'; qline p1c1 | grep -q "its fix ticket #$FT was withdrawn" || fail 'an amendment that took the row out is not its end'

# (5) a held row, a red row in the run, a red fix of an earlier build: the owner's, as today
back s1; state ROW-003 held; rq2 2 ROW-003="$U" -- ROW-003="$U"; ok '^close-lost staging-1 p1c1$'; no 'close-unrun'; [ "$(fixes)" = 0 ] || fail 'a fix line for a held row'
back s1; state ROW-003 failing; rq2 2 ROW-003="$U" -- ROW-003="$U"; ok '^close-lost staging-1 p1c1$'; no 'close-unrun'; [ "$(fixes)" = 0 ] || fail 'a fix line for a failing row'
back s1; rq2 2 ROW-003="$U" -- ROW-003=fail:wrong_total; ok '^close-lost staging-1 p1c1$'; ok '^failing ROW-003$'; no 'close-unrun'; ! grep -q 'could not run there' .vid/tw/handed || fail 'could-not-run words beside a real failure'

# (6) another chunk red while one waits; a late red of the waiting row, unpublished then published
back s1; rq2 2 ROW-003="$U" -- ROW-003=pass SEAM-002=fail:wrong_total; ok '^close-unrun staging-1 p1c1 ROW-003 #unpublished$'; ok '^failing SEAM-002$'; [ "$(fixes)" = 2 ] || fail 'not one fix each'; [ ! -f $K/cs/done ] || fail 'done while a chunk waits'
back s2; N=$CSN; rq p2c1-3 "$X" beta $(allof pass ROW-003=fail:wrong_total); fetch; cs decide --stage 1; ok '^failing ROW-003$'
[ "$(fixes)" = 1 ] && ! grep -q 'could not run there' .vid/tw/handed || fail "not one fix for the late red: $(grep '^fix ' .vid/tw/handed)"; [ -z "$(qline p1c1)" ] || fail 'a question for the chunk still waiting'
back s2; N=$CSN; rq p1c1-3 "$X" alpha $(allof pass ROW-003=fail:wrong_total); rq p2c1-3 "$X" beta $(allof pass ROW-003=fail:wrong_total); fetch; cs decide --stage 1; ok '^close-done staging-1$'; [ ! -s $K/cs/waits-fix ] || fail 'late reds left a chunk waiting'
back s2t; N=$CSN; rq p2c1-3 "$X" beta $(allof pass ROW-003=fail:wrong_total); fetch; cs decide --stage 1; ok '^close-waits staging-1 ROW-003$'; [ "$(fixes)" = 1 ] || fail 'a second ticket beside the published one'

# (6b) two rows could not run, one red later: the other keeps its fix; an earlier question of the chunk goes with the fix; a fix merged
# after the build was named: no question
back s0; rq2 1 ROW-003="$U" ROW-007="$U" -- ROW-003="$U" ROW-007="$U"; rq2 2 ROW-003="$U" ROW-007="$U" -- ROW-003="$U" ROW-007="$U"; grep -q '^fix ROW-003 ROW-007 | ' .vid/tw/handed || fail 'no one line for both rows'
N=$CSN; rq p2c1-3 "$X" beta $(allof pass ROW-003=fail:wrong_total ROW-007="$U"); fetch; cs decide --stage 1; ok '^failing ROW-003$'; no 'close-lost'
grep -q "^fix ROW-007 | ROW-007: could not run there: its test in alpha, beta | CS #$CSN of stage 1: " .vid/tw/handed || fail "the sibling lost its fix: $(grep '^fix ' .vid/tw/handed)"
back s1; printf 'vid: lost p1c1 1\nby: DM\n' > "$T/c"; gh issue comment "$CSN" -R $R --body-file "$T/c" > /dev/null; fetch; cs decide --stage 1; ok '^close-lost staging-1 p1c1$'; [ -n "$(qline p1c1)" ] || fail 'no question for the lost chunk'
rq2 2 ROW-003="$U" -- ROW-003="$U"; ok '^close-unrun staging-1 p1c1 ROW-003 '; ! grep -q '^lost p1c1 ' $K/cs/items && [ -z "$(qline p1c1)" ] || fail "the earlier question stands beside the fix: $(qline p1c1)"
back s1; N=$CSN; rq p1c1-2 "$X" alpha $(allof pass ROW-003="$U"); fetch; cs decide --stage 1; ok '^close-unrun staging-1 p1c1 ROW-003 #unpublished$'
pubfix ROW-003 S01; mg 41 "$TN"; N=$CSN; rq p2c1-2 "$X" beta $(allof pass ROW-003="$U"); fetch; cs decide --stage 1; no 'close-lost'; [ -z "$(qline p2c1)" ] || fail "a question while the fix merged after the build: $(qline p2c1)"

# (7) GitHub manual: as today
# (the toy is no GitHub manual project: its plan reader refuses after the chunks are decided, so the exit is not read)
back s1; printf 'setup-answered key=github-mode value="manual" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; N=$CSN; rq p1c1-2 "$X" alpha $(allof pass ROW-003="$U"); rq p2c1-2 "$X" beta $(allof pass ROW-003="$U"); fetch; cs decide --stage 1
ok '^close-lost staging-1 p1c1$'; ok '^close-lost staging-1 p2c1$'; no 'close-unrun'; [ "$(fixes)" = 0 ] || fail 'a fix line in GitHub manual'
echo 'cs-unrun-fix: ok'

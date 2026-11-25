#!/bin/sh
# Purpose: selftest case — a stage's full run and its staging run ask every row of their stages (FB-7 A2), checks/close.sh on the writer's
# toy and the fake gh. A row an open fix ticket holds, one an open step ticket holds and one another close found red are asked in both. Red
# there, each waits: no failing row, no fix line, no second ticket, a ticket that merged while the run was out still holding its row; the
# run is done, not passed, and no new build is due while one waits. Once each ticket merged or was withdrawn, the full run's next build is
# due; a staging run's waiting row whose ticket was withdrawn is read as any red at the next decide, a fix line, never passed, and the next
# build is due once that fix merged. Green, each
# passes. A red staging run's issue stays open, and closes once the run is replaced (FB-7 D3). Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "stage-asks-every-row: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CL_NOASK=1; cl_toy
# the full run: an open fix ticket (S01's), an open step ticket of a later stage, another close's red
nt fix S01 ROW-003; F1=$TN; nt step S05 ROW-006; F2=$TN; mkdir -p .vid/decide/close/S05/1; printf 'issue\t9\ncommit\tx\nasked\t2026-11-09T00:00:00Z\n' > .vid/decide/close/S05/1/ask; printf 'ROW-001\tits test in alpha\n' > .vid/decide/close/S05/1/acted; : > .vid/decide/close/S05/1/done; tw_hand 'closed S05'
cl_ask; for r in ROW-001 ROW-002 ROW-003 ROW-006; do grep -q "^$r " $K/rows || fail "the full run leaves out $r: $(cat $K/rows)"; done
mg 40 "$F2"; cl_c3 ROW-001=fail:a ROW-003=fail:b ROW-006=fail:c
for r in ROW-001 ROW-003 ROW-006; do ok "^close-waits stage-1 $r\$"; done; no '^failing '; no '^close-fix '; ! grep -q '^fix ' .vid/tw/handed || fail "a fix line for a held row: $(grep '^fix ' .vid/tw/handed)"
sh "$QS" keys > "$T/k" 2>&1; for w in 'no fix ticket is written; ' "; ROW-001 waits on another close's fix; " "; ROW-003 waits on #$F1; " "; ROW-006 waits on #$F2; "; do grep 'chunk p1c1, failing' "$T/k" | grep -qF -- "$w" || fail "the red line lacks: $w"; done; ! grep 'chunk p1c1, failing' "$T/k" | grep -q 'is written for them' || fail "the red line's words: $(grep 'chunk p1c1, failing' "$T/k")"
[ -f $K/done ] && [ ! -f $K/passed ] || fail 'the full run is not done, or it passed'; cs owed; no '^stage 1$'
printf 'withdrawn %s decision=plan-change\n' "$F1" >> .vid/tw/log; cs owed; no '^stage 1$'; rm -rf .vid/decide/close/S05; cs owed; ok '^stage 1$'
cl_ask; [ "$CN" = 2 ] || fail "candidate $CN"; cl_c3; ok '^stage-c3 1 passed$'; cl_d1
# the staging run: the same, its rows asked; red, it waits; a staging run that only waited makes the next build due
nt fix S01 SEAM-001 SEAM-001=seam; F3=$TN; nt step S05 ROW-003; F4=$TN
cl_cs; for r in ROW-003 SEAM-001 SEAM-002 ROW-007 DIF-001; do case " $CSR " in *" $r "*) ;; *) fail "the staging run leaves out $r: $CSR" ;; esac; done; cp -R $K "$T/k2"
csr 1 pass SEAM-001=fail:x ROW-003=fail:y; ok '^close-waits staging-1 SEAM-001$'; ok '^close-waits staging-1 ROW-003$'; no '^failing '; no '^close-fix '; ok '^paid DIF-001$'; no 'passed'; [ -f $K/cs/done ] || fail 'the staging run is not done'
cs owed; no '^stage 1$'; printf 'withdrawn %s decision=plan-change\nwithdrawn %s decision=plan-change\n' "$F3" "$F4" >> .vid/tw/log; cs decide --stage 1; ok '^failing SEAM-001$'; ok '^failing ROW-003$'; ok '^close-fix staging-1 ROW-003 SEAM-001$'; no 'passed'
cs owed; no '^stage 1$'; pubfix 'ROW-003 SEAM-001' S03 SEAM-001=seam; cs owed; no '^stage 1$'; mg 41 "$TN"; state ROW-003 accepted; state SEAM-001 owed; fetch; cs owed; ok '^stage 1$'
# D3: the red staging run's issue is open; replaced, it is told once and closed, at the next owed when GitHub refused its close
! grep -qx CLOSED "$T/gh/issues/$CSN/state" || fail "the red staging run's issue closed (D3)"; K0=$K; X0=$X; failclose "$CSN"; cl_ask; [ "$CN" = 3 ] || fail "candidate $CN"; [ ! -f $K0/cs/withdrawn ] || fail 'a staging run whose close GitHub refused is marked withdrawn'; cs owed; grep -qx CLOSED "$T/gh/issues/$CSN/state" || fail "the replaced staging run's issue is open (D3)"; cs owed
[ "$(grep -rl '^vid: withdrawn. Stage 1 has a new candidate' "$T/gh/issues/$CSN/comments" | grep -c .)" = 1 ] || fail 'the replaced staging run is told more than once'; rm -rf $K; K=$K0; X=$X0; ROWS=$CSR
# green at an open ticket's row: passed
rm -rf $K; cp -R "$T/k2" $K; nt step S05 ROW-003; csr 2 pass; ok '^stage-cs 1 passed$'
# a red row whose fix ticket a plan change withdrew is no close's any more
mkdir -p .vid/decide/close/S05/1; printf 'issue\t9\ncommit\tx\nasked\t2026-11-09T00:00:00Z\n' > .vid/decide/close/S05/1/ask; printf 'ROW-001\tits test in alpha\n' > .vid/decide/close/S05/1/acted; printf '777\tROW-001\n' > .vid/decide/close/S05/1/fixes; nt fix S05 ROW-001; sed "s/^\(published $TN .*\) at=/\1 fix=777 at=/" .vid/tw/log > "$T/l"; cat "$T/l" > .vid/tw/log
cs owned; ok '^ROW-001$'; printf 'withdrawn %s decision=plan-change\n' "$TN" >> .vid/tw/log; cs owned; no '^ROW-001$'
exit 0

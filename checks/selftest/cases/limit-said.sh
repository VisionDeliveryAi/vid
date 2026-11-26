#!/bin/sh
# Purpose: selftest case — what an answer of limit does is said with the question, and with the answer (FB-7 A3), checks/close.sh and
# checks/queue.sh on the writer's toy and the fake gh: on a full run's and a staging run's red line and on a lost chunk's question. The
# tests stay on the later runs; with a ticket of the stages' rows merged after the build, that merge makes a new build; each open one is
# said as open; a red row's line adds its fix's open ticket; a ticket of a later stage's rows, one the build holds and a withdrawn one are
# not said, and none is once a later stage's candidate is named. A step's close says none of it. Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "limit-said: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
B='after limit: the tests stay on the later runs and are named in each stage'"'"'s summary'
line() { sh "$QS" keys > "$T/k" 2>&1 || true; grep "$1" "$T/k" | head -n 1; }
cl_toy; N=$C3N; cl_s1; rq p1c1-1 "$X" alpha $(allof pass ROW-006=fail:x); rq p2c1-1 "$X" beta $(allof pass); rq p1cx-1 "$X" alpha test_other=pass; fetch; cs decide --stage 1; ok '^close-fix stage-1 ROW-006$'
# neither: the first sentence alone
line 'chunk p1c1, failing' > "$T/out"; ok "; answer limit to rule them known limits · $B\$"
# a later stage's ticket, and a withdrawn one: not said; an open one of the stages, and the fix's own ticket, are
KF=$(cut -f1 $K/fixes); nt fix S03 ROW-006; FT=$TN; sed "s/^\(published $FT .*\) at=/\1 fix=$KF at=/" .vid/tw/log > "$T/l"; cat "$T/l" > .vid/tw/log; nt step S05 ROW-017; nt fix S01 ROW-003; W=$TN; printf 'withdrawn %s decision=plan-change\n' "$W" >> .vid/tw/log; fetch; cs decide --stage 1
line 'chunk p1c1, failing' > "$T/out"; ok "$B; #$FT is open: if it merges before the stage closes, it makes a new build; limit also lets in #$FT, its fix\$"
# merged since: the new build
nt fix S01 ROW-003; M1=$TN; mg 70 "$M1"; fetch; cs decide --stage 1; line 'chunk p1c1, failing' > "$T/out"; ok "$B; this build will not close the stage: #$M1, merged since, makes a new one, with its full run, deploy, staging run and walk; #$FT is open: "; no 'cannot close'
# a later stage's candidate named: none of it
cp .vid/tw/handed "$T/h"; tw_hand 'candidate 2'; cs decide --stage 1; [ ! -s $K/newbuild ] || fail "newbuild: $(cat $K/newbuild)"; cat "$T/h" > .vid/tw/handed; cs decide --stage 1
# the answer prints the same words
printf 'ROW-006\tfailing\tfailing\t22\tx\tx\n' >> .vid/decide/state; QN=$(qn 'chunk p1c1, failing'); sh "$QS" answer "$QN" limit 'not now' > "$T/out" 2>&1 || fail 'the limit was refused'; ok "^$B; this build will not close the stage: #$M1, merged since, "; ok "limit also lets in #$FT, its fix\$"
tail -n 1 .vid/decide/rulings | grep -q "${TAB}ROW-006${TAB}limit${TAB}not now${TAB}owner\$" || fail "the ruling's words: $(tail -n 1 .vid/decide/rulings)"
# the staging run's red line and a lost chunk's question say it too; a step's close does not
printf 'withdrawn %s decision=plan-change\n' "$FT" >> .vid/tw/log; cs decide --stage 1; [ -f $K/passed ] || fail 'the full run did not pass after its limit'; cl_d1; cl_cs; state SEAM-001 held; csr 1 pass ROW-007=fail:x SEAM-001='err:setup: x' DIF-001='err:setup: x'; csr 2 pass ROW-007=fail:x SEAM-001='err:setup: x'; ok '^close-lost staging-1 p1c1$'; cs decide --stage 1
line 'chunk p1c1, lost twice' > "$T/out"; ok "answer again, or limit · $B; this build will not close the stage: #$M1, merged since, makes"
mkdir -p .vid/decide/close/S05/1; printf 'issue\t9\ncommit\tx\nasked\t2026-11-09T00:00:00Z\n' > .vid/decide/close/S05/1/ask; echo 'red p1c1 alpha:ROW-017' > .vid/decide/close/S05/1/items; line 'the close of S05, chunk p1c1' > "$T/out"; no 'after limit'; ok 'answer limit to rule them known limits$'
exit 0

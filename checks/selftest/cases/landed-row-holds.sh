#!/bin/sh
# Purpose: selftest case — a build is held while a row of its runs landed since its full run was asked and is not settled at a commit the
# build holds (FB-7 A1), checks/close.sh and checks/walk.sh on the writer's toy and the fake gh. A full run whose rows all passed with one
# landed reads `close-held`, once, never passed; settled at a commit the build holds, at its known limit, or out of the stages, it
# passes. A landed row settled at a newer merge makes the next build due, its full run passed or not, and the older run's issue closes;
# held, not decided, or of an earlier stage, its merge keeps the next build back until it is settled. Held before the okay, before the staging run, with the
# staging run out (every row of it landed, the read empty; a lost chunk's question kept) and before the walk and the close: none is owed.
# A landing that only adds rows changes nothing. Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "landed-row-holds: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cl_toy
# the full run out: a row of it landed, the rest passed: held, said once, not passed; a second read says nothing more
land ROW-001; cl_c3; ok '^close-held stage-1 ROW-001$'; no '^stage-c3 1 passed$'; [ ! -f $K/passed ] || fail 'the full run passed with a row that landed'
cs decide --stage 1; no 'close-held'; no 'close-numbers'; cs owed; no '^okay staging'; no '^stage 1$'; no '^cs 1$'
cs deploy staging 1; ok '^refused staging: stage 1: row ROW-001 landed, not decided$'
# an earlier stage's row, and a held word: neither is settled; the next build waits for it
unland; land ROW-003; cs decide --stage 1; ok '^close-held stage-1 ROW-003$'; nt fix S01 ROW-003; mg 30 "$TN"; fetch; cs owed; no '^stage 1$'; cs stage 1; ok 'ROW-003 landed, not decided'
state ROW-003 held; cs decide --stage 1; no 'passed'; cs owed; no '^stage 1$'
# settled at a merge the build does not hold: still held, and the next build is due
state ROW-003 accepted; cs decide --stage 1; no 'stage-c3 1 passed'; cs owed; ok '^stage 1$'
printf 'withdrawn %s decision=plan-change\n' "$TN" >> .vid/tw/log; printf '30\n' > "$T/p0"; grep -vxF -f "$T/p0" .vid/decide/merged-prs > "$T/p1"; cat "$T/p1" > .vid/decide/merged-prs; grep -v '^30	' .vid/decide/merges > "$T/p1"; cat "$T/p1" > .vid/decide/merges
# settled at a commit the build holds: it passes; and a known limit, and a row out of its stages, hold nothing
state ROW-003 accepted-by-ruling; cp -R $K "$T/k0"; cs decide --stage 1; ok '^stage-c3 1 passed$'; { grep -v '^closed S0[234] ' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed
back() { rm -rf $K; cp -R "$T/k0" $K; { grep -v '^closed S0[234] ' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed; }
back; unland; land ROW-001; limit ROW-001; cs decide --stage 1; ok '^stage-c3 1 passed$'; grep -v 'known limit' .vid/decide/state > "$T/s" || true; cat "$T/s" > .vid/decide/state
back; unland; land ROW-001; cp STAGES.md "$T/st"; awk '{ print } $0 == "row: ROW-004 -> STAGE-0" { print "row: ROW-001 -> STAGE-2" }' "$T/st" > STAGES.md; cs decide --stage 1; ok '^stage-c3 1 passed$'; cat "$T/st" > STAGES.md
# a landing that only adds a row changes nothing; then held before the okay
back; unland; echo "ROW-099 0123456789ab $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/decide/landed; cs decide --stage 1; ok '^stage-c3 1 passed$'; cs owed; ok '^okay staging 1$'
unland; land ROW-007; cs owed; no '^okay staging'; cs okay --stage 1; [ "$RC" != 0 ] || fail 'an okay went out at a held build'
unland; cl_d1
# before the staging run
land ROW-007; cs owed; no '^cs 1$'; cs ask --cs 1; [ "$RC" != 0 ] || fail 'a staging run was asked at a held build'; [ ! -f $K/cs/ask ] || fail 'a staging run ask is on record'
unland; cl_cs; cp -R $K "$T/k1"
# the staging run out: a chunk lost to the owner keeps its question (a held row of it keeps it the owner's, PB-5); every row landed, so the read holds none: held, not passed, no walk
state ROW-007 held; csr 1 'err:setup: no clock here'; ok '^close-again staging-1 p1c1$'; csr 2 'err:setup: no clock here' 'ROW-003=pass'; ok '^close-lost staging-1 p1c1$'   # PB-5: a held row keeps it the owner's
land ROW-003; cs decide --stage 1; [ -n "$(qn 'chunk p1c1, lost twice')" ] || fail 'the question went with the landing'; unland; state ROW-007 owed
rm -rf $K; cp -R "$T/k1" $K; for b in $(git --git-dir="$T/code.git" for-each-ref --format='%(refname)' "refs/heads/vid-results/req-$CSN-*"); do git --git-dir="$T/code.git" update-ref -d "$b"; git --git-dir=.vid/code update-ref -d "$b" 2>/dev/null || true; done
csr 1 'err:setup: no clock here'; land $CSR; cs decide --stage 1; ok '^close-held staging-1 '; no 'stage-cs 1 passed'; [ ! -f $K/cs/passed ] || fail 'the staging run passed with every row of it landed'; cs owed; no '^walk 1$'; cs decide --stage 1; no 'close-held'
unland
# passed, then a landing: what it paid stands, no walk, no close; the walk and the summary refuse for the row
csr 2 pass; ok '^stage-cs 1 passed$'; ok '^paid DIF-001$'; cs owed; ok '^walk 1$'; land ROW-006; cs owed; no '^walk 1$'; no '^close-stage 1$'; cs walk 1; ok 'row ROW-006 landed, not decided'
sh "$CHECKS/walk.sh" due 1 2>/dev/null && fail 'a walk is due at a held build'; cs conds 1; ok '^1 ROW-006 landed, not decided$'
# not passed and held: the next build is due at the row's merge, and the older full run's issue closes when it is named
rm -rf $K; cp -R "$T/k0" $K; nt step S03 ROW-006; mg 31 "$TN"; fetch; cs owed; no '^stage 1$'; state ROW-006 accepted; cs owed; ok '^stage 1$'; C0=$C3N; failclose "$C0"; cl_ask; [ "$CN" = 2 ] || fail "the next build is candidate $CN"
[ ! -f .vid/decide/stage/1/1/done ] || fail 'a full run whose close GitHub refused counts as done'; fetch; cs owed; [ "$(grep -rl '^vid: withdrawn. Stage 1 has a new candidate' "$T/gh/issues/$C0/comments" | grep -c .)" = 1 ] || fail 'the replaced full run is told more than once'
grep -qx CLOSED "$T/gh/issues/$C0/state" || fail 'the replaced full run is open on GitHub'; cl_c3; ok '^stage-c3 1 passed$'
exit 0

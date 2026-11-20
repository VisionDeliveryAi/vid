#!/bin/sh
# Purpose: selftest case — the amend, withdraw and team-change moves wired (GM-2 T10, with T5, T6, T7). On the form fixture's toy
# (fixtures/form.sh, fixtures/amend.sh) in GitHub manual, S02, S04 and S05 posted. S04 leaves the plan by a recorded change (its
# tests on .vid/tw/to-place in the owner's words) and ROW-012 moves out of S02 into S03 in the same change, so writer.sh due owes
# `amend` of S02's ticket and `withdraw` of S04's; the team adds ROW-019 to S05's issue. The listing shows the three moves, the
# team change with its size warning (writer.sh topup: 1 added to the 1 test of S05's ticket). One call, made as /vid next makes it
# after its read under this session's lock, names `amend "#<S02's>" "<words>" -- withdraw "#<S04's>" "<words>" -- team-change
# "#<S05's>" ROW-019 no "<words>"`: S02's ticket is amended in the owner's words and the call's read holds its body as GitHub
# holds it now; S04's ticket is withdrawn in the owner's words; the team change is answered no in them (.vid/next/team-answers),
# one comment on S05's issue. (A yes would move ROW-019, a stage 1 test, into S05 of stage 2: the planner's check refuses it.)
# S03 is posted in GitHub auto first (its body ViD's part 1) and the team takes ROW-006 out of it; the team pastes a
# copy of S02's tests line under its requirements line; the call also names `amend "#<S03's>"` then `team-change "#<S03's>" ROW-006
# no`. After each such move the call's read holds the issue as GitHub holds it: S02's body exactly, S04's ticket closed; the team
# change on S03, whose evidence is the whole body its amendment changed, is shown again and not done, and named again at the next
# call it is done on the evidence of the body GitHub holds. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-ticket-moves: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
HOME=$T/home; export HOME; mkdir -p "$HOME"
# S03 posted first in GitHub auto, as /vid run posts it (its body ViD's part 1), then GitHub manual again
printf 'setup-answered key=github-mode value="auto" words="auto, for the toy" at=2026-11-19T09:10:00Z\n' >> .vid/plan/setup
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified in auto'
fm_prep S03 || { cp "$T/post" "$T/out"; fail "S03's ticket could not be written in auto"; }
sh "$CHECKS/github.sh" tw-post "$FM_F" > "$T/post" 2>&1 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in auto'; }
N3=$(awk '$1 == "published" && / step=S03 / { print $2 }' .vid/tw/log)
printf 'setup-answered key=github-mode value="manual" words="by hand again" at=2026-11-19T09:20:00Z\n' >> .vid/plan/setup
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted'; }; N2=$FM_N
fm_post S04 || { cp "$T/post" "$T/out"; fail 'S04 was not posted'; }; N4=$FM_N
fm_post S05 || { cp "$T/post" "$T/out"; fail 'S05 was not posted'; }; N5=$FM_N
for n in $N2 $N3 $N4 $N5; do gh_attr "$n" created "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; done
# S04 out of the plan, its tests to place; ROW-012 out of S02 into S03
grep -v '^step S04 \|^needs ROW-002 ' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
am_move ROW-012 S02 S03
for r in ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004; do printf '%s\tno-step\t2026-11-19T11:00:00Z\tthe limits wait, the owner says\n' "$r"; done > .vid/tw/to-place
am_change "$N4" 'S04 waits; S03 takes ROW-012' || { cp "$T/chg" "$T/out"; fail 'the plan change was refused'; }
fm_team_edit "$N5" 's/^The toy team.s own checklist line\.$/&\
- ROW-019/'
# the team takes ROW-006 out of S03's part-1 body, and pastes a copy of S02's tests line under its requirements line
fm_team_edit "$N3" 's/ ROW-006,\{0,1\}//g; /ROW-006/d'
RL=$(awk -F'\t' '$1 == "{requirements}" { print $2; exit }' ".vid/tw/form/issue-$N2"); TL=$(awk -F'\t' '$1 == "{tests}" { print $2; exit }' ".vid/tw/form/issue-$N2")
awk -v r="$RL" -v t="$TL" '{ print } $0 == r && !d { print ""; print t; d = 1 }' "$FAKEGH/issues/$N2/body" > "$T/b2" && cat "$T/b2" > "$FAKEGH/issues/$N2/body"
[ "$(grep -cxF "$TL" "$FAKEGH/issues/$N2/body")" = 2 ] || fail "the team's copy of S02's tests line did not take"
CLAUDE_CODE_SESSION_ID=ticket-moves-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
sh "$CHECKS/next.sh" triggers > "$T/lines" 2> "$T/out" || fail 'next.sh triggers failed'
for m in "amend${TB}#$N2" "withdraw${TB}#$N4" "team-change${TB}#$N5 ROW-019" "amend${TB}#$N3" "team-change${TB}#$N3 ROW-006"; do grep -q "^move${TB}$m${TB}" "$T/lines" || { grep '^move\|^unread' "$T/lines" > "$T/out"; fail "the listing holds no move $m"; }; done
grep -q "^warning${TB}team-change${TB}#$N5 ROW-019${TB}size${TB}1 test added to the 1 tests of #$N5" "$T/lines" || { cp "$T/lines" "$T/out"; fail "the team change on #$N5 shows no size warning"; }
call amend "#$N2" "Yes, amend #$N2" -- withdraw "#$N4" "Yes, withdraw #$N4" -- team-change "#$N5" ROW-019 no "No, ROW-019 stays with S03" -- amend "#$N3" "Yes, amend #$N3" -- team-change "#$N3" ROW-006 no "No, ROW-006 stays"; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q "^done amend #$N2" "$T/out" || fail "the amend move of #$N2 is not reported done"
grep -q "^amended $N2 .* words=\"Yes, amend #$N2\"\$" .vid/tw/log || fail "#$N2's amended line does not end with the owner's words"
awk '{ L[NR] = $0 } END { while (NR > 0 && L[NR] == "") NR--; for (i = 1; i <= NR; i++) print L[i] }' "$FAKEGH/issues/$N2/body" > "$T/want"
awk -F'\t' -v n="$N2" '$1 == "body" && $2 == n { print substr($0, length("body") + length(n) + 3) }' .vid/next/read > "$T/got"
cmp -s "$T/want" "$T/got" || { diff "$T/want" "$T/got" > "$T/out" || :; fail "the call's read does not hold #$N2's body as the amendment left it"; }
grep -q "^done withdraw #$N4" "$T/out" || fail "the withdraw move of #$N4 is not reported done"
grep -q "^withdrawn $N4 .* words=\"Yes, withdraw #$N4\"\$" .vid/tw/log && [ "$(cat "$FAKEGH/issues/$N4/state")" = CLOSED ] || fail "#$N4 was not withdrawn in the owner's words"
grep -q "^done team-change #$N5 ROW-019" "$T/out" || fail "the team-change move on #$N5 is not reported done"
grep -q "^$N5${TB}added${TB}ROW-019${TB}[0-9a-f]\{40\}${TB}no${TB}.*${TB}No, ROW-019 stays with S03\$" .vid/next/team-answers 2>/dev/null || fail "the team change's no is not recorded in the owner's words"
# the withdrawn ticket read as closed; S03's part-1 body amended (its first line changed on GitHub), so the team's
# drop of ROW-006, whose evidence is the whole body, changed within the call: shown again, not done, and done at the next call on
# the evidence of the body GitHub holds
grep -q "^ticket${TB}$N4${TB}CLOSED${TB}" .vid/next/read || fail "the call's read does not hold the withdrawn #$N4 as closed"
grep -q "^done amend #$N3" "$T/out" || fail "the amend move of #$N3 is not reported done"
grep -q "^again team-change #$N3 ROW-006" "$T/out" || fail "the team change on #$N3, its evidence changed by the amendment before it, is not shown again"
! grep -q "^$N3${TB}dropped${TB}ROW-006${TB}" .vid/next/team-answers 2>/dev/null || fail "the team change on #$N3 was answered on the body before its amendment"
call team-change "#$N3" ROW-006 no "No, ROW-006 stays"; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q "^done team-change #$N3 ROW-006" "$T/out" || fail "the team change on #$N3, named again as shown, is not done"
H3=$(awk '{ L[NR] = $0 } END { while (NR > 0 && L[NR] == "") NR--; for (i = 1; i <= NR; i++) print L[i] }' "$FAKEGH/issues/$N3/body" | git hash-object --stdin)
grep -q "^$N3${TB}dropped${TB}ROW-006${TB}$H3${TB}no${TB}" .vid/next/team-answers || { cp .vid/next/team-answers "$T/out"; fail "the no on #$N3 is not recorded on the evidence of the body GitHub holds ($H3)"; }
exit 0

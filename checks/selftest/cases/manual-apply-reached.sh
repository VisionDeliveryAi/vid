#!/bin/sh
# Purpose: selftest case — an apply with no analysis: reached rows, a marked decision, a closed ticket's reset row and a
# proved-red: change (GM-3 U4; its case manual-apply-reached). On the form fixture's toy (fixtures/form.sh), S02 posted as #N2
# (open) and S03 as #N3, taken over from its comments (fixtures/amend.sh's am_take_over) and closed on the fake. Then committed:
# REQ-001's fail-if reworded (ROW-001 and ROW-008, in #N2, reached), D-001 marked replaced by a new D-005 (both quoted by S02's
# ticket), and ROW-007 reworded (a reset, in the closed #N3). `replan.sh ready` says `apply own`: nothing pending adds a test.
# `replan.sh apply --review --words` exits 0, with no analysis: #N2 is amended, its notice naming ROW-001 reached, its writing
# quoting D-005; #N3 is not amended (closed); a follow-up ticket of S03 is published, its log line `kind=step step=S03
# rows=ROW-007` (that row alone, never S03's others), its writing naming #N3 as the ticket it follows. Then a change to ROW-013's
# proved-red: alone (a field no ticket quotes), committed: ready says `apply own`, and the apply amends #N2 again. And:
# `replan.sh own` shows each own proposal before its apply; and on GitHub manual's switch toy (fixtures/manual.sh), #M2 (S02)
# taken over by mode.sh itself, with no step-start event, closed, and ROW-013 reworded and committed: writer.sh due --why at HEAD (GM-4 F7),
# #M2 read as closed, owes S02's follow-up holding ROW-013. The apply with its own proposal is given --review, the fresh agent's
# review its skill step makes (none here), since the toy's planner adds rows. S01, the skeleton, posted as #N1 and
# closed: its tests REQ-001's change reaches go out in a follow-up of S01 holding exactly them, naming #N1; and with ROW-019 (the
# closed #N3's) reworded alongside the proved-red change while S03's follow-up #F is open, the second apply publishes a follow-up
# of S03 holding ROW-019 alone, #F unchanged. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); T0=$T; trap 'rm -rf "$T0" "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-apply-reached: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'none\n' > "$T/none"   # the fresh agent's review of the rows ViD adds, as the apply's skill step makes it
# the skeleton, S01, posted as #N1 and closed
fm_post S01 || { cp "$T/post" "$T/out"; fail 'S01 was not posted in manual'; }; N1=$FM_N; echo CLOSED > "$FAKEGH/issues/$N1/state"
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
am_take_over "$N3"; echo CLOSED > "$FAKEGH/issues/$N3/state"
grep -q 'D-001' ".vid/tw/out/issue-$N2.md" || fail "S02's ticket does not quote D-001"
# the changes: REQ-001's fail-if, D-001 marked, ROW-007 reworded
awk '/^REQ-001 / && !d { sub(/fail-if: /, "fail-if: within the day, "); d = 1 } { print }' PRD.md > "$T/p" && cat "$T/p" > PRD.md
! git diff --quiet -- PRD.md || fail "REQ-001's fail-if could not be reworded"
sed 's/^\(- \*\*D-001\*\* .*\)$/\1 | replaced-by: D-005/' DECISIONS.md > "$T/d" && cat "$T/d" > DECISIONS.md
printf -- '- **D-005** the mail provider is the one named in the hosting block | why: one place | enforced: convention\n' >> DECISIONS.md
sed 's/opens the unsubscribe page with no sign-in/opens the unsubscribe page at once, with no sign-in/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'REQ-001, D-001 and ROW-007 changed'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 && grep -q "^pending${TB}reached${TB}ROW-001\$" "$T/out" && grep -q "^pending${TB}reset${TB}ROW-007\$" "$T/out" || fail 'ROW-001 reached and ROW-007 reset are not both pending'
R1=$(for r in ROW-003 ROW-004; do awk -F'\t' -v r="$r" '$1 == "pending" && ($2 == "reset" || $2 == "reached") && $3 == r { print r; exit }' "$T/out"; done | paste -sd , -)
[ -n "$R1" ] || fail "no test of the skeleton's step S01 is reached by REQ-001's change"
sh "$CHECKS/replan.sh" ready > "$T/out" 2>&1 && grep -q "^apply${TB}own" "$T/out" || fail 'with only reached rows, a decision and a reset pending, ready does not say apply own'
[ ! -e .vid/next/proposal ] || fail 'an analysis proposal is there before the apply'
sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || fail "the apply's own proposal could not be made"   # shown before the apply
RC=0; sh "$CHECKS/replan.sh" apply --review "$T/none" --words 'Yes, apply what changed' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply with no analysis exited $RC"
[ "$(grep -c "^amended $N2 " .vid/tw/log)" = 1 ] || fail "#$N2 was not amended once"
! grep -q "^amended $N3 " .vid/tw/log || fail "the closed #$N3 was amended"
am_comment "$N2" 'vid: amended' > "$T/am"; grep -q '^- reached: ROW-001' "$T/am" || { cp "$T/am" "$T/out"; fail "#$N2's notice does not name ROW-001 reached"; }
grep -q 'D-005' ".vid/tw/out/issue-$N2.md" || fail "#$N2's writing does not quote D-005, which replaces D-001"
F=$(awk -v n="$N3" '$1 == "published" && $2 + 0 > n + 0 && / step=S03 / { print $2 }' .vid/tw/log | tail -n 1)
[ -n "$F" ] || { grep '^published' .vid/tw/log > "$T/out"; fail 'no follow-up ticket of S03 was published'; }
grep "^published $F " .vid/tw/log | grep -q ' kind=step step=S03 rows=ROW-007 ' || { grep "^published $F " .vid/tw/log > "$T/out"; fail "the follow-up #$F does not hold ROW-007 alone"; }
grep -q "^- follows: #$N3\$" ".vid/tw/out/issue-$F.md" || fail "the follow-up #$F does not name #$N3 as the ticket it follows"
# the closed skeleton ticket's reached tests go out in a follow-up of S01 holding exactly them
F1=$(awk -v n="$N1" '$1 == "published" && $2 + 0 > n + 0 && / step=S01 / { print $2 }' .vid/tw/log | tail -n 1)
[ -n "$F1" ] && grep "^published $F1 " .vid/tw/log | grep -q " step=S01 rows=$R1 " || { grep '^published' .vid/tw/log > "$T/out"; fail "no follow-up of the skeleton's step S01 holding exactly $R1 was published"; }
grep -q "^- follows: #$N1\$" ".vid/tw/out/issue-$F1.md" || fail "the follow-up #$F1 does not name #$N1 as the ticket it follows"
# a proved-red: change alone owes #N2 an amendment
# and ROW-019, a test of the closed #N3, reworded while S03's follow-up #F is open
sed -e 's/^\(ROW-013 .*\)$/\1 | proved-red: 1a2b3c4/' -e 's/support address that reaches a person\./support address that reaches a person within a day./' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
grep -q 'reaches a person within a day' INVENTORY.md || fail 'ROW-019 could not be reworded'
g commit -qam "ROW-013's red proved, ROW-019 reworded"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the proved-red change'; }
sh "$CHECKS/replan.sh" ready > "$T/out" 2>&1 && grep -q "^apply${TB}own" "$T/out" || fail 'with a proved-red change alone pending, ready does not say apply own'
sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || fail "the second own proposal could not be made"
RC=0; sh "$CHECKS/replan.sh" apply --review "$T/none" --words 'Yes, apply the red proof' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the second apply exited $RC"
[ "$(grep -c "^amended $N2 " .vid/tw/log)" = 2 ] || fail "a change to ROW-013's proved-red: alone did not owe #$N2 an amendment"
F2=$(awk -v n="$F" '$1 == "published" && $2 + 0 > n + 0 && / step=S03 / { print $2 }' .vid/tw/log | tail -n 1)
[ -n "$F2" ] && grep "^published $F2 " .vid/tw/log | grep -q ' kind=step step=S03 rows=ROW-019 ' || { grep '^published\|^amended' .vid/tw/log > "$T/out"; fail "ROW-019, reset in the closed #$N3 while the follow-up #$F is open, is not out in a follow-up of its own"; }
grep -q "^- rows: ROW-007\$" ".vid/tw/out/issue-$F.md" || fail "the open follow-up #$F was changed to hold more than ROW-007"
# a ticket taken over by the switch itself (no step-start event), closed, keeps its follow-up
T=$(mktemp -d); . "$CHECKS/selftest/fixtures/manual.sh"; mn_project "$T/p"
R2=$(sed -n 's/^step S02 .*| rows: \([^|]*[^| ]\) *|.*/\1/p' "$T/plan.blk"); [ -n "$R2" ] || fail "S02's rows could not be read from the switch toy's plan"
M2=$(gh_issue 'Step S02'); mn_ticket "$M2" S02 step $R2 > "$T/t2"; gh_writing "$M2" "$T/t2" comments 2; printf '%s S02\n' "$M2" > "$T/register"; gh_wclear
mn_switch --applied "$AP" --words 'yes, ratify the taken-over plan'; cp "$T/mo" "$T/out"; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
! grep -q '^step-start .* step=S02 ' .vid/metrics-events || fail 'the switch recorded a start of S02'
echo CLOSED > "$FAKEGH/issues/$M2/state"
sed 's/Reading the same feed twice leaves/Reading one feed twice leaves/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; git commit -qam 'ROW-013 reworded'
VID_WRITER_CLOSED=$M2 VID_WRITER_AT=$(git rev-parse HEAD) sh "$CHECKS/writer.sh" due --why > "$T/out" 2>&1 || fail 'writer.sh due --why failed on the switched project'
grep -qx 'followup S02 ROW-013' "$T/out" || fail "the closed #$M2, taken over by the switch, is owed no follow-up of S02 holding ROW-013"
exit 0

#!/bin/sh
# Purpose: selftest case — the first amendment of a ticket taken over from comments names only the test added, with the move's own
# cause, and at the next call neither that test nor the body reads as a team change (GM-2 T5; its case manual-amend-taken-over). On
# the form fixture's toy (fixtures/form.sh), S02 posted in the form, then its records made those of a ticket /vid mode took over from
# its comments (fixtures/amend.sh's am_take_over: the switch's published line, no `sent` line, no form or kept-body record), its
# recorded writing older in its wording outside the rows (a line of its asks reworded). ROW-002 moves from S04 into S02 by a recorded
# plan change; amended with the cause the move gives. The notice opens with that cause, names ROW-002 as added and no test as
# restated or taken out, and says nothing of a plan change; the body stands byte for byte (taken over from comments); the kept body
# record is made. At the next call (next.sh read, next.sh changes) nothing is listed for the ticket. S03
# posted and taken over the same way; the team takes ROW-006 out of its body and adds a line naming ROW-011 (a test of S04). Both
# are listed. The yes to ROW-011 (checks/team-change.sh, as lane E's move will call it) amends S03: its notice names ROW-011 as the
# team's own addition; at the next call ROW-006's removal, unanswered, is still listed as dropped. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-amend-taken-over: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N; D=$FAKEGH/issues/$N
# taken over, its writing in an older wording outside its rows
awk '/^## Asks/ { a = 1 } a && /^- / && !d { $0 = $0 " (an older writer'"'"'s wording)"; d = 1 } { print }' ".vid/tw/out/issue-$N.md" > "$T/w" && cat "$T/w" > ".vid/tw/out/issue-$N.md"
grep -q "an older writer's wording" ".vid/tw/out/issue-$N.md" || fail 'the older wording did not take'
am_take_over "$N"; grep -q "^published $N .* taken-over=comments " .vid/tw/log && ! grep -q "^sent .* ticket=$N " .vid/tw/log || fail 'the take-over records did not take'
cp "$D/body" "$T/b0"
am_move ROW-002 S04 S02; am_change "$N" 'S02 takes ROW-002, the owner says' || { cp "$T/chg" "$T/out"; fail 'the plan change was refused'; }
am_amend "$N" "Yes, amend #$N" "the owner's own move: S02 gains ROW-002" || { cp "$T/post" "$T/out"; fail "#$N was not amended in manual"; }
am_comment "$N" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"
head -n 1 "$T/am" | grep -qF "vid: amended. Cause: the owner's own move: S02 gains ROW-002." || fail 'the notice does not open with the move'"'"'s cause'
[ "$(grep -c '^- ' "$T/am")" = 1 ] && grep -q '^- added: ROW-002 ' "$T/am" || fail 'the notice does not name ROW-002 as added, and nothing else'
! grep -qi 'plan change' "$T/am" || fail 'the notice names a plan change as its cause'
! grep -q 'restated\|changed rows' "$T/am" || fail 'the notice reads kept tests as restated'
cmp -s "$T/b0" "$D/body" || { diff "$T/b0" "$D/body" > "$T/out" || :; fail 'the body of a ticket taken over from comments changed'; }
[ -s ".vid/tw/body/issue-$N" ] || fail 'the kept body record was not made'
# the next call
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
! awk -F'\t' -v n="$N" '$2 == n' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail "a team change is listed for #$N after its amendment"; }
# S03 taken over; the team drops ROW-006 and adds ROW-011
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
am_take_over "$N3"; ! grep -q "^sent .* ticket=$N3 " .vid/tw/log && [ ! -f ".vid/tw/body/issue-$N3" ] || fail "S03's take-over records did not take"
fm_team_edit "$N3" 's/ROW-006, //g'; printf 'Also ROW-011, the team adds it.\n' >> "$FAKEGH/issues/$N3/body"; ! grep -q 'ROW-006' "$FAKEGH/issues/$N3/body" || fail 'the team edit did not take ROW-006 out'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed for S03'; }
awk -F'\t' -v n="$N3" '$1 == "dropped" && $2 == n && $3 == "ROW-006"' "$T/ch" | grep -q . && awk -F'\t' -v n="$N3" '$1 == "added" && $2 == n && $3 == "ROW-011"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail "the team's two changes on #$N3 are not both listed"; }
sh "$CHECKS/team-change.sh" "$N3" ROW-011 yes "Yes, S03 takes ROW-011" > "$T/out" 2>&1 || fail 'the yes to ROW-011 failed'
am_comment "$N3" 'vid: amended' | grep -q "^- added: ROW-011 .*the team's own addition" || fail "the notice does not name ROW-011 as the team's own addition on the taken-over ticket"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the yes'; }
awk -F'\t' -v n="$N3" '$1 == "dropped" && $2 == n && $3 == "ROW-006"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail "ROW-006's unanswered removal from #$N3 is no longer listed after the amendment"; }
exit 0

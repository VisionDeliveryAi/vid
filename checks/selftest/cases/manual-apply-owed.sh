#!/bin/sh
# Purpose: selftest case — what an apply owes a ticket taken over, and a post that fails (GM-3 U4; its case manual-apply-owed). On
# the form fixture's toy (fixtures/form.sh), S02 posted as #N and its records made those of a ticket /vid mode took over from its
# comments (fixtures/amend.sh's am_take_over), its recorded writing older in its wording outside the rows. With nothing pending,
# writer.sh due owes it nothing for that wording alone. ROW-012 reworded and committed (a reset, adding no test): `replan.sh
# ready` says `apply own`, and writer.sh due still owes nothing (the applied commit has not moved). `replan.sh apply --review
# --words` (its own proposal, no analysis) exits 0 and amends #N: its notice names ROW-012 restated and no other test. Then
# ROW-013 reworded and committed, and #N's comments made to fail on the fake: the apply exits 3, its records standing (the applied
# commit moved, the plan ratified), saying #N's amendment is owed; writer.sh due owes `amend <N>`, and at the next call next.sh
# triggers lists the move `amend #<N>`. S03 posted as #N3 too; the first apply, with no proposal shown, makes the
# own proposal and its page and refuses (exit 4, shown again), the applied commit unmoved; the next applies it. In the failing part
# ROW-007 (#N3's) is reworded too and #N3 closed: `replan.sh own` shows the follow-up of S03 holding ROW-007; the fake refuses to make
# its issue, so the apply also says S03's follow-up is owed; due owes `new step S03`, and next.sh triggers lists `publish S03`. The apply with its own proposal is given --review, the fresh agent's review its skill step
# makes (none here), since the toy's planner adds rows. GM-3 U4 and U6: at that next call each post the apply left owed is shown
# as critical, its cause the apply: a critical `apply-owed` trigger for #<N> and for S03, naming the apply's commit, and the amend
# and publish moves saying the apply owes them. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-apply-owed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'none\n' > "$T/none"   # the fresh agent's review of the rows ViD adds, as the apply's skill step makes it
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
awk '/^## Asks/ { a = 1 } a && /^- / && !d { $0 = $0 " (an older writer'"'"'s wording)"; d = 1 } { print }' ".vid/tw/out/issue-$N.md" > "$T/w" && cat "$T/w" > ".vid/tw/out/issue-$N.md"
am_take_over "$N"; grep -q "^published $N .* taken-over=comments " .vid/tw/log || fail 'the take-over records did not take'
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed'; }
! grep -qx "amend $N" "$T/due" || { cp "$T/due" "$T/out"; fail "#$N is owed an amendment for its older wording alone"; }
# a reset alone: the apply with its own proposal
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-012 reworded'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
sh "$CHECKS/replan.sh" ready > "$T/out" 2>&1 || fail 'replan.sh ready failed'
grep -q "^apply${TB}own" "$T/out" || fail 'with a reset alone pending, ready does not say apply own'
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed after the reset'; }
! grep -qx "amend $N" "$T/due" || { cp "$T/due" "$T/out"; fail "#$N is owed an amendment before the apply moved the applied commit"; }
# the apply's own proposal is never applied unseen: with none shown, the apply makes it and its page, and refuses
cp .vid/tw/applied "$T/ap0"; RC=0; sh "$CHECKS/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 4 ] && grep -q 'shown again' "$T/out" || fail "the apply with no proposal shown exited $RC, or did not say its proposal is shown again"
[ -f .vid/next/proposal/block ] && [ -f .vid/pages/REPLAN-PAGE.html ] && cmp -s "$T/ap0" .vid/tw/applied || fail 'the refused apply did not show its own proposal, or moved the applied commit'
RC=0; sh "$CHECKS/replan.sh" apply --review "$T/none" --words 'Yes, apply the reworded row' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply exited $RC"
grep -q "^amended $N " .vid/tw/log || fail "#$N was not amended"
am_comment "$N" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"
grep -q '^- restated: ROW-012 ' "$T/am" && [ "$(grep -c '^- \(added\|restated\|retired\|reached\|taken out\):' "$T/am")" = 1 ] || fail "#$N's notice does not name ROW-012 restated, and no other test"
# a post that fails: its amendment owed, listed at the next call
sed -e 's/Reading the same feed twice leaves/Reading one feed twice leaves/' -e 's/opens the unsubscribe page with no sign-in/opens the unsubscribe page at once, with no sign-in/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-013 and ROW-007 reworded'; HD=$(git rev-parse HEAD); echo CLOSED > "$FAKEGH/issues/$N3/state"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed before the failing post'; }
sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || fail "the apply's own proposal could not be made"
grep -q "^S03${TB}ROW-007\$" .vid/next/proposal/followup || { cat .vid/next/proposal/followup > "$T/out"; fail 'the own proposal does not hold the follow-up of S03 with ROW-007'; }
mv "$T/bin/gh" "$T/bin/gh.real"
printf '#!/bin/sh\nif [ "$1 $2" = "issue comment" ] && [ "$3" = "%s" ]; then echo "the comment could not be written" >&2; exit 1; fi\nif [ "$1 $2" = "issue create" ]; then echo "the issue could not be made" >&2; exit 1; fi\nexec "%s/bin/gh.real" "$@"\n' "$N" "$T" > "$T/bin/gh"; chmod +x "$T/bin/gh"
NA=$(grep -c "^amended $N " .vid/tw/log)
RC=0; sh "$CHECKS/replan.sh" apply --review "$T/none" --words 'Yes, apply ROW-013' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] && grep -q "owed amend #$N" "$T/out" && grep -q 'owed publish S03' "$T/out" || fail "the apply whose posts failed exited $RC, or did not say #$N's amendment and S03's follow-up are owed"
[ "$(sed -n 1p .vid/tw/applied)" = "$HD" ] && sh "$CHECKS/planner.sh" ratified > /dev/null 2>&1 || fail "the apply's records did not stand when its post failed"
[ "$(grep -c "^amended $N " .vid/tw/log)" = "$NA" ] || fail "#$N reads as amended though its post failed"
mv "$T/bin/gh.real" "$T/bin/gh"
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed after the failed post'; }
grep -qx "amend $N" "$T/due" || { cp "$T/due" "$T/out"; fail "#$N's amendment is not owed after its post failed"; }
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read failed at the next call'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^move${TB}amend${TB}#$N${TB}" "$T/tr" || { grep '^move' "$T/tr" > "$T/out"; fail "the next call does not list amend #$N"; }
grep -qx "new step S03" "$T/due" || { cp "$T/due" "$T/out"; fail "S03's follow-up is not owed after its post failed"; }
grep -q "^move${TB}publish${TB}S03${TB}" "$T/tr" || { grep '^move' "$T/tr" > "$T/out"; fail "the next call does not list publish S03, the follow-up left unposted"; }
# the next call shows each post the apply left owed as critical, its cause the apply
A12=$(printf %.12s "$HD"); cp "$T/tr" "$T/out"
grep -q "^trigger${TB}critical${TB}apply-owed${TB}#$N${TB}the apply $A12 left it owed" "$T/tr" && grep -q "^trigger${TB}critical${TB}apply-owed${TB}S03${TB}the apply $A12 left it owed" "$T/tr" ||
  fail "the next call does not show #$N's amendment and S03's follow-up as critical, owed by the apply $A12"
grep -q "^move${TB}amend${TB}#$N${TB}[0-9a-f]*${TB}.*; owed by the apply $A12, whose post did not go out" "$T/tr" && grep -q "^move${TB}publish${TB}S03${TB}[0-9a-f]*${TB}.*; owed by the apply $A12, whose post did not go out" "$T/tr" ||
  fail "the amend #$N and publish S03 moves do not name the apply as their cause"
exit 0

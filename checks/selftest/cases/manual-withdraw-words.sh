#!/bin/sh
# Purpose: selftest case — in GitHub manual nothing is withdrawn, and no test taken out of a published ticket, without the owner's
# words (GM-2 T6; its case manual-withdraw-words). On the form fixture's toy (fixtures/form.sh), S02 and S05 posted. S05 leaves the
# plan by a recorded change (its one test on .vid/tw/to-place with the owner's words, S04's fakes: no longer naming it), and ROW-012
# moves out of S02 into S04 in the same change. writer.sh due owes `withdraw <S05's ticket>`; next.sh triggers lists it as the move
# `withdraw #<n>`, and the issue stays open. tw-close with no words is refused and writes nothing; tw-post --amend of S02 with no
# words is refused and writes nothing. With the words: S05's ticket is closed, its `withdrawn` line ends with them, and its comment
# names no plan change; S02's amendment names ROW-012 as taken out at the owner's word, going to step S04. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-withdraw-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
fm_post S05 || { cp "$T/post" "$T/out"; fail 'S05 was not posted in manual'; }; N5=$FM_N
# S05 out of the plan, ROW-012 out of S02
grep -v '^step S05 \|^needs ROW-017 ' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; pt_rs 's/ | fakes: S05//'
am_move ROW-012 S02 S04
printf 'ROW-017\tno-step\t2026-11-19T11:00:00Z\tsearch waits, the owner says\n' > .vid/tw/to-place
am_change "$N5" 'S05 waits; S04 takes ROW-012' || { cp "$T/chg" "$T/out"; fail 'the plan change was refused'; }
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1; sh "$CHECKS/github.sh" tw-sync >> "$T/out" 2>&1
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed'; }
grep -q "^withdraw $N5\( \|\$\)" "$T/due" || { cp "$T/due" "$T/out"; fail "due does not owe the withdrawal of #$N5"; }
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^move${TB}withdraw${TB}#$N5${TB}" "$T/tr" || { grep '^move\|^unread' "$T/tr" > "$T/out"; fail "the withdrawal of #$N5 is not listed as a move"; }
[ "$(cat "$FAKEGH/issues/$N5/state")" = OPEN ] || fail "#$N5 was closed by the listing"
# no words: refused, nothing written
gh_wclear; RC=0; sh "$CHECKS/github.sh" tw-close "$N5" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'words' "$T/out" || fail "tw-close with no words exited $RC, not a refusal naming the words"
[ ! -s "$FAKEGH/writes" ] && [ "$(cat "$FAKEGH/issues/$N5/state")" = OPEN ] && ! grep -q "^withdrawn $N5 " .vid/tw/log || fail "#$N5 was withdrawn with no words"
F=$(sh "$CHECKS/writer.sh" write amend "$N2" 2> "$T/out") || fail "the amendment of #$N2 could not be written"
gh_wclear; RC=0; sh "$CHECKS/github.sh" tw-post --amend "$N2" "$F" > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] && [ ! -s "$FAKEGH/writes" ] && ! grep -q "^amended $N2 " .vid/tw/log || fail "#$N2 lost a test with no words (tw-post exited $RC)"
# with the words
sh "$CHECKS/github.sh" tw-close --words "Yes, withdraw #$N5" "$N5" > "$T/out" 2>&1 || fail "tw-close with the words was refused"
[ "$(cat "$FAKEGH/issues/$N5/state")" = CLOSED ] || fail "#$N5 is not closed"
grep -q "^withdrawn $N5 .* words=\"Yes, withdraw #$N5\"\$" .vid/tw/log || fail "#$N5's withdrawn line does not end with the words"
am_comment "$N5" 'vid: withdrawn' > "$T/wd"; cp "$T/wd" "$T/out"; [ -s "$T/wd" ] && ! grep -qi 'plan change' "$T/wd" || fail "#$N5's withdrawal comment is missing or names a plan change"
am_amend "$N2" "Yes, amend #$N2" || { cp "$T/post" "$T/out"; fail "#$N2 was not amended with the words"; }
am_comment "$N2" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"
grep -q "^- taken out: ROW-012 .*at the owner's word.*step S04" "$T/am" || fail "#$N2's notice does not name ROW-012 as taken out at the owner's word, to step S04"
exit 0

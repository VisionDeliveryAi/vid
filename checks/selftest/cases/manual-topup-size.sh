#!/bin/sh
# Purpose: selftest case — a top-up of a published ticket is flagged by size, kept with the owner's words, never refused (GM-2 T6;
# its case manual-topup-size). The rule, one place (writer.sh topup <added> <tests>): 2 added to 12 tests is not flagged; 3 added to
# 12 is (more than a fifth), and so are 6 added to 40 (more than 5); 1 added to 5 is not, 2 to 5 is. Then two real amendments on the
# form fixture's toy (fixtures/form.sh): S03 (12 tests) gains ROW-002 and ROW-009 from S04, amended unflagged: its `amended` line holds
# added=ROW-002,ROW-009 and no size=, its notice no top-up line; S02 (11 tests) gains ROW-011, ROW-018 and HOS-003, amended flagged and
# not refused: its line holds added= those three and size=3/11 before the owner's words, and its notice names the size. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-topup-size: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tu() { sh "$CHECKS/writer.sh" topup "$1" "$2" 2> "$T/out"; }
for c in '2 12' '1 5'; do set -- $c; [ -z "$(tu "$1" "$2")" ] || fail "$1 added to $2 tests is flagged"; done
for c in '3 12' '6 40' '2 5'; do set -- $c; [ -n "$(tu "$1" "$2")" ] || fail "$1 added to $2 tests is not flagged"; done
tu 6 40 | grep -q 'more than 5' || fail '6 added to 40 is not flagged as more than 5'
tu 3 12 | grep -q 'more than a fifth' || fail '3 added to 12 is not flagged as more than a fifth'
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
[ "$(awk -v n="$N3" '$1 == "published" && $2 == n' .vid/tw/log | tr ' ' '\n' | sed -n 's/^rows=//p' | tr , '\n' | grep -c .)" = 12 ] || fail 'S03 does not hold 12 tests'
# 2 added to 12: unflagged
am_move ROW-002 S04 S03; am_move ROW-009 S04 S03; am_change "$N3" 'S03 takes two rows of S04' || { cp "$T/chg" "$T/out"; fail 'the first plan change was refused'; }
am_amend "$N3" "Yes, amend #$N3" || { cp "$T/post" "$T/out"; fail "#$N3 was not amended"; }
L3=$(grep "^amended $N3 " .vid/tw/log | tail -n 1); echo "$L3" > "$T/out"
case "$L3" in *" added=ROW-009,ROW-002 "*|*" added=ROW-002,ROW-009 "*) ;; *) fail "#$N3's amended line does not hold its two added tests" ;; esac
case "$L3" in *' size='*) fail "#$N3's top-up of 2 to 12 is flagged" ;; esac
am_comment "$N3" 'vid: amended' > "$T/am"; ! grep -qi 'size' "$T/am" || { cp "$T/am" "$T/out"; fail "#$N3's notice names a size"; }
# 3 added to 11: flagged, not refused
am_move ROW-011 S04 S02; am_move ROW-018 S04 S02; am_move HOS-003 S04 S02; am_change "$N2" 'S02 takes three rows of S04' || { cp "$T/chg" "$T/out"; fail 'the second plan change was refused'; }
am_amend "$N2" "Yes, amend #$N2, big as it is" || { cp "$T/post" "$T/out"; fail "#$N2's flagged top-up was refused"; }
L2=$(grep "^amended $N2 " .vid/tw/log | tail -n 1); echo "$L2" > "$T/out"
printf '%s\n' "$L2" | grep -qE ' added=[A-Z0-9,-]+ size=3/11 words="Yes, amend #'"$N2"', big as it is"$' || fail "#$N2's amended line does not keep size=3/11 with the owner's words"
for r in ROW-011 ROW-018 HOS-003; do printf '%s\n' "$L2" | tr ' ' '\n' | sed -n 's/^added=//p' | tr , '\n' | grep -qx "$r" || fail "#$N2's added= lacks $r"; done
am_comment "$N2" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"; grep -q 'more than a fifth' "$T/am" || fail "#$N2's notice does not name the size flag"
exit 0

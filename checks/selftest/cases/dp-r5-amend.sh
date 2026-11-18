#!/bin/sh
# Purpose: selftest case — naming a decision for a step with an open ticket owes its amendment (0.26.10.29.5, DP-1 R5). On
# TW's toy, S02's ticket (#2) is open and owes nothing; once writer.sh name names D-005 (labelled for a row no ticket holds)
# for S02, writer.sh due owes amend 2, the amendment quotes D-005, and once it is posted nothing is owed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r5-amend: $*" >&2; cat "$T/out" "$T/due" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
printf -- '- **D-005** the digest lists at most fifty jobs a page | why: one screen | enforced: convention | applies-to: ROW-999\n' >> DECISIONS.md
g commit -qam 'a decision'
tw_skel || fail 'the skeleton round failed'
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; [ "$TW_N" = 2 ] || fail "S02's ticket is #$TW_N"
sh "$GS" tw-sync > /dev/null 2>&1
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; ! grep -qx 'amend 2' "$T/due" || fail 'S02 owes an amendment before any name'
! sec "$TW_F" Decisions | grep -q 'D-005' || fail 'D-005 joined S02 without its name'
sh "$W" name S02 D-005 > "$T/out" 2>&1 || fail 'S02 and D-005 were refused'
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; grep -qx 'amend 2' "$T/due" || fail 'naming a decision for S02 owes no amendment of its open ticket'
tw_post amend 2 || fail 'the amendment was refused'; sec "$TW_F" Decisions | grep -q 'D-005' || fail 'the amendment lacks D-005'
sh "$GS" tw-sync > /dev/null 2>&1
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; ! grep -qx 'amend 2' "$T/due" || fail 'the amendment is still owed once posted'
echo 'dp-r5-amend: ok'

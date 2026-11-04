#!/bin/sh
# Purpose: selftest case — fix tickets, W6 (v0.26.10.12.3 R5). On TW's toy, S02's
# ticket (#2) merged and S03's (#3) open: from the stand-in's fix ask for ROW-001, `writer.sh due` owes `new fix ROW-001`;
# its fix ticket is of S02, the row's own started step, holds the row with the reason it failed, and links to its
# earlier ticket and to the ask's failing decision and run; it asks T1–T5, the base allowed as the tests-first commit;
# once published, it is no longer owed. A second ask for the row links the fix ticket too. A fix of the stage-0 row
# ROW-003 stays the skeleton step's. A fix for ROW-010, deploy-owed, waits while its ticket is open, then asks T1, T3
# and T5 only: no red and no fault. Refused: an unknown row, a known limit, a row with no ask. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-fix: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
asks() { sec "$1" Asks | sed -n 's/^- \(T[1-5]\) .*/\1/p' | paste -sd ' ' -; }
tw_skel || fail 'the skeleton round failed'
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; [ "$TW_N" = 2 ] || fail "S02's ticket is #$TW_N"
tw_hand 'closed S02'; tw_close 2; tw_start S03 || fail 'S03 was refused'; tw_post step S03 || fail "S03's ticket was refused"
sh "$GS" tw-sync > /dev/null 2>&1
tw_hand 'fix ROW-001 | its digest held a job it had sent the day before, at the close run | decision on pull request 7, close run 4123'
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; grep -qx 'new fix ROW-001' "$T/due" || fail "the fix ask is not owed: $(cat "$T/due")"
tw_post fix ROW-001 || fail 'the fix ticket was refused'; F=$TW_F; N=$TW_N
grep -qx -- '- kind: fix' "$F" && grep -qx -- '- step: S02' "$F" && grep -qx -- '- rows: ROW-001' "$F" || fail 'the fix ticket is not of S02, the row'"'"'s step'
sec "$F" Rows | grep -qx -- '- ROW-001 failed: its digest held a job it had sent the day before, at the close run' || fail 'the reason is missing'
sec "$F" History | grep -qx -- '- ROW-001: its earlier tickets #2; its failing decisions, fix tickets and runs: decision on pull request 7, close run 4123.' || fail 'the links are missing'
[ "$(asks "$F")" = 'T1 T2 T3 T4 T5' ] && sec "$F" Asks | grep -q 'TM may name the base as the tests-first commit' || fail "the fix ticket asks $(asks "$F")"
sh "$W" due > "$T/due" 2>&1; ! grep -q 'new fix ROW-001' "$T/due" || fail 'a published fix ask is still owed'
grep -q "^published $N kind=fix step=S02 rows=ROW-001 .* fix=[0-9]" .vid/tw/log || fail 'the fix ticket is not logged with its ask'
# a second ask links the fix ticket; a stage-0 row's fix stays the skeleton step's
tw_close "$N"; sh "$GS" tw-sync > /dev/null 2>&1; tw_hand 'fix ROW-001 | it failed again in the staging run | staging run 4200'
tw_post fix ROW-001 || fail 'the second fix ticket was refused'; sec "$TW_F" History | grep -q "^- ROW-001: its earlier tickets #2, #$N; " || fail 'the second fix does not link the first fix ticket'
tw_close "$TW_N"; tw_hand 'fix ROW-003 | the saved state lost its line in the close run | close run 4300'
tw_post fix ROW-003 || fail "ROW-003's fix was refused"; grep -qx -- '- step: S01' "$TW_F" || fail "a stage-0 row's fix is not the skeleton step's"
# a deploy-owed row's fix: no red and no fault, and only once its open ticket is closed
tw_hand 'fix ROW-010 | the unsubscribe stopped no digest on staging | staging run 4400'
if sh "$W" write fix ROW-010 > "$T/out" 2>&1; then fail 'a fix was written for a row in an open ticket'; fi; grep -q 'ROW-010 is in an open ticket' "$T/out" || fail 'the open ticket is not named'
tw_close 3; sh "$GS" tw-sync > /dev/null 2>&1; tw_post fix ROW-010 || fail "ROW-010's fix was refused"; D=$TW_F
[ "$(asks "$D")" = 'T1 T3 T5' ] && grep -q 'Every row of this ticket is deploy-owed' "$D" && sec "$D" 'Faulted rows' | grep -qx none || fail "the deploy-owed fix asks $(asks "$D"), or is faulted"
# refusals
tw_hand 'row ROW-016 known-limit'; tw_hand 'fix ROW-016 | it failed | run 1'
for r in ROW-999 ROW-016 ROW-002; do if sh "$W" write fix "$r" > "$T/out" 2>&1; then fail "a fix ticket was written for $r"; fi; done
sh "$W" write fix ROW-999 > "$T/out" 2>&1 || true; grep -q 'ROW-999 is no row' "$T/out" || fail 'an unknown row is not named'
sh "$W" write fix ROW-016 > "$T/out" 2>&1 || true; grep -q 'ROW-016 is a known limit' "$T/out" || fail 'a known limit is not named'
sh "$W" write fix ROW-002 > "$T/out" 2>&1 || true; grep -q 'no fix ask for ROW-002' "$T/out" || fail 'a row with no ask is not named'
exit 0

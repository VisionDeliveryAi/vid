#!/bin/sh
# Purpose: selftest case — fix tickets, W6 (v0.26.10.12.3 R5). On TW's toy, S02's
# ticket (#2) merged and S03's (#3) open: from the stand-in's fix ask for ROW-001, `writer.sh due` owes `new fix ROW-001`;
# its fix ticket is of S02, the row's own started step, holds the row with the reason it failed, and links to its
# earlier ticket and to the ask's failing decision and run; it asks T1–T5, the base allowed as the tests-first commit;
# once published, it is no longer owed. A second ask for the row links the fix ticket too. A fix of the stage-0 row
# ROW-003 stays the skeleton step's. A fix for ROW-010, deploy-owed, waits while its ticket is open, then asks T1, T3
# and T5 only: no red and no fault. Refused: an unknown row, a known limit, a row with no ask. v0.26.10.25.4 (R1, R2, R5): a fix line is
# owed by its key, a hash of its text, found again when a line above it moves; one line of three rows is one fix ticket, in the step of
# the close it names, each row with its own reason; an `again` line beside it is owed too, and waits while its row's ticket is open; a
# row ruled a known limit leaves the unpublished line, and a line left empty owes nothing; rule 2 tells the grader of a fix ticket to
# read it without failed: lines, History or why:. Env: CHECKS.
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
key() { printf '%s' "$1" | cksum | cut -d' ' -f1; }; K1=$(key 'fix ROW-001 | its digest held a job it had sent the day before, at the close run | decision on pull request 7, close run 4123')
sh "$W" due > "$T/due" 2>&1 || fail 'due failed'; grep -qx "new fix $K1" "$T/due" || fail "the fix ask is not owed by its key: $(cat "$T/due")"
tw_post fix ROW-001 || fail 'the fix ticket was refused'; F=$TW_F; N=$TW_N
grep -qx -- '- kind: fix' "$F" && grep -qx -- '- step: S02' "$F" && grep -qx -- '- rows: ROW-001' "$F" || fail 'the fix ticket is not of S02, the row'"'"'s step'
sec "$F" Rows | grep -qx -- '- ROW-001 failed: its digest held a job it had sent the day before, at the close run' || fail 'the reason is missing'
sec "$F" History | grep -qx -- '- ROW-001: its earlier tickets #2; its failing decisions, fix tickets and runs: decision on pull request 7, close run 4123.' || fail 'the links are missing'
[ "$(asks "$F")" = 'T1 T2 T3 T4 T5' ] && sec "$F" Asks | grep -q 'TM may name the base as the tests-first commit' || fail "the fix ticket asks $(asks "$F")"
sh "$W" due > "$T/due" 2>&1; ! grep -q "new fix $K1" "$T/due" || fail 'a published fix ask is still owed'
grep -q "^published $N kind=fix step=S02 rows=ROW-001 .* fix=$K1 " .vid/tw/log || fail 'the fix ticket is not logged with its key'
grep -q '^2\. GR is .* GR reads the ticket without the why: of each decision, and a fix ticket also without its failed: lines and its History' "$F" || fail 'rule 2 does not keep the history from the grader'
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
# one line of three rows, of a close of S02: one ticket, each row its reason; found again by its key once a line above it moves
L3='fix ROW-005 ROW-008 ROW-012 | ROW-005: ROW-005 lists a job once in chromium; ROW-008: ROW-008 skips old jobs in chromium, ROW-008 skips old jobs in firefox; ROW-012: ROW-012-T1 with no case in firefox | close #9 of S02: req-9-p1c1-1, req-9-p2c1-1'
L2='fix ROW-008 | ROW-008: ROW-008 skips old jobs in chromium | close #9 of S02: req-9-p1c1-2'; tw_hand "$L3"; tw_hand "$L2"; K3=$(key "$L3"); K2=$(key "$L2")
{ printf 'row ROW-099 accepted | stand-in: decision\n'; cat .vid/tw/handed; } > "$T/h"; cat "$T/h" > .vid/tw/handed
sh "$W" due > "$T/due" 2>&1; grep -qx "new fix $K3" "$T/due" && grep -qx "new fix $K2" "$T/due" || fail "the lines are not owed by their keys after a line moved: $(cat "$T/due")"
tw_post fix "$K3" || fail "the three rows' fix was refused: $(cat "$T/werr")"; F3=$TW_F; N3=$TW_N; grep -qx -- '- rows: ROW-005 ROW-008 ROW-012' "$F3" && grep -qx -- '- step: S02' "$F3" || fail 'the three rows are not one ticket of S02'
sec "$F3" Rows | grep -qx -- '- ROW-008 failed: ROW-008 skips old jobs in chromium, ROW-008 skips old jobs in firefox' && sec "$F3" Rows | grep -qx -- '- ROW-012 failed: ROW-012-T1 with no case in firefox' || fail 'each row does not carry its own reason'
sh "$W" check "$F3" > "$T/out" 2>&1 || fail 'the fix ticket fails the check'
if sh "$W" write fix "$K2" > "$T/out" 2>&1; then fail 'the again line was written while its row is in an open ticket'; fi; grep -q 'ROW-008 is in an open ticket' "$T/out" || fail 'the open ticket is not named'
tw_close "$N3"; sh "$GS" tw-sync > /dev/null 2>&1; tw_post fix "$K2" || fail 'the again line was refused once the first fix closed'; grep -qx -- '- rows: ROW-008' "$TW_F" || fail 'the again line is not its own ticket'
# a refused word in a case's name is no refusal of the ticket
tw_close "$TW_N"; sh "$GS" tw-sync > /dev/null 2>&1; L5='fix ROW-016 | ROW-016: ROW-016 rejects a damn password in chromium | close #12 of S02: req-12-p1c1-1'; tw_hand "$L5"
F5=$(sh "$W" write fix "$(key "$L5")" 2> "$T/werr") || fail "a reason with a refused word was refused: $(cat "$T/werr")"; grep -qx -- '- ROW-016 failed: ROW-016 rejects a (a word) password in chromium' "$F5" || fail 'the word was not masked'; rm -f "$F5"; grep -vxF "$L5 | stand-in: the self-test" .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed
# a known limit leaves an unpublished line; a line left empty owes nothing
tw_close "$TW_N"; sh "$GS" tw-sync > /dev/null 2>&1; L4='fix ROW-013 ROW-015 | ROW-013: ROW-013 in chromium; ROW-015: ROW-015 in chromium | close #11 of S02: req-11-p1c1-1'; tw_hand "$L4"; K4=$(key "$L4")
tw_hand 'row ROW-013 known-limit'; F4=$(sh "$W" write fix "$K4" 2> "$T/werr") || fail "the line less its limit was refused: $(cat "$T/werr")"; grep -qx -- '- rows: ROW-015' "$F4" || fail 'a known limit stayed in the line'
tw_hand 'row ROW-015 known-limit'; if sh "$W" fresh "$F4" > "$T/out" 2>&1; then fail 'a draft holding a row since ruled a known limit reads fresh'; fi; grep -q 'ROW-015 is now a known limit' "$T/out" || fail 'the stale row is not named'
sh "$W" due > "$T/due" 2>&1; ! grep -q "new fix $K4" "$T/due" || fail 'a line of known limits alone is still owed'
# refusals
tw_hand 'row ROW-016 known-limit'; tw_hand 'fix ROW-016 | it failed | run 1'
for r in ROW-999 ROW-016 ROW-002; do if sh "$W" write fix "$r" > "$T/out" 2>&1; then fail "a fix ticket was written for $r"; fi; done
sh "$W" write fix ROW-999 > "$T/out" 2>&1 || true; grep -q 'ROW-999 is no row' "$T/out" || fail 'an unknown row is not named'
sh "$W" write fix ROW-016 > "$T/out" 2>&1 || true; grep -q 'ROW-016 is a known limit' "$T/out" || fail 'a known limit is not named'
sh "$W" write fix ROW-002 > "$T/out" 2>&1 || true; grep -q 'no fix ask for ROW-002' "$T/out" || fail 'a row with no ask is not named'
exit 0

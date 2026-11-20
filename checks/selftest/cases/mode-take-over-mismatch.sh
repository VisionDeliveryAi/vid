#!/bin/sh
# Purpose: selftest case — a copy line that differs from the ticket's quote is never written into the spec (GM-3 S2, its case
# mode-take-over-mismatch). On the fake gh, the toy of mode-take-over (fixtures/manual.sh mn_takeover), the copy changed after
# the tickets were written: ROW-022's line reworded, ROW-023's line gone. With --from and the owner's yes the switch refuses,
# naming each row and why; no take-over commit, no ref under refs/vid, no commit at HEAD, INVENTORY.md and the applied version
# untouched, the lock freed. The copy put back as the tickets quote it, the take-over goes on. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-take-over-mismatch: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
sw() { MN_RC=0; sh "$CHECKS/mode.sh" manual --register "$T/register" --applied "$MN_H" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
mn_takeover "$T/p"
H0=$(git rev-parse HEAD); TC=$T/copy; cp INVENTORY.md "$T/inv0"; cp "$TC/INVENTORY.md" "$T/cinv"
# the copy changed after the tickets were written: ROW-022 reworded, ROW-023 gone
sed 's/^\(ROW-022 .*\)A digest names the saved search/\1A digest names the search/' "$T/cinv" | grep -v '^ROW-023 ' > "$TC/INVENTORY.md"
grep -q '^ROW-022 .*A digest names the search it' "$TC/INVENTORY.md" || fail 'the fixture did not reword ROW-022 in the copy'
sw --from "$TC" --take-over 'yes, write them in'
[ "$MN_RC" = 1 ] || fail "the switch with a copy line differing from the quote exited $MN_RC, not 1"
grep -q "^take-over-refused ROW-022 #$MN_N2 — .*differs" "$T/mo" || fail 'the refusal does not name ROW-022, whose copy line differs from the quote'
grep -q "^take-over-refused ROW-023 #$MN_N2 — .*no line" "$T/mo" || fail 'the refusal does not name ROW-023, which the copy holds no line for'
grep -q '^take-over-row ' "$T/mo" && fail 'a row was listed to take over beside a refused one'
[ -z "$(git for-each-ref refs/vid/)" ] || fail 'a take-over commit was kept under refs/vid'
[ -z "$(git log --format=%H "$H0..HEAD" -- INVENTORY.md PLAN.md)" ] && cmp -s INVENTORY.md "$T/inv0" && [ -z "$(git status --porcelain -- INVENTORY.md)" ] || fail 'the refused take-over changed HEAD or INVENTORY.md'
for c in $(git rev-list --all); do git show "$c:INVENTORY.md" 2>/dev/null; done | grep -q 'A digest names the search it' && fail 'the differing copy line was written into a commit'
[ ! -s .vid/tw/applied ] || fail 'the refused take-over recorded an applied version'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the refusal'
# the copy as the tickets quote it: the take-over goes on, to the rows to place
cp "$T/cinv" "$TC/INVENTORY.md"
sw --from "$TC" --take-over 'yes, write them in'
[ "$MN_RC" = 1 ] && grep -q 'rows are to place' "$T/mo" && git rev-parse -q --verify refs/vid/applied/1 > /dev/null || fail "with the copy matching the quotes the switch exited $MN_RC, not taken over and stopped at the rows to place"
echo 'mode-take-over-mismatch: ok'

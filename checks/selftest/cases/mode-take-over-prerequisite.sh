#!/bin/sh
# Purpose: selftest case — a take-over takes a row whose quote holds an `owed: prerequisite` note (FB-3 C1). The take-over toy
# (fixtures/manual.sh mn_takeover), ROW-023's line in the copy and its quote in #2 made owed on a prerequisite: the switch with
# --from lists `take-over-row ROW-023 #2`, never `take-over-refused`. Control: a quote whose promise differs is refused still.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-take-over-prerequisite: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
sw() { MN_RC=0; sh "$CHECKS/mode.sh" manual --register "$T/register" --applied "$MN_H" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
mn_takeover "$T/p"
NOTE='/ROW-023 /s/owed: spec-only — first stage/owed: prerequisite — the clock the test sets/'
sed "$NOTE" "$T/copy/INVENTORY.md" > "$T/i" && cat "$T/i" > "$T/copy/INVENTORY.md"
sed "$NOTE" "$T/t2" > "$T/i" && cat "$T/i" > "$T/t2"; gh_writing "$MN_N2" "$T/t2" body 2
grep -q '^ROW-023 .*| owed: prerequisite' "$T/copy/INVENTORY.md" && grep -q '^> ROW-023 .*| owed: prerequisite' "$T/t2" || fail 'the note did not land'
sw --from "$T/copy"
grep -q '^take-over-refused' "$T/mo" && fail "ROW-023, quoted as the copy's line stands, is refused"
grep -q "^take-over-row ROW-023 #$MN_N2 " "$T/mo" && grep -q -- '--take-over' "$T/mo" || fail 'ROW-023 is not a row to take over'
# control: another promise in the quote
sed '/^> ROW-023 /s/newest first/oldest first/' "$T/t2" > "$T/i" && gh_writing "$MN_N2" "$T/i" body 2
sw --from "$T/copy"
grep -q "^take-over-refused ROW-023 #$MN_N2 " "$T/mo" || fail 'a quote of another promise is taken over'
echo 'mode-take-over-prerequisite: ok'

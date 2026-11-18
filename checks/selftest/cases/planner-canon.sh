#!/bin/sh
# Purpose: selftest case — the writer's gate reads the plan as the admission does (0.26.10.29.2, R1). On the planner's
# toy, ratified: RUN-STATE's block re-spaced (S05's line with runs of spaces) and S04's rows re-ordered, unrecorded,
# still reads as ratified (`planner.sh ratified` exits 0), as the admission counts a canonically equal block unchanged,
# and so does S05's row written twice in its step;
# a real edit (S05's rows changed) still reads as not ratified. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-canon: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
pl() { sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1; }
cd "$T"; pt_toy "$T/toy"; printf 'none\n' > "$T/none"
pl review --in "$T/none" && pl page && pl ratify --words 'yes' || fail 'the toy was not ratified'
pt_rs 's/^step S05 | name: synonym-aware search | modules: search |/step S05  |  name:   synonym-aware search |	modules: search  |/; s/rows: ROW-002 ROW-009 ROW-011/rows: ROW-011 ROW-002   ROW-009/'
grep -q 'rows: ROW-011 ROW-002   ROW-009' .vid/RUN-STATE.md && grep -q '^step S05  |  name:   ' .vid/RUN-STATE.md || fail 'the toy block was not re-spaced'
pl ratified || fail 'a block canonically equal to the newest recorded plan reads as not ratified'
pt_rs 's/rows: ROW-017 |/rows: ROW-017 ROW-017 |/'; grep -q 'rows: ROW-017 ROW-017 |' .vid/RUN-STATE.md || fail 'ROW-017 was not repeated'
pl ratified || fail 'a block whose step repeats a row (canonically equal) reads as not ratified'
pt_rs 's/^\(step S05 .*rows: \)ROW-017/\1ROW-017 ROW-020/'
if pl ratified; then fail 'a block that changed a step'"'"'s rows still reads as ratified'; fi
grep -q 'not the newest recorded plan' "$T/out" || fail 'the changed block is not named'
exit 0

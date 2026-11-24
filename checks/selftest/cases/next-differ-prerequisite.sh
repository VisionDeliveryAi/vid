#!/bin/sh
# Purpose: selftest case — an `owed: prerequisite` note is no difference (FB-3 C1). On the toy switched to GitHub manual with
# ROW-006 and ROW-007 owed on a prerequisite, quoted in #3 with the note as their lines stand, and ROW-001's quote in #2 with one
# word changed: `next.sh differ` names ROW-001 alone (not a note's row, with or without the note in the quote); the switch's
# `differs` lines the same; and the call's count holds one restated row. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "next-differ-prerequisite: $*" >&2; cat "$T/mo" "$T/out" >&2 2>/dev/null || true; exit 1; }
TB=$(printf '\t')
mn_project "$T/p"
sed -e '/^ROW-00[67] /s/owed: spec-only — first stage/owed: prerequisite — the page frame the test opens/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
[ "$(grep -c '^ROW-00[67] .*| owed: prerequisite' INVENTORY.md)" = 2 ] || fail 'the notes did not land'
git commit -qam 'two rows owed on a prerequisite'; AP=$(git rev-parse HEAD)
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 | sed '/^> ROW-001 /s/one digest a day/two digests a day/' > "$T/t2"; gh_writing "$N2" "$T/t2" body 2
grep -q '^> ROW-001 .*two digests a day' "$T/t2" || fail "ROW-001's quote was not changed"
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 ROW-007 | sed '/^> ROW-007 /s/ | owed: prerequisite[^|]*//' > "$T/t3"; gh_writing "$N3" "$T/t3" body 2
grep -q '^> ROW-006 .*| owed: prerequisite' "$T/t3" && ! grep -q '^> ROW-007 .*owed:' "$T/t3" || fail "#$N3 does not quote one row with its note and one without"
printf '%s S01\n%s S02\n%s S03\n' "$N1" "$N2" "$N3" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
[ "$(grep '^differs ' "$T/mo" | paste -sd, -)" = "differs $N2 ROW-001" ] || fail "the switch printed $(grep '^differs ' "$T/mo" | paste -sd, -), not differs $N2 ROW-001 alone"
for n in "$N1" "$N2" "$N3"; do sh "$CHECKS/next.sh" differ "$n"; done > "$T/out" 2>&1 || fail 'next.sh differ failed'
[ "$(cat "$T/out")" = "differ$TB$N2${TB}ROW-001" ] || fail 'next.sh differ does not name ROW-001 alone'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^count${TB}restated${TB}1\$" "$T/out" && grep -q "^counted${TB}restated${TB}ROW-001${TB}" "$T/out" || fail "the count's restated is $(grep "^count${TB}restated" "$T/out" | cut -f3), not 1, ROW-001"
# the promise beside the note changed: a difference
sed '/^ROW-006 /s/the support address/the help address/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
[ "$(sh "$CHECKS/next.sh" differ "$N3")" = "differ$TB$N3${TB}ROW-006" ] || fail 'a row whose promise changed beside its note is not a difference'
echo 'next-differ-prerequisite: ok'

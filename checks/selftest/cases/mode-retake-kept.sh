#!/bin/sh
# Purpose: selftest case — a take-stock asks only what is new (FB-3 C4). A switch to GitHub manual with ROW-002 to place, in the
# owner's words. A re-take with no flag and nothing changed records it, asks nothing, says `ratified-kept`, and leaves the list and
# the ratification byte for byte; `--words` given ratifies afresh, the row kept. A second row out of the plan: the re-take lists and
# asks that one alone, and with its words the first keeps its time and words. A row as of another stage is asked again. A spec commit
# restating ROW-002 and moved by --applied: ROW-002 is asked again. A switch asks as before: refused with no words, the mode left.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-retake-kept: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
retake() { MN_RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
out_() { sed -e "s/^\(step S04 .*rows: .*\)$1 /\1/" -e "s/^\(needs .*\)$1 /\1/" "$T/plan.blk" > "$T/b" && mv "$T/b" "$T/plan.blk"; ! grep -q "$1" "$T/plan.blk" || fail "$1 is still in the plan block"; }
mn_project "$T/p"; out_ ROW-002
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
W='yes: ROW-002 waits for a step'
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] && [ "$(mode_)" = none ] || fail "a switch with a row to place and no words for it exited $MN_RC"
mn_switch --applied "$AP" --to-place "$W"
[ "$MN_RC" = 1 ] && [ "$(mode_)" = none ] || fail "a switch with no yes exited $MN_RC"
mn_switch --applied "$AP" --to-place "$W" --words 'yes, ratify'
[ "$MN_RC" = 0 ] && [ "$(grep -c . .vid/tw/to-place)" = 1 ] || fail "the switch exited $MN_RC"
cp .vid/tw/to-place "$T/tp"; cp .vid/plan/ratified "$T/ra"

# nothing changed: nothing asked
retake
[ "$MN_RC" = 0 ] && grep -qx 'mode: GitHub manual, re-taken' "$T/mo" || fail "the re-take with nothing changed exited $MN_RC"
grep -q "^ratified-kept $(sed -n '$s/.* plan=[^ ]* at=\([^ ]*\) .*/\1/p' "$T/ra") " "$T/mo" || fail 'the re-take does not say the ratification is kept, with its time'
cmp -s .vid/tw/to-place "$T/tp" && cmp -s .vid/plan/ratified "$T/ra" || fail 'the list or the ratification was written again'
grep -q '^mode-retake .* ratified-kept=' .vid/metrics-events || fail 'no event says the ratification was kept'
[ -f .vid/plan/PLAN-PAGE.md ] && [ -z "$(mn_lock)" ] || fail 'the page is not there, or the lock is held'

# --words given: ratified afresh, the row to place kept as it stood, its words not asked
retake --words 'yes, once more'
[ "$MN_RC" = 0 ] && [ "$(grep -c '^ratified ' .vid/plan/ratified)" = 2 ] && cmp -s .vid/tw/to-place "$T/tp" || fail "the re-take in the owner's words exited $MN_RC, or did not ratify afresh with the row kept"

# a second row out of the plan: it alone is listed and asked; the first keeps its time and words
out_ ROW-018; retake --plan "$T/plan.blk" --words 'yes, ROW-018 too'
[ "$MN_RC" = 1 ] && grep -q '1 rows are to place' "$T/mo" && grep -q '^ *place ROW-018' "$T/mo" && ! grep -q '^ *place ROW-002' "$T/mo" || fail "the re-take does not ask ROW-018 alone ($MN_RC)"
cmp -s .vid/tw/to-place "$T/tp" || fail 'the refused re-take changed the list'
retake --plan "$T/plan.blk" --to-place 'yes: ROW-018 waits too' --words 'yes, ROW-018 too'
[ "$MN_RC" = 0 ] || fail "the re-take with ROW-018's words exited $MN_RC"
grep -qxF "$(cat "$T/tp")" .vid/tw/to-place && awk -F'\t' '$1 == "ROW-018" && $2 == "no-step" && $4 == "yes: ROW-018 waits too" { f = 1 } END { exit !f }' .vid/tw/to-place && [ "$(grep -c . .vid/tw/to-place)" = 2 ] || { cat .vid/tw/to-place >&2; fail "ROW-002's time and words were not kept, or ROW-018's not recorded"; }
grep -qx 'to-place ROW-018 no-step' "$T/mo" && ! grep -q '^to-place ROW-002 ' "$T/mo" || fail 'a row accepted before is listed as new'

# a row as of another stage is asked again (its flag names its step, which the list does not hold)
cp .vid/tw/to-place "$T/tp2"; printf 'ROW-017\tother-stage\t2026-11-20T09:00:00Z\tyes, as of another stage\n' >> .vid/tw/to-place
sed -e '/^step S05 /d' -e '/^needs ROW-017 /d' -e 's/^\(step S04 .*rows: \)/\1ROW-017 /' -e 's/^needs ROW-009 /needs ROW-017 ROW-009 /' "$T/plan.blk" > "$T/b2"
retake --plan "$T/b2" --words 'yes'
[ "$MN_RC" = 1 ] && grep -q '^ *place ROW-017' "$T/mo" && ! grep -q '^ *place ROW-0\(02\|18\)' "$T/mo" || fail "a row as of another stage is not asked again, or another is ($MN_RC)"
cp "$T/tp2" .vid/tw/to-place; retake --plan "$T/plan.blk" --words 'yes, as before'
[ "$MN_RC" = 0 ] && cmp -s .vid/tw/to-place "$T/tp2" || fail "back to the plan before, the two rows are not kept ($MN_RC)"

# ROW-002's line changed at the applied commit: asked again, ROW-018 kept
sed '/^ROW-002 /s/up to ten saved searches/up to twelve saved searches/' INVENTORY.md > I.x && mv I.x INVENTORY.md; grep -q 'up to twelve' INVENTORY.md || fail 'the restatement did not land'
git commit -qam 'ROW-002 restated'; retake --applied "$(git rev-parse HEAD)" --words 'yes'
[ "$MN_RC" = 1 ] && grep -q '^ *place ROW-002' "$T/mo" && ! grep -q '^ *place ROW-018' "$T/mo" || fail "a row whose line changed is not asked again, alone ($MN_RC)"
echo 'mode-retake-kept: ok'

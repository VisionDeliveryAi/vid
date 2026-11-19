#!/bin/sh
# Purpose: selftest case — the switch's two kinds of open flag (GM-1 S2 step 8, its case mode-switch-flags). A plan with two rows in no
# step (ROW-002, ROW-011) and one row of stage 2 in a stage-1 step (ROW-017 in S04): with no --to-place words the switch is refused
# and the mode stays; a size flag (rule A's ceiling at 3) refuses it although the words are given; with the ceiling back and the
# words, it ratifies, .vid/tw/to-place holds the three rows in the owner's words, and planner.sh ratified passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-switch-flags: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
mn_project "$T/p"
sed -e '/^step S05 /d' -e 's/rows: ROW-002 ROW-009 ROW-011 ROW-018/rows: ROW-009 ROW-018 ROW-017/' -e 's/^needs ROW-002 ROW-009 ROW-011 ROW-018/needs ROW-009 ROW-018/' "$T/plan.blk" > "$T/b" && mv "$T/b" "$T/plan.blk"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
W='yes: ROW-002 and ROW-011 wait for a step, ROW-017 waits for its stage'
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "with rows to place and no --to-place words the switch exited $MN_RC, not 1"
grep -q 'to place' "$T/mo" || fail 'the refusal does not name the rows to place'
[ "$(mode_)" != manual ] || fail 'a refused switch changed the mode'
mkdir -p .vid; echo 'unverified-rows=3' > .vid/budget
mn_switch --to-place "$W" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "with a size flag the switch exited $MN_RC, not 1"
grep -q '^ *size ' "$T/mo" || fail 'the size flag is not printed'
[ "$(mode_)" != manual ] || fail 'a switch refused for a size flag changed the mode'
rm -f .vid/budget
mn_switch --to-place "$W" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "with the words and no other flag the switch exited $MN_RC"
for r in ROW-002:no-step ROW-011:no-step ROW-017:other-stage; do awk -F'\t' -v r="${r%%:*}" -v k="${r#*:}" -v w="$W" '$1 == r && $2 == k && $4 == w { f = 1 } END { exit !f }' .vid/tw/to-place || fail "${r%%:*} is not to place as ${r#*:} in the owner's words"; done
[ "$(grep -c . .vid/tw/to-place)" = 3 ] || fail "to-place holds $(grep -c . .vid/tw/to-place) rows, not 3"
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'planner.sh ratified refuses with the rows to place recorded'; }
[ "$(mode_)" = manual ] || fail 'the mode is not manual after the switch'
# a refused re-take (no --to-place words) keeps the rows to place as last ratified
cp .vid/tw/to-place "$T/tp"; mn_switch --words 'yes, again'
[ "$MN_RC" = 1 ] && cmp -s .vid/tw/to-place "$T/tp" || fail "a refused re-take did not keep the rows to place ($MN_RC)"
echo 'mode-switch-flags: ok'

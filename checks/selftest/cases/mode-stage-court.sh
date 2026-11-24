#!/bin/sh
# Purpose: selftest case — the switch to GitHub manual refuses an applied commit whose STAGES.md the stage court refuses (FB-3 C2).
# The toy's commit holds a row: line placing a hostility row: the switch with the owner's yes is refused, names the court's reason and
# how to go on, records no mode and no ratification and frees the lock; run again with the fixed commit as --applied, it records the mode.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-stage-court: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
mn_project "$T/p"
awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "row: HOS-001 -> STAGE-2" }' STAGES.md > S.x && mv S.x STAGES.md; git commit -qam 'a cut the court refuses'; AP=$(git rev-parse HEAD)
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "with a STAGES.md the court refuses the switch exited $MN_RC, not 1"
grep -qF 'stages STAGES.md — row: HOS-001 is no ROW or census row of the inventory' "$T/mo" || fail "the refusal does not name the court's reason"
grep -q 'the check flags the plan beyond the rows to place.*fix it in a commit and give it with --applied' "$T/mo" || fail 'the refusal does not say how to go on'
[ "$(mode_)" = none ] && [ ! -s .vid/plan/ratified ] || fail 'the refused switch recorded the mode or a ratification'
[ -z "$(mn_lock)" ] || fail 'the refused switch left the lock held'
grep -v '^row: HOS-001' STAGES.md > S.x && mv S.x STAGES.md; git commit -qam 'the cut, fixed'
mn_switch --applied "$(git rev-parse HEAD)" --words 'yes, ratify'
[ "$MN_RC" = 0 ] && grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail "the switch at the fixed commit exited $MN_RC"
[ "$(mode_)" = manual ] && [ -s .vid/plan/ratified ] || fail 'the mode or the ratification is not recorded'
echo 'mode-stage-court: ok'

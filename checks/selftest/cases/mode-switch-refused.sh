#!/bin/sh
# Purpose: selftest case — a refused switch (GM-1 S2, its case mode-switch-refused). A switch refused at the ratification (a size
# flag, rule A's ceiling at 3) leaves the mode as it was and frees the lock; the team then edits #1's body, and the next switch, the
# flag fixed, completes as a switch, and #1, already in the record, keeps its writing, not the edited body. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-switch-refused: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mkdir -p .vid; echo 'unverified-rows=3' > .vid/budget
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "with a size flag the switch exited $MN_RC, not 1"
[ "$(mode_)" = none ] || fail "a refused switch changed the mode to $(mode_)"
[ -z "$(mn_lock)" ] || fail 'the refused switch left the lock held'
cmp -s ".vid/tw/out/issue-$N1.md" "$T/t1" || fail "the refused switch did not keep what it took over"
printf '\nThe team adds: ROW-019 too.\n' >> "$FAKEGH/issues/$N1/body"
rm -f .vid/budget
mn_switch --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "the next switch, the flag fixed, exited $MN_RC"
grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail 'the next call was not a switch'
cmp -s ".vid/tw/out/issue-$N1.md" "$T/t1" || fail "#$N1's recorded writing was replaced by its edited body"
[ "$(grep -c "^published $N1 " .vid/tw/log)" = 1 ] || fail "#$N1 was taken over twice"
[ "$(mode_)" = manual ] || fail 'the mode is not manual'
echo 'mode-switch-refused: ok'

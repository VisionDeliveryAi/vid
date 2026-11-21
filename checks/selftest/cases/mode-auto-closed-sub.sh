#!/bin/sh
# Purpose: selftest case — a closed sub-issue does not refuse the switch to auto (the GM-4 proof's D4; GM M2: the switch "is
# refused while any open ticket has sub-issues, since DevAgent works whole tickets", read as sub-issues still open: one the team
# closed is done work, and vid-mode tells the team to close or merge them). On the GitHub manual toy (fixtures/manual.sh),
# switched to GitHub manual with one open ticket: with an open sub-issue under it, `mode.sh auto` is refused (`no-auto
# sub-issues`, naming the ticket); once the team closed that sub-issue, still linked, the switch goes on and completes. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-auto-closed-sub: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
auto_() { MN_RC=0; sh "$CHECKS/mode.sh" auto --register "$T/register" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] && [ "$(mode_)" = manual ] || fail "the switch to manual exited $MN_RC"
NS=$(gh_issue 'A unit of the skeleton'); gh_sub "$N1" "$NS"
auto_ --words 'yes, back to auto'
[ "$MN_RC" = 1 ] && grep -q "^no-auto sub-issues .*#$N1" "$T/mo" && [ "$(mode_)" = manual ] || fail 'an open sub-issue did not refuse the switch to auto'
# the team closes the sub-issue; it stays linked under the ticket
printf 'CLOSED\n' > "$FAKEGH/issues/$NS/state"; [ -f "$FAKEGH/issues/$NS/parent" ] || fail 'the closed sub-issue is not linked: the scene is wrong'
auto_ --words 'yes, back to auto'
! grep -q '^no-auto sub-issues' "$T/mo" || fail 'a closed sub-issue still refuses the switch to auto'
[ "$MN_RC" = 0 ] && [ "$(mode_)" = auto ] || fail "with the sub-issue closed the switch to auto exited $MN_RC"
echo 'mode-auto-closed-sub: ok'

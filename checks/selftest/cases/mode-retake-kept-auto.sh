#!/bin/sh
# Purpose: selftest case — a take-stock in GitHub auto asks only what is new (FB-3 C4). The toy switched to GitHub manual and back to
# auto: the switch is refused with no words. A take-stock in auto with nothing changed and no words records it, says `ratified-kept`,
# writes no ratification and no second `publish-approved`; `--words` ratifies afresh and records it; a plan changed since asks again.
# Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-retake-kept-auto: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
auto_() { MN_RC=0; sh "$CHECKS/mode.sh" auto --register "$T/register" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
pa() { grep -c '^publish-approved ' .vid/metrics-events || :; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "the switch to manual exited $MN_RC"
auto_; [ "$MN_RC" = 1 ] && [ "$(mode_)" = manual ] || fail "the switch to auto with no words exited $MN_RC"
auto_ --words 'yes, back to auto'; [ "$MN_RC" = 0 ] && [ "$(mode_)" = auto ] || fail "the switch to auto exited $MN_RC"
cp .vid/plan/ratified "$T/ra"; P0=$(pa)
auto_
[ "$MN_RC" = 0 ] && grep -qx 'mode: GitHub auto, re-taken' "$T/mo" && grep -q '^ratified-kept ' "$T/mo" || fail "the take-stock in auto with nothing changed exited $MN_RC, or asked"
cmp -s .vid/plan/ratified "$T/ra" && [ "$(pa)" = "$P0" ] || fail 'a kept ratification was written again, or approved to publish again'
grep -q '^mode-retake .* ratified-kept=' .vid/metrics-events || fail 'no event says the ratification was kept'
auto_ --words 'yes, once more'
[ "$MN_RC" = 0 ] && [ "$(pa)" = $((P0 + 1)) ] && [ "$(grep -c . .vid/plan/ratified)" = "$(($(grep -c . "$T/ra") + 1))" ] || fail "in the owner's words the take-stock did not ratify afresh ($MN_RC)"
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | sed 's/^step S05 | name: synonym-aware search/step S05 | name: synonym-aware search, its own step/' > "$T/b"
auto_ --plan "$T/b"
[ "$MN_RC" = 1 ] && grep -q 'the page is written' "$T/mo" || fail "a plan changed since is not asked ($MN_RC)"
echo 'mode-retake-kept-auto: ok'

#!/bin/sh
# Purpose: selftest case — a switch from GitHub auto needs the owner's words that DevAgent is stopped (GM-1 S2 step 3, its case
# mode-switch-from-auto): without --devagent it is refused and the mode stays auto; with them it completes, the words recorded and
# the mode event naming auto. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-switch-from-auto: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
mn_project "$T/p"
printf 'setup-answered key=github-mode value="auto" words="DevAgent works them" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 1 ] || fail "from GitHub auto with no --devagent the switch exited $MN_RC, not 1"
grep -q 'DevAgent is stopped' "$T/mo" || fail 'the refusal does not ask for the words that DevAgent is stopped'
[ "$(mode_)" = auto ] || fail 'a refused switch changed the mode'
mn_switch --applied "$AP" --devagent 'DevAgent is stopped, I stopped it this morning' --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "with --devagent the switch exited $MN_RC"
grep -q '^mode-devagent words="DevAgent is stopped, I stopped it this morning"' .vid/metrics-events || fail 'the DevAgent words are not recorded'
grep -q '^mode name=manual from=auto ' .vid/metrics-events || fail 'the mode event does not name auto'
[ "$(mode_)" = manual ] || fail 'the mode is not manual'
echo 'mode-switch-from-auto: ok'

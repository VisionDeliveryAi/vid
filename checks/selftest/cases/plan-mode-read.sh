#!/bin/sh
# Purpose: selftest case — plan.sh reads the mode and the applied version through lib.sh's, never a copy (GM-4 F10, plan.sh's part;
# its case plan-mode-read). plan.sh reads no github-mode setup line, no caller mark and no .vid/tw/applied itself, and loads lib.sh.
# On the ticket writer's toy (fixtures/tw-toy.sh) in GitHub manual, inside a planning sitting: under the switch to auto's mark
# (VID_CALLER=mode-auto, which only lib.sh's manual reads as auto) S05, of stage 2 while stage 0 is current, is refused by the
# stage rule, as in auto; with no mark it is admitted with no hold, as GitHub manual admits it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "plan-mode-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
P() { RC=0; sh "$CHECKS/plan.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
ev() { printf '%s at=%s\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
starts() { grep -c "^step-start step=$1 " .vid/metrics-events || true; }
# no copy of the mode read
grep -n 'setup-answered key=github-mode\|VID_CALLER\|tw/applied' "$CHECKS/plan.sh" | grep -v '^[0-9]*:[[:space:]]*#' > "$T/out" || :
[ ! -s "$T/out" ] || fail 'plan.sh reads the mode, the caller mark or the applied record itself (above), not through lib.sh'
grep -q 'lib\.sh' "$CHECKS/plan.sh" || fail 'plan.sh does not load lib.sh'
tw_toy "$T/toy"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # the stage rule reads them at the home
P start S01; [ "$RC" = 0 ] && [ "$(starts S01)" = 1 ] || fail 'the skeleton S01 was not started'
git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
ev 'stage name=plan state=start session=S2 records=29'
RC=0; VID_CALLER=mode-auto sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] || fail "under the switch to auto's mark S05 was not refused ($RC): plan.sh did not read the mode through lib.sh"
grep -q 'holds rows outside stages' "$T/out" || fail "under the switch to auto's mark S05 is not refused by the stage rule"
[ "$(starts S05)" = 0 ] || fail 'the refused S05 has a start recorded'
P start S05; [ "$RC" = 0 ] && [ "$(starts S05)" = 1 ] || fail "in GitHub manual S05 was not admitted with no hold ($RC)"
echo 'plan-mode-read: ok'

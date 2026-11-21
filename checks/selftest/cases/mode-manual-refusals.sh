#!/bin/sh
# Purpose: selftest case — GitHub manual's refusals (GM-1 S1). On the ticket writer's toy (fixtures/tw-toy.sh, the fake gh)
# with the owner's `github-mode manual` answer recorded: round.sh wait and next refuse at their start, in one line naming /vid next,
# and write nothing (the backstop of /vid run's refusal; GM-4 E5: step, asks and accept run there, the call's own work); queue.sh status opens with `mode: GitHub manual`; devagent-start.sh prints nothing, and its mode prints manual.
# Where the skills sit beside checks/ (the plugin, not a project): the run's start's refusal names /vid next (vid-connect's since
# GM-4 F2 and K10, which move the run skill's start there), and the fix, add
# and stage skills each read the mode. (GM-3 U2 opened the door in GitHub manual: land.sh's refusals and the hand path are gone.) With next.sh present (lane
# C's file): its mode prints `mode: GitHub manual` in manual, and in GitHub auto refuses, naming /vid run. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "mode-manual-refusals: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/tw-toy.sh"
run() { RC=0; "$@" > "$T/out" 2>&1 || RC=$?; }
tw_toy "$T/p"
printf 'setup-answered key=github-mode value="manual" words="by hand, from now on" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
cp .vid/metrics-events "$T/ev0"; cp .vid/RUN-STATE.md "$T/rs0"
# the run's backstop: round.sh refuses at its start, one line naming /vid next, nothing written
for c in wait next; do run sh "$CHECKS/round.sh" "$c"   # GM-4 E5: step, asks and accept run in GitHub manual
  [ "$RC" != 0 ] || fail "round.sh $c acted in GitHub manual"
  [ "$(grep -c . "$T/out")" = 1 ] || fail "round.sh $c's refusal is not one line"
  grep -q 'GitHub manual' "$T/out" && grep -qF '/vid next' "$T/out" || fail "round.sh $c's refusal does not name GitHub manual and /vid next"
done
[ ! -d .vid/round ] || fail 'round.sh made .vid/round in GitHub manual'
cmp -s .vid/metrics-events "$T/ev0" || fail 'round.sh wrote an event in GitHub manual'
cmp -s .vid/RUN-STATE.md "$T/rs0" || fail 'round.sh changed RUN-STATE in GitHub manual'
# the status opens with the mode's line
VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'queue.sh status failed'
[ "$(sed -n 1p "$T/out")" = 'mode: GitHub manual' ] || fail "the status does not open with the mode: $(sed -n 1p "$T/out")"
# DevAgent's start prints nothing; its mode is manual
run sh "$CHECKS/devagent-start.sh"; [ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "devagent-start.sh printed in GitHub manual ($RC)"
run sh "$CHECKS/devagent-start.sh" mode; [ "$(cat "$T/out")" = manual ] || fail "devagent-start.sh mode printed $(cat "$T/out")"
# the skills' lines, where the skills are beside checks/
S=$CHECKS/../skills
one() { tr '\n' ' ' < "$1" | tr -s ' '; }
if [ -f "$S/vid-run/SKILL.md" ]; then
  one "$S/vid-connect/SKILL.md" | grep -qF 'this project is in GitHub manual: call /vid next' || fail "the run's start has no refusal naming /vid next"
  for k in vid-fix vid-add vid-stage; do [ -f "$S/$k/SKILL.md" ] || fail "no $k skill beside the run skill"
    one "$S/$k/SKILL.md" | grep -qF 'devagent-start.sh" mode' || fail "the $k skill does not read the mode"; done
fi
# /vid next's first step reads the one mode command (GM-4 F15): devagent-start.sh mode; next.sh has no mode of its own
if [ -f "$CHECKS/next.sh" ]; then
  run sh "$CHECKS/next.sh" mode; [ "$RC" = 2 ] || fail "next.sh mode is still a subcommand ($RC)"
  run sh "$CHECKS/devagent-start.sh" mode; [ "$RC" = 0 ] && grep -qx 'manual' "$T/out" || fail "devagent-start.sh mode in GitHub manual ($RC)"
  printf 'setup-answered key=github-mode value="auto" words="DevAgent again" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup
  run sh "$CHECKS/devagent-start.sh" mode; [ "$RC" = 0 ] && grep -qx 'auto' "$T/out" || fail "devagent-start.sh mode in GitHub auto ($RC)"
fi
exit 0

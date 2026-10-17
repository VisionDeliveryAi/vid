#!/bin/sh
# Purpose: selftest case — the event and run-id helpers called before a
# project's checks/ exists, or against an older one, keep 0.9.6.2's local
# result (v0.9.7.0.1 spec 3.1, R4, R10; §6 A-7). The plugin's event.sh
# and run.sh (the plan.sh beside them answering home-of) write the stage
# event, with its run id, and .vid/run in the caller's checkout: from a
# repository with no checks/, from one whose checks/plan.sh predates
# home-of, and from a directory outside any repository. A copy of event.sh
# and run.sh with no plan.sh beside them does the same. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "home-plugin-helper: $*" >&2; exit 1; }
local_stage() { # <dir> <event.sh>: the stage event and the run id land in <dir>
  ( cd "$1" && sh "$2" 'stage name=init state=start session=S1' ) 2> "$T/err" || fail "event.sh failed in $1"
  [ ! -s "$T/err" ] || fail "event.sh printed in $1: $(cat "$T/err")"
  _p=$(cd "$1" && pwd -P)
  grep -qE '^stage name=init state=start session=S1 run=[0-9TZ]+-[0-9a-f]{6} at=' "$1/.vid/metrics-events" || fail "no local stage event with its run id in $1"
  [ "$(sed -n 's/^path=//p' "$1/.vid/run")" = "$_p" ] || fail "the run id is not local to $1"
  [ "$(cd "$1" && sh "${2%event.sh}run.sh" id)" = "$(sed -n 's/^id=//p' "$1/.vid/run")" ] || fail "run.sh id does not read the local run in $1"
}
# a repository with no checks/
mkdir -p "$T/nochecks"; ( cd "$T/nochecks" && git init -q )
local_stage "$T/nochecks" "$CHECKS/event.sh"
# a repository whose checks/plan.sh predates home-of
mkdir -p "$T/older/checks"; ( cd "$T/older" && git init -q )
printf '#!/bin/sh\necho "ViD plan: usage — sh checks/plan.sh gate | home --brief <f>" >&2; exit 2\n' > "$T/older/checks/plan.sh"
local_stage "$T/older" "$CHECKS/event.sh"
# outside any repository
mkdir -p "$T/plain"
local_stage "$T/plain" "$CHECKS/event.sh"
# the helpers with no plan.sh beside them
mkdir -p "$T/alone/checks"; ( cd "$T/alone" && git init -q ); cp "$CHECKS/event.sh" "$CHECKS/run.sh" "$T/alone/checks/"
local_stage "$T/alone" "$T/alone/checks/event.sh"
exit 0

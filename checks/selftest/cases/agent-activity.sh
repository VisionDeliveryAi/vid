#!/bin/sh
# Purpose: selftest case — agent transcript entries are the run's activity
# (v0.9.7.0.6 spec 3.2, R4, round 1 finding 3; §6 A-4). The interval 60 s.
# Convicts unless: with no agents, a run whose clocks are months old gets
# its quiet notice (the expected-unchanged control); with one agent whose
# newest entry is 17 min old — `working` under the 20-minute rule, past the
# run's quiet interval — the run's quiet notice is not sent, while another
# agent, quiet, is told; and once no episode is working, the run's quiet
# age counts from the newest agent entry. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-activity
. "$CHECKS/selftest/fixtures/observer-lib.sh"
. "$CHECKS/selftest/fixtures/agent-lib.sh"
Q='gone quiet'; A='an agent has had no new step'
reset; rs active; tick
[ "$(nnote "$Q")" -eq 1 ] || fail 'the control: with no agents the quiet run was not told'
reset; rs active
start w 3600; entry w 1020
start q 3600; entry q 1500; task q 'Build slice 4'
tick
[ "$(nnote "$Q")" -eq 0 ] || fail "the run was called quiet while an agent's episode works"
[ "$(nnote "$A")" -eq 1 ] && grep -q 'Build slice 4' "$T/notify.log" || fail 'the quiet agent beside the working one was not told'
# no episode working: the quiet notice tells the minutes since the newest agent entry
reset; rs active; start x 3600; stop x 2000; entry x 1500; tick
grep -q "$Q for 25 min" "$T/notify.log" || fail 'the newest agent entry is not the run'"'"'s activity'
exit 0

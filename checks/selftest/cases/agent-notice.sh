#!/bin/sh
# Purpose: selftest case — a quiet agent reaches the owner (v0.9.7.0.6 spec
# 3.2, R3; §6 A-3). Toy events and transcripts; a recent session heartbeat
# line keeps the run itself from reading quiet. Convicts unless: a quiet agent
# with `run: active` is told once, naming its task, and the next tick sends
# nothing more; a new entry clears the notice and a later quiet stretch is
# told again; with `run: stopped owner asked to pause` nothing is sent and a
# standing agent notice is cleared; and with `run: waiting` (the idle
# branch, nothing declared) the quiet agent is told. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-notice
. "$CHECKS/selftest/fixtures/observer-lib.sh"
. "$CHECKS/selftest/fixtures/agent-lib.sh"
A='an agent has had no new step'
fresh() { hb "$(ago 0)" 'working'; }
# once, then nothing more
reset; rs active; fresh
start q1 3600; entry q1 1500; task q1 'Grade slice 3'
tick
[ "$(nnote "$A")" -eq 1 ] || fail 'a quiet agent was not told once'
grep -q "$A for 25 min: Grade slice 3. It may be stuck. Open the build's session and ask what it is doing." "$T/notify.log" || fail 'the notice text is not as specified'
fresh; tick; [ "$(nnote "$A")" -eq 1 ] || fail 'the agent notice repeated'
# a new entry clears it; a later quiet stretch is told again
entry q1 60; fresh; tick
[ "$(nnote "$A")" -eq 1 ] || fail 'a working agent was told'
grep -q '^notified\.agentq\.' .vid/observer.state && fail 'a new entry did not clear the agent notice'
VID_OBSERVE_NOW=$(( $(date +%s) + 1500 )); export VID_OBSERVE_NOW; tick; unset VID_OBSERVE_NOW
[ "$(nnote "$A")" -eq 2 ] || fail 'a later quiet stretch was not told again'
# the owner's pause: nothing sent, a standing notice cleared
reset; rs active; fresh; start q2 3600; entry q2 1500; tick
[ "$(nnote "$A")" -eq 1 ] || fail 'no notice to stand before the pause'
rs 'stopped owner asked to pause'; tick
[ "$(nnote "$A")" -eq 1 ] || fail 'a quiet agent was told while the owner paused the run'
grep -q '^notified\.agentq\.' .vid/observer.state && fail 'the pause did not clear the standing agent notice'
# waiting, through the idle branch
reset; rs waiting "- Q1 · asked $(ago 900) · gates all remaining work · Is the export weekly?"; start q3 3600; entry q3 1500; tick
grep -q 'observe: idle' .vid/HEARTBEAT.md || fail 'the waiting run did not take the idle branch'
[ "$(nnote "$A")" -eq 1 ] || fail 'a quiet agent was not told while the run waits'
exit 0

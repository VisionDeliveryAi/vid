#!/bin/sh
# Purpose: selftest case — the owner is told the run waits on an answer
# (v0.9.5 spec 3.5, R5; §7 case 2). `run: waiting` with a `Q1` line and a
# `run state=waiting` event. Convicts unless one tick gives one "stopped
# until you answer" notice and no NUDGE and the next tick nothing; an
# answer and a new `waiting` between two ticks (a new episode, the same
# day) give a further notice; and, for an episode that began just under a
# day ago, a tick past the day's mark gives one reminder. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-waiting
. "$CHECKS/selftest/fixtures/observer-lib.sh"
W='ViD: the build has stopped until you answer: '
Q1="- Q1 · asked $(ago 200) · gates all remaining work · Should the export include archived rows?"
reset; rs waiting "$Q1"; ev 'run state=waiting' "$(ago 100)"
tick
[ "$(nnote "$W")" -eq 1 ] || fail 'no waiting notice'
grep -q "${W}Q1 Should the export include archived rows?" "$T/notify.log" || fail 'the waiting notice does not name the question'
[ ! -f .vid/NUDGE ] || fail 'a waiting run was nudged'
tick; [ "$(nnote "$W")" -eq 1 ] || fail 'the waiting notice repeated within the day'
ev 'run state=active' "$(ago 2)"; ev 'run state=waiting' "$(ago 1)"
tick; [ "$(nnote "$W")" -eq 2 ] || fail 'an answer and a new waiting between two ticks gave no new notice'
reset; rs waiting "$Q1"; ev 'run state=waiting' "$(ago $((86400 - 12)))"
tick; [ "$(nnote "$W")" -eq 1 ] || fail 'no waiting notice for the older episode'
sleep 13
tick; [ "$(nnote "$W")" -eq 2 ] || fail 'no reminder once a day had passed'
tick; [ "$(nnote "$W")" -eq 2 ] || fail 'the reminder repeated'
[ ! -f .vid/NUDGE ] || fail 'a waiting run was nudged'
[ "$(nnote 'gone quiet')" -eq 0 ] || fail 'a waiting run with a question got the quiet notice'
exit 0

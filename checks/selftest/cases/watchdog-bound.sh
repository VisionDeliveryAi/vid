#!/bin/sh
# Purpose: selftest case — the bounded predicate probe, done-requires-check
# and re-declare (v0.9.3 spec 3.9, R13; §7 case 9). Convicts unless: a
# probe sleeping past VID_PROBE_BOUND is stopped and reported `probe
# timeout` with exit 3, and the next operation is still checked; `declare`
# refuses a probe naming no operation identifier; an operation whose
# process is gone, probed by a predicate on its pid, exits 3; a probe
# returning zero exits 2; `done` on an overdue operation before `check` is
# refused and accepted after it; a re-declare of an expired, unchecked
# operation is refused and leaves `start=` unchanged — enlarging the
# envelope past the elapsed time is refused the same way — while a
# re-declare inside the envelope keeps `start=`; `report` prints
# `EXCEEDED (unprobed)`; under VID_OBSERVER=1 the heartbeat lines are
# prefixed `observe:` and no `stall` event is written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
W() { sh "$CHECKS/watchdog.sh" "$@"; }   # quoted: a project path may hold a space
fail() { echo "watchdog-bound: $*" >&2; exit 1; }
age() { sed "s/^start=.*/start=$(( $(date +%s) - $2 ))/" ".vid/watchdog/$1" > x && mv x ".vid/watchdog/$1"; }   # make an operation $2 seconds old
# a probe naming no operation identifier, and a missing identifier → refused
if W declare close-run 60 'echo every container is listed' 4242 >/dev/null 2>&1; then fail 'a probe naming no identifier was accepted'; fi
if W declare close-run 60 'kill -0 4242' >/dev/null 2>&1; then fail 'a declaration with no identifier was accepted'; fi
# the bound: a sleeping probe beside a second operation
W declare slow 10 'sleep 30 # slow-op' slow-op >/dev/null
W declare gone 10 "kill -0 99999999" 99999999 >/dev/null
W declare answers 10 'echo answers-op alive' answers-op >/dev/null
age slow 100; age gone 100; age answers 100
T0=$(date +%s); ST=0; OUT=$(VID_PROBE_BOUND=2 W check slow 2>&1) || ST=$?; T1=$(date +%s)
[ "$ST" -eq 3 ] || fail "a probe past the bound exited $ST, not 3"
printf '%s\n' "$OUT" | grep -q 'probe timeout' || fail 'a probe past the bound was not reported as probe timeout'
[ $((T1 - T0)) -le 10 ] || fail "the bound did not stop the probe ($((T1 - T0)) s)"
ST=0; W check gone >/dev/null 2>&1 || ST=$?; [ "$ST" -eq 3 ] || fail "a predicate on a gone pid exited $ST, not 3"
ST=0; W check answers >/dev/null 2>&1 || ST=$?; [ "$ST" -eq 2 ] || fail "a probe returning zero exited $ST, not 2"
grep -q '^stall op=slow ' .vid/metrics-events || fail 'the session-run check wrote no stall event'
# done requires check
W declare late 10 'kill -0 12345 # late-op' late-op >/dev/null; age late 100
if W done late >/dev/null 2>&1; then fail 'done on an overdue unchecked operation was accepted'; fi
W check late >/dev/null 2>&1 || true
W done late >/dev/null 2>&1 || fail 'done after a check was refused'
[ ! -f .vid/watchdog/late ] || fail 'done did not close the operation'
# re-declare: refused on an expired unchecked operation, start unchanged; enlarging past the elapsed time likewise
W declare expired 10 'kill -0 777 # op 777' 777 >/dev/null; age expired 100
S0=$(sed -n 's/^start=//p' .vid/watchdog/expired)
if W declare expired 20 >/dev/null 2>&1; then fail 're-declare of an expired unchecked operation was accepted'; fi
if W declare expired 100000 >/dev/null 2>&1; then fail 'enlarging an expired envelope past the elapsed time was accepted'; fi
[ "$(sed -n 's/^start=//p' .vid/watchdog/expired)" = "$S0" ] || fail 're-declare moved start='
W report | grep -q '^EXCEEDED (unprobed) expired ' || fail 'report does not say EXCEEDED (unprobed)'
W declare fresh 100 'kill -0 888 # op 888' 888 >/dev/null; age fresh 10; S1=$(sed -n 's/^start=//p' .vid/watchdog/fresh)
W declare fresh 500 >/dev/null || fail 're-declare inside the envelope was refused'
[ "$(sed -n 's/^start=//p' .vid/watchdog/fresh)" = "$S1" ] || fail 're-declare inside the envelope moved start='
grep -q '^envelope=500$' .vid/watchdog/fresh || fail 're-declare did not change the envelope'
# the observer's own checks: prefixed lines, no stall event
: > .vid/metrics-events
ST=0; VID_OBSERVER=1 W check gone >/dev/null 2>&1 || ST=$?; [ "$ST" -eq 3 ] || fail 'the observer check did not exit 3'
[ ! -s .vid/metrics-events ] || fail 'the observer wrote a stall event'
tail -n 1 .vid/HEARTBEAT.md | grep -q '| observe: watchdog gone EXCEEDED' || fail 'the observer heartbeat line is not prefixed observe:'
exit 0

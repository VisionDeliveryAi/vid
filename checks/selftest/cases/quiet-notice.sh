#!/bin/sh
# Purpose: selftest case — a stop without a recorded reason is told at once,
# from outside (v0.9.5 spec 3.3, R3; §7 case 7). A toy run whose clocks are
# months old; the interval 60 s (2 s where a second quiet stretch is
# timed). Convicts unless: `run: active` with nothing declared and no
# activity for over an interval gives ONE quiet notice at the first tick,
# with the resume suffix and no NUDGE, and the next tick nothing; newer
# activity clears it and a new quiet stretch gives a second; nothing is
# sent for a live ledger-lock holder, a declared operation inside its
# envelope under 2 h from its start, a live gated run folder (v0.9.6), `waiting` with a Q1, `stopped
# <reason>`, a proven `complete`, a standing death, a recent
# .vid/hook-times line or a recent event line by its `at=`; one is sent for
# `waiting` with no Q<n>, a bare `stopped`, only `brief-check` events and
# `observe:` lines recent, a lock whose holder pid is gone, a live holder
# that started over 2 h ago, and a declared operation still inside its
# envelope 2 h after its start; while the quiet notice stands, a failing
# declared operation's own notice is held; a tick in the main checkout
# tells a quiet run in a linked worktree, naming that directory; and
# (v0.9.6) the observer's own `progress … by=observer` lines neither clear
# nor re-arm a quiet notice, while a session's progress event clears it.
# Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'rm -rf "$T"; [ -n "$P" ] && kill "$P" 2>/dev/null; true' EXIT
cd "$T"; CASE=quiet-notice
. "$CHECKS/selftest/fixtures/observer-lib.sh"
Q='gone quiet'
oldhb() { printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: the session last spoke months ago\n' > .vid/HEARTBEAT.md; }
age() { sed "s/^start=.*/start=$(( $(date +%s) - $2 ))/" ".vid/watchdog/$1" > x && mv x ".vid/watchdog/$1"; }
runf() { rm -rf .vid/runs; mkdir -p .vid/runs/r1; printf 'pid=%s\nstart=%s\n' "$1" "$(( $(date +%s) - $2 ))" > .vid/runs/r1/holder; }
lock() { mkdir -p .vid/ledger.lock; printf '%s\n%s\n%s\n' "$1" 'started' "$(( $(date +%s) - $2 ))" > .vid/ledger.lock/holder; }
sleep 300 & P=$!
none() { tick; [ "$(nnote "$Q")" -eq 0 ] || fail "a quiet notice was sent for: $1"; }
one() { tick; [ "$(nnote "$Q")" -eq 1 ] || fail "no quiet notice for: $1"; }
# A. one notice at the first quiet tick, no nudge; the next tick nothing
reset; rs active
tick
[ "$(nnote)" -eq 1 ] && [ "$(nnote "$Q")" -eq 1 ] || fail 'not one quiet notice at the first quiet tick'
[ ! -f .vid/NUDGE ] || fail 'the quiet run was nudged first'
grep -q 'observe.sh resume' "$T/notify.log" && grep -q 'claude --resume S1' "$T/notify.log" || fail 'the quiet text lacks the resume steps'
tick; [ "$(nnote)" -eq 1 ] || fail 'the quiet notice repeated'
# B. newer activity clears it; a new quiet stretch sends a second
sleep 1; hb "$(ago 0)" 'working again'
( VID_OBSERVE_INTERVAL=2; export VID_OBSERVE_INTERVAL; tick ); [ "$(nnote "$Q")" -eq 1 ] || fail 'fresh activity was told as quiet'
sleep 3
( VID_OBSERVE_INTERVAL=2; export VID_OBSERVE_INTERVAL; tick ); [ "$(nnote "$Q")" -eq 2 ] || fail 'a new quiet stretch after activity gave no second notice'
# C. nothing is sent while the run has a reason, or something it started runs
reset; rs active; lock "$P" 60; none 'a live ledger-lock holder'
reset; rs active; runf "$P" 60; none 'a live gated run folder (v0.9.6)'; rm -rf .vid/runs
reset; rs active
sh checks/watchdog.sh declare build-3 3600 "kill -0 $P # build-3" "$P" >/dev/null; age build-3 600; oldhb
none 'a declared operation inside its envelope'
reset; rs waiting "- Q1 · asked $(ago 900) · gates all remaining work · Is the export weekly?"; none 'waiting with a Q1'
reset; rs 'stopped disk full'; none 'stopped with a reason'
reset; rs complete; ev 'completion unmet=0 strict-gaps=0' "$(ago 900)"; none 'a proven complete'
reset; rs active; ev 'died reason=overloaded session=S1' "$(ago 300)"; none 'a standing death'
reset; rs active; printf 'hook result=pass seconds=3 at=%s\n' "$(ago 5)" > .vid/hook-times; none 'a recent hook-times line'
reset; rs active; ev 'tokens slice=3 phase=build n=10' "$(ago 5)"; none 'a recent event line'
# D. one is sent where nothing holds it back
reset; rs waiting; one 'waiting with no question'
reset; rs stopped; one 'a bare stopped'
reset; rs active; ev 'brief-check path=.vid/briefs/3/g.md result=ok' "$(ago 5)"; printf -- '- %s | observe: idle\n' "$(ago 5)" >> .vid/HEARTBEAT.md
one 'only brief-check events and observe: lines recent'
reset; rs active; lock 99999999 60; one 'a lock whose holder pid is gone'
reset; rs active; runf 99999999 60; one 'a run folder whose holder pid is gone (v0.9.6)'; rm -rf .vid/runs
reset; rs active; lock "$P" 7300; one 'a live lock holder that started over 2 h ago'
reset; rs active
sh checks/watchdog.sh declare long-3 10800 "kill -0 $P # long-3" "$P" >/dev/null; age long-3 7300; oldhb
one 'a declared operation inside its envelope, 2 h after its start'
# E. while the quiet notice stands, a failing operation's own notice is held
reset; rs active
sh checks/watchdog.sh declare stuck 10 'kill -0 99999999 # stuck' 99999999 >/dev/null; age stuck 500; oldhb
tick; tick; tick
[ "$(nnote "$Q")" -eq 1 ] || fail 'no quiet notice beside the failing operation'
[ "$(nnote 'failed its probe')" -eq 0 ] || fail 'the failing operation was told while the quiet notice stands'
grep -q 'its notice is held while the quiet notice stands' .vid/HEARTBEAT.md || fail 'the held notice was not recorded'
# G. v0.9.6 (3.15; §7 case 35): the observer's own progress lines are not activity — repeated
# `progress … by=observer` events neither clear nor re-arm a standing quiet notice; a session's does
reset; rs active; tick
[ "$(nnote "$Q")" -eq 1 ] || fail 'no quiet notice to stand before the progress lines'
for i in 1 2 3; do ev 'progress trigger=hourly by=observer rows-passing=0 rows-left=4 estimate=none' "$(ago 0)"; tick; done
[ "$(nnote "$Q")" -eq 1 ] || fail 'observer progress lines re-armed the quiet notice'
[ -n "$(sed -n 's/^quiet\.standing //p' .vid/observer.state)" ] || fail 'observer progress lines cleared the quiet notice'
sleep 1; ev 'progress trigger=session by=session rows-passing=0 rows-left=4 estimate=none' "$(ago 0)"; tick
[ -z "$(sed -n 's/^quiet\.standing //p' .vid/observer.state)" ] || fail 'a session-written progress event was not activity'
# F. a tick here also covers a linked worktree's run (3.5), naming its directory
reset; rm -rf .vid/watchdog .vid/RUN-STATE.md
git worktree add -q "$T/wt two" -b wt
mkdir -p "$T/wt two/.vid"; printf 'run: active\nsession: S2\nquestions: - · next Q1\n' > "$T/wt two/.vid/RUN-STATE.md"
printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: old\n' > "$T/wt two/.vid/HEARTBEAT.md"
tick; [ "$(nnote "$Q")" -eq 1 ] || fail "the linked worktree's quiet run was not told"
grep -q "in a terminal in $(cd "$T/wt two" && pwd -P): \`claude --resume S2\`" "$T/notify.log" || fail 'the notice does not name the worktree and its session'
exit 0

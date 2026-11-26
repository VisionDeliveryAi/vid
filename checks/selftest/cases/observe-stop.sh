#!/bin/sh
# Purpose: selftest case — the watcher's stop, and an unknown word refused (FIX-BATCH-T1 §5.1, B-4). The observer fixture,
# the default interval (900 s: the loop asleep, so only the TERM ends it in time). Convicts unless: `stop` after `start` prints `watcher stopped (pid <p>)`, that loop is gone
# within 10 s and the pid file's token reads `-`; a second `stop` prints `watcher: not running here` and exits 0; `start`
# again starts a new loop; a process whose command line holds `observe.sh loop` with another token, named in the pid file,
# is never signalled by `stop`, nor one whose token holds the pid file's (`<token>x`); and `observe.sh stpo` exits 2 with the usage, writing nothing to .vid/observer.state. In ticket mode (both GitHub
# modes), where the loop keeps ticking after run: complete, stop ends it.
# Every process is stopped at the end. Env: CHECKS.
set -eu
T=$(mktemp -d)
cleanup() { p=$(sed -n 1p "$T/repo/.vid/observer.pid" 2>/dev/null || true); case "$p" in ''|*[!0-9]*) ;; *) kill -TERM -"$p" 2>/dev/null || true; kill "$p" 2>/dev/null || true ;; esac
  [ -n "${DECOY:-}" ] && kill "$DECOY" 2>/dev/null; rm -rf "$T"; }
trap cleanup EXIT
mkdir -p "$T/repo"; cd "$T/repo"; CASE=observe-stop
. "$CHECKS/selftest/fixtures/observer-lib.sh"
VID_OBSERVE_INTERVAL=900; export VID_OBSERVE_INTERVAL   # the default: the loop asleep, only a TERM ends it in 10 s
D=$(pwd -P)
gone() { _i=0; while kill -0 "$1" 2>/dev/null && [ "$_i" -lt "${2:-10}" ]; do sleep 1; _i=$((_i + 1)); done; ! kill -0 "$1" 2>/dev/null; }
reset; rs active
sh checks/observe.sh start > "$T/out" 2>&1 || fail "start failed: $(cat "$T/out")"
P=$(sed -n 1p .vid/observer.pid)
sh checks/observe.sh stop > "$T/out" 2>&1 || fail "stop failed: $(cat "$T/out")"
grep -qx "watcher stopped (pid $P)" "$T/out" || fail "stop did not say watcher stopped (pid $P): $(cat "$T/out")"
gone "$P" 10 || fail "the loop (pid $P) outlived stop by 10 s"
[ "$(sed -n 3p .vid/observer.pid)" = - ] || fail "the pid file's token is not - after stop: $(sed -n 3p .vid/observer.pid)"
sh checks/observe.sh stop > "$T/out" 2>&1 || fail "a second stop failed: $(cat "$T/out")"
grep -qx 'watcher: not running here' "$T/out" || fail "a second stop did not say not running: $(cat "$T/out")"
sh checks/observe.sh start > "$T/out" 2>&1 || fail "start after stop failed: $(cat "$T/out")"
P2=$(sed -n 1p .vid/observer.pid); [ "$P2" != "$P" ] && kill -0 "$P2" 2>/dev/null || fail 'start after stop did not start a new loop'
sh checks/observe.sh stop > /dev/null 2>&1; gone "$P2" 10 || fail 'the second loop outlived stop'
# a decoy: its command line holds `observe.sh loop <the pid file's token>x` (a longer token holding it); the pid file names it
perl -e 'exec { "sleep" } "sh checks/observe.sh loop decoyx", 60' & DECOY=$!
sleep 1
printf '%s\n%s\n%s\n' "$DECOY" "$D" decoy > .vid/observer.pid
sh checks/observe.sh stop > "$T/out" 2>&1 || fail "stop beside the decoy failed: $(cat "$T/out")"
kill -0 "$DECOY" 2>/dev/null || fail 'stop signalled a process that is not this home'"'"'s loop'
grep -qx 'watcher: not running here' "$T/out" || fail "stop beside the decoy did not say not running: $(cat "$T/out")"
kill "$DECOY" 2>/dev/null; wait "$DECOY" 2>/dev/null || true; DECOY=""
# ticket mode (both GitHub modes): the loop keeps ticking after run: complete, so stop is what ends it
reset; rs complete; sed '1i\
mode: tickets
' .vid/RUN-STATE.md > "$T/rs" && cp "$T/rs" .vid/RUN-STATE.md
VID_OBSERVE_INTERVAL=2 sh checks/observe.sh start > "$T/out" 2>&1 || fail "ticket mode: start failed: $(cat "$T/out")"
P3=$(sed -n 1p .vid/observer.pid); sleep 5
kill -0 "$P3" 2>/dev/null || fail 'ticket mode: the loop did not keep ticking after run: complete'
sh checks/observe.sh stop > "$T/out" 2>&1 || fail "ticket mode: stop failed: $(cat "$T/out")"
grep -qx "watcher stopped (pid $P3)" "$T/out" && gone "$P3" 10 || fail "ticket mode: stop did not end the loop: $(cat "$T/out")"
# an unknown word
cp .vid/observer.state "$T/st0" 2>/dev/null || : > "$T/st0"
RC=0; sh checks/observe.sh stpo > "$T/out" 2>&1 || RC=$?
[ "$RC" = 2 ] || fail "an unknown word exited $RC, not 2: $(cat "$T/out")"
grep -q 'usage' "$T/out" || fail "an unknown word did not print the usage: $(cat "$T/out")"
cmp -s "$T/st0" .vid/observer.state || fail 'an unknown word wrote to .vid/observer.state'
exit 0

#!/bin/sh
# Purpose: selftest case — develop's watcher loop (v0.9.7.0.9 spec 3.8, R11).
# The observer fixture, the loop's interval 2 s. Convicts unless: `sh
# checks/observe.sh start` prints `watcher started (pid <p>)`, the pid file
# holding that pid, this home and a token, and .vid/observer.state the
# loop's acknowledgement `loop <token> <home>`; `alive` then exits 0; a
# second start prints `watcher running (pid <p>)` and starts nothing; two
# starts at once leave one loop; a copied .vid/ in another directory never
# passes for that run's watcher — a start there starts its own; a killed
# loop is started again; the log is cut to its last 200 lines at a start;
# the loop ends by itself when RUN-STATE reads `run: complete`, and when the
# pid file holds another token; a first tick slower than 30 s (rehearsal
# R-1: a large project's progress update; here a memory reader of 35 s)
# still gives `watcher started` within 30 s and `alive` 0, and a start
# while it runs finds the loop and starts none. The tick: a live holder of
# .vid/observer.lock makes a tick skip, a dead holder's lock is reclaimed;
# with a 900 s interval a tick at once after a tick records nothing, and
# `tick --now` forces one; a fresh tick in a state copied from another home
# holds nothing back, and a tick drops a legacy `notifier` line. Every loop
# is stopped at the end. Env: CHECKS.
set -eu
T=$(mktemp -d)
cleanup() { for f in "$T/repo/.vid/observer.pid" "$T/copy/.vid/observer.pid"; do p=$(sed -n 1p "$f" 2>/dev/null || true); case "$p" in ''|*[!0-9]*) ;; *) kill -TERM -"$p" 2>/dev/null || true; kill "$p" 2>/dev/null || true ;; esac; done; rm -rf "$T"; }
trap cleanup EXIT
mkdir -p "$T/repo"; cd "$T/repo"; CASE=watcher-loop
. "$CHECKS/selftest/fixtures/observer-lib.sh"
VID_OBSERVE_INTERVAL=2; export VID_OBSERVE_INTERVAL
D=$(pwd -P)
loops() { ps -A -o args= 2>/dev/null | grep -c "^sh .*/${T##*/}/$1/checks/observe.sh loop " || true; }   # <repo|copy>
pidof_loop() { sed -n 1p .vid/observer.pid; }
gone() { _i=0; while kill -0 "$1" 2>/dev/null && [ "$_i" -lt "${2:-20}" ]; do sleep 1; _i=$((_i + 1)); done; ! kill -0 "$1" 2>/dev/null; }
reset; rs active
# started, acknowledged, alive
sh checks/observe.sh start > "$T/out" 2>&1 || fail "start failed: $(cat "$T/out")"
P=$(pidof_loop); TK=$(sed -n 3p .vid/observer.pid)
grep -qx "watcher started (pid $P)" "$T/out" || fail "start did not print watcher started: $(cat "$T/out")"
[ "$(sed -n 2p .vid/observer.pid)" = "$D" ] && [ -n "$TK" ] || fail 'the pid file does not hold the home and a token'
grep -qxF "loop $TK $D" .vid/observer.state || fail 'no acknowledgement loop <token> <home> in observer.state'
[ "$(loops repo)" -eq 1 ] || fail "not one loop running: $(loops repo)"
sh checks/observe.sh alive > "$T/out" 2>&1 || fail "alive failed after start: $(cat "$T/out")"
# idempotent
sh checks/observe.sh start > "$T/out" 2>&1 || fail 'a second start failed'
grep -qx "watcher running (pid $P)" "$T/out" || fail "a second start did not say running: $(cat "$T/out")"
[ "$(loops repo)" -eq 1 ] || fail 'a second start started another loop'
# killed: started again; two starts at once leave one loop
kill "$P"; gone "$P" || fail 'the loop did not die'
( sh checks/observe.sh start > "$T/s1" 2>&1 ) & A=$!
( sh checks/observe.sh start > "$T/s2" 2>&1 ) & B=$!
wait "$A" || fail "a concurrent start failed: $(cat "$T/s1")"; wait "$B" || fail "a concurrent start failed: $(cat "$T/s2")"
[ "$(loops repo)" -eq 1 ] || fail "two starts at once left $(loops repo) loops"
cat "$T/s1" "$T/s2" | grep -q '^watcher started (pid ' || fail 'neither concurrent start started the loop'
P2=$(pidof_loop); [ "$P2" != "$P" ] || fail 'the killed loop was not replaced'
# a copied .vid/ elsewhere never passes for this run's watcher
cp -R "$D" "$T/copy"; ( cd "$T/copy" && sh checks/observe.sh start > "$T/out" 2>&1 ) || fail "start in the copy failed: $(cat "$T/out")"
grep -q '^watcher started (pid ' "$T/out" || fail "a copied .vid/ passed for a running watcher: $(cat "$T/out")"
[ "$(loops copy)" -eq 1 ] && [ "$(loops repo)" -eq 1 ] || fail 'the copy did not get its own loop beside this one'
CP=$(sed -n 1p "$T/copy/.vid/observer.pid"); kill "$CP"; gone "$CP" || fail 'the copy'"'"'s loop did not die'
# the log is cut to its last 200 lines at a start
kill "$P2"; gone "$P2" || fail 'the loop did not die'
i=1; while [ "$i" -le 300 ]; do echo "old line $i"; i=$((i + 1)); done > .vid/observer.log
sh checks/observe.sh start > "$T/out" 2>&1 || fail 'start after the log filled failed'
[ "$(sed -n 1p .vid/observer.log)" = 'old line 101' ] || fail "the log was not cut to its last 200 lines: $(sed -n 1p .vid/observer.log)"
# the loop ends by itself: another token in the pid file; then run: complete
P3=$(pidof_loop)
printf '%s\n%s\n%s\n' "$P3" "$D" other-token > .vid/observer.pid
gone "$P3" 20 || fail 'the loop outlived a pid file holding another token'
sh checks/observe.sh start > "$T/out" 2>&1 || fail 'start after the token change failed'
P4=$(pidof_loop); rs complete
gone "$P4" 20 || fail 'the loop outlived run: complete'
grep -q "^observe loop .* ended at " .vid/observer.log || fail 'the loop did not log its end'
# (R-1) a first tick slower than the 30 s wait: acknowledged as it begins; a second start meanwhile starts nothing
rs active; rm -f .vid/observer.state; mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: a slow memory reader\nsleep 35\necho free-mb 4000\n' > checks/extractors/memory.sh
t0=$(date +%s); sh checks/observe.sh start > "$T/out" 2>&1 || fail "start failed beside a slow first tick: $(cat "$T/out")"
P5=$(pidof_loop); grep -qx "watcher started (pid $P5)" "$T/out" && [ $(( $(date +%s) - t0 )) -lt 30 ] || fail "start was not acknowledged within 30 s of a slow first tick: $(cat "$T/out")"
sh checks/observe.sh start > "$T/out" 2>&1 || fail "a start during the slow tick failed: $(cat "$T/out")"
grep -qx "watcher running (pid $P5)" "$T/out" && [ "$(loops repo)" -eq 1 ] || fail "a start during the slow tick started another loop: $(cat "$T/out")"
sh checks/observe.sh alive > "$T/out" 2>&1 || fail "alive failed during the slow first tick: $(cat "$T/out")"
kill -TERM -"$P5" 2>/dev/null || true; kill "$P5" 2>/dev/null || true; gone "$P5" || fail 'the slow loop did not die'
rm -f checks/extractors/memory.sh; sleep 1
# the tick's lock: a live holder skips, a dead one is reclaimed; the interval holds unless --now
rs active; sleep 30 & H=$!
mkdir .vid/observer.lock; echo "$H" > .vid/observer.lock/pid
N0=$(grep -c '| observe: ' .vid/HEARTBEAT.md)
sh checks/observe.sh tick --now > "$T/out" 2>&1
grep -q "skipped — a tick is running here (pid $H)" "$T/out" && [ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -eq "$N0" ] || fail 'a tick ran beside a live tick'
kill "$H"; wait "$H" 2>/dev/null || true
sh checks/observe.sh tick --now > "$T/out" 2>&1
[ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -gt "$N0" ] && [ ! -d .vid/observer.lock ] || fail "a dead holder's lock was not reclaimed: $(cat "$T/out")"
N1=$(grep -c '| observe: ' .vid/HEARTBEAT.md); T1=$(sed -n 's/^tick //p' .vid/observer.state)
VID_OBSERVE_INTERVAL=900 sh checks/observe.sh > "$T/out" 2>&1
grep -q '^observe: skipped — the last tick here was' "$T/out" && [ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -eq "$N1" ] && [ "$(sed -n 's/^tick //p' .vid/observer.state)" = "$T1" ] || fail 'a tick within the interval recorded something'
VID_OBSERVE_INTERVAL=900 sh checks/observe.sh tick --now > "$T/out" 2>&1
[ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -gt "$N1" ] || fail 'tick --now did not force a tick'
# (R-1) a fresh tick in a state copied from another home holds nothing back here; a legacy notifier line goes
printf 'tick %s /another/home\nnotifier yes\n' "$(date +%s)" > .vid/observer.state
N2=$(grep -c '| observe: ' .vid/HEARTBEAT.md)
VID_OBSERVE_INTERVAL=900 sh checks/observe.sh > "$T/out" 2>&1
[ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -gt "$N2" ] && [ "$(sed -n 's/^tick [0-9]* //p' .vid/observer.state)" = "$D" ] || fail "a copied state's tick held back this home's tick: $(cat "$T/out")"
grep -q '^notifier' .vid/observer.state && fail 'a legacy notifier line survived a tick'
exit 0

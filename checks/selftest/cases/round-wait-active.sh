#!/bin/sh
# Purpose: selftest case — a healthy wait is activity (v0.26.10.28.6, R6), checks/round.sh wait and checks/observe.sh on the toy and the fake gh.
# Red first at 5b39465: the real `round.sh wait` runs twice back to back on short limits, and the watcher ticks during the second, every other
# activity older than its interval (its clock, VID_OBSERVE_NOW, 30 s on): no "gone quiet" notice. Nothing is planted: the base watcher counts
# metrics events and a live declared operation, and only the wait, which writes nothing at the base, can change the answer. Kept: a wait whose
# process was killed mid-wait leaves its record, and the notice still comes once the wait's limit and its margin have passed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); WP=''; trap '[ -z "$WP" ] || kill "$WP" 2>/dev/null || true; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-wait-active: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md
sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || fail 'the first step failed'   # the round's seen record, so a wait waits
quiet() { awk '/observe: notice — ViD: the build has gone quiet/ { n++ } END { print n + 0 }' .vid/HEARTBEAT.md 2>/dev/null || echo 0; }
tick() { VID_OBSERVE_INTERVAL=10 VID_OBSERVE_NOW=$1 sh "$CHECKS/observe.sh" > "$T/tick.out" 2>&1 || true; }
q0=$(quiet)
# two waits back to back; the watcher ticks during the second, its clock 30 s on, so every other activity is older than its 10 s interval
VID_WAIT_MAX=20 VID_WAIT_TICK=5 sh "$CHECKS/round.sh" wait > "$T/out" 2>&1 || fail 'the first wait failed'
VID_WAIT_MAX=20 VID_WAIT_TICK=5 sh "$CHECKS/round.sh" wait > "$T/w2" 2>&1 & WP=$!
sleep 4; tick $(($(date +%s) + 30))
[ "$(quiet)" = "$q0" ] || { cat "$T/tick.out" > "$T/out"; fail 'a healthy wait read as gone quiet'; }
wait "$WP" || fail "the second wait failed: $(cat "$T/w2")"; WP=''
# kept: a wait killed mid-wait leaves its record; once its limit and its margin have passed, the notice comes
VID_WAIT_MAX=20 VID_WAIT_TICK=5 sh "$CHECKS/round.sh" wait > "$T/w3" 2>&1 & WP=$!; sleep 4; kill -9 "$WP" 2>/dev/null || true; wait "$WP" 2>/dev/null || true; WP=''
tick $(($(date +%s) + 20 + 120 + 30))
[ "$(quiet)" -gt "$q0" ] || { cat "$T/tick.out" > "$T/out"; fail 'a wait killed mid-wait kept the run from reading quiet past its limit and margin'; }
exit 0

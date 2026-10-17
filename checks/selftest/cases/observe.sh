#!/bin/sh
# Purpose: selftest case — the observer outside the session (v0.9.3 spec
# 3.9, R13; §7 case 8). A toy repository with RUN-STATE, a heartbeat and the
# watchdog (v0.9.7.0.9: a notice is an `observe: notice —` heartbeat line,
# nothing is sent); the interval is 60 s and "dead"
# clocks are dated months back. Convicts unless: a declared operation
# inside its envelope with clocks two intervals old → quiet; nothing
# declared, `run: active`, clocks dead → (v0.9.5 3.3) one notice at the
# first tick with the resume suffix and no nudge, and no second notice at
# the next two; a claim with evidence clears a nudge; three ticks with an overdue
# operation whose probe fails, beside a stub committing every tick and a
# closed slice → the nudge at the second tick, the notification at the
# third, the healthy overdue operation beside it never escalated, no
# `stall` event written; the observer's own lines never refresh the
# session's clock; `run: complete` with nothing declared → one `idle` line
# over three ticks; a heartbeat "complete" after the last slice with a
# `completion unmet=3` event → FLAG false-complete. v0.9.7.0.9 (3.8, R14):
# the activity line reads `run activity <s>s ago (<source>)` — events,
# commit hooks, heartbeat or git, whichever is newest — and `run activity:
# none recorded` in a repository with no activity at all. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks .vid
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
export VID_OBSERVE_INTERVAL=60 VID_PROBE_BOUND=5
printf '.vid/\n' > .gitignore
OLD='2026-01-01T00:00:00+0000'
GIT_COMMITTER_DATE=$OLD GIT_AUTHOR_DATE=$OLD git -c user.email=vid@selftest -c user.name=vid add -A
GIT_COMMITTER_DATE=$OLD GIT_AUTHOR_DATE=$OLD git -c user.email=vid@selftest -c user.name=vid commit -qm root
fresh_commit() { printf '%s\n' "$1" >> work.txt; git add work.txt; git -c user.email=vid@selftest -c user.name=vid commit -qm "$1"; }
rs() { printf 'run: %s\nslice: %s    since: 2026-01-01T00:00:00Z    commit: x\nmodules: app/feed\nclaims: -\nreceipt: none    briefs: -\nheld: -\n\nThe plan, as prose.\n' "$1" "$2" > .vid/RUN-STATE.md; }
reset() { rm -rf .vid/watchdog .vid/NUDGE .vid/observer.state; printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: the session last spoke months ago\n' > .vid/HEARTBEAT.md; : > .vid/metrics-events; }
tick() { sh checks/observe.sh > "$T/tick.out" 2>&1; }
notes() { sed -n 's/^- [^|]* | observe: notice — //p' .vid/HEARTBEAT.md; }
nnote() { notes | grep -c . || true; }
age() { sed "s/^start=.*/start=$(( $(date +%s) - $2 ))/" ".vid/watchdog/$1" > x && mv x ".vid/watchdog/$1"; }
fail() { echo "observe: $*" >&2; cat "$T/tick.out" >&2; exit 1; }
# A. a declared operation inside its envelope, clocks two intervals old → quiet
reset; rs active '3 open'
sh checks/watchdog.sh declare close-run 3600 'kill -0 424242 # close-run' 424242 >/dev/null
printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: the session last spoke months ago\n' > .vid/HEARTBEAT.md   # the declaration is old news: every clock is dead
tick; tick
[ ! -f .vid/NUDGE ] && [ "$(nnote)" -eq 0 ] || fail 'an operation inside its envelope escalated'
grep -q '| observe: run activity [0-9]*s ago (' .vid/HEARTBEAT.md || fail 'the observer wrote no activity line'
# B. nothing declared, run active, clocks dead → one notice at once, no nudge (v0.9.5 3.3)
reset; rs active '3 open'
tick; [ ! -f .vid/NUDGE ] && [ "$(nnote)" -eq 1 ] || fail 'the first dead tick did not notify at once, or nudged'
notes | grep -q 'observe.sh resume' || fail 'the notice does not name resume'
tick; [ "$(nnote)" -eq 1 ] || fail 'the notification repeated'
tick; [ "$(nnote)" -eq 1 ] && [ ! -f .vid/NUDGE ] || fail 'a later dead tick notified again or nudged'
# C. a claim with evidence answers a nudge (an operation's, the one kind left)
printf 'declared operation stuck failed its probe on two successive ticks\n' > .vid/NUDGE
sh checks/watchdog.sh claim run --evidence 'commit 1a2b3c: slice 3 red count 12 → 9' 'working' >/dev/null
[ ! -f .vid/NUDGE ] || fail 'the claim did not clear the nudge'
tick; [ ! -f .vid/NUDGE ] || fail 'a tick after the answered nudge nudged again'
# D. a failing operation beside fresh commits and a closed slice: nudge at 2, notify at 3; the healthy one never
reset; rs active '4 closed'
sh checks/watchdog.sh declare stuck 10 'kill -0 99999999 # stuck worker' 99999999 >/dev/null
sh checks/watchdog.sh declare healthy 10 'echo healthy-op alive' healthy-op >/dev/null
age stuck 500; age healthy 500
printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: the session last spoke months ago\n' > .vid/HEARTBEAT.md   # the declarations are old news; only the observer writes from here
fresh_commit t1; tick; [ ! -f .vid/NUDGE ] && [ "$(nnote)" -eq 0 ] || fail 'the first failing tick escalated'
fresh_commit t2; tick; [ -f .vid/NUDGE ] || fail 'the second failing tick did not nudge'
grep -q 'stuck' .vid/NUDGE || fail 'the nudge does not name the operation'
[ "$(nnote)" -eq 0 ] || fail 'the second failing tick notified'
fresh_commit t3; tick; [ "$(nnote)" -eq 1 ] || fail 'the third failing tick did not notify despite fresh commits'
notes | grep -q 'healthy' && fail 'the healthy operation was escalated'
grep -q 'healthy' .vid/NUDGE && fail 'the healthy operation was nudged'
grep -q '^stall ' .vid/metrics-events && fail 'the observer wrote stall events'
# E. the observer's own lines never refresh the run's clock: after three observer ticks the newest activity is the commit
grep -q '^observe: run activity [0-9]*s ago (git) · last commit [0-9]*s ago · run: active' "$T/tick.out" || fail "the observer's own lines became the run's activity: $(grep 'run activity' "$T/tick.out")"
# F. run complete, nothing declared → one idle line over three ticks
reset; rs complete '5 closed'
tick; tick; tick
[ "$(grep -c '| observe: idle' .vid/HEARTBEAT.md)" -eq 1 ] || fail 'not exactly one idle line'
[ "$(grep -c '| observe: ' .vid/HEARTBEAT.md)" -eq 1 ] || fail 'the idle observer wrote more than its idle line'
# G. a false completion claim after the last slice
reset; rs active '6 closed'
printf -- '- %s | note: the run is complete: 596 rows paid\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/HEARTBEAT.md
printf 'completion unmet=3 strict-gaps=451\n' >> .vid/metrics-events
tick; grep -q '| observe: FLAG false-complete' .vid/HEARTBEAT.md || fail 'a false completion claim was not flagged'
printf 'completion unmet=0 strict-gaps=0\n' >> .vid/metrics-events
rm -f .vid/HEARTBEAT.md; printf '# Heartbeat\n- %s | note: the run is complete\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > .vid/HEARTBEAT.md
tick; grep -q 'FLAG false-complete' .vid/HEARTBEAT.md && fail 'a true completion claim was flagged'
# H. (R14) the activity line names its source; with none at all it says so
src() { sed -n 's/^observe: run activity [0-9]*s ago (\([^)]*\)) · .*/\1/p' "$T/tick.out"; }
reset; rs active '7 open'
printf -- '- %s | note: building\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/HEARTBEAT.md
tick; [ "$(src)" = heartbeat ] || fail "a fresh session heartbeat line is not the source: $(grep 'run activity' "$T/tick.out")"
sleep 1; printf 'brief-write role=builder at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
tick; [ "$(src)" = events ] || fail "a fresh event is not the source: $(grep 'run activity' "$T/tick.out")"
sleep 1; printf 'pre-commit 3 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/hook-times
tick; [ "$(src)" = 'commit hooks' ] || fail "a fresh hook time is not the source: $(grep 'run activity' "$T/tick.out")"
mkdir "$T/empty"; cd "$T/empty"; git init -q; mkdir -p checks .vid; cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf 'run: active\nslice: 1 open\n' > .vid/RUN-STATE.md; printf '# Heartbeat\n' > .vid/HEARTBEAT.md
tick; grep -q '^observe: run activity: none recorded · last commit: none · run: active' "$T/tick.out" || fail "no activity at all is not 'none recorded': $(grep 'run activity' "$T/tick.out")"
exit 0

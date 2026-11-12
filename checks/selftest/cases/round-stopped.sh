#!/bin/sh
# Purpose: selftest case — ViD reads the dev side's stop (v0.26.10.28.6, R3), checks/round.sh and github.sh's round-read on the toy and the fake gh.
# Red first at 5b39465: a stopped report, vid-results/stopped-<k>, with nothing else changed and no work open, ends a wait with `new`; the step
# raises `flag devagent-stopped <id>: <why>` once, the stop's words its own, and a second step says nothing; a later report of any kind, the read
# otherwise unchanged, ends a wait too, and the step clears the flag. The stopped report passes the fetch's proof. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "round-stopped: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* failed ($RC)"; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd step; VID_WAIT_TICK=1 VID_WAIT_MAX=2 rd wait; grep -qx timeout "$T/out" || fail 'a wait with nothing new did not time out'
# the dev side stops with nothing open: its stopped report alone
rr_put stopped-1 results.txt "$(printf 'by: DM\nstopped: the time limit: 3600s\nat: 2026-11-12T03:00:00Z')"; send stopped-1
VID_WAIT_TICK=1 VID_WAIT_MAX=5 rd wait; grep -qx new "$T/out" || fail "a stopped report did not end the wait: $(cat "$T/out")"
rd step; grep -qx 'flag devagent-stopped stopped-1: the time limit: 3600s' "$T/out" || fail 'the stop was not flagged with its words'
grep -q 'round: FLAG devagent-stopped stopped-1: the time limit: 3600s' .vid/HEARTBEAT.md || fail 'the flag has no heartbeat line'
rd step; ! grep -q '^flag devagent-stopped' "$T/out" || fail 'the flag was said twice'
VID_WAIT_TICK=1 VID_WAIT_MAX=2 rd wait; grep -qx timeout "$T/out" || fail 'a standing flag ended a wait with nothing new'
# a later report of any kind, the read otherwise unchanged: the wait ends, the flag clears
sleep 2; rr_put req-9-p1c1-1 results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 1' "$(git -C "$T/code.git" rev-parse main)")"; rr_put req-9-p1c1-1 cases-alpha.xml "$(rr_cases ROW-001=pass)"; send req-9-p1c1-1
VID_WAIT_TICK=1 VID_WAIT_MAX=5 rd wait; grep -qx new "$T/out" || fail "a later report did not end the wait: $(cat "$T/out")"
rd step; grep -q 'flag-cleared word=devagent-stopped on=stopped-1' .vid/metrics-events && ! grep -q '^devagent-stopped ' .vid/decide/flags || fail 'a later report did not clear the flag'
exit 0

#!/bin/sh
# Purpose: selftest case — a reused pid does not hold the lock (v0.9.8 R16). A lock naming a live pid with another start
# time — the pid reused by a new process — is stale: reclaimed, and the request runs. The control: a lock naming a live
# pid with its own start time holds — the request stays queued — until it is removed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; kill "$HP" 2>/dev/null; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/admit-lock.sh"
fail() { echo "admit-lock-pid-reused: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
al_repo "$T/repo"
sleep 300 & HP=$!
ln -s "$HP Thu Jan  1 00:00:00 1970" "$AL"
al_req || fail 'the request was refused'; al_end
grep -q '^status=0 ran-to-end=yes' "$T/res" || fail 'a reused pid held the lock'
ln -s "$HP $(ps -o lstart= -p "$HP" | sed 's/^ *//; s/ *$//')" "$AL"
al_req || fail 'the second request was refused'
sleep 6; [ "$(al_state)" = queued ] || fail "a live holder's lock did not hold: the request is $(al_state)"
[ -L "$AL" ] || fail 'the live holder'"'"'s lock was taken'
rm -f "$AL"; al_end
grep -q '^status=0 ran-to-end=yes' "$T/res" || fail 'the request did not run once the lock was free'
exit 0

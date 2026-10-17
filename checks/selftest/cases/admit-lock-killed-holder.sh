#!/bin/sh
# Purpose: selftest case — a lock whose holder died is reclaimed (v0.9.8 R16). The admission lock left by a holder
# that is gone — a symbolic link naming a dead pid — is reclaimed, and a request runs to its end; a request takes and
# leaves the lock as a symbolic link naming its own pid and start time, never a directory, so no window leaves a lock
# without its holder. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/admit-lock.sh"
fail() { echo "admit-lock-killed-holder: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
al_repo "$T/repo"
sh -c 'exit 0' & DEAD=$!; wait "$DEAD"
ln -s "$DEAD Thu Jan  1 00:00:00 1970" "$AL"
al_req || fail 'the request was refused'; al_end
grep -q '^status=0 ran-to-end=yes' "$T/res" || fail 'the run behind a dead holder'"'"'s lock did not end'
[ -e "$AL" ] || [ -L "$AL" ] && fail 'the lock was left behind'
grep -q 'ln -s "$_mine" "$_al"' "$CHECKS/test.sh" || fail 'the lock is not made in one step as a symbolic link'
grep -q 'mkdir "$_al"' "$CHECKS/test.sh" && fail 'the lock is still a directory made before its holder is written'
exit 0

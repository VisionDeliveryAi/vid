#!/bin/sh
# Purpose: selftest case — an older ViD's directory lock (v0.9.8 R16). A directory lock with no pid in it, older than
# 30 s, is stale: reclaimed, and the request runs. The control: the same directory, fresh, holds — the request stays
# queued — and once it ages past 30 s it is reclaimed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/admit-lock.sh"
fail() { echo "admit-lock-legacy-dir: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
al_repo "$T/repo"
old() { touch -t "$(date -v-2M '+%Y%m%d%H%M.%S' 2>/dev/null || date -d '2 minutes ago' '+%Y%m%d%H%M.%S')" "$AL"; }
mkdir "$AL"; old
al_req || fail 'the request was refused'; al_end
grep -q '^status=0 ran-to-end=yes' "$T/res" || fail 'an old pidless directory lock held'
mkdir "$AL"
al_req || fail 'the second request was refused'
sleep 6; [ "$(al_state)" = queued ] || fail "a fresh directory lock did not hold: the request is $(al_state)"
[ -d "$AL" ] && [ ! -L "$AL" ] && [ -z "$(ls -A "$AL")" ] || fail 'the request left a link inside the directory lock (ln -s onto a directory)'
old; al_end
grep -q '^status=0 ran-to-end=yes' "$T/res" || fail 'the directory lock, aged, was not reclaimed'
exit 0

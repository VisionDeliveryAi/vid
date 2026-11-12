#!/bin/sh
# Purpose: selftest case — the one-session lock on GitHub (v0.26.10.25.1 R7), on the toy and a bare repository. Two takers at once: one wins. A lock under
# VID_LOCK_COLD seconds old is refused, saying when; a colder one is taken, a line of the record; the loser's renew and free are refused; freed, it can be taken. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "state-lock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
cp -R "$T/toy" "$T/b"
( x=0; sh "$GS" lock-take a > "$T/a" 2>&1 || x=$?; echo $x > "$T/ra" ) & P=$!; ( cd "$T/b"; x=0; sh "$GS" lock-take b > "$T/b.out" 2>&1 || x=$?; echo $x > "$T/rb" ) & Q=$!; wait "$P"; wait "$Q"
[ "$(cat "$T/ra")$(cat "$T/rb")" = 01 ] || [ "$(cat "$T/ra")$(cat "$T/rb")" = 10 ] || fail "two takers: $(cat "$T/ra") and $(cat "$T/rb")"
if [ "$(cat "$T/ra")" = 0 ]; then W=$T/toy; O=$T/b; else W=$T/b; O=$T/toy; fi
cd "$O"; RC=0; sh "$GS" lock-take c > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'it may be taken in' "$T/out" || fail 'a warm lock was taken'
sh "$GS" lock-renew > "$T/out" 2>&1 && fail 'a loser renewed the lock'; grep -q 'lock is lost' "$T/out" || fail 'the loser was not told'
cd "$W"; sh "$GS" lock-renew > "$T/out" 2>&1 || fail 'the holder could not renew'
cd "$O"; VID_LOCK_COLD=0 sh "$GS" lock-take d > "$T/out" 2>&1 || fail 'a cold lock was refused'; grep -q 'lock-taken session=d from=' .vid/metrics-events || fail 'the taking is no line of the record'
cd "$W"; sh "$GS" lock-renew > "$T/out" 2>&1 && fail 'a session whose lock was taken renewed it'; sh "$GS" lock-free > "$T/out" 2>&1 && fail "another's lock was freed"
CLAUDE_CODE_SESSION_ID=a; export CLAUDE_CODE_SESSION_ID; cd "$O"; sh "$GS" lock-renew > "$T/out" 2>&1 && fail 'a session renewed a lock another took in its folder'; unset CLAUDE_CODE_SESSION_ID
cd "$O"; sh "$GS" lock-free > "$T/out" 2>&1 || fail 'the holder could not free it'; cd "$W"; sh "$GS" lock-take e > "$T/out" 2>&1 || fail 'a freed lock was refused'
exit 0

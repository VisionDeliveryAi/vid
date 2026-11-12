#!/bin/sh
# Purpose: selftest case — a truncated read pays what it returned but its last line (v0.26.10.10 R1, F-71). Needs
# the plugin's hooks/ beside checks/. The reread fixture, a debt listing one file whose Read count is 1,227 (the
# size of vid-develop's skill): a truncated read that returned one line records nothing; a truncated read of 1–882
# records `cover <path> 1 881 1227` and leaves the debt (Bash still refused); a read of 881–1227 then removes the
# debt file and Bash is allowed. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || { echo 'needs hooks/stop-failure.sh'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reread-oversize
. "$CHECKS/selftest/fixtures/reread-lib.sh"
BIG="$PR/skills/vid-big/SKILL.md"; mkdir -p "${BIG%/*}"; awk 'BEGIN { for (i = 1; i <= 1227; i++) print "line " i }' > "$BIG"
OW="$H/.vid/reread-owed.S1"; printf 'since 2026-10-24T10:00:00Z\nfile %s\n' "$BIG" > "$OW"
rd "$BIG" 1 1 S1 "$H" '' truncated
grep -q '^cover ' "$OW" && fail 'a truncated one-line read recorded a cover'
rd "$BIG" 1 882 S1 "$H" '' truncated
grep -qxF "cover $BIG 1 881 1227" "$OW" || fail "the truncated read of 1–882 did not record 1 881 1227: $(cat "$OW")"
pre Bash; denied 'Bash with 882–1227 unread'
rd "$BIG" 881 347
[ ! -e "$OW" ] || fail 'the debt file stands after 881–1227 was read'
pre Bash; allowed 'Bash after the debt was paid'
exit 0

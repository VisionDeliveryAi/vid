#!/bin/sh
# Purpose: selftest case — the re-read refusal names what is left and how to read it (v0.26.10.10 R2, F-71). Needs
# the plugin's hooks/ beside checks/. The reread fixture, a debt listing a file of 1,227 lines covered 1–400 and
# 801–1227 and a second file with no cover: a Bash call is refused, and the reason holds `lines 401–800 of 1227`,
# `<second path>, all of it` and `offset`, and neither `delete` nor the debt file's path; a listed path that does not
# exist reads `cannot be read`. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || { echo 'needs hooks/stop-failure.sh'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reread-deny-ranges
. "$CHECKS/selftest/fixtures/reread-lib.sh"
BIG="$PR/skills/vid-big/SKILL.md"; mkdir -p "${BIG%/*}"; awk 'BEGIN { for (i = 1; i <= 1227; i++) print "line " i }' > "$BIG"
OW="$H/.vid/reread-owed.S1"; printf 'since 2026-10-24T10:00:00Z\nfile %s\nfile %s\n' "$BIG" "$TM" > "$OW"
rd "$BIG" 1 400; rd "$BIG" 801 427
pre Bash; denied 'Bash with lines 401–800 and a second file unread'
grep -qF "$BIG lines 401–800 of 1227" "$T/pre.out" || fail 'the reason does not name lines 401–800 of 1227'
grep -qF "$TM, all of it" "$T/pre.out" || fail 'the reason does not say all of the second file'
grep -qF 'offset' "$T/pre.out" || fail 'the reason does not say how to read in windows'
grep -qF 'delete' "$T/pre.out" && fail 'the reason tells of deleting'
grep -qF "$OW" "$T/pre.out" && fail 'the reason names the debt file'
GONE="$PR/skills/vid-gone/SKILL.md"; printf 'file %s\n' "$GONE" >> "$OW"
pre Bash; denied 'Bash with a listed path that does not exist'
grep -qF "$GONE cannot be read" "$T/pre.out" || fail 'the reason does not say the missing path cannot be read'
exit 0

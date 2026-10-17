#!/bin/sh
# Purpose: selftest case — the re-read refusal names when the debt was armed (v0.9.8.1 R31). Needs the plugin's hooks/
# beside checks/. The reread fixture: after a compaction's page, a Bash call is refused, and the refusal names the
# debt's `since` as recorded in .vid/reread-owed.<session>. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reread-deny-since
. "$CHECKS/selftest/fixtures/reread-lib.sh"
page compact S1
S=$(sed -n 's/^since //p' "$H/.vid/reread-owed.S1"); [ -n "$S" ] || fail 'the debt has no since'
pre Bash S1
grep -q '"permissionDecision":"deny"' "$T/pre.out" || fail 'the call was not refused'
grep -qF "re-read owed since $S" "$T/pre.out" || fail "the refusal does not name the debt's since: $(cat "$T/pre.out")"
exit 0

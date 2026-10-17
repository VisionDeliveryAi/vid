#!/bin/sh
# Purpose: selftest case — a resume owes no re-read (v0.9.8.1 R31, F-20). Needs the plugin's hooks/ beside checks/.
# The reread fixture in a live run: `source=resume` prints the page — the skills listed as a recommendation, nothing
# refused — writes no debt and writes .vid/reentry-shown.<session> with its UTC time; a second resume within 30
# minutes prints nothing; one after 30 minutes (the marker 31 minutes old) prints the page again; another session's
# resume is unaffected; and `source=compact` still writes the debt. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reentry-resume-no-debt
. "$CHECKS/selftest/fixtures/reread-lib.sh"
page resume S1
grep -q '^ViD re-entry' "$T/page.out" || fail 'a resume printed no page'
grep -q 'no re-read is enforced' "$T/page.out" || fail 'the resume page does not say no re-read is enforced'
grep -q 'every tool but Read is refused' "$T/page.out" && fail 'the resume page says tools are refused'
[ ! -f "$H/.vid/reread-owed.S1" ] || fail 'a resume wrote a re-read debt'
grep -qE '^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "$H/.vid/reentry-shown.S1" || fail 'no shown marker with its UTC time'
page resume S1; [ ! -s "$T/page.out" ] || fail 'a second resume within 30 minutes printed the page'
page resume S2; grep -q '^ViD re-entry' "$T/page.out" || fail "another session's resume was held back"
touch -t "$(date -v-31M +%Y%m%d%H%M 2>/dev/null || date -d '31 minutes ago' +%Y%m%d%H%M)" "$H/.vid/reentry-shown.S1"
page resume S1; grep -q '^ViD re-entry' "$T/page.out" || fail 'a resume after 30 minutes printed no page'
page compact S1; [ -f "$H/.vid/reread-owed.S1" ] || fail 'a compaction wrote no debt'
grep -q 'every tool but Read is refused' "$T/page.out" || fail 'the compaction page does not say the re-read is enforced'
exit 0

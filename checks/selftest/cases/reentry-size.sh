#!/bin/sh
# Purpose: selftest case — the re-entry page stays under 10,000 characters
# (v0.9.7.0.6 spec 3.4, round 1 finding 1; §6 C-2). Needs the plugin's
# hooks/ beside checks/. A run with 500 uncommitted paths and one claims
# line of 20,000 characters. Convicts unless the page is under 10,000
# characters, ends with the "(+N more: sh checks/observe.sh resume)"
# pointer, keeps every re-read path and the watcher's line whole, and cuts
# no line past 300 characters. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reentry-size
. "$CHECKS/selftest/fixtures/reread-lib.sh"
C=$(awk 'BEGIN { for (i = 1; i <= 2000; i++) printf "ROW-%05d ", i }')
printf 'run: active\nsession: S1\nslice: 3 open\nclaims: %s\n' "$C" > "$H/.vid/RUN-STATE.md"
i=0; while [ $i -lt 500 ]; do : > "$H/file-$i.txt"; i=$((i + 1)); done
page compact
N=$(wc -m < "$T/page.out" | tr -d ' ')
[ "$N" -lt 10000 ] || fail "the page is $N characters"
tail -n 1 "$T/page.out" | grep -qE '^\(\+[0-9]+ more: sh checks/observe.sh resume\)$' || fail 'no +N more pointer'
for f in "$DV" "$TM" "$VV" "$VB"; do grep -qxF -- "- $f" "$T/page.out" || fail "the page lost $f"; done
grep -qxF 'watcher: start it: sh checks/observe.sh start' "$T/page.out" || fail 'the page lost the watcher line'
grep '^resume' "$T/page.out" | awk 'length($0) > 300 { exit 1 }' || fail 'a resume line is longer than 300 characters'
grep -q '^resume: claims: ROW-00001' "$T/page.out" || fail 'the claims line was dropped rather than cut'
exit 0

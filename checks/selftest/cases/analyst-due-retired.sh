#!/bin/sh
# Purpose: selftest case — a retired analyst reason is never listed
# (v0.9.7.0.10 spec 3.3, R7, Codex 7). A recorded `analyst-due …
# reason=startup harness=<hash>` with no analyst-done stays in the events,
# untouched, and `sh checks/test.sh analyst-due` lists only the retained
# reasons — cap, setup, slow — so it is never dispatched. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "analyst-due-retired: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/repo/checks" "$T/repo/.vid"; cp "$CHECKS/test.sh" "$T/repo/checks/"; cd "$T/repo"
E=.vid/metrics-events
printf 'analyst-due request=T1 reason=startup harness=1234567890 at=2026-10-06T01:00:00Z\n' >> $E
printf 'analyst-due request=T2 reason=cap at=2026-10-06T01:01:00Z\n' >> $E
printf 'analyst-due request=T3 reason=slow rows=ROW-001 at=2026-10-06T01:02:00Z\n' >> $E
cp $E "$T/before"
sh checks/test.sh analyst-due > "$T/out" 2>&1 || fail 'the listing failed'
printf 'analyst due: request=T2 reason=cap\nanalyst due: request=T3 reason=slow\n' > "$T/want"
cmp -s "$T/out" "$T/want" || fail "the listing is not the two retained dues: $(cat "$T/out")"
cmp -s $E "$T/before" || fail 'the events were changed'
exit 0

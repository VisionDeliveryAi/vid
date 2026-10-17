#!/bin/sh
# Purpose: selftest case — durations from the events (v0.9.5 spec 3.15, R13;
# §7 case 19). A planted events file and hook-times file over two slices
# and two questions. Convicts unless `metrics.sh timing` prints each slice's
# wall, its rows paid and its product rounds by INVENTORY kind (a row
# BREACHED then KEPT in the slice still counts its round; a second verdict
# of the same brief is the same round; a test-class breach is no product
# round), the hook's seconds and attempts inside the slice, each question's
# window, `open` for a question never answered, and `uncounted` for a
# slice whose close is timed before its open; and `metrics.sh` prints the
# slice's hook roll-up. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > INVENTORY.md <<'IV'
# toy
```vid-inventory
grammar: 0.9.3
ROW-001 | surface | /feed | anonymous | P01/list | one | REQ-001 | owed: prerequisite — x
ROW-002 | journey | /feed | anonymous | n/a | two | REQ-002 | owed: prerequisite — x
ROW-003 | behavior | REQ-003 | n/a | n/a | three | REQ-003 | owed: prerequisite — x
```
IV
cat > .vid/metrics-events <<'EV'
slice-open slice=1 sha=a at=2026-09-25T10:00:00Z
question n=1 state=asked gates=ROW-003 at=2026-09-25T10:05:00Z
paid row=ROW-001 via=ledger at=2026-09-25T10:10:00Z
paid row=ROW-003 via=ledger at=2026-09-25T10:20:00Z
verdict slice=1 row=ROW-002 result=BREACHED class=product brief=.vid/briefs/1/g-1.md quoted-at=a at=2026-09-25T10:30:00Z
verdict slice=1 row=ROW-002 result=BREACHED class=product transition=2/2 brief=.vid/briefs/1/g-1.md quoted-at=a at=2026-09-25T10:31:00Z
verdict slice=1 row=ROW-003 result=BREACHED class=test brief=.vid/briefs/1/g-1.md quoted-at=a at=2026-09-25T10:32:00Z
verdict slice=1 row=ROW-002 result=KEPT class=product brief=.vid/briefs/1/g-2.md quoted-at=a at=2026-09-25T10:40:00Z
question n=1 state=answered at=2026-09-25T10:45:00Z
slice-close slice=1 sha=b at=2026-09-25T11:00:00Z
paid row=ROW-002 via=ledger at=2026-09-25T11:20:00Z
slice-open slice=2 sha=b at=2026-09-25T12:00:00Z
question n=2 state=asked gates=all at=2026-09-25T11:30:00Z
verdict slice=2 row=ROW-001 result=BREACHED brief=.vid/briefs/2/g-1.md quoted-at=b at=2026-09-25T11:50:00Z
slice-close slice=2 sha=c at=2026-09-25T11:40:00Z
EV
cat > .vid/hook-times <<'HT'
hook result=pass seconds=40 placement=1 conformance=1 imports=- seams=- inventory+census=30 design-cite=- prd=12 harness=- selftest=- at=2026-09-25T10:15:00Z
hook result=refused seconds=20 placement=2 conformance=1 imports=- seams=- inventory+census=15 design-cite=- prd=memo harness=- selftest=- at=2026-09-25T10:50:00Z
hook result=pass seconds=90 placement=1 conformance=1 imports=- seams=- inventory+census=10 design-cite=- prd=5 harness=- selftest=80 at=2026-09-25T11:10:00Z
HT
OUT=$(sh checks/metrics.sh timing)
fail() { echo "timing: $*" >&2; printf '%s\n' "$OUT" >&2; exit 1; }
L1=$(printf '%s\n' "$OUT" | grep '^timing slice n=1 ') || fail 'no slice 1 line'
printf '%s\n' "$L1" | grep -q ' start=2026-09-25T10:00:00Z end=2026-09-25T11:00:00Z seconds=3600 ' || fail 'slice 1 wall'
printf '%s\n' "$L1" | tr ' ' '\n' | grep '^paid=' | tr ',' '\n' | sed 's/^paid=//' | sort | tr '\n' ' ' | grep -qx 'behavior:1 surface:1 ' || fail 'slice 1 rows paid by kind'
printf '%s\n' "$L1" | grep -q ' product-rounds=journey:1 ' || fail 'slice 1 product rounds (one brief, one round; KEPT later does not remove it; a test breach is none)'
printf '%s\n' "$L1" | grep -q ' hook-seconds=60 hook-attempts=2$' || fail "slice 1's hook share"
printf '%s\n' "$OUT" | grep -q '^timing slice n=2 start=2026-09-25T12:00:00Z end=2026-09-25T11:40:00Z seconds=uncounted ' || fail 'a negative span is not uncounted'
printf '%s\n' "$OUT" | grep -qx 'timing question n=1 asked=2026-09-25T10:05:00Z answered=2026-09-25T10:45:00Z seconds=2400' || fail 'the question window'
printf '%s\n' "$OUT" | grep -qx 'timing question n=2 asked=2026-09-25T11:30:00Z answered=open seconds=-' || fail 'an open question'
M=$(sh checks/metrics.sh 2>/dev/null)
printf '%s\n' "$M" | grep -q '^cost slice=1 hook attempts=2 seconds=60 median=30 costliest inventory+census=45 prd=12 placement=3 conformance=2 ' || { printf '%s\n' "$M" | grep hook >&2; fail "slice 1's hook roll-up"; }
exit 0

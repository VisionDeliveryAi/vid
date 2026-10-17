#!/bin/sh
# Purpose: selftest case — stage events pair by the last-token time (v0.9.5
# spec 3.11, 3.15; §7 case 17). A planted events file: init containing
# create-prd (three pauses) and test-inventory, a develop start whose session
# died, a second develop start after it with its end — the end written
# first in the file, so only the time orders them — a fix start with no
# end, a stage line carrying an earlier `at=` before its own, and an end
# with no start. Convicts unless `metrics.sh timing` prints each pair with
# its seconds and pauses, the dead session's start and the fix start as
# `open`, the orphan end as uncounted, and takes the LAST `at=` on a line.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" checks/
cat > .vid/metrics-events <<'EV'
stage name=init state=start session=S1 records=1 at=2026-09-25T10:00:00Z
stage name=create-prd state=start session=S1 records=1 at=2026-09-25T10:01:00Z
stage name=create-prd state=pause-1 session=S1 at=2026-09-25T10:20:00Z
stage name=create-prd state=pause-2 session=S1 at=2026-09-25T10:40:00Z
stage name=create-prd state=pause-3 session=S1 at=2026-09-25T10:50:00Z
stage name=create-prd state=end session=S1 at=2026-09-25T11:00:00Z
stage name=test-inventory state=start session=S1 records=1 at=2026-09-25T11:10:00Z
stage name=test-inventory state=end session=S1 at=2026-09-25T11:40:00Z
stage name=init state=end session=S1 at=2026-09-25T12:00:00Z
stage name=develop state=start session=S2 records=1 at=2026-09-25T12:10:00Z
died reason=rate_limit session=S2 at=2026-09-25T12:50:00Z
stage name=develop state=end session=S3 at=2026-09-25T14:00:00Z
stage name=develop state=start session=S3 records=1 at=2026-09-25T09:00:00Z at=2026-09-25T13:00:00Z
stage name=fix state=start session=S3 records=1 at=2026-09-25T15:00:00Z
stage name=deploy state=end session=S3 at=2026-09-25T15:30:00Z
EV
OUT=$(sh checks/metrics.sh timing)
fail() { echo "stage-pairing: $*" >&2; printf '%s\n' "$OUT" >&2; exit 1; }
for want in \
  'timing stage name=init start=2026-09-25T10:00:00Z end=2026-09-25T12:00:00Z seconds=7200 session=S1' \
  'timing stage name=create-prd start=2026-09-25T10:01:00Z end=2026-09-25T11:00:00Z seconds=3540 pause-1=2026-09-25T10:20:00Z pause-2=2026-09-25T10:40:00Z pause-3=2026-09-25T10:50:00Z session=S1' \
  'timing stage name=test-inventory start=2026-09-25T11:10:00Z end=2026-09-25T11:40:00Z seconds=1800 session=S1' \
  'timing stage name=develop start=2026-09-25T12:10:00Z end=open seconds=- session=S2' \
  'timing stage name=develop start=2026-09-25T13:00:00Z end=2026-09-25T14:00:00Z seconds=3600 session=S3' \
  'timing stage name=fix start=2026-09-25T15:00:00Z end=open seconds=- session=S3'; do
  printf '%s\n' "$OUT" | grep -qxF "$want" || fail "missing: $want"
done
printf '%s\n' "$OUT" | grep -q '^timing stage name=deploy start=- end=2026-09-25T15:30:00Z seconds=uncounted' || fail 'the end with no start is not uncounted'
[ "$(printf '%s\n' "$OUT" | grep -c '^timing stage ')" -eq 7 ] || fail 'not seven stage lines'
exit 0

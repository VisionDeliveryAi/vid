#!/bin/sh
# Purpose: selftest case — the event helper (v0.9.5 spec 3.11, R11; §7 case
# 13). In a scratch directory with no checks/ and no .vid/ — the plugin-path
# call before init — `sh "$CHECKS/event.sh" '<line>'` must create .vid/ and
# append exactly `<line> at=<UTC>` in the form YYYY-MM-DDTHH:MM:SSZ, dated
# this hour in UTC; a second call appends a second line; an empty event, a
# missing argument and a two-line event are refused and write nothing.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "event-helper: $*" >&2; cat .vid/metrics-events >&2 2>/dev/null || true; exit 1; }
D0=$(date -u '+%Y-%m-%dT%H')
sh "$CHECKS/event.sh" 'incident slice=3 the probe said at=noon' || fail 'the helper failed'
D1=$(date -u '+%Y-%m-%dT%H')
[ -d .vid ] || fail 'the helper did not create .vid/'
[ "$(grep -c . .vid/metrics-events)" -eq 1 ] || fail 'not exactly one line'
L=$(cat .vid/metrics-events)
printf '%s\n' "$L" | grep -qxE 'incident slice=3 the probe said at=noon at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' || fail 'the line is not <line> at=<UTC> in the exact form'
D=$(printf '%s\n' "$L" | sed 's/.* at=\([0-9-]*T[0-9]*\):.*/\1/')
[ "$D" = "$D0" ] || [ "$D" = "$D1" ] || fail "the time is not this hour in UTC ($D)"
sh "$CHECKS/event.sh" 'stage name=develop state=start session=S1 records=1'
[ "$(grep -c . .vid/metrics-events)" -eq 2 ] || fail 'the second call did not append'
for bad in '' 'two
lines'; do
  if sh "$CHECKS/event.sh" "$bad" 2>/dev/null; then fail 'a bad event was accepted'; fi
done
if sh "$CHECKS/event.sh" 2>/dev/null; then fail 'a missing argument was accepted'; fi
[ "$(grep -c . .vid/metrics-events)" -eq 2 ] || fail 'a refused event wrote something'
exit 0

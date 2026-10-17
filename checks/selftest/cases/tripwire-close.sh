#!/bin/sh
# Purpose: selftest case — a selected close counts as a full run in the
# full-runs-per-pass tripwire (v0.9.6.1 spec 3.1, R1; §6 case 11). Two
# `ledger-run kind=close` events in one pass flag; with an `invalidated`
# event between them, or a verdict closing the pass, they do not; a close
# after a full run in one pass flags. v0.9.7.0.12 (3.5, R5): a close
# batch's chunk runs (`batch=<id>`) count once — four chunks do not flag;
# a second batch in the pass does. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" checks/
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | x | anon | - | one | REQ-001 | owed: prerequisite — x; paid at slice 2\n```\n' > INVENTORY.md
flags() { sh checks/metrics.sh | grep -c 'cost FLAG full-runs-per-pass' || true; }
printf 'ledger-run seconds=9 kind=close report=a.close.xml status=0 at=2026-01-01T00:00:01Z\nledger-run seconds=9 kind=close report=b.close.xml status=0 at=2026-01-01T00:00:02Z\n' > .vid/metrics-events
[ "$(flags)" = 1 ] || { echo 'tripwire-close: two closes in one pass did not flag' >&2; exit 1; }
printf 'ledger-run seconds=9 kind=close report=a.close.xml status=0 at=2026-01-01T00:00:01Z\ninvalidated slice=1 report=a.close.xml the stack died at=2026-01-01T00:00:02Z\nledger-run seconds=9 kind=close report=b.close.xml status=0 at=2026-01-01T00:00:03Z\n' > .vid/metrics-events
[ "$(flags)" = 0 ] || { echo 'tripwire-close: a close after an invalidation flagged' >&2; exit 1; }
printf 'ledger-run seconds=9 kind=close report=a.close.xml status=0 at=2026-01-01T00:00:01Z\nverdict slice=1 claimed=3 breached=0 at=2026-01-01T00:00:02Z\nledger-run seconds=9 kind=close report=b.close.xml status=0 at=2026-01-01T00:00:03Z\n' > .vid/metrics-events
[ "$(flags)" = 0 ] || { echo 'tripwire-close: closes in two passes flagged' >&2; exit 1; }
printf 'ledger-run seconds=9 kind=full report=a.full.xml status=0 at=2026-01-01T00:00:01Z\nledger-run seconds=9 kind=close report=b.close.xml status=0 at=2026-01-01T00:00:02Z\n' > .vid/metrics-events
[ "$(flags)" = 1 ] || { echo 'tripwire-close: a close after a full run in one pass did not flag' >&2; exit 1; }
ch() { printf 'ledger-run seconds=9 kind=close report=%s.close.xml status=0 request=%s/%s batch=%s at=2026-01-01T00:00:0%sZ\n' "$1$2" "$1" "$2" "$1" "$2"; }
{ ch A 1; ch A 2; ch A 3; ch A 4; } > .vid/metrics-events
[ "$(flags)" = 0 ] || { echo "tripwire-close: one batch's chunks flagged" >&2; exit 1; }
ch B 5 >> .vid/metrics-events
[ "$(flags)" = 1 ] || { echo 'tripwire-close: a second batch in one pass did not flag' >&2; exit 1; }
exit 0

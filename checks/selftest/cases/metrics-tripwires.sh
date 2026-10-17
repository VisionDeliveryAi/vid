#!/bin/sh
# Purpose: selftest case — the two v0.9.2 tripwires (spec 3.6, 3.7 R16, 3.9b
# R14). (1) full runs per pass: a second `ledger-run kind=full` event before
# the next slice close, with no `invalidated` or `incident` event between,
# FLAGs; one full run per pass, or a second one after an invalidation, does
# not. (2) report-only classes: once slice 2 has closed, a report-only
# extractor class (vacuity, rendered, strength) with no `adjudicated
# class=<name>` event FLAGs; the event clears it; before slice 2 nothing
# flags. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors app .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '#!/bin/sh\n# Purpose: fixture vacuity extractor\necho "inactive fixture"\n' > checks/extractors/vacuity.ledger.sh
printf '# toy\n```vid-inventory\ngrammar: 0.9.2\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2\n```\n' > INVENTORY.md
cat > .vid/metrics-events <<'EV'
ledger-run seconds=100 kind=full report=none
ledger-run seconds=100 kind=full report=none
verdict slice=1 claimed=3 breached=0
ledger-run seconds=90 kind=full report=none
invalidated slice=2 the close run died with the stack
ledger-run seconds=90 kind=full report=none
ledger-run seconds=5 kind=scoped report=none
EV
OUT=$(sh checks/metrics.sh)
printf '%s\n' "$OUT" | grep -q 'cost FLAG full-runs-per-pass n=1' || { echo 'metrics-tripwires: the second full run did not flag' >&2; printf '%s\n' "$OUT" | grep -i flag >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'FLAG report-only-unadjudicated' && { echo 'metrics-tripwires: report-only flagged before slice 2' >&2; exit 1; }
# slice 2 closes: the report-only class flags until adjudicated
printf 'verdict slice=2 claimed=2 breached=0\n' >> .vid/metrics-events
sh checks/metrics.sh | grep -q 'evidence FLAG report-only-unadjudicated class=vacuity' || { echo 'metrics-tripwires: the unadjudicated class did not flag' >&2; exit 1; }
printf 'adjudicated class=vacuity advisory true=3 false=7\n' >> .vid/metrics-events
sh checks/metrics.sh | grep -q 'FLAG report-only-unadjudicated' && exit 1
# one full run per pass, and a second after an invalidation, never flag
cat > .vid/metrics-events <<'EV'
ledger-run seconds=100 kind=full report=none
verdict slice=1 claimed=3 breached=0
ledger-run seconds=90 kind=full report=none
incident slice=2 stack death mid-run
ledger-run seconds=90 kind=full report=none
verdict slice=2 claimed=2 breached=0
adjudicated class=vacuity deleted true=0 false=10
EV
sh checks/metrics.sh | grep -q 'FLAG full-runs-per-pass' && { echo 'metrics-tripwires: a lawful pair of full runs flagged' >&2; exit 1; }
exit 0

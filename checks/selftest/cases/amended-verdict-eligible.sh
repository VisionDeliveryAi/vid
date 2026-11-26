#!/bin/sh
# Purpose: selftest case — a verdict quoted after its row's amendment counts (FIX-BATCH-T1 §1, B-1). A gated toy run:
# ROW-001 amended at commit A (`amended row=ROW-001 sha=A by=obligation`); a verdict KEPT quoted at B, a descendant of A,
# makes the row KEPT; a later verdict BREACHED quoted at C, a commit on a side branch not descended from A, is ignored:
# the row stays KEPT. Convicts on the read that split nothing (metrics.sh's vstate93), which threw both away. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "amended-verdict-eligible: $*" >&2; exit 1; }
latest() { sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $3 }'; }
plan_repo "$T/repo"; rows S1 1 1; commit_all rows
P=$(git rev-parse HEAD)
printf 'amended\n' > app/s1/notes.txt; commit_all 'the amendment'
A=$(git rev-parse --short=12 HEAD)
printf 'amended row=ROW-001 sha=%s by=obligation at=%s\n' "$A" "$(utcnow)" >> .vid/metrics-events
printf 'later\n' > app/s1/later.txt; commit_all 'after the amendment'
B=$(git rev-parse --short=12 HEAD)
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$B" "$(utcnow)" >> .vid/metrics-events
[ "$(latest)" = KEPT ] || fail "a verdict quoted at a descendant of the amendment reads $(latest), not KEPT"
git checkout -q -b side "$P"; printf 'side\n' > app/s1/side.txt; commit_all 'a side commit'
C=$(git rev-parse --short=12 HEAD); git checkout -q -
printf 'verdict slice=1 row=ROW-001 result=BREACHED class=product brief=b2 quoted-at=%s at=%s\n' "$C" "$(utcnow)" >> .vid/metrics-events
[ "$(latest)" = KEPT ] || fail "a verdict quoted at a commit not descended from the amendment counted: $(latest)"
exit 0

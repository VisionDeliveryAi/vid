#!/bin/sh
# Purpose: selftest case — prd.sh must convict the known-bad fixture AND
# name one GAP per join class, so a court that convicts on the first
# violation and skips the rest is caught. Exits 0 only on a full
# conviction. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cp "$FIXTURES/prd-known-bad.md" "$T/PRD.md"
cd "$T"
OUT=$(sh "$COURT" PRD.md --report 2>&1)
# default mode must convict.
if sh "$COURT" PRD.md >/dev/null 2>&1; then exit 1; fi
# one named GAP per join class — a partial conviction is a failing court.
for want in \
  'GAP  join 3 (REQ-101): a demand row with no fail-if' \
  'GAP  join 3 (INV-101): a frame row carrying fail-if' \
  "GAP  join 2 (REQ-102): unknown type 'feature'" \
  'GAP  join 4 (REQ-110): a demand row with no serves' \
  'GAP  join 5 (REQ-103): provisional with no confirms_via' \
  'GAP  join 6 (REQ-104): a pending item claims covers' \
  'GAP  join 7 (A-103): settles REQ-105' \
  "GAP  join 8 (A-104): settles 'REQ-888'" \
  "GAP  join 9 (DIM-consent): written status 'covered' but no item cites it" \
  "GAP  join 9 (DIM-nfr-operability): facet 'observability' is cited by no item" \
  'GAP  join 9 (DIM-panel-noprompt): a panel-added dimension with no prompt' \
  'GAP  join 9: 25 dimensions' \
  'GAP  join 9 (REQ-108): covers cites DIM-ghost,' \
  "'ghostfacet' is not a declared facet" \
  "GAP  join 9 (MET-101): type 'metric' is not in DIM-notifications" \
  'GAP  join 10: zero non_goal rows' \
  'GAP  join 11: goal G3 has no mechanisms row' \
  'does not appear verbatim in the Seed section' \
  'GAP  join 12: duplicate statement in the effective set' \
  "GAP  join 12: 'REQ-777 AMENDED' has no earlier row" \
  "GAP  join 12 (A-999 AMENDED): no earlier ledger row with id A-999" \
  'GAP  join 12 (INV-102): spans cites REQ-999' \
  'GAP  join 2 (REQ-111): cross-cutting: names no surface' \
  'GAP  join 5 (REQ-112): pending on OQ-11, but that carrier is resolved' \
  'GAP  join 8 (OQ-12): RESOLVED names no ledger answer that exists' \
  'GAP  join 13 (F-901): a blocking finding merely noted' \
  "GAP  join 13 (F-902): target 'REQ-888' resolves to no item" \
  "GAP  join 8 (A-103): unchanged: names 'REQ-999'" \
  "NOTE  join 1 (A-104): unlabeled field 'notes: dedupe by title'" \
; do
  printf '%s\n' "$OUT" | grep -qF "$want" || { echo "missing conviction: $want" >&2; exit 1; }
done
# The grammar gate (v0.9.1 3.2, 3.6): the same unknown answer-row label is a
# NOTE on this legacy file (above) and a GAP once the header carries
# `grammar: 0.9.1` — a new strictness never convicts a pre-0.9.1 file.
printf '%s\n' "$OUT" | grep -qF "GAP  join 1 (A-104): unlabeled field" && { echo 'legacy file convicted on an answer-row label — the grammar gate is broken' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'grammar=legacy' || { echo 'report line does not name the legacy grammar' >&2; exit 1; }
{ sed -n '1p' PRD.md; echo 'grammar: 0.9.1'; sed -n '2,$p' PRD.md; } > PRD-091.md
OUT2=$(sh "$COURT" PRD-091.md --report 2>&1)
printf '%s\n' "$OUT2" | grep -qF "GAP  join 1 (A-104): unlabeled field 'notes: dedupe by title'" || { echo 'missing conviction under grammar: 0.9.1: the answer-row label' >&2; exit 1; }
printf '%s\n' "$OUT2" | grep -q 'grammar=0.9.1' || { echo 'report line does not name the 0.9.1 grammar' >&2; exit 1; }
# 3.8: under the grammar line a five-field row convicts — its priority column is a stray field.
printf '%s\n' "$OUT2" | grep -qE "GAP  join 1 \(REQ-1[0-9]+\): the priority column \('(P[0-2]|-)'\) is gone under grammar 0.9.1" || { echo 'missing conviction under grammar: 0.9.1: the five-field row' >&2; exit 1; }
exit 0

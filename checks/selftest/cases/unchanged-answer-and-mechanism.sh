#!/bin/sh
# Purpose: selftest case — `unchanged:` may name answers and mechanisms (0.26.10.29.3, phase 2 R3). On the known-good
# PRD fixture with one answer appended, the court (checks/prd.sh, join 8) accepts `unchanged: A-001, MECH-01` and
# `unchanged: REQ-001, A-002, MECH-02` (all exist), and refuses `unchanged: A-777` and `unchanged: MECH-99`, naming
# the id. Env: CHECKS.
set -eu
fail() { echo "unchanged-answer-and-mechanism: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
prd() { # <unchanged list>
  { cat "$F"; printf '\n### 2026-11-15 (owner answer)\n\n```vid-prd-answers\nA-007 | human | 2026-11-15 | Q: does a digest wait for a paused feed? | A: no — the digest goes out with what the other feed has | settles: REQ-001 | unchanged: %s\n```\n\nreview: delta, round 1, 0 findings\n' "$1"; } > PRD.md; }
prd 'A-001, MECH-01'
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'unchanged: A-001, MECH-01 (both exist) was refused'; }
prd 'REQ-001, A-002, MECH-02'
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'unchanged: REQ-001, A-002, MECH-02 was refused'; }
for bad in A-777 MECH-99; do
  prd "$bad"
  if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail "unchanged: $bad (no such row) passed"; fi
  grep -q "GAP  join 8 (A-007): unchanged: names '$bad'" out.txt || { cat out.txt >&2; fail "the refusal does not name $bad"; }
done
echo 'unchanged-answer-and-mechanism: ok'

#!/bin/sh
# Purpose: selftest case — a finding may target another document, by form only (0.26.10.29.3, phase 2 R6). On the
# known-good PRD fixture, in a folder holding no other document, the court (checks/prd.sh, join 13) accepts targets
# naming each listed document, bare or with an id (INVENTORY.md:ROW-12, DESIGN-BRIEF.md:D-149, design/tokens.css,
# design/screens/index.json, ARCHITECTURE.md, DECISIONS.md:D-3, BASELINE.md, GRADING-CHECKLIST.md:G-3, STAGES.md) —
# it never opens them — and refuses a file outside the list (NOTES.md:N-1, PRD.md:REQ-001, ../INVENTORY.md), an
# empty id (INVENTORY.md:), an id holding a space, and a design path climbing out (design/../x). Env: CHECKS.
set -eu
fail() { echo "findings-file-target-form: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
prd() { awk -v t="$1" '/^## Ratifications$/ { print "### 2026-11-15 — final review"; print ""; print "```vid-prd-findings"
    print "F-10 | final | advisory | " t " | noted | evidence: minor — a probe"; print "```"; print "" } { print }' "$F" > PRD.md; }
for t in INVENTORY.md:ROW-12 DESIGN-BRIEF.md:D-149 design/tokens.css design/screens/index.json design/ ARCHITECTURE.md \
  DECISIONS.md:D-3 BASELINE.md GRADING-CHECKLIST.md:G-3 STAGES.md STAGES.md:S-2 'REQ-001, INVENTORY.md:ROW-12'; do
  prd "$t"
  sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail "the target '$t' was refused"; }
done
for t in NOTES.md:N-1 PRD.md:REQ-001 ../INVENTORY.md INVENTORY.md: 'INVENTORY.md:ROW 12' design/../x inventory.md; do
  prd "$t"
  if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail "the target '$t' passed"; fi
  grep -q "GAP  join 13 (F-10): target" out.txt || { cat out.txt >&2; fail "the refusal of '$t' is not join 13's target rule"; }
done
echo 'findings-file-target-form: ok'

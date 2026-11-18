#!/bin/sh
# Purpose: selftest case — a finding may target an answer (0.26.10.29.3, phase 2 R3). On the known-good PRD fixture
# with one sitting added under `## Findings`, the court (checks/prd.sh, join 13) accepts a finding whose target is an
# answer that exists (A-005), and one naming every side of a contradiction (REQ-006, A-001, MECH-02), and refuses one
# whose target is an answer that does not exist (A-777). Env: CHECKS.
set -eu
fail() { echo "findings-target-answer: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
prd() { # <target>
  awk -v t="$1" '/^## Ratifications$/ { print "### 2026-11-15 — pause 3 sitting"; print ""; print "```vid-prd-findings"
    print "F-10 | review | blocking | " t " | repaired | evidence: the cap answer and the rows it settles disagree"; print "```"; print "" } { print }' "$F" > PRD.md; }
prd A-005
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'a finding targeting the existing answer A-005 was refused'; }
prd 'REQ-006, A-001, MECH-02'
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'a finding naming every side (an item, an answer and a mechanism) was refused'; }
prd A-777
if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail 'a finding targeting the missing answer A-777 passed'; fi
grep -q "GAP  join 13 (F-10): target 'A-777' resolves to no item" out.txt || { cat out.txt >&2; fail 'the refusal does not name the missing answer'; }
echo 'findings-target-answer: ok'

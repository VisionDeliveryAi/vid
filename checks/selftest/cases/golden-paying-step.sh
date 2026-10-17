#!/bin/sh
# Purpose: selftest case — inventory.sh must join a golden-set row to its
# difference row (v0.8.1d): `divergence: DIF-NNN` must name a difference row
# that exists and carries `paying-step:`, and `golden:` must name a fixture
# that exists. Polarity: the complete pair passes.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p tests/invariants
: > tests/invariants/test_req941.py
: > tests/invariants/golden_search.md
inv() { { printf '# toy\n```vid-inventory\n'; for l in "$@"; do printf '%s\n' "$l"; done; printf '```\n'; } > INVENTORY.md; }
ROW='ROW-941 | behavior | REQ-941 | n/a | n/a | every golden query must-appear result is on the first page | REQ-941 | tests/invariants/test_req941.py | golden: tests/invariants/golden_search.md | divergence: DIF-001'
# polarity: DIF exists and carries its paying step
inv "$ROW" 'difference | DIF-001 | embedder | stand-in | real model | no network in the ledger | paying-step: staging — re-run tests/invariants/golden_search.md against the real component'
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
# 1. the DIF lacks a paying step
inv "$ROW" 'difference | DIF-001 | embedder | stand-in | real model | no network in the ledger'
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'carries no paying-step' || exit 1
# 2. the named DIF does not exist
inv "$ROW"
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'names no difference row' || exit 1
# 3. the golden fixture does not exist
rm tests/invariants/golden_search.md
inv "$ROW" 'difference | DIF-001 | embedder | stand-in | real model | no network in the ledger | paying-step: staging — re-run against the real component'
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q "golden: 'tests/invariants/golden_search.md' does not exist" || exit 1
exit 0

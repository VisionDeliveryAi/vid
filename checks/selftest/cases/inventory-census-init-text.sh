#!/bin/sh
# Purpose: selftest case — the inventory writer is told the census rule at init (FIX-BATCH-T1 §4, B-5). Where the skills
# are: vid-test-inventory's `invariant` bullet and its §4.1 each say that at init a census over the code is written as an
# extractor-path census (checks/extractors/invariant.<name>.sh) and that checks/inventory.sh refuses, at the spec commit,
# an inline census command that searches a path not there yet. Outside the plugin repository there is nothing to read.
# Env: CHECKS.
set -eu
fail() { echo "inventory-census-init-text: $*" >&2; exit 1; }
F=$CHECKS/../skills/vid-test-inventory/SKILL.md
[ -f "$F" ] || { echo 'inventory-census-init-text: no skills here — nothing to read'; exit 0; }
flat() { tr '\n' ' ' | tr -s ' '; }
B=$(awk '/^- \*\*`invariant` rows are the RULE-row candidates\*\*/ { on = 1 } on && /^- \*\*`non_goal`/ { exit } on' "$F" | flat)
S=$(awk '/^### 4\.1 Census row classes/ { on = 1; next } on && /^\*\*Lifecycle fields/ { exit } on' "$F" | flat)
[ -n "$B" ] || fail 'no invariant bullet found'
[ -n "$S" ] || fail 'no §4.1 found'
for t in "$B" "$S"; do
  printf '%s\n' "$t" | grep -qF 'checks/extractors/invariant.<name>.sh' || fail "a place lacks the extractor-path census: $(printf '%s' "$t" | cut -c1-80)"
  printf '%s\n' "$t" | grep -qF 'checks/inventory.sh refuses' || fail "a place does not say inventory.sh refuses an inline census over a path not there yet: $(printf '%s' "$t" | cut -c1-80)"
done
echo 'inventory-census-init-text: ok'

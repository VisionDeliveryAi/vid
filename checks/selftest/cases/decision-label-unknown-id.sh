#!/bin/sh
# Purpose: selftest case — a label names only what briefs join on (v0.9.7.3 spec 3.1, R1). Under the real hook with
# stub courts, from the staged INVENTORY.md: a row id, its derived-from REQ id, a rule-row id and a marker's screen
# code pass; a row id that is no row, a screen code no row marks (a design-manifest code), an INV id, and a DIF id
# while no row carries a divergence: field are refused, each named; once a row's divergence: names it, the DIF label
# passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "decision-label-unknown-id: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\nrule | RULE-001 | sessions expire | grep x | 0 | owed: census-armed — later | origin: REQ-001\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md
g add -A && g commit -qm 'the inventory'
try() { cp DECISIONS.md "$T/.vid/dec"; printf -- '- **D-001** sessions last a day | why: support load | enforced: convention | applies-to: %s\n' "$1" >> DECISIONS.md; g add -A
  if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then r=pass; else r=refused; fi
  cp "$T/.vid/dec" DECISIONS.md; g add DECISIONS.md; echo "$r"; }
[ "$(try 'ROW-001, REQ-001, RULE-001, LOGIN')" = pass ] || fail 'a row, its REQ, a rule row and a screen code were refused'
[ "$(try 'ROW-001, ROW-999')" = refused ] || fail 'a row id that is no row passed'; grep -q 'ROW-999: not an id a brief joins on' "$T/.vid/out" || fail 'ROW-999 is not named'
[ "$(try 'CHECKOUT')" = refused ] || fail 'a screen code no row marks passed'; grep -q 'CHECKOUT: not a screen code' "$T/.vid/out" || fail 'CHECKOUT is not named'
[ "$(try 'INV-001')" = refused ] || fail 'an INV id passed'
[ "$(try 'DIF-001')" = refused ] || fail 'a DIF id passed with no divergence: field'; grep -q 'DIF-001: no INVENTORY row carries a divergence: field' "$T/.vid/out" || fail 'the DIF refusal does not say why'
sed 's/| REQ-001 | owed: prerequisite — later$/| REQ-001 | owed: prerequisite — later | divergence: DIF-001/' INVENTORY.md > x && mv x INVENTORY.md
[ "$(try 'DIF-001')" = pass ] || fail 'a DIF id a row divergence: names was refused'
[ "$(try 'DIF-002')" = refused ] || fail 'a DIF id no row names passed'
exit 0

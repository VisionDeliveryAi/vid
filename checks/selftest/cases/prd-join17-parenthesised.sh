#!/bin/sh
# Purpose: selftest case — join 17 reads every answer a source: cites (v0.9.8.1 R38, F-28). From the 0.9.4
# known-good fixture, A-005 a ViD decision (model_proposed): under a PRD headed grammar 0.9.8.1, an authoritative
# item citing it only inside an entry — `the owner's sitting (A-005)` — is refused by join 17; under 0.9.4, a
# provisional owner-decision item whose only ViD decision is cited so is acquitted (it cites one). Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-join17-parenthesised: $*" >&2; printf '%s\n' "$OUT" | grep '^GAP\|^NOTE' | head -5 >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
cp "$FIXTURES/prd-094-good.md" G.md
sed -e 's/^grammar: 0\.9\.4$/grammar: 0.9.8.1/' -e "s/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, the owner's sitting (A-005) |/" G.md > NEW.md
grep -q "^REQ-011 .*source: thesis, the owner's sitting (A-005) |" NEW.md && grep -qx 'grammar: 0.9.8.1' NEW.md || fail 'the mutation did not apply'
run NEW.md; [ "$RC" -ne 0 ] || fail 'an authoritative item citing a ViD decision in brackets was acquitted under 0.9.8.1'
printf '%s\n' "$OUT" | grep -qF 'GAP  join 17 (REQ-011): authoritative but its source: cites A-005' || fail 'join 17 did not refuse it'
sed "s/^\(REQ-006 .*\)| source: A-005 |/\1| source: per the decision (A-005) |/" G.md > PROV.md
grep -q '^REQ-006 .*source: per the decision (A-005) |' PROV.md || fail 'the provisional mutation did not apply'
run PROV.md; [ "$RC" -eq 0 ] || fail 'a provisional item citing its ViD decision in brackets was refused'
# a new PRD starts under the refusing grammar: the template's header is 0.9.8.1 (plugin repository only)
TPL="$CHECKS/../templates/PRD.md"; [ ! -f "$TPL" ] || sed -n 2p "$TPL" | grep -qx 'grammar: 0.9.8.1' || fail "the PRD template's grammar is not 0.9.8.1"
exit 0

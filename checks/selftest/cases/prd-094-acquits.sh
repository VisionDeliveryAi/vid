#!/bin/sh
# Purpose: selftest case — prd.sh, v0.9.4 spec §7 case 2: the 0.9.4
# known-good fixture (checks/selftest/fixtures/prd-094-good.md) acquits by
# default and under --pause, with zero GAP and zero NOTE lines — a court
# that convicts a lawful 0.9.4 PRD is as false as one that convicts
# nothing. The fixture must keep exercising every new rule: a features
# block, feature: on every demand item and invariant, a T0 item routed to a
# carrier naming its ViD decision, a human answer marked priority, current
# shown: labels, a traced value, a lens row. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-acquits: $*" >&2; exit 1; }
cp "$FIXTURES/prd-094-good.md" PRD.md
sed -n '2p' PRD.md | grep -qx 'grammar: 0.9.4' || fail 'the fixture is not headed grammar: 0.9.4'
grep -q '^```vid-prd-features$' PRD.md || fail 'no features block'
grep -q '^INV-002 | invariant | T0 .*confirms_via: owner-decision OQ-3/yes | source: A-007' PRD.md || fail 'no T0 item routed to its question'
grep -q '^VID-QUESTION: (OQ-3) A-007 — ' PRD.md || fail 'no carrier naming its ViD decision'
grep -q '| importance: priority$' PRD.md || fail 'no priority answer'
[ "$(grep -c '| shown: pause-[0-9]* [0-9]*$' PRD.md)" -eq 2 ] || fail 'the two shown: labels are missing'
grep -q '^MET-001 .*28-day.*| source: A-008 ' PRD.md || fail 'no traced value'
grep -q '^F-05 | lens ' PRD.md || fail 'no lens row'
for m in '' --pause; do
  set +e; OUT=$(sh "$COURT" PRD.md $m 2>&1); RC=$?; set -e
  [ "$RC" -eq 0 ] || { printf '%s\n' "$OUT" | grep '^GAP' | head -5 >&2; fail "convicted ${m:-by default}"; }
  printf '%s\n' "$OUT" | grep -q '^GAP' && fail "GAP lines ${m:-by default}"
  printf '%s\n' "$OUT" | grep -q '^NOTE' && fail "NOTE lines ${m:-by default}"
  printf '%s\n' "$OUT" | grep -q ' gaps=0 grammar=0.9.4 notes=0 features=3 ' || fail "report ${m:-by default}: $(printf '%s\n' "$OUT" | tail -1)"
done
exit 0

#!/bin/sh
# Purpose: selftest case — consolidation keeps every amended mechanism
# (0.26.10.29.3, R1). From the known-good fixture with two more base
# mechanisms, MECH-14 and MECH-32, whose append restates both as AMENDED
# rows: checks/prd-consolidate.sh writes `## Mechanisms` as the effective
# rows — one per id, MECH-01, MECH-02, MECH-14, MECH-32 in first-appearance
# order, MECH-14 and MECH-32 in their amended wording, no AMENDED marker, one
# mechanisms block in the file; the history keeps the AMENDED rows verbatim;
# the court passes on the output given the input as --before; a second run is
# byte-identical. Env: CHECKS.
set -eu
SCRIPT="$CHECKS/prd-consolidate.sh"; COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "consolidate-keeps-amended-mechanisms: $*" >&2; exit 1; }
awk '{ print } /^MECH-02 \|/ {
  print "MECH-14 | G1 | A digest is assembled once per saved search from the listings new since its last send. | stated: answer A-001"
  print "MECH-32 | G2 | Synonyms come from one maintained table the matcher reads at query time. | stated: answer A-002" }' \
  "$FIXTURES/prd-known-good.md" > PRD.md
cat >> PRD.md <<'APP'

### 2026-09-20 (owner answer — two mechanisms reworded)

```vid-prd-mechanisms
MECH-14 AMENDED | G1 | A digest is assembled once per saved search from the listings new since its last send, and an empty digest is never sent. | stated: answer A-001
MECH-32 AMENDED | G2 | Synonyms come from one maintained table, reviewed monthly, that the matcher reads at query time. | stated: answer A-002
```
APP
sh "$COURT" PRD.md >/dev/null 2>&1 || fail 'the seeded input is not court-green'
cp PRD.md IN.md
sh "$SCRIPT" PRD.md --date 2026-09-21 >run1.txt 2>&1 || { cat run1.txt >&2; fail 'the consolidation refused the fixture'; }
MS=$(sed -n '/^## Mechanisms$/,/^## /p' PRD.md)
[ "$(printf '%s\n' "$MS" | grep -E '^MECH-[0-9]+' | cut -d' ' -f1 | paste -sd ' ' -)" = 'MECH-01 MECH-02 MECH-14 MECH-32' ] \
  || fail "the mechanism rows are not one per id in first-appearance order: $(printf '%s\n' "$MS" | grep -E '^MECH-' | cut -d' ' -f1-2 | paste -sd ',' -)"
printf '%s\n' "$MS" | grep '^MECH-14 ' | grep -q 'an empty digest is never sent' || fail 'MECH-14 is not in its amended wording'
printf '%s\n' "$MS" | grep '^MECH-32 ' | grep -q 'reviewed monthly' || fail 'MECH-32 is not in its amended wording'
printf '%s\n' "$MS" | grep -q 'AMENDED' && fail 'the AMENDED marker survived in ## Mechanisms'
[ "$(grep -c '^```vid-prd-mechanisms$' PRD.md)" -eq 1 ] || fail 'not one mechanisms block in the consolidated file'
grep -qxF 'MECH-01 | G1 | Feeds are polled on a schedule and normalised into one listing store. | stated: seed "two source feeds, merged"' PRD.md || fail 'MECH-01 changed'
grep -qF 'MECH-14 AMENDED | G1 | A digest is assembled once per saved search from the listings new since its last send, and an empty digest is never sent.' PRD-HISTORY-2026-09-21.md || fail 'the history lost the AMENDED row'
sh "$COURT" --before IN.md PRD.md >court.txt 2>&1 || { cat court.txt >&2; fail 'the court refuses the consolidated file given its input as --before'; }
cp PRD.md PRD.first
sh "$SCRIPT" PRD.md --date 2026-09-22 >run2.txt 2>&1 || { cat run2.txt >&2; fail 'the second run refused'; }
cmp -s PRD.md PRD.first || fail 'the second run is not byte-identical'
exit 0

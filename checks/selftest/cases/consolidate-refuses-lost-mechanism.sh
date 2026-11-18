#!/bin/sh
# Purpose: selftest case — consolidation refuses to lose a mechanism
# (0.26.10.29.3, R1). On a copy of checks/prd-consolidate.sh with a planted
# defect — the line after `MECHROWS=` drops the last effective mechanism row
# before it is written — the fixture whose append amends MECH-14 and MECH-32
# is refused: the script exits non-zero naming MECH-32, and PRD.md, SEED.md
# and the history are untouched (nothing written). The court half: a
# consolidated file whose MECH-14 is put back to its first wording passes
# checks/prd.sh alone (the defect class the court passed before) and is
# refused with --before <the input>, the GAP naming MECH-14. The whole row is
# compared: a mechanism whose text holds a tab, changed only after the tab, is
# a gap under --before and makes the script's own check refuse, naming it
# changed. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "consolidate-refuses-lost-mechanism: $*" >&2; exit 1; }
B14='MECH-14 | G1 | A digest is assembled once per saved search from the listings new since its last send. | stated: answer A-001'
awk -v b14="$B14" '{ print } /^MECH-02 \|/ { print b14
  print "MECH-32 | G2 | Synonyms come from one maintained table the matcher reads at query time. | stated: answer A-002" }' \
  "$FIXTURES/prd-known-good.md" > IN.md
cat >> IN.md <<'APP'

### 2026-09-20 (owner answer — two mechanisms reworded)

```vid-prd-mechanisms
MECH-14 AMENDED | G1 | A digest is assembled once per saved search from the listings new since its last send, and an empty digest is never sent. | stated: answer A-001
MECH-32 AMENDED | G2 | Synonyms come from one maintained table, reviewed monthly, that the matcher reads at query time. | stated: answer A-002
```
APP
sh "$COURT" IN.md >/dev/null 2>&1 || fail 'the seeded input is not court-green'
# the planted defect: a copy of the script and its court, one line added after the MECHROWS= line
mkdir c d
cp "$COURT" c/prd.sh
cat > plant.txt <<'EOF'
MECHROWS=$(printf '%s\n' "$MECHROWS" | sed '$d')
EOF
awk 'FNR == NR { p = $0; next } { print } /^MECHROWS=/ && !done { print p; done = 1 }' plant.txt "$CHECKS/prd-consolidate.sh" > c/prd-consolidate.sh
[ "$(grep -c '^MECHROWS=' c/prd-consolidate.sh)" -eq 2 ] || fail 'the defect could not be planted: no MECHROWS= line in checks/prd-consolidate.sh'
cp IN.md d/PRD.md
if sh c/prd-consolidate.sh d/PRD.md --date 2026-09-21 >bad.txt 2>&1; then fail 'the planted defect dropped a mechanism and the script wrote its output'; fi
grep -q 'MECH-32' bad.txt || { cat bad.txt >&2; fail 'the refusal does not name the lost mechanism MECH-32'; }
cmp -s d/PRD.md IN.md || fail 'the refused run changed PRD.md'
[ ! -f d/SEED.md ] && [ ! -f d/PRD-HISTORY-2026-09-21.md ] || fail 'the refused run wrote SEED.md or the history'
# the court half: the old copy (MECH-14 back to its first wording) passes the court alone, and is refused with --before
mkdir e && cp IN.md e/PRD.md
sh "$CHECKS/prd-consolidate.sh" e/PRD.md --date 2026-09-21 >good.txt 2>&1 || { cat good.txt >&2; fail 'the real script refused the fixture'; }
awk -v b14="$B14" '/^MECH-14 \|/ { print b14; next } { print }' e/PRD.md > e/OLD.md
grep -qxF "$B14" e/OLD.md || fail 'the reverted copy does not carry the first wording'
sh "$COURT" e/OLD.md >/dev/null 2>&1 || fail 'the reverted copy fails the court alone (the case expects the court to need --before)'
if sh "$COURT" --before IN.md e/OLD.md >old.txt 2>&1; then fail 'the court passed a consolidation that put MECH-14 back to its first wording, given --before'; fi
grep '^GAP' old.txt | grep -q 'MECH-14' || { cat old.txt >&2; fail 'the --before refusal does not name MECH-14'; }
# a mechanism whose text holds a tab: a change after the tab is a change (the whole row is compared)
TAB=$(printf '\t')
T14="MECH-14 | G1 | A digest is assembled once per saved search${TAB}from the listings new since its last send. | stated: answer A-001"
awk -v t14="$T14" '{ print } /^MECH-02 \|/ { print t14 }' "$FIXTURES/prd-known-good.md" > TAB.md
sh "$COURT" TAB.md >/dev/null 2>&1 || fail 'the fixture with a tab in a mechanism is not court-green'
mkdir f g && cp TAB.md f/PRD.md && cp TAB.md g/PRD.md
sh "$CHECKS/prd-consolidate.sh" f/PRD.md --date 2026-09-21 >goodt.txt 2>&1 || { cat goodt.txt >&2; fail 'the real script refused the tab fixture'; }
sed "s/${TAB}from the listings new/${TAB}from every listing new/" f/PRD.md > f/OLD.md
cmp -s f/PRD.md f/OLD.md && fail 'the text after the tab was not changed'
if sh "$COURT" --before TAB.md f/OLD.md >oldt.txt 2>&1; then fail 'the court passed a mechanism whose text after a tab changed, given --before'; fi
grep '^GAP' oldt.txt | grep -q 'MECH-14' || { cat oldt.txt >&2; fail 'the --before refusal does not name MECH-14 (the tab row)'; }
printf 'MECHROWS=$(printf '"'"'%%s\\n'"'"' "$MECHROWS" | sed '"'"'s/\tfrom the listings new/\tfrom every listing new/'"'"')\n' > plantt.raw
sed "s/\\t/${TAB}/g" plantt.raw > plantt.txt
awk 'FNR == NR { p = $0; next } { print } /^MECHROWS=/ && !done { print p; done = 1 }' plantt.txt "$CHECKS/prd-consolidate.sh" > c/prd-consolidate.sh
if sh c/prd-consolidate.sh g/PRD.md --date 2026-09-21 >badt.txt 2>&1; then fail 'the planted defect changed a mechanism after its tab and the script wrote its output'; fi
grep -q 'MECH-14 changed' badt.txt || { cat badt.txt >&2; fail 'the refusal does not name MECH-14 as changed (the text after its tab)'; }
cmp -s g/PRD.md TAB.md || fail 'the refused run changed PRD.md (the tab fixture)'
exit 0

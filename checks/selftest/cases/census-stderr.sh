#!/bin/sh
# Purpose: selftest case — census.sh must fail a rule row whose census
# command writes to standard error (v0.8.1d, G-08's measured class: a syntax
# error in one arm of a compound command took a population from 72 sites to
# 18 with zero orphans and exit 0). Exits 0 only if the court convicts the
# arm-broken command AND (polarity) passes the same rule with a clean one,
# AND reports a strength-class extractor's orphan as STR without failing.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors tests/invariants
touch tests/invariants/test_rule921.py
# the left arm emits one site, then a broken sub-command: today's population
# would silently be 1 site, 1 guarded, exit 0.
cat > INVENTORY.md <<'EOF2'
# toy
```vid-inventory
rule | RULE-921 | seeded arm-broken census | { printf 'site-a\n'; printf 'site-b\n' | sed 's/x/'; } :: printf 'site-a\nsite-b\n' | T1 | tests/invariants/test_rule921.py
```
EOF2
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/census.sh" --report 2>&1 | grep -q 'RULE-921  census command wrote to standard error' || exit 1
# the single-enumeration form convicts too
cat > INVENTORY.md <<'EOF2'
# toy
```vid-inventory
rule | RULE-921 | seeded arm-broken single enumeration | { printf 'site-a\n'; printf 'site-b\n' | sed 's/x/'; } | T1 | tests/invariants/test_rule921.py
```
EOF2
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
# polarity: the same rule with a clean compound command passes, 2 sites 2 guarded
cat > INVENTORY.md <<'EOF2'
# toy
```vid-inventory
rule | RULE-921 | seeded clean census | printf 'site-a\nsite-b\n' :: printf 'site-a\nsite-b\n' | T1 | tests/invariants/test_rule921.py
```
EOF2
sh "$CHECKS/census.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/census.sh" --report 2>&1 | grep -q 'census RULE-921: 2 sites, 2 guarded' || exit 1
# strength class: report-only — an orphan prints as STR and never fails
rm INVENTORY.md
printf '#!/bin/sh\necho "ok tests/invariants/test_a.py:12"\necho "orphan tests/invariants/test_b.py:30 ROW-004 T0 strongest=existence"\n' > checks/extractors/strength.ledger.sh
sh "$CHECKS/census.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/census.sh" --report 2>&1 | grep -q '^STR   strength.ledger  tests/invariants/test_b.py:30' || exit 1
sh "$CHECKS/census.sh" --report 2>&1 | grep -q 'strength-reports=1' || exit 1
exit 0

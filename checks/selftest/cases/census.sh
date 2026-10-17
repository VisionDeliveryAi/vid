#!/bin/sh
# Purpose: selftest case — census.sh must fail a rule row with an unguarded
# site; a zero-denominator ARMED rule must never pass silently; a
# silent-empty extractor must fail; and (polarity check) an owed rule with
# an empty population must PASS as pending — init stays committable.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors tests/invariants
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-901 | seeded unguarded site | printf 'site-a\nsite-b\n' :: printf 'site-a\n' | T1 | tests/invariants/test_rule901.py
```
EOF
touch tests/invariants/test_rule901.py
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-902 | seeded empty denominator | true :: true | T1 | tests/invariants/test_rule902.py
```
EOF
touch tests/invariants/test_rule902.py
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
# a silent-empty extractor must be a failure, never "inactive by inference"
printf '#!/bin/sh\nexit 0\n' > checks/extractors/dead-path.silent.sh
if sh "$CHECKS/census.sh" --report >/dev/null 2>&1 && sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
rm checks/extractors/dead-path.silent.sh
# polarity: an owed rule with an empty population is pending, not fatal
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-903 | ratified, armed later | true :: true | T1 | owed: sites arrive with the first slice
```
EOF
sh "$CHECKS/census.sh" >/dev/null 2>&1 || exit 1
exit 0

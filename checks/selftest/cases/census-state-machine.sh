#!/bin/sh
# Purpose: selftest case — census.sh must convict a state-machine rule row
# (§6.1) on a mutation outside the declared transition table, naming the
# site, and on a guard reading an undeclared state. Polarity: sites moving
# and reading inside the declared vocabulary pass.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p tests/invariants
touch tests/invariants/test_rule911.py
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-911 | state-machine status: draft>published published>archived | printf 'app/a.py:10 draft>published\napp/b.py:22 draft>deleted\n' | T1 | tests/invariants/test_rule911.py
```
EOF
ST=0; OUT=$(sh "$CHECKS/census.sh" 2>&1) || ST=$?
[ "$ST" -ne 0 ] || exit 1
printf '%s\n' "$OUT" | grep -q 'app/b.py:22' || exit 1
# a guard reading a state the table does not declare convicts too
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-911 | state-machine status: draft>published published>archived | printf 'app/a.py:10 draft>published\napp/g.py:7 limbo\n' | T1 | tests/invariants/test_rule911.py
```
EOF
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
# polarity: declared transitions and states pass
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
rule | RULE-911 | state-machine status: draft>published published>archived | printf 'app/a.py:10 draft>published\napp/g.py:7 archived\n' | T1 | tests/invariants/test_rule911.py
```
EOF
sh "$CHECKS/census.sh" >/dev/null 2>&1 || exit 1
# (v0.8.1b) the table's extractor lives under checks/extractors/ as the
# state-machine class: it is the rule row's denominator, never run as a
# class census — so its transition lines are not judged zero-population.
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: state-machine extractor (fixture)\nprintf "app/a.py:10 draft>published\\napp/g.py:7 archived\\n"\n' > checks/extractors/state-machine.status.sh
cat > INVENTORY.md <<'EOF2'
# toy
```vid-inventory
rule | RULE-911 | state-machine status: draft>published published>archived | checks/extractors/state-machine.status.sh | T1 | tests/invariants/test_rule911.py
```
EOF2
sh "$CHECKS/census.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/census.sh" --report 2>&1 | grep -q 'census RULE-911: 2 sites, 2 guarded' || exit 1
# and an undeclared transition through the extractor still convicts
printf '#!/bin/sh\n# Purpose: state-machine extractor (fixture)\nprintf "app/a.py:10 draft>published\\napp/b.py:22 draft>deleted\\n"\n' > checks/extractors/state-machine.status.sh
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
exit 0

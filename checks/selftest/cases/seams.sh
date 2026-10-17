#!/bin/sh
# Purpose: selftest case — seams.sh must reject staged client code touching
# a seam row whose probe is still owed (§3.4), naming the row. Polarity:
# contract tests under tests/ are the probe's own artifact and pass while
# owed; a probed seam frees the client code.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
seam | SEAM-901 | examplepay | card charges | chosen: D-001 | credentials: not-yet | probe: owed | evidence: owed | quirks: none yet | match: examplepay
```
EOF
mkdir -p app tests/invariants
printf '# Purpose: seeded violation\nimport examplepay\n' > app/pay.py
git add -A
if sh "$CHECKS/seams.sh" >/dev/null 2>&1; then exit 1; fi
# polarity: a contract test touching the token while owed is the probe paying itself
git rm -q --cached app/pay.py; rm app/pay.py
printf '# Purpose: contract test over the captured response\nimport examplepay\n' > tests/invariants/test_seam901_contract.py
git add -A
sh "$CHECKS/seams.sh" >/dev/null 2>&1 || exit 1
# polarity: probed seam frees the client code
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
seam | SEAM-901 | examplepay | card charges | chosen: D-001 | credentials: not-yet | probe: probed(2026-08-24) | evidence: tests/invariants/test_seam901_contract.py + tests/invariants/samples/examplepay.json | quirks: none yet | match: examplepay
```
EOF
printf '# Purpose: client\nimport examplepay\n' > app/pay.py
git add -A
sh "$CHECKS/seams.sh" >/dev/null 2>&1 || exit 1
exit 0

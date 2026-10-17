#!/bin/sh
# Purpose: selftest case — inventory.sh must JOIN a proved-red stamp, not
# merely see it (v0.8.1d; H-17 measured 22 rows citing a file absent at the
# stamped sha and 34 citing a file that never names the row; G-08 measured
# `proved-red: TBD-never-happened` passing). Convicts: a sha resolving to
# no commit; a sha at which the cited file is absent; a sha at which the
# file never names the row or its REQ. Polarity: a stamp where the file
# existed and named the REQ passes, default and --strict; default mode
# joins only the rows this commit stages.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p app tests/invariants
printf '# Purpose: scaffold\n' > app/main.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
ROOT=$(git rev-parse HEAD)
printf '# Purpose: ledger test for REQ-901\ndef test_req_901():\n    assert False\n' > tests/invariants/test_req901.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm 'test red'
RED=$(git rev-parse HEAD)
printf '# Purpose: ledger test naming nothing\ndef test_other():\n    assert False\n' > tests/invariants/test_req901.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm 'renamed away'
NONAME=$(git rev-parse HEAD)
git checkout -q "$RED" -- tests/invariants/test_req901.py
git -c user.email=vid@selftest -c user.name=vid commit -qm 'restored' >/dev/null

inv() { printf '# toy\n```vid-inventory\nROW-901 | behavior | REQ-901 | n/a | n/a | one consent | REQ-901 | tests/invariants/test_req901.py | proved-red: %s\n```\n' "$1" > INVENTORY.md; git add INVENTORY.md; }

# polarity: stamped where the file existed and named the REQ
inv "$RED"
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1
# 1. a sha that resolves to no commit
inv cafe123
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'resolves to no commit' || exit 1
# 2. a sha at which the cited file did not exist
inv "$ROOT"
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'does not exist at that commit' || exit 1
# 3. a sha at which the file never names the row or its REQ
inv "$NONAME"
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'never names the row' || exit 1
# scope: default mode joins only staged rows — commit the bad row, then an
# unrelated staged change passes default and --strict still convicts.
git -c user.email=vid@selftest -c user.name=vid commit -qm 'bad stamp landed elsewhere' >/dev/null
printf '# Purpose: unrelated\n' > app/other.py; git add app/other.py
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
if sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1; then exit 1; fi
exit 0

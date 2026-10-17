#!/bin/sh
# Purpose: selftest case — inventory.sh must resolve a row's cited test path
# against the commit under construction (index, then HEAD), never the
# working tree (v0.8.1d; promotion candidate #4: a row landed citing a file
# first present in history two commits later, and the court reported
# compliance it had not checked). Convicts a worktree-only citation and a
# directory cited as a test; polarity: staged → passes; committed → passes.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p tests/invariants
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
printf '# toy\n```vid-inventory\nROW-931 | behavior | REQ-931 | n/a | n/a | home renders | REQ-931 | tests/invariants/test_req931.py\n```\n' > INVENTORY.md
git add INVENTORY.md
# the test exists in the working tree only
printf '# Purpose: ledger test REQ-931\n' > tests/invariants/test_req931.py
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'worktree-only' || exit 1
# staged → the commit under construction carries it
git add tests/invariants/test_req931.py
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
# committed, index clean → HEAD carries it
git -c user.email=vid@selftest -c user.name=vid commit -qm 'test then row' >/dev/null
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
# a directory is not a test
printf '# toy\n```vid-inventory\nROW-931 | behavior | REQ-931 | n/a | n/a | home renders | REQ-931 | tests/invariants\n```\n' > INVENTORY.md
git add INVENTORY.md
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
exit 0

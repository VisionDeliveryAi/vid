#!/bin/sh
# Purpose: selftest case — the Tests-by: trail (v0.9.2 spec 3.1c, R1/R5;
# §7.4). Real commits in a temporary repository with the commit-msg hook
# installed: a commit adding a file under tests/invariants/ with no
# `Tests-by:` trailer is refused; with `Tests-by: test-author <date>
# <batch>` it is accepted; `Tests-by: init` and `Tests-by: builder` are
# refused; a commit that adds no ledger file needs none; a commit that only
# MODIFIES a ledger file needs none (the rule is on additions). The
# Decisions: rule stands beside it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p hooks app tests/invariants
cp "$CHECKS/hooks/commit-msg" hooks/commit-msg && chmod +x hooks/commit-msg
git config core.hooksPath hooks
G='git -c user.email=vid@selftest -c user.name=vid'
printf '# Purpose: toy\n' > app/main.py
git add -A && $G commit -qm 'root

Decisions: none — nothing surprising'
ROOT=$(git rev-parse HEAD)
# 1. a ledger addition with no trailer is refused
printf '# REQ-001 ROW-001\ndef test_req001():\n    assert False\n' > tests/invariants/test_req001.py
git add tests/invariants/test_req001.py
if $G commit -qm 'ledger test

Decisions: none — nothing surprising' 2>err.txt; then echo 'hook-tests-by: a ledger addition without Tests-by: landed' >&2; exit 1; fi
grep -q 'no valid "Tests-by:" trailer' err.txt || { cat err.txt >&2; exit 1; }
[ "$(git rev-parse HEAD)" = "$ROOT" ] || exit 1
# 2. init and builder are not values
if $G commit -qm 'ledger test

Decisions: none — nothing surprising
Tests-by: init' 2>err.txt; then echo 'hook-tests-by: Tests-by: init landed' >&2; exit 1; fi
grep -q 'not a value' err.txt || exit 1
if $G commit -qm 'ledger test

Decisions: none — nothing surprising
Tests-by: builder' 2>/dev/null; then exit 1; fi
# 3. the pass's trailer is accepted
$G commit -qm 'ledger test

Decisions: none — nothing surprising
Tests-by: test-author 2026-09-21 accounts' || { echo 'hook-tests-by: the valid trailer was refused' >&2; exit 1; }
[ "$(git rev-parse HEAD)" != "$ROOT" ] || exit 1
# 4. a commit adding no ledger file needs no trailer
printf '# Purpose: toy, more\n' > app/more.py
git add app/more.py
$G commit -qm 'app work

Decisions: none — nothing surprising' || exit 1
# 5. modifying an existing ledger file needs none (the builder greens; additions are the pass's)
printf '# REQ-001 ROW-001\ndef test_req001():\n    assert True\n' > tests/invariants/test_req001.py
git add tests/invariants/test_req001.py
$G commit -qm 'green

Decisions: none — nothing surprising' || { echo 'hook-tests-by: a ledger modification was refused' >&2; exit 1; }
# 6. the Decisions: rule still stands
printf '# REQ-002\n' > tests/invariants/test_req002.py
git add tests/invariants/test_req002.py
if $G commit -qm 'no decisions line

Tests-by: test-author 2026-09-21 accounts' 2>err.txt; then exit 1; fi
grep -q 'no "Decisions:" line' err.txt || exit 1
exit 0

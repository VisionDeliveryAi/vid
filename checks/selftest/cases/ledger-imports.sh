#!/bin/sh
# Purpose: selftest case — imports.sh (enforce mode) must reject a ledger
# test that imports application internals (v0.8.1d, behavior-keying as a
# court): a tests/invariants/test* file, or any generator under tests/,
# importing a seam-table module that does not name tests/invariants among
# its dependents. Polarity: the harness entry that declares it passes; a
# helper under tests/invariants/ not named test* passes; the non-law tier
# tests/scaffolding/ passes.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
cat > ARCHITECTURE.md <<'EOF2'
Import court: enforce

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core | domain logic | `core` | app |
| 2 | app | delivery, the harness entry | `app` | tests/invariants |
EOF2
mkdir -p tests/invariants tests/generators tests/scaffolding
stage() { # $1=path $2=import line
  printf '# Purpose: seeded\n%s\n' "$2" > "$1"; git add "$1"
}
# 1. a ledger test importing internals — rejected
stage tests/invariants/test_a.py 'import core'
if sh "$CHECKS/imports.sh" >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/imports.sh" 2>&1 | grep -q 'a ledger test enters the product only through its public surface' || exit 1
git rm -q --cached tests/invariants/test_a.py
# 2. a generator under tests/ importing internals — rejected
stage tests/generators/corpus.py 'from core import listings'
if sh "$CHECKS/imports.sh" >/dev/null 2>&1; then exit 1; fi
git rm -q --cached tests/generators/corpus.py
# polarity: the harness entry declares tests/invariants — passes
stage tests/invariants/test_b.py 'import app'
sh "$CHECKS/imports.sh" >/dev/null 2>&1 || exit 1
git rm -q --cached tests/invariants/test_b.py
# polarity: a helper (not test*) under tests/invariants/ is the exception surface
stage tests/invariants/helpers.py 'import core'
sh "$CHECKS/imports.sh" >/dev/null 2>&1 || exit 1
git rm -q --cached tests/invariants/helpers.py
# polarity: the non-law tier is exempt
stage tests/scaffolding/test_c.py 'import core'
sh "$CHECKS/imports.sh" >/dev/null 2>&1 || exit 1
git rm -q --cached tests/scaffolding/test_c.py
# report-only mode lists, never fails
printf 'Import court: report-only\n' > ARCHITECTURE.md
cat >> ARCHITECTURE.md <<'EOF2'

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core | domain logic | `core` | app |
EOF2
stage tests/invariants/test_a.py 'import core'
sh "$CHECKS/imports.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/imports.sh" 2>&1 | grep -q '1 boundary violation' || exit 1
exit 0

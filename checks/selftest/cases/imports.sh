#!/bin/sh
# Purpose: selftest case — imports.sh (enforce mode) must reject a staged
# import from an undeclared dependent across a seam. Exits 0 only if the
# court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
cat > ARCHITECTURE.md <<'EOF'
Import court: enforce

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core | domain logic | `core` | none |
| 2 | app | delivery | `app` | none |
EOF
mkdir -p app && printf '# Purpose: seeded violation\nimport core\n' > app/main.py
git add -A
if sh "$CHECKS/imports.sh" >/dev/null 2>&1; then exit 1; fi
exit 0

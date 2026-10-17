#!/bin/sh
# Purpose: selftest case — conformance.sh must reject a staged addition
# mentioning a forbidden term. Exits 0 only if the court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '```vid-allowed-extensions\n.py .md\n```\n```vid-forbidden\nforbidden_dep_xyz\n```\n' > BASELINE.md
mkdir -p app && printf '# Purpose: seeded violation\nimport forbidden_dep_xyz\n' > app/bad.py
git add -A
if sh "$CHECKS/conformance.sh" >/dev/null 2>&1; then exit 1; fi
exit 0

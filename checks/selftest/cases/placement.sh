#!/bin/sh
# Purpose: selftest case — placement.sh must reject a staged file outside the
# placement map. Exits 0 only if the court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p rogue && printf '# Purpose: seeded violation\n' > rogue/outlaw.py
git add -A
if sh "$CHECKS/placement.sh" >/dev/null 2>&1; then exit 1; fi
exit 0

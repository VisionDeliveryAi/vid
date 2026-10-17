#!/bin/sh
# Purpose: selftest case — pre-commit must refuse to run while a law source
# carries UNSTAGED edits: the courts judge with the working tree, so an
# unstaged law edit would judge this commit by law that is never committed.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks app
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh; do
  cp "$CHECKS/$c" checks/ 2>/dev/null || true
done
cp "$CHECKS/lawfiles" checks/lawfiles
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
git add -A
git -c user.email=vid@selftest -c user.name=vid commit -qm 'root'
# widen the placement block WITHOUT staging it; stage only the file it admits
printf '```vid-placement\napp/\nrogue/\n```\n' > CLAUDE.md
mkdir -p rogue && printf '# Purpose: seeded violation\n' > rogue/outlaw.py
git add rogue/outlaw.py
if VID_ROLE=fix sh "$CHECKS/hooks/pre-commit" >/dev/null 2>&1; then exit 1; fi
exit 0

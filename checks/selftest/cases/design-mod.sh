#!/bin/sh
# Purpose: selftest case — modifying a ratified design file alongside app
# code must be rejected: design/ has ledger standing, and law changes alone.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks app design/screens
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh; do
  cp "$CHECKS/$c" checks/ 2>/dev/null || true
done
cp "$CHECKS/lawfiles" checks/lawfiles
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh .html\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<html>v1</html>\n' > design/screens/p01.html
git add -A
git -c user.email=vid@selftest -c user.name=vid commit -qm 'root'
# rewrite the canvas to match the build, alongside the build
printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<html>v2 rewritten to match the code</html>\n' > design/screens/p01.html
printf '# Purpose: app\n' > app/main.py
git add -A
if VID_ROLE=fix sh "$CHECKS/hooks/pre-commit" >/dev/null 2>&1; then exit 1; fi
exit 0

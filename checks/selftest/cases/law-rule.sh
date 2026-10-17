#!/bin/sh
# Purpose: selftest case — the pre-commit law-change rule must reject a commit
# that widens a vid-* machine block alongside any other file (§4.1). The
# scratch repo carries real courts so a neutered law rule would let the
# mixed commit pass — which this case then reports as failure to convict.
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
# widen the placement block AND stage an unrelated file the widening admits
printf '```vid-placement\napp/\nrogue/\n```\n' > CLAUDE.md
mkdir -p rogue && printf '# Purpose: seeded violation\n' > rogue/outlaw.py
git add -A
if VID_ROLE=fix sh "$CHECKS/hooks/pre-commit" >/dev/null 2>&1; then exit 1; fi
exit 0

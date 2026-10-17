#!/bin/sh
# Purpose: selftest case — an ADDED skip marker over a row-bound ledger test
# alongside other work must be rejected (neutering by addition is a law
# change, same as deleting the assertion).
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks app tests/invariants
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh; do
  cp "$CHECKS/$c" checks/ 2>/dev/null || true
done
cp "$CHECKS/lawfiles" checks/lawfiles
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
printf '# Purpose: ledger seed\ndef test_req001():\n    assert False\n' > tests/invariants/test_req001.py
git add -A
git -c user.email=vid@selftest -c user.name=vid commit -qm 'root'
printf '# Purpose: ledger seed\nimport pytest\n@pytest.mark.skip(reason="later")\ndef test_req001():\n    assert False\n' > tests/invariants/test_req001.py
printf '# Purpose: app\n' > app/main.py
git add -A
if VID_ROLE=fix sh "$CHECKS/hooks/pre-commit" >/dev/null 2>&1; then exit 1; fi
exit 0

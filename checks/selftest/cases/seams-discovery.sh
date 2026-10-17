#!/bin/sh
# Purpose: selftest case — seams.sh's discovery door (§3.2) must reject a
# staged outbound destination no seam row covers. Polarity: a covering seam
# row (even owed, provided its tokens are not in the staged source) and a
# ratified `seam` exception row both stand.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '# toy\n```vid-inventory\nROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | owed: scaffold\n```\n' > INVENTORY.md
mkdir -p app
printf '# Purpose: seeded violation\nFEED_URL = "https://api.somefeed.io/v1/items"\n' > app/feed.py
git add -A
if sh "$CHECKS/seams.sh" >/dev/null 2>&1; then exit 1; fi
# polarity: a seam row covering the host stands (probed, so owed-touch is quiet)
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
ROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | owed: scaffold
seam | SEAM-902 | somefeed | listings feed | chosen: D-002 | credentials: never | probe: probed(2026-08-24) | evidence: tests/invariants/test_seam902_contract.py + tests/invariants/samples/somefeed.json | quirks: none yet | match: somefeed.io
```
EOF
git add -A
sh "$CHECKS/seams.sh" >/dev/null 2>&1 || exit 1
# polarity: a content link that is no outbound call takes a `seam` exception row
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
ROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | owed: scaffold
exception | EXC-901 | somefeed.io | seam | footer content link, not an outbound call
```
EOF
git add -A
sh "$CHECKS/seams.sh" >/dev/null 2>&1 || exit 1
exit 0

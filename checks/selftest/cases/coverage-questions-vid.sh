#!/bin/sh
# Purpose: selftest case — the open-question count reads the project's live text only (FIX-BATCH-T1 §13, B-10). A toy with one
# live VID-QUESTION marker in PRD.md and two copies of it under .vid/ (a rendered page and an old sitting file): coverage.sh
# counts one open marker, with and without --rows. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "coverage-questions-vid: $*" >&2; printf '%s\n' "${OUT:-}" | tail -4 >&2; exit 1; }
cd "$T"; mkdir -p checks app tests/invariants .vid/pages .vid/sittings
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
cat > PRD.md <<'PRD'
# Toy — PRD
grammar: 0.9.1

## Items

```vid-prd
REQ-001 | functional | T1 | A visitor sees the home page. | fail-if: the home page does not render | serves: the door | authority: authoritative | source: seed | phase: pilot
```

## Open decisions

VID-QUESTION: OQ-1 — does the home page greet by name? (REQ-001)
PRD
printf '# toy\n```vid-inventory\nROW-001 | surface | / | anonymous | n/a | the home page renders | REQ-001 | tests/invariants/test_home.py\n```\n' > INVENTORY.md
printf '# Purpose: toy home — REQ-001\n' > app/home.py; printf '# REQ-001 ROW-001\n' > tests/invariants/test_home.py
printf '<p>VID-QUESTION: OQ-1 — does the home page greet by name? (REQ-001)</p>\n' > .vid/pages/prd.html
printf 'VID-QUESTION: OQ-1 — does the home page greet by name? (REQ-001)\n' > .vid/sittings/pause-1.md
OUT=$(sh checks/coverage.sh 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'open VID-QUESTION markers: 1 ' || fail 'unscoped: the count is not 1'
printf 'ROW-001\nREQ-001\n' > scope.txt
OUT=$(sh checks/coverage.sh --rows scope.txt 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'open VID-QUESTION markers: 1 ' || fail 'scoped: the count is not 1'
echo 'coverage-questions-vid: ok'

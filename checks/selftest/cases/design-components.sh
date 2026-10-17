#!/bin/sh
# Purpose: selftest case — the components canvas (v0.9.1 spec 3.7a, R12-iv).
# A 0.9.1 pack with no C00 canvas convicts at the join (the manifest must
# carry C00's rows when the brief carries the grammar line); with C00's row
# and canvas it acquits; a CSS rule block citing `(C00/card-default —
# REQ-046)` passes design-cite.sh at the commit court and coverage.sh
# --strict (a valid component citation is never "uncited"); a pre-0.9.1
# brief without C00 is reported, never convicted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks app tests/invariants design/screens
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/design-join.sh" "$CHECKS/design-cite.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Toy — PRD\ngrammar: 0.9.1\n\n## Items\n\n```vid-prd\nREQ-046 | functional | T1 | A result card shows the employer logo or a fallback, the publication age, and a New label within seven days. | fail-if: a card omits publication age, or a job published eight days ago carries New | serves: cards carry what candidates scan | authority: authoritative | source: seed | phase: pilot\n```\n' > PRD.md
printf '<!-- @screen P02 state=populated reqs=REQ-046 -->\n<section>{{ cards }}</section>\n' > design/screens/p02.html
brief() { printf '# Toy — design brief\ngrammar: 0.9.1\n\n```vid-design-manifest\n%s\n```\n' "$1" > DESIGN-BRIEF.md; }
# (1) a 0.9.1 manifest without C00 rows convicts, naming the missing canvas
brief 'P02 | populated | REQ-046 | pins: card count = page size; publication age on every card; New within seven days'
if sh checks/design-join.sh DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then echo 'design-components: a 0.9.1 pack without C00 passed the join' >&2; exit 1; fi
sh checks/design-join.sh DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'no components canvas' || exit 1
# (2) with C00's row and canvas it acquits
brief 'P02 | populated | REQ-046 | pins: card count = page size; publication age on every card; New within seven days
C00 | card-default | REQ-046 | pins: logo or fallback; publication age; New within seven days'
printf '<!-- @screen C00 state=card-default reqs=REQ-046 -->\n<article>{{ card }}</article>\n' > design/screens/c00.html
sh checks/design-join.sh DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || { echo 'design-components: the pack with C00 does not acquit' >&2; sh checks/design-join.sh DESIGN-BRIEF.md design/screens 2>&1 | tail -3 >&2; exit 1; }
# (3) a rule block citing the component passes the citation court and the coverage join
printf '/* Result card (C00/card-default — REQ-046) */\n.card { color: var(--ink); }\n/* Results page (P02/populated — REQ-046) */\n.results { display: grid; }\n' > app/styles.css
printf '# Purpose: results — REQ-046\n' > app/results.py
printf '# REQ-046: cards carry age and New\n' > tests/invariants/test_cards.py
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
ROW-001 | surface | /results | anonymous | P02/populated | card count = page size; publication age on every card; New within seven days | REQ-046 | tests/invariants/test_cards.py
ROW-002 | surface | card | anonymous | C00/card-default | logo or fallback; publication age; New within seven days | REQ-046 | tests/invariants/test_cards.py
```
INV
sh checks/design-cite.sh --strict >/dev/null 2>&1 || { echo 'design-components: the C00 citation failed design-cite --strict' >&2; sh checks/design-cite.sh --strict 2>&1 | tail -3 >&2; exit 1; }
sh checks/coverage.sh --strict >/dev/null 2>&1 || { echo 'design-components: coverage --strict failed with the C00 citation' >&2; sh checks/coverage.sh --strict 2>&1 | tail -4 >&2; exit 1; }
# (4) a pre-0.9.1 pack — no C00 canvas, a brief without the grammar line — is reported, never convicted
rm design/screens/c00.html
printf '# Toy — design brief\n\n```vid-design-manifest\nP02 | populated | REQ-046\n```\n' > DESIGN-BRIEF.md
sh checks/design-join.sh DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
sh checks/design-join.sh DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'note: the manifest carries no C00 rows (pre-0.9.1 brief' || exit 1
exit 0

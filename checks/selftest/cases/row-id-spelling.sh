#!/bin/sh
# Purpose: selftest case — the row engine joins a case that names its row in
# a test function's spelling (v0.9.6, a live project's replay: 955 of 1,239 cases
# named `test_ROW_NNNN_…`). Under grammar 0.9.3, a full receipt whose cases
# are `tests/invariants/t.py::test_ROW_001_…` (passed) and
# `…::test_ROW_002_…` (failed): `metrics.sh row-state` reads ROW-001 green
# (unverdicted) and ROW-002 red with its case named, never absent; ROW-003,
# with no case, stays absent. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q
mkdir -p checks/extractors .vid/ledger-results tests/invariants
cp "$CHECKS/metrics.sh" checks/
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)".*/case \\1 \\2 0.1/p'"'"' "$1"\n' > checks/extractors/results.sh
printf '# ledger\n' > tests/invariants/t.py
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | a | anon | - | x | REQ-001 | tests/invariants/t.py\nROW-002 | behavior | b | anon | - | x | REQ-002 | tests/invariants/t.py\nROW-003 | behavior | c | anon | - | x | REQ-003 | tests/invariants/t.py\n```\n' > INVENTORY.md
printf '.vid/\n' > .gitignore
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
S=$(git rev-parse --short=12 HEAD)
printf '<r>\n<case name="tests/invariants/t.py::test_ROW_001_the_first" status="passed"/>\n<case name="tests/invariants/t.py::test_ROW_002_the_second" status="failed"/>\n</r>\n' > ".vid/ledger-results/$S.full.xml"
OUT=$(sh checks/metrics.sh row-state ROW-001 ROW-002 ROW-003)
fail() { echo "row-id-spelling: $*" >&2; printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^ROW-001: unverdicted (green, no verdict)' || fail 'test_ROW_001_… did not join ROW-001'
printf '%s\n' "$OUT" | grep -q '^ROW-002: red (not green: tests/invariants/t.py::test_ROW_002_the_second failed)' || fail 'test_ROW_002_… did not join ROW-002'
printf '%s\n' "$OUT" | grep -q '^ROW-003: red (absent from' || fail 'ROW-003 found a case it does not have'
exit 0

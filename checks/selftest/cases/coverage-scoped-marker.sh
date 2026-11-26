#!/bin/sh
# Purpose: selftest case — scoped coverage judges the markers its scoped rows bind (FIX-BATCH-T1 §1, B-1b). A toy with two
# drawn screens, ROW-001 binding S01/default and ROW-002 binding S02/default, neither cited by any implementation. With a
# scope file holding ROW-001 and its item alone, `coverage.sh --rows` names S01/default a GAP and leaves S02/default out
# (only an out-of-scope row binds it); without --rows both are GAPs. Convicts on the read that split nothing, which made
# every bound marker out of scope. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "coverage-scoped-marker: $*" >&2; printf '%s\n' "${OUT:-}" | tail -8 >&2; exit 1; }
cd "$T"
mkdir -p checks app tests/invariants design/screens
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
cat > PRD.md <<'PRD'
# Toy — PRD
grammar: 0.9.1

## Items

```vid-prd
REQ-001 | functional | T1 | A visitor sees the first screen. | fail-if: the first screen does not render | serves: the door | authority: authoritative | source: seed | phase: pilot
REQ-002 | functional | T1 | A visitor sees the second screen. | fail-if: the second screen does not render | serves: the door | authority: authoritative | source: seed | phase: pilot
```
PRD
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
ROW-001 | surface | / | anonymous | S01/default | the first screen renders | REQ-001 | tests/invariants/test_one.py
ROW-002 | surface | /two | anonymous | S02/default | the second screen renders | REQ-002 | tests/invariants/test_two.py
```
INV
printf '# Purpose: toy — REQ-001 REQ-002\n' > app/main.py
printf '# REQ-001 ROW-001\n' > tests/invariants/test_one.py
printf '# REQ-002 ROW-002\n' > tests/invariants/test_two.py
printf '<!-- @screen S01 state=default reqs=REQ-001 -->\n<section>one</section>\n' > design/screens/s01.html
printf '<!-- @screen S02 state=default reqs=REQ-002 -->\n<section>two</section>\n' > design/screens/s02.html
printf 'ROW-001\nREQ-001\n' > scope.txt
OUT=$(sh checks/coverage.sh --rows scope.txt 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'GAP  S01/default drawn but not cited' || fail 'scoped: the scoped row'"'"'s uncited marker S01/default is no GAP'
printf '%s\n' "$OUT" | grep -q 'S02/default' && fail 'scoped: S02/default, bound only by an out-of-scope row, was judged'
OUT=$(sh checks/coverage.sh 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'GAP  S01/default drawn but not cited' && printf '%s\n' "$OUT" | grep -q 'GAP  S02/default drawn but not cited' || fail 'unscoped: both uncited markers are not GAPs'
echo 'coverage-scoped-marker: ok'

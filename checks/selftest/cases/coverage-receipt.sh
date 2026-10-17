#!/bin/sh
# Purpose: selftest case — the execution receipt (v0.9.2 spec 3.6, R9; §7.2).
# In a toy repository under the 0.9.2 inventory grammar, with a fixture
# results reader (checks/extractors/results.sh, the generated shape): (1) an
# empty test file holding a REQ comment and no report → --strict names the
# row and prints `receipt: none`; (2) a report with the cited case skipped →
# --strict names the row as skipped; (3) an export-backed full report for
# HEAD with the case passed → --strict passes; (4) a `.live.` report alone →
# not accepted; (5) a report with nothing collected → not green; (6) two rows
# for one REQ, one passed and one skipped → --strict fails naming the skipped
# row; (7) the same tree under a legacy block (no grammar line) keeps the
# citation grep and passes — no retroactive conviction. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks/extractors app tests/invariants .vid/ledger-results
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" checks/
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Toy\n\n## Items\n\n```vid-prd\nREQ-001 | functional | T1 | P1 | The home page renders. | fail-if: it does not | serves: x | authority: authoritative | source: seed\n```\n' > PRD.md
printf '# Purpose: toy — REQ-001\n' > app/home.py
printf '# REQ-001 ROW-001 — an empty file holding one REQ comment\n' > tests/invariants/test_home.py
# the fixture reader: one <case name= status= time=/> element per line
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture) — the report's cases as `case <id> <status> <seconds>` lines.
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1" | tr ' ' ' '
RD
inv() { printf '# toy\n```vid-inventory\n%s%s\n```\n' "$1" "$2" > INVENTORY.md; }
G='grammar: 0.9.2
'
inv "$G" 'ROW-001 | surface | / | anonymous | n/a | the home page renders | REQ-001 | tests/invariants/test_home.py'
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
SHA=$(git rev-parse --short=12 HEAD)
report() { printf '<report>\n%s</report>\n' "$1" > ".vid/ledger-results/$2"; }

# 1. the empty-file probe: no report → strict names the row, receipt: none
if sh checks/coverage.sh --strict >out.txt 2>&1; then echo 'coverage-receipt: the empty REQ-comment file passed strict with no receipt' >&2; exit 1; fi
grep -q '^receipt: none — materialised rows unverified' out.txt || { cat out.txt >&2; exit 1; }
grep -q 'RED  ROW-001 (REQ-001) — absent from the receipt' out.txt || exit 1
grep -qE '^REQ-001 .* no .*GAP' out.txt || exit 1
# 4. a .live. report alone is never certification
report '<case name="tests/invariants/test_home.py::test_home[ROW-001]" status="passed" time="0.2"/>
' "$SHA.live.sel-12345.xml"
if sh checks/coverage.sh --strict >out.txt 2>&1; then exit 1; fi
grep -q '^receipt: none' out.txt || exit 1
# 2. the cited case skipped → named
report '<case name="tests/invariants/test_home.py::test_home[ROW-001]" status="skipped" time="0.0"/>
' "$SHA.full.xml"
if sh checks/coverage.sh --strict >out.txt 2>&1; then echo 'coverage-receipt: a skipped case passed strict' >&2; exit 1; fi
grep -q "^receipt: .vid/ledger-results/$SHA.full.xml cases=1 passed=0 failed=0 skipped=1 error=0" out.txt || { cat out.txt >&2; exit 1; }
grep -q 'RED  ROW-001 (REQ-001) — not green: tests/invariants/test_home.py::test_home\[ROW-001\] skipped' out.txt || exit 1
# 5. nothing collected is not green
report '' "$SHA.full.xml"
if sh checks/coverage.sh --strict >out.txt 2>&1; then exit 1; fi
grep -q 'nothing collected (0 cases): not green' out.txt || exit 1
# 3. the case passed in an export-backed full report for HEAD → strict passes; both engines and parameters count
report '<case name="tests/invariants/test_home.py::test_home[ROW-001-engine-a]" status="passed" time="0.2"/>
<case name="tests/invariants/test_home.py::test_home[ROW-001-engine-b]" status="passed" time="0.3"/>
' "$SHA.full.xml"
sh checks/coverage.sh --strict >out.txt 2>&1 || { echo 'coverage-receipt: a passed receipt failed strict' >&2; cat out.txt >&2; exit 1; }
grep -q 'cases=2 passed=2' out.txt || exit 1
# one engine failing fails the row
report '<case name="tests/invariants/test_home.py::test_home[ROW-001-engine-a]" status="passed" time="0.2"/>
<case name="tests/invariants/test_home.py::test_home[ROW-001-engine-b]" status="error" time="0.3"/>
' "$SHA.full.xml"
if sh checks/coverage.sh --strict >out.txt 2>&1; then exit 1; fi
grep -q 'engine-b\] error' out.txt || exit 1
# a report for another tree is not HEAD's
mv ".vid/ledger-results/$SHA.full.xml" .vid/ledger-results/000000000000.full.xml
if sh checks/coverage.sh --strict >out.txt 2>&1; then exit 1; fi
grep -q '^receipt: none' out.txt || exit 1
rm .vid/ledger-results/000000000000.full.xml
# 6. two rows for one REQ, one passed and one skipped → the skipped row named
inv "$G" 'ROW-001 | surface | / | anonymous | n/a | the home page renders | REQ-001 | tests/invariants/test_home.py
ROW-002 | behavior | REQ-001 | n/a | n/a | the title is the product name | REQ-001 | tests/invariants/test_home.py'
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm 'two rows'
SHA=$(git rev-parse --short=12 HEAD)
report '<case name="tests/invariants/test_home.py::test_home[ROW-001]" status="passed" time="0.2"/>
<case name="tests/invariants/test_home.py::test_title[ROW-002]" status="skipped" time="0.0"/>
' "$SHA.full.xml"
if sh checks/coverage.sh --strict >out.txt 2>&1; then echo 'coverage-receipt: one passed and one skipped row passed strict' >&2; exit 1; fi
grep -q 'RED  ROW-002 (REQ-001) — not green: .*test_title\[ROW-002\] skipped' out.txt || { cat out.txt >&2; exit 1; }
grep -q 'RED  ROW-001' out.txt && exit 1
# a case keyed to the REQ id (no row id) pays the row too
report '<case name="tests/invariants/test_home.py::test_home[ROW-001]" status="passed" time="0.2"/>
<case name="tests/invariants/test_home.py::test_title_REQ-001" status="passed" time="0.1"/>
' "$SHA.full.xml"
sh checks/coverage.sh --strict >out.txt 2>&1 || { cat out.txt >&2; exit 1; }
# 7. the legacy block keeps the grep under strict — no receipt read, no retroactive conviction
rm -f .vid/ledger-results/*
inv '' 'ROW-001 | surface | / | anonymous | n/a | the home page renders | REQ-001 | tests/invariants/test_home.py'
sh checks/coverage.sh --strict >out.txt 2>&1 || { echo 'coverage-receipt: the legacy block was convicted' >&2; cat out.txt >&2; exit 1; }
grep -q '^receipt:' out.txt && exit 1
exit 0

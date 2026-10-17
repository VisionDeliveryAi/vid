#!/bin/sh
# Purpose: selftest case — the strength class at function grain (v0.9.2 spec
# 3.9a, R13; §7.5). A toy strength extractor over a fixture ledger file and
# three rows, through checks/census.sh: (1) at FUNCTION grain a Tier-0 row
# bound to an Existence-only function is one STR report even though the
# same file holds a value-level assertion in another function; (2) the same
# file read at FILE grain reports nothing — the mutation a generated
# extractor's case must fail on, asserted here as the shape that must not
# ship; (3) a row whose cited file holds no function naming it is reported
# `unbound-row`; the class stays report-only (exit 0). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors tests/invariants
# the fixture ledger file: one Existence-only function for a Tier-0 row, one value-level function for another row
cat > tests/invariants/ledger.sh <<'LEDGER'
# Purpose: fixture ledger (toy assertion vocabulary: assert_present = existence, assert_status = status, assert_equal = value)
test_ROW_001_tier0_guard() {
  page=$(harness_get /account)
  assert_present "$page" delete-control
}
test_ROW_002_page_size() {
  page=$(harness_get /jobs)
  assert_status "$page" 200
  assert_equal "$(count "$page" job-card)" 3
}
LEDGER
# the rows: ROW-001 Tier-0, ROW-002 Tier-1, ROW-003 Tier-0 citing the file with no function naming it
cat > rows.txt <<'ROWS'
ROW-001 T0 tests/invariants/ledger.sh
ROW-002 T1 tests/invariants/ledger.sh
ROW-003 T0 tests/invariants/ledger.sh
ROWS
# the toy extractor, FUNCTION grain: the scan is the function whose name carries the row id
cat > checks/extractors/strength.toy.sh <<'EOF2'
#!/bin/sh
# Purpose: fixture strength extractor at function grain (v0.9.2 3.9a): each row-bound test is the function naming the row id.
GRAIN=${GRAIN:-function}
while read -r row tier file; do
  [ -f "$file" ] || { echo "orphan $file unbound-row $row (no such file)"; continue; }
  fn=$(printf '%s' "$row" | tr '-' '_')
  if [ "$GRAIN" = function ]; then
    body=$(awk -v fn="$fn" '$0 ~ "^[A-Za-z0-9_]*" fn "[A-Za-z0-9_]*\\(\\)" { on = 1 } on { print } on && /^}/ { exit }' "$file")
    [ -n "$body" ] || { echo "orphan $file unbound-row $row"; continue; }
    line=$(grep -n "$fn" "$file" | head -n 1 | cut -d: -f1)
  else
    body=$(cat "$file"); line=1
  fi
  strongest=existence
  printf '%s\n' "$body" | grep -q 'assert_status' && strongest=status
  printf '%s\n' "$body" | grep -qE 'assert_equal|assert_behaviour' && strongest=value
  if [ "$tier" = T0 ] && [ "$strongest" = existence ]; then echo "orphan $file:$line $row strongest=existence"; else echo "ok $row"; fi
done < rows.txt
EOF2
ST=0; OUT=$(sh "$CHECKS/census.sh" 2>&1) || ST=$?
[ "$ST" -eq 0 ] || { printf '%s\n' "$OUT" >&2; echo 'strength-grain: a report-only class failed the commit' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^STR .*tests/invariants/ledger.sh:2 .*ROW-001 strongest=existence' || { printf '%s\n' "$OUT" >&2; echo 'strength-grain: the Existence-only Tier-0 function was not reported at function grain' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^STR .*unbound-row ROW-003' || { printf '%s\n' "$OUT" >&2; echo 'strength-grain: the row bound to no function was not reported unbound-row' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'strength-reports=2' || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'ROW-002' && { echo 'strength-grain: the value-level row was reported' >&2; exit 1; }
# the mutation that must fail: at FILE grain the value-level assertion elsewhere in the file lifts the Tier-0 row — nothing is reported
OUT2=$(GRAIN=file sh "$CHECKS/census.sh" 2>&1) || true
printf '%s\n' "$OUT2" | grep -q 'ROW-001' && { echo 'strength-grain: file grain reported the row — the fixture no longer shows the miss' >&2; exit 1; }
printf '%s\n' "$OUT2" | grep -q 'strength-reports=0' || { printf '%s\n' "$OUT2" >&2; exit 1; }
exit 0

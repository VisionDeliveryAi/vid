#!/bin/sh
# Purpose: selftest case — a harness-only fix re-grades rows held under the
# new reasons when their latest breach is the harness (v0.9.7.0.4 spec
# 3.2; §6 A-8). A toy repository under `grammar: 0.9.3`; verdict events
# only. Convicts unless: a row held `rounds` after a harness breach and a
# row held `scope` on a harness breach are both in a harness-only fix's
# population `why=harness-held`; and a row held `rounds` after a product
# breach is not (the control). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors tests/invariants app .vid/ledger-results
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
ROWS='HR HS PR'
{ printf '# toy\n```vid-inventory\ngrammar: 0.9.3\n'
  for r in $ROWS; do printf 'ROW-%s | behavior | REQ-001 | n/a | n/a | the row %s | REQ-001 | tests/invariants/t.py\n' "$r" "$r"; done
  printf '```\n'; } > INVENTORY.md
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
printf '# Purpose: harness client (fixture)\n' > tests/invariants/harness.py
g add -A && g commit -qm root; Q=$(git rev-parse --short=12 HEAD)
receipt() { S=$(git rev-parse --short=12 HEAD); { echo '<r>'; for r in $ROWS; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"; }
receipt
V() { printf 'verdict slice=1 row=ROW-%s result=%s class=%s brief=.vid/briefs/%s.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$1" "$2" "$3" "$4" "${5:-$Q}" >> .vid/metrics-events; }
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="ROW-$1" -v c="$2" '$1==id { print $c }'; }   # 2 bucket 5 held 7 attempts 11 allow 12 ar
fail() { echo "fix-population-hold: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
V HR BREACHED product b0
echo "reissued row=ROW-HR why=A-1 rounds=1 at=2026-10-02T09:01:00Z" >> .vid/metrics-events
V HR BREACHED harness b1
printf 'verdict slice=1 row=ROW-HS result=BREACHED class=harness scope="is a retry in the promise?" brief=.vid/briefs/b1.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$Q" >> .vid/metrics-events
echo "reissued row=ROW-PR why=A-1 rounds=1 at=2026-10-02T09:01:00Z" >> .vid/metrics-events
V PR BREACHED product b1
[ "$(col HR 5)" = rounds ] && [ "$(col HS 5)" = scope ] && [ "$(col PR 5)" = rounds ] || fail "the fixture holds are not rounds, scope, rounds"
B=$(git rev-parse --short=12 HEAD)
printf "# Purpose: harness client (fixture), repaired\n" > tests/invariants/harness.py
g commit -qam "repair the harness"; receipt
POP=$(sh checks/metrics.sh fix-population --base "$B")
printf "%s\n" "$POP" | grep -qx "regrade row=ROW-HR why=harness-held" || fail "a rounds-held harness row is not re-graded: $POP"
printf "%s\n" "$POP" | grep -qx "regrade row=ROW-HS why=harness-held" || fail "a scope-held harness row is not re-graded: $POP"
printf "%s\n" "$POP" | grep -q "row=ROW-PR " && fail "a rounds-held product row was re-graded by a harness-only fix: $POP"
exit 0

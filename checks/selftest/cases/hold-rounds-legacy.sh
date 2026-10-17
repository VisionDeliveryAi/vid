#!/bin/sh
# Purpose: selftest case — a `reissued` without `rounds=` behaves as before
# (v0.9.7.0.4 spec 3.2, R5; §6 A-4). A toy repository under `grammar:
# 0.9.3`; verdict events only. Convicts unless: two product rounds hold the
# row `reason=bound`; a `reissued` with no `rounds=` releases it, attempts
# still 2, `allow` and the counter 0; one more product round leaves it
# unheld; another holds it `bound` again — no `rounds` hold ever appears.
# The existing verdict-classes.sh is the other half of this case. Env: CHECKS.
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
ROWS='L1'
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
fail() { echo "hold-rounds-legacy: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
V L1 BREACHED product b1; V L1 BREACHED product b2
[ "$(col L1 5)" = bound ] || fail "two product rounds are not held bound"
echo "reissued row=ROW-L1 why=A-1 at=2026-10-02T09:01:00Z" >> .vid/metrics-events
[ "$(col L1 5)" = - ] && [ "$(col L1 7)" = 2 ] && [ "$(col L1 11)" = 0 ] && [ "$(col L1 12)" = 0 ] || fail "a reissue without rounds= did not release as before"
V L1 BREACHED test b3
[ "$(col L1 5)" = - ] || fail "one round after a plain reissue held the row"
V L1 BREACHED product b4; V L1 BREACHED product b5
[ "$(col L1 5)" = bound ] || fail "two product rounds after a plain reissue are not held bound"
exit 0

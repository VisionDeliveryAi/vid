#!/bin/sh
# Purpose: selftest case — the class bounds still apply inside an allowance
# (v0.9.7.0.4 spec 3.2, R5–R6; §6 A-5). A toy repository under `grammar:
# 0.9.3`; verdict events only. Convicts unless: after one product round and
# `reissued rounds=5`, the attempts stay 1 (a re-issue never lowers them);
# two more product rounds hold the row `reason=bound`, not `rounds`, with
# attempts 3 and the counter 2 against `allow` 5. Env: CHECKS.
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
ROWS='P1'
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
fail() { echo "hold-rounds-class: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
V P1 BREACHED product b1
echo "reissued row=ROW-P1 why=A-1 rounds=5 at=2026-10-02T09:01:00Z" >> .vid/metrics-events
[ "$(col P1 7)" = 1 ] && [ "$(col P1 5)" = - ] || fail "the re-issue lowered the attempts or did not release"
V P1 BREACHED product b2; V P1 BREACHED product b3
[ "$(col P1 5)" = bound ] || fail "two product rounds inside rounds=5 are not held bound"
[ "$(col P1 7)" = 3 ] && [ "$(col P1 11)" = 5 ] && [ "$(col P1 12)" = 2 ] || fail "attempts 3, allow 5, counter 2 not computed"
exit 0

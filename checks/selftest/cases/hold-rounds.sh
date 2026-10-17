#!/bin/sh
# Purpose: selftest case — `reissued … rounds=N` holds the row after N more
# breached briefs (v0.9.7.0.4 spec 3.2, R5; §6 A-2). A toy repository under
# `grammar: 0.9.3`; verdict events only. Convicts unless: after `reissued
# rounds=2` one breached brief leaves the row unheld and a second, of
# another class (test, then product, so neither class bound fires), holds
# it `reason=rounds`, with `allow` 2 and the counter 2 as the table's 11th
# and 12th columns (v0.9.7.2 R9: four more follow, sixteen in all); a KEPT ends the allowance, so two later breached briefs of mixed
# classes do not hold it; and `amended` clears a `rounds` hold. Env: CHECKS.
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
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
grammar: 0.9.3
ROW-R1 | behavior | REQ-001 | n/a | n/a | two rounds then held | REQ-001 | tests/invariants/t.py
ROW-R2 | behavior | REQ-001 | n/a | n/a | a KEPT ends the allowance | REQ-001 | tests/invariants/t.py
ROW-R3 | behavior | REQ-001 | n/a | n/a | amended clears the hold | REQ-001 | tests/invariants/t.py
```
INV
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
g add -A && g commit -qm root; C1=$(git rev-parse --short=12 HEAD)
{ echo '<r>'; for r in R1 R2 R3; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$C1.full.xml"
V() { printf 'verdict slice=1 row=%s result=%s class=%s brief=.vid/briefs/%s.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$1" "$2" "$3" "$4" "$C1" >> .vid/metrics-events; }
RI() { printf 'reissued row=%s why=A-1 rounds=%s at=2026-10-02T09:01:00Z\n' "$1" "$2" >> .vid/metrics-events; }
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }   # 5 held 11 allow 12 ar
fail() { echo "hold-rounds: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
for r in ROW-R1 ROW-R2; do V $r BREACHED product "$r-b0"; RI $r 2; done
V ROW-R1 BREACHED test r1-b1
[ "$(col ROW-R1 5)" = - ] && [ "$(col ROW-R1 12)" = 1 ] || fail 'one breached brief inside rounds=2 held the row, or was not counted'
V ROW-R1 BREACHED product r1-b2
[ "$(col ROW-R1 5)" = rounds ] || fail 'two breached briefs inside rounds=2 do not hold the row reason=rounds'
[ "$(col ROW-R1 11)" = 2 ] && [ "$(col ROW-R1 12)" = 2 ] || fail 'allow and the counter are not columns 11 and 12, 2 and 2'
[ "$(sh checks/metrics.sh row-state --table | awk -F'\t' '$1=="ROW-R1" { print NF }')" = 16 ] || fail 'the table is not sixteen columns'
V ROW-R2 BREACHED test r2-b1; V ROW-R2 KEPT product r2-b2
[ "$(col ROW-R2 11)" = 0 ] && [ "$(col ROW-R2 12)" = 0 ] || fail 'a KEPT did not end the allowance'
V ROW-R2 BREACHED test r2-b3; V ROW-R2 BREACHED product r2-b4
[ "$(col ROW-R2 5)" = - ] || fail 'a row was held reason=rounds after its allowance ended on KEPT'
RI ROW-R3 1; V ROW-R3 BREACHED test r3-b1
[ "$(col ROW-R3 5)" = rounds ] || fail 'rounds=1 and one breached brief did not hold the row'
echo "amended row=ROW-R3 sha=$C1 at=2026-10-02T09:02:00Z" >> .vid/metrics-events
[ "$(col ROW-R3 5)" = - ] && [ "$(col ROW-R3 11)" = 0 ] || fail 'amended did not clear the rounds hold'
exit 0

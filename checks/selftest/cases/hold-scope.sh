#!/bin/sh
# Purpose: selftest case — a scoped breach holds its row at once
# (v0.9.7.0.4 spec 3.2, R1–R2; §6 A-1). A toy repository under `grammar:
# 0.9.3` with a fixture results reader and a current receipt; verdict events
# only. Convicts unless: a BREACHED with `scope="…"` is held `reason=scope`
# after one round; a later BREACHED without `scope=` leaves it held `scope`
# (the precedence over `bound`); `reissued` releases it; `amended` releases
# another; a scoped BREACHED followed by a plain KEPT is not held; and a
# breach with no `scope=` and no reissue is not held (the control). Env: CHECKS.
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
ROW-S1 | behavior | REQ-001 | n/a | n/a | scoped, then breached again, then reissued | REQ-001 | tests/invariants/t.py
ROW-S2 | behavior | REQ-001 | n/a | n/a | scoped, then amended | REQ-001 | tests/invariants/t.py
ROW-S3 | behavior | REQ-001 | n/a | n/a | scoped, then kept | REQ-001 | tests/invariants/t.py
ROW-S4 | behavior | REQ-001 | n/a | n/a | one plain breach | REQ-001 | tests/invariants/t.py
```
INV
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
g add -A && g commit -qm root; C1=$(git rev-parse --short=12 HEAD)
{ echo '<r>'; for r in S1 S2 S3 S4; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$C1.full.xml"
V() { printf 'verdict slice=1 row=%s result=%s class=product %sbrief=.vid/briefs/%s.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$1" "$2" "$3" "$4" "$C1" >> .vid/metrics-events; }
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }   # 2 bucket 5 held 7 attempts 11 allow 12 ar
fail() { echo "hold-scope: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
V ROW-S1 BREACHED 'scope="does the promise include a nested include?" ' s1-b1
V ROW-S2 BREACHED 'scope="is a redirect chain in the promise?" ' s2-b1
V ROW-S3 BREACHED 'scope="is a ten-level chain in the promise?" ' s3-b1
V ROW-S4 BREACHED '' s4-b1
[ "$(col ROW-S1 5)" = scope ] && [ "$(col ROW-S1 2)" = breached ] || fail 'a scoped breach is not held reason=scope at once'
[ "$(col ROW-S4 5)" = - ] || fail 'a plain breach was held (the control)'
sh checks/metrics.sh row-state ROW-S1 | grep -q 'held reason=scope' || fail 'row-state does not print the scope hold'
V ROW-S1 BREACHED '' s1-b2
[ "$(col ROW-S1 5)" = scope ] && [ "$(col ROW-S1 7)" = 2 ] || fail 'a later unscoped breach changed the scope hold'
V ROW-S3 KEPT '' s3-b2
[ "$(col ROW-S3 5)" = - ] && [ "$(col ROW-S3 2)" = kept ] || fail 'a scoped breach followed by KEPT is still held'
echo 'reissued row=ROW-S1 why=A-1 at=2026-10-02T09:01:00Z' >> .vid/metrics-events
[ "$(col ROW-S1 5)" = - ] && [ "$(col ROW-S1 7)" = 2 ] || fail 'reissued did not release the scope hold, or lowered the attempts'
echo "amended row=ROW-S2 sha=$C1 at=2026-10-02T09:02:00Z" >> .vid/metrics-events
[ "$(col ROW-S2 5)" = - ] || fail 'amended did not release the scope hold'
exit 0

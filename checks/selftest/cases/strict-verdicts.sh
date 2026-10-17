#!/bin/sh
# Purpose: selftest case — strict completion consumes verdicts (v0.9.3 spec
# 3.7, 3.3's readers; R11, R4; §7 case 5). A toy repository under `grammar:
# 0.9.3` with a fixture results reader, a harness contract declaring a
# deployed selector, a current full report and its deployed twin. Convicts
# unless `coverage.sh --strict`: names a green row whose latest verdict is
# BREACHED; names a green row with no verdict; passes a green KEPT row;
# counts a marker-only surface row green + BREACHED as ONE gap and never on
# a REQ line; leaves a `later:`-marker-only row out of the pass; names a
# `(process)` row green in the full report and absent from the deployed
# report as absent from the deployed-shape report; passes a `(process)` row
# failing in the full report and passing in the deployed one; reports a
# pilot REQ whose rows are all deploy-owed as `deploy-owed=N`; prints
# nothing of 0.9.3 under a 0.9.2 block; and runs 900 rows and 5,000 events
# in seconds. v0.9.7.0.11 (3.13, R13): that bound is 30 + ceil(10 ×
# max(1, load1 / cores)) — 40 s on an idle host, the 10 s of slack
# stretched by the load; v0.9.7.3 (3.7, R7): the bound is on the run's CPU
# seconds, 120 (the owner's floor), and the wall clock is not bounded. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors app tests/invariants .vid/ledger-results
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
cat > PRD.md <<'PRD'
# Toy

## Items

```vid-prd
REQ-001 | functional | T1 | Breached with a green test. | fail-if: it is not | serves: x | phase: pilot
REQ-002 | functional | T1 | Green, never verdicted. | fail-if: it is not | serves: x | phase: pilot
REQ-003 | functional | T1 | Green and KEPT. | fail-if: it is not | serves: x | phase: pilot
REQ-004 | functional | T1 | A feed is searchable. | fail-if: it is not | serves: x | phase: pilot
REQ-005 | functional | T1 | A feed is matched. | fail-if: it is not | serves: x | phase: pilot
REQ-006 | functional | T1 | The worker runs on the platform. | fail-if: it does not | serves: x | phase: pilot
```
PRD
printf '# Purpose: toy — REQ-001 REQ-002 REQ-003 REQ-004 REQ-005 P01/default\n' > app/main.py
printf 'x-vid-harness:\n  product: product\n  forbidden: none-such\n  deployed-selector: deployed-marker\n  processes: [worker]\nservices:\n  product:\n    build: .\n' > docker-compose.test.yml
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
printf '# design\n```vid-design-manifest\nP01 | default | covered\nP09 | promo | later: REQ-020 phase 2\n```\n' > DESIGN-BRIEF.md
inv() { { printf '# toy\n```vid-inventory\n%s' "$1"; cat <<'INV'
ROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | tests/invariants/t.py
ROW-002 | behavior | REQ-002 | n/a | n/a | two | REQ-002 | tests/invariants/t.py
ROW-003 | behavior | REQ-003 | n/a | n/a | three | REQ-003 | tests/invariants/t.py
ROW-S01 | surface | / | anonymous | P01/default | the home state | P01/default | tests/invariants/t.py
ROW-S09 | surface | /promo | anonymous | P09/promo | a later marker | P09/promo | tests/invariants/t.py
ROW-J04 | journey | feed | (process) | n/a | enter · parse · index | REQ-004 | tests/invariants/t.py
ROW-J05 | journey | feed | (process) | n/a | enter · parse · match | REQ-005 | tests/invariants/t.py
ROW-D06 | behavior | REQ-006 | n/a | n/a | the platform worker | REQ-006 | owed: paid by /vid deploy gate 2 — the platform's worker consumes it
```
INV
} > INVENTORY.md; }
inv 'grammar: 0.9.3
'
g add -A && g commit -qm root; S=$(git rev-parse --short=12 HEAD)
C() { printf '<case name="tests/invariants/t.py::%s" status="%s" time="0.1"/>\n' "$1" "${2:-passed}"; }
{ echo '<r>'; C 'a[ROW-001]'; C 'a[ROW-002]'; C 'a[ROW-003]'; C 's[ROW-S01]'; C 's[ROW-S09]'; C 'j[ROW-J04]'; C 'j[ROW-J05]' failed; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"
{ echo '<r>'; C 'j[ROW-J05]'; echo '</r>'; } > ".vid/ledger-results/$S.deployed.xml"
cat > .vid/metrics-events <<EV
verdict slice=1 row=ROW-001 result=BREACHED class=product brief=b1 quoted-at=$S
verdict slice=1 row=ROW-003 result=KEPT class=product brief=b1 quoted-at=$S
verdict slice=1 row=ROW-S01 result=BREACHED class=product brief=b1 quoted-at=$S
verdict slice=1 row=ROW-S09 result=BREACHED class=product brief=b1 quoted-at=$S
verdict slice=1 row=ROW-J04 result=KEPT class=product brief=b1 quoted-at=$S
verdict slice=1 row=ROW-J05 result=KEPT class=product brief=b1 quoted-at=$S
EV
fail() { echo "strict-verdicts: $*" >&2; cat out.txt >&2; exit 1; }
if sh checks/coverage.sh --strict >out.txt 2>&1; then fail 'strict passed with breached and unverdicted rows'; fi
grep -q "^receipt: .vid/ledger-results/$S.full.xml cases=7" out.txt || fail 'the receipt line'
grep -q "^deployed: .vid/ledger-results/$S.deployed.xml" out.txt || fail 'the deployed line'
grep -qx '    GAP  ROW-001 — green, latest verdict BREACHED class=product (slice 1)' out.txt || fail 'a green BREACHED row is not named'
grep -qx '    GAP  ROW-002 — green, no verdict' out.txt || fail 'a green unverdicted row is not named'
grep -q 'GAP  ROW-003' out.txt && fail 'a green KEPT row was named'
grep -qE '^REQ-003 +yes +yes +OK' out.txt || fail 'the KEPT row does not ledger-test its REQ'
[ "$(grep -c 'ROW-S01' out.txt)" -eq 1 ] || fail 'the marker-only BREACHED row is not exactly one line'
grep -q 'GAP  ROW-S09' out.txt && fail 'a later:-marker-only row entered the pass'
grep -q "    GAP  ROW-J04 — absent from the deployed-shape report .vid/ledger-results/$S.deployed.xml" out.txt || fail 'a (process) row absent from the deployed report is not named'
grep -q 'GAP  ROW-J05' out.txt && fail 'a (process) row passing in the deployed report was named'
grep -qE '^REQ-005 +yes +yes +OK' out.txt || fail 'the deployed report is not the receipt for the (process) row'
grep -qE '^REQ-001 +yes +no +ROW-GAP \(ROW-001\) — counted once per row' out.txt || fail 'the REQ line re-counts or omits its failing row'
grep -qE '^REQ-006 .*DEPLOY-OWED \(ROW-D06\)' out.txt || fail 'the all-deploy-owed pilot REQ'
grep -q 'deploy-owed: 1 ' out.txt || fail 'deploy-owed=1 not reported'
# gaps: ROW-001, ROW-002, ROW-S01, ROW-J04 once each, REQ-001/002/004 not again
grep -q '^REQs: 6   gaps: 4 ' out.txt || fail 'the gaps are not counted once per row'
# a 0.9.2 block prints none of it
inv 'grammar: 0.9.2
'
g commit -qam 'the 0.9.2 block'; S2=$(git rev-parse --short=12 HEAD); cp ".vid/ledger-results/$S.full.xml" ".vid/ledger-results/$S2.full.xml"
sh checks/coverage.sh --strict >out.txt 2>&1 || true
grep -qE '^deployed:|GAP  ROW-|ROW-GAP' out.txt && fail 'a 0.9.3 line printed under a 0.9.2 block'
grep -q "^receipt: .vid/ledger-results/$S2.full.xml cases=7" out.txt || fail 'the 0.9.2 receipt'
# 900 rows and 5,000 events in seconds
inv 'grammar: 0.9.3
'
awk 'BEGIN { for (i=1;i<=900;i++) printf "ROW-%04d | behavior | REQ-003 | n/a | n/a | row %d | REQ-003 | tests/invariants/t.py\n", i, i }' > rows.txt
awk '/^```$/ && !d { while ((getline l < "rows.txt") > 0) print l; d=1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
g commit -qam 'nine hundred rows'; S3=$(git rev-parse --short=12 HEAD)
{ echo '<r>'; for i in $(seq 1 900); do printf '<case name="tests/invariants/t.py::a[ROW-%04d]" status="passed" time="0.1"/>\n' "$i"; done; echo '</r>'; } > ".vid/ledger-results/$S3.full.xml"
awk -v s="$S3" 'BEGIN { for (i=1;i<=5000;i++) printf "verdict slice=%d row=ROW-%04d result=%s class=product brief=b%d quoted-at=%s\n", int(i/300)+1, (i%900)+1, (i%7 ? "KEPT" : "BREACHED"), int(i/300), s }' > .vid/metrics-events
# v0.9.7.3 (3.7, R7): what the host measures for the run — the CPU seconds the run and its children used (the
# shell's `times`, read without a subshell), which a busy host does not stretch as it stretches the wall clock (the
# load-scaled wall bound failed 8 of 10 runs under one busy loop per core) — bounded at the owner's floor, 120 s
cpu() { awk 'NR == 2 { n = split($0, a, " "); t = 0; for (i = 1; i <= n; i++) { v = a[i]; m = v; sub(/m.*/, "", m); sub(/^[0-9]+m/, "", v); sub(/s$/, "", v); t += m * 60 + v } printf "%.2f\n", t }' "$1"; }
times > cpu0.txt; T0=$(date +%s); sh checks/coverage.sh --strict >out.txt 2>&1 || true; T1=$(date +%s); times > cpu1.txt
CPU=$(awk -v a="$(cpu cpu0.txt)" -v b="$(cpu cpu1.txt)" 'BEGIN { printf "%d\n", b - a + 0.999 }')
[ "$CPU" -le 120 ] || fail "900 rows and 5,000 events used $CPU CPU seconds (bound 120; $((T1 - T0)) s on the clock)"
grep -q '^REQs: 6 ' out.txt || fail 'the large run did not complete'
exit 0

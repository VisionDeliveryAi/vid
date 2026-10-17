#!/bin/sh
# Purpose: selftest case — receipts stay current across records (v0.9.3 spec
# 3.10, R15; §7 case 6). A toy repository under `grammar: 0.9.3` with a
# fixture results reader. Convicts unless both readers — the metrics
# headline and `coverage.sh --strict` — agree that: a full receipt for S
# stays current after a commit touching only .vid/ (a slice report); a
# commit touching design/, DECISIONS.md, or a `paid-at:` stamp in
# INVENTORY.md stales it (`receipt: none`); with two current receipts the
# newest is read; the deployed twin is read with the full report it
# belongs to; and a 0.9.2 block keeps the exact-sha lookup. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors app tests/invariants design .vid/ledger-results
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Toy\n\n## Items\n\n```vid-prd\nREQ-001 | functional | T1 | Home. | fail-if: it does not | serves: x | phase: pilot\nREQ-002 | functional | T1 | The worker. | fail-if: it does not | serves: x | phase: pilot\n```\n' > PRD.md
printf '# Purpose: toy — REQ-001 P01/default\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
printf '# Decisions\n' > DECISIONS.md
printf '<!-- @screen P01 -->\n' > design/p01.html
printf 'x-vid-harness:\n  product: product\n  deployed-selector: deployed-marker\n  processes: [worker]\nservices:\n  product:\n    build: .\n' > docker-compose.test.yml
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | home | REQ-001 | tests/invariants/t.py\nROW-J01 | journey | feed | (process) | n/a | enter · store | REQ-001 | tests/invariants/t.py\nROW-D02 | behavior | REQ-002 | n/a | n/a | worker | REQ-002 | owed: paid by /vid deploy gate 2 — the platform worker consumes it\n```\n' > INVENTORY.md
g add -A && g commit -qm root; S1=$(git rev-parse --short=12 HEAD)
rep() { printf '<r>\n<case name="tests/invariants/t.py::a[ROW-001]" status="passed" time="0.1"/>\n</r>\n' > ".vid/ledger-results/$1.full.xml"
        printf '<r>\n<case name="tests/invariants/t.py::j[ROW-J01]" status="passed" time="0.1"/>\n</r>\n' > ".vid/ledger-results/$1.deployed.xml"; }
rep "$S1"
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s\nverdict slice=1 row=ROW-J01 result=KEPT class=product brief=b1 quoted-at=%s\n' "$S1" "$S1" > .vid/metrics-events
head() { sh checks/metrics.sh 2>/dev/null | sed -n 2p; }
fail() { echo "receipt-currency: $*" >&2; head >&2; sh checks/coverage.sh --strict 2>&1 | sed -n '1,3p' >&2; exit 1; }
cur() { # $1=expected report sha: both readers name it
  head | grep -q "^rows: kept 2 .*receipt .vid/ledger-results/$1.full.xml; deployed .vid/ledger-results/$1.deployed.xml)" || fail "the headline does not read $1 and its twin"
  sh checks/coverage.sh --strict 2>/dev/null | grep -q "^receipt: .vid/ledger-results/$1.full.xml cases=1" || fail "coverage does not read $1"
  sh checks/coverage.sh --strict 2>/dev/null | grep -q "^deployed: .vid/ledger-results/$1.deployed.xml" || fail "coverage does not read $1's deployed twin"
}
none() { head | grep -q '^rows: receipt: none' || fail "$1: the headline kept a stale receipt"
         sh checks/coverage.sh --strict 2>/dev/null | grep -q '^receipt: none' || fail "$1: coverage kept a stale receipt"; }
cur "$S1"
sh checks/coverage.sh --strict >out.txt 2>&1 || { cat out.txt >&2; fail "the current, all-KEPT tree failed strict"; }
# a records-only commit keeps it current
printf '# Slice reports\nslice 1 closed\n' > .vid/SLICE-REPORTS.md
g add .vid/SLICE-REPORTS.md && g commit -qm 'slice report'
cur "$S1"
# design/, DECISIONS.md and a paid-at: stamp each stale it
for what in design DECISIONS paid-at; do
  B=$(git rev-parse HEAD)
  case "$what" in
    design) printf '<!-- @screen P01 state=empty -->\n' >> design/p01.html ;;
    DECISIONS) printf -- '- **D-001** x | why: y | enforced: convention\n' >> DECISIONS.md ;;
    paid-at) sed 's/consumes it$/consumes it | paid-at: gate-2 2026-09-23 row 1/' INVENTORY.md > i && mv i INVENTORY.md ;;
  esac
  g commit -qam "$what"
  none "$what"
  g reset -q --hard "$B"
done
cur "$S1"
# two current receipts: the newest is read; a stale older one is not
printf 'slice 2 closed\n' >> .vid/SLICE-REPORTS.md; g commit -qam 'slice report 2'; S2=$(git rev-parse --short=12 HEAD); rep "$S2"
printf 'slice 3 note\n' >> .vid/SLICE-REPORTS.md; g commit -qam 'slice report 3'
cur "$S2"
# a 0.9.2 block: the exact-sha lookup (a records commit after the run leaves no receipt)
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'back to 0.9.2'
sh checks/coverage.sh --strict 2>/dev/null | grep -q '^receipt: none' || fail 'a 0.9.2 block took a receipt by the currency rule'
sh checks/coverage.sh --strict 2>/dev/null | grep -q '^deployed:' && fail 'a 0.9.2 block printed the deployed line'
exit 0

#!/bin/sh
# Purpose: selftest case — the claim names the new holds and claims neither
# row (v0.9.7.0.4 spec 3.2; §6 A-6). A toy repository under `grammar:
# 0.9.3`; verdict events only. Convicts unless: the claim prints `held
# row=ROW-SC reason=scope` and `held row=ROW-RD reason=rounds` and claims
# neither; and a row with no verdict events is claimed `why=unverdicted`
# as before (the expected-unchanged control). Env: CHECKS.
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
ROWS='SC RD UN'
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
fail() { echo "hold-claim: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
: > .vid/metrics-events
printf 'verdict slice=1 row=ROW-SC result=BREACHED class=product scope="is a nested case in the promise?" brief=.vid/briefs/b1.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$Q" >> .vid/metrics-events
V RD BREACHED product b1
echo "reissued row=ROW-RD why=A-1 rounds=1 at=2026-10-02T09:01:00Z" >> .vid/metrics-events
V RD BREACHED test b2
CL=$(sh checks/metrics.sh claim --to ".vid/ledger-results/$Q.full.xml")
printf "%s\n" "$CL" | grep -qx "held row=ROW-SC reason=scope" || fail "the claim does not name the scope hold: $CL"
printf "%s\n" "$CL" | grep -qx "held row=ROW-RD reason=rounds" || fail "the claim does not name the rounds hold: $CL"
printf "%s\n" "$CL" | grep -qE "claim row=ROW-(SC|RD)" && fail "the claim includes a held row: $CL"
printf "%s\n" "$CL" | grep -qx "claim row=ROW-UN why=unverdicted" || fail "a row with no events is not claimed as before: $CL"
exit 0

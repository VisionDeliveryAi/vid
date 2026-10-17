#!/bin/sh
# Purpose: selftest case — the owner's option (c), a known limit, is one law
# commit the courts accept and that releases the hold as debt (v0.9.7.0.4
# spec 3.3, R4; §6 A-7). Real commits in a temporary repository with the
# real hooks installed (pre-commit, commit-msg, post-commit) under
# `grammar: 0.9.3`, the PRD the known-good fixture. Convicts unless: a row
# held `reason=rounds` is released by one commit that amends its obligation
# to the part that holds and appends a row whose test is `owed:
# owner-decision — OQ-1 <the limit>`; the inventory court accepts it; the
# post-commit hook records `amended` for the held row only; the appended
# row counts owed in the headline and stands in the contract-ambiguity
# closure; and completion stays unmet. Env: CHECKS.
set -eu
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/hooks checks/extractors tests/invariants app .vid/ledger-results
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh prd-consolidate.sh metrics.sh lawfiles; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
inv() { printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | %s | REQ-001 | tests/invariants/t.py\nROW-002 | behavior | REQ-002 | n/a | n/a | the unsubscribe link stops every digest | REQ-002 | tests/invariants/t.py\n%s```\n' "$1" "$2" > INVENTORY.md; }
inv 'one digest per saved search per day, at any nesting depth' ''
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
receipt() { S=$(git rev-parse --short=12 HEAD); { echo '<r>'; for r in 001 002; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"; }
receipt; Q=$(git rev-parse --short=12 HEAD)
EVF=.vid/metrics-events
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }
fail() { echo "hold-limit: $*" >&2; sh checks/metrics.sh row-state --table >&2; cat "$EVF" >&2; exit 1; }
{ printf 'verdict slice=1 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/1.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$Q"
  printf 'reissued row=ROW-001 why=A-1 rounds=1 at=2026-10-02T09:01:00Z\n'
  printf 'verdict slice=2 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/2.md quoted-at=%s at=2026-10-02T09:02:00Z\n' "$Q"; } > "$EVF"
[ "$(col ROW-001 5)" = rounds ] || fail 'the fixture row is not held reason=rounds'
# option (c): the Fail-if narrowed to what holds, the excluded part appended as owed owner-decision debt
inv 'one digest per saved search per day, up to three levels of nesting' 'ROW-003 | behavior | REQ-001 | n/a | n/a | one digest per saved search per day beyond three levels of nesting | REQ-001 | owed: owner-decision — OQ-1 nesting deeper than three levels is a known limit
'
g add INVENTORY.md && g commit -qm 'ROW-001 known limit (Q1, option c)

Decisions: none — the owner chose to record deeper nesting as a known limit' >/dev/null 2>&1 || fail 'the courts refused the known-limit law commit'
H=$(git rev-parse --short=12 HEAD)
grep -qxE "amended row=ROW-001 sha=$H by=(obligation|fail-if) $ATRE" "$EVF" || fail 'the post-commit hook did not record amended for the held row'
[ "$(grep -c '^amended ' "$EVF")" -eq 1 ] || fail 'the appended row recorded an amendment'
receipt
[ "$(col ROW-001 5)" = - ] && [ "$(col ROW-001 11)" = 0 ] || fail 'the known-limit commit did not release the hold'
[ "$(col ROW-003 2)" = owed ] || fail 'the appended row does not count owed'
sh checks/metrics.sh | sed -n 2p | grep -q ' owed 1 ' || fail 'the headline does not count the known limit owed'
sh checks/metrics.sh closure | grep -q '^closure contract-ambiguity n=1 ROW-003$' || fail 'the known limit is not in the contract-ambiguity closure'
CO=$(sh checks/metrics.sh completion)
printf '%s\n' "$CO" | grep -q '^completion unmet=[1-9]' || fail 'completion is met with a known limit standing'
exit 0

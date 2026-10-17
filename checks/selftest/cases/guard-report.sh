#!/bin/sh
# Purpose: selftest case — guard before probe (v0.9.3 spec 3.5, R6; §7 case
# 14, the guard half). A toy repository under `grammar: 0.9.3` with a
# current receipt and verdict events; census.sh and the selftest runner are
# stubs that leave a mark if run. Convicts unless `inventory.sh --report`
# prints `guard HOS-004 protects ROW-212: red (absent from …)`, `guard
# HOS-009 protects RULE-031: owed: guard-first — …`, `guard HOS-011 protects
# REQ-044: kept 3 · red 1 · owed 0` and `guard ROW-440 control of ROW-438:
# kept`, runs neither the census nor the selftest to do it, and prints no
# guard line under a 0.9.2 block. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks/extractors checks/selftest tests/invariants .vid/ledger-results
cp "$CHECKS/inventory.sh" "$CHECKS/metrics.sh" "$CHECKS/lawfiles" checks/
printf '#!/bin/sh\n# Purpose: stub — marks that the census ran\ntouch "%s/census-ran"\n' "$T" > checks/census.sh
printf '#!/bin/sh\n# Purpose: stub — marks that the selftest ran\ntouch "%s/selftest-ran"\n' "$T" > checks/selftest/run.sh
printf '#!/bin/sh\n# Purpose: results reader (fixture)\n[ -f "${1:-}" ] || { echo inactive; exit 0; }\ngrep "^case " "$1"\n' > checks/extractors/results.sh
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Purpose: ledger\n' > tests/invariants/t.sh
inv() { cat > INVENTORY.md <<INV
# toy
\`\`\`vid-inventory
$1
ROW-212 | behavior | REQ-040 | n/a | n/a | the export needs a signed-in owner | REQ-040 | tests/invariants/t.sh
ROW-438 | behavior | REQ-041 | n/a | n/a | an owner exports their data | REQ-041 | tests/invariants/t.sh
ROW-440 | behavior | REQ-041 | n/a | n/a | control of ROW-438: the owner's own export succeeds | REQ-041 | tests/invariants/t.sh
ROW-501 | behavior | REQ-044 | n/a | n/a | a | REQ-044 | tests/invariants/t.sh
ROW-502 | behavior | REQ-044 | n/a | n/a | b | REQ-044 | tests/invariants/t.sh
ROW-503 | behavior | REQ-044 | n/a | n/a | c | REQ-044 | tests/invariants/t.sh
ROW-504 | behavior | REQ-044 | n/a | n/a | d | REQ-044 | tests/invariants/t.sh
rule | RULE-031 | every export is scoped to its owner | checks/extractors/invariant.scope.sh | 0 | owed: guard-first — the scope guard lands in slice 4
hostility | HOS-004 | fetch another owner's export with a valid session, expect refusal | protects: ROW-212 | disable: drop the owner check | owed: guard-first — ROW-212's guard
hostility | HOS-009 | request an unscoped export | protects: RULE-031 | disable: drop the scope filter | owed: guard-first — RULE-031's guard
hostility | HOS-011 | read the export of a closed account | protects: REQ-044 | disable: skip the closed check | owed: guard-first — REQ-044's rows
\`\`\`
INV
}
inv 'grammar: 0.9.3'
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root; S=$(git rev-parse --short=12 HEAD)
{ for r in 438 440 501 502 503; do printf 'case tests/invariants/t.sh::t[ROW-%s] passed 0.1\n' "$r"; done; printf 'case tests/invariants/t.sh::t[ROW-504] failed 0.1\n'; } > ".vid/ledger-results/$S.full.xml"
for r in 438 440 501 502 503; do printf 'verdict slice=3 row=ROW-%s result=KEPT class=product brief=b quoted-at=%s\n' "$r" "$S"; done > .vid/metrics-events
OUT=$(sh checks/inventory.sh --report 2>&1)
fail() { echo "guard-report: $*" >&2; printf '%s\n' "$OUT" | grep '^guard' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q "^guard HOS-004 protects ROW-212: red (absent from .vid/ledger-results/$S.full.xml" || fail 'a red ROW target'
printf '%s\n' "$OUT" | grep -q '^guard HOS-009 protects RULE-031: owed: guard-first — the scope guard lands in slice 4$' || fail 'an owed RULE target'
printf '%s\n' "$OUT" | grep -q '^guard HOS-011 protects REQ-044: kept 3 · red 1 · owed 0$' || fail 'a REQ target with mixed rows'
printf '%s\n' "$OUT" | grep -q '^guard ROW-440 control of ROW-438: kept$' || fail 'a control sibling'
[ ! -e "$T/census-ran" ] && [ ! -e "$T/selftest-ran" ] || fail 'the guard block ran the census or the selftest'
inv 'grammar: 0.9.2'
sh checks/inventory.sh --report 2>&1 | grep -q '^guard ' && fail 'a 0.9.2 block printed guard lines'
exit 0

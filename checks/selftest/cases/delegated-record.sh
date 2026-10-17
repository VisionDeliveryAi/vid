#!/bin/sh
# Purpose: selftest case — the delegated mark (v0.9.7.4 spec 3.9, R10). A PRD whose answer ledger holds a human
# answer, the same answer amended in an append, and a model_proposed answer. Convicts unless `sh checks/metrics.sh
# delegated --answer A-002` exits 0 and appends exactly one `delegated answer=A-002 at=<UTC>` line, and an answer
# that lives only as an AMENDED row in an append (A-003) is marked too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "delegated-record: $*" >&2; exit 1; }
cd "$T"; mkdir -p checks .vid; cp "$CHECKS/metrics.sh" checks/; : > .vid/metrics-events
cat > PRD.md <<'P'
# A product
## Answer ledger
```vid-prd-answers
A-001 | model_proposed | 2026-10-01 | A: a default ViD chose. | settles: thesis
A-002 | human | 2026-10-01 | Q: Which? | A: Delegated by the owner, accepted as recommended — the first. | settles: thesis
A-003 | human | 2026-10-01 | A: the owner's own. | settles: thesis
```
## Appends
```vid-prd-answers
A-003 AMENDED | human | 2026-10-02 | A: the owner's own, restated. | settles: thesis
```
P
sh checks/metrics.sh delegated --answer A-002 > "$T/out" 2>&1 || fail "A-002 refused: $(cat "$T/out")"
grep -Eqx 'delegated answer=A-002 at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' .vid/metrics-events || fail "no delegated line for A-002: $(cat .vid/metrics-events)"
[ "$(grep -c '^delegated ' .vid/metrics-events)" = 1 ] || fail 'more than one line written'
sh checks/metrics.sh delegated --answer A-003 > "$T/out" 2>&1 || fail "the amended A-003 refused: $(cat "$T/out")"
[ "$(grep -c '^delegated answer=A-003 ' .vid/metrics-events)" = 1 ] || fail 'A-003 not marked'
exit 0

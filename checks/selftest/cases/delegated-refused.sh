#!/bin/sh
# Purpose: selftest case — the delegated mark's refusals (v0.9.7.4 spec 3.9, R10). Convicts unless `sh
# checks/metrics.sh delegated --answer <id>` exits non-zero and writes nothing for: an id no answer row carries
# (A-009), an id that appears only outside the answer blocks (A-004, cited by an item), an answer of tier
# model_proposed (A-001), and an answer already marked (A-002, marked once). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "delegated-refused: $*" >&2; exit 1; }
cd "$T"; mkdir -p checks .vid; cp "$CHECKS/metrics.sh" checks/; : > .vid/metrics-events
cat > PRD.md <<'P'
# A product
```vid-prd
REQ-001 | functional | T1 | A thing happens. | fail-if: it does not | source: A-004 | phase: pilot
```
## Answer ledger
```vid-prd-answers
A-001 | model_proposed | 2026-10-01 | A: a default ViD chose. | settles: thesis
A-002 | human | 2026-10-01 | A: Delegated by the owner — the first. | settles: thesis
```
P
for a in A-009 A-004 A-001; do
  if sh checks/metrics.sh delegated --answer "$a" > "$T/out" 2>&1; then fail "$a was marked: $(cat "$T/out")"; fi
  grep -q 'refused' "$T/out" || fail "$a: no refusal said: $(cat "$T/out")"
done
[ ! -s .vid/metrics-events ] || fail "a refused mark wrote: $(cat .vid/metrics-events)"
sh checks/metrics.sh delegated --answer A-002 > "$T/out" 2>&1 || fail "A-002 refused: $(cat "$T/out")"
if sh checks/metrics.sh delegated --answer A-002 > "$T/out" 2>&1; then fail 'A-002 was marked twice'; fi
[ "$(grep -c '^delegated ' .vid/metrics-events)" = 1 ] || fail 'a second mark was written'
exit 0

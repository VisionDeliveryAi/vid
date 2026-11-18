#!/bin/sh
# Purpose: selftest case — the strength pass's record (0.26.10.29.4, phase 3 R1, the court part). On the known-good PRD
# fixture, the court (checks/prd.sh, join 13) accepts a dated `## Findings` heading carrying
# `review: whole, round 1, 2 findings` over two rows of pass `strength` (one targeting `INVENTORY.md:ROW-12`), and one
# carrying `review: delta, round 1, 1 finding` over one; a row of an unknown pass (`sweep`) is still refused, and the
# refusal names `strength` among the passes. Env: CHECKS.
set -eu
fail() { echo "findings-pass-strength-accepted: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
infind() { awk -v f="$1" '/^## Ratifications$/ { while ((getline l < f) > 0) print l; print "" } { print }' "$F" > PRD.md; }
cat > h.txt <<'H'
### 2026-11-16 — strength pass

review: whole, round 1, 2 findings

```vid-prd-findings
F-10 | strength | blocking | INVENTORY.md:ROW-12 | repaired | evidence: a digest that repeats a job on the second day still passes the row — one more observation added
F-11 | strength | advisory | REQ-012 | noted | evidence: arm 2 reworded in an append; the new words still fail every bounce the old ones failed
```

### 2026-11-16 — strength pass, the append's delta

review: delta, round 1, 1 finding

```vid-prd-findings
F-12 | strength | advisory | INVENTORY.md:ROW-3 | noted | evidence: the row and ROW-4 hold the same obligation; the unratified one was dropped
```
H
infind h.txt
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'rows of pass strength under whole and delta review lines were refused'; }
sed 's/^F-11 | strength |/F-11 | sweep |/' h.txt > h2.txt; infind h2.txt
if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail 'a row of the unknown pass sweep passed'; fi
grep -q "GAP  join 13 (F-11): unknown pass 'sweep' — .*strength" out.txt || { cat out.txt >&2; fail 'the refusal does not name the unknown pass, or does not list strength among the passes'; }
echo 'findings-pass-strength-accepted: ok'

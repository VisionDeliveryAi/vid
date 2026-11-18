#!/bin/sh
# Purpose: selftest case — the final pass's record (0.26.10.29.3, phase 2 R6 and R2). On the known-good PRD fixture,
# the court (checks/prd.sh, join 13) accepts a dated `## Findings` heading carrying
# `review: final, round 1, 0 findings, read: …` and no rows (the form the spec-commit rule reads), and one carrying
# `review: final, round 2, 2 findings, read: …` over two rows of pass `final`, one targeting another document; a row of
# an unknown pass (`sweep`) is refused. Env: CHECKS.
set -eu
fail() { echo "findings-pass-final-accepted: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
infind() { awk -v f="$1" '/^## Ratifications$/ { while ((getline l < f) > 0) print l; print "" } { print }' "$F" > PRD.md; }
printf '%s\n' '### 2026-11-15 — final review' '' 'review: final, round 1, 0 findings, read: PRD.md ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md' > h.txt
infind h.txt
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'a final heading with review: final, round 1, 0 findings, read: … was refused'; }
cat > h.txt <<'H'
### 2026-11-15 — final review

review: final, round 2, 2 findings, read: PRD.md DESIGN-BRIEF.md design/ ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md

```vid-prd-findings
F-10 | final | blocking | REQ-010, ARCHITECTURE.md | repaired | evidence: major — the backup bound is a day here and a week in the architecture
F-11 | final | advisory | INVENTORY.md:ROW-12 | noted | evidence: minor — the row's "fast" has no bound
```
H
infind h.txt
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'two final rows under review: final, round 2, 2 findings were refused'; }
sed 's/^F-11 | final |/F-11 | sweep |/' h.txt > h2.txt; infind h2.txt
if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail 'a row of the unknown pass sweep passed'; fi
grep -q "GAP  join 13 (F-11): unknown pass 'sweep'" out.txt || { cat out.txt >&2; fail 'the refusal does not name the unknown pass'; }
echo 'findings-pass-final-accepted: ok'

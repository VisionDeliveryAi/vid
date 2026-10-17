#!/bin/sh
# Purpose: selftest case — presence gating and fail-closed parsing. A
# PRD.md with no ```vid-prd block must exit 0 silently (pre-enrichment
# projects unaffected); a malformed row (a stray | inside a field) must
# be a named GAP, never a silent skip or a half-parse. Exits 0 only if
# both hold. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"

# 1. presence gate: no ```vid-prd block — silent exit 0.
printf '# Old project — PRD\n\n## Requirements\n\n### REQ-001 (T1) — home\nHome renders.\n**Fail-if:** it does not.\n' > PRD.md
OUT=$(sh "$COURT" PRD.md 2>&1) || exit 1
[ -z "$OUT" ] || exit 1

# 2. fail-closed: a stray | inside a field is a named GAP and a conviction.
cp "$FIXTURES/prd-known-good.md" PRD.md
printf '\n### 2026-08-29 (owner answer)\n\n```vid-prd\nREQ-030 | functional | T1 | P1 | A statement with a stray | pipe inside it. | fail-if: it breaks | serves: parsing law | authority: authoritative | source: seed\n```\n' >> PRD.md
if sh "$COURT" PRD.md >/dev/null 2>&1; then exit 1; fi
sh "$COURT" PRD.md --report 2>&1 | grep -q 'GAP  join 1 (REQ-030)' || exit 1
exit 0

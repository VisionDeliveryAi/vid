#!/bin/sh
# Purpose: selftest case — checks/prd-consolidate.sh, the mechanical copy
# (v0.9.1 spec 3.4, 7a). From the known-good fixture: two amendments of one
# item and one amended answer consolidate to one effective row with the
# latest text and one answer row without its Q: text (the question text in
# the history file); the output is court-green, carries grammar: 0.9.1, four
# positional fields and phase: pilot, the Seed: pointer with SEED.md beside
# it; a second run is byte-identical and writes no second archive; the
# RESOLVED: (OQ-2) carrier survives with its F-05 … routed OQ-2 disposition;
# the open OQ-1 carrier stays one line and, once resolved in PRD.md, the
# coverage census reports zero open markers with the archive (which still
# holds the carrier verbatim) present; an amendment that dropped an arm is
# flagged arm-losing in the ledger; a SEED.md with other content refuses the
# write; a pre-enrichment PRD refuses. Env: CHECKS.
set -eu
SCRIPT="$CHECKS/prd-consolidate.sh"; COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
cp "$FIXTURES/prd-known-good.md" PRD.md
# a second amendment of REQ-002 (three arms → two: the sign-in arm dropped, unaccounted)
cat >> PRD.md <<'APP'

### 2026-08-30 (owner answer — the second unsubscribe ruling)

```vid-prd
REQ-002 AMENDED | functional | T1 | P0 | Every digest carries a working one-click unsubscribe that stops all digests for that address within one hour. | fail-if: a digest arrives more than one hour after its address unsubscribed | serves: consent exit — the second amendment | authority: authoritative | source: A-001 | covers: DIM-consent
```
APP
sh "$COURT" PRD.md >/dev/null 2>&1 || { echo 'prd-consolidate: the seeded input is not court-green' >&2; exit 1; }
sh "$SCRIPT" PRD.md --date 2026-09-21 >run1.txt 2>&1 || { cat run1.txt >&2; exit 1; }
[ -f SEED.md ] && [ -f PRD-HISTORY-2026-09-21.md ] && [ -f .vid/consolidation-arms-2026-09-21.md ] || exit 1
cp PRD-HISTORY-2026-09-21.md HIST.first.md
sh "$COURT" PRD.md >/dev/null 2>&1 || exit 1                                              # court green on the output
sed -n '2p' PRD.md | grep -qx 'grammar: 0.9.1' || exit 1
sed -n '3p' PRD.md | grep -qE '^Seed: SEED\.md \(sha256 [0-9a-f]{64}\)$' || exit 1
grep -q '^## Seed$' PRD.md && exit 1                                                        # the seed section is gone
grep -q 'A newsletter-style job board' SEED.md || grep -q . SEED.md || exit 1               # the seed text lives in SEED.md
[ "$(grep -c '^REQ-002' PRD.md)" -eq 1 ] || exit 1                                          # one effective row
grep '^REQ-002' PRD.md | grep -q 'within one hour' || exit 1                                # the latest text
grep '^REQ-002' PRD.md | grep -q ' AMENDED' && exit 1
grep '^REQ-002' PRD.md | grep -qE '^REQ-002 \| functional \| T1 \| Every' || exit 1         # four positional fields: the priority column is gone
grep '^REQ-002' PRD.md | grep -q '| phase: pilot' || exit 1
[ "$(grep -c '^A-005' PRD.md)" -eq 1 ] || exit 1
grep '^A-005' PRD.md | grep -q 'ten confirmed as the launch cap' || exit 1                  # the amended answer, once
grep -q '| Q:' PRD.md && exit 1                                                             # no question text in the live file
grep -q 'Q: how many saved searches per subscriber?' PRD-HISTORY-2026-09-21.md || exit 1   # the question text in history
grep -q '^RESOLVED: (OQ-2) A-005' PRD.md || exit 1                                          # a resolved carrier is law (R12-ii)
grep -q 'F-05 | audit | advisory | REQ-006 | routed OQ-2' PRD.md || exit 1
grep -q '^VID-QUESTION: (OQ-1)' PRD.md || exit 1                                            # the open carrier, one line
[ "$(grep -c 'VID-QUESTION:' PRD.md)" -eq 1 ] || exit 1
grep -qE '^## REQ-002 — 3 rows — arms first=2 consolidated=1 — arm-losing' .vid/consolidation-arms-2026-09-21.md || exit 1
sed -n '/^## Appends/,$p' PRD.md | grep -q '^### ' && exit 1                                # appends emptied to the comment
# byte-identical on a second run; no second archive
cp PRD.md PRD.first.md
sh "$SCRIPT" PRD.md --date 2026-09-22 >run2.txt 2>&1 || { cat run2.txt >&2; exit 1; }
cmp -s PRD.md PRD.first.md || exit 1
[ -f PRD-HISTORY-2026-09-22.md ] && exit 1
cmp -s PRD-HISTORY-2026-09-21.md HIST.first.md || exit 1                                    # the archive is never rewritten by a no-op run
rm -f HIST.first.md
rm -f PRD.first.md run1.txt run2.txt                                                        # the case's own copies leave the tree before the census
# the archive is invisible to the census: resolve OQ-1 in PRD.md, keep the archive (which still carries the carrier verbatim)
printf '# toy\n```vid-placement\napp\n```\n' > CLAUDE.md
sed -i.bak 's/^VID-QUESTION: (OQ-1) \(.*\)$/RESOLVED: (OQ-1) A-001 — \1/' PRD.md && rm -f PRD.md.bak
grep -q 'VID-QUESTION: (OQ-1)' PRD-HISTORY-2026-09-21.md || exit 1
sh "$CHECKS/coverage.sh" 2>/dev/null | grep -q 'open VID-QUESTION markers: 0' || exit 1
# a SEED.md with other content refuses the write, and the live file is untouched
mkdir other && cp "$FIXTURES/prd-known-good.md" other/PRD.md && printf 'not the seed\n' > other/SEED.md && cp other/PRD.md other/PRD.orig.md
if sh "$SCRIPT" other/PRD.md --date 2026-09-21 >/dev/null 2>&1; then exit 1; fi
cmp -s other/PRD.md other/PRD.orig.md || exit 1
# a pre-enrichment PRD (no ```vid-prd block) refuses
printf '# old\n\n## Seed\n\ntext\n\n### REQ-001\nFail-if: nothing\n' > legacy.md
if sh "$SCRIPT" legacy.md >/dev/null 2>&1; then exit 1; fi
exit 0

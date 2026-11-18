#!/bin/sh
# Purpose: selftest case — no append is committed without its review
# (0.26.10.29.3, R3). Real commits in a scratch repository with the real
# hooks installed, the PRD the known-good fixture: a new append section
# holding a row and no `review:` line is refused by pre-commit, naming the
# section; the same section with `review: delta, 0 findings` is accepted;
# one whose line says 2 findings while its ```vid-prd-findings block holds 1
# is refused; one with `review: delta, 1 findings` and its one findings row
# is accepted; a section holding only an open carrier (no rows for a review
# to read) needs no line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "append-without-review-refused: $*" >&2; exit 1; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh prd.sh lawfiles event.sh; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg post-commit; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
printf '.vid/\n' > .gitignore
g add -A && g commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
# door <body>: append a dated section and commit it through the hooks; prints ACCEPTED or REFUSED
door() {
  cp PRD.md PRD.base
  printf '\n### 2026-10-01 (/vid add)\n\n%s\n' "$1" >> PRD.md
  g add PRD.md
  if g commit -qm "an append

Decisions: none — a review probe" >out.txt 2>&1; then echo ACCEPTED; else cp PRD.base PRD.md; g reset -q; echo REFUSED; fi
}
ROW='```vid-prd
REQ-070 | functional | T2 | P2 | A subscriber can pause all digests for a holiday. | fail-if: a digest arrives while the subscriber paused them | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis
```'
[ "$(door "$ROW")" = REFUSED ] || fail 'an append with no review: line was accepted'
grep -q '### 2026-10-01 (/vid add)' out.txt && grep -q 'review: delta' out.txt || { cat out.txt >&2; fail 'the refusal does not name the section and the review: line'; }
[ "$(door "$ROW

review: delta, 2 findings

\`\`\`vid-prd-findings
F-06 | review | advisory | REQ-070 | noted | evidence: the pause has no end date; a subscriber who forgets it gets no digest — noted for the owner
\`\`\`")" = REFUSED ] || fail 'a review: line counting 2 findings over a block of 1 was accepted'
grep -q '2 finding' out.txt || { cat out.txt >&2; fail 'the count refusal does not name the count'; }
[ "$(door "$ROW

review: delta, 0 findings")" = ACCEPTED ] || { cat out.txt >&2; fail 'the same section with its review: line was refused'; }
[ "$(door "$(printf '%s\n' "$ROW" | sed 's/REQ-070/REQ-071/; s/for a holiday/for a fortnight/')

review: delta, 1 findings

\`\`\`vid-prd-findings
F-07 | review | advisory | REQ-071 | noted | evidence: a fortnight's pause overlaps the holiday pause; a subscriber may set both — noted for the owner
\`\`\`")" = ACCEPTED ] || { cat out.txt >&2; fail 'a section with one finding and its line was refused'; }
# 0.26.10.29.3 (phase 2 R2): block 6c reads a final line with its read: list as a review line
[ "$(door "$(printf '%s\n' "$ROW" | sed 's/REQ-070/REQ-072/; s/for a holiday/for a weekend/')

review: final, round 1, 0 findings, read: PRD.md INVENTORY.md")" = ACCEPTED ] || { cat out.txt >&2; fail 'a section with review: final, round 1, 0 findings, read: … was refused'; }
[ "$(door 'VID-QUESTION: (OQ-3) Does a paused subscriber keep their saved searches?')" = ACCEPTED ] || { cat out.txt >&2; fail 'a carrier-only section was refused for a review: line'; }
exit 0

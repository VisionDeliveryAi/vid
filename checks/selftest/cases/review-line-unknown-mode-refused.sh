#!/bin/sh
# Purpose: selftest case — every `review:` line has one of the closed forms (0.26.10.29.3, phase 2 R2). On the
# known-good PRD fixture with one heading added under `## Findings`, the court (checks/prd.sh, join 13) refuses a line
# whose mode is not delta, whole or final, and each line outside the forms: a round that is not a number, a `final`
# line with no `read:`, a `read:` on a delta line, a `see` line on delta, one counting findings, and one naming a
# heading that is not under `## Findings`; a `see` line naming the heading passes, as do the three modes in their
# forms. Env: CHECKS.
set -eu
fail() { echo "review-line-unknown-mode-refused: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
# prd <findings line> <append line>: the fixture with a `### 2026-11-15 — final review` heading under ## Findings
# carrying the first line, and an append section carrying the second (either may be empty)
prd() {
  awk -v l="$1" '/^## Ratifications$/ { print "### 2026-11-15 — final review"; print ""; if (l != "") print l; print "" } { print }' "$F" > PRD.md
  [ -z "$2" ] || printf '\n### 2026-11-15 (final review repairs)\n\nVID-QUESTION: (OQ-9) Does a held digest go out later?\n\n%s\n' "$2" >> PRD.md; }
refused() { # <findings line> <append line> <what>
  prd "$1" "$2"
  if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail "$3 passed the court"; fi
  grep -q 'GAP  join 13.*review:' out.txt || { cat out.txt >&2; fail "$3: the refusal is not join 13's review: rule"; }; }
passes() { prd "$1" "$2"; sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail "$3 was refused"; }; }
refused 'review: sweep, round 1, 0 findings' '' 'an unknown mode (sweep)'
refused 'review: Final, round 1, 0 findings, read: PRD.md' '' 'a mode in the wrong case (Final)'
refused 'review: final, round two, 0 findings, read: PRD.md' '' 'a round that is not a number'
refused 'review: final, round 1, 0 findings' '' 'a final line with no read:'
refused 'review: final, round 1, 0 findings, read:' '' 'a final line with an empty read:'
refused 'review: whole, round 1, 0 findings, read: PRD.md' '' 'a read: on a whole line'
refused 'review: final, round 1, 0 findings, read: PRD.md, extra' '' 'a final line with a trailing field'
refused 'review: final, round 1, 0 findings, read: PRD.md INVENTORY.md' 'review: delta, round 1, 0 findings, see 2026-11-15 — final review' 'a see line on a delta review'
refused 'review: final, round 1, 0 findings, read: PRD.md INVENTORY.md' 'review: final, round 1, 2 findings, see 2026-11-15 — final review' 'a see line counting 2 findings'
refused 'review: final, round 1, 0 findings, read: PRD.md INVENTORY.md' 'review: final, round 1, 0 findings, see 2026-11-14 — final review' 'a see line naming no heading under ## Findings'
refused 'review: final, round 1, 0 findings, read: PRD.md INVENTORY.md' 'review: final, round 1, 0 findings, see 2026-08-28 (owner answer)' 'a see line naming an append heading'
passes 'review: final, round 1, 0 findings, read: PRD.md INVENTORY.md' 'review: final, round 1, 0 findings, see 2026-11-15 — final review' 'a see line naming the final heading'
passes 'review: whole, round 2, 0 findings' '' 'review: whole, round 2, 0 findings'
passes 'review: delta, round 1, 0 finding' '' 'review: delta, round 1, 0 finding'
echo 'review-line-unknown-mode-refused: ok'

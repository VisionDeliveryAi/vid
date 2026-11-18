#!/bin/sh
# Purpose: selftest case — phase 1's `review:` line still passes (0.26.10.29.3, phase 2 R2). On the known-good PRD
# fixture, append sections carrying `review: delta, 0 findings` alone, `review: delta, 1 finding` with its one row,
# and `review: whole, 2 findings` with two rows pass the court (checks/prd.sh) with no gap; the court reads the line
# (a misspelt phase-1 line, `review: delta, no findings`, is refused) and the same delta section in this phase's
# form, `review: delta, round 1, 1 findings`, passes too. Env: CHECKS.
set -eu
fail() { echo "review-line-phase1-form-passes: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
sect() { # <date> <review line> <findings rows, | separated by newlines, or empty> <REQ id>
  printf '\n### %s (/vid add)\n\n```vid-prd\n%s | functional | T2 | P2 | A subscriber can pause digest number %s. | fail-if: digest %s arrives while paused | serves: a subscriber on leave stays subscribed | authority: authoritative | source: thesis\n```\n\n%s\n' "$1" "$4" "$4" "$4" "$2"
  [ -z "$3" ] || printf '\n```vid-prd-findings\n%s\n```\n' "$3"; }
{ cat "$F"
  sect 2026-10-01 'review: delta, 0 findings' '' REQ-070
  sect 2026-10-02 'review: delta, 1 finding' 'F-10 | review | advisory | REQ-071 | noted | evidence: no end date' REQ-071
  sect 2026-10-03 'review: whole, 2 findings' 'F-11 | review | advisory | REQ-072 | noted | evidence: no end date
F-12 | review | advisory | REQ-072 | noted | evidence: overlaps REQ-071' REQ-072
} > PRD.md
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail 'phase 1 review: lines (no round) were refused'; }
grep -q '^GAP' out.txt && { cat out.txt >&2; fail 'the court printed a gap on phase 1 review: lines'; }
{ cat "$F"; sect 2026-10-01 'review: delta, no findings' '' REQ-070; } > PRD.md
if sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1; then fail 'a misspelt phase-1 line (review: delta, no findings) passed — the court does not read the line'; fi
{ cat "$F"; sect 2026-10-02 'review: delta, round 1, 1 findings' 'F-10 | review | advisory | REQ-071 | noted | evidence: no end date' REQ-071; } > PRD.md
sh "$CHECKS/prd.sh" PRD.md > out.txt 2>&1 || { cat out.txt >&2; fail "this phase's form of the same delta line was refused"; }
echo 'review-line-phase1-form-passes: ok'

#!/bin/sh
# Purpose: selftest case — an answer that merely settles the item never closes a weakening (0.26.10.29.4, phase 3 R4).
# A first append rewords REQ-012's arm 2 ("mail to it bounces" → "… bounces twice", `retained`) under the human answer
# A-007 it cites. `checks/prd.sh --arms` keeps listing it after a later human answer settling REQ-012 (a blanket "all
# recommended"), after a findings row accepting the arm under A-007 (an answer the amending row's `source:` cites), and
# after a later revision whose arm only contains the old words. Env: CHECKS.
set -eu
fail() { echo "prd-arms-open-after-settling-answer: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
S='Every digest footer carries a support contact address that reaches a person.'
r12() { printf 'REQ-012 AMENDED | functional | T2 | P2 | %s | fail-if: %s | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: %s | covers: DIM-nfr-operability/support | arms: 1 retained, 2 retained\n' "$1" "$2" "$3"; }
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd-answers\n'
  printf '%s\n' 'A-007 | human | 2026-09-01 | Q: may the support footer bounce once? | A: yes, a single bounce is tolerated | settles: REQ-012'
  printf '```\n\n```vid-prd\n'
  r12 "$S" 'the footer lacks a support address, or mail to it bounces twice' 'thesis, A-007'; printf '```\n'; } > A.md
arms() { sh "$CHECKS/prd.sh" --arms "$1" > out.txt 2> err.txt || { cat err.txt >&2; fail "--arms exited non-zero on $1"; }
  grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt || { cat out.txt >&2; fail "$2"; }; }
arms A.md 'the weakening is not listed under its own settling answer'
{ cat A.md; printf '\n### 2026-09-05 (owner answer)\n\n```vid-prd-answers\n'
  printf '%s\n' 'A-008 | human | 2026-09-05 | Q: accept every recommendation of the sitting? | A: all recommended | settles: REQ-012'
  printf '```\n'; } > B.md
sh "$CHECKS/prd.sh" B.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the fixture with the settling answer is not a lawful PRD'; }
arms B.md 'a later human answer that merely settles REQ-012 (all recommended) closed the entry'
{ cat B.md; printf '\n```vid-prd-findings\n'
  printf '%s\n' 'F-20 | review | blocking | REQ-012 | accepted A-007 | evidence: arm 2 — the single bounce accepted'
  printf '```\n'; } > C.md
sh "$CHECKS/prd.sh" C.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the fixture with the findings row is not a lawful PRD'; }
arms C.md "a ruling under A-007, an answer the amending row's source: cites, closed the entry"
{ cat B.md; printf '\n### 2026-09-09 (owner answer)\n\n```vid-prd\n'
  r12 "$S On every digest." 'the footer lacks a support address, or mail to it bounces twice, or mail to it bounces and stays unread' thesis
  printf '```\n'; } > D.md
arms D.md 'a later arm that only contains the old words closed the entry'
echo 'prd-arms-open-after-settling-answer: ok'

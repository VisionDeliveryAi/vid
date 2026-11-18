#!/bin/sh
# Purpose: selftest case — `checks/prd.sh --arms` compares whole arms, never text found inside one (0.26.10.29.4,
# phase 3 R4). An append keeps REQ-012's arm 1 word for word with a condition added ("… and the digest is a weekly one")
# and its arm 2 word for word, both marked `retained`: arm 1 is listed, since an added condition can let more wrong
# builds through, and arm 2 is not. White space alone (a doubled space, a tab) is not a change. Join 14's legacy
# substring reading is not the test. Env: CHECKS.
set -eu
fail() { echo "prd-arms-added-condition: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
TB=$(printf '\t')
NEW="the footer lacks a support address and the digest is a weekly one, or mail  to${TB}it bounces"
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n'
  printf 'REQ-012 AMENDED | functional | T2 | P2 | Every digest footer carries a support contact address that reaches a person. | fail-if: %s | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | arms: 1 retained, 2 retained\n' "$NEW"
  printf '```\n'; } > A.md
sh "$CHECKS/prd.sh" --arms A.md > out.txt 2> err.txt || { cat err.txt >&2; fail '--arms exited non-zero'; }
grep -q '^REQ-012 arm 1 retained | was: the footer lacks a support address | now: the footer lacks a support address and the digest is a weekly one, or mail' out.txt \
  || { cat out.txt >&2; fail 'the arm kept with a condition added is not listed'; }
if grep -q '^REQ-012 arm 2 ' out.txt; then cat out.txt >&2; fail 'arm 2, kept word for word (its white space aside), is listed'; fi
[ "$(grep -c . out.txt)" = 1 ] || { cat out.txt >&2; fail 'more than the one entry is listed'; }
echo 'prd-arms-added-condition: ok'

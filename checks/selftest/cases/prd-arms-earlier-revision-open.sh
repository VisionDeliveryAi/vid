#!/bin/sh
# Purpose: selftest case — a weakening in an earlier revision stays listed (0.26.10.29.4, phase 3 R4). A first append
# rewords REQ-012's arm 2 ("mail to it bounces" → "… bounces twice", marked `retained`); a second append keeps that
# wording word for word and adds a third arm. `checks/prd.sh --arms` lists the first revision's entry once, its `now:`
# the item's fail-if as it stands today (the second revision's, the effective row), and the second revision adds none.
# Env: CHECKS.
set -eu
fail() { echo "prd-arms-earlier-revision-open: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
r12() { printf 'REQ-012 AMENDED | functional | T2 | P2 | %s | fail-if: %s | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | arms: %s\n' "$1" "$2" "$3"; }
REV1='the footer lacks a support address, or mail to it bounces twice'
REV2='the footer lacks a support address, or mail to it bounces twice, or the address is missing from any one digest'
{ cat BASE.md
  printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n'
  r12 'Every digest footer carries a support contact address that reaches a person.' "$REV1" '1 retained, 2 retained'
  printf '```\n\n### 2026-09-05 (owner answer)\n\n```vid-prd\n'
  r12 'Every digest footer carries a support contact address that reaches a person, on every digest.' "$REV2" '1 retained, 2 retained'
  printf '```\n'; } > A.md
sh "$CHECKS/prd.sh" A.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the fixture is not a lawful PRD'; }
sh "$CHECKS/prd.sh" --arms A.md > out.txt 2> err.txt || { cat err.txt >&2; fail '--arms exited non-zero'; }
printf 'REQ-012 arm 2 retained | was: mail to it bounces | now: %s\n' "$REV2" > want.txt
cmp -s want.txt out.txt || { echo '--- wanted' >&2; cat want.txt >&2; echo '--- got' >&2; cat out.txt >&2; fail "the first revision's weakening is not listed once, against today's fail-if"; }
echo 'prd-arms-earlier-revision-open: ok'

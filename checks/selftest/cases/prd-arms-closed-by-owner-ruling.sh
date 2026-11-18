#!/bin/sh
# Purpose: selftest case — the owner's ruling on the arm closes a weakening (0.26.10.29.4, phase 3 R4). A first append
# rewords REQ-012's arm 2 (`retained`, source thesis). A later append holding the human answer A-008 and a findings row
# targeting REQ-012, its evidence opening `arm 2`, dispositioned `accepted A-008` or `overruled A-008`, closes it:
# `checks/prd.sh --arms` is silent. It stays open when the row names another arm (`arm 1`, `arm 21`), another item, or
# disposes `repaired`; when A-008 is ViD's (`model_proposed`); when A-008 lies in an append before the amending row; and
# while A-008's effective row carries `delegated: yes` — until the owner confirms it, restated without the field.
# Env: CHECKS.
set -eu
fail() { echo "prd-arms-closed-by-owner-ruling: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
AMEND=$(printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n%s\n```\n' 'REQ-012 AMENDED | functional | T2 | P2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces twice | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | arms: 1 retained, 2 retained')
ans() { printf 'A-008 | %s | 2026-09-05 | Q: may the support footer bounce once? | A: yes, a single bounce is tolerated | settles: REQ-012%s\n' "$1" "${2:-}"; }
ruling() { printf 'F-20 | review | blocking | %s | %s | evidence: %s\n' "$1" "$2" "$3"; }
mk() { # <answer row> <findings row> [before] → P.md: the amendment, then (or, with before, ahead of it) the answer's append
  SIT=$(printf '\n### 2026-09-05 (owner answer)\n\n```vid-prd-answers\n%s\n```\n\n```vid-prd-findings\n%s\n```\n' "$1" "$2")
  if [ "${3:-}" = before ]; then { cat BASE.md; printf '%s\n' "$SIT"; printf '%s\n' "$AMEND"; } > P.md
  else { cat BASE.md; printf '%s\n' "$AMEND"; printf '%s\n' "$SIT"; } > P.md; fi; }
run() { sh "$CHECKS/prd.sh" --arms P.md > out.txt 2> err.txt || { cat err.txt >&2; fail "--arms exited non-zero ($1)"; }; }
closed() { run "$1"; [ ! -s out.txt ] || { cat out.txt >&2; fail "the entry stays open: $1"; }; }
open() { run "$1"; grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt || { cat out.txt >&2; fail "the entry was closed: $1"; }; }
mk "$(ans human)" "$(ruling REQ-012 'accepted A-008' 'arm 2 — the owner accepts a single bounce')"
sh "$CHECKS/prd.sh" P.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the ruling fixture is not a lawful PRD'; }
closed 'accepted A-008, a later human answer, evidence arm 2'
mk "$(ans human)" "$(ruling REQ-012 'overruled A-008' 'arm 2 — the owner keeps the narrower words')"; closed 'overruled A-008'
mk "$(ans human)" "$(ruling 'REQ-011, REQ-012' 'accepted A-008' 'arm 2 — both sides')"; closed 'a target list naming REQ-012 among others'
mk "$(ans human)" "$(ruling REQ-012 'accepted A-008' 'arm 1 — the owner accepts')"; open 'the ruling names arm 1'
mk "$(ans human)" "$(ruling REQ-012 'accepted A-008' 'arm 21 — the owner accepts')"; open 'the ruling names arm 21'
mk "$(ans human)" "$(ruling REQ-012 'accepted A-008' 'the owner accepts arm 2')"; open 'the evidence does not open with arm 2'
mk "$(ans human)" "$(ruling REQ-011 'accepted A-008' 'arm 2 — the owner accepts')"; open 'the ruling targets another item'
mk "$(ans human)" "$(ruling REQ-012 repaired 'arm 2 — repaired')"; open 'the row is repaired, not the owner ruling'
mk "$(ans model_proposed)" "$(ruling REQ-012 'accepted A-008' 'arm 2 — accepted')"; open "A-008 is ViD's (model_proposed)"
mk "$(ans human)" "$(ruling REQ-012 'accepted A-008' 'arm 2 — accepted')" before; open 'A-008 lies in an append before the amending row'
mk "$(ans human ' | delegated: yes')" "$(ruling REQ-012 'accepted A-008' 'arm 2 — accepted')"; open 'A-008 carries delegated: yes'
{ cat P.md; printf '\n### 2026-09-07 (owner answer — the delegated answer confirmed)\n\n```vid-prd-answers\n'
  printf '%s\n' 'A-008 AMENDED | human | 2026-09-07 | Q: may the support footer bounce once? | A: yes, a single bounce is tolerated | settles: REQ-012'
  printf '```\n'; } > Q.md; mv Q.md P.md
sh "$CHECKS/prd.sh" P.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the confirmed-answer fixture is not a lawful PRD'; }
closed 'A-008 confirmed by the owner (restated human without delegated: yes)'
echo 'prd-arms-closed-by-owner-ruling: ok'

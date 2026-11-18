#!/bin/sh
# Purpose: selftest case — a weakening closes when a later revision restores the old arm exactly (0.26.10.29.4,
# phase 3 R4). A first append rewords REQ-012's arm 2 ("mail to it bounces" → "… bounces twice", `retained`): listed. A
# later append whose fail-if has an arm equal to the old one, white space aside, closes it: `checks/prd.sh --arms` is
# silent. A later arm that only contains the old words ("mail to it bounces and stays unread") does not close it, and a
# file with no amendment is silent. Env: CHECKS.
set -eu
fail() { echo "prd-arms-closed-by-later-append: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
r12() { printf 'REQ-012 AMENDED | functional | T2 | P2 | %s | fail-if: %s | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | arms: %s\n' "$1" "$2" "$3"; }
S='Every digest footer carries a support contact address that reaches a person.'
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n'
  r12 "$S" 'the footer lacks a support address, or mail to it bounces twice' '1 retained, 2 retained'; printf '```\n'; } > A.md
arms() { sh "$CHECKS/prd.sh" --arms "$1" > out.txt 2> err.txt || { cat err.txt >&2; fail "--arms exited non-zero on $1"; }; }
arms A.md
grep -qxF 'REQ-012 arm 2 retained | was: mail to it bounces | now: the footer lacks a support address, or mail to it bounces twice' out.txt \
  || { cat out.txt >&2; fail 'the weakening is not listed before the restoration'; }
later() { # <fail-if> → B.md: A.md and a later append carrying it, every arm of the first revision accounted
  { cat A.md; printf '\n### 2026-09-05 (owner answer)\n\n```vid-prd\n'
    r12 "$S On every digest." "$1" '1 retained, 2 retained'; printf '```\n'; } > B.md; }
later 'the footer lacks a support address, or mail to it bounces twice, or mail  to it bounces'
sh "$CHECKS/prd.sh" B.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the restoring fixture is not a lawful PRD'; }
arms B.md
[ ! -s out.txt ] || { cat out.txt >&2; fail 'a later revision with an arm equal to the old one (white space aside) did not close the entry'; }
later 'the footer lacks a support address, or mail to it bounces twice, or mail to it bounces and stays unread'
arms B.md
grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt \
  || { cat out.txt >&2; fail 'a later arm that only contains the old words closed the entry'; }
arms BASE.md
[ ! -s out.txt ] || { cat out.txt >&2; fail 'a file with no amendment is not silent'; }
echo 'prd-arms-closed-by-later-append: ok'

#!/bin/sh
# Purpose: selftest case — a ruling in the same sitting closes a weakening (0.26.10.29.4, phase 3 R4, the master
# session's ruling 2). One append holds the amendment rewording REQ-012's arm 2 (`retained`, source thesis), the human
# answer A-008 and a findings row targeting REQ-012, evidence `arm 2 …`, `accepted A-008`: `checks/prd.sh --arms` is
# silent. The same answer carrying `delegated: yes`, or cited by the amending row's `source:` (as `A-008`, or by its leading id, `A-008 (…)`,
# `A-008 §2`, or as a whole identifier inside an entry, `thesis (A-008)`, `SRC-001 (A-008)`, as join 17 reads it), does
# not close it, nor `A-008[9]` beside a file named A-0089 (no pathname expansion); an id holding A-008 only as a part (`A-0081`, `XA-008`) is no citation of it.
# Env: CHECKS.
set -eu
fail() { echo "prd-arms-same-sitting-ruling: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
grep -v '^REQ-002 AMENDED ' "$CHECKS/selftest/fixtures/prd-known-good.md" > BASE.md
mk() { # <source> <answer's extra field>
  { cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd-answers\n'
    printf 'A-008 | human | 2026-09-01 | Q: may the support footer bounce once? | A: yes, a single bounce is tolerated | settles: REQ-012%s\n' "$2"
    printf '```\n\n```vid-prd\n'
    printf 'REQ-012 AMENDED | functional | T2 | P2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces twice | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: %s | covers: DIM-nfr-operability/support | arms: 1 retained, 2 retained\n' "$1"
    printf '```\n\n```vid-prd-findings\n%s\n```\n' 'F-20 | review | blocking | REQ-012 | accepted A-008 | evidence: arm 2 — the owner accepts a single bounce, at this sitting'
  } > P.md; }
run() { sh "$CHECKS/prd.sh" --arms P.md > out.txt 2> err.txt || { cat err.txt >&2; fail "--arms exited non-zero ($1)"; }; }
mk thesis ''
sh "$CHECKS/prd.sh" P.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the same-sitting fixture is not a lawful PRD'; }
run 'the same-sitting ruling'
[ ! -s out.txt ] || { cat out.txt >&2; fail "the owner's ruling in the amending row's own append did not close the entry"; }
mk thesis ' | delegated: yes'; run 'delegated'
grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt || { cat out.txt >&2; fail 'a same-sitting answer carrying delegated: yes closed the entry'; }
# every answer join 17 reads as cited (a leading id, or a whole identifier anywhere in an entry) is cited here too
for src in 'thesis, A-008' 'A-008 (the sitting of 2026-09-01)' 'thesis, A-008 §2' 'thesis (A-008)' 'SRC-001 (A-008)'; do
  mk "$src" ''; run "cited: $src"
  grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt || { cat out.txt >&2; fail "a same-sitting answer the amending row's source: cites ('$src') closed the entry"; }
done
# a glob character in an entry never expands against the working directory: with a file A-0089 beside the PRD,
# `source: A-008[9]` still cites A-008 (its leading id) and keeps the entry open
: > A-0089
mk 'A-008[9]' ''; run 'glob'
grep -q '^REQ-012 arm 2 retained | was: mail to it bounces | now: ' out.txt || { cat out.txt >&2; fail "source: 'A-008[9]' beside a file A-0089 was expanded, so the cited A-008 closed the entry"; }
rm -f A-0089
# an id that only holds A-008 as a part is not a citation of it (join 17's identifier boundary): the ruling closes the entry
for src in 'thesis (A-0081)' 'thesis (XA-008)'; do
  mk "$src" ''; run "not cited: $src"
  [ ! -s out.txt ] || { cat out.txt >&2; fail "source: '$src' was read as citing A-008, so the same-sitting ruling did not close the entry"; }
done
echo 'prd-arms-same-sitting-ruling: ok'

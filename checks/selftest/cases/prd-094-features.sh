#!/bin/sh
# Purpose: selftest case — prd.sh join 16, the features (v0.9.4 spec §3.2,
# §7 case 3), gated on `grammar: 0.9.4`. From the 0.9.4 known-good fixture,
# each of these convicts: a demand item without feature:; two feature:
# fields; `feature: FEAT-01, FEAT-02`; an undeclared feature; a goal
# neither in ### MVP focus nor `-`; a duplicate base id; an AMENDED feature
# row with no ancestor. Each of these acquits: an appended feature with
# goal `-` (a NOTE); a feature with no demand item (listed by --pause,
# never convicted); a pause-1 file carrying a features block and no items
# (a NOTE when the features do not outnumber the goals). The same missing
# feature: on the 0.9.1 file convicts nothing. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-features: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
convicts() { # file, wanted GAP substring — one run: default mode prints the gaps and the report line
  run "$1"; [ "$RC" -ne 0 ] || fail "$1 acquitted, expected a conviction ($2)"
  gaps | grep -qF "$2" || { gaps | head -3 >&2; fail "$1 convicted but not for '$2'"; }
}
acquits() { run "$1" ${2:-}; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted, expected an acquittal"; }; }
cp "$FIXTURES/prd-094-good.md" G.md
acquits G.md
# --- convictions
sed 's/^\(REQ-003 .*\) | feature: FEAT-02$/\1/' G.md > NOFEAT.md
grep -q '^REQ-003 .*feature:' NOFEAT.md && fail 'the NOFEAT mutation did not apply'
convicts NOFEAT.md 'GAP  join 16 (REQ-003): no feature: — every demand item and invariant belongs to exactly one feature.'
sed 's/^\(INV-001 .*\) | feature: FEAT-01$/\1/' G.md > NOFEATINV.md
convicts NOFEATINV.md 'GAP  join 16 (INV-001): no feature:'
sed 's/^\(REQ-001 .*\) | feature: FEAT-01$/\1 | feature: FEAT-01 | feature: FEAT-03/' G.md > TWO.md
convicts TWO.md 'GAP  join 16 (REQ-001): 2 feature: fields — an item belongs to exactly one feature.'
sed 's/^\(REQ-001 .*\) | feature: FEAT-01$/\1 | feature: FEAT-01, FEAT-02/' G.md > LIST.md
convicts LIST.md "GAP  join 16 (REQ-001): feature: 'FEAT-01, FEAT-02' is not a single FEAT-NN"
sed 's/^\(REQ-001 .*\) | feature: FEAT-01$/\1 | feature: FEAT-09/' G.md > UNDECL.md
convicts UNDECL.md 'GAP  join 16 (REQ-001): feature: FEAT-09 names no declared feature'
sed 's/^FEAT-02 | G2 | /FEAT-02 | G7 | /' G.md > GOAL.md
convicts GOAL.md "GAP  join 16 (FEAT-02): goal 'G7' is no goal label in ### MVP focus"
sed 's/^\(FEAT-03 | G1 | subscriber care and exit\)$/\1\
FEAT-01 | G2 | the daily digest, again/' G.md > DUP.md
[ "$(grep -c '^FEAT-01 |' DUP.md)" -eq 2 ] || fail 'the DUP mutation did not apply'
convicts DUP.md 'GAP  join 16: duplicate feature id FEAT-01'
{ cat G.md; printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-features\nFEAT-07 AMENDED | G1 | a rename of nothing\n```\n'; } > ANC.md
convicts ANC.md 'GAP  join 16 (FEAT-07 AMENDED): no earlier features row with id FEAT-07'
# --- acquittals
# an appended feature with goal `-`, and an appended item in it: a NOTE, no gap
cat G.md > DASH.md
cat >> DASH.md <<'APP'

### 2026-09-02 (/vid add)

```vid-prd-features
FEAT-04 | - | referral rewards
```

```vid-prd
REQ-021 | functional | T2 | A subscriber can forward a digest to a friend, who can subscribe from it. | fail-if: a forwarded digest carries no subscribe path, or subscribing from it skips address confirmation | serves: an outcome the frozen thesis did not name — word of mouth | authority: authoritative | source: thesis | phase: pilot | feature: FEAT-04
```
APP
acquits DASH.md
printf '%s\n' "$OUT" | grep -qF 'NOTE  join 16 (FEAT-04): goal - — serves no ratified goal' || fail 'the goal - NOTE is missing'
# a feature with no demand item: acquits; --pause lists it
sed 's/^\(FEAT-03 | G1 | subscriber care and exit\)$/\1\
FEAT-05 | G2 | saved-search sharing/' G.md > EMPTY.md
acquits EMPTY.md
acquits EMPTY.md --pause
printf '%s\n' "$OUT" | grep -qx 'features with no demand item: 1 — FEAT-05' || fail '--pause does not list the empty feature'
# a pause-1 file: a features block, no items — acquits; features not outnumbering goals is a NOTE
cat > P1.md <<'P1'
# Toy — PRD
grammar: 0.9.4

## Seed

A toy seed with two goals.

## Thesis

### MVP focus

- G1: the first goal.
- G2: the second goal.

## Mechanisms

```vid-prd-mechanisms
MECH-01 | G1 | the first mechanism | stated: seed "A toy seed"
MECH-02 | G2 | the second mechanism | stated: answer A-002
```

## Content contract

```vid-prd-contract
DIM-notifications | Notifications | mechanism | required | covered_by: functional | status: covered
```

## Items

```vid-prd-features
FEAT-01 | G1 | the first part
FEAT-02 | G2 | the second part
FEAT-03 | G1 | the third part
```

## Answer ledger

```vid-prd-answers
A-001 | human | 2026-09-01 | Q: the contract sitting? | A: the one dimension kept | settles: contract
A-002 | model_proposed | 2026-09-01 | Q: which mechanism serves the second goal? | A: the second mechanism | settles: MECH-02
```
P1
acquits P1.md
printf '%s\n' "$OUT" | grep -q '^NOTE' && fail 'the pause-1 file with three features for two goals carries a NOTE'
sed '/^FEAT-03 | G1 | the third part$/d' P1.md > P1B.md
acquits P1B.md
printf '%s\n' "$OUT" | grep -qF 'NOTE  join 16: 2 feature(s) for 2 goal(s) — a feature is narrower than a goal.' || fail 'no NOTE for features not outnumbering goals'
# the grammar gate: the same missing feature: under 0.9.1 convicts nothing
sed 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' NOFEAT.md > NOFEAT091.md
acquits NOFEAT091.md
exit 0

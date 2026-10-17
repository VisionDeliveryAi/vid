#!/bin/sh
# Purpose: selftest case — prd.sh's pause material (v0.9.4 spec §3.5, §7
# case 11). A plant on the 0.9.4 known-good fixture: four ViD decisions
# written in REVERSE rank order — A-021 grounding one T2 item, A-022 one T1,
# A-023 three T1, A-024 (the highest id) one T0 — print A-024, A-023, A-022,
# A-021 (a court printing in id order fails); the fixture's shown decisions
# (A-005, A-007) are not printed; the must-never-break question prints with
# its recommendation and the T0 item waiting on it; a near-duplicate pair
# prints, and not once a findings row names both ids; a sensitive T1 item
# (on a ViD decision, covering consent) prints; a measurement item without
# golden-set prints and the golden-set one does not; the features' pilot
# counts sum to the size line's pilot demand count. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-material: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
awk '/^VID-QUESTION: \(OQ-3\)/ { print; print ""; print "VID-QUESTION: (OQ-9) A-024 — May an operator read a subscriber'"'"'s saved searches while investigating a complaint?"; next } { print }' "$FIXTURES/prd-094-good.md" > P.md
cat >> P.md <<'APP'

### 2026-09-03 (gap augment)

```vid-prd-answers
A-021 | model_proposed | 2026-09-03 | Q: may a digest carry a sponsored listing? | A: no sponsored listings at launch | settles: REQ-050
A-022 | model_proposed | 2026-09-03 | Q: does saving a search imply consent to digests? | A: yes — saving a search is the consent, stated at the save | settles: REQ-051
A-023 | model_proposed | 2026-09-03 | Q: how are listing locations shown? | A: town and region, never a street address | settles: REQ-052, REQ-053, REQ-054
A-024 | model_proposed | 2026-09-03 | Q: may an operator read saved searches? | A: only while a complaint names the subscriber, and every read is logged | settles: INV-010
```

```vid-prd
REQ-050 | functional | T2 | A digest never carries a sponsored or paid listing. | fail-if: a digest shows a listing placed by payment | serves: the digest stays a neutral alert | authority: provisional | confirms_via: owner-decision/no | source: A-021 | phase: pilot | feature: FEAT-01
REQ-051 | functional | T1 | Saving a search records the subscriber's consent to receive its digests, stated on the save screen. | fail-if: a digest is sent for a search whose save screen stated no consent | serves: lawful contact from the first digest | authority: provisional | confirms_via: owner-decision/no | source: A-022 | covers: DIM-consent | phase: pilot | feature: FEAT-03
REQ-052 | ux_flow | T1 | A listing card shows its town and region. | fail-if: a card omits the town or the region | serves: subscribers judge commute at a glance | authority: provisional | confirms_via: owner-decision/no | source: A-023 | phase: pilot | feature: FEAT-01
REQ-053 | functional | T1 | Search matches a query's place against the listing's town and region. | fail-if: a listing in the queried town is missing from its results | serves: place is how trades search | authority: provisional | confirms_via: owner-decision/no | source: A-023 | phase: pilot | feature: FEAT-02
REQ-054 | data_entity | T1 | A stored listing keeps its town and region and drops any street address the feed sends. | fail-if: a stored listing retains a street address | serves: the store holds only what the card shows | authority: provisional | confirms_via: owner-decision/no | source: A-023 | phase: pilot | feature: FEAT-01
REQ-060 | functional | T2 | Every digest footer carries a support contact address that reaches a person within one business day. | fail-if: the footer lacks a support address, or a reply takes longer than one business day | serves: a stuck subscriber hears back | authority: authoritative | source: thesis | phase: pilot | feature: FEAT-03
REQ-061 | nfr | T2 | Digest assembly keeps pace with the daily feed volume. | fail-if: a daily run ends with digests unassembled | serves: digests arrive the morning they are due | authority: provisional | confirms_via: measurement/no | source: thesis | phase: pilot | feature: FEAT-01
INV-010 | invariant | T0 | No operator reads a subscriber's saved searches except while a complaint names that subscriber, and every read is logged. | serves: saved searches reveal job hunting — an unlogged read is a leak | authority: provisional | confirms_via: owner-decision OQ-9/yes | source: A-024 | phase: pilot | feature: FEAT-03
```
APP
run P.md; [ "$RC" -eq 0 ] || { printf '%s\n' "$OUT" | grep '^GAP' | head -3 >&2; fail 'the plant is not court-green by default'; }
run P.md --pause --report
M=$(printf '%s\n' "$OUT" | sed -n '/^new ViD decisions /,/^sensitive /p' | sed -n 's/^  \(A-[0-9]*\).*/\1/p' | tr '\n' ' ')
[ "$M" = 'A-024 A-023 A-022 A-021 ' ] || fail "the ranked list reads '$M', expected 'A-024 A-023 A-022 A-021 '"
printf '%s\n' "$OUT" | grep -qF '  A-024 | ' || fail 'no sum on the T0 decision line'
printf '%s\n' "$OUT" | grep -qE '^  A-024 \| [0-9]+ \| grounds T0 1 · T1 0 · T2 0 \(items INV-010\) \| A: only while a complaint names the subscriber, and every read is logged$' || fail 'the T0 decision line is malformed'
printf '%s\n' "$OUT" | grep -qE '^  A-023 \| [0-9]+ \| grounds T0 0 · T1 3 · T2 0 \(items REQ-052, REQ-053, REQ-054\) \| ' || fail 'the T1x3 decision line is malformed'
printf '%s\n' "$OUT" | grep -qE '^  A-00[57] ' && fail 'a shown decision is printed as new'
printf '%s\n' "$OUT" | grep -qF "  OQ-9 A-024 — May an operator read a subscriber's saved searches while investigating a complaint? | recommended: only while a complaint names the subscriber, and every read is logged | waiting: INV-010" || fail 'the must-never-break question is missing'
printf '%s\n' "$OUT" | grep -qE '^  REQ-012 ~ REQ-060 \| overlap [0-9.]+ · jaccard [0-9.]+$' || fail 'the near-duplicate pair does not print'
printf '%s\n' "$OUT" | grep -qF '  REQ-051 | T1 | DIM-consent | rests on A-022' || fail 'the sensitive T1 item does not print'
printf '%s\n' "$OUT" | grep -qF '  REQ-061 | provisional | confirms_via: measurement/no | no derives: golden-set' || fail 'the measurement item without golden-set does not print'
printf '%s\n' "$OUT" | sed -n '/^measurement and external-dependency/,/^near-duplicates/p' | grep -qE '^  REQ-003 ' && fail 'the golden-set measurement item is listed'   # v0.9.5: read in its own section — the plain sentences list every item
P=$(printf '%s\n' "$OUT" | sed -n 's/^size: demand=[0-9]* pilot=\([0-9]*\) .*/\1/p')
S=$(printf '%s\n' "$OUT" | sed -n 's/^  FEAT-[0-9]* | .* | pilot demand \([0-9]*\) | T0 [0-9]*$/\1/p' | awk '{ s += $1 } END { print s + 0 }')
[ -n "$P" ] && [ "$P" -eq "$S" ] || fail "the features' pilot counts sum to $S, the size line says pilot=$P"
[ "$P" -gt 0 ] || fail 'no pilot demand counted'
# a findings row naming both ids retires the pair
awk '{ print } /^F-05 \| lens/ { print "F-06 | review | advisory | REQ-012, REQ-060 | noted | evidence: near-duplicate kept — the reply bound is its own decision" }' P.md > PK.md
run PK.md --pause --report
printf '%s\n' "$OUT" | grep -qE '^  REQ-012 ~ REQ-060 ' && fail 'a kept pair is shown again'
printf '%s\n' "$OUT" | grep -q '^near-duplicates (not yet ruled; .*): 0$' || fail 'the near-duplicate count is not 0 once the pair is recorded'
exit 0

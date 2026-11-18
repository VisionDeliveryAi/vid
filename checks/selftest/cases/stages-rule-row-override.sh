#!/bin/sh
# Purpose: selftest case — a row: line overrides the by-origin reading (0.26.10.29.4, phase 4 R2). On the three-stage
# toy with `rules: by-origin`: RULE-001 with `origin: REQ-003` (stage 3) and `row: RULE-001 -> STAGE-2` reads 2;
# with `origin: domain` and `row: RULE-001 -> STAGE-3` reads 3; as a Tier-0 rule (tier 0) with `origin: REQ-004` and
# `row: RULE-001 -> STAGE-3`, reads 3. As a control, `origin: REQ-003` with no row: line reads 3. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-rule-row-override: $*" >&2; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv; cp INVENTORY.md "$T/inv0"
cut() { st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'rules: by-origin' "row: RULE-001 -> STAGE-$1"; }
sed 's/^\(rule | RULE-001 | .*\)$/\1 | origin: REQ-003/' "$T/inv0" > INVENTORY.md
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'rules: by-origin'
[ "$(sh checks/stages.sh stage-of RULE-001 2>&1)" = 3 ] || fail "the control, origin REQ-003 with no row: line, is not in stage 3: $(sh checks/stages.sh stage-of RULE-001 2>&1)"
cut 2
[ "$(sh checks/stages.sh stage-of RULE-001)" = 2 ] || fail "a row: line to stage 2 did not override the origin's stage 3: $(sh checks/stages.sh stage-of RULE-001)"
sed 's/^\(rule | RULE-001 | .*\)$/\1 | origin: domain/' "$T/inv0" > INVENTORY.md; cut 3
[ "$(sh checks/stages.sh stage-of RULE-001)" = 3 ] || fail "a row: line to stage 3 did not place a rule of origin domain: $(sh checks/stages.sh stage-of RULE-001)"
sed 's/^rule | RULE-001 | \(.*\) | 1 | \(tests[^|]*\)$/rule | RULE-001 | \1 | 0 | \2 | origin: REQ-004/' "$T/inv0" > INVENTORY.md; cut 3
grep -q '^rule | RULE-001 | .* | 0 | tests/invariants/test_rule.py | origin: REQ-004$' INVENTORY.md || fail 'the fixture did not take tier 0'
[ "$(sh checks/stages.sh stage-of RULE-001)" = 3 ] || fail "a row: line to stage 3 did not place a Tier-0 rule: $(sh checks/stages.sh stage-of RULE-001)"
exit 0

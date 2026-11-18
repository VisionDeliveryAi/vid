#!/bin/sh
# Purpose: selftest case — a Tier-0 rule row stays stage 1 (0.26.10.29.4, phase 4 R2): a must-never-break rule covers the
# code from the first stage. On the three-stage toy with `rules: by-origin`, RULE-001 with its tier `0`, then `T0`, and
# `origin: REQ-003` (stage 3) reads stage 1 and is in `scope --upto 1`; the same rule at tier 1 reads 3, as a control.
# The tier is the field before the test, read from the right: a census command holding `|` does not move it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-rule-tier0-stays: $*" >&2; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv; cp INVENTORY.md "$T/inv0"
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'rules: by-origin'
tier() { printf '%s\n' "rule | RULE-001 | every note write is logged | $2 | $1 | tests/invariants/test_rule.py | origin: REQ-003" > "$T/rl"
  grep -v '^rule | RULE-001 ' "$T/inv0" | awk -v f="$T/rl" '/^hostility \| HOS-001 / { while ((getline l < f) > 0) print l } { print }' > INVENTORY.md; }
tier 1 'echo app/main.py'
[ "$(sh checks/stages.sh stage-of RULE-001)" = 3 ] || fail "the tier-1 control, its origin in stage 3, is not in stage 3: $(sh checks/stages.sh stage-of RULE-001)"
for t in 0 T0; do for c in 'echo app/main.py' 'ls app | grep main'; do tier "$t" "$c"
  [ "$(sh checks/stages.sh stage-of RULE-001)" = 1 ] || fail "a rule at tier $t (census '$c'), its origin in stage 3, is not in stage 1: $(sh checks/stages.sh stage-of RULE-001)"
  sh checks/stages.sh scope --upto 1 | grep -qx RULE-001 || fail "a rule at tier $t is not in scope --upto 1"
done; done
exit 0

#!/bin/sh
# Purpose: selftest case — a census row goes to the first stage that needs it (0.26.10.29.4, phase 4 R2). On the toy
# product (fixtures/stages.sh) cut in three stages (stage 2 FEAT-03 with REQ-004, stage 3 REQ-003 by a split: line) and
# the line `rules: by-origin`, RULE-001 with `origin: REQ-003, REQ-004` (stages 3 and 2) reads stage 2 in `stage-of`,
# is out of `scope --upto 1` and in `scope --upto 2`, and the court passes the cut. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-rule-earliest-origin: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv
sed 's/^\(rule | RULE-001 | .*\)$/\1 | origin: REQ-003, REQ-004/' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
grep -q '^rule | RULE-001 .* | origin: REQ-003, REQ-004$' INVENTORY.md || fail 'the fixture did not take the origin'
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'rules: by-origin'
git add -A
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the court refused a cut carrying rules: by-origin'
[ "$(sh checks/stages.sh stage-of RULE-001)" = 2 ] || fail "RULE-001, its origin in stages 3 and 2, is not in stage 2: $(sh checks/stages.sh stage-of RULE-001)"
sh checks/stages.sh scope --upto 1 | grep -qx RULE-001 && fail 'RULE-001 is in scope --upto 1'
sh checks/stages.sh scope --upto 2 | grep -qx RULE-001 || fail 'RULE-001 is not in scope --upto 2'
exit 0

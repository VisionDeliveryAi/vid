#!/bin/sh
# Purpose: selftest case — existing cuts read as before (0.26.10.29.4, phase 4 R2). On the same three-stage toy as
# stages-rule-earliest-origin, without the line `rules: by-origin`, RULE-001 with `origin: REQ-003, REQ-004` (stages
# 3 and 2) reads stage 1 in `stage-of` and is in `scope --upto 1`, as every census row did before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-rule-default-without-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv
sed 's/^\(rule | RULE-001 | .*\)$/\1 | origin: REQ-003, REQ-004/' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2'
git add -A
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the court refused the cut'
[ "$(sh checks/stages.sh stage-of RULE-001)" = 1 ] || fail "without rules: by-origin RULE-001 is not in stage 1: $(sh checks/stages.sh stage-of RULE-001)"
sh checks/stages.sh scope --upto 1 | grep -qx RULE-001 || fail 'without rules: by-origin RULE-001 is not in scope --upto 1'
# and the line, added, moves it (the reading is the line's alone)
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'rules: by-origin'
[ "$(sh checks/stages.sh stage-of RULE-001)" = 2 ] || fail "with rules: by-origin RULE-001 is not in stage 2: $(sh checks/stages.sh stage-of RULE-001 2>&1)"
exit 0

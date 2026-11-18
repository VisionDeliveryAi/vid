#!/bin/sh
# Purpose: selftest case — a census row whose origin names no staged PRD item stays stage 1 (0.26.10.29.4, phase 4 R2).
# On the three-stage toy (stage 2 FEAT-03, stage 3 REQ-003 by a split: line), with `rules: by-origin` and without it,
# RULE-001 reads stage 1 when its origin is `domain`, `finding-007`, `derivation 2026-11-15`, absent, or names only
# REQ-005, a `phase: later` item; as a control, with the line, `origin: REQ-004` reads 2. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-rule-domain-stage-1: $*" >&2; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv; cp INVENTORY.md "$T/inv0"
for L in '' 'rules: by-origin'; do
  st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
    'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' ${L:+"$L"}
  for O in 'domain' 'finding-007' 'derivation 2026-11-15' '-' 'REQ-005'; do
    if [ "$O" = - ]; then cp "$T/inv0" INVENTORY.md; else sed "s/^\(rule | RULE-001 | .*\)\$/\1 | origin: $O/" "$T/inv0" > INVENTORY.md; fi
    S=$(sh checks/stages.sh stage-of RULE-001 2>&1 || true)
    [ "$S" = 1 ] || fail "RULE-001 with origin '$O' (${L:-no rules: line}) is in stage $S, not 1"
  done
done
sed 's/^\(rule | RULE-001 | .*\)$/\1 | origin: REQ-005, REQ-004/' "$T/inv0" > INVENTORY.md
[ "$(sh checks/stages.sh stage-of RULE-001 2>&1)" = 2 ] || fail "the control, origin REQ-005 (later) and REQ-004 (stage 2) with the line, is not in stage 2: $(sh checks/stages.sh stage-of RULE-001 2>&1)"
exit 0

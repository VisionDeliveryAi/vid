#!/bin/sh
# Purpose: selftest case — the readers with stage 0 (v0.26.10.8 spec R2; §5 stages-scope-stage0). On the toy product
# (fixtures/stages.sh) cut as STAGE-0 (technical, ROW-001 and ROW-002 placed by row: lines), STAGE-1 and STAGE-2, with
# HOS-003 protecting ROW-002: `scope --upto 0` is exactly ROW-001 ROW-002 HOS-003 — the placed rows and their probe,
# no census row (RULE-001 stays in stage 1) and, with --reqs, no requirement (theirs keep their stages); `scope
# --upto 1` includes them; `stage-of` prints 0 for a placed row and 1 for its requirement; `current` gives 0 with no
# `stage:` line (1 without STAGE-0); `counts` prints `stage 0 requirements=0 rows=3`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-scope-stage0: $*" >&2; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv
awk '/^hostility \| HOS-002 /{ print; print "hostility | HOS-003 | lose a saved note on restart | protects: ROW-002 | disable: drop the write | tests/invariants/test_hos2.py"; next } { print }' INVENTORY.md > INVENTORY.x && mv INVENTORY.x INVENTORY.md
st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-001 -> STAGE-0' 'row: ROW-002 -> STAGE-0'
sh checks/stages.sh check > "$T/c" 2>&1 || fail "the court refused the toy cut: $(cat "$T/c")"
[ "$(sh checks/stages.sh scope --upto 0 | tr '\n' ' ')" = 'ROW-001 ROW-002 HOS-003 ' ] || fail "scope --upto 0 is not ROW-001 ROW-002 HOS-003: $(sh checks/stages.sh scope --upto 0 | tr '\n' ' ')"
[ "$(sh checks/stages.sh scope --upto 0 --reqs | tr '\n' ' ')" = 'ROW-001 ROW-002 HOS-003 ' ] || fail 'scope --upto 0 --reqs holds a requirement'
U1=$(sh checks/stages.sh scope --upto 1 | tr '\n' ' ')
for id in ROW-001 ROW-002 HOS-003 RULE-001 HOS-002; do case " $U1" in *" $id "*) ;; *) fail "scope --upto 1 lacks $id: $U1" ;; esac; done
[ "$(sh checks/stages.sh stage-of ROW-001)" = 0 ] && [ "$(sh checks/stages.sh stage-of HOS-003)" = 0 ] || fail 'stage-of does not print 0 for a stage-0 row and its probe'
[ "$(sh checks/stages.sh stage-of REQ-001)" = 1 ] || fail "a stage-0 row's requirement left its own stage"
[ "$(sh checks/stages.sh current)" = 0 ] || fail 'current is not 0 with no stage: line'
mkdir -p .vid; printf 'run: active\nstage: 1\n' > .vid/RUN-STATE.md
[ "$(sh checks/stages.sh current)" = 1 ] || fail 'current does not read stage: 1'
rm .vid/RUN-STATE.md
sh checks/stages.sh counts > "$T/n"
grep -qx 'stage 0 requirements=0 rows=3 | the skeleton' "$T/n" || fail "counts does not print stage 0: $(cat "$T/n")"
grep -qx 'stage 1 requirements=2 rows=2 | the basics' "$T/n" || fail "counts' stage 1 is not 2 requirements and 2 rows: $(cat "$T/n")"
# without STAGE-0, current is 1 again
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2'
[ "$(sh checks/stages.sh current)" = 1 ] || fail 'current is not 1 without STAGE-0'
[ -z "$(sh checks/stages.sh scope --upto 0)" ] || fail 'scope --upto 0 is not empty without STAGE-0'
exit 0

#!/bin/sh
# Purpose: selftest case — two usable stages inside one feature (v0.26.10.5 amendment 1, R1a). On the toy product
# (fixtures/stages.sh), a three-stage cut whose stage 2 lists no feature (`features: -`) and holds REQ-003 by a split:
# line passes the court (staged, as pre-commit reads it); scope and stage-of read it (ROW-003 in stage 2), and
# `stages.sh counts` gives each stage the numbers `scope --upto k [--reqs]` minus `--upto k-1` give (requirements by
# REQ id), and the block's row: lines; with no STAGES.md (the single-stage rung) it gives stage 1 the whole scope. A
# stage that lists no feature and receives no split: is refused, named.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-split-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_files
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | tags | features: -' 'STAGE-3 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-3'
git add -A
sh checks/stages.sh > "$T/out" 2>&1 || fail 'a stage fed only by a split: line was refused'
[ "$(sh checks/stages.sh stage-of ROW-003)" = 2 ] && [ "$(sh checks/stages.sh stage-of REQ-003)" = 2 ] || fail 'REQ-003 and its row are not in stage 2'
sh checks/stages.sh counts > "$T/out" 2>&1
d() { _a=$(sh checks/stages.sh scope --upto "$1" $2 | grep -c "^$3" || true); _b=$(sh checks/stages.sh scope --upto "$(($1 - 1))" $2 | grep -c "^$3" || true); echo $((_a - _b)); }
for k in 1 2 3; do
  W="stage $k requirements=$(d "$k" --reqs REQ-) rows=$(d "$k" '' '[A-Z]')"
  grep -q "^$W |" "$T/out" || fail "counts does not say '$W' (scope's differences)"
done
grep -qx 'stage 2 requirements=1 rows=1 | tags' "$T/out" && grep -qx 'row-lines=1' "$T/out" || fail 'counts does not give stage 2 one requirement and one row, and one row: line'
# the single-stage rung: no STAGES.md, every stage-able obligation and requirement in stage 1
rm STAGES.md
sh checks/stages.sh counts > "$T/out" 2>&1
W="stage 1 requirements=$(sh checks/stages.sh scope --upto 1 --reqs | grep -c '^REQ-') rows=$(sh checks/stages.sh scope --upto 1 | grep -c .)"
grep -q "^$W |" "$T/out" && grep -qx 'row-lines=0' "$T/out" || fail "with no STAGES.md counts does not say '$W' and row-lines=0"
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | nothing | features: -' 'STAGE-3 | sharing | features: FEAT-03' 'row: ROW-006 -> STAGE-3'
git add -A
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'a stage holding nothing passed'; fi
grep -q 'STAGE-2 holds nothing: it lists no feature and no split: line moves a requirement to it' "$T/out" || fail 'the empty stage is not named'
exit 0

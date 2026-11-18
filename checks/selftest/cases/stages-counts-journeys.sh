#!/bin/sh
# Purpose: selftest case — every stage's line in `stages.sh counts` gives its journeys (0.26.10.29.4, phase 4 R3). On the
# toy product (fixtures/stages.sh) cut in three stages, with journey rows in two of them (ROW-006 placed in stage 2;
# ROW-007, a journey deriving from REQ-003, in stage 3 by REQ-003's split: line) and none in stage 1, each stage's line
# is `stage <k> requirements=<n> rows=<n> journeys=<n> | <name>`, `journeys=` after `rows=` and before ` | <name>`:
# 0, 1 and 1. The rows= and requirements= numbers stay scope's differences. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-counts-journeys: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv
awk '{ print } /^ROW-006 / { print "ROW-007 | journey | /tags | anonymous | n/a | tag a note, then find it by the tag | REQ-003 | tests/invariants/test_c.py" }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | tags | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2'
git add -A
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the court refused the three-stage cut'
sh checks/stages.sh counts > "$T/out" 2>&1
d() { _a=$(sh checks/stages.sh scope --upto "$1" $2 | grep -c "^$3" || true); _b=$(sh checks/stages.sh scope --upto "$(($1 - 1))" $2 | grep -c "^$3" || true); echo $((_a - _b)); }
for kj in '1 0 the basics' '2 1 sharing' '3 1 tags'; do k=${kj%% *}; r=${kj#* }; j=${r%% *}; nm=${r#* }
  W="stage $k requirements=$(d "$k" --reqs REQ-) rows=$(d "$k" '' '[A-Z]') journeys=$j | $nm"
  grep -qx "$W" "$T/out" || fail "counts does not say '$W'"
done
exit 0

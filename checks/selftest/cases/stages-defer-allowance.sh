#!/bin/sh
# Purpose: selftest case — deferring a feature's item to later, with its split: line kept for one commit (0.26.10.29.4,
# phase 4 R5). On the toy product (fixtures/stages.sh) committed with its cut (REQ-003 split to stage 2, its row ROW-003
# placed there by a row: line), the commit whose staged PRD.md makes REQ-003 `phase: later` passes the stage court
# with the split: and row: lines still naming it, as a feature a commit adds may stay unplaced at it. The next commit
# that is not the law commit removing them is refused, naming the split: line and the row: line; the law commit
# removing them passes. A split: line naming an item already later at HEAD is refused as before. And a stage fed only by
# that split: line (`features: -`, the cut of stages-split-stage) still holds it at the deferring commit: the commit
# passes, not refused as a stage holding nothing; the next commit is refused until the law commit removes the line.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-defer-allowance: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_files
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-003 -> STAGE-2'
g add -A; sh checks/stages.sh > "$T/out" 2>&1 || fail 'the base cut was refused'; g commit -qm 'the toy and its cut'
# the owner's deferral: REQ-003 later, STAGES.md untouched
sed 's/^\(REQ-003 .*\)| phase: pilot |/\1| phase: later |/' PRD.md > "$T/p" && cp "$T/p" PRD.md
grep -q '^REQ-003 .*| phase: later |' PRD.md || fail 'the fixture did not take the deferral'
g add PRD.md
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the commit making REQ-003 later was refused for the split: and row: lines it keeps'
g commit -qm 'REQ-003 waits for later, A-009'
# the next commit, not the law commit: refused
printf 'z\n' > x.txt; g add x.txt
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'a commit after the deferral passed with the split: line still naming the later item'; fi
grep -q 'split: REQ-003 is phase: later' "$T/out" && grep -q 'row: ROW-003 is placed, but every item it derives from is phase: later' "$T/out" || fail 'the refusal does not name the split: line and the row: line'
# the law commit removing them: passes
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'row: ROW-006 -> STAGE-2'
g add STAGES.md; g reset -q x.txt
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the law commit removing the lines was refused'
g commit -qm 'the cut without REQ-003, A-009'
# an item already later at HEAD: a split: naming it is refused as before
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'row: ROW-006 -> STAGE-2' 'split: REQ-005 -> STAGE-2'
g add STAGES.md
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'a split: naming an item later at HEAD passed'; fi
grep -q 'split: REQ-005 is phase: later' "$T/out" || fail 'the refusal does not name REQ-005'
# a stage fed only by the split: line of the item deferred
rm -rf "$T/r2"; mkdir -p "$T/r2/checks"; cd "$T/r2"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_files
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | tags | features: -' 'STAGE-3 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-3'
g add -A; sh checks/stages.sh > "$T/out" 2>&1 || fail 'the split-only cut was refused'; g commit -qm 'the toy, stage 2 fed by a split: line'
sed 's/^\(REQ-003 .*\)| phase: pilot |/\1| phase: later |/' PRD.md > "$T/p" && cp "$T/p" PRD.md; g add PRD.md
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the commit deferring the only requirement of a split-only stage was refused'
g commit -qm 'REQ-003 waits for later, A-010'
printf 'z\n' > x.txt; g add x.txt
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'a commit after deferring the split-only stage passed with its split: line'; fi
grep -q 'split: REQ-003 is phase: later' "$T/out" || fail 'the refusal after deferring the split-only stage does not name the split: line'
g reset -q x.txt
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'row: ROW-006 -> STAGE-2'
g add STAGES.md; sh checks/stages.sh > "$T/out" 2>&1 || fail 'the law commit dropping the split-only stage was refused'
exit 0

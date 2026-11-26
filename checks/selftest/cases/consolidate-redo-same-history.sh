#!/bin/sh
# Purpose: selftest case — redoing PRD consolidation step 7a writes no second history (FIX-BATCH-T1 §6, B-6). On the
# known-good PRD: a first 7a writes PRD-HISTORY-<date>.md; the same input again, the same date, writes no -2 file and names
# the first in its summary; a different input the same date (one append fewer) writes PRD-HISTORY-<date>-2.md, its own
# history, and leaves the first unchanged. Env: CHECKS.
set -eu
fail() { echo "consolidate-redo-same-history: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
D=2026-09-21; mkdir c
cp "$CHECKS/selftest/fixtures/prd-known-good.md" in1.md
awk '/^### 2026-08-29 /{ skip = 1 } !skip' in1.md > in2.md
cmp -s in1.md in2.md && fail 'the second input is the first'
cp in1.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$D" > out 2>&1 || fail 'the first 7a refused'
[ -f "c/PRD-HISTORY-$D.md" ] || fail 'the first 7a wrote no history'
cp "c/PRD-HISTORY-$D.md" h1.md
cp in1.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$D" > out 2>&1 || fail 'the redo refused'
[ ! -e "c/PRD-HISTORY-$D-2.md" ] || fail 'the redo from the same input wrote a second history'
grep -q "history=PRD-HISTORY-$D.md " out || fail 'the redo does not name the first history'
cmp -s h1.md "c/PRD-HISTORY-$D.md" || fail 'the redo changed the first history'
cp in2.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$D" > out 2>&1 || fail 'the different input refused'
[ -f "c/PRD-HISTORY-$D-2.md" ] || fail 'a different history the same day got no -2 file'
grep -q "history=PRD-HISTORY-$D-2.md " out || fail 'the summary does not name the -2 history'
cmp -s h1.md "c/PRD-HISTORY-$D.md" || fail 'a different history overwrote the first'
cmp -s "c/PRD-HISTORY-$D.md" "c/PRD-HISTORY-$D-2.md" && fail 'the -2 history is the first one again'
cp "c/PRD-HISTORY-$D-2.md" h2.md; cp in2.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$D" > out 2>&1 || fail 'the second input again refused'
[ ! -e "c/PRD-HISTORY-$D-3.md" ] || fail 'the second input again wrote a -3 history'
grep -q "history=PRD-HISTORY-$D-2.md " out || fail 'the second input again does not name the -2 history'
cmp -s h2.md "c/PRD-HISTORY-$D-2.md" || fail 'the -2 history changed'
# the unsuffixed history removed: a redo of the second input still finds its -2
rm "c/PRD-HISTORY-$D.md"; cp in2.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$D" > out 2>&1 || fail 'the redo with the first history gone refused'
[ ! -e "c/PRD-HISTORY-$D.md" ] && [ ! -e "c/PRD-HISTORY-$D-3.md" ] || fail 'with the first history gone, the redo wrote a new history'
grep -q "history=PRD-HISTORY-$D-2.md " out || fail 'with the first history gone, the redo does not name its -2'
echo 'consolidate-redo-same-history: ok'

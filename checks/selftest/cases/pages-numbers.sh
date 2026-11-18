#!/bin/sh
# Purpose: selftest case — every number is a script's number, a count of what is listed, or a sum of what is listed
# (usability, B14). On the full pages' toy (fixtures/pages-toy.sh pg_full, the three rungs of pg_rungs), every page
# made so far (the product, the foundation, the findings, the tests, the cuts, the stages, the book): each line the script
# writes with a number is traced — the PRD's head to `prd.sh --report`'s figures, each feature's counts to `--pause`;
# the findings' head and the tests' head, their counts by kind and each fold's "— k tests" to the entries listed;
# each stage table's rows to `stages.sh counts` in its folder, its "All stages" to the sum of the rows above, the
# largest stage's X and Y to the table, the ladder to the rungs' tables; "As of" is the time, a commit line a commit
# of the file. Then every other piece the script wrote (fixtures/pages-toy.sh pg_rest: what is not copied from a
# document) holds no digit, and no page shows a percentage. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-numbers: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
pg_full "$T/toy"; pg_design; pg_rungs "$T/r"; mv STAGES.md "$T/STAGES.md"   # usability (B12): the design chapter too
sh "$S" cuts "$T/r/three" "$T/r/merged" "$T/r/single" > /dev/null 2>&1 || fail 'cuts failed'
mv "$T/STAGES.md" STAGES.md
sh "$S" all > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'all failed'; }
P=.vid/pages
for n in PRD FOUNDATION FINDINGS TESTS CUTS STAGES BOOK; do [ -f "$P/$n.md" ] || fail "no $n page"; done
# drop <page> <line>: a line traced, taken out of what is left to trace
cp "$P"/*.md "$T/"; : > "$T/dropped"; drop() { printf "%s\n" "$2" >> "$T/dropped"; grep -vxF -- "$2" "$T/$1.md" > "$T/x" || true; mv "$T/x" "$T/$1.md"; }
# as of, and each commit line, on every page
for n in PRD FOUNDATION FINDINGS TESTS CUTS STAGES BOOK; do
  a=$(grep '^As of ' "$T/$n.md"); printf '%s\n' "$a" | grep -qxE 'As of [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} UTC' || fail "$n: the as-of line"; drop $n "$a"
  grep -E '^- `[^`]+`: commit [0-9a-f]+ of [0-9-]+$' "$T/$n.md" | while IFS= read -r l; do f=$(printf '%s' "$l" | sed 's/^- `\([^`]*\)`.*/\1/'); h=$(printf '%s' "$l" | sed 's/.*commit \([0-9a-f]*\) of \(.*\)$/\1 \2/')
    [ "$(git log -1 --format='%h %cd' --date=short -- "$f")" = "$h" ] || fail "$n: $f is not at commit $h"; done
  grep -vE '^- `[^`]+`: commit [0-9a-f]+ of [0-9-]+$' "$T/$n.md" > "$T/x" || true; mv "$T/x" "$T/$n.md"; done
# the PRD's head and its features
R=$(sh "$CHECKS/prd.sh" PRD.md --report 2>/dev/null | grep '^prd:' || true); rf() { printf '%s\n' "$R" | sed -n "s/.*[ (]$1=\([0-9][0-9]*\).*/\1/p"; }
h="Requirements: $(rf demand) · Features: $(rf features) · Open questions: $(rf open-OQs) · Answers of yours: $(rf human) · Answers of ViD's: $(rf model) · Findings: $(rf findings)"
grep -qxF "$h" "$T/PRD.md" || fail "the PRD's head is not the report's"; drop PRD "$h"
# the history's warning is the spec's own sentence, its numbers the page's parts, not a count
drop PRD 'Wording here may have been replaced since. Parts 2 to 6 show what holds now.'
sh "$CHECKS/prd.sh" PRD.md --pause 2>/dev/null | grep -E '^  FEAT-[0-9]+ \|' | while IFS='|' read -r id g nm pd t0; do nm=$(echo $nm); pd=$(echo $pd | sed 's/pilot demand //'); t0=$(echo $t0 | sed 's/T0 //')
  w=requirements; [ "$pd" = 1 ] && w=requirement; echo "::: fold $nm — $pd $w in the first version, $t0 must never break {id: $(echo $id)}"; done > "$T/fl"
while IFS= read -r l; do grep -qxF -- "$l" "$T/PRD.md" || fail "a feature's counts are not --pause's: $l"; drop PRD "$l"; done < "$T/fl"
# counts of what is listed: the findings' head, the tests' head, kinds and folds
c() { awk -v h="## $2" '$0 == h { on = 1; next } on && /^## / { exit } on' "$P/$1.md" | grep -c "$3" || true; }
h="Still open: $(c FINDINGS 'Still open' '{id: F-') · Fixed: $(c FINDINGS Fixed '{id: F-') · Your rulings: $(c FINDINGS 'Your rulings' '{id: F-') · Noted: $(c FINDINGS Noted '{id: F-')"
grep -qxF "$h" "$T/FINDINGS.md" || fail "the findings' head is not its groups' counts"; drop FINDINGS "$h"
N=$(awk '/^## By feature$/ { on = 1 } /^## What is deliberately not tested$/ { on = 0 } on && /^\{at: /' "$P/TESTS.md" | grep -c .)
h="This list has $N tests. You are asked to approve it, not to read every line."; grep -qxF "$h" "$T/TESTS.md" || fail 'N is not the entries of parts 4 and 5'; drop TESTS "$h"
k=$(grep '^Behaviours: ' "$T/TESTS.md"); s=0; for x in $(printf '%s\n' "$k" | grep -oE '[0-9]+'); do s=$((s + x)); done; [ "$s" = "$N" ] || fail 'the counts by kind are not the entries'; drop TESTS "$k"
awk '/^::: fold .* — [0-9]+ tests?$/ { h = $0; d = 1; n = 0; next } h != "" && /^::: fold / { d++ } h != "" && /^:::$/ { d--; if (!d) { x = h; sub(/.* — /, "", x); sub(/ tests?$/, "", x); if (x + 0 != n) print "bad " h; else print h; h = "" } next } h != "" && /^\{at: / { n++ }' "$P/TESTS.md" > "$T/folds"
grep -q '^bad ' "$T/folds" && fail "a fold's count is not its entries: $(grep '^bad ' "$T/folds" | head -n 1)"
while IFS= read -r l; do drop TESTS "$l"; done < "$T/folds"
# the stage tables: stages.sh counts in the folder, the sums, the largest stage, the ladder
tab() { # tab <page> <section> <folder>
  ( cd "$3" && sh "${4:-checks/stages.sh}" counts ) | grep '^stage ' > "$T/cn"
  awk -v h="## $2" '$0 == h { on = 1; next } on && /^## / { exit } on' "$P/$1.md" > "$T/sec"
  q=0; w=0; bx=-1; bn=''
  while IFS= read -r l; do st=$(printf '%s' "$l" | sed 's/^stage \([0-9]*\) requirements=\([0-9]*\) rows=\([0-9]*\)\( journeys=[0-9]*\)\{0,1\} | \(.*\)$/\1|\2|\3|\5/'); IFS='|' read -r a b cc d <<EOF
$st
EOF
    [ "$d" = - ] && d='One stage'; r="| $a | $d | $b | $cc |"; grep -qxF -- "$r" "$T/sec" || fail "$1 $2: no row $r"; drop "$1" "$r"
    q=$((q + b)); w=$((w + cc)); [ "$cc" -gt "$bx" ] && { bx=$cc; bn=$d; }; done < "$T/cn"
  r="| | All stages | $q | $w |"; grep -qxF -- "$r" "$T/sec" || fail "$1 $2: All stages is not the sum"; drop "$1" "$r"
  r="The largest stage is $bn: $bx of $w tests."; grep -qxF -- "$r" "$T/sec" || fail "$1 $2: the largest stage"; drop "$1" "$r"
  printf '| %s | %s | %s | %s of %s |\n' "$2" "$(grep -c . "$T/cn")" "$bn" "$bx" "$w" >> "$T/ladder"; }
: > "$T/ladder"; tab CUTS three "$T/r/three"; tab CUTS merged "$T/r/merged"; tab CUTS single "$T/r/single"
while IFS= read -r l; do grep -qxF -- "$l" "$T/CUTS.md" || fail "the ladder lacks $l"; drop CUTS "$l"; done < "$T/ladder"
tab STAGES 'The stages' . "$CHECKS/stages.sh"
# usability (B12): the book's chapters are its pages, so the lines traced on the pages are traced in the book
grep -vxFf "$T/dropped" "$T/BOOK.md" > "$T/x" || true; mv "$T/x" "$T/BOOK.md"
# what is left is the script's own words and what it copied: no digit in the script's words, no percentage
for n in PRD FOUNDATION FINDINGS TESTS CUTS STAGES BOOK; do
  case $n in CUTS) src="$T/r/three/STAGES.md $T/r/merged/STAGES.md PRD.md INVENTORY.md" ;; *) src='PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md DESIGN-BRIEF.md DESIGN-AMENDMENT-BRIEF.md' ;; esac
  pg_rest "$T/$n.md" $src > "$T/rest"
  grep '[0-9]' "$T/rest" > "$T/bad" || true; [ ! -s "$T/bad" ] || fail "$n: a number traced to nothing: $(head -n 3 "$T/bad" | tr '\n' '/')"
  grep -q '%\|percent' "$T/rest" && fail "$n: a percentage"; done
# a planted line of numbers and ids standing alone between the script's words is caught, though each is found in a
# document somewhere
{ cat "$P/PRD.md"; echo 'Tests passing: 3 · Stages done: 2 · See also: ROW-007 (FEAT-01)'; } > "$T/plant.md"
pg_rest "$T/plant.md" PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md > "$T/rest"
for x in 3 2 ROW-007 FEAT-01; do grep -qxF "$x" "$T/rest" || fail "the planted $x is not caught"; done
exit 0

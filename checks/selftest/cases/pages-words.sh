#!/bin/sh
# Purpose: selftest case — plain words in everything the script adds (usability, B15). On the full pages' toy, every
# page made so far (the product, the foundation, the findings, the tests, the cuts, the stages, the book) and every line the
# script prints: what the script itself wrote (fixtures/pages-toy.sh pg_rest, the pieces copied from no document)
# holds none of ViD's internal words in the list below, whole words, any case (`ratif` as the start of a word), and no
# id; an id is drawn only on request ({id: …}). A planted label with a word of the list, and one with an id, are
# convicted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-words: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
WORDS='court|frame|genus|recognition|compaction|arm|tier|T0|lens|ledger|ratif[a-z]*'
bad() { grep -inwE "$WORDS" "$1" || true; grep -nE '(^|[^A-Za-z])[A-Z]{1,6}-[0-9]+' "$1" || true; }
pg_full "$T/toy"; pg_design; pg_rungs "$T/r"; mv STAGES.md "$T/STAGES.md"   # usability (B12): the design chapter too
sh "$S" cuts "$T/r/three" "$T/r/merged" "$T/r/single" > "$T/said" 2>&1 || fail 'cuts failed'
mv "$T/STAGES.md" STAGES.md
sh "$S" all >> "$T/said" 2>&1 || fail 'all failed'
sh "$S" link prd https://claude.ai/artifact/x >> "$T/said" 2>&1; sh "$S" publish yes --words 'fine' >> "$T/said" 2>&1; sh "$S" prd >> "$T/said" 2>&1
sh "$S" for 2 >> "$T/said" 2>&1
P=.vid/pages
for n in PRD FOUNDATION FINDINGS TESTS CUTS STAGES BOOK; do
  case $n in CUTS) src="$T/r/three/STAGES.md $T/r/merged/STAGES.md PRD.md INVENTORY.md" ;; *) src='PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md DESIGN-BRIEF.md DESIGN-AMENDMENT-BRIEF.md' ;; esac
  pg_rest "$P/$n.md" $src > "$T/rest"; [ -s "$T/rest" ] || fail "$n: nothing left to read, so the reading is broken"
  bad "$T/rest" > "$T/b"; [ ! -s "$T/b" ] || fail "$n: the script's words hold an internal word or an id: $(head -n 3 "$T/b" | tr '\n' '/')"; done
# the printed lines, the paths and the link taken out
sed -e "s|$(pwd -P)[^ ]*||g" -e "s|$(cd "$CHECKS" && pwd -P)[^ \`]*||g" -e 's|https://claude.ai/[^ ]*||g' -e "s|$T[^ ]*||g" "$T/said" > "$T/s2"
bad "$T/s2" > "$T/b"; [ ! -s "$T/b" ] || fail "the printed lines hold an internal word or an id: $(head -n 3 "$T/b" | tr '\n' '/')"
# the plants are convicted
printf 'the court of the page\n' > "$T/p1"; printf 'about REQ-012 here\n' > "$T/p2"; printf 'Ratified at the sitting\n' > "$T/p3"
for p in p1 p2 p3; do [ -n "$(bad "$T/$p")" ] || fail "a planted $p is not convicted"; done
# a planted line of ids standing alone between the script's words is caught, though each is found in a document
{ cat "$P/PRD.md"; echo 'Tests passing: 3 · Stages done: 2 · See also: ROW-007 (FEAT-01)'; } > "$T/plant.md"
pg_rest "$T/plant.md" PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md > "$T/rest"
bad "$T/rest" > "$T/b"; grep -q 'ROW-007' "$T/b" && grep -q 'FEAT-01' "$T/b" || fail 'the planted ids are not convicted'
exit 0

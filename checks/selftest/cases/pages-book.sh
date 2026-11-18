#!/bin/sh
# Purpose: selftest case — one book a project (usability, B12). On the full pages' toy at three moments — after the
# first pause (the PRD alone), after the test list (the foundation, a design brief and its amendment record, the
# list), after the plan (the committed cut and the plan's page) — `pages.sh all` writes .vid/pages/BOOK.md and .html:
# the spine lists the eight chapters in order, each "Written" or "Not written yet" as its document exists; a chapter
# not written is one line saying at which stop it comes; each written chapter is its page's markdown made at that
# moment (B13's note and marks aside, none here), the idea the seed as written, the design its screens with their
# states and the rulings as written; in the html every chapter's sections are folded, no two places share an address,
# every link names one. `pages.sh book` alone makes the same chapters. A book of a 2,000-test list stays under 15 MB.
# The book's index line has no stops. A chapter's html is its page's but for the book's own differences; a source with
# no final line break does not run into the next chapter; the design's fences are read past their words and comment
# lines; a consolidated PRD's idea is SEED.md. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-book: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh; P=.vid/pages
pg_full "$T/toy"; H=$(pwd -P)
mkdir "$T/k"; mv BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md "$T/k/"
NAMES='The idea|The product|The technical foundation|The design|The tests|The stages|The plan|The findings'
# chap <n>: chapter n of the book's markdown, from its {chapter:} line to the next
chap() { awk -v n="{chapter: $1}" '$0 == n { on = 1; next } on && /^\{chapter: [0-9]+\}$/ { exit } on' "$P/BOOK.md"; }
noasof() { grep -v '^As of [0-9-]* [0-9:]* UTC$' "$1" || true; }
# same <n> <page.md>: the chapter is its page, made at the same moment
same() { chap "$1" > "$T/c"; noasof "$T/c" | awk 1 > "$T/c1"; noasof "$2" | awk 1 > "$T/p1"; cmp -s "$T/c1" "$T/p1" || { diff "$T/p1" "$T/c1" | head -n 5 >&2; fail "chapter $1 is not its page $2"; }; }
# hsame <n> <page.html>: the chapter's html is its page's, the book's own differences taken out (the chapter's number
# in its addresses, the folds of its sections, the toolbar, the as-of line)
hnorm() { sed -e 's/<\/\{0,1\}details[^>]*>//g' -e 's/<\/\{0,1\}summary>//g' -e "s/\"#c$1-/\"#/g; s/ id=\"c$1-/ id=\"/g" -e '/^<div class="tools">/d' -e '/^<p>As of /d' -e '/^[[:space:]]*$/d'; }
hsame() { awk -v a="<span id=\"chapter-$1\" class=\"at\"></span>" 'index($0, a) == 1 { on = 1; next } on && /^<span id="chapter-[0-9]+" class="at"><\/span>$/ { exit } on && /^<\/main>$/ { exit } on' "$P/BOOK.html" | hnorm "$1" > "$T/hc"
  awk '/<body><main>$/ { on = 1; next } /^<\/main>$/ { on = 0 } on' "$2" | hnorm "$1" > "$T/hp"
  [ -s "$T/hp" ] && cmp -s "$T/hc" "$T/hp" || { diff "$T/hp" "$T/hc" | head -n 6 >&2; fail "chapter $1 renders other than its page $2"; }; }
# spine <states…>: the spine's eight lines
spine() { i=0; for st; do i=$((i + 1)); nm=$(printf '%s' "$NAMES" | cut -d'|' -f$i)
  grep -qxF -- "- [$nm](#chapter-$i) — $st" "$P/BOOK.md" || fail "the spine does not say $nm is $st"; done; }
html() { B=$P/BOOK.html; [ -f "$B" ] || fail 'no book'
  [ -z "$(grep -o ' id="[^"]*"' "$B" | sort | uniq -d)" ] || fail "two places in the book share an address: $(grep -o ' id="[^"]*"' "$B" | sort | uniq -d | head -n 2)"
  grep -o 'href="[^"]*"' "$B" | sed 's/^href="#//; s/"$//' | while IFS= read -r a; do grep -qF "id=\"$a\"" "$B" || fail "a link names no place: $a"; done
  grep -qiE 'https?://|src=' "$B" && fail 'the book names an outside address'
  grep -q '<details class="fold chap">' "$B" || fail "a chapter's sections are not folded"
  grep -q '<details[^>]* open' "$B" && fail 'something is open when the book opens'; return 0; }
# moment 1: the PRD alone
sh "$S" all > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'all at moment 1 failed'; }
grep -qF "page: JobDigest: the product book | $H/$P/BOOK.html | -" "$T/out" || fail 'no page line for the book'
grep -qF "$(printf 'book\tJobDigest: the product book\t%s/%s/BOOK.html\t-\t-' "$H" "$P")" "$P/index" || fail "the book's index line"
spine Written Written 'Not written yet' 'Not written yet' 'Not written yet' 'Not written yet' 'Not written yet' Written
same 2 "$P/PRD.md"; same 8 "$P/FINDINGS.md"
chap 1 | grep -qF 'I want a small job-alert product: two source feeds, merged into one' || fail 'the idea is not the seed as written'
chap 3 | grep -qxF 'Not written yet: it comes at the technical hints.' || fail 'a chapter not written does not say at which stop it comes'
chap 6 | grep -qxF 'Not written yet: it comes at the releases.' && chap 7 | grep -qxF 'Not written yet: it comes when the plan is made, after the releases.' || fail 'the stages or the plan do not say when they come'
html
# moment 2: the foundation, the design, the test list
cp "$T/k/BASELINE.md" "$T/k/ARCHITECTURE.md" "$T/k/DECISIONS.md" "$T/k/INVENTORY.md" "$T/k/GRADING-CHECKLIST.md" .; pg_design
sh "$S" all > "$T/out" 2>&1 || fail 'all at moment 2 failed'
spine Written Written Written Written Written 'Not written yet' 'Not written yet' Written
same 2 "$P/PRD.md"; same 3 "$P/FOUNDATION.md"; same 5 "$P/TESTS.md"; same 8 "$P/FINDINGS.md"
D=$(chap 4); for r in '| S01 | default |' '| S01 | saved |' '| S02 | active |'; do printf '%s\n' "$D" | grep -qxF -- "$r" || fail "the design does not list its screens and their states: $r"; done
printf '%s\n' "$D" | grep -qF 'S01/saved' && printf '%s\n' "$D" | grep -qF 'ruling: design wins' && printf '%s\n' "$D" | grep -qF 'ruling: not a disagreement' || fail "the design's rulings are not as written"
html
# moment 3: the committed cut and the plan's page; the book alone makes the same chapters
cp "$T/k/STAGES.md" .; printf '# The plan: JobDigest\n\n## The plan\n\n- S01 the skeleton\n\n## The plan\n\n- the same heading twice\n\n```\nS01 | a block that ends the file\n```' > .vid/plan/PLAN-PAGE.md   # no final line break
sh "$S" all > "$T/out" 2>&1 || fail 'all at moment 3 failed'
spine Written Written Written Written Written Written Written Written
same 6 "$P/STAGES.md"; same 7 .vid/plan/PLAN-PAGE.md
for n in PRD FOUNDATION TESTS STAGES FINDINGS; do cp "$P/$n.md" "$T/$n.md"; done
sh "$S" book > "$T/out" 2>&1 || fail 'book alone failed'
[ "$(grep -c '^page: ' "$T/out")" = 1 ] || fail 'book alone printed other than its own line'
same 2 "$T/PRD.md"; same 3 "$T/FOUNDATION.md"; same 5 "$T/TESTS.md"; same 6 "$T/STAGES.md"; same 7 .vid/plan/PLAN-PAGE.md; same 8 "$T/FINDINGS.md"
html
grep -qF '<h1>JobDigest: the findings</h1>' "$P/BOOK.html" || fail 'a chapter after one with no final line break is not drawn as a chapter'
hsame 2 "$P/PRD.html"; hsame 5 "$P/TESTS.html"
printf '%s\n' "$(chap 4)" | grep -qE 'a note for the designer|screen . state . requirements' && fail 'a comment line of the design is shown'
# a consolidated PRD: the seed in SEED.md, a Seed: line in the header, read as prd.sh reads it
awk '/^## Seed$/ { on = 1; next } on && /^## / { on = 0 } on' PRD.md > SEED.md
awk 'NR == 1 { print; print "Seed: SEED.md (sha256 0123abcd)"; next } /^## Seed$/ { skip = 1; next } skip && /^## / { skip = 0 } !skip' PRD.md > P.x && mv P.x PRD.md
grep -q '^## Seed$' PRD.md && fail 'the PRD was not consolidated'
sh "$S" book > "$T/out" 2>&1 || fail 'the book of a consolidated PRD failed'
grep -qxF -- '- [The idea](#chapter-1) — Written' "$P/BOOK.md" || fail 'the idea of a consolidated PRD is said not written'
chap 1 | grep -qF 'I want a small job-alert product: two source feeds, merged into one' || fail 'the idea is not SEED.md as written'
# a 2,000-test list: under 15 MB
awk '/^ROW-001 \|/ { for (i = 1; i <= 2000; i++) { l = $0; sub(/^ROW-001/, sprintf("ROW-%04d", i + 1000), l); print l } next } { print }' INVENTORY.md > I.x && mv I.x INVENTORY.md
[ "$(grep -cE '^ROW-[123][0-9]{3} ' INVENTORY.md)" = 2000 ] || fail 'the large list was not made'
sh "$S" book > "$T/out" 2>&1 || fail 'the large book failed'
[ "$(wc -c < "$P/BOOK.html")" -lt 15728640 ] || fail "the book of 2,000 tests is $(wc -c < "$P/BOOK.html") bytes"
[ "$(grep -cE '^\{at: row-[123][0-9]{3}\}$' "$P/BOOK.md")" = 2000 ] || fail 'the large book does not hold every test'
exit 0

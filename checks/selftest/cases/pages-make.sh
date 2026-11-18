#!/bin/sh
# Purpose: selftest case — one script makes every page (usability, B1). On the pages' toy (fixtures/pages-toy.sh),
# `pages.sh prd`, `foundation` and `findings` each write .vid/pages/<NAME>.md and .html and print one line,
# `page: <title> | <the html file's full path> | -`; the index holds one line a page made, five tab-separated fields
# (id, title, the html's full path, the link or -, the stops), each naming a file that exists; each page's first line
# under its title says how fresh it is (a committed document by its short hash, an uncommitted one as "not committed
# yet"); every file of the project but .vid/pages/ is the same before and after, the events and the plan folder among
# them. A page whose document is missing is not made, said in one line, exit 0; an unknown page is refused; with no
# .vid/ nothing is written; a page whose file is gone leaves the index at the next call. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-make: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
pg_toy "$T/toy"; H=$(pwd -P)
pg_snap > "$T/before"
for p in prd foundation findings; do
  sh "$S" $p > "$T/out" 2>&1 || fail "$p failed"
  case $p in prd) N=PRD ;; foundation) N=FOUNDATION ;; findings) N=FINDINGS ;; esac
  [ -f ".vid/pages/$N.md" ] && [ -f ".vid/pages/$N.html" ] || fail "$p: no .vid/pages/$N.md and .html"
  grep -qxE "page: [^|]+ \| $H/\.vid/pages/$N\.html \| -" "$T/out" || fail "$p: no page line naming the full path"
  sed -n '2,4p' ".vid/pages/$N.md" | grep -q '^As of [0-9-]* [0-9:]* UTC' || fail "$p: the page does not say how fresh it is"
done
pg_snap > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2; fail 'a file outside .vid/pages/ changed'; }
[ "$(ls -A .vid | tr '\n' ' ')" = 'metrics-events pages plan ' ] || fail "a call wrote beside .vid/pages/: $(ls -A .vid)"
# the index: one line a page made, five fields, each file there
I=.vid/pages/index; [ -f "$I" ] || fail 'no index'
[ "$(cut -f1 "$I" | tr '\n' ' ')" = 'prd foundation findings ' ] || fail "the index does not name the three pages: $(cut -f1 "$I" | tr '\n' ' ')"
awk -F'\t' 'NF != 5 { exit 1 }' "$I" || fail 'an index line has other than five fields'
cut -f3 "$I" | while IFS= read -r f; do [ -f "$f" ] || fail "the index names $f, which is missing"; done
grep -qF "$(printf 'prd\tJobDigest: the product\t%s/.vid/pages/PRD.html\t-\t3,4,5,6,7,8' "$H")" "$I" || fail "the PRD's index line: $(grep '^prd' "$I")"
# freshness: a committed document by its hash, a changed one not committed yet
h=$(git log -1 --format=%h -- PRD.md); grep -qF "\`PRD.md\`: commit $h of " .vid/pages/PRD.md || fail "the PRD page does not name commit $h"
printf '\n- **D-004** a later decision | why: x | enforced: convention | scope: project\n' >> DECISIONS.md
sh "$S" foundation > "$T/out" 2>&1 || fail 'foundation again failed'
grep -qF '`DECISIONS.md`: not committed yet' .vid/pages/FOUNDATION.md || fail 'a changed document is not said to be not committed yet'
grep -qF "\`BASELINE.md\`: commit $h of " .vid/pages/FOUNDATION.md || fail 'a committed document beside it is not named by its commit'
git checkout -q DECISIONS.md
# a missing document: one line, exit 0, no page; an unknown page refused
mv BASELINE.md "$T/b"; mv ARCHITECTURE.md "$T/a"; mv DECISIONS.md "$T/d"; rm .vid/pages/FOUNDATION.*
sh "$S" foundation > "$T/out" 2>&1 || fail 'a missing document fails the call'
[ "$(grep -c . "$T/out")" = 1 ] && [ ! -f .vid/pages/FOUNDATION.html ] || fail 'a missing document is not one line and no page'
# a page whose file is gone leaves the index at the next call
grep -q '^foundation' "$I" && fail 'the index still names the removed page'
mv "$T/b" BASELINE.md; mv "$T/a" ARCHITECTURE.md; mv "$T/d" DECISIONS.md
if sh "$S" nonsense > "$T/out" 2>&1; then fail 'an unknown page is not refused'; fi
grep -q '|book|' "$T/out" || fail 'the usage does not name the book'   # usability (B12)
# no .vid/: nothing written
mkdir "$T/bare"; cd "$T/bare"; git init -q; cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
sh "$S" prd > "$T/out" 2>&1 || fail 'no .vid/ fails the call'
[ ! -e .vid ] && [ "$(grep -c . "$T/out")" = 1 ] || fail 'with no .vid/ something was written, or more than one line said'
exit 0

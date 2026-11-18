#!/bin/sh
# Purpose: selftest case — which pages are due at which stop (usability, B10). On the pages' toy (a PRD and the three
# foundation documents; no test list, no stages, no cuts), from an empty pages folder each time, `pages.sh for <stop>`
# makes exactly the pages of the table whose documents exist and prints one page line each: 2 none; 3 and 4 the PRD;
# 5 the PRD and the findings; 6 and 7 the PRD and the foundation; 8 the PRD; 9 none here. Each index line's fifth field
# is the table's (prd 3,4,5,6,7,8; findings 5; foundation 6,7). With the foundation's documents gone, stop 6 still makes
# the PRD and exits 0. A stop outside 2 to 9 is refused. usability (B12): every stop then makes the book too, its index
# line with no stops. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-for: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
pg_toy "$T/toy"
due() { rm -rf .vid/pages; sh "$S" for "$1" > "$T/out" 2>&1 || fail "for $1 failed"
  m=$(ls .vid/pages 2>/dev/null | sed -n 's/\.html$//p' | LC_ALL=C sort | tr '\n' ' ')
  [ "$m" = "$2" ] || fail "stop $1 made '$m', not '$2'"
  [ "$(grep -c '^page: ' "$T/out")" = "$3" ] || fail "stop $1 printed other than $3 page lines"; }
due 2 'BOOK ' 1; due 3 'BOOK PRD ' 2; due 4 'BOOK PRD ' 2; due 5 'BOOK FINDINGS PRD ' 3; due 6 'BOOK FOUNDATION PRD ' 3; due 7 'BOOK FOUNDATION PRD ' 3; due 8 'BOOK PRD ' 2; due 9 'BOOK ' 1
# the fifth field, as the table has it
sh "$S" for 5 > /dev/null 2>&1; sh "$S" for 6 > /dev/null 2>&1
[ "$(cut -f1,5 .vid/pages/index | tr '\t\n' ': ')" = 'prd:3,4,5,6,7,8 foundation:6,7 findings:5 book:- ' ] || fail "the stops in the index: $(cut -f1,5 .vid/pages/index | tr '\t\n' ': ')"
# one page's document missing does not fail the call
mkdir "$T/gone"; mv BASELINE.md ARCHITECTURE.md DECISIONS.md "$T/gone/"
due 6 'BOOK PRD ' 2
for s in 1 10 x ''; do if sh "$S" for $s > "$T/out" 2>&1; then fail "the stop '$s' is not refused"; fi; done
# usability (B5, B6): with a test list and a committed cut (the full toy), stop 8 makes the tests and the PRD, stop 9
# the stages and the tests; with no cut committed, stop 9 prints the cuts' page from the index and makes the tests
pg_full "$T/full"
due 8 'BOOK PRD TESTS ' 3; due 9 'BOOK STAGES TESTS ' 3
[ "$(cut -f1,5 .vid/pages/index | tr '\t\n' ': ')" = 'tests:8,9 stages:9 book:- ' ] || fail "the stops in the index: $(cut -f1,5 .vid/pages/index | tr '\t\n' ': ')"
pg_rungs "$T/rungs"; mv STAGES.md "$T/STAGES.md"; sh "$S" cuts "$T/rungs/three" > /dev/null 2>&1 || fail 'cuts failed'
sh "$S" for 9 > "$T/out" 2>&1 || fail 'for 9 with no cut committed failed'
grep -q '^page: JobDigest: the cuts to choose from |' "$T/out" && grep -q '^page: JobDigest: the tests |' "$T/out" || fail 'stop 9 with no cut committed: not the cuts and the tests'
[ "$(grep -c '^page: ' "$T/out")" = 3 ] || fail 'stop 9 with no cut committed printed other than the two pages and the book'
exit 0

#!/bin/sh
# Purpose: selftest case — the stage cut as a page, before and after the pick (usability, B6). On the full pages' toy
# with its STAGES.md moved away (no cut committed) and three rungs' scratch copies (fixtures/pages-toy.sh pg_rungs:
# `three`, `merged`, and `single` with no STAGES.md): `pages.sh cuts` writes .vid/pages/CUTS.md with one table a rung,
# a row a stage holding what `sh checks/stages.sh counts` prints in that folder and a last row "All stages", the sum
# of the rows above; "The largest stage is <name>: X of Y tests." above each table; the ladder, a row a rung, every
# folder in it; the cards of the rung that has them, folded; no percentage; nothing in a folder changed. `pages.sh for
# 9` prints the cuts' page from the index and leaves it there; with STAGES.md back, `for 9` shows the cuts and the
# stages, and neither it nor `all` takes the cuts out. The pick, by name: `pages.sh stages` writes .vid/pages/STAGES.md
# from the project's STAGES.md, every count equal to stages.sh's in the project, and takes the cuts' line out of the
# index; STAGES.md unchanged. A re-cut: the new cuts stay through `for 9`. Back to one stage by name (no STAGES.md):
# `pages.sh stages` says so and takes the cuts out; then `for 9`, with neither, shows no page of the cut and does not
# fail. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-stages: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
pg_full "$T/toy"; H=$(pwd -P)
pg_rungs "$T/r"; mv STAGES.md "$T/STAGES.md"
fsum() { find "$T/r" -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(cksum < "$f")" "$f"; done; }
fsum > "$T/f0"
sh "$S" cuts "$T/r/three" "$T/r/merged" "$T/r/single" > "$T/out" 2>&1 || fail 'cuts failed'
fsum > "$T/f1"; cmp -s "$T/f0" "$T/f1" || fail "a rung's folder changed"
M=.vid/pages/CUTS.md; [ -f "$M" ] && [ -f .vid/pages/CUTS.html ] || fail 'no cuts page'
grep -qF "page: JobDigest: the cuts to choose from | $H/.vid/pages/CUTS.html | -" "$T/out" || fail 'no page line for the cuts'
grep -q '%\|percent' "$M" && fail 'a percentage is shown'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$M"; }
# check <section> <folder>: the section's table is what stages.sh counts prints there, then All stages, the sum
check() { (cd "$2" && sh checks/stages.sh counts) | grep '^stage ' > "$T/c"
  sec "$1" | grep '^| ' | grep -v '^| Stage |' > "$T/t"
  [ "$(grep -c . "$T/t")" = "$(( $(grep -c . "$T/c") + 1 ))" ] || fail "$1: the table does not hold every stage and the sum"
  rq=0; rw=0; big=''; bx=-1; i=0
  while IFS= read -r l; do i=$((i + 1)); k=$(printf '%s' "$l" | sed 's/^stage \([0-9]*\) .*/\1/'); q=$(printf '%s' "$l" | sed 's/.* requirements=\([0-9]*\) .*/\1/'); w=$(printf '%s' "$l" | sed 's/.* rows=\([0-9]*\) .*/\1/'); nm=${l#*| }
    [ "$nm" = - ] && nm='One stage'
    [ "$(sed -n "${i}p" "$T/t")" = "| $k | $nm | $q | $w |" ] || fail "$1: stage $k's row is not '| $k | $nm | $q | $w |': $(sed -n "${i}p" "$T/t")"
    rq=$((rq + q)); rw=$((rw + w)); [ "$w" -gt "$bx" ] && { bx=$w; big=$nm; }; done < "$T/c"
  [ "$(tail -n 1 "$T/t")" = "| | All stages | $rq | $rw |" ] || fail "$1: All stages is not the sum: $(tail -n 1 "$T/t")"
  sec "$1" | grep -qxF "The largest stage is $big: $bx of $rw tests." || fail "$1: the largest stage is not named in words"
  printf '%s|%s|%s|%s\n' "$(grep -c . "$T/c")" "$big" "$bx" "$rw"; }
a=$(check three "$T/r/three"); b=$(check merged "$T/r/merged"); c=$(check single "$T/r/single")
# the ladder: every folder, its stages, its largest stage, X and Y
lad=$(sec 'The ladder' | grep '^| ' | grep -v '^| Rung |')
for x in "three|$a" "merged|$b" "single|$c"; do IFS='|' read -r r k nm xx yy <<EOF
$x
EOF
  printf '%s\n' "$lad" | grep -qxF "| $r | $k | $nm | $xx of $yy |" || fail "the ladder lacks $r as | $r | $k | $nm | $xx of $yy |"; done
[ "$(printf '%s\n' "$lad" | grep -c .)" = 3 ] || fail 'the ladder is not three rungs'
# the cards: folded, for the rung that has them
sec three | grep -qxF '::: fold Stage 1 — The daily digest' && sec three | grep -qF 'a job seeker saves searches and reads one digest a day' || fail "the cards of the first rung are not folded in"
sec merged | grep -q '^::: fold' && fail 'a rung with no cards shows a card'
# for 9 with no cut committed: the cuts' page from the index, still there
sh "$S" for 9 > "$T/out" 2>&1 || fail 'for 9 failed'
grep -qF "page: JobDigest: the cuts to choose from | $H/.vid/pages/CUTS.html | -" "$T/out" && [ -f .vid/pages/CUTS.html ] || fail 'for 9 does not print the cuts page'
grep -q '^cuts	' .vid/pages/index || fail 'for 9 took the cuts out of the index'
grep -qF "$(printf 'cuts\tJobDigest: the cuts to choose from\t%s/.vid/pages/CUTS.html\t-\t9' "$H")" .vid/pages/index || fail "the cuts' index line"
# STAGES.md back: stop 9 and all show the cuts while their line stands, the stages page too; neither takes them out
cp "$T/STAGES.md" STAGES.md; s0=$(cksum < STAGES.md)
sh "$S" for 9 > "$T/out" 2>&1 || fail 'for 9 with a STAGES.md and the cuts failed'
grep -q '^page: JobDigest: the cuts to choose from |' "$T/out" && grep -q '^page: JobDigest: the stages |' "$T/out" || fail 'for 9 does not show the cuts and the stages while the cuts stand'
sh "$S" all > "$T/out" 2>&1 || fail 'all failed'
grep -q '^cuts	' .vid/pages/index || fail 'for 9 or all took the cuts out of the index'
# the pick, by name: pages.sh stages takes the cuts out
sh "$S" stages > "$T/out" 2>&1 || fail 'stages failed'
[ "$(cksum < STAGES.md)" = "$s0" ] || fail 'STAGES.md changed'
M=.vid/pages/STAGES.md; [ -f .vid/pages/STAGES.html ] || fail 'no stages page'
cp -R "$CHECKS" "$T/pc"; mkdir -p "$T/p"; cp PRD.md INVENTORY.md STAGES.md "$T/p/"; mv "$T/pc" "$T/p/checks"
check 'The stages' "$T/p" > /dev/null
grep -q '^cuts	' .vid/pages/index && fail "the cuts' line is still in the index once the pick is made"
grep -q '^stages	.*	9$' .vid/pages/index || fail "the stages' index line"
sec 'The stages' | grep -qxF '::: fold Stage 2 — Synonym-aware search' || fail "the cut's cards are not folded in"
# a re-cut: new cuts with a cut already there: they stay through for 9, shown with the stages, until the pick
sh "$S" cuts "$T/r/three" "$T/r/merged" "$T/r/single" > "$T/out" 2>&1 || fail 'the re-cut failed'
sh "$S" for 9 > "$T/out" 2>&1 || fail 'for 9 at a re-cut failed'
grep -q '^page: JobDigest: the cuts to choose from |' "$T/out" || fail 'for 9 at a re-cut does not print the new cuts'
grep -q '^cuts	' .vid/pages/index || fail 'the re-cut left the index at for 9'
# back to one stage, by name: STAGES.md gone, pages.sh stages says so, takes the cuts out, and nothing breaks
rm STAGES.md
sh "$S" stages > "$T/out" 2>&1 || fail 'stages with no STAGES.md failed'
grep -q 'one stage' "$T/out" || fail 'stages with no STAGES.md does not say the project keeps one stage'
grep -q '^cuts	' .vid/pages/index && fail 'going back to one stage leaves the cuts in the index'
# for 9 with neither: no page of the stage cut, and the call does not fail
sh "$S" for 9 > "$T/out" 2>&1 || fail 'for 9 with neither cuts nor stages failed'
grep -qE '^page: JobDigest: the (cuts to choose from|stages) \|' "$T/out" && fail 'for 9 with neither prints a page of the stage cut'
exit 0

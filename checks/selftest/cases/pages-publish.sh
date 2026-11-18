#!/bin/sh
# Purpose: selftest case — a link when the session can, a local file always (usability, B9). On the pages' toy: with no
# answer recorded, `pages.sh prd` prints the page line (the html's full path) and the question to ask before anything
# is published, never the words to publish; `publish yes --words …` records the answer in .vid/pagelinks, after which
# the call prints the words to publish with the script's own full path for `link`; `link` refuses an address that does
# not start https://claude.ai/ and an unknown page, each in one line, and records a good one in .vid/pagelinks and the
# index; the pages folder emptied and made again keeps the answer and the link; `publish no` prints only "Give the owner
# each file's full path."; an answer with no words is refused; a page over the size limit says it is too large to
# publish (the limit lowered for the case by VID_PAGES_LIMIT, in bytes). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-publish: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh; SF=$(cd "$CHECKS" && pwd -P)/pages.sh
pg_toy "$T/toy"; H=$(pwd -P)
Q="May ViD put this project's pages on private claude.ai pages, so you get a link? Only you can open them. Without it you get a local file."
PUB="Publish each page above as a private page: at its link where it has one, as a new page where it has none. Record a new link with \`sh $SF link <page> <address>\`. Give the owner the link. Where this session cannot publish, give the file's full path."
# no answer: the question, never the words to publish
sh "$S" prd > "$T/out" 2>&1 || fail 'prd failed'
grep -qxF "page: JobDigest: the product | $H/.vid/pages/PRD.html | -" "$T/out" || fail 'no page line with the full path'
grep -qF "$Q" "$T/out" || fail 'with no answer, the question is not printed'
grep -qF 'Publish each page above' "$T/out" && fail 'with no answer, the session is told to publish'
[ ! -e .vid/pagelinks ] || fail 'a page call wrote .vid/pagelinks'
# an answer needs the owner's words
if sh "$S" publish yes > "$T/out" 2>&1; then fail 'an answer with no words is recorded'; fi
if sh "$S" publish maybe --words 'hm' > "$T/out" 2>&1; then fail 'an answer other than yes or no is recorded'; fi
# yes: the words to publish, with the script's full path
sh "$S" publish yes --words 'yes, links are fine' > "$T/out" 2>&1 || fail 'publish yes failed'
grep -q '^publish	yes	yes, links are fine	' .vid/pagelinks || fail 'the yes is not recorded with the words'
sh "$S" prd > "$T/out" 2>&1 || fail 'prd after yes failed'
grep -qxF "$PUB" "$T/out" || fail 'with a yes, the words to publish are not printed'
grep -qF "$Q" "$T/out" && fail 'with a yes, the question is asked again'
# links: refused, then recorded
cp .vid/pagelinks "$T/l0"
for a in http://claude.ai/x https://claude.ai.example.com/x https://example.com/claude.ai/ 'https://claude.ai/a b'; do
  if sh "$S" link prd "$a" > "$T/out" 2>&1; then fail "the link $a is recorded"; fi
  [ "$(grep -c . "$T/out")" = 1 ] || fail "the refusal of $a is not one line"; done
if sh "$S" link nonsense https://claude.ai/artifact/x > "$T/out" 2>&1; then fail 'a link for an unknown page is recorded'; fi
cmp -s "$T/l0" .vid/pagelinks || fail 'a refused link changed .vid/pagelinks'
sh "$S" link prd https://claude.ai/artifact/abc123 > "$T/out" 2>&1 || fail 'a good link is refused'
grep -qxF "$(printf 'link\tprd\thttps://claude.ai/artifact/abc123')" .vid/pagelinks || fail 'the link is not in .vid/pagelinks'
[ "$(grep '^prd	' .vid/pages/index | cut -f4)" = https://claude.ai/artifact/abc123 ] || fail 'the link is not in the index'
# the pages folder emptied and made again: the answer and the link kept
rm -rf .vid/pages
sh "$S" prd > "$T/out" 2>&1 || fail 'prd after the folder was emptied failed'
grep -qxF "page: JobDigest: the product | $H/.vid/pages/PRD.html | https://claude.ai/artifact/abc123" "$T/out" || fail 'the link is lost with the pages folder'
grep -qxF "$PUB" "$T/out" || fail 'the yes is lost with the pages folder'
[ "$(grep '^prd	' .vid/pages/index | cut -f4)" = https://claude.ai/artifact/abc123 ] || fail 'the index made again lacks the link'
# no: only the paths
sh "$S" publish no --words 'no, local files' > "$T/out" 2>&1 || fail 'publish no failed'
[ "$(grep -c '^publish	' .vid/pagelinks)" = 1 ] && grep -q '^publish	no	no, local files	' .vid/pagelinks || fail 'the no does not replace the yes'
sh "$S" prd > "$T/out" 2>&1 || fail 'prd after no failed'
grep -qxF "Give the owner each file's full path." "$T/out" || fail 'with a no, the session is not told to give the paths'
grep -qF 'Publish each page above' "$T/out" && fail 'with a no, the session is told to publish'
grep -qF "$Q" "$T/out" && fail 'with a no, the question is asked again'
# too large to publish: still written, the path given
VID_PAGES_LIMIT=100 sh "$S" prd > "$T/out" 2>&1 || fail 'a large page fails'
grep -qF "page: JobDigest: the product | $H/.vid/pages/PRD.html | https://claude.ai/artifact/abc123 | too large to publish: give the owner the path" "$T/out" && [ -f .vid/pages/PRD.html ] || fail 'a page over the limit does not say it is too large'
# with a yes, a page too large is never told to be published: alone, only the paths; beside a smaller one, the words
# to publish leave it out
sh "$S" publish yes --words 'yes again' > /dev/null 2>&1 || fail 'publish yes again failed'
VID_PAGES_LIMIT=100 sh "$S" prd > "$T/out" 2>&1 || fail 'a large page with a yes fails'
grep -qF 'Publish each page above' "$T/out" && fail 'a page too large to publish is told to be published'
grep -qxF "Give the owner each file's full path." "$T/out" || fail 'a page too large to publish, alone, is not given by its path'
sh "$S" findings > /dev/null 2>&1; a=$(wc -c < .vid/pages/PRD.html); b=$(wc -c < .vid/pages/FINDINGS.html); [ "$a" -gt "$b" ] || fail 'the toy PRD page is not the larger'
VID_PAGES_LIMIT=$(( (a + b) / 2 )) sh "$S" all > "$T/out" 2>&1 || fail 'all with one page too large fails'
grep -qF 'too large to publish' "$T/out" || fail 'the larger page is not too large'
grep -qxF "Publish each page above that is not too large to publish as a private page: at its link where it has one, as a new page where it has none. Record a new link with \`sh $SF link <page> <address>\`. Give the owner the link, and the file's full path of each page too large to publish. Where this session cannot publish, give the file's full path." "$T/out" || fail 'beside a smaller page, the words to publish do not leave the large one out'
exit 0

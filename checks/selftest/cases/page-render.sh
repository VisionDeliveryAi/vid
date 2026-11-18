#!/bin/sh
# Purpose: selftest case — the one page renderer (v0.26.10.9 spec R25; §5 page-render). A replan report's markdown with
# a heading, a list, a table and two question cards addressed to two answerers: `page.sh` writes one HTML file,
# .vid/pages/<name>.html, with its style inline and no address outside the page in a link, a script or a style (every
# href= a `#` address the page itself holds, no src=, no style that loads from elsewhere), light and dark themes, the table as a table, both cards (their ids, their
# answerers, their questions, the recommended option marked and checked) and the copy-answers button.
# usability (B8): the five additions — folds (`::: fold <words>` … `:::`, one inside another, closed by default, with
# "Open all" and "Close all" only on a page that has one), contents (`[[contents]]`; every `##` heading an address, a
# second of the same words numbered, no two alike), links inside the page only (`[words](#address)` to a heading or an
# `{at: <name>}`, a link to any other address left as its words alone), ids on request (`{id: …}` hidden, "Show ids" only on a page that holds
# one), the viewer's theme (`data-theme="light"` and `"dark"` on the root), and the note box `!!!` and the mark `{!}`.
# A page made in the earlier subset renders the same body as before, but for its headings' addresses (a fixed sum of the
# earlier renderer's body). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "page-render: $*" >&2; exit 1; }
# usability (B8): no address outside the page in a link, a script or a style: no src=, no style that loads (url(,
# @import), and every href= names an id the page holds; an outside address shown as text is text, as B8 allows
inside() { grep -qiE 'src=|url\(|@import' "$1" && return 1
  grep -o 'href="[^"]*"' "$1" | sed 's/^href="//; s/"$//' | while IFS= read -r h; do
    case $h in '#'*) grep -qF "id=\"${h#\#}\"" "$1" || { echo "$h"; return 0; } ;; *) echo "$h"; return 0 ;; esac; done | grep -q . && return 1
  grep -qi 'href=[^"]' "$1" && return 1; return 0; }
mkdir -p "$T/r/.vid/replans"; cd "$T/r"
cat > .vid/replans/R2.md <<'MD'
# Replan R2

What came back: **two** merged pull requests.

- return blocks checked: 2
- corrections asked: 0

| ticket | rows | KEPT | BREACHED | unverdicted |
|---|---|---|---|---|
| #15 | 3 | 3 | 0 | 0 |
| #16 | 2 | 1 | 1 | 0 |

## Questions, by answerer

```vid-card
id: Q4
to: Dana (notes)
question: May a note's title be blank?
why: ROW-019 and the design differ
options:
- No, a title is required (recommended)
- Yes, shown as "Untitled"
```

```vid-card
id: Q5
to: Lee (sharing)
question: Does a shared link expire?
why: REQ-031 is silent on it
options:
- After 30 days (recommended)
- Never
```
MD
P=$(sh "$CHECKS/page.sh" .vid/replans/R2.md) || fail 'page.sh failed'
[ "$P" = .vid/pages/R2.html ] && [ -f "$P" ] || fail "the page is not .vid/pages/R2.html: $P"
[ "$(ls .vid/pages | grep -c .)" = 1 ] || fail 'more than one file was written'
inside "$P" || fail 'the page names an address outside it'
grep -q '<style>' "$P" && grep -q 'prefers-color-scheme: dark' "$P" || fail 'no inline style with a dark theme'
grep -q '<table><thead><tr><th>ticket</th>' "$P" && grep -q '<td>#16</td>' "$P" || fail 'the table is not rendered'
for x in 'data-id="Q4"' 'data-id="Q5"' 'to Dana (notes)' 'to Lee (sharing)' "May a note's title be blank?" 'Does a shared link expire?'; do grep -qF "$x" "$P" || fail "the page lacks $x"; done
grep -q 'class="rec"><input type="radio" name="Q4" value="No, a title is required" checked>' "$P" || fail "Q4's recommended option is not marked"
grep -q '<button id="copy" type="button">copy answers</button>' "$P" || fail 'no copy-answers button'
# usability (B8): no fold, no id, so no fold buttons and no "Show ids" on this page
grep -qE 'id="open-all"|id="close-all"|id="show-ids"' "$P" && fail 'a page with no fold or id draws their buttons'
# usability (B8): a page in the earlier subset renders the same body as before, its headings' addresses aside
L=$CHECKS/selftest/fixtures/pages-legacy.md
sh "$CHECKS/page.sh" "$L" --out "$T/legacy.html" > /dev/null || fail 'the earlier page did not render'
[ "$(sed -n '/<main>/,/<\/main>/p' "$T/legacy.html" | sed 's/ id="[^"]*"//g' | cksum)" = '3262601356 1142' ] || fail 'a page made in the earlier subset renders differently'
# usability (B8): the five additions
cat > .vid/replans/N.md <<'MD'
# New things

[[contents]]

## Steps

!!! Waiting on you: the gaps, 2 items. Answer in the panel or in the chat.

::: fold The first step
{at: req-001}
The first requirement {id: REQ-001} {!}

::: fold An inner block
- an inner point
:::
:::

## Steps

See [the first requirement](#req-001), [the steps](#steps), [the second steps](#steps-2) and [an outside page](https://example.com/x) and [a missing place](#nowhere).

## Last, & more
MD
sh "$CHECKS/page.sh" .vid/replans/N.md > /dev/null || fail 'the new page did not render'
N=.vid/pages/N.html
inside "$N" || fail 'the new page names an address outside it'
# folds: details, closed, one inside another, the two buttons
[ "$(grep -c '<details class="fold">' "$N")" = 2 ] && [ "$(grep -c '</details>' "$N")" = 2 ] || fail 'the two folds are not two blocks'
grep -q '<details class="fold" open' "$N" && fail 'a fold is open by default'
grep -qF '<summary>The first step</summary>' "$N" && grep -qF '<summary>An inner block</summary>' "$N" || fail 'a fold lacks its heading words'
awk '/<summary>The first step/ { o = 1 } /<summary>An inner block/ && o && !c { n = 1 } /<\/details>/ { c++ } END { exit !n }' "$N" || fail 'the inner fold is not inside the outer one'
grep -qF '<button id="open-all" type="button">Open all</button>' "$N" && grep -qF '<button id="close-all" type="button">Close all</button>' "$N" || fail 'no Open all and Close all'
# contents and addresses: every ## heading one, the second numbered, none alike
grep -qF '<h2 id="steps">Steps</h2>' "$N" && grep -qF '<h2 id="steps-2">Steps</h2>' "$N" && grep -qF '<h2 id="last-more">Last, &amp; more</h2>' "$N" || fail 'the headings lack their addresses'
[ -z "$(grep -o ' id="[^"]*"' "$N" | sort | uniq -d)" ] || fail 'two places share an address'
grep -qF '<nav class="contents"><ul><li><a href="#steps">Steps</a></li><li><a href="#steps-2">Steps</a></li><li><a href="#last-more">Last, &amp; more</a></li></ul></nav>' "$N" || fail 'the contents are not the three headings'
# links inside the page; the rest as text
grep -qF '<span id="req-001" class="at"></span>' "$N" || fail 'the {at:} address is not drawn'
for a in '<a href="#req-001">the first requirement</a>' '<a href="#steps">the steps</a>' '<a href="#steps-2">the second steps</a>'; do grep -qF "$a" "$N" || fail "no link $a"; done
grep -qF 'and an outside page and a missing place.' "$N" || fail 'a link to an outside address or a missing place is not left as its words'
grep -q 'example\.com\|#nowhere' "$N" && fail 'an outside address or a missing place is still named'
# ids hidden, the Show ids button; the note box and the mark
grep -qF '<span class="vid-id">REQ-001</span>' "$N" && grep -q '\.vid-id *{ *display: *none' "$N" || fail 'the id is not drawn hidden'
grep -qF '<button id="show-ids" type="button">Show ids</button>' "$N" || fail 'no Show ids button'
grep -qF '<div class="note">Waiting on you: the gaps, 2 items. Answer in the panel or in the chat.</div>' "$N" || fail 'no note box'
grep -qF '<span class="mark"' "$N" || fail 'no mark'
grep -qF '{!}' "$N" && fail 'the mark is left as text'
# usability (B8): a link whose words hold code still names no outside address; a heading named like one of the page's
# own controls (Open all, Close all, Show ids, copy) takes the next free address, so no two places share one
cat > .vid/replans/N2.md <<'MD'
# Clashes

[[contents]]

## Open all

See [the `manual`](https://example.com/x) and [the **guide**](#show-ids-2).

::: fold a block {id: X-1}
- inside
:::

## Show ids

## Copy
MD
sh "$CHECKS/page.sh" .vid/replans/N2.md > /dev/null || fail 'the clashing page did not render'
N2=.vid/pages/N2.html
inside "$N2" || fail 'the clashing page names an address outside it in a link'
grep -qF 'See [the <code>manual</code>](https://example.com/x) and <a href="#show-ids-2">the <strong>guide</strong></a>.' "$N2" || fail "markup the renderer does not read as a link is not left as text, or the inside link is lost"
grep -qF '<h2 id="open-all-2">Open all</h2>' "$N2" && grep -qF '<h2 id="show-ids-2">Show ids</h2>' "$N2" && grep -qF '<h2 id="copy-2">Copy</h2>' "$N2" || fail "a heading takes the address of one of the page's own controls"
[ -z "$(grep -o ' id="[^"]*"' "$N2" | sort | uniq -d)" ] || fail 'two places share an address on the clashing page'
# usability (B8): no outside address in a link, whatever its shape: a link whose words hold code and a link in a table
# cell whose words hold a pipe are not read as links, so they stay as the text they are, with no href; inline code and
# a fenced block that look like links render as written
cat > .vid/replans/N3.md <<'MD'
# Shapes

See [the `manual`](https://example.com/one) here.

| what | where |
|---|---|
| [read `a|b`](https://example.com/two) | there |

Code that looks like a link: `a[b](c)` and `[docs](https://example.com/a)`.

```
see [the guide](https://example.com/five) in a block
```
MD
sh "$CHECKS/page.sh" .vid/replans/N3.md > /dev/null || fail 'the shapes page did not render'
N3=.vid/pages/N3.html
inside "$N3" || fail 'the shapes page names an address outside it in a link, a script or a style'
grep -qF 'See [the <code>manual</code>](https://example.com/one) here.' "$N3" || fail 'a link whose words hold code is not left as its text'
grep -qF '<code>a[b](c)</code>' "$N3" && grep -qF '<code>[docs](https://example.com/a)</code>' "$N3" || fail 'inline code that looks like a link is not kept as written'
grep -qxF 'see [the guide](https://example.com/five) in a block' "$N3" || fail 'a fenced block that holds a link is not kept as written'
# usability (B12, B13): a page is a book only by the directive it parses: `{chapter: 1}` shown inside a code fence
# leaves an ordinary page with its cards and copy button; in a book a card keeps its words, its why among them, and
# loses only what answers
cat > .vid/replans/N4.md <<'MD'
# Not a book

```
{chapter: 1}
```

```vid-card
id: Q7
to: Dana (notes)
question: Is the footer required?
why: ROW-019 says so
options:
- Yes (recommended)
- No
```
MD
sh "$CHECKS/page.sh" .vid/replans/N4.md > /dev/null || fail 'the page with a fenced directive did not render'
grep -qF '<button id="copy" type="button">copy answers</button>' .vid/pages/N4.html && grep -qF 'name="Q7"' .vid/pages/N4.html || fail 'a directive inside a code fence takes the copy button or the choices away'
{ printf '# A book\n\n{chapter: 1}\n'; sed 1d .vid/replans/N4.md | grep -v '^{chapter: 1}$'; } > .vid/replans/N5.md
sh "$CHECKS/page.sh" .vid/replans/N5.md > /dev/null || fail 'the book with a card did not render'
grep -qF 'why: ROW-019 says so' .vid/pages/N5.html && grep -qF 'Is the footer required?' .vid/pages/N5.html || fail "a card in a book loses its words"
grep -qE '<input|<textarea|id="copy"' .vid/pages/N5.html && fail 'a card in a book can answer'
# the viewer's theme: the system's dark unless light is chosen, and dark when chosen
grep -qF ':root:not([data-theme="light"])' "$N" && grep -qF ':root[data-theme="dark"]' "$N" || fail "the page does not follow the viewer's theme"
exit 0

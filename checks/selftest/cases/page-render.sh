#!/bin/sh
# Purpose: selftest case — the one page renderer (v0.26.10.9 spec R25; §5 page-render). A replan report's markdown with
# a heading, a list, a table and two question cards addressed to two answerers: `page.sh` writes one HTML file,
# .vid/pages/<name>.html, with its style inline and no outside URL (no http(s):// and no src= or href= at all), light
# and dark themes, the table as a table, both cards (their ids, their answerers, their questions, the recommended
# option marked and checked) and the copy-answers button. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "page-render: $*" >&2; exit 1; }
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
grep -qiE 'https?://|src=|href=' "$P" && fail 'the page names an outside URL'
grep -q '<style>' "$P" && grep -q 'prefers-color-scheme: dark' "$P" || fail 'no inline style with a dark theme'
grep -q '<table><thead><tr><th>ticket</th>' "$P" && grep -q '<td>#16</td>' "$P" || fail 'the table is not rendered'
for x in 'data-id="Q4"' 'data-id="Q5"' 'to Dana (notes)' 'to Lee (sharing)' "May a note's title be blank?" 'Does a shared link expire?'; do grep -qF "$x" "$P" || fail "the page lacks $x"; done
grep -q 'class="rec"><input type="radio" name="Q4" value="No, a title is required" checked>' "$P" || fail "Q4's recommended option is not marked"
grep -q '<button id="copy" type="button">copy answers</button>' "$P" || fail 'no copy-answers button'
exit 0

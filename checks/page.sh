#!/bin/sh
# Purpose: ViD's page renderer (v0.26.10.9 spec R25, R26) — the owner's pages (the plan page, the replan report, the
# ticket preview) from their markdown, which stays as the record. `sh checks/page.sh <markdown> [--out <file>]` writes
# .vid/pages/<name>.html (name: the markdown's file name without .md): one file, its style and its one script inline,
# no outside URL, readable offline in light and dark themes. A fixed markdown subset: `#`–`####` headings, paragraphs,
# `-` and `1.` lists, tables (`| a | b |` with a `|---|` line), fenced code, `inline code` and **bold**; anything else
# shows as text. A ```vid-card block is a question card: `id:`, `to:` (the answerer), `question:`, `why:`, `options:`
# then one `- <option>` line each, the recommended one ending `(recommended)`; each card offers its options and a note,
# and the page's "copy answers" button copies every card's answer as `<id>: <option>[ — <note>]`, one per line. Prints
# the file's path. Quick yes/no questions stay in chat; the skill publishes the page as a private artifact where it can.
# usability (B8), five additions, the subset above unchanged: `::: fold <heading words>` opens a block closed by
# default and `:::` closes it, one inside another allowed, with "Open all" and "Close all" on a page that has one; every
# `##` heading gets an address made from its words (a second of the same words numbered: -2, -3), and a line
# `[[contents]]` lists them as links; `[words](#address)` links to a heading or to a line `{at: <name>}` (the entry
# after it), and a link to any other address shows its words alone, so a page names no outside address; `{id: …}` is
# drawn hidden, shown by a "Show ids" button on a page that holds one; the dark colours follow the system unless the
# root carries data-theme="light", and always with data-theme="dark". Also `!!! <words>`, a note box, and `{!}`, a
# small mark. usability (B12, B13): a line `{chapter: N}` begins a chapter of a book: its addresses carry its number
# (`cN-…`, the chapter itself `chapter-N`), a link inside it finds its own address first, `[[contents]]` lists its
# own headings, each `##` section is folded when the book opens, and a question card keeps its words but no choice, note or copy button:
# nothing is answered in a book. A page is a book by the directive read, never by a text search.
# Usage: sh checks/page.sh <markdown> [--out <file>]
# serves: tickets (0.26.10.28.4, M9)
set -eu
MD=${1:-}; [ -n "$MD" ] && [ -f "$MD" ] || { echo 'ViD page: usage — sh checks/page.sh <markdown> [--out <file>]' >&2; exit 2; }
OUT=''; [ "${2:-}" = --out ] && OUT=${3:-}
NAME=$(basename "$MD" .md); [ -n "$OUT" ] || OUT=.vid/pages/$NAME.html
mkdir -p "$(dirname "$OUT")"
TITLE=$(sed -n 's/^# //p' "$MD" | head -n 1); [ -n "$TITLE" ] || TITLE=$NAME
esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; }
{
cat <<'HEAD'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
HEAD
printf '<title>%s</title>\n' "$(esc "$TITLE")"
cat <<'STYLE'
<style>
:root { --bg: #fbfaf7; --fg: #1d1d1b; --mute: #6b6a66; --line: #dedbd3; --card: #ffffff; --accent: #2f5d8a; --rec: #e7f0e4; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg: #181816; --fg: #ecebe6; --mute: #a3a29c; --line: #3a3934; --card: #22221f; --accent: #8cb4dc; --rec: #233523; } }
:root[data-theme="dark"] { --bg: #181816; --fg: #ecebe6; --mute: #a3a29c; --line: #3a3934; --card: #22221f; --accent: #8cb4dc; --rec: #233523; }
body { background: var(--bg); color: var(--fg); font: 16px/1.55 system-ui, -apple-system, "Segoe UI", sans-serif; margin: 0; padding: 24px 16px 64px; }
main { max-width: 860px; margin: 0 auto; }
h1 { font-size: 1.6em; margin: 0 0 .6em; } h2 { font-size: 1.25em; margin: 1.8em 0 .5em; border-bottom: 1px solid var(--line); padding-bottom: .2em; }
h3 { font-size: 1.05em; margin: 1.4em 0 .4em; } h4 { font-size: 1em; margin: 1.2em 0 .3em; color: var(--mute); }
table { border-collapse: collapse; width: 100%; margin: .8em 0; font-size: .94em; display: block; overflow-x: auto; }
th, td { border: 1px solid var(--line); padding: .35em .6em; text-align: left; vertical-align: top; } th { background: var(--card); }
code { font: .9em ui-monospace, SFMono-Regular, Menlo, monospace; background: var(--card); padding: .05em .3em; border-radius: 3px; }
pre { background: var(--card); border: 1px solid var(--line); padding: .8em; overflow-x: auto; border-radius: 6px; } pre code { background: none; padding: 0; }
.card { background: var(--card); border: 1px solid var(--line); border-left: 4px solid var(--accent); border-radius: 6px; padding: .8em 1em; margin: 1em 0; }
.card .meta { color: var(--mute); font-size: .88em; } .card .q { font-weight: 600; margin: .3em 0; } .card label { display: block; margin: .2em 0; }
.card label.rec { background: var(--rec); border-radius: 4px; padding: 0 .3em; } .card textarea { width: 100%; box-sizing: border-box; margin-top: .4em; background: var(--bg); color: var(--fg); border: 1px solid var(--line); border-radius: 4px; }
button#copy { position: sticky; top: 8px; float: right; background: var(--accent); color: var(--bg); border: 0; border-radius: 6px; padding: .5em .9em; font-weight: 600; cursor: pointer; }
a { color: var(--accent); }
.tools { position: sticky; top: 8px; float: right; display: flex; gap: .4em; } .tools button { background: var(--card); color: var(--fg); border: 1px solid var(--line); border-radius: 6px; padding: .3em .7em; cursor: pointer; }
details.fold { border: 1px solid var(--line); border-radius: 6px; padding: .2em .8em; margin: .6em 0; background: var(--card); } details.fold > summary { cursor: pointer; font-weight: 600; padding: .3em 0; }
details.fold details.fold { background: var(--bg); }
nav.contents ul { padding-left: 1.2em; } .note { border: 1px solid var(--accent); border-left-width: 4px; border-radius: 6px; padding: .6em 1em; margin: 1em 0; background: var(--rec); }
.mark { color: var(--accent); font-size: .8em; vertical-align: super; } .vid-id { display: none; } body.show-ids .vid-id { display: inline; color: var(--mute); font: .8em ui-monospace, SFMono-Regular, Menlo, monospace; margin-left: .3em; }
</style>
</head><body><main>
STYLE
awk '
  function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); gsub(/"/, "\\&quot;", s); return s }
  function inl(s,   o, p, q) { s = esc(s); o = ""
    while ((p = index(s, "`")) > 0) { q = index(substr(s, p + 1), "`"); if (!q) break; o = o bold(substr(s, 1, p - 1)) "<code>" substr(s, p + 1, q - 1) "</code>"; s = substr(s, p + q + 1) }
    return o bold(s) }
  function bold(s,   o, p, q) { s = links(ext(s)); o = ""; while ((p = index(s, "**")) > 0) { q = index(substr(s, p + 2), "**"); if (!q) break; o = o substr(s, 1, p - 1) "<strong>" substr(s, p + 2, q - 1) "</strong>"; s = substr(s, p + q + 3) } return o s }
  # usability (B8): ids drawn hidden, and the small mark
  function ext(s,   p) {
    while (match(s, /\{id: [^}]*\}/)) s = substr(s, 1, RSTART - 1) "<span class=\"vid-id\">" substr(s, RSTART + 5, RLENGTH - 6) "</span>" substr(s, RSTART + RLENGTH)
    while ((p = index(s, "{!}")) > 0) s = substr(s, 1, p - 1) "<span class=\"mark\" title=\"Waiting on you\">&#9679;</span>" substr(s, p + 3)
    return s }
  # usability (B8): links, read outside code (a link in a code span is not a link): one to an address inside the page
  # is drawn, any other shows its words alone; markup not read as a link stays the text it is
  function links(s,   o, p, q, r, w, a) { o = ""
    while ((p = index(s, "[")) > 0) { q = index(substr(s, p + 1), "]("); if (!q) break
      w = substr(s, p + 1, q - 1); if (index(w, "[")) { o = o substr(s, 1, p); s = substr(s, p + 1); continue }
      r = index(substr(s, p + q + 2), ")"); if (!r) break
      a = substr(s, p + q + 2, r - 1); o = o substr(s, 1, p - 1)
      if (CH && (("c" CH "-" substr(a, 2)) in ADDR)) a = "#c" CH "-" substr(a, 2)   # usability (B12): a chapter, its own address first
      o = o ((a ~ /^#[A-Za-z0-9_-]+$/ && (substr(a, 2) in ADDR)) ? "<a href=\"" a "\">" w "</a>" : w); s = substr(s, p + q + 2 + r) }
    return o s }
  function slug(w) { w = tolower(w); gsub(/[^a-z0-9]+/, "-", w); gsub(/^-+|-+$/, "", w); return (w == "" ? "part" : w) }
  function closep() { if (para != "") { print "<p>" inl(para) "</p>"; para = "" } }
  function closel() { if (list != "") { print "</" list ">"; list = "" } }
  function closet() { if (intab) { print "</tbody></table>"; intab = 0 } }
  function closeall() { closep(); closel(); closet() }
  function closesec() { closeall(); if (book) while (fd > 0) { print "</details>"; fd-- } if (sec) { print "</details>"; sec = 0 } }
  function cells(l,   n, a, i, o) { sub(/^[ \t]*\|/, "", l); sub(/\|[ \t]*$/, "", l); n = split(l, a, "|"); o = ""; for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); o = o "<" ct ">" inl(a[i]) "</" ct ">" } return o }
  function card(   i, o, id) {
    id = esc(C["id"])
    o = "<div class=\"card\" data-id=\"" id "\"><div class=\"meta\">" id " · to " inl(C["to"]) "</div><div class=\"q\">" inl(C["question"]) "</div>"
    if (C["why"] != "") o = o "<div class=\"meta\">why: " inl(C["why"]) "</div>"
    # usability (B13): in a book a card keeps its words; only what answers (the choices, the note) is left out
    for (i = 1; i <= no; i++) { r = (OPT[i] ~ /\(recommended\)[ \t]*$/); v = OPT[i]; sub(/[ \t]*\(recommended\)[ \t]*$/, "", v)
      o = o "<label" (r ? " class=\"rec\"" : "") ">" (book ? "" : "<input type=\"radio\" name=\"" id "\" value=\"" esc(v) "\"" (r ? " checked" : "") "> ") inl(v) (r ? " <em>(recommended)</em>" : "") "</label>" }
    print o (book ? "" : "<textarea rows=\"2\" placeholder=\"a note (optional)\"></textarea>") "</div>"; split("", C); split("", OPT); no = 0 }
  # usability (B8): the first reading collects the addresses (every ## heading, numbered when its words repeat, and
  # each {at: <name>} not already taken) and whether the page has a fold or an id; the controls of the page hold
  # their names first, so a heading named like one takes the next number
  BEGIN { ADDR["open-all"] = 1; ADDR["close-all"] = 1; ADDR["show-ids"] = 1; ADDR["copy"] = 1 }
  FNR == NR { if (f1) { if ($0 ~ /^```[ \t]*$/) f1 = 0; next } if ($0 ~ /^```/) { if ($0 ~ /^```vid-card[ \t]*$/) hascard = 1; f1 = 1; next }
    # usability (B12): a line {chapter: N} begins a chapter of the book; its addresses carry its number (cN-…)
    if ($0 ~ /^\{chapter: [0-9]+\}[ \t]*$/) { CH1 = $0; gsub(/[^0-9]/, "", CH1); ADDR["chapter-" CH1] = 1; hasfold = 1; book = 1 }
    else if ($0 ~ /^## /) { w = substr($0, 4); s = (CH1 ? "c" CH1 "-" : "") slug(w); a = s; k = 1; while (a in ADDR) { k++; a = s "-" k } ADDR[a] = 1; HA[++NH] = a; HW[NH] = w; HC[NH] = CH1 + 0 }
    else if ($0 ~ /^\{at: [A-Za-z0-9_-]+\}[ \t]*$/) { x = $0; sub(/^\{at: /, "", x); sub(/\}[ \t]*$/, "", x); if (CH1) x = "c" CH1 "-" x; if (!(x in ADDR)) { ADDR[x] = 1; ATOK[x] = 1 } }
    if ($0 ~ /^::: fold /) hasfold = 1
    if (index($0, "{id: ")) hasid = 1
    next }
  !started { started = 1
    # the copy button: a page with a card, never a book (known from the directive read, not from a text search)
    if (hascard && !book) print "<button id=\"copy\" type=\"button\">copy answers</button>"
    if (hasfold || hasid) { t = "<div class=\"tools\">"
      if (hasfold) t = t "<button id=\"open-all\" type=\"button\">Open all</button><button id=\"close-all\" type=\"button\">Close all</button>"
      if (hasid) t = t "<button id=\"show-ids\" type=\"button\">Show ids</button>"
      print t "</div>" } }
  infence == 1 { if ($0 ~ /^```[ \t]*$/) { print "</code></pre>"; infence = 0 } else print esc($0); next }
  incard { if ($0 ~ /^```[ \t]*$/) { card(); incard = 0; next }
    if ($0 ~ /^[ \t]*- /) { x = $0; sub(/^[ \t]*- /, "", x); OPT[++no] = x; next }
    if (match($0, /^[a-z]+:/)) { k = substr($0, 1, RLENGTH - 1); v = substr($0, RLENGTH + 1); gsub(/^[ \t]+|[ \t]+$/, "", v); C[k] = v }
    next }
  /^```vid-card[ \t]*$/ { closeall(); incard = 1; next }
  /^```/ { closeall(); print "<pre><code>"; infence = 1; next }
  /^::: fold / { closeall(); print "<details class=\"fold\"><summary>" inl(substr($0, 10)) "</summary>"; fd++; next }
  /^:::[ \t]*$/ { closeall(); if (fd > 0) { print "</details>"; fd-- } next }
  /^\[\[contents\]\][ \t]*$/ { closeall(); o = "<nav class=\"contents\"><ul>"; for (i = 1; i <= NH; i++) if (HC[i] == CH + 0) o = o "<li><a href=\"#" HA[i] "\">" inl(HW[i]) "</a></li>"; print o "</ul></nav>"; next }
  /^\{at: [A-Za-z0-9_-]+\}[ \t]*$/ { closeall(); x = $0; sub(/^\{at: /, "", x); sub(/\}[ \t]*$/, "", x); if (CH) x = "c" CH "-" x; if (ATOK[x]) { print "<span id=\"" x "\" class=\"at\"></span>"; ATOK[x] = 0 } next }
  /^!!! / { closeall(); print "<div class=\"note\">" inl(substr($0, 5)) "</div>"; next }
  # usability (B12): in a chapter, each ## section is folded when the book opens
  /^\{chapter: [0-9]+\}[ \t]*$/ { closeall(); closesec(); CH = $0; gsub(/[^0-9]/, "", CH); print "<span id=\"chapter-" CH "\" class=\"at\"></span>"; next }
  /^#{1,4} / { closeall(); n = index($0, " ") - 1; if (n <= 2) closesec()
    if (n == 2 && CH) { print "<details class=\"fold chap\"><summary><h2 id=\"" HA[++hi] "\">" inl(substr($0, 4)) "</h2></summary>"; sec = 1; next }
    print "<h" n (n == 2 ? " id=\"" HA[++hi] "\"" : "") ">" inl(substr($0, n + 2)) "</h" n ">"; next }
  /^[ \t]*\|/ { closep(); closel()
    if (!intab) { ct = "th"; print "<table><thead><tr>" cells($0) "</tr></thead><tbody>"; intab = 1; next }
    if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) next
    ct = "td"; print "<tr>" cells($0) "</tr>"; next }
  /^[ \t]*- / { closep(); closet(); if (list != "ul") { closel(); print "<ul>"; list = "ul" } x = $0; sub(/^[ \t]*- /, "", x); print "<li>" inl(x) "</li>"; next }
  /^[ \t]*[0-9]+\. / { closep(); closet(); if (list != "ol") { closel(); print "<ol>"; list = "ol" } x = $0; sub(/^[ \t]*[0-9]+\. /, "", x); print "<li>" inl(x) "</li>"; next }
  /^[ \t]*$/ { closeall(); next }
  { closet(); closel(); para = (para == "" ? $0 : para " " $0) }
  END { if (infence) print "</code></pre>"; if (incard) card(); closeall(); while (fd > 0) { print "</details>"; fd-- } closesec() }' "$MD" "$MD"
cat <<'TAIL'
</main>
<script>
(function () {
  var b = document.getElementById('copy'); if (!b) return;
  b.addEventListener('click', function () {
    var out = [];
    document.querySelectorAll('.card').forEach(function (c) {
      var id = c.getAttribute('data-id'), r = c.querySelector('input:checked'), n = c.querySelector('textarea').value.trim();
      out.push(id + ': ' + (r ? r.value : '(no answer)') + (n ? ' — ' + n : ''));
    });
    var t = out.join('\n');
    if (navigator.clipboard) navigator.clipboard.writeText(t).then(function () { b.textContent = 'copied'; }, function () { prompt('Copy these answers:', t); });
    else prompt('Copy these answers:', t);
  });
})();
(function () {
  function all(o) { document.querySelectorAll('details.fold').forEach(function (d) { d.open = o; }); }
  var a = document.getElementById('open-all'), c = document.getElementById('close-all'), s = document.getElementById('show-ids');
  if (a) a.addEventListener('click', function () { all(true); });
  if (c) c.addEventListener('click', function () { all(false); });
  if (s) s.addEventListener('click', function () { var on = document.body.classList.toggle('show-ids'); s.textContent = on ? 'Hide ids' : 'Show ids'; });
  function reveal() {
    var h = decodeURIComponent(location.hash.slice(1)), e = h ? document.getElementById(h) : null; if (!e) return;
    for (var p = e.parentElement; p; p = p.parentElement) if (p.tagName === 'DETAILS') p.open = true;
    e.scrollIntoView();
  }
  window.addEventListener('hashchange', reveal); reveal();
})();
</script>
</body></html>
TAIL
} > "$OUT"
echo "$OUT"

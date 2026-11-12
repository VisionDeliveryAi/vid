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
@media (prefers-color-scheme: dark) { :root { --bg: #181816; --fg: #ecebe6; --mute: #a3a29c; --line: #3a3934; --card: #22221f; --accent: #8cb4dc; --rec: #233523; } }
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
</style>
</head><body><main>
STYLE
[ -n "$(grep -m 1 '^```vid-card' "$MD" || true)" ] && printf '<button id="copy" type="button">copy answers</button>\n'
awk '
  function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); gsub(/"/, "\\&quot;", s); return s }
  function inl(s,   o, p, q) { s = esc(s); o = ""
    while ((p = index(s, "`")) > 0) { q = index(substr(s, p + 1), "`"); if (!q) break; o = o bold(substr(s, 1, p - 1)) "<code>" substr(s, p + 1, q - 1) "</code>"; s = substr(s, p + q + 1) }
    return o bold(s) }
  function bold(s,   o, p, q) { o = ""; while ((p = index(s, "**")) > 0) { q = index(substr(s, p + 2), "**"); if (!q) break; o = o substr(s, 1, p - 1) "<strong>" substr(s, p + 2, q - 1) "</strong>"; s = substr(s, p + q + 3) } return o s }
  function closep() { if (para != "") { print "<p>" inl(para) "</p>"; para = "" } }
  function closel() { if (list != "") { print "</" list ">"; list = "" } }
  function closet() { if (intab) { print "</tbody></table>"; intab = 0 } }
  function closeall() { closep(); closel(); closet() }
  function cells(l,   n, a, i, o) { sub(/^[ \t]*\|/, "", l); sub(/\|[ \t]*$/, "", l); n = split(l, a, "|"); o = ""; for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); o = o "<" ct ">" inl(a[i]) "</" ct ">" } return o }
  function card(   i, o, id) {
    id = esc(C["id"]); o = "<div class=\"card\" data-id=\"" id "\"><div class=\"meta\">" id " · to " inl(C["to"]) "</div><div class=\"q\">" inl(C["question"]) "</div>"
    if (C["why"] != "") o = o "<div class=\"meta\">why: " inl(C["why"]) "</div>"
    for (i = 1; i <= no; i++) { r = (OPT[i] ~ /\(recommended\)[ \t]*$/); v = OPT[i]; sub(/[ \t]*\(recommended\)[ \t]*$/, "", v)
      o = o "<label" (r ? " class=\"rec\"" : "") "><input type=\"radio\" name=\"" id "\" value=\"" esc(v) "\"" (r ? " checked" : "") "> " inl(v) (r ? " <em>(recommended)</em>" : "") "</label>" }
    print o "<textarea rows=\"2\" placeholder=\"a note (optional)\"></textarea></div>"; split("", C); split("", OPT); no = 0 }
  infence == 1 { if ($0 ~ /^```[ \t]*$/) { print "</code></pre>"; infence = 0 } else print esc($0); next }
  incard { if ($0 ~ /^```[ \t]*$/) { card(); incard = 0; next }
    if ($0 ~ /^[ \t]*- /) { x = $0; sub(/^[ \t]*- /, "", x); OPT[++no] = x; next }
    if (match($0, /^[a-z]+:/)) { k = substr($0, 1, RLENGTH - 1); v = substr($0, RLENGTH + 1); gsub(/^[ \t]+|[ \t]+$/, "", v); C[k] = v }
    next }
  /^```vid-card[ \t]*$/ { closeall(); incard = 1; next }
  /^```/ { closeall(); print "<pre><code>"; infence = 1; next }
  /^#{1,4} / { closeall(); n = index($0, " ") - 1; print "<h" n ">" inl(substr($0, n + 2)) "</h" n ">"; next }
  /^[ \t]*\|/ { closep(); closel()
    if (!intab) { ct = "th"; print "<table><thead><tr>" cells($0) "</tr></thead><tbody>"; intab = 1; next }
    if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) next
    ct = "td"; print "<tr>" cells($0) "</tr>"; next }
  /^[ \t]*- / { closep(); closet(); if (list != "ul") { closel(); print "<ul>"; list = "ul" } x = $0; sub(/^[ \t]*- /, "", x); print "<li>" inl(x) "</li>"; next }
  /^[ \t]*[0-9]+\. / { closep(); closet(); if (list != "ol") { closel(); print "<ol>"; list = "ol" } x = $0; sub(/^[ \t]*[0-9]+\. /, "", x); print "<li>" inl(x) "</li>"; next }
  /^[ \t]*$/ { closeall(); next }
  { closet(); closel(); para = (para == "" ? $0 : para " " $0) }
  END { if (infence) print "</code></pre>"; if (incard) card(); closeall() }' "$MD"
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
</script>
</body></html>
TAIL
} > "$OUT"
echo "$OUT"

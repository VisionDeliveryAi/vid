#!/bin/sh
# Purpose: the fixture measure module (v0.9.2 3.4, R7, R20 — a TOY, never
# installed): the shape a project's tests/invariants/measure.<ext> realises
# against a real browser, here realised over the harness's page reader so
# the instrument's checker can run without one. One operation per state;
# the contract is seed/extractors/README.md "The measure module":
#
#   measure_state ENGINE ACTOR ROUTE MARKER STATE  < literal-set
#
# The literal set (stdin), one line each — what the canvas section declares,
# read at production time by the pass and carried by the instrument:
#   prop <identifier> <property> <value…>   (`root` = the section root)
#   has <identifier>                        (an identified element with nothing to compare)
#   content <text…>                         (text the canvas draws for the state)
#   control <identity>                      (a control the state draws: its data-element, or tag:name / tag:text)
#   shell <marker/state>                    (the shell rows' markers — the denominator's exclusion)
# It prints the contract's lines and nothing else:
#   navigations=1 · ok M/S/id:prop · differs M/S/id:prop cited=V painted=W ·
#   missing element M/S/id · stray M/S <identity> · missing marker M/S ·
#   missing content M/S <text> · console error M/S <message> · status M/S <code>
# The page: the section root is the element carrying data-screen-label="M/S";
# the section runs to the next labelled element; a descendant is mapped by
# its data-element (the FIRST element carrying it inside the section — a
# repeated element compares once; the hook counts them); a computed value
# is the element's inline style with var() resolved through design/tokens.css;
# colours in any notation compare as colours, lengths in any unit as computed
# pixels (root 16px, ≤1px tolerance); `<!-- console-error: … -->` and
# `<!-- status: N -->` comments stand in for the console and the response.
# After the call MEASURED_PAGE is the loaded page's handle — what the pins
# hook reads through the harness (harness_count, harness_element_text …)
# without a second navigation; call measure_state in the case's own shell,
# never inside $( ), so the hook sees it.
: "${DESIGN_TOKENS:=design/tokens.css}"

measure_state() {
  e=$1; a=$2; r=$3; m=$4; s=$5
  lit=$(mktemp); cat > "$lit"
  harness_actor "$e" "$a" || { rm -f "$lit"; echo "status $m/$s no-session"; echo "navigations=0"; return 0; }
  page=$(harness_load "$e" "$a" "$r"); MEASURED_PAGE=$page
  if [ -z "$page" ]; then echo "status $m/$s 404"; echo "missing marker $m/$s"; echo "navigations=1"; rm -f "$lit"; return 0; fi
  awk -v MS="$m/$s" -v LIT="$lit" -v TOK="$DESIGN_TOKENS" '
    function trim(x) { gsub(/^[ \t\n]+|[ \t\n]+$/, "", x); return x }
    function hex2(h,   i, c, v) { v = 0; for (i = 1; i <= length(h); i++) { c = index("0123456789abcdef", substr(h, i, 1)) - 1; v = v * 16 + c } return v }
    function colour(t,   h, r, g, b, inner, n, p) {
      if (t ~ /^#[0-9a-f]{3}$/) { h = substr(t, 2); return "rgb(" hex2(substr(h,1,1) substr(h,1,1)) ", " hex2(substr(h,2,1) substr(h,2,1)) ", " hex2(substr(h,3,1) substr(h,3,1)) ")" }
      if (t ~ /^#[0-9a-f]{6}$/) { h = substr(t, 2); return "rgb(" hex2(substr(h,1,2)) ", " hex2(substr(h,3,2)) ", " hex2(substr(h,5,2)) ")" }
      if (t ~ /^rgba?\(.*\)$/) { inner = t; sub(/^rgba?\(/, "", inner); sub(/\)$/, "", inner); gsub(/[ \t]*[,\/][ \t]*/, " ", inner); gsub(/[ \t]+/, " ", inner); n = split(trim(inner), p, " ")
        if (n >= 4 && p[4] + 0 != 1) return "rgba(" p[1] ", " p[2] ", " p[3] ", " p[4] ")"; return "rgb(" p[1] ", " p[2] ", " p[3] ")" }
      if (t == "white") return "rgb(255, 255, 255)"; if (t == "black") return "rgb(0, 0, 0)"; if (t == "red") return "rgb(255, 0, 0)"
      if (t == "transparent") return "rgba(0, 0, 0, 0)"
      return t
    }
    function resolve(v,   k, name) { for (k = 0; k < 4 && index(v, "var(--") > 0; k++) { if (!match(v, /var\(--[A-Za-z0-9_-]+\)/)) break; name = substr(v, RSTART + 6, RLENGTH - 7); v = substr(v, 1, RSTART - 1) ((name in tok) ? tok[name] : "unresolved") substr(v, RSTART + RLENGTH) } return v }
    function norm(v,   n, t, i, out, tk, nf, fn) {
      v = tolower(resolve(trim(v))); gsub(/[ \t]*,[ \t]*/, ", ", v)
      # keep functional colours as one token: lift each rgb()/rgba() out, split, put them back
      nf = 0; while (match(v, /rgba?\([^)]*\)/)) { nf++; fn[nf] = substr(v, RSTART, RLENGTH); v = substr(v, 1, RSTART - 1) "\001" nf "\001" substr(v, RSTART + RLENGTH) }
      n = split(v, tk, /[ \t]+/); out = ""
      for (i = 1; i <= n; i++) { t = tk[i]; if (t ~ /^\001[0-9]+\001,?$/) { k = t; gsub(/[\001,]/, "", k); t = fn[k + 0] }
        if (t ~ /^-?[0-9.]+rem,?$/) { sub(/rem,?$/, "", t); t = sprintf("%.2fpx", t * 16) }
        else if (t ~ /^-?[0-9.]+em,?$/) { sub(/em,?$/, "", t); t = sprintf("%.2fpx", t * 16) }
        else if (t ~ /^-?[0-9.]+px,?$/) { sub(/px,?$/, "", t); t = sprintf("%.2fpx", t + 0) }
        else t = colour(t)
        out = out (i > 1 ? " " : "") t }
      return out
    }
    function same(a, b,   na, nb, ta, tb, i, x, y) { na = split(a, ta, " "); nb = split(b, tb, " "); if (na != nb) return 0
      for (i = 1; i <= na; i++) { x = ta[i]; y = tb[i]; if (x == y) continue
        if (x ~ /px$/ && y ~ /px$/) { sub(/px$/, "", x); sub(/px$/, "", y); if ((x - y) <= 1 && (y - x) <= 1) continue }
        return 0 } return 1 }
    function decl(style, prop,   n, d, i, k, v) { n = split(style, d, ";"); for (i = 1; i <= n; i++) { if (index(d[i], ":") == 0) continue; k = trim(substr(d[i], 1, index(d[i], ":") - 1)); v = trim(substr(d[i], index(d[i], ":") + 1)); if (tolower(k) == prop) return v } return "" }
    function attr(head, name,   v, q) { if (!match(head, "(^|[ \t\n])" name "[ \t]*=[ \t]*")) return ""; v = substr(head, RSTART + RLENGTH); q = substr(v, 1, 1); if (q == "\"" || q == "\047") { v = substr(v, 2); sub(q ".*", "", v) } else sub(/[ \t\n>].*/, "", v); return v }
    BEGIN {
      while ((getline l < TOK) > 0) { if (match(l, /--[A-Za-z0-9_-]+[ \t]*:/)) { k = substr(l, RSTART + 2, RLENGTH - 3); sub(/[ \t]*:$/, "", k); v = substr(l, RSTART + RLENGTH); sub(/;.*/, "", v); tok[k] = trim(v) } }
      NW = 0; NC = 0; NK = 0
      while ((getline l < LIT) > 0) { l = trim(l); if (l == "" || l ~ /^#/) continue
        kind = l; sub(/[ \t].*/, "", kind); rest = trim(substr(l, length(kind) + 1))
        if (kind == "prop") { id = rest; sub(/[ \t].*/, "", id); rest = trim(substr(rest, length(id) + 1)); pr = rest; sub(/[ \t].*/, "", pr); val = trim(substr(rest, length(pr) + 1)); NW++; wid[NW] = id; wprop[NW] = tolower(pr); wval[NW] = val; known[id] = 1 }
        else if (kind == "has") known[rest] = 1
        else if (kind == "content") { NC++; want_text[NC] = rest }
        else if (kind == "control") drawn[rest] = 1
        else if (kind == "shell") shells[rest] = 1 }
      RS = "<"; region = ""; inside = 0; NCTL = 0; NE = 0; status = ""; NERR = 0
    }
    {
      rec = $0; if (rec == "") next
      if (rec ~ /^!--/) { c = rec; sub(/-->.*/, "", c); sub(/^!--[ \t]*/, "", c); c = trim(c)
        if (c ~ /^console-error:/) { sub(/^console-error:[ \t]*/, "", c); NERR++; errs[NERR] = c }
        if (c ~ /^status:/) { sub(/^status:[ \t]*/, "", c); status = c }
        next }
      if (rec ~ /^\//) { # a closing tag: its trailing text still belongs to the region
        if (inside) rtext = rtext " " substr(rec, index(rec, ">") + 1); next }
      head = rec; if (index(head, ">") > 0) head = substr(head, 1, index(head, ">") - 1)
      text = (index(rec, ">") > 0) ? substr(rec, index(rec, ">") + 1) : ""
      tag = tolower(head); sub(/[ \t\n].*/, "", tag)
      label = attr(head, "data-screen-label")
      if (label != "") { region = label; inside = (label == MS)
        if (inside) { NE++; eid[NE] = "root"; estyle[NE] = attr(head, "style"); rtext = "" } }
      else if (inside) { id = attr(head, "data-element"); if (id != "") { NE++; eid[NE] = id; estyle[NE] = attr(head, "style"); seen_id[id] = 1 } }
      if (inside) rtext = rtext " " text
      if (tag == "button" || tag == "a" || tag == "input" || tag == "select" || tag == "textarea") {
        ident = attr(head, "data-element")
        if (ident == "") { nm = attr(head, "name"); if ((tag == "input" || tag == "select" || tag == "textarea") && nm != "") ident = tag ":" nm; else { t = text; gsub(/[ \t\n]+/, " ", t); ident = tag ":" trim(t) } }
        NCTL++; ctl[NCTL] = ident; ctlregion[NCTL] = region }
    }
    END {
      if (status != "" && status != "200") print "status " MS " " status
      for (i = 1; i <= NERR; i++) print "console error " MS " " errs[i]
      found = 0; for (i = 1; i <= NE; i++) if (eid[i] == "root") found = 1
      if (!found) { print "missing marker " MS; print "navigations=1"; exit }
      for (i = 1; i <= NE; i++) if (!(eid[i] in first)) first[eid[i]] = i
      for (w = 1; w <= NW; w++) { id = wid[w]
        if (!(id in first)) { if (!(id in said)) print "missing element " MS "/" id; said[id] = 1; continue }
        st = estyle[first[id]]; painted = decl(st, wprop[w]); if (painted == "" && wprop[w] == "background-color") painted = decl(st, "background")
        if (index(norm(wval[w]), "unresolved") > 0) continue   # a literal the browser cannot resolve is not a finding
        if (painted == "") { print "differs " MS "/" id ":" wprop[w] " cited=" wval[w] " painted=none"; continue }
        if (same(norm(wval[w]), norm(painted))) print "ok " MS "/" id ":" wprop[w]; else print "differs " MS "/" id ":" wprop[w] " cited=" wval[w] " painted=" painted }
      for (i = 1; i <= NE; i++) { id = eid[i]; if (id == "root" || (id in known) || (id in strayed)) continue; strayed[id] = 1; print "stray " MS " " id }
      for (i = 1; i <= NCTL; i++) { if (ctlregion[i] in shells) continue; if (ctl[i] in drawn) continue; if (ctl[i] in strayed) continue; strayed[ctl[i]] = 1; print "stray " MS " " ctl[i] }
      gsub(/[ \t\n]+/, " ", rtext)
      for (i = 1; i <= NC; i++) if (index(rtext, want_text[i]) == 0) print "missing content " MS " " want_text[i]
      print "navigations=1"
    }' "$page"
  rm -f "$lit"
}

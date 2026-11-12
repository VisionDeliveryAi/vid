#!/bin/sh
# Purpose: ViD's results reader (v0.26.10.24.5). It reads each results folder DevAgent sends for a ticket's asks (T2, the head
# report, the head grade, the sort report), checks its form alone, and says what each row's evidence shows. It decides nothing: a row's standing
# is the decider's. It reads only .vid/code (a local copy of the code repository, kept current by `github.sh results-fetch`),
# the published tickets (.vid/tw/out/issue-<n>.md) and its own folder, calls no network and runs nothing of the code repository.
#   check <id> --ticket <n> [--commit <asked>]   the form of one report: `ok <id>`; or `refused <why>`, exit 1
#   read --ticket <n> --pr <p> --head <commit>   writes .vid/results/pr-<p>-<head12>.txt and prints it, exit 0 however broken a
#       report is. Report lines, then one tab-separated line per row or transition: row, kind, red, t3, fault, reason; then
#       the grades' findings, an `open grade line:` for each row whose newest grade line is breached or unclear, a `finding: note` line for each note it of the sort, a fault folder for no row, and the head report's engines, environments and
#       retested. Every head report of the pull request also feeds .vid/results/stand-in.txt: <head12> TAB <the line>, each once
#   page <evidence>                              a page of that file: <evidence less .txt>.html, by page.sh
#   declare --pr <p> --head <commit>             that head report's engines and environments, into .vid/tw/handed and .vid/budget
#   close --step <s>                             the step close (v0.26.10.25.3 R9): each chunk of the step's newest ask, .vid/decide/close/<s>/<k>/ask
#       (v0.26.10.25.4 R3), by its newest report req-<issue>-<chunk>-<k>; prints, and writes to the ask's read, tab-separated: chunk <name>
#       green|red|incomplete|absent <k or ->; row <chunk> <engine> <row> passed|failed <its first failing case>|could not run|not run; split <row>
#       <passed in> <failed in>; engine <e> <n> could not run; refused <id> <why>. Exit 0 however broken a report is
#   close --cs <N> (v0.26.10.26.2)              CS, the staging run, as C3, from <c>/cs/ask; a rule row reads by its covers: line
#   deploy --stage <N> (v0.26.10.26.2)          the okay's newest D1 report, deploy-<issue>-<k>, on its form alone, into <c>/d1/read
#   grade --ask <n> (v0.26.10.27.2)             an owner's grade ask's newest report, grade-<issue>-<k>, its commit the ask's own, into
#                                                .vid/decide/grade/<n>/read; a `vs` ask's second word checked
# v0.26.10.25.3 R11–R13: a head report's every cases file is read; once .vid/tw/handed has an engine-split line every declared engine is asked;
#   a fault folder at the head is read as a row, whether the ticket lists it or not
# v0.26.10.25.5 R4: an id landed after a ticket was published (.vid/decide/landed) has no evidence from that ticket's reports, retested
#   lines or fault folders; a row's transitions and marks come from the newest ticket holding it, by .vid/tw/log
# Usage: sh checks/results.sh check|read|page|declare|close …
# serves: tickets (0.26.10.28.4, M9)
set -eu
LC_ALL=C; export LC_ALL   # a report's bytes are bytes: one that is no character stops nothing
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
die() { echo "ViD results: $*" >&2; exit 2; }
G() { git --git-dir=.vid/code "$@"; }
mkdir -p .vid/results; T=$(mktemp -d "$PWD/.vid/results/tmp.XXXXXX"); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
# the XML reader: split on <, as a stream of tags, so that text is never read as a tag. Only failure, error and skipped directly
# inside a testcase count; system-out and any other child are passed over whole, CDATA and comments are honoured. One line a case,
# c TAB name TAB status TAB first line TAB forbidden-effect row ids; then whole TAB 1 when the file closes what it first opened
CA='function chr(n) { return (n > 8 && n < 127) ? sprintf("%c", n) : "?" }
  function hex(s,   i, v) { v = 0; for (i = 1; i <= length(s); i++) v = v * 16 + index("0123456789abcdef", tolower(substr(s, i, 1))) - 1; return v }
  function dec(s) { gsub(/&lt;/, "<", s); gsub(/&gt;/, ">", s); gsub(/&quot;/, "\"", s); gsub(/&apos;/, "\047", s)
    while (match(s, /&#[0-9]+;/)) s = substr(s, 1, RSTART - 1) chr(substr(s, RSTART + 2, RLENGTH - 3) + 0) substr(s, RSTART + RLENGTH)
    while (match(s, /&#[xX][0-9a-fA-F]+;/)) s = substr(s, 1, RSTART - 1) chr(hex(substr(s, RSTART + 3, RLENGTH - 4))) substr(s, RSTART + RLENGTH)
    gsub(/&amp;/, "\\&", s); return s }
  function attr(t, a,   v, q, p) { if (!match(t, "[ \t\n\r]" a "[ \t\n\r]*=[ \t\n\r]*[\"\047]")) return ""; q = substr(t, RSTART + RLENGTH - 1, 1); v = substr(t, RSTART + RLENGTH); p = index(v, q); return dec(substr(v, 1, p - 1)) }
  function tagend(r,   i, c, q, n) { n = length(r); q = ""; for (i = 1; i <= n; i++) { c = substr(r, i, 1); if (q != "") { if (c == q) q = "" } else if (c == "\"" || c == "\047") q = c; else if (c == ">") return i } return 0 }
  function firstline(s,   n, l, i) { n = split(s, l, "\n"); for (i = 1; i <= n; i++) { sub(/\r$/, "", l[i]); if (l[i] ~ /[^ \t]/) { sub(/^[ \t]+/, "", l[i]); return l[i] } } return "" }
  function endchild(   s, f, st, n, l, i, x) { s = msg "\n" txt; f = firstline(msg); if (f == "") f = firstline(txt)
    sub(/^[^ \t]*(Error|Exception|Failed|Failure):[ \t]*/, "", f)
    st = (child == "error") ? 3 : (child == "skipped") ? 1 : (f ~ /^setup:/) ? 3 : 2
    if (st > rank) { rank = st; first = f }
    n = split(s, l, "\n"); for (i = 1; i <= n; i++) { x = l[i]; gsub(/^[ \t\r]+|[ \t\r]+$/, "", x); if (x ~ /^vid-forbidden-effect: [^ \t]+$/) fb = fb " " substr(x, 23) }
    child = "" }
  function endcase(   s) { s = (rank == 3) ? "errored" : (rank == 2) ? "failed" : (rank == 1) ? "skipped" : "passed"; gsub(/[\t\r\n]/, " ", first); gsub(/[\t\r\n]/, " ", cname)
    printf "c\t%s\t%s\t%s\t%s\n", cname, s, first, fb; incase = 0; rank = 0; first = ""; fb = "" }
  BEGIN { RS = "<"; outer = ""; closed = 0; rank = 0; first = ""; fb = ""; child = ""; skip = ""; mode = ""; txt = "" }
  NR == 1 { next }
  { r = $0
    if (mode == "cdata") { p = index(r, "]]>"); if (!p) { if (child != "") txt = txt "<" r; next } if (child != "") txt = txt "<" substr(r, 1, p - 1) dec(substr(r, p + 3)); mode = ""; next }
    if (mode == "comment") { p = index(r, "-->"); if (p) { mode = ""; if (child != "") txt = txt dec(substr(r, p + 3)) } next }
    if (substr(r, 1, 8) == "![CDATA[") { r = substr(r, 9); p = index(r, "]]>"); if (!p) { mode = "cdata"; if (child != "") txt = txt r; next } if (child != "") txt = txt substr(r, 1, p - 1) dec(substr(r, p + 3)); next }
    if (substr(r, 1, 3) == "!--") { p = index(r, "-->"); if (!p) mode = "comment"; else if (child != "") txt = txt dec(substr(r, p + 3)); next }
    if (substr(r, 1, 1) ~ /[?!]/) next
    if (skip != "") { if (index(r, "/" skip) == 1) skip = ""; next }
    if (r !~ /^\/?[A-Za-z_]/) { if (child != "") txt = txt "<" dec(r); next }
    e = tagend(r); if (!e) next
    tag = substr(r, 1, e - 1); rest = substr(r, e + 1); slf = (substr(tag, length(tag), 1) == "/"); nm = tag; sub(/^\//, "", nm); sub(/[ \t\r\n\/].*/, "", nm)
    if (substr(tag, 1, 1) == "/") { if (child != "" && nm == child) endchild(); else if (nm == "testcase" && incase) { if (child != "") endchild(); endcase() } else if (nm == outer) closed = 1; next }
    if (nm == "testsuites" || nm == "testsuite") { if (outer == "") outer = nm; if (nm == outer) closed = slf; next }
    if (nm == "testcase") { if (incase) endcase(); cname = attr(" " tag, "name"); incase = 1; if (slf) endcase(); next }
    if (!incase || child != "") { if (child != "") txt = txt dec(rest); next }
    if (nm == "failure" || nm == "error" || nm == "skipped") { child = nm; msg = attr(" " tag, "message"); txt = dec(rest); if (slf) endchild(); next }
    if (!slf) skip = nm }
  END { if (incase && closed) endcase(); printf "whole\t%d\n", closed }'
cases() { G show "$1" 2>/dev/null | awk "$CA"; }
iswhole() { cases "$1" | grep -q "^whole${TAB}1\$"; }
newest() { G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/$1-*" 2>/dev/null | sed -n "s/^$1-\([0-9][0-9]*\)\$/\1/p" | sort -n | tail -n 1; }
# ticket <n>: KIND, ENGS (primary first), $T/tk: `row id kind marks transitions`, `reg id`, `flt id`
ticket() { F=.vid/tw/out/issue-$1.md; [ -f "$F" ] || die "no published ticket at $F"
  awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^## / { s = substr($0, 4); next }
    s == "Header" && /^- kind: / { print "kind\t" substr($0, 9); next }
    s == "Engines" && /^- (primary|also): / { sub(/^- [a-z]+: /, ""); print "eng\t" $0; next }
    s == "Rows" && /^> / { a = tr(substr($1, 3)); b = tr($2); if (a ~ /^[A-Z]+-[0-9]/) { id = a; k = b } else { id = b; k = a }; o[++n] = id; K[id] = k; t = 0; p = index($0, "transitions:")
      if (p) { r = " " substr($0, p + 12); while ((q = index(r, " " (t + 1) ". ")) > 0) { r = substr(r, q + 1); t++ } } N[id] = t; next }
    s == "Rows" && match($0, /^- [^ ]+ marks: /) { split($0, w, " "); m = substr($0, RLENGTH + 1); gsub(/\t/, " ", m); M[w[2]] = m; next }
    s == "Regression rows" && /^- [A-Z]+-[0-9]/ { split($0, w, " "); print "reg\t" w[2]; next }
    s == "Faulted rows" && /^- [A-Z]+-[0-9]/ { split($0, w, " "); sub(/:$/, "", w[2]); print "flt\t" w[2]; next }
    END { for (i = 1; i <= n; i++) printf "row\t%s\t%s\t%s\t%d\n", o[i], K[o[i]], (M[o[i]] == "" ? "-" : M[o[i]]), N[o[i]] }' "$F" > "$T/tk"
  KIND=$(sed -n "s/^kind$TAB//p" "$T/tk" | head -n 1); ENGS=$(sed -n "s/^eng$TAB//p" "$T/tk" | tr '\n' ' ')
  if [ -n "$ENGS" ] && grep -q '^engine-split ' .vid/tw/handed 2>/dev/null; then for e in $(sed -n 's/^engines \([^|]*\)|.*/\1/p' .vid/tw/handed | tail -n 1); do case " $ENGS " in *" $e "*) ;; *) ENGS="$ENGS$e " ;; esac; done; fi; }   # R11: every declared engine, once a row has split
# form <id> <asked commit, or empty>: WHY says why the report may not be read, with exit 1. With KIND empty it leaves the cases files alone
form() { R=refs/heads/vid-results/$1; WHY=''
  case $1 in red-*) FN=results.txt; BY=TM ;; pr-*|req-*) FN=results.txt; BY=TM ;; grade-pr-*) FN=grade.txt; BY=GR ;; grade-[0-9]*) FN=grade.txt; BY=GR ;; sort-pr-*) FN=sorted.txt; BY=SR ;; deploy-[0-9]*) FN=report.txt; BY=DP ;; *) WHY="not a T2, head report, head grade, sort report, run report or deploy report: $1"; return 1 ;; esac
  G rev-parse -q --verify "$R" > /dev/null 2>&1 || { WHY="no branch vid-results/$1"; return 1; }
  x=$(G ls-tree -r --name-only "$R" | grep -v "^$1/" | head -n 1 || true); [ -z "$x" ] || { WHY="the branch holds more than its folder: $x"; return 1; }
  G cat-file -e "$R:$1/$FN" 2>/dev/null || { WHY="no $FN"; return 1; }
  x=$(G show "$R:$1/$FN" | head -n 1); [ "$x" = "by: $BY" ] || { WHY="the first line of $FN is not by: $BY: $x"; return 1; }
  c=$(G show "$R:$1/$FN" | sed -n 's/^commit: *//p' | head -n 1); [ -n "$c" ] || { WHY="$FN names no commit"; return 1; }
  G cat-file -e "$c^{commit}" 2>/dev/null || { WHY="the code repository lacks the commit $c"; return 1; }
  case $1 in red-*) ;; req-*|grade-[0-9]*|deploy-[0-9]*) [ -n "$2" ] && [ "$c" = "$2" ] || { WHY="the commit $c is not the one asked for, ${2:-none}"; return 1; } ;; *) h=${1%-*}; h=${h##*-}
    if [ -n "$2" ]; then [ "$c" = "$2" ] || { WHY="the commit $c is not the one asked for, $2"; return 1; }
    else case $c in "$h"*) ;; *) WHY="the commit $c is not this report's head, $h"; return 1 ;; esac; fi ;; esac
  case $1 in sort-pr-*) x=$(G show "$R:$1/$FN" | awk 'NR > 2 && !/^[^ ]+ (test it|note it|drop it) — / { print; exit }'); [ -z "$x" ] || { WHY="a line of sorted.txt holds none of the three words: $x"; return 1; } ;; esac
  case $1 in pr-*) x=$(G show "$R:$1/$FN" | sed -n 's/^retested: *//p' | tr ' ' '\n' | grep -v '^$' | grep -Ev '^[A-Z]+-[0-9][A-Za-z0-9-]*$' | head -n 1 || true); [ -z "$x" ] || { WHY="a retested: line holds more than row ids: $x"; return 1; } ;; esac   # read carries it, for the decider
  case $1 in req-*) for e in $CE; do iswhole "$R:$1/cases-$e.xml" || { WHY="no whole cases file for $e"; return 1; }; done; return 0 ;; esac   # a close chunk's report: every engine of its chunk
  [ "$FN" = results.txt ] && [ -n "$KIND" ] || return 0
  E=$ENGS; case $1 in red-*) E=${ENGS%% *} ;; *) [ "$KIND" != skeleton ] || { E=$(G show "$R:$1/$FN" | sed -n 's/^engines: *//p' | head -n 1); [ -n "$E" ] || { WHY='a skeleton head report declares no engines'; return 1; }; } ;; esac
  for e in $E; do iswhole "$R:$1/cases-$e.xml" || { WHY="no whole cases file for $e"; return 1; }; done
  case $1 in pr-*) for r in $(G ls-tree -r --name-only "$R" | sed -n "s|^$1/faults/\([^/]*\)/.*|\1|p" | sort -u); do G cat-file -e "$R:$1/faults/$r/inconclusive.txt" 2>/dev/null || iswhole "$R:$1/faults/$r/cases-${E%% *}.xml" || { WHY="no whole cases file for ${E%% *} in faults/$r"; return 1; }; done ;; esac; }
sl() { G show "$R:$1/results.txt" | sed -n "s/^$2: *//p"; }
# the evidence, from the stream $T/in: the format's matching, red rule and faults
EV='function norm(s) { gsub(/[-_.]/, "-", s); return s }
  function hit(n, id,   o, p, a, b, s) { id = norm(id); o = 1
    while ((p = index(substr(n, o), id)) > 0) { a = o + p - 1; b = (a > 1) ? substr(n, a - 1, 1) : ""; s = substr(n, a + length(id), 1); if (b !~ /[A-Za-z0-9]/ && s !~ /[A-Za-z0-9]/) return 1; o = a + 1 } return 0 }
  function add(set, name, st, f, fbd,   i) { i = ++nc[set]; cn[set, i] = norm(name); cs[set, i] = st; cf[set, i] = f; cb[set, i] = " " fbd " " }
  function scan(set, id,   i, w) { sn = 0; sfail = 0; sbad = 0; serr = 0; ssu = 0; sline = ""; sbline = ""; sfb = ""
    for (i = 1; i <= nc[set]; i++) if (hit(cn[set, i], id)) { sn++; w = cs[set, i]; if (w == "failed") { sfail++; if (sline == "") sline = cf[set, i]; sfb = sfb cb[set, i] } else if (w != "passed") { sbad++; serr += (w == "errored"); ssu += (w == "errored" && cf[set, i] ~ /^setup:/); if (sbline == "") sbline = w ": " cf[set, i] } } }
  function t3c(id,   j, e, rf) { T3 = "passed"; TW = ""
    for (j = 1; j <= ne; j++) { e = en[j]; scan("h:" e, id)
      if (CT) { ES[e] = 1; if (!sn || sfail || sbad) EN[e] = 1 }
      if (e in xa) { rf = (sfail || serr > ssu); if (rf) { T3 = "failed"; if (TW == "") TW = (sline != "" ? sline : sbline) " in " e } else if ((!sn || sbad) && CT) UX[e] = 1; if (rf && CT) EF[e] = 1; continue }   # an engine not asked (R11): its failure fails the row; setup:, a skip or no case could not run
      if (CT && (sfail || sbad > ssu)) EF[e] = 1
      if (!sn) { T3 = "failed"; if (TW == "") TW = "no case" (ne > 1 ? " in " en[j] : "") } else if (sfail || sbad) { T3 = (!sfail && ssu == sbad && T3 != "failed") ? "setup" : "failed"; if (TW == "") TW = (sline != "" ? sline : sbline) } } }
  function t3(id,   k, a, w) { t3c(id); a = T3; w = TW
    for (k = 1; k <= nj[id] + 0; k++) { t3c(id "-T" k); if (T3 != "passed") { a = (a == "failed" || T3 == "failed") ? "failed" : "setup"; w = why(w, "T" k ": " TW) } }
    if (rl[id]) { if (!(id in cov)) { if (a == "passed") a = "missing"; w = why("no covers: line", w) } else if (cov[id] + 0 == 0) { if (a != "setup") a = "failed"; w = why("covers 0", w) } else w = why("covers " cov[id], w) }
    T3 = a; TW = w }
  function fault(id,   set, c, w, nf, cw, ok, d, k) { FV = ""; FW = ""; FQ = 0; d = ((id in fdir) || (id in inc)) ? id : bm[id]; if (!(d in fdir) && !(d in inc)) return; set = "f:" d; used[d] = 1
    if (d in inc) { FV = "inconclusive"; FW = inc[d]; return }
    c = fctl[d]; ok = (c != ""); cw = ""
    if (ok) { t3(c); if (T3 != "passed") { ok = 0; cw = "control " c " did not pass at T3" } else { scan(set, c); if (c == id || c == bm[id]) { if (sbad) { ok = 0; cw = sbline } else if (sn > sfail) cw = "control: another case of the row passed"; else { ok = 0; cw = "no case of its own passed under the fault" } } else if (!sn || sfail || sbad) { ok = 0; cw = "control " c " did not pass under the fault" (sn ? "" : ": no case") } else cw = "control " c " passed" } }
    scan(set, id); if (d != id && !sfail) { n2t = split(jt[d], tw2, " "); for (k = 1; k <= n2t; k++) if (tw2[k] != id) { scan(set, tw2[k]); if (sfail) { FV = ""; FQ = 1; return } } scan(set, id) } if (!sn) { FV = "inconclusive"; FW = why("no case of the row under its fault", cw); return } if (sbad) { FV = "inconclusive"; FW = why(sbline, cw); return }
    nf = sfail; w = sline
    if (!nf) { FV = "not-proven"; FW = why("its test still passes under its fault", cw); return }
    if (prot[id] && !index(sfb, " " id " ") && !index(sfb, " " bm[id] " ")) { FV = "inconclusive"; FW = why("no vid-forbidden-effect line: " w, cw); return }
    if (c == "" && KD != "skeleton") { FV = "inconclusive"; FW = "no control named"; return }
    FV = (c == "" || ok) ? "proven" : "inconclusive"; FW = why(w, cw) }
  function why(a, b) { return (a == "") ? b : (b == "") ? a : a "; " b }
  BEGIN { FS = "\t"; KD = ""; hs = "none"; ne = 0 }
  $1 == "kind" { KD = $2 } $1 == "eng" { en[++ne] = $2 } $1 == "xeng" { en[++ne] = $2; xa[$2] = 1 } $1 == "later" { LAT = 1 }
  $1 == "line" { print $2 }
  $1 == "row" { i = ++nr; id[i] = $2; kd[i] = $3; cl[i] = $4; ow[i] = ($5 ~ /(^|[ ;])(owed-[a-z-]*|seam)($|[ ;])/); dwo[$2] = ow[i]; prot[$2] = ($5 ~ /(^|[ ;])protection($|[ ;])/); rl[$2] = ($5 ~ /(^|[ ;])rule($|[ ;])/); bs[i] = $6; bm[$2] = $6; nj[$2] = $7 + 0; if ($2 != $6) jt[$6] = jt[$6] " " $2 }
  $1 == "flt" { fl[$2] = 1 } $1 == "hs" { hs = $2; hw = $3 } $1 == "h" { add("h:" $2, $3, $4, $5, $6) } $1 == "cov" { cov[$2] = $3 } $1 == "ret" { ret[$2] = 1 }
  $1 == "ts" { ts[$2] = $3; tw[$2] = $4; o2[++n2] = $2 } $1 == "tr" { tl[$2, $3] = 1 } $1 == "t" { add("t:" $2, $3, $4, $5, $6) }
  $1 == "fd" { fdir[$2] = 1; if ($3 != "") fctl[$2] = $3 } $1 == "fi" { inc[$2] = $3 } $1 == "f" { add("f:" $2, $3, $4, $5, $6) }
  $1 == "gx" { gx[++ng] = $2 } $1 == "gt" { gt[++ngt] = $2 } $1 == "tail" { tl2[++nt] = $2 }
  END { for (i = 1; i <= nr; i++) { r = id[i]; b = bs[i]; RED = "n/a"; RW = ""; c = cl[i]
      if (c == "t" && KD != "skeleton" && KD != "reached" && !ow[i]) { RED = "no-red"; RW = (n2 ? "no T2 lists it" : "no T2")
        for (j = 1; j <= n2; j++) { k = o2[j]; if (ts[k] == "lost") { RW = "T2 " k " refused, its rows unread: " tw[k]; RED = "missing"; continue } if ((k, r) in tl || (k, b) in tl) { if (ts[k] != "read") { RED = "missing"; RW = "T2 " k " refused: " tw[k]; break }
            scan("t:" k, r); RED = (sfail && !serr) ? "red" : "no-red"; RW = (RED == "red") ? "" : (sbline != "" ? "T2: " sbline : (sn ? "T2: it passed" : "T2: no case")); break } } }
      isret = (hs == "read" && ((r in ret) || (b in ret)))
      if (ow[i]) { T3v = "owed"; TR = isret ? "retested: owed again" : "" }
      else if (hs == "refused") { T3v = "missing"; TR = "head report refused: " hw } else if (hs == "none") { T3v = "missing"; TR = "no head report" }
      else { split("", ES); split("", EN); split("", EF); split("", UX); CT = 1; t3(r); CT = 0; T3v = T3; TR = TW; Pe = ""; Fe = ""
        for (j = 1; j <= ne; j++) { e = en[j]; if (EF[e]) Fe = Fe (Fe == "" ? "" : " ") e; else if (ES[e] && !EN[e]) Pe = Pe (Pe == "" ? "" : " ") e; if (UX[e]) cx[e]++ }
        if (Pe != "" && Fe != "") spl[++nsl] = "split\t" r "\t" Pe "\t" Fe }
      need = !ow[i] && (isret || (((r in fl) || (b in fl)) && c == "t") || (c == "t" && (KD == "skeleton" || RED == "no-red")))
      FVv = "n/a"; FR = ""
      if (!ow[i]) { if (hs == "read") fault(r); else FV = ""
        if (FV == "") { if (need && (!FQ || isret)) { FVv = (T3v == "failed" || T3v == "setup") ? "waits" : "missing"; FR = (FVv == "waits") ? "" : "no fault folder" } }
        else if (T3v == "failed" || T3v == "setup") FVv = "waits" (need ? "" : " extra"); else if (T3v != "passed") { FVv = "missing" (need ? "" : " extra"); FR = "no T3 to read it by" } else { FVv = FV (need ? "" : " extra"); FR = FW } }
      if (ow[i] && (r in fdir)) { used[r] = 1; FR = "a fault folder no owed row needs" }
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", r, (c != "t" && kd[i] == "transition") ? "retested" : kd[i], RED, T3v, FVv, why(why(RW, TR), FR) }
    for (j = 1; j <= nsl; j++) print spl[j]
    for (j = 1; j <= ne; j++) if ((en[j] in xa) && cx[en[j]]) printf "engine %s: %d could not run\n", en[j], cx[en[j]]
    for (j = 1; j <= ng; j++) print gx[j]
    for (j = 1; j <= ngt; j++) { r = gt[j]; if (dwo[r] || (!LAT && !((r in fdir) || (bm[r] in fdir)))) print "open grade line: " r }   # a weak-test line closed by its break, and at any later head than that of the grade (v0.26.10.25.2 R3)
    for (r in fdir) if (!(r in used)) printf "fault folder for no row: %s\n", r
    for (j = 1; j <= nt; j++) print tl2[j] }'
# one report's cases into the stream, each line headed by its words: push <rev> <head…>
push() { cases "$1" | awk -F'\t' -v h="$2" '$1 == "c" { print h "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' >> "$T/in"; }
tally() { cases "$1" | awk -F'\t' '$1 == "c" { t[$3]++ } END { printf "%d passed, %d failed, %d errored, %d skipped", t["passed"], t["failed"], t["errored"], t["skipped"] }'; }
# standins <p>: stand-in-pr-<p>.txt, rebuilt from each head's newest attempt, oldest report first; stand-in.txt, all of them, each line once
standins() { P=$1; O=.vid/results/stand-in-pr-$P.txt; : > "$T/hd"; : > "$T/so"   # the rebuild in $T/so, published once (R6)
  for h in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/pr-$P-*" 2>/dev/null | sed -n "s/^pr-$P-\([0-9a-f]\{12\}\)-[0-9][0-9]*\$/\1/p" | sort -u); do
    k=$(newest "pr-$P-$h"); i=pr-$P-$h-$k; form "$i" '' || continue; printf '%s %s %s\n' "$(G log -1 --format=%ct "refs/heads/vid-results/$i")" "$h" "$i" >> "$T/hd"; done
  sort -n "$T/hd" | while read -r _d h i; do R=refs/heads/vid-results/$i; sl "$i" stand-in | while IFS= read -r l; do [ -n "$l" ] || continue
      cut -f2- "$T/so" | grep -qxF "stand-in: $l" || printf '%s\tstand-in: %s\n' "$h" "$l" >> "$T/so"; done; done || exit 1; put "$O" < "$T/so" || exit 1
  for n in $(ls .vid/results | sed -n 's/^stand-in-pr-\([0-9][0-9]*\)\.txt$/\1/p' | sort -n); do cat ".vid/results/stand-in-pr-$n.txt"; done | awk -F'\t' '!s[$2]++' > "$T/si" || exit 1; put .vid/results/stand-in.txt < "$T/si" || exit 1; }
cmd_read() { N=''; P=''; HD=''; while [ $# -ge 2 ]; do case $1 in --ticket) N=$2 ;; --pr) P=$2 ;; --head) HD=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -n "$N" ] && [ -n "$P" ] && [ -n "$HD" ] || die 'usage — sh checks/results.sh read --ticket <n> --pr <p> --head <commit>'
  ticket "$N"; HD=$(G rev-parse -q --verify "$HD^{commit}" 2>/dev/null || echo "$HD"); H=$(printf %s "$HD" | cut -c1-12); : > "$T/in"; printf 'kind\t%s\n' "$KIND" >> "$T/in"; mkdir -p .vid/results
  printf 'line\tticket %s, pull request %s, head %s\n' "$N" "$P" "$HD" >> "$T/in"
  for k in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/red-$N-*" 2>/dev/null | sed -n "s/^red-$N-\([0-9][0-9]*\)\$/\1/p" | sort -rn); do i=red-$N-$k; R=refs/heads/vid-results/$i
    if form "$i" ''; then printf 'ts\t%s\tread\t\n' "$i"; printf 'line\treport T2 %s read: %s\n' "$i" "$(tally "$R:$i/cases-${ENGS%% *}.xml")"; push "$R:$i/cases-${ENGS%% *}.xml" "t$TAB$i"
    else printf 'ts\t%s\trefused\t%s\n' "$i" "$WHY"; printf 'line\treport T2 %s refused %s\n' "$i" "$WHY"; fi >> "$T/in"
    l=$(G show "$R:$i/results.txt" 2>/dev/null | sed -n 's/^rows: *//p' | head -n 1 || true)
    if [ -n "$l" ]; then for r in $l; do printf 'tr\t%s\t%s\n' "$i" "$r"; done >> "$T/in"; else [ -z "$WHY" ] || printf 'ts\t%s\tlost\t%s\n' "$i" "$WHY" >> "$T/in"; fi; done
  case $KIND in skeleton|reached) ;; *) [ -n "$(G for-each-ref "refs/heads/vid-results/red-$N-*" 2>/dev/null)" ] || printf 'line\treport T2 none\n' >> "$T/in" ;; esac
  k=$(newest "pr-$P-$H"); i=pr-$P-$H-${k:-0}; RET=''; FD=''
  if [ -z "$k" ]; then printf 'hs\tnone\t\nline\treport head none\n' >> "$T/in"
  elif ! form "$i" "$HD"; then printf 'hs\trefused\t%s\nline\treport head %s refused %s\n' "$WHY" "$i" "$WHY" >> "$T/in"
  else R=refs/heads/vid-results/$i; printf 'hs\tread\t\n' >> "$T/in"; E=$ENGS; [ "$KIND" != skeleton ] || E=$(sl "$i" engines | head -n 1)
    X=$(G ls-tree --name-only "$R:$i" | sed -n 's/^cases-\([^ ]*\)\.xml$/\1/p' | awk -v E=" $E " '!index(E, " " $0 " ")' | tr '\n' ' ')   # R11: the engines it holds that were not asked
    printf 'line\treport head %s read:' "$i" >> "$T/in"; for e in $E $X; do printf ' %s %s;' "$e" "$(tally "$R:$i/cases-$e.xml")" >> "$T/in"; done; echo >> "$T/in"
    for e in $E; do printf 'eng\t%s\n' "$e" >> "$T/in"; push "$R:$i/cases-$e.xml" "h$TAB$e"; done; for e in $X; do printf 'xeng\t%s\n' "$e" >> "$T/in"; push "$R:$i/cases-$e.xml" "h$TAB$e"; done
    sl "$i" covers | while read -r a b; do printf 'cov\t%s\t%s\n' "$a" "$b"; done >> "$T/in"; RET=$(sl "$i" retested | tr '\n' ' ')
    for r in $RET; do printf 'ret\t%s\n' "$r" >> "$T/in"; done; P1=${E%% *}
    for r in $(G ls-tree -r --name-only "$R" | sed -n "s|^$i/faults/\([^/]*\)/.*|\1|p" | sort -u); do D=$R:$i/faults/$r; c=$(G show "$D/control.txt" 2>/dev/null | head -n 1 | tr -d ' \r' || true); printf 'fd\t%s\t%s\n' "$r" "$c" >> "$T/in"; FD="$FD $r"
      if G cat-file -e "$D/inconclusive.txt" 2>/dev/null; then printf 'fi\t%s\t%s\n' "$r" "$(G show "$D/inconclusive.txt" | head -n 1 | tr '\t' ' ')" >> "$T/in"
      else push "$D/cases-$P1.xml" "f$TAB$r"; fi; done
    { for w in engines environments retested; do x=$(sl "$i" "$w" | tr '\n' ' ' | sed 's/ *$//'); [ -z "$x" ] || printf 'tail\t%s: %s\n' "$w" "$x"; done; } >> "$T/in"; fi
  awk -F'\t' '$1 == "flt"' "$T/tk" > "$T/in.rows"
  [ "$KIND" = reached ] || awk -F'\t' '$1 == "row" { if ($5 + 0 > 0) { for (i = 1; i <= $5; i++) printf "row\t%s-T%d\ttransition\tt\t%s\t%s\n", $2, i, $4, $2 } else printf "row\t%s\t%s\tt\t%s\t%s\n", $2, $3, $4, $2 }' "$T/tk" >> "$T/in.rows"
  { sed -n "s/^reg$TAB//p" "$T/tk"; [ "$KIND" != reached ] || cut -f1,2 "$T/tk" | sed -n "s/^row$TAB//p"; } > "$T/more"; for r in $(cat "$T/more"); do more "$r" regression r; done
  for r in $RET; do more "$r" retested o; done
  for r in $FD; do ! printf %s "$r" | grep -Eq '^[A-Z]+-[0-9][A-Za-z0-9-]*$' || more "$r" regression r; done   # R13: a fault folder is read wherever it is
  # the ticket's one grade (v0.26.10.25.2 R2): the oldest grade report's head, its newest attempt, and no other
  GL=''; : > "$T/gr"; i=$(G for-each-ref --sort=committerdate --format='%(refname:lstrip=3)' "refs/heads/vid-results/grade-pr-$P-*" 2>/dev/null | head -n 1); if [ -n "$i" ]; then i=${i%-*}; h=${i##*-}; i=$i-$(newest "$i"); if form "$i" ''; then GL="report grade $i read"; { G show "refs/heads/vid-results/$i:$i/grade.txt"; echo; } >> "$T/gr"; else GL="report grade $i refused $WHY"; fi; [ "$h" = "$H" ] || printf 'later\t1\n' >> "$T/in"; fi
  [ "$KIND" = reached ] || printf 'line\t%s\n' "${GL:-report grade none}" >> "$T/in"; awk '/^finding: / { if (!s[$0]++) print "gx\t" $0; next } /^(by|commit): / || !NF { next } { v[$1] = $2; k[$1] = $3 } END { for (r in v) { if (v[r] != "kept") print "gx\tlist: " r; if (v[r] ~ /^(breached|unclear)$/) print ((v[r] == "breached" && k[r] == "test") ? "gt\t" : "gx\topen grade line: ") r } }' "$T/gr" >> "$T/in"
  i=$(G for-each-ref --sort=committerdate --format='%(refname:lstrip=3)' "refs/heads/vid-results/sort-pr-$P-*" 2>/dev/null | tail -n 1)
  if [ -z "$i" ]; then [ "$KIND" = reached ] || printf 'line\treport sort none\n' >> "$T/in"
  elif ! form "$i" ''; then printf 'line\treport sort %s refused %s\n' "$i" "$WHY" >> "$T/in"
  else printf 'line\treport sort %s read\n' "$i" >> "$T/in"; G show "refs/heads/vid-results/$i:$i/sorted.txt" | awk 'NR > 2 && $2 == "note" && $3 == "it" { print "gx\tfinding: note — " substr($0, length($1) + 14) }' >> "$T/in"; fi
  # R4: a landed id's evidence starts at its landing: from a ticket published before it, none of its lines is read
  stale "$N" > "$T/stale"; if [ -s "$T/stale" ]; then for f in in.rows in; do awk -F'\t' -v S="$T/stale" 'BEGIN { while ((getline l < S) > 0) X[l] = 1 }
      ($1 == "row" || $1 == "flt") && (($2 in X) || ($6 in X)) { next } ($1 ~ /^(ret|fd|fi|f)$/) && ($2 in X) { next } $1 == "tr" && ($3 in X) { next } { print }' "$T/$f" > "$T/$f.s" && mv "$T/$f.s" "$T/$f"; done; fi
  setups "$P"; { cat "$T/in.rows"; cat "$T/in"; } | awk "$EV" > "$T/ev" || exit 1; put ".vid/results/pr-$P-$H.txt" < "$T/ev" || exit 1; standins "$P"; cat ".vid/results/pr-$P-$H.txt"; }
# setups <p>: R12's count, the setup: errors of each engine over the pull request's head reports, each head's newest attempt, as tail lines
setups() { : > "$T/su"; for h in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/pr-$1-*" 2>/dev/null | sed -n "s/^pr-$1-\([0-9a-f]\{12\}\)-[0-9][0-9]*\$/\1/p" | sort -u); do
    k=$(newest "pr-$1-$h"); i=pr-$1-$h-$k; form "$i" '' || continue; R=refs/heads/vid-results/$i
    for e in $(G ls-tree --name-only "$R:$i" | sed -n 's/^cases-\([^ ]*\)\.xml$/\1/p'); do cases "$R:$i/cases-$e.xml" | awk -F'\t' -v e="$e" '$1 == "c" && $3 == "errored" && $4 ~ /^setup:/ { n++ } END { print e "\t" n + 0 }'; done; done >> "$T/su"
  awk -F'\t' '{ if (!($1 in n)) o[++m] = $1; n[$1] += $2; k[$1]++ } END { for (i = 1; i <= m; i++) if (n[o[i]]) printf "tail\tsetup errors %s: %d cases over %d runs\n", o[i], n[o[i]], k[o[i]] }' "$T/su" >> "$T/in"; }
# more <row> <kind> <class>: a row beyond the ticket's own. A journey is one line, every transition's cases needed, or a line each when retested
more() { has "$1" && return 0; n=$(tcount "$1"); m=$(mark "$1"); case " $RET " in *" $1 "*) i=0; while [ "$i" -lt "${n:-0}" ]; do i=$((i + 1)); printf 'row\t%s-T%d\ttransition\t%s\t%s\t%s\n' "$1" "$i" "$3" "$m" "$1"; done >> "$T/in.rows"; [ "${n:-0}" = 0 ] || return 0 ;; esac
  printf 'row\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$m" "$1" "${n:-0}" >> "$T/in.rows"; }
# v0.26.10.25.5 (R4): stale <n>, the ids landed after ticket n was published; tfile <row>, the newest ticket holding it, by the log
stale() { [ -f .vid/tw/log ] || return 0; awk -v n="$1" '$1 == "published" && $2 == n { p = 1; next } p && $1 == "landed" { for (i = 2; i <= NF; i++) if ($i ~ /^ids=/) { m = split(substr($i, 5), a, ","); for (j = 1; j <= m; j++) print a[j] } }' .vid/tw/log | sort -u; }   # by the log's order: a landing's line follows the ticket's
tfile() { n=''; [ ! -f .vid/tw/log ] || n=$(awk -v r="$1" '($1 == "published" || $1 == "amended") { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/ && index("," substr($i, 6) ",", "," r ",")) n = $2 } END { print n }' .vid/tw/log 2>/dev/null)
  if [ -n "$n" ] && [ -f ".vid/tw/out/issue-$n.md" ]; then echo ".vid/tw/out/issue-$n.md"; else ls .vid/tw/out/issue-*.md 2>/dev/null; fi; }
tcount() { grep -h "^> $1 | " $(tfile "$1") /dev/null 2>/dev/null | head -n 1 | awk '{ t = 0; p = index($0, "transitions:"); if (p) { r = " " substr($0, p + 12); while ((q = index(r, " " (t + 1) ". ")) > 0) { r = substr(r, q + 1); t++ } } print t }'; }
has() { awk -F'\t' -v r="$1" '$1 == "row" && ($2 == r || $6 == r) { f = 1 } END { exit !f }' "$T/in.rows"; }
mark() { x=$(grep -h "^- ${1%-T[0-9]*} marks: " $(tfile "${1%-T[0-9]*}") /dev/null 2>/dev/null | head -n 1 | sed 's/^- [^ ]* marks: //' || true); printf '%s' "${x:--}"; }
cmd_check() { I=${1:-}; [ $# -gt 0 ] && shift; N=''; C=''; while [ $# -ge 2 ]; do case $1 in --ticket) N=$2 ;; --commit) C=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -n "$I" ] && [ -n "$N" ] || die 'usage — sh checks/results.sh check <id> --ticket <n> [--commit <asked>]'; ticket "$N"
  if form "$I" "$C"; then echo "ok $I"; else echo "refused $WHY"; exit 1; fi; }
cmd_page() { E=${1:-}; [ -f "$E" ] || die "no evidence file at '$E'"; M=$T/$(basename "${E%.txt}").md
  awk -F'\t' -v n="$(basename "$E" .txt)" 'BEGIN { print "# Results: " n "\n" } function c(s) { gsub(/\|/, "/", s); return s }
    NF == 6 { if (!h++) print "\n| Row | Kind | Red | T3 | Fault | Reason |\n|---|---|---|---|---|---|"; printf "| %s | %s | %s | %s | %s | %s |\n", c($1), c($2), c($3), c($4), c($5), c($6); next }
    { if (h && !t++) print ""; print "- " $0 }' "$E" > "$M"; sh "$HERE/page.sh" "$M" --out "${E%.txt}.html"; }
cmd_declare() { P=''; HD=''; while [ $# -ge 2 ]; do case $1 in --pr) P=$2 ;; --head) HD=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -n "$P" ] && [ -n "$HD" ] || die 'usage — sh checks/results.sh declare --pr <p> --head <commit>'
  HD=$(G rev-parse -q --verify "$HD^{commit}" 2>/dev/null || echo "$HD"); H=$(printf %s "$HD" | cut -c1-12); k=$(newest "pr-$P-$H"); [ -n "$k" ] || { echo "no head report at $H"; return 0; }; i=pr-$P-$H-$k; KIND=''
  form "$i" "$HD" || { echo "refused $WHY"; return 0; }; E=$(sl "$i" engines | head -n 1); M=$(sl "$i" environments | head -n 1)
  if [ -n "$E" ]; then mkdir -p .vid/tw; { grep -v '^engines ' .vid/tw/handed 2>/dev/null || true; printf 'engines %s | stand-in: results reader\n' "$E"; } > "$T/h" || exit 1; put .vid/tw/handed < "$T/h" || exit 1; fi
  case $M in ''|*[!0-9]*) ;; *) { grep -vE '^(stacks|unverified-rows)=' .vid/budget 2>/dev/null || true; printf 'stacks=%s\nunverified-rows=%s\n' "$M" "$((60 * M))"; } > "$T/b" || exit 1; put .vid/budget < "$T/b" || exit 1 ;; esac
  echo "declared engines=${E:--} environments=${M:--}"; }
# the close's reading of one chunk, from the stream: c <engine> <attempt> <name> <status> <first line>; u <row> <transitions>; h <engine> <row> <name>,
# a case of the row's newest accepted head report. Each row in each engine of the chunk: passed, failed, could not run, not run, or, in phase 2
# with no case at all, an x line for the engine line. Then the chunk's line and its rows
CL='function norm(s) { gsub(/[-_.]/, "-", s); return s }
  function hit(n, id,   o, p, a, b, s) { id = norm(id); o = 1
    while ((p = index(substr(n, o), id)) > 0) { a = o + p - 1; b = (a > 1) ? substr(n, a - 1, 1) : ""; s = substr(n, a + length(id), 1); if (b !~ /[A-Za-z0-9]/ && s !~ /[A-Za-z0-9]/) return 1; o = a + 1 } return 0 }
  function unit(u, e, a,   i, n, bad, su) { n = 0; bad = 0; su = 0
    for (i = 1; i <= nc[e, a]; i++) if (hit(cn[e, a, i], u)) { n++; if (cs[e, a, i] == "errored" && cf[e, a, i] ~ /^setup:/) su++; else if (cs[e, a, i] != "passed") { bad++; if (FN == "") FN = cr[e, a, i] } }
    return !n ? "none" : bad ? "failed" : su ? "setup" : "passed" }
  function full(r, e, a,   s, k, gone) { FN = ""; s = unit(r, e, a); gone = 0; for (k = 1; k <= nt[r]; k++) if (unit(r "-T" k, e, a) == "none") { gone = 1; if (FN == "") FN = r "-T" k " with no case" }
    if (s == "none") { if (FN == "") FN = r " with no case"; return (P2 && !nh[r, e]) ? "none" : P2 ? "not run" : "failed" } if (s == "failed" || gone) return "failed"
    for (k = 1; k <= nh[r, e]; k++) if (!((e, a, hn[r, e, k]) in have)) return "not run"
    return (s == "setup") ? "could not run" : "passed" }
  BEGIN { FS = "\t"; ne = split(CE, en, " "); P2 = (C !~ /^p1c/) }
  $1 == "c" { i = ++nc[$2, $3]; cn[$2, $3, i] = norm($4); cr[$2, $3, i] = $4; cs[$2, $3, i] = $5; cf[$2, $3, i] = $6; have[$2, $3, norm($4)] = 1; next }
  $1 == "u" { ro[++nr] = $2; nt[$2] = $3 + 0; next }
  $1 == "q" { RL[$2] = 1; next } $1 == "v" { CV[$2] = $3; next }
  $1 == "h" && hit(norm($4), $3) && !((e2 = $2 SUBSEP $3 SUBSEP norm($4)) in hs) { hs[e2] = 1; i = ++nh[$3, $2]; hn[$3, $2, i] = norm($4); next }
  END { for (i = 1; i <= nr; i++) { r = ro[i]; for (j = 1; j <= ne; j++) { e = en[j]; v = full(r, e, K)
        if (r in RL) { if (!(r in CV)) v = "not run"; else if (CV[r] + 0 == 0) { v = "failed"; FN = "covers 0" } }   # v0.26.10.26.2 (R4): CS reads a rule row by its covers: line, in every engine
        if (v == "none") { X[++nx] = "x\t" e "\t" r; continue }
        if (v == "could not run") for (a = K - 1; a >= 1; a--) if (nc[e, a] && full(r, e, a) == "passed") { v = "passed"; break }   # CK-T-109
        L[++nl] = "row\t" C "\t" e "\t" r "\t" v (v == "failed" ? "\t" FN : ""); if (v == "failed") red = 1; else if (v != "passed") inc = 1 } }
    print "chunk\t" C "\t" (red ? "red" : inc ? "incomplete" : "green") "\t" K; for (i = 1; i <= nl; i++) print L[i]; for (i = 1; i <= nx; i++) print X[i] }'
# acc <row> <engines>: h lines, the cases of the row's newest accepted head report whose head is an ancestor of the close's commit (CK-R-160)
acc() { awk -F'\t' -v r="$1" '($4 == r || index($4, r "-T") == 1) && $5 ~ /^(accepted|accepted by ruling|passing)$/ { print NR "\t" $2 "\t" $3 }' .vid/decide/log 2>/dev/null | sort -rn | while IFS=$TAB read -r _n p h; do
    G merge-base --is-ancestor "$h" "$C" 2>/dev/null || continue; q=$(newest "pr-$p-$h"); [ -n "$q" ] || continue; q=pr-$p-$h-$q
    for e in $2; do cases "refs/heads/vid-results/$q:$q/cases-$e.xml" | awk -F'\t' -v e="$e" -v r="$1" '$1 == "c" { print "h\t" e "\t" r "\t" $2 }'; done; break; done; }
# v0.26.10.26.1 (R2, R4): stdir <N>, the stage's newest candidate folder; ids, every id of INVENTORY.md, a line each
stdir() { c=''; for d in $(ls ".vid/decide/stage/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f ".vid/decide/stage/$1/$d/ask" ] && c=$d; done; echo ".vid/decide/stage/$1/${c:-0}"; }
invids() { sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md 2>/dev/null | awk -F'|' '{ a = $1; gsub(/[ \t]/, "", a); b = $2; gsub(/[ \t]/, "", b); if (a ~ /^ROW-[0-9]+$/) print a; else if (b ~ /^[A-Z]+-[0-9]+$/) print b }'; }
# unmatched <rev> <engine>: the rest chunk's cases whose name holds no id of the inventory, `unmatched <case> <status>`
unmatched() { invids > "$T/ids"; cases "$1" | awk -F'\t' -v I="$T/ids" 'BEGIN { while ((getline l < I) > 0) W[++n] = l }
    $1 == "c" { c = $2; gsub(/[-_.]/, "-", c); f = 0; for (i = 1; i <= n && !f; i++) { q = c; while ((p = index(q, W[i])) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; a = substr(q, p + length(W[i]), 1); if (b !~ /[A-Za-z0-9]/ && a !~ /[A-Za-z0-9]/) { f = 1; break } q = substr(q, p + 1) } }
      if (!f) print "unmatched\t" $2 "\t" $3 }'; }   # the format matching: separators one for one, the id whole
cmd_close() { S=''; ST=''; CS=''; CCA=''; while [ $# -ge 2 ]; do case $1 in --step) S=$2 ;; --stage) ST=$2 ;; --cs) ST=$2; CS=cs ;; --cr) ST=$2; CS=cr ;; --cp) ST=$2; CS=cp ;; --candidate) CCA=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -n "$S$ST" ] || die 'usage — sh checks/results.sh close --step <step> | --stage <N> | --cs <N>'; CD=.vid/decide/close/$S; [ -z "$ST" ] || { S=stage-$ST; CD=$(stdir "$ST"); [ -z "$CCA" ] || CD=.vid/decide/stage/$ST/$CCA; }; [ -z "$CS" ] || { case $CS in cs) S=staging-$ST ;; cr) S=rehearsal-$ST ;; cp) S=production-$ST ;; esac; CD=$CD/$CS; }   # v0.26.10.27.3: --candidate, CP read at its own candidate
  [ -f "$CD/ask" ] || for d in $(ls "$CD" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f ".vid/decide/close/$S/$d/ask" ] && CD=.vid/decide/close/$S/$d; done; [ -f "$CD/ask" ] || die "no close ask at $CD/ask"
  [ ! -f "$CD/withdrawn" ] || die "the newest close ask of $S is withdrawn ($(head -n 1 "$CD/withdrawn")): a report for it is not read"
  I=$(awk -F'\t' '$1 == "issue" { print $2; exit }' "$CD/ask"); C=$(awk -F'\t' '$1 == "commit" { print $2; exit }' "$CD/ask"); [ -n "$I" ] && [ -n "$C" ] || die "$CD/ask names no issue or no commit"
  KIND=''; : > "$T/co"; awk -F'\t' '$1 == "chunk"' "$CD/ask" > "$T/ch"
  while IFS=$TAB read -r _w CH CE RW <&3; do k=$(newest "req-$I-$CH")
    if [ "$CH" = p1cx ]; then   # the rest chunk (R4): no row; its cases matching no id of the inventory listed
      # v0.26.10.26.7 (R7, W-9): a report with no test case is green only with the line `none left` in its results.txt
      if [ -n "$k" ] && form "req-$I-$CH-$k" "$C"; then i=req-$I-$CH-$k; nc=0; for e in $CE; do nc=$((nc + $(cases "refs/heads/vid-results/$i:$i/cases-$e.xml" | grep -c '^c	' || true))); done
        [ "$nc" -gt 0 ] || G show "refs/heads/vid-results/$i:$i/results.txt" 2>/dev/null | grep -qx 'none left' || WHY='no test case, and results.txt has no line none left'; fi
      if [ -n "$k" ] && [ -z "$WHY" ] && form "req-$I-$CH-$k" "$C"; then printf 'chunk\tp1cx\tgreen\t%s\n' "$k" >> "$T/co"; for e in $CE; do unmatched "refs/heads/vid-results/req-$I-$CH-$k:req-$I-$CH-$k/cases-$e.xml"; done >> "$T/co"
      else [ -z "$k" ] || printf 'refused\t%s\t%s\n' "req-$I-$CH-$k" "$WHY" >> "$T/co"; printf 'chunk\tp1cx\tabsent\t%s\n' "${k:--}" >> "$T/co"; fi; continue; fi
    if [ -n "$k" ] && form "req-$I-$CH-$k" "$C"; then : > "$T/cc"; j=$k
      while [ "$j" -ge 1 ]; do i=req-$I-$CH-$j; if [ "$j" = "$k" ] || form "$i" "$C"; then for e in $CE; do cases "refs/heads/vid-results/$i:$i/cases-$e.xml" | awk -F'\t' -v e="$e" -v a="$j" '$1 == "c" { print "c\t" e "\t" a "\t" $2 "\t" $3 "\t" $4 }'; done >> "$T/cc"; fi; j=$((j - 1)); done
      for r in $RW; do printf 'u\t%s\t%s\n' "$r" "$(tcount "$r")"; acc "$r" "$CE"
        [ -n "$CS" ] && mark "$r" | grep -qE '(^|[ ;])rule($|[ ;])' && { printf 'q\t%s\n' "$r"; R=refs/heads/vid-results/req-$I-$CH-$k; sl "req-$I-$CH-$k" covers | awk -v r="$r" '$1 == r { print "v\t" $1 "\t" $2 }'; }; done >> "$T/cc"; awk -v C="$CH" -v CE="$CE" -v K="$k" "$CL" "$T/cc" >> "$T/co"
    else [ -z "$k" ] || printf 'refused\t%s\t%s\n' "req-$I-$CH-$k" "$WHY" >> "$T/co"; printf 'chunk\t%s\tabsent\t%s\n' "$CH" "${k:--}" >> "$T/co"
      for r in $RW; do for e in $CE; do printf 'row\t%s\t%s\t%s\tnot run\n' "$CH" "$e" "$r"; done; done >> "$T/co"; fi; done 3< "$T/ch"
  # R4 (v0.26.10.25.5): a row landed since the ask was asked has no evidence from it: its lines leave the read
  AT=$(sed -n "s/^asked$TAB//p" "$CD/ask" | head -n 1); if [ -s .vid/decide/landed ]; then awk -v a="$AT" 'FILENAME == ARGV[1] { if ($3 >= a) X[$1] = 1; next } $1 == "row" { b = $4; sub(/-T[0-9]+$/, "", b); if (($4 in X) || (b in X)) next } { print }' .vid/decide/landed FS='\t' "$T/co" > "$T/co2" && cat "$T/co2" > "$T/co"; fi
  { grep -v "^x$TAB" "$T/co" || true
    awk -F'\t' '$1 == "row" { k = $4; if (!(k in o)) { o[k] = 1; id[++n] = k } if ($5 == "passed") p[k] = p[k] " " $3; else if ($5 == "failed") f[k] = f[k] " " $3 } END { for (i = 1; i <= n; i++) { k = id[i]; if (p[k] != "" && f[k] != "") print "split\t" k "\t" substr(p[k], 2) "\t" substr(f[k], 2) } }' "$T/co"
    awk -F'\t' '$1 == "x" && !s[$2, $3]++ { if (!($2 in n)) o[++m] = $2; n[$2]++ } END { for (i = 1; i <= m; i++) print "engine\t" o[i] "\t" n[o[i]] "\tcould not run" }' "$T/co"; } > "$T/rd" || exit 1
  mkdir -p "$CD"; put "$CD/read" < "$T/rd" || exit 1; cat "$T/rd"; }
# grade --stage <N> (v0.26.10.26.1 R3): the newest S1 report of the stage's newest candidate, its form checked: `s1 read <k>`, then
# `grade <REQ> <word> <reason>` a line and `finding <line>`; or `s1 refused <k> <why>`, or `s1 absent -`. Written to the folder's s1read
# grade --ask <n> (v0.26.10.27.2 R1): an owner's grade ask's newest report, S1's form but its commit the ask's own, a finding's severity
# after its tag allowed, each line of a `vs` ask running on ` — vs: <word> — <reason>`, and a robustify ask's report its finding lines
# alone: `ask read <k>`, then `grade <REQ> <word> <reason> <vs word> <vs reason>` and `finding <line>`; or `ask refused <k> <why>`, or
# `ask absent -`. Written to .vid/decide/grade/<n>/read
cmd_gask() { CD=.vid/decide/grade/$1; [ -f "$CD/ask" ] || die "no grade ask at $CD/ask"; ak() { sed -n "s/^$1$TAB//p" "$CD/ask" | head -n 1; }
  I=$(ak issue); C=$(ak commit); RQ=$(ak reqs); VS=$(ak vs); k=$(newest "grade-$I")
  if [ -z "$k" ]; then printf 'ask\tabsent\t-\n' > "$T/g"
  elif ! form "grade-$I-$k" "$C"; then printf 'ask\trefused\t%s\t%s\n' "$k" "$WHY" > "$T/g"
  else G show "refs/heads/vid-results/grade-$I-$k:grade-$I-$k/grade.txt" | awk -v RQ=" $RQ " -v VS="$VS" -v k="$k" 'BEGIN { n = split(RQ, a, " "); for (i = 1; i <= n; i++) A[a[i]] = 1 }
      function no(w) { bad = bad (bad == "" ? "" : "; ") w }
      NR <= 2 && /^(by|commit):/ { next } /^[ \t]*$/ { next }
      /^finding: (bug|rule)( (high|medium|low))? — / { F[++nf] = $0; next }
      /^finding:/ { no("a finding not tagged bug or rule, or its severity not high, medium or low: " substr($0, 1, 60)); next }
      { r = $1; w = $2; why = $0; if (!sub(/^[^ ]+ [^ ]+ — /, "", why) || why ~ /^[ \t]*$/) { no(r " has no reason"); next }
        if (!(r in A)) { no(r " was not asked"); next } if (w !~ /^(pass|partial|facade|absent)$/) { no(r " has no word of the four: " w); next }
        if (r in G) { no(r " twice"); next } vw = ""; vy = ""
        if (VS != "") { p = index(why, " — vs: "); if (!p) { no(r " has no vs: word"); next } vy = substr(why, p + length(" — vs: ")); why = substr(why, 1, p - 1); if (why ~ /^[ \t]*$/) { no(r " has no reason"); next } vw = vy; sub(/ .*/, "", vw)
          if (vw !~ /^(pass|partial|facade|absent)$/) { no(r " has no vs: word of the four: " vw); next } if (!sub(/^[^ ]+ — /, "", vy) || vy ~ /^[ \t]*$/) { no(r " has no vs: reason"); next } }
        else if (index(why, " — vs: ")) { no(r " has a vs: word, and this ask has no vs commit"); next }
        G[r] = w; Y[r] = why; VW[r] = vw; VY[r] = vy; O[++no_] = r }
      END { for (r in A) if (!(r in G)) no(r " has no grade")
        if (bad != "") { printf "ask\trefused\t%s\t%s\n", k, bad; exit } printf "ask\tread\t%s\n", k; for (i = 1; i <= no_; i++) printf "grade\t%s\t%s\t%s\t%s\t%s\n", O[i], G[O[i]], Y[O[i]], VW[O[i]], VY[O[i]]; for (i = 1; i <= nf; i++) printf "finding\t%s\n", F[i] }' > "$T/g"; fi
  put "$CD/read" < "$T/g" || exit 1; cat "$T/g"; }
cmd_grade() { [ "${1:-}" = --ask ] && [ -n "${2:-}" ] && { cmd_gask "$2"; return; }; ST=''; while [ $# -ge 2 ]; do case $1 in --stage) ST=$2 ;; *) die "unknown $1" ;; esac; shift 2; done; [ -n "$ST" ] || die 'usage — sh checks/results.sh grade --stage <N> | --ask <n>'
  CD=$(stdir "$ST"); [ -f "$CD/s1ask" ] || die "no S1 ask at $CD/s1ask"; I=$(sed -n "s/^issue$TAB//p" "$CD/s1ask" | head -n 1); C=$(sed -n "s/^commit$TAB//p" "$CD/s1ask" | head -n 1)
  RQ=$(sed -n "s/^reqs$TAB//p" "$CD/s1ask" | head -n 1); k=$(newest "grade-$I")
  if [ -z "$k" ]; then printf 's1\tabsent\t-\n' > "$T/g"
  elif ! form "grade-$I-$k" "$C"; then printf 's1\trefused\t%s\t%s\n' "$k" "$WHY" > "$T/g"
  else G show "refs/heads/vid-results/grade-$I-$k:grade-$I-$k/grade.txt" | awk -v RQ=" $RQ " -v k="$k" 'BEGIN { n = split(RQ, a, " "); for (i = 1; i <= n; i++) A[a[i]] = 1 }
      NR <= 2 && /^(by|commit):/ { next } /^[ \t]*$/ { next }
      /^finding: (bug|rule)( (high|medium|low))? — / { F[++nf] = $0; next }   # v0.26.10.27.4: a severity after the tag, as RESULTS-FORMAT and 8.2 have it
      /^finding:/ { bad = bad (bad == "" ? "" : "; ") "a finding not tagged bug or rule, or its severity not high, medium or low: " substr($0, 1, 60); next }
      { r = $1; w = $2; why = $0; if (!sub(/^[^ ]+ [^ ]+ — /, "", why) || why ~ /^[ \t]*$/) { bad = bad (bad == "" ? "" : "; ") r " has no reason"; next }
        if (!(r in A)) { bad = bad (bad == "" ? "" : "; ") r " was not asked"; next } if (w !~ /^(pass|partial|facade|absent)$/) { bad = bad (bad == "" ? "" : "; ") r " has no word of the four: " w; next }
        if (r in G) { bad = bad (bad == "" ? "" : "; ") r " twice"; next } G[r] = w; Y[r] = why; O[++no] = r }
      END { for (r in A) if (!(r in G)) bad = bad (bad == "" ? "" : "; ") r " has no grade"
        if (bad != "") { printf "s1\trefused\t%s\t%s\n", k, bad; exit } printf "s1\tread\t%s\n", k; for (i = 1; i <= no; i++) printf "grade\t%s\t%s\t%s\n", O[i], G[O[i]], Y[O[i]]; for (i = 1; i <= nf; i++) printf "finding\t%s\n", F[i] }' > "$T/g"; fi
  put "$CD/s1read" < "$T/g" || exit 1; cat "$T/g"; }
# deploy --stage <N> (v0.26.10.26.2 R1, R6): the newest D1 report of the stage's newest candidate's okay, its form checked. Writes the okay's
# read: `d1 passed <k>` with `staging <address>`, `signin <role> <address>` and `differs <what> TAB <staging> TAB <production>` lines (none for
# `differs: none`); `d1 failed <k> <step> <yes|no>`; `d1 refused <k> <why>`; or `d1 absent -`
# v0.26.10.27.1 (R1, R4): --kind rh, the rehearsal, and d2, the production deploy, read from <c>/rh/ and <c>/d2/, the stage's newest
# closed candidate's folder (--candidate <c>); prodnow: production's commit, the newest line of .vid/decide/production (none: none yet)
prodnow() { [ -f .vid/decide/production ] || return 0; awk -F'\t' 'NF { c = $1 } END { print c }' .vid/decide/production; }
cmd_deploy() { ST=''; KD=d1; DCA=''; while [ $# -ge 2 ]; do case $1 in --stage) ST=$2 ;; --kind) KD=$2 ;; --candidate) DCA=$2 ;; *) die "unknown $1" ;; esac; shift 2; done; [ -n "$ST" ] || die 'usage — sh checks/results.sh deploy --stage <N> [--kind d1|rh|d2] [--candidate <c>]'
  case $KD in d1|rh|d2) ;; *) die "no kind $KD" ;; esac; CD=$(stdir "$ST"); [ -z "$DCA" ] || CD=.vid/decide/stage/$ST/$DCA; CD=$CD/$KD
  [ -f "$CD/ask" ] || die "no okay at $CD/ask"; I=$(sed -n "s/^issue$TAB//p" "$CD/ask" | head -n 1); C=$(sed -n "s/^commit$TAB//p" "$CD/ask" | head -n 1); k=$(newest "deploy-$I")
  [ ! -f "$CD/closed" ] || { printf '%s\tclosed\t-\n' "$KD" > "$T/g" || exit 1; put "$CD/read" < "$T/g" || exit 1; cat "$T/g"; return 0; }   # a closed okay's report is not read
  if [ -z "$k" ]; then printf '%s\tabsent\t-\n' "$KD" > "$T/g"
  elif ! form "deploy-$I-$k" "$C"; then printf '%s\trefused\t%s\t%s\n' "$KD" "$k" "$WHY" > "$T/g"
  elif [ "$KD" != d1 ]; then deploy2 "$KD" "deploy-$I-$k" "$k" > "$T/g"
  else i=deploy-$I-$k; o=$(G show "$R:$i/report.txt" | sed -n 's/^outcome: *//p' | head -n 1); pc=$(G show "$R:$i/report.txt" | sed -n 's/^product change: *//p' | head -n 1 | tr -d ' \r')
    case $o in
      passed) if ! G cat-file -e "$R:$i/staging.txt" 2>/dev/null; then printf 'd1\trefused\t%s\ta passed deploy has no staging.txt\n' "$k" > "$T/g"
        else G show "$R:$i/staging.txt" | awk -v k="$k" '/^staging: *[^ ]/ { a = $2 } /^signin: / { if (NF >= 3) S[++ns] = $2 "\t" $3; else bad = "a signin: line lacks its role or address" }
            /^differs: *none[ \t]*$/ { none = 1; next } /^differs: / { x = $0; sub(/^differs: */, "", x); n = split(x, p, / — /); if (n != 3) bad = "a differs: line is not <what> — <on staging> — <on production>: " x; else D[++nd] = p[1] "\t" p[2] "\t" p[3] }
            END { if (a == "") bad = "staging.txt has no staging: line"; else if (!none && !nd && bad == "") bad = "staging.txt has no differs: line, nor differs: none"
              if (bad != "") { printf "d1\trefused\t%s\t%s\n", k, bad; exit } printf "d1\tpassed\t%s\nstaging\t%s\n", k, a; for (i = 1; i <= ns; i++) print "signin\t" S[i]; for (i = 1; i <= nd; i++) print "differs\t" D[i] }' > "$T/g"; fi ;;
      failed\ ?*) case $pc in yes|no) printf 'd1\tfailed\t%s\t%s\t%s\n' "$k" "${o#failed }" "$pc" > "$T/g" ;; *) printf 'd1\trefused\t%s\ta failed deploy has no product change: yes or no line\n' "$k" > "$T/g" ;; esac ;;
      *) printf 'd1\trefused\t%s\treport.txt has no outcome: passed, nor outcome: failed <step>\n' "$k" > "$T/g" ;;
    esac; fi
  put "$CD/read" < "$T/g" || exit 1; cat "$T/g"; }
# deploy2 <rh|d2> <id> <k>: the rehearsal's or production deploy's report, its form alone
deploy2() { i=$2; k=$3; G show "$R:$i/report.txt" > "$T/rp"; o=$(sed -n 's/^outcome: *//p' "$T/rp" | head -n 1 | sed 's/[[:space:]]*$//'); pc=$(sed -n 's/^product change: *//p' "$T/rp" | head -n 1 | tr -d ' \r')
  steps=$(G show "$R:$i/deploy.xml" 2>/dev/null | awk 'BEGIN { RS = "<" } /^testcase[ \t\n]/ { n = $0; sub(/.*[ \t\n]name="/, "", n); sub(/".*/, "", n); print n }')
  P=$(prodnow); bad=''
  if [ "$1" = rh ]; then
    G show "$R:$i/change.txt" > "$T/ch" 2>/dev/null || bad='no change.txt'
    [ -n "$bad" ] || bad=$(awk '/^migrates: *(yes|no)[ \t]*$/ { m = 1 } /^drops: *[^ ]/ { d = 1 } /^services: *[^ ]/ { s = 1 } END { if (!m) print "change.txt has no migrates: yes or no line"; else if (!d) print "change.txt has no drops: line, nor drops: none"; else if (!s) print "change.txt has no services: line, nor services: none" }' "$T/ch")
    case $o in
      passed) [ -n "$bad" ] || grep -qx 'sealed: *yes' "$T/rp" || bad='a passed rehearsal is not sealed: yes'; [ -n "$bad" ] || grep -q '^copy: *[^ ]' "$T/rp" || bad='a passed rehearsal has no copy: line'
        for x in restore migrate boot; do [ -n "$bad" ] || printf '%s\n' "$steps" | grep -qx "$x" || bad="deploy.xml has no $x step"; done ;;
      'no backup yet') [ -z "$P" ] || [ "$P" = none ] || bad="no backup yet, though production runs $P" ;;
      failed\ ?*) case $pc in yes|no) ;; *) bad=${bad:-a failed rehearsal has no product change: yes or no line} ;; esac ;;
      *) bad=${bad:-report.txt has no outcome: passed, failed <step>, nor no backup yet} ;;
    esac
    [ -z "$bad" ] || { printf 'rh\trefused\t%s\t%s\n' "$k" "$bad"; return 0; }
    case $o in passed) printf 'rh\tpassed\t%s\n' "$k"; sed -n 's/^copy: *\([^ ]*\).*/copy\t\1/p' "$T/rp"; awk '/^signin: / && NF >= 3 { print "signin\t" $2 "\t" $3 }' "$T/rp" ;;
      'no backup yet') printf 'rh\tno-backup\t%s\n' "$k" ;; *) printf 'rh\tfailed\t%s\t%s\t%s\n' "$k" "${o#failed }" "$pc" ;; esac
    awk '/^migrates: / { print "migrates\t" $2 } /^(drops|rewrites|services): / { w = $1; sub(/:$/, "", w); x = $0; sub(/^[a-z]+: */, "", x); if (x != "none") print w "\t" x }' "$T/ch"; return 0; fi
  # d2: backup the first step; production: on a passed one; logs: on the first D2 ever
  [ "$(printf '%s\n' "$steps" | head -n 1)" = backup ] || bad="deploy.xml's first step is not backup"
  case $o in
    passed) [ -n "$bad" ] || grep -q '^production: *[^ ]' "$T/rp" || bad='a passed production deploy has no production: line'
      if [ -z "$bad" ] && { [ -z "$P" ] || [ "$P" = none ]; }; then grep -q '^logs: *[^ ]' "$T/rp" || bad='the first production deploy has no logs: line'; fi ;;
    failed\ ?*) ;;
    *) bad=${bad:-report.txt has no outcome: passed, nor failed <step>} ;;
  esac
  [ -z "$bad" ] || { printf 'd2\trefused\t%s\t%s\n' "$k" "$bad"; return 0; }
  case $o in passed) printf 'd2\tpassed\t%s\n' "$k"; sed -n 's/^production: *\([^ ]*\).*/production\t\1/p' "$T/rp"; sed -n 's/^logs: *\(.*\)/logs\t\1/p' "$T/rp" ;;
    *) printf 'd2\tfailed\t%s\t%s\t%s\n' "$k" "${o#failed }" "${pc:--}"; sed -n 's/^production: *\([^ ]*\).*/production\t\1/p' "$T/rp" ;; esac; }
CMD=${1:-}; [ $# -gt 0 ] && shift
case $CMD in
  grade) cmd_grade "$@" ;; deploy) cmd_deploy "$@" ;;
  check) cmd_check "$@" ;; read) cmd_read "$@" ;; page) cmd_page "$@" ;; declare) cmd_declare "$@" ;; close) cmd_close "$@" ;;
  *) die 'usage — sh checks/results.sh check|read|page|declare|close …' ;;
esac

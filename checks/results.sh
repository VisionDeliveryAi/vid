#!/bin/sh
# Purpose: ViD's results reader (v0.26.10.24.5). It reads each results folder DevAgent sends for a ticket's asks (T2, the head
# report, the head grade, the sort report), checks its form alone, and says what each row's evidence shows. It decides nothing: a row's standing
# is the decider's. It reads only .vid/code (a local copy of the code repository, kept current by `github.sh results-fetch`),
# the published tickets (.vid/tw/out/issue-<n>.md), its own folder and (FB-3 A1, GitHub manual) the call's read, the log and ViD's own reviews' records, calls no network and runs nothing of the code repository.
#   check <id> --ticket <n> [--commit <asked>]   the form of one report: `ok <id>`; or `refused <why>`, exit 1
#   read --ticket <n> --pr <p> --head <commit>   writes .vid/results/pr-<p>-<head12>.txt and prints it, exit 0 however broken a
#       report is. Report lines, then one tab-separated line per row or transition: row, kind, red, t3, fault, reason; then
#       the grades' findings, an `open grade line:` for each row whose newest grade line is breached or unclear, a `finding: note` line for each note it of the sort, a `finding: real` line for each prove it real (0.26.11.1.3, R3), a fault folder for no row, and the head report's engines, environments and
#       retested. Every head report of the pull request also feeds .vid/results/stand-in.txt: <head12> TAB <the line>, each once
#   read --ticket <n> --at <commit>              GM-4 E1 (GitHub manual: a ticket decided at a commit of main) the same shape, into
#       .vid/results/step-<n>-<commit12>.txt, its first line `ticket <n>, at <commit>`. FB-3 A1.1, A1.2: from the team's own results, whatever
#       their id and whoever made them: every result report (an id beginning none of red-, req-, grade-, sort-, deploy-, stopped-) whose
#       commit is that one or holds its very files (the tree id, read from the commit object), by the form alone (mform), one pool (pool).
#       No engine, red, break or covers: line is asked; each is read when given, a red from red-<n or a sub-issue of it>-. Beside the rows:
#       `fin TAB <row> TAB <the reports a case of it failed in>`, `near TAB <row> TAB <commit12>` (a row with no case there, and where one
#       passed). FB-3 A1.4: the grade and the sort are ViD's own review's, by its record in .vid/decide/review/, and a `request: <row> —
#       <words>` line for each test it line of the sort. GM-4 E3: a test the newest `amended <n>` log line names in added= or restated= is
#       read only from reports made (their branch's commit) after that line, each report by itself; every other test from its
#       publication, a landed one included. A test the ticket lists marked retired (GM-3 U4) is no row of the read
#   at <n> [<commit>]                            FB-3 A1.3 (GitHub manual): the result reports at that commit whose form is right; with none named,
#       the newest commit of main's first-parent line at which one holds a case of one of the ticket's rows
#   page <evidence>                              a page of that file: <evidence less .txt>.html, by page.sh
#   declare --pr <p> --head <commit>             that head report's engines and environments, into .vid/tw/handed and .vid/budget
#   declare --ticket <n> --at <commit>           GM-4 E4: the same from the reports at a ticket's commit, when given (the skeleton's acceptance; FB-3 A1.3)
#   declare --engines "<primary> <other>…" --words "<w>"   GM-4 F16: the engines the owner names, their words kept, the one writer of
#       .vid/tw/handed's engines line: `engines <them> | stand-in: owner at <now>, words "<w>"`; refused without words or names
#       (0.26.10.29.2 R10: the budget's stacks= and unverified-rows= only when the count differs from stacks=, so a raise stands)
#   close --step <s>                             the step close (v0.26.10.25.3 R9): each chunk of the step's newest ask, .vid/decide/close/<s>/<k>/ask
#       (v0.26.10.25.4 R3), by its newest report req-<issue>-<chunk>-<k>; prints, and writes to the ask's read, tab-separated: chunk <name>
#       green|red|incomplete|absent <k or ->; row <chunk> <engine> <row> passed|failed <its first failing case>|could not run|not run; split <row>
#       <passed in> <failed in>; engine <e> <n> could not run; refused <id> <why>. Exit 0 however broken a report is
#   close --cs <N> (v0.26.10.26.2)              CS, the staging run, as C3, from <c>/cs/ask; a rule row reads by its covers: line
#   deploy --stage <N> (v0.26.10.26.2)          the okay's newest D1 report, deploy-<issue>-<k>, on its form alone, into <c>/d1/read
#                                                0.26.10.29.5 (DP-1 R2): each kind refused with no decision: line, nor decisions: none
#                                                0.26.11.1.1 (R1, R3 to R6): a passed D1 refused without duties.txt, a staging duty missing or
#                                                not done (but a known one), a seam: line for a row of the okay's, or the okay's seed:; its
#                                                read gains seed, stays, seam and duty lines; a passed RH refused without a kept: line or the
#                                                kept step, its kept lines read; a passed D2's duty lines read, never refused for them
#                                                0.26.11.1.3 (R3): a passed D1 refused without a real: line for each real check its okay
#                                                lists, or with one not done the owner has not ruled; its read gains the real lines
#   grade --ask <n> (v0.26.10.27.2)             an owner's grade ask's newest report, grade-<issue>-<k>, its commit the ask's own, into
#                                                .vid/decide/grade/<n>/read; a `vs` ask's second word checked
# FB-3 A1.4: cases <rev>:<path>                 one results file's cases, as the reader reads them: c, name, status, first line, forbidden effects;
#   tab-separated, then whole 1 or 0 (checks/review.sh's brief)
# v0.26.10.25.3 R11–R13: a head report's every cases file is read; once .vid/tw/handed has an engine-split line every declared engine is asked;
#   a fault folder at the head is read as a row, whether the ticket lists it or not
# v0.26.10.25.5 R4: an id landed after a ticket was published (.vid/decide/landed) has no evidence from that ticket's reports, retested
#   lines or fault folders; a row's transitions and marks come from the newest ticket holding it, by .vid/tw/log
# FB-3 A2: skipped [--ticket <n>]               the report branches github.sh results-fetch left out, with the owner's words for each (a flag's); a
#   ticket's, a `report left out — vid-results/<id>: <why>` line each. `read` says each of the ticket's, `report skipped <id> <why>`
# FB-6 A2.2: missing --ticket <n> --at <commit>  (GitHub manual) in one line what an ask at a commit with no result lacks, posted by round.sh accept
# FB-5 B1.8: lacks --ticket <n> --at <commit>   (GitHub manual) what the team's older form lacked in the evidence last read there, a lack a line
# FB-3 A3: team [--hand]                       the text telling the team what its reports hold, in the project's mode, for the owner to hand over;
#   --hand writes it to .vid/plan/TEAM-REPORTS.md too (FB-5 B1.7: not while the team's own rules are on record). No lock, no GitHub
# Usage: sh checks/results.sh check|read|page|declare|close|skipped|lacks|at|team …
# serves: tickets (0.26.10.28.4, M9)
set -eu
LC_ALL=C; export LC_ALL   # a report's bytes are bytes: one that is no character stops nothing
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
die() { echo "ViD results: $*" >&2; exit 2; }
G() { git --git-dir=.vid/code -c log.showSignature=false "$@"; }   # no signature's lines before a log's, whatever the owner's git shows
mkdir -p .vid/results; T=$(mktemp -d "$PWD/.vid/results/tmp.XXXXXX"); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t'); MAN=''; ! manual || MAN=1   # FB-3 A1: GitHub manual, its own form and reading
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
    s == "Rows" && /^- [A-Z]+-[0-9]+ could not run there: / { split($0, w, " "); print "unrun\t" w[2]; next }   # PB-5: a staging run row that could not run there
    s == "Regression rows" && /^- [A-Z]+-[0-9]/ { split($0, w, " "); print "reg\t" w[2]; next }
    s == "Faulted rows" && /^- [A-Z]+-[0-9]/ { split($0, w, " "); sub(/:$/, "", w[2]); print "flt\t" w[2]; next }
    END { for (i = 1; i <= n; i++) if (M[o[i]] !~ /^retired;/) printf "row\t%s\t%s\t%s\t%d\n", o[i], K[o[i]], (M[o[i]] == "" ? "-" : M[o[i]]), N[o[i]]; for (r in M) if (M[r] ~ /^retired;/) print "rtd\t" r }' "$F" > "$T/tk"
  # GM-3 U4, GM-4 E2: RTD, the tests the ticket lists retired (their marks, and its newest log line's retired=): no row of the read, and
  # no evidence beside the ticket's own (a regression or faulted line, retested:, a fault folder) brings one back
  { sed -n "s/^rtd$TAB//p" "$T/tk"; awk -v n="$1" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { k = split(l, w, " "); for (i = 3; i <= k; i++) if (w[i] ~ /^retired=/) { m = split(substr(w[i], 9), q, ","); for (j = 1; j <= m; j++) if (q[j] != "" && q[j] != "-") print q[j] } }' .vid/tw/log 2>/dev/null; } | sort -u > "$T/rtd"
  RTD=" $(tr '\n' ' ' < "$T/rtd")"; awk -F'\t' -v R="$RTD" '!(($1 == "reg" || $1 == "flt") && index(R, " " $2 " "))' "$T/tk" > "$T/tk2" && mv "$T/tk2" "$T/tk"
  KIND=$(sed -n "s/^kind$TAB//p" "$T/tk" | head -n 1); ENGS=$(sed -n "s/^eng$TAB//p" "$T/tk" | tr '\n' ' ')
  if [ -n "$ENGS" ] && grep -q '^engine-split ' .vid/tw/handed 2>/dev/null; then for e in $(sed -n 's/^engines \([^|]*\)|.*/\1/p' .vid/tw/handed | tail -n 1); do case " $ENGS " in *" $e "*) ;; *) ENGS="$ENGS$e " ;; esac; done; fi; }   # R11: every declared engine, once a row has split
# form <id> <asked commit, or empty>: WHY says why the report may not be read, with exit 1. With KIND empty it leaves the cases files alone
# FB-3 A1.1, A1.5 (GitHub manual): a result report (any id but a red, run, grade, sort, deploy or stopped one's), a red, a close chunk's and a
# deploy report are by anyone (mform); a grade and a sort are ViD's own review (github.sh own-refs), by GR and SR as before
form() { R=refs/heads/vid-results/$1; WHY=''; if [ -n "$MAN" ]; then case $1 in grade-*|sort-*) ;; *) mform "$1" "$2"; return ;; esac; fi
  case $1 in red-*) FN=results.txt; BY=TM ;; pr-*|step-*|req-*) FN=results.txt; BY=TM ;; grade-pr-*|grade-step-*) FN=grade.txt; BY=GR ;; grade-[0-9]*) FN=grade.txt; BY=GR ;; sort-pr-*|sort-step-*) FN=sorted.txt; BY=SR ;; deploy-[0-9]*) FN=report.txt; BY=DP ;; *) WHY="not a T2, head report, head grade, sort report, run report or deploy report: $1"; return 1 ;; esac
  G rev-parse -q --verify "$R" > /dev/null 2>&1 || { WHY="no branch vid-results/$1"; return 1; }
  x=$(G ls-tree -r --name-only "$R" | grep -v "^$1/" | head -n 1 || true); [ -z "$x" ] || { WHY="the branch holds more than its folder: $x"; return 1; }
  G cat-file -e "$R:$1/$FN" 2>/dev/null || { WHY="no $FN"; return 1; }
  x=$(G show "$R:$1/$FN" | head -n 1); [ "$x" = "by: $BY" ] || { WHY="the first line of $FN is not by: $BY: $x"; return 1; }
  c=$(G show "$R:$1/$FN" | sed -n 's/^commit: *//p' | head -n 1); [ -n "$c" ] || { WHY="$FN names no commit"; return 1; }
  G cat-file -e "$c^{commit}" 2>/dev/null || { WHY="the code repository lacks the commit $c"; return 1; }
  case $1 in red-*) ;; req-*|grade-[0-9]*|deploy-[0-9]*) [ -n "$2" ] && [ "$c" = "$2" ] || { WHY="the commit $c is not the one asked for, ${2:-none}"; return 1; } ;; *) h=${1%-*}; h=${h##*-}
    if [ -n "$2" ]; then [ "$c" = "$2" ] || { WHY="the commit $c is not the one asked for, $2"; return 1; }
    else case $c in "$h"*) ;; *) WHY="the commit $c is not this report's head, $h"; return 1 ;; esac; fi ;; esac
  case $1 in sort-pr-*|sort-step-*) x=$(G show "$R:$1/$FN" | awk 'NR > 2 && !/^[^ ]+ (test it|note it|drop it|prove it real) — / { print; exit }'); [ -z "$x" ] || { WHY="a line of sorted.txt holds none of the four words: $x"; return 1; } ;; esac   # 0.26.11.1.3 (R3): prove it real
  case $1 in pr-*|step-*) x=$(G show "$R:$1/$FN" | sed -n 's/^retested: *//p' | tr ' ' '\n' | grep -v '^$' | grep -Ev '^[A-Z]+-[0-9][A-Za-z0-9-]*$' | head -n 1 || true); [ -z "$x" ] || { WHY="a retested: line holds more than row ids: $x"; return 1; } ;; esac   # read carries it, for the decider
  case $1 in req-*) for e in $CE; do iswhole "$R:$1/cases-$e.xml" || { WHY="no whole cases file for $e"; return 1; }; done; return 0 ;; esac   # a close chunk's report: every engine of its chunk
  [ "$FN" = results.txt ] && [ -n "$KIND" ] || return 0
  E=$ENGS; case $1 in red-*) E=${ENGS%% *} ;; *) [ "$KIND" != skeleton ] || { E=$(G show "$R:$1/$FN" | sed -n 's/^engines: *//p' | head -n 1); [ -n "$E" ] || { WHY='a skeleton head report declares no engines'; return 1; }; } ;; esac
  for e in $E; do iswhole "$R:$1/cases-$e.xml" || { WHY="no whole cases file for $e"; return 1; }; done
  case $1 in pr-*|step-*) for r in $(G ls-tree -r --name-only "$R" | sed -n "s|^$1/faults/\([^/]*\)/.*|\1|p" | sort -u); do G cat-file -e "$R:$1/faults/$r/inconclusive.txt" 2>/dev/null || iswhole "$R:$1/faults/$r/cases-${E%% *}.xml" || { WHY="no whole cases file for ${E%% *} in faults/$r"; return 1; }; done ;; esac; }
# mform <id> <asked commit, or empty> (GitHub manual): the first line of results.txt (a deploy report's report.txt) `by: <anyone>`, a commit: the
# code repository holds (the asked one's, or one with its very files; a close chunk's and a deploy's the asked one itself), and but for a
# deploy at least one whole results file with a test case (load); the rest chunk p1cx alone may hold none (RESULTS-FORMAT). Nothing else refuses
mform() { FN=results.txt; case $1 in stopped-*) WHY="not a results, red, run or deploy report: $1"; return 1 ;; deploy-[0-9]*) FN=report.txt ;; esac
  G rev-parse -q --verify "$R" > /dev/null 2>&1 || { WHY="no branch vid-results/$1"; return 1; }
  _x=$(G ls-tree --name-only "$R" | grep -vxF -e "$1" | head -n 1 || true); [ -z "$_x" ] || { WHY="the branch holds more than its folder: $_x"; return 1; }
  G cat-file -e "$R:$1/$FN" 2>/dev/null || { WHY="no $FN"; return 1; }; G show "$R:$1/$FN" | tr -d '\r' > "$T/mf"
  _x=$(head -n 1 "$T/mf"); case $_x in 'by: '*[!\ ]*) ;; *) WHY="the first line of $FN is not by: <who made it>: $_x"; return 1 ;; esac
  _c=$(sed -n 's/^commit: *//p' "$T/mf" | head -n 1 | sed 's/ *$//'); [ -n "$_c" ] || { WHY="$FN names no commit"; return 1; }
  _x=$(G rev-parse -q --verify "$_c^{commit}" 2>/dev/null) || { WHY="no branch of the code repository holds the commit $_c"; return 1; }; _c=$_x
  case $1 in red-*) ;; *) [ -z "$2" ] || [ "$_c" = "$2" ] || { case $1 in req-*|deploy-*) false ;; *) [ "$(tid "$_c")" = "$(tid "$2")" ] ;; esac; } || { WHY="the commit $_c is not the one asked for, $2"; return 1; } ;; esac
  case $1 in req-*|deploy-*) [ -n "$2" ] || { WHY="the commit $_c is not the one asked for, none"; return 1; } ;; esac
  [ "$FN" = results.txt ] || return 0; load "$1"; case $1 in req-*-p1cx-*) _m=0 ;; *) _m=1 ;; esac
  awk -F'\t' -v m="$_m" '$2 == 1 && $3 >= m { f = 1 } END { exit !f }' "$T/cx/$1/names" || { WHY='no whole results file with a test case (an .xml at the top of its folder)'; return 1; }; }
# tid <commit>: its tree's id, read from the commit object alone (.vid/code holds no tree of the code). load <id>: every .xml at the top of its
# folder read once, $T/cx/<id>/<k> its cases and a line of names: `<k> TAB <1 when whole> TAB <its cases> TAB <its name>`
tid() { G log -1 --format=%T "$1" 2>/dev/null; }
load() { [ ! -f "$T/cx/$1/names" ] || return 0; mkdir -p "$T/cx/$1"; : > "$T/cx/$1/names"; _k=0
  G -c core.quotePath=off ls-tree "refs/heads/vid-results/$1:$1" 2>/dev/null | awk -F'\t' '$1 ~ /^100/ && tolower($2) ~ /[.]xml$/ { print $2 }' > "$T/cx/$1/ls"
  while IFS= read -r _lf <&5; do _k=$((_k + 1)); cases "refs/heads/vid-results/$1:$1/$_lf" > "$T/cx/$1/$_k"; printf '%s\t%s\t%s\t%s\n' "$_k" "$(grep -c "^whole${TAB}1\$" "$T/cx/$1/$_k" || true)" "$(grep -c "^c$TAB" "$T/cx/$1/$_k" || true)" "$_lf" >> "$T/cx/$1/names"; done 5< "$T/cx/$1/ls"; }
# pushf <id> <head> [f]: its files' cases into the stream, each headed by <head>, with f by <head> and `<id>:<file>`; of a file that is not whole
# the failed and errored cases alone, so it can fail a row and never pass one
pushf() { while IFS=$TAB read -r _k _w _n _f <&5; do [ "$_n" -gt 0 ] || continue; _h=$2; [ -z "${3:-}" ] || _h="$2$TAB$1:$_f"
    awk -F'\t' -v h="$_h" -v w="$_w" '$1 == "c" && (w == 1 || $3 == "failed" || $3 == "errored") { print h "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' "$T/cx/$1/$_k"; done 5< "$T/cx/$1/names" >> "$T/in"; }
# tallyf <id>: ` <file> <its tally>;` for each of its files with a case
tallyf() { while IFS=$TAB read -r _k _w _n _f <&5; do [ "$_n" -gt 0 ] || continue; printf ' %s %s%s;' "$_f" "$(awk -F'\t' '$1 == "c" { t[$3]++ } END { printf "%d passed, %d failed, %d errored, %d skipped", t["passed"], t["failed"], t["errored"], t["skipped"] }' "$T/cx/$1/$_k")" "$([ "$_w" = 1 ] || echo ', not whole')"; done 5< "$T/cx/$1/names"; }
# rlist (GitHub manual), once a call: $T/rl, every result report's `<id> TAB <its full commit> TAB <that commit's tree id>`, the two empty when
# its results.txt names no commit the code repository holds. attempts, a filter of such lines with `@` first on the ones wanted: of each
# attempt (an id that ends -<the first 7 or more characters of its own commit>-<k>, each report by its own; one of that base that names
# no commit with them) the newest alone, any other id itself. atids <full
# commit>: the reports at it: their commit is it, or holds its very files; each refused one among them too
rlist() { [ ! -f "$T/rl" ] || return 0; G for-each-ref --format='%(refname:lstrip=3)' refs/heads/vid-results/ 2>/dev/null | grep -vE '^(red|req|grade|sort|deploy|stopped)-' > "$T/ri" || true
  sed 's|^|refs/heads/vid-results/|' "$T/ri" | tr '\n' '\0' | xargs -0 -n 200 sh -c '[ $# -eq 0 ] || git --git-dir=.vid/code grep -I -E --no-color --no-line-number --no-column --no-heading --no-break --no-recurse-submodules "^commit:" "$@" -- "*/results.txt" || :' x 2>/dev/null | awk '{ p = index($0, ":"); r = substr($0, 1, p - 1); sub(/^refs\/heads\/vid-results\//, "", r); x = substr($0, p + 1); if (index(x, r "/results.txt:") != 1 || (r in s)) next; s[r] = 1
    x = substr(x, length(r) + 14); sub(/^commit: */, "", x); sub(/[ \t\r]*$/, "", x); if (x ~ /^[0-9a-f]+$/) print x "^{commit} " r }' > "$T/rc"
  G cat-file --batch-check='%(objectname) %(objecttype) %(rest)' < "$T/rc" 2>/dev/null | awk '$2 == "commit" && NF == 3 { print $3 "\t" $1 }' > "$T/rf"
  : > "$T/rt"; [ ! -s "$T/rf" ] || cut -f2 "$T/rf" | sort -u | G log --no-walk --stdin --format='%H%x09%T' > "$T/rt" 2>/dev/null || true
  awk -F'\t' -v F="$T/rf" -v TR="$T/rt" 'BEGIN { while ((getline l < TR) > 0) { split(l, x, "\t"); t[x[1]] = x[2] } while ((getline l < F) > 0) { split(l, x, "\t"); c[x[1]] = x[2] } } { print $1 "\t" c[$1] "\t" t[c[$1]] }' "$T/ri" > "$T/rl.n"; mv "$T/rl.n" "$T/rl"; }
attempts() { awk -F'\t' '{ id = $2; k = id; sub(/.*-/, "", k); b = id; sub(/-[^-]*$/, "", b); h = b; sub(/.*-/, "", h); n++; I[n] = id; W[n] = ($1 == "@"); B[n] = ""; if (k !~ /^[0-9]+$/) next; N[n] = k + 0
    if (length(h) >= 7 && $3 != "" && index($3, h) == 1) { B[n] = b; A[b] = 1 } else if ($3 == "") U[n] = b }
  END { for (i = 1; i <= n; i++) { if ((i in U) && (U[i] in A)) B[i] = U[i]; if (B[i] == "") continue; if (!(B[i] in M) || N[i] > M[B[i]]) M[B[i]] = N[i]; if (W[i]) G[B[i]] = 1 }
    for (i = 1; i <= n; i++) if (B[i] == "") { if (W[i]) print I[i] } else if ((B[i] in G) && N[i] == M[B[i]]) print I[i] }'; }
atids() { rlist; awk -F'\t' -v c="$1" -v t="$(tid "$1")" '{ print (($2 != "" && ($2 == c || (t != "" && $3 == t))) ? "@" : "-") "\t" $1 "\t" $2 }' "$T/rl" | attempts; }
# hits <id>: a case of the report names one of the rows of $T/hr (a line each); kept in $T/hit.<id>. HT, the matching, as the evidence's
hits() { [ -f "$T/hit.$1" ] || { load "$1"; cat "$T/cx/$1/"[0-9]* 2>/dev/null | awk -F'\t' -v H="$T/hr" "$HT"' BEGIN { while ((getline l < H) > 0) r[++n] = l } $1 == "c" && !f { x = norm($2); for (i = 1; i <= n && !f; i++) if (hit(x, r[i])) f = 1 } END { print f + 0 }' > "$T/hit.$1"; }; [ "$(cat "$T/hit.$1")" = 1 ]; }
HT=$(hitf)
# at <ticket> [<commit>] (GitHub manual): the result reports at that commit whose form is right, an id a line; with no commit, the newest
# commit of main's first-parent line at which one holds a case of one of the ticket's rows
cmd_at() { [ -n "$MAN" ] && [ -n "${1:-}" ] || die 'usage — sh checks/results.sh at <ticket> [<commit>] (GitHub manual)'; KIND=''; ticket "$1"; cut -f1,2 "$T/tk" | sed -n "s/^row$TAB//p" > "$T/hr"
  if [ -n "${2:-}" ]; then for i in $(atids "$2"); do ! form "$i" "$2" || echo "$i"; done; return 0; fi
  rlist; G log --first-parent --format='%H%x09%T' refs/heads/main 2>/dev/null | awk -F'\t' -v L="$T/rl" 'BEGIN { while ((getline l < L) > 0) { split(l, x, "\t"); if (x[2] != "") { c[x[2]] = 1; t[x[3]] = 1 } } } ($1 in c) || ($2 in t) { print $1 }' > "$T/fpc"
  while read -r x <&6; do for i in $(atids "$x"); do if form "$i" "$x" && hits "$i"; then echo "$x"; return 0; fi; done; done 6< "$T/fpc"; }
sl() { G show "$R:$1/results.txt" | sed -n "s/^$2: *//p"; }
# FB-3 A2: skips, the report branches left out (github.sh results-fetch, .vid/round/reports-skipped), each `<id> TAB <its number or -> TAB
# <commit> TAB <author> TAB <date> TAB <why>`; an id's number is its first part between hyphens that is digits alone, a stopped- id's none.
# units <n>: a ticket's numbers, a line each: its own, its sub-issues' at every depth, its pull requests' (GitHub manual).
# left <n> [<p>] [<commit>]: those of the skips that are the ticket's: any id of one of its numbers in GitHub manual; with a pull request (GitHub
# auto) `red-<n>-`, `pr-<p>-`, `grade-pr-<p>-` and `sort-pr-<p>-` alone. FB-3 A1.1 (GitHub manual): each result report whose form is refused too, at
# the commit, or under one of the ticket's numbers with no commit to place it by (with no commit named, each under one of its numbers)
skips() { [ -s .vid/round/reports-skipped ] || return 0; awk -F'\t' '{ n = "-"; if ($1 !~ /^stopped-/) { k = split($1, p, "-"); for (i = 1; i <= k; i++) if (p[i] ~ /^[0-9]+$/) { n = p[i]; break } } print $1 "\t" n "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' .vid/round/reports-skipped; }
subs() { echo "$1"; [ ! -f .vid/round/read ] || awk -F'\t' -v n="$1" '$1 == "sub" && $2 == n { print $4 }' .vid/round/read; }   # its own number and its sub-issues'
units() { [ -f .vid/round/read ] || { echo "$1"; return 0; }; { sh "$HERE/decide.sh" umap 2>/dev/null | awk -F'\t' -v n="$1" '$2 == n { print "u\t" $1 }'; cat .vid/round/read; } | awk -F'\t' -v n="$1" 'BEGIN { M[n] = 1 } $1 == "u" { M[$2] = 1; next } $1 == "sub" && $2 == n { M[$4] = 1 } ($1 == "open" || $1 == "merged") { P[$2] = $3 } END { for (p in P) if (P[p] in M) M[p] = 1; for (x in M) print x }' | sort -n; }
left() { skips > "$T/sk"; [ -s "$T/sk" ] || [ -n "$MAN" ] || return 0; if [ -n "${2:-}" ]; then awk -F'\t' -v n="$1" -v p="$2" '$1 ~ ("^(red-" n "|(grade-|sort-)?pr-" p ")-") { print $1 "\t" $6 }' "$T/sk"
  else units "$1" > "$T/un"; awk -F'\t' 'FILENAME == ARGV[1] { U[$1] = 1; next } $2 in U { print $1 "\t" $6 }' "$T/un" "$T/sk"
    rlist; { [ -z "${3:-}" ] || atids "$3"; awk -F'\t' -v c="${3:-}" 'FILENAME == ARGV[1] { U[$1] = 1; next } c != "" && $2 != "" { next } { k = split($1, p, "-"); for (i = 1; i <= k; i++) if (p[i] ~ /^[0-9]+$/) { if (p[i] in U) print $1; break } }' "$T/un" "$T/rl"; } | sort -u > "$T/lf"
    while read -r i <&6; do form "$i" "${3:-}" || printf '%s\t%s\n' "$i" "$WHY"; done 6< "$T/lf"; fi; }
# skipped: each left-out branch, `<id> TAB <the flag's words>`; skipped --ticket <n> [--at <commit>]: the ticket's, a `report left out — …` line each
cmd_skipped() { if [ "${1:-}" = --ticket ] && [ -n "${2:-}" ]; then left "$2" '' "${4:-}" | while IFS=$TAB read -r i y; do echo "report left out — vid-results/$i: $y"; done; return 0; fi; [ $# -eq 0 ] || die 'usage — sh checks/results.sh skipped [--ticket <n>]'
  skips | while IFS=$TAB read -r i n c a d y; do [ "$n" = - ] && o='' || o=" reports on #$n"; printf "%s\tthe branch vid-results/%s (its newest commit %s by %s, %s)%s: %s. Put the report's files in a folder named %s on that branch and push it again; whatever else the branch holds is not read.\n" "$i" "$i" "$(printf %s "$c" | cut -c1-12)" "$a" "$d" "$o" "$y" "$i"; done; }
# FB-6 A2.2: missing --ticket <n> --at <commit> (GitHub manual), in one line what no result at a commit of main lacks, and the pull request merged as it whose
# last commit holds the same files (the tree id, read from the commit object)
cmd_missing() { [ -n "$MAN" ] && [ "${1:-}" = --ticket ] && [ -n "${2:-}" ] && [ "${3:-}" = --at ] && [ -n "${4:-}" ] || die 'usage — sh checks/results.sh missing --ticket <n> --at <commit> (GitHub manual)'
  printf 'no result report that can be read is at %s, or at a commit with its very files' "$(printf %.12s "$4")"; _t=$(tid "$4" || true)
  [ -z "$_t" ] || awk -F'\t' -v c="$4" '$4 == c && $3 != c { print $1 " " $3 }' .vid/decide/unit-merges 2>/dev/null | while read -r _p _h; do [ "$(tid "$_h" || true)" = "$_t" ] || continue
    printf " — pull request #%s's last commit, %s, holds the same files: a report at it counts" "$_p" "$(printf %.12s "$_h")"; break; done; echo; }
# FB-5 B1.8: lacks, from the evidence file and the reports at the commit: a transition no test names, a row's id written with other digits, results
# older than a row's amendment, a report's branch, a file or a break's folder left out, no engine named. Read for the owner alone; it changes nothing
cmd_lacks() { [ -n "$MAN" ] && [ "${1:-}" = --ticket ] && [ -n "${2:-}" ] && [ "${3:-}" = --at ] && [ -n "${4:-}" ] || die 'usage — sh checks/results.sh lacks --ticket <n> --at <commit> (GitHub manual)'
  N=$2; HD=$(G rev-parse -q --verify "$4^{commit}" 2>/dev/null || echo "$4"); E=.vid/results/step-$N-$(printf %.12s "$HD").txt; [ -f "$E" ] || return 0; KIND=''; : > "$T/lc"
  awk -F'\t' 'NF == 6 { if ($6 ~ /(^|; )no case($|;)/) print $1; n = split($6, w, /; /); for (i = 1; i <= n; i++) if (w[i] ~ /^T[0-9]+: no case$/) { t = w[i]; sub(/:.*/, "", t); print $1 "-" t } }' "$E" > "$T/ln"
  [ ! -s "$T/ln" ] || for i in $(atids "$HD"); do form "$i" "$HD" || continue; awk -F'\t' '$1 == "c" { print $2 }' "$T/cx/$i/"[0-9]*; done > "$T/lc"
  awk 'function out(s) { if (!d[s]++) print s }
    FILENAME == ARGV[1] { if (!s[$0]++) { o[++n] = $0; b = $0; sub(/-T[0-9]+$/, "", b); B[n] = b } next }
    { for (i = 1; i <= n; i++) { b = B[i]; if ((b in W) || !match(b, /-[0-9]+$/)) continue; p = substr(b, 1, RSTART - 1); k = substr(b, RSTART + 1); sub(/^0+/, "", k); if (k == "") k = "0"; gsub(/-/, "[-_.]", p)
        if (match($0, "(^|[^A-Za-z0-9])" p "[-_.]0*" k "($|[^A-Za-z0-9])")) { x = substr($0, RSTART, RLENGTH); sub(/^[^A-Za-z0-9]/, "", x); sub(/[^A-Za-z0-9]$/, "", x); y = x; gsub(/[_.]/, "-", y); if (y != b) W[b] = x } } }
    END { t = ""; for (i = 1; i <= n; i++) if (B[i] in W) out(B[i] " written " W[B[i]]); else if (o[i] != B[i]) t = t (t == "" ? "" : " ") o[i]; if (t != "") print t ": no test of its own name" }' "$T/ln" "$T/lc"
  awk -F'\t' 'NF == 6 && $6 ~ /since its amendment/ { r = r (r == "" ? "" : " ") $1 } END { if (r != "") print r ": results older than its amendment" }' "$E"
  sed -n 's/^report skipped \([^ ]*\) \(.*\)$/vid-results\/\1 left out: \2/p' "$E"
  sed -n "s/^report head \([^ ]*\) read:\(.*\)\$/\1$TAB\2/p" "$E" | awk -F'\t' '{ n = split($2, w, /;/); for (i = 1; i <= n; i++) if (w[i] ~ /, not whole$/) { f = w[i]; sub(/^ /, "", f); sub(/ [0-9]+ passed, .*$/, "", f); print $1 " " f ": not whole" } }'
  sed -n 's/^fault folder for no row: \(.*\)$/faults\/\1: a break of no row/p' "$E"
  grep -q '^engines: ' "$E" || echo 'no engine named'; }
# FB-3 A3: team [--hand], the text telling the team what its reports hold, for the owner to hand over: GitHub manual's rules (mform, pool, A1.5)
# in plain words, GitHub auto's own ids there; filled with the code repository and the label prefix. A change of those rules changes it here.
# --hand writes it to .vid/plan/TEAM-REPORTS.md too. The case team-text-join holds its ids and the reader's together
tmanual() { cat <<'W'
# What ViD reads from the team

How a ticket is reported and decided. Each report goes to the code repository, `@REPO@`, as a branch. ViD runs nothing there and
keeps no copy of the code.

## Your test results

A result report is one folder, pushed as a branch of its own:

- **The branch** is `vid-results/<id>` and holds a folder named exactly `<id>`. ViD reads that folder alone; whatever else the branch
  holds is neither read nor downloaded. A branch without that folder is left out, and the product owner is told.
- **The id** is yours to choose. It must not begin `red-`, `req-`, `grade-`, `sort-`, `deploy-` or `stopped-`. An id that ends with the
  first 7 or more characters of its own commit and a number, as `step-<ticket>-<commit12>-<k>` does, is an attempt: of the attempts of
  one report the newest, the highest number, is read. Any other id is a report of its own.
- **`results.txt`** in the folder: its first line is `by: ` and whoever made it, a person, a group or an automated build; a line
  `commit: ` gives the full id of the commit the tests ran on, one the code repository holds.
- **At least one results file** in the folder itself: any `.xml` file with test cases in it, of any name, from any test suite, whole, in
  the form most test runners write (`testcase` elements, each with a `name`). Put in as many as you have.

Nothing else is asked of its form. A report with no results file cannot be read: it holds no result of any test.

**When it counts.** A report counts at the commit you ask about when its commit is that one, or holds the very same files: so the
results of a pull request's last commit count after a squash merge, when nothing else came in. A test that passed at other files is no
proof there, and the decision says where it passed. A test that an amendment of the ticket adds or changes counts only from reports
pushed after the amendment.

**How a row is found.** By the row's id in the test's name, with `-`, `_` and `.` counted as one character and neither a letter nor a
digit right before or after it: `test_ROW_012_adds_item` is of ROW-012, `test_ROW_0121` is not. A journey needs a test for each
transition, named by the transition's id (`ROW-012-T1`).

**How a row is read.** All the reports at the commit are read together, whoever made them and for whichever ticket. A row passes when
at least one file has a test of it, every test of it in that file passed, and no file has a failed or errored one. A test skipped in
another file, or one whose failure message begins `setup:`, stops nothing. The ticket's regression rows are read the same way.

## Read when you give it, never needed

- In `results.txt`: `covers: <rule row id> <number of places>` for a rule row, zero fails it; `stand-in: <what> — <test value> —
  <production value>` for each test difference; `engines: <the engines you run, the first one first>` and `environments: <n>` with
  the project's first ticket, the skeleton.
- A run of the tests before the product code, seen to fail: `red-<ticket or sub-issue>-<k>`, in the same form.
- A deliberate break: in a result report, a folder `faults/<row id>/` with the results files of that run and `control.txt`, the id of
  one row whose test should keep passing. A test that still passes under the break is too weak, and its row fails.

## The pull requests

- Each begins `ticket: #` and the number of the ticket, or of one of its sub-issues. ViD's own review of a ticket reads what its merged
  pull requests changed, as GitHub shows it: one that names no ticket may not be found, and a ticket with none is not accepted.
- When the ticket asks for a Decisions section, each holds the line `Decisions:` and under it one line a technical decision,
  `- <what was chosen> | why: <the reason>`, or the one line `Decisions: none`.
- Any branch, any number of them, any kind of merge. You merge before you ask. Do not let one close the ticket's own issue.

## Asking, and the answer

Once the results are pushed, comment on the ticket's own issue, the first line and nothing more:

    vid: decide <the full id of a commit on main's own line>

A commit inside a merged branch is not on that line; a merge, a squashed commit or main's newest is. Once every row passes, ViD makes
its own review of the ticket, once; nothing is asked of you for it. The answer is a comment on the ticket: `ticket: accepted`, or
`ticket: not yet` with a line for each row. A `request` line asks for one added test. After a fix, push the results at the new commit
and ask there. A ticket is claimed by a comment `vid: claimed`, an assignee or a sub-issue. Product questions are a comment that begins
`Question:`; the label `@PX@blocked` only when the work cannot go on without the answer.

## When ViD asks for a run or a deploy

Each is an issue of its own, which says what to run and what to comment there. The ids are fixed here, and the commit is the one the
issue names, itself.

- **A step's or a stage's run, or one against a deployed product**, in chunks: `req-<ask issue>-<chunk>-<k>`, in the form above, its `by:` and its results files of any name.
  Run at least the tests your accepted results held for each row. When no test is left for the chunk of everything else (`p1cx`), its
  results file holds no test and `results.txt` the line `none left`.
- **A deploy**, after ViD's okay: `deploy-<okay issue>-<k>`, with `report.txt`, whose first lines are `by: ` and `commit: ` too. The okay
  says the rest it holds.

You are asked for no grade: ViD makes the stage's itself.

The full form of every file: ViD results format 1 (`docs/RESULTS-FORMAT.md`), which the product owner can hand you.
W
}
tauto() { cat <<'W'
# What ViD reads from the dev side

Each report is one folder `<id>/`, pushed to the code repository, `@REPO@`, as the branch `vid-results/<id>`. ViD reads that folder alone; a
branch without it is left out. `<head12>` is the first 12 characters of the pull request's head, `<k>` the attempt, from 1.

| Report | Id | Its first file, and who it is by |
|---|---|---|
| The red run, the tests alone before the product code | `red-<ticket>-<k>` | `results.txt`, `by: TM`, with a `rows:` line |
| The head's run, and its breaks | `pr-<pull request>-<head12>-<k>` | `results.txt`, `by: TM` |
| The ticket's grade, once, at its first head | `grade-pr-<pull request>-<head12>-<k>` | `grade.txt`, `by: GR` |
| The sort of that grade's open lines | `sort-pr-<pull request>-<head12>-<k>` | `sorted.txt`, `by: SR` |
| A close's, a stage's or a staging run, a chunk | `req-<ask issue>-<chunk>-<k>` | `results.txt`, `by: TM` |
| A stage's grade, or one the owner asks | `grade-<ask issue>-<k>` | `grade.txt`, `by: GR` |
| A deploy | `deploy-<okay issue>-<k>` | `report.txt`, `by: DP` |
| The dev side stopped | `stopped-<k>` | `results.txt`, `by: DM` |

Each names its `commit:`, the commit it was made at, and a run has a whole `cases-<engine>.xml` for each engine asked. The ask for a decision
is a comment on the pull request, `vid: decide <the head's full commit>`; its description begins `ticket: #` and the ticket's number, and
holds a Decisions section. The label `@PX@blocked` only when the work cannot go on without an answer.

The full form of every file: ViD results format 1 (`docs/RESULTS-FORMAT.md`).
W
}
cmd_team() { case "$#:${1:-}" in 0:|1:--hand) ;; *) die 'usage — sh checks/results.sh team [--hand]' ;; esac; _r=$(skey repo); _p=$(skey labels-prefix)
  { if [ -n "$MAN" ]; then tmanual; else tauto; fi; } | awk -v r="${_r:-the code repository}" -v p="$_p" 'function sub1(s, k, v,   i) { while ((i = index(s, k)) > 0) s = substr(s, 1, i - 1) v substr(s, i + length(k)); return s } { print sub1(sub1($0, "@REPO@", r), "@PX@", p) }' > "$T/team" || exit 1
  # FB-5 B1.7: in GitHub manual, with the team's own rules on record (team-rules), --hand prints the text and writes nothing
  [ $# = 0 ] || { [ -n "$MAN" ] && [ -n "$(skey team-rules)" ]; } || { mkdir -p .vid/plan && put .vid/plan/TEAM-REPORTS.md < "$T/team"; } || exit 1; cat "$T/team"; }
# the evidence, from the stream $T/in: the format's matching, red rule and faults
EV=$HT'
  function add(set, name, st, f, fbd,   i) { i = ++nc[set]; cn[set, i] = norm(name); cs[set, i] = st; cf[set, i] = f; cb[set, i] = " " fbd " " }
  function scan(set, id,   i, w) { sn = 0; sfail = 0; sbad = 0; serr = 0; ssu = 0; sline = ""; sbline = ""; sfb = ""
    for (i = 1; i <= nc[set]; i++) if (hit(cn[set, i], id)) { sn++; w = cs[set, i]; if (w == "failed") { sfail++; if (sline == "") sline = cf[set, i]; sfb = sfb cb[set, i] } else if (w != "passed") { sbad++; serr += (w == "errored"); ssu += (w == "errored" && cf[set, i] ~ /^setup:/); if (sbline == "") sbline = w ": " cf[set, i] } } }
  # FB-7 C6: a row with no case in an engine is missing, not failed; a case that failed, or stopped at setup:, in another engine replaces it, its words too (over)
  function over() { if (TW ~ /^no case( in [^ ]+)?$/) TW = "" }
  function nocase(w) { return w ~ /(^|; )(T[0-9]+: )?no case( in [^ ;]+)?(;|$)/ }
  function t3c(id,   j, e, rf) { T3 = "passed"; TW = ""
    for (j = 1; j <= ne; j++) { e = en[j]; scan("h:" e, id)
      if (CT) { ES[e] = 1; if (!sn || sfail || sbad) EN[e] = 1 }
      if (e in xa) { rf = (sfail || serr > ssu); if (rf) { T3 = "failed"; over(); if (TW == "") TW = (sline != "" ? sline : sbline) " in " e } else if ((!sn || sbad) && CT) UX[e] = 1; if (rf && CT) EF[e] = 1; continue }   # an engine not asked (R11): its failure fails the row; setup:, a skip or no case could not run
      if (CT && (sfail || sbad > ssu)) EF[e] = 1
      if (!sn) { if (T3 == "passed") T3 = "missing"; if (TW == "") TW = "no case" (ne > 1 ? " in " en[j] : "") } else if (sfail || sbad) { T3 = (!sfail && ssu == sbad && T3 != "failed") ? "setup" : "failed"; over(); if (TW == "") TW = (sline != "" ? sline : sbline) } } }
  # FB-3 A1.2 (GitHub manual, POOL): every file of the reports at the commit is one pool. A row passes when at least one file has a case of it and every
  # one there passed, and no file has a failed or errored case of it; a skipped or setup: case in another file stops nothing. A file of a report made
  # before the row was amended (of) is left out for it. FI: the reports a case of it failed in
  function t3p(id,   j, b, fl, n, o, su, sk, good, w) { T3 = "passed"; TW = ""; FI = ""; o = su = sk = good = 0; w = ""; b = id; sub(/-T[0-9]+$/, "", b)
    for (j = 1; j <= ne; j++) { scan("h:" en[j], id); if (!sn) continue; fl = en[j]; sub(/:.*/, "", fl); if (((id SUBSEP fl) in of) || ((b SUBSEP fl) in of)) { o++; continue }
      if (sfail || serr > ssu) { T3 = "failed"; if (TW == "") TW = (sline != "" ? sline : sbline); if (!index(" " FI " ", " " fl " ")) FI = FI (FI == "" ? "" : " ") fl } else if (!sbad) good++; else if (ssu) { su++; if (w == "") w = sbline } else sk++ }
    if (T3 == "failed" || good) return; if (su) { T3 = "setup"; TW = w } else { T3 = "missing"; TW = sk ? "no case ran, skipped" : o ? "no case since its amendment" : "no case" } }
  function t3q(id,   k, i, n, a, w, f, x) { t3p(id); a = T3; w = TW; f = FI
    for (k = 1; k <= nj[id] + 0; k++) { t3p(id "-T" k); if (T3 != "passed") { if (rank[T3] > rank[a]) a = T3; w = why(w, "T" k ": " TW); n = split(FI, x, " "); for (i = 1; i <= n; i++) if (!index(" " f " ", " " x[i] " ")) f = f (f == "" ? "" : " ") x[i] } }
    if (rl[id] && (id in cov)) { if (cov[id] + 0 == 0) { a = "failed"; w = why("covers 0", w) } else w = why("covers " cov[id], w) }
    T3 = a; TW = w; FI = f }
  function t3(id,   k, a, w) { if (POOL) { t3q(id); return } t3c(id); a = T3; w = TW
    for (k = 1; k <= nj[id] + 0; k++) { t3c(id "-T" k); if (T3 != "passed") { if (rank[T3] > rank[a]) a = T3; w = why(w, "T" k ": " TW) } }
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
  BEGIN { FS = "\t"; KD = ""; hs = "none"; ne = 0; rank["missing"] = 1; rank["setup"] = 2; rank["failed"] = 3 }
  $1 == "pool" { POOL = 1 } $1 == "of" { of[$2, $3] = 1 }
  $1 == "kind" { KD = $2 } $1 == "eng" { en[++ne] = $2 } $1 == "xeng" { en[++ne] = $2; xa[$2] = 1 } $1 == "later" { LAT = 1 }
  $1 == "line" { print $2 }
  $1 == "row" { i = ++nr; id[i] = $2; kd[i] = $3; cl[i] = $4; ow[i] = ($5 ~ /(^|[ ;])(owed-[a-z-]*|seam)($|[ ;])/); dwo[$2] = ow[i]; prot[$2] = ($5 ~ /(^|[ ;])protection($|[ ;])/); rl[$2] = ($5 ~ /(^|[ ;])rule($|[ ;])/); bs[i] = $6; bm[$2] = $6; nj[$2] = $7 + 0; if ($2 != $6) jt[$6] = jt[$6] " " $2 }
  $1 == "flt" { fl[$2] = 1 } $1 == "unrun" { un[$2] = 1 } $1 == "old" { old[$2] = 1 } $1 == "hs" { hs = $2; hw = $3 } $1 == "h" { add("h:" $2, $3, $4, $5, $6) } $1 == "cov" { if (!POOL || !($2 in cov) || $3 + 0 < cov[$2] + 0) cov[$2] = $3 } $1 == "ret" { ret[$2] = 1 }
  $1 == "ts" { ts[$2] = $3; tw[$2] = $4; o2[++n2] = $2 } $1 == "tr" { tl[$2, $3] = 1 } $1 == "t" { add("t:" $2, $3, $4, $5, $6) }
  $1 == "fd" { fdir[$2] = 1; if ($3 != "") fctl[$2] = $3 } $1 == "fi" { inc[$2] = $3 } $1 == "f" { add("f:" $2, $3, $4, $5, $6) }
  $1 == "gx" { gx[++ng] = $2 } $1 == "gt" { gt[++ngt] = $2 } $1 == "tail" { tl2[++nt] = $2 }
  END { for (i = 1; i <= nr; i++) { r = id[i]; b = bs[i]; RED = "n/a"; RW = ""; c = cl[i]
      if (c == "t" && !ow[i] && ((r in un) || (b in un))) RED = "unrun"   # PB-5: no red and no fault owed, the transitions of a journey too
      else if (c == "t" && KD != "skeleton" && KD != "reached" && !ow[i]) { RED = "no-red"; RW = (n2 ? "no T2 lists it" : "no T2")
        if (POOL) { RED = "n/a"; RW = ""; for (j = 1; j <= n2; j++) { k = o2[j]; if (((r, k) in of) || ((b, k) in of)) continue; scan("t:" k, r); if (!sn) continue; RED = (sfail && !serr) ? "red" : "no-red"; RW = (RED == "red") ? "" : (sbline != "" ? "T2: " sbline : "T2: it passed"); break } }
        else for (j = 1; j <= n2; j++) { k = o2[j]; if (ts[k] == "lost") { RW = "T2 " k " refused, its rows unread: " tw[k]; RED = "missing"; continue } if ((k, r) in tl || (k, b) in tl) { if (ts[k] != "read") { RED = "missing"; RW = "T2 " k " refused: " tw[k]; break }
            scan("t:" k, r); RED = (sfail && !serr) ? "red" : "no-red"; RW = (RED == "red") ? "" : (sbline != "" ? "T2: " sbline : (sn ? "T2: it passed" : "T2: no case")); break } } }
      isret = (hs == "read" && ((r in ret) || (b in ret))); hs0 = hs; if (hs == "read" && ((r in old) || (b in old))) { hs = "old"; isret = 0 }; ncs = 0   # GM-4 E3
      if (ow[i]) { T3v = "owed"; TR = isret ? "retested: owed again" : "" }
      else if (hs == "refused") { T3v = "missing"; TR = "head report refused: " hw } else if (hs == "none") { T3v = "missing"; TR = "no head report" } else if (hs == "old") { T3v = "missing"; TR = "no head report since its amendment" }
      else { split("", ES); split("", EN); split("", EF); split("", UX); CT = 1; t3(r); CT = 0; T3v = T3; TR = TW; ncs = (!POOL && T3 == "missing" && nocase(TW)); if (POOL && T3 == "failed" && FI != "") fin[++nfin] = "fin\t" r "\t" FI; Pe = ""; Fe = ""
        for (j = 1; j <= ne; j++) { e = en[j]; if (EF[e]) Fe = Fe (Fe == "" ? "" : " ") e; else if (ES[e] && !EN[e]) Pe = Pe (Pe == "" ? "" : " ") e; if (UX[e]) cx[e]++ }
        if (Pe != "" && Fe != "") spl[++nsl] = "split\t" r "\t" Pe "\t" Fe }
      need = !POOL && !ow[i] && RED != "unrun" && (isret || (((r in fl) || (b in fl)) && c == "t") || (c == "t" && (KD == "skeleton" || RED == "no-red")))
      FVv = "n/a"; FR = ""
      if (!ow[i]) { if (hs == "read") fault(r); else FV = ""
        if (FV == "") { if (need && (!FQ || isret)) { FVv = (T3v == "failed" || T3v == "setup" || ncs) ? "waits" : "missing"; FR = (FVv == "waits") ? "" : "no fault folder" } }
        else if (T3v == "failed" || T3v == "setup" || ncs) FVv = "waits" (need ? "" : " extra"); else if (T3v != "passed") { FVv = "missing" (need ? "" : " extra"); FR = "no T3 to read it by" } else { FVv = FV (need ? "" : " extra"); FR = FW } }
      if (ow[i] && (r in fdir)) { used[r] = 1; FR = "a fault folder no owed row needs" }
      if (hs == "old" && ((r in fdir) || (b in fdir))) { used[r] = 1; used[b] = 1 } hs = hs0
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", r, (c != "t" && kd[i] == "transition") ? "retested" : kd[i], RED, T3v, FVv, why(why(RW, TR), FR) }
    for (j = 1; j <= nsl; j++) print spl[j]
    for (j = 1; j <= nfin; j++) print fin[j]
    for (j = 1; j <= ne; j++) if ((en[j] in xa) && cx[en[j]]) printf "engine %s: %d could not run\n", en[j], cx[en[j]]
    for (j = 1; j <= ng; j++) print gx[j]
    for (j = 1; j <= ngt; j++) { r = gt[j]; if (dwo[r] || (!LAT && !((r in fdir) || (bm[r] in fdir)))) print "open grade line: " r }   # a weak-test line closed by its break, and at any later head than that of the grade (v0.26.10.25.2 R3)
    for (r in fdir) if (!(r in used)) printf "fault folder for no row: %s\n", r
    for (j = 1; j <= nt; j++) print tl2[j] }'
# one report's cases into the stream, each line headed by its words: push <rev> <head…>
push() { cases "$1" | awk -F'\t' -v h="$2" '$1 == "c" { print h "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' >> "$T/in"; }
tally() { cases "$1" | awk -F'\t' '$1 == "c" { t[$3]++ } END { printf "%d passed, %d failed, %d errored, %d skipped", t["passed"], t["failed"], t["errored"], t["skipped"] }'; }
# standins <key>: stand-in-<key>.txt (the key pr-<p>, or GM-4 E1's step-<n>), rebuilt from each head's newest attempt, oldest report
# first; stand-in.txt, all of them, each line once
standins() { KS=$1; O=.vid/results/stand-in-$KS.txt; : > "$T/hd"; : > "$T/so"   # the rebuild in $T/so, published once (R6)
  if [ -n "$MAN" ]; then for i in $(cat "$T/pids"); do printf '%s %s %s\n' "$(G log -1 --format=%ct "refs/heads/vid-results/$i")" "$H" "$i" >> "$T/hd"; done   # FB-3 A1.2: the reports at the commit decided
  else for h in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/$KS-*" 2>/dev/null | sed -n "s/^$KS-\([0-9a-f]\{12\}\)-[0-9][0-9]*\$/\1/p" | sort -u); do
    k=$(newest "$KS-$h"); i=$KS-$h-$k; form "$i" '' || continue; printf '%s %s %s\n' "$(G log -1 --format=%ct "refs/heads/vid-results/$i")" "$h" "$i" >> "$T/hd"; done; fi
  sort -n "$T/hd" | while read -r _d h i; do R=refs/heads/vid-results/$i; sl "$i" stand-in | while IFS= read -r l; do [ -n "$l" ] || continue
      cut -f2- "$T/so" | grep -qxF "stand-in: $l" || printf '%s\tstand-in: %s\n' "$h" "$l" >> "$T/so"; done; done || exit 1; put "$O" < "$T/so" || exit 1
  { for n in $(ls .vid/results | sed -n 's/^stand-in-pr-\([0-9][0-9]*\)\.txt$/\1/p' | sort -n); do cat ".vid/results/stand-in-pr-$n.txt"; done
    for n in $(ls .vid/results | sed -n 's/^stand-in-step-\([0-9][0-9]*\)\.txt$/\1/p' | sort -n); do cat ".vid/results/stand-in-step-$n.txt"; done; } | awk -F'\t' '!s[$2]++' > "$T/si" || exit 1; put .vid/results/stand-in.txt < "$T/si" || exit 1; }
# GM-4 E1: K, the key of the reports read and of the evidence file: pr-<p> for a pull request's head, step-<n> for a ticket at a commit
cmd_read() { N=''; P=''; HD=''; AT=''; while [ $# -ge 2 ]; do case $1 in --ticket) N=$2 ;; --pr) P=$2 ;; --head) HD=$2 ;; --at) AT=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  if [ -n "$AT" ]; then [ -n "$N" ] && [ -z "$P$HD" ] || die 'usage — sh checks/results.sh read --ticket <n> --at <commit>'; HD=$AT; K=step-$N
  else [ -n "$N" ] && [ -n "$P" ] && [ -n "$HD" ] || die 'usage — sh checks/results.sh read --ticket <n> --pr <p> --head <commit> | --ticket <n> --at <commit>'; K=pr-$P; fi
  ticket "$N"; HD=$(G rev-parse -q --verify "$HD^{commit}" 2>/dev/null || echo "$HD"); H=$(printf %s "$HD" | cut -c1-12); : > "$T/in"; printf 'kind\t%s\n' "$KIND" >> "$T/in"; mkdir -p .vid/results
  if [ -n "$AT" ]; then printf 'line\tticket %s, at %s\n' "$N" "$HD"; else printf 'line\tticket %s, pull request %s, head %s\n' "$N" "$P" "$HD"; fi >> "$T/in"
  if [ -n "$MAN" ]; then pool; else
  for k in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/red-$N-*" 2>/dev/null | sed -n "s/^red-$N-\([0-9][0-9]*\)\$/\1/p" | sort -rn); do i=red-$N-$k; R=refs/heads/vid-results/$i
    if form "$i" ''; then printf 'ts\t%s\tread\t\n' "$i"; printf 'line\treport T2 %s read: %s\n' "$i" "$(tally "$R:$i/cases-${ENGS%% *}.xml")"; push "$R:$i/cases-${ENGS%% *}.xml" "t$TAB$i"
    else printf 'ts\t%s\trefused\t%s\n' "$i" "$WHY"; printf 'line\treport T2 %s refused %s\n' "$i" "$WHY"; fi >> "$T/in"
    l=$(G show "$R:$i/results.txt" 2>/dev/null | sed -n 's/^rows: *//p' | head -n 1 || true)
    if [ -n "$l" ]; then for r in $l; do printf 'tr\t%s\t%s\n' "$i" "$r"; done >> "$T/in"; else [ -z "$WHY" ] || printf 'ts\t%s\tlost\t%s\n' "$i" "$WHY" >> "$T/in"; fi; done
  case $KIND in skeleton|reached) ;; *) [ -n "$(G for-each-ref "refs/heads/vid-results/red-$N-*" 2>/dev/null)" ] || printf 'line\treport T2 none\n' >> "$T/in" ;; esac
  k=$(newest "$K-$H"); i=$K-$H-${k:-0}; RET=''; FD=''
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
    { for w in engines environments retested; do x=$(sl "$i" "$w" | tr '\n' ' ' | sed 's/ *$//'); [ -z "$x" ] || printf 'tail\t%s: %s\n' "$w" "$x"; done; } >> "$T/in"; fi; fi
  awk -F'\t' '$1 == "flt" || $1 == "unrun"' "$T/tk" > "$T/in.rows"
  [ "$KIND" = reached ] || awk -F'\t' '$1 == "row" { if ($5 + 0 > 0) { for (i = 1; i <= $5; i++) printf "row\t%s-T%d\ttransition\tt\t%s\t%s\n", $2, i, $4, $2 } else printf "row\t%s\t%s\tt\t%s\t%s\n", $2, $3, $4, $2 }' "$T/tk" >> "$T/in.rows"
  { sed -n "s/^reg$TAB//p" "$T/tk"; [ "$KIND" != reached ] || cut -f1,2 "$T/tk" | sed -n "s/^row$TAB//p"; } > "$T/more"; for r in $(cat "$T/more"); do more "$r" regression r; done
  for r in $RET; do more "$r" retested o; done
  for r in $FD; do ! printf %s "$r" | grep -Eq '^[A-Z]+-[0-9][A-Za-z0-9-]*$' || more "$r" regression r; done   # R13: a fault folder is read wherever it is
  # the ticket's one grade (v0.26.10.25.2 R2): the oldest grade report's head, its newest attempt, and no other
  # FB-3 A1.4 (GitHub manual): the grade, and the sort, are ViD's own review's, the one the ticket's record names (.vid/decide/review/), whatever the
  # commit it was made at; a grade- or sort- branch of the team's is not read
  GL=''; : > "$T/gr"; i=$(G for-each-ref --sort=committerdate --format='%(refname:lstrip=3)' "refs/heads/vid-results/grade-$K-*" 2>/dev/null | head -n 1)
  if [ -n "$MAN" ]; then i=$(own grade grade.txt); fi; if [ -n "$i" ]; then h=${i%-*}; h=${h##*-}; [ -n "$MAN" ] || i=${i%-*}-$(newest "${i%-*}"); if form "$i" ''; then GL="report grade $i read"; { G show "refs/heads/vid-results/$i:$i/grade.txt"; echo; } >> "$T/gr"; else GL="report grade $i refused $WHY"; fi; [ "$h" = "$H" ] || printf 'later\t1\n' >> "$T/in"; fi
  [ "$KIND" = reached ] || printf 'line\t%s\n' "${GL:-report grade none}" >> "$T/in"; awk '/^finding: / { if (!s[$0]++) print "gx\t" $0; next } /^(by|commit): / || !NF { next } { v[$1] = $2; k[$1] = $3 } END { for (r in v) { if (v[r] != "kept") print "gx\tlist: " r; if (v[r] ~ /^(breached|unclear)$/) print ((v[r] == "breached" && k[r] == "test") ? "gt\t" : "gx\topen grade line: ") r } }' "$T/gr" >> "$T/in"
  i=$(G for-each-ref --sort=committerdate --format='%(refname:lstrip=3)' "refs/heads/vid-results/sort-$K-*" 2>/dev/null | tail -n 1); [ -z "$MAN" ] || i=$(own sort sorted.txt)
  if [ -z "$i" ]; then [ "$KIND" = reached ] || printf 'line\treport sort none\n' >> "$T/in"
  elif ! form "$i" ''; then printf 'line\treport sort %s refused %s\n' "$i" "$WHY" >> "$T/in"
  else printf 'line\treport sort %s read\n' "$i" >> "$T/in"; G show "refs/heads/vid-results/$i:$i/sorted.txt" | awk -v MAN="$MAN" 'NR > 2 && $2 == "note" && $3 == "it" { print "gx\tfinding: note — " substr($0, length($1) + 14) }
    MAN != "" && NR > 2 && $2 == "test" && $3 == "it" { print "gx\trequest: " $1 " — " substr($0, length($1) + 14) }   # FB-3 A1.4: an added test asked of the team, in its decision once
    NR > 2 && $2 == "prove" && $3 == "it" && $4 == "real" { print "gx\tfinding: real — " substr($0, length($1) + 20) }' >> "$T/in"; fi   # 0.26.11.1.3 (R3): a real check, for the staging okay
  left "$N" "$P" "$AT" | while IFS=$TAB read -r i y; do printf 'line\treport skipped %s %s\n' "$i" "$y"; done >> "$T/in"   # FB-3 A2
  # R4: a landed id's evidence starts at its landing: from a ticket published before it, none of its lines is read. GM-4 E3: in GitHub
  # manual a landing the team has not got changes nothing it was asked for, so nothing is dropped for it; one list replaces it there,
  # the tests whose evidence counts from an amendment (amends): a T2's rows and a head report made before it are not read for them
  if [ -n "$MAN" ]; then : > "$T/stale"; else stale "$N" > "$T/stale"; fi; cat "$T/rtd" >> "$T/stale"; if [ -s "$T/stale" ]; then for f in in.rows in; do awk -F'\t' -v S="$T/stale" 'BEGIN { while ((getline l < S) > 0) X[l] = 1 }
      ($1 == "row" || $1 == "flt") && (($2 in X) || ($6 in X)) { next } ($1 ~ /^(ret|fd|fi|f)$/) && ($2 in X) { next } $1 == "tr" && ($3 in X) { next } { print }' "$T/$f" > "$T/$f.s" && mv "$T/$f.s" "$T/$f"; done; fi
  setups "$K"; { cat "$T/in.rows"; cat "$T/in"; } | awk "$EV" > "$T/ev" || exit 1; [ -z "$MAN" ] || near; put ".vid/results/$K-$H.txt" < "$T/ev" || exit 1; standins "$K"; cat ".vid/results/$K-$H.txt"; }
# own <grade|sort> <file> (FB-3 A1.4): the ticket's own review's id, from its record
own() { ls .vid/decide/review/ 2>/dev/null | grep "^$1-step-$N-" | while read -r x; do [ ! -f ".vid/decide/review/$x/$2" ] || { echo "$x"; break; }; done; }
# GM-4 E3 (GitHub manual): amends <n> <id>, the tests the newest `amended <n>` log line naming them in added= or restated= names, where that
# line is as new as the report or newer (FB-3 A1.2: per report): $T/oldr, and an `of` line of the stream each, so the report is not read for them
rtime() { G log -1 --format=%ct "refs/heads/vid-results/$1" 2>/dev/null || echo 0; }
amlist() { : > "$T/am2"; [ -f .vid/tw/log ] || return 0; awk -v n="$1" '$1 == "amended" && $2 == n { a = ""; for (i = 3; i <= NF; i++) if ($i ~ /^at=/) a = substr($i, 4); for (i = 3; i <= NF; i++) if ($i ~ /^(added|restated)=/) { m = split(substr($i, index($i, "=") + 1), w, ","); for (j = 1; j <= m; j++) if (w[j] != "" && w[j] != "-") A[w[j]] = a } } END { for (r in A) print r "\t" A[r] }' .vid/tw/log > "$T/am"
  while IFS=$TAB read -r r a; do printf '%s\t%s\n' "$r" "$(epoch "$a")" >> "$T/am2"; done < "$T/am"; }
amends() { : > "$T/oldr"; [ -s "$T/am2" ] || return 0; awk -F'\t' -v t="$(rtime "$1")" '$2 + 0 >= t + 0 { print $1 }' "$T/am2" > "$T/oldr"; awk -v i="$1" '{ print "of\t" $0 "\t" i }' "$T/oldr" >> "$T/in"; }
isold() { grep -qxF -e "$1" -e "${1%-T[0-9]*}" "$T/oldr"; }
# pool (FB-3 A1.2, GitHub manual): the ticket's red runs, under its own number or a sub-issue's, each read and shown, a refused one said; then every
# result report at the commit, its newest attempt, each by its own form: $T/pids. A refused one is said by left
pool() { RET=''; FD=''; RX=''; : > "$T/pids"; printf 'pool\t1\n' >> "$T/in"; amlist "$N"; subs "$N" > "$T/iss"
  for i in $(G for-each-ref --sort=-committerdate --format='%(refname:lstrip=3)' 'refs/heads/vid-results/red-*' 2>/dev/null); do x=${i#red-}; grep -qxF "${x%%-*}" "$T/iss" || continue
    if form "$i" ''; then printf 'ts\t%s\tread\t\nline\treport T2 %s read:%s\n' "$i" "$i" "$(tallyf "$i")" >> "$T/in"; amends "$i"; pushf "$i" "t$TAB$i"; else printf 'line\treport T2 %s refused %s\n' "$i" "$WHY" >> "$T/in"; fi; done
  for i in $(atids "$HD"); do form "$i" "$HD" || { RX=1; continue; }; echo "$i" >> "$T/pids"; printf 'line\treport head %s read:%s\n' "$i" "$(tallyf "$i")" >> "$T/in"; amends "$i"; R=refs/heads/vid-results/$i
    awk -F'\t' -v i="$i" '$3 > 0 { print "eng\t" i ":" $4 }' "$T/cx/$i/names" >> "$T/in"; pushf "$i" h f
    sl "$i" covers | while read -r a b; do isold "$a" || printf 'cov\t%s\t%s\n' "$a" "$b"; done >> "$T/in"; for r in $(sl "$i" retested | tr -d '\r'); do ! printf %s "$r" | grep -Eq '^[A-Z]+-[0-9][A-Za-z0-9-]*$' || RET="$RET$r "; done
    for r in $(G ls-tree -r --name-only "$R" | awk -v p="$i/faults/" 'index($0, p) == 1 { x = substr($0, length(p) + 1); if (sub(/\/.*/, "", x)) print x }' | sort -u); do isold "$r" && continue; D=$R:$i/faults/$r; c=$(G show "$D/control.txt" 2>/dev/null | head -n 1 | tr -d ' \r' || true); printf 'fd\t%s\t%s\n' "$r" "$c" >> "$T/in"; FD="$FD $r"
      if G cat-file -e "$D/inconclusive.txt" 2>/dev/null; then printf 'fi\t%s\t%s\n' "$r" "$(G show "$D/inconclusive.txt" | head -n 1 | tr '\t' ' ')" >> "$T/in"
      else G -c core.quotePath=off ls-tree --name-only "$D" 2>/dev/null | grep -i '[.]xml$' > "$T/fx" || true; while IFS= read -r f <&5; do push "$D/$f" "f$TAB$r"; done 5< "$T/fx"; fi; done
    for w in engines environments retested; do x=$(sl "$i" "$w" | tr -d '\r' | tr '\n' ' ' | sed 's/ *$//'); [ -z "$x" ] || grep -q "^tail$TAB$w: " "$T/in" || printf 'tail\t%s: %s\n' "$w" "$x" >> "$T/in"; done; done
  for r in $RET; do printf 'ret\t%s\n' "$r" >> "$T/in"; done
  if [ -s "$T/pids" ]; then printf 'hs\tread\t\n'; elif [ -n "$RX" ]; then printf 'hs\trefused\tits form\nline\treport head none\n'; else printf 'hs\tnone\t\nline\treport head none\n'; fi >> "$T/in"; }
# near (FB-3 A1.1): for each row with no case that ran in the reports at the commit, `near TAB <row> TAB <commit12>`, the newest other report it passed in
near() { awk -F'\t' 'NF == 6 && $4 == "missing" && $6 ~ /(^|; )(T[0-9]+: )?no case/ { print $1 }' "$T/ev" > "$T/nr"; [ -s "$T/nr" ] || return 0
  G for-each-ref --sort=-committerdate --format='%(refname:lstrip=3)' refs/heads/vid-results/ > "$T/no"; while read -r i <&6; do [ -s "$T/nr" ] || break; c=$(awk -F'\t' -v i="$i" '$1 == i { print substr($2, 1, 12) }' "$T/rl"); [ -n "$c" ] || continue; grep -qxF -e "$i" "$T/pids" && continue; form "$i" '' || continue; amends "$i"
    cat "$T/cx/$i/"[0-9]* | awk -F'\t' -v N="$T/nr" -v O="$T/oldr" -v c="$c" "$HT"' BEGIN { while ((getline l < O) > 0) old[l] = 1; while ((getline l < N) > 0) { bb = l; sub(/-T[0-9]+$/, "", bb); if (!(l in old) && !(bb in old)) r[++n] = l } } $1 == "c" { x = norm($2); for (i = 1; i <= n; i++) if (hit(x, r[i])) { if ($3 == "passed") p[i] = 1; else b[i] = 1 } } END { for (i = 1; i <= n; i++) if (p[i] && !b[i]) print "near\t" r[i] "\t" c }' > "$T/nn"
    cat "$T/nn" >> "$T/ev"; cut -f2 "$T/nn" > "$T/nx"; grep -vxFf "$T/nx" "$T/nr" > "$T/nr2" || true; mv "$T/nr2" "$T/nr"; done 6< "$T/no"; }
# setups <key>: R12's count, the setup: errors of each engine over the pull request's head reports (the key pr-<p>), or a ticket's
# (GM-4 E1, step-<n>), each head's newest attempt, as tail lines
setups() { : > "$T/su"; for h in $(G for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/$1-*" 2>/dev/null | sed -n "s/^$1-\([0-9a-f]\{12\}\)-[0-9][0-9]*\$/\1/p" | sort -u); do
    k=$(newest "$1-$h"); i=$1-$h-$k; form "$i" '' || continue; R=refs/heads/vid-results/$i
    for e in $(G ls-tree --name-only "$R:$i" | sed -n 's/^cases-\([^ ]*\)\.xml$/\1/p'); do cases "$R:$i/cases-$e.xml" | awk -F'\t' -v e="$e" '$1 == "c" && $3 == "errored" && $4 ~ /^setup:/ { n++ } END { print e "\t" n + 0 }'; done; done >> "$T/su"
  awk -F'\t' '{ if (!($1 in n)) o[++m] = $1; n[$1] += $2; k[$1]++ } END { for (i = 1; i <= m; i++) if (n[o[i]]) printf "tail\tsetup errors %s: %d cases over %d runs\n", o[i], n[o[i]], k[o[i]] }' "$T/su" >> "$T/in"; }
# more <row> <kind> <class>: a row beyond the ticket's own. A journey is one line, every transition's cases needed, or a line each when retested
more() { has "$1" && return 0; case "$RTD " in *" ${1%-T[0-9]*} "*) return 0 ;; esac; n=$(tcount "$1"); m=$(mark "$1"); case " $RET " in *" $1 "*) i=0; while [ "$i" -lt "${n:-0}" ]; do i=$((i + 1)); printf 'row\t%s-T%d\ttransition\t%s\t%s\t%s\n' "$1" "$i" "$3" "$m" "$1"; done >> "$T/in.rows"; [ "${n:-0}" = 0 ] || return 0 ;; esac
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
cmd_declare() { P=''; HD=''; K=''; EN=''; WD=''; WS=''; while [ $# -ge 2 ]; do case $1 in --pr) P=$2; K=pr-$2 ;; --head|--at) HD=$2 ;; --ticket) K=step-$2 ;; --engines) EN=$2 ;; --words) WD=$2; WS=1 ;; *) die "unknown $1" ;; esac; shift 2; done
  # GM-4 F16: the engines the owner names, in their words: this the one writer of the handed record's engines line
  if [ -n "$EN$WS" ]; then [ -z "$K$HD" ] || die 'usage — sh checks/results.sh declare --engines "<primary> <other>…" --words "<the owner'"'"'s words>"'
    printf '%s' "$EN" | grep -Eq '^[A-Za-z0-9._+-]+( [A-Za-z0-9._+-]+)*$' || { echo "ViD results: refused — \"$EN\" is not the engines' names, the primary first, a space between" >&2; exit 1; }
    [ -n "$(printf '%s' "$WD" | tr -d '[:space:]')" ] || { echo "ViD results: refused — the engines go on record only in the owner's words" >&2; exit 1; }
    mkdir -p .vid/tw; { grep -v '^engines ' .vid/tw/handed 2>/dev/null || true; printf 'engines %s | stand-in: owner at %s, words "%s"\n' "$EN" "$(now)" "$(printf '%s' "$WD" | tr '\t\n' '  ' | tr '"' "'")"; } > "$T/h" || exit 1; put .vid/tw/handed < "$T/h" || exit 1
    echo "declared engines=$EN by the owner's words"; return 0; fi
  [ -n "$K" ] && [ -n "$HD" ] || die 'usage — sh checks/results.sh declare --pr <p> --head <commit> | --ticket <n> --at <commit> | --engines "<primary> <other>…" --words "<w>"'
  HD=$(G rev-parse -q --verify "$HD^{commit}" 2>/dev/null || echo "$HD"); H=$(printf %s "$HD" | cut -c1-12); if [ -n "$MAN" ]; then mdeclare; return 0; fi; k=$(newest "$K-$H"); [ -n "$k" ] || { echo "no head report at $H"; return 0; }; i=$K-$H-$k; KIND=''
  form "$i" "$HD" || { echo "refused $WHY"; return 0; }; E=$(sl "$i" engines | head -n 1); M=$(sl "$i" environments | head -n 1); declared; }
# FB-3 A1.3 (GitHub manual): the engines (by spaces or commas, FB-5 B1.3) and the environments, when given, of the reports at the commit, each the first report's that names them
mdeclare() { E=''; M=''; KIND=''; for i in $(atids "$HD"); do form "$i" "$HD" || continue; [ -n "$E" ] || E=$(sl "$i" engines | tr -d '\r' | head -n 1 | tr ', ' '  ' | tr -s ' ' | sed 's/ $//'); [ -n "$M" ] || M=$(sl "$i" environments | tr -d '\r' | head -n 1); done; [ -n "$E$M" ] || { echo "no engines or environments declared at $H"; return 0; }; declared; }
declared() {
  if [ -n "$E" ]; then mkdir -p .vid/tw; { grep -v '^engines ' .vid/tw/handed 2>/dev/null || true; printf 'engines %s | stand-in: results reader\n' "$E"; } > "$T/h" || exit 1; put .vid/tw/handed < "$T/h" || exit 1; fi
  # 0.26.10.29.2 (R10): stacks= and unverified-rows= are rewritten only when the declared count differs from stacks=; the same
  # count leaves a recorded raise (plan-change what=other naming unverified-rows=<n>) standing, as develop re-measures only on a
  # change; a budget with no unverified-rows= line is written whole
  # both read as numbers (02 is 2, written 2), and no stacks= line is one environment, as the planner and admission read it
  case $M in ''|*[!0-9]*) ;; *) M=$(printf '%s' "$M" | sed 's/^0*//'); M=${M:-0} ;; esac
  OS=$(sed -n 's/^stacks=0*\([0-9][0-9]*\).*/\1/p' .vid/budget 2>/dev/null | head -n 1); OS=${OS:-1}; NM=$M; [ "$OS" != "$M" ] || ! grep -q '^unverified-rows=' .vid/budget 2>/dev/null || NM=''
  case $NM in ''|*[!0-9]*) ;; *) { grep -vE '^(stacks|unverified-rows)=' .vid/budget 2>/dev/null || true; printf 'stacks=%s\nunverified-rows=%s\n' "$M" "$((60 * M))"; } > "$T/b" || exit 1; put .vid/budget < "$T/b" || exit 1 ;; esac
  echo "declared engines=${E:--} environments=${M:--}"; }
# the close's reading of one chunk, from the stream: c <engine> <attempt> <name> <status> <first line>; u <row> <transitions>; h <engine> <row> <name>,
# a case of the row's newest accepted head report. Each row in each engine of the chunk: passed, failed, could not run, not run, or, in phase 2
# with no case at all, an x line for the engine line. Then the chunk's line and its rows
CL=$HT'
  function unit(u, e, a,   i, n, bad, su) { n = 0; bad = 0; su = 0
    for (i = 1; i <= nc[e, a]; i++) if (hit(cn[e, a, i], u)) { n++; if (cs[e, a, i] == "errored" && cf[e, a, i] ~ /^setup:/) su++; else if (cs[e, a, i] != "passed") { bad++; if (FN == "") FN = cr[e, a, i] } }
    return !n ? "none" : bad ? "failed" : su ? "setup" : "passed" }
  # FB-3 A1.5 (GitHub manual, MAN): every file of the report of a chunk is one pool, for each engine of the chunk: a unit passes when one file has a case
  # of it and all there passed, and none has a failed or errored one; a skipped or setup: case in another file stops nothing
  function unitm(u, a,   i, j, f, n, g, b, s, p, sk, w) { g = 0; s = 0; sk = 0; w = ""
    for (j = 1; j <= nf[a]; j++) { f = fl[a, j]; n = 0; b = 0; p = 0; for (i = 1; i <= nc[f, a]; i++) if (hit(cn[f, a, i], u)) { n++; if (cs[f, a, i] == "failed" || (cs[f, a, i] == "errored" && cf[f, a, i] !~ /^setup:/)) { if (FN == "") FN = cr[f, a, i]; return "failed" } if (cs[f, a, i] == "errored") b++; else if (cs[f, a, i] != "passed") { p++; w = cr[f, a, i] } }
      if (!n) continue; if (b) s++; else if (p) sk++; else g++ }
    if (g) return "passed"; if (s) return "setup"; if (sk) { if (FN == "") FN = w; return "failed" } return "none" }
  function fullm(r, e, a,   s, k, t) { FN = ""; s = unitm(r, a); if (s == "none") { if (FN == "") FN = r " with no case"; return (P2 && !nh[r, e]) ? "none" : P2 ? "not run" : "failed" }
    for (k = 1; k <= nt[r]; k++) { t = unitm(r "-T" k, a); if (t == "none") { if (FN == "") FN = r "-T" k " with no case"; s = "failed" } else if (t == "failed" || (t == "setup" && s == "passed")) s = t }
    if (s == "failed") return s; for (k = 1; k <= nh[r, e]; k++) if (!((a, hn[r, e, k]) in havem)) return "not run"; return (s == "setup") ? "could not run" : "passed" }
  function full(r, e, a,   s, k, gone) { if (MAN != "") return fullm(r, e, a); FN = ""; s = unit(r, e, a); gone = 0; for (k = 1; k <= nt[r]; k++) if (unit(r "-T" k, e, a) == "none") { gone = 1; if (FN == "") FN = r "-T" k " with no case" }
    if (s == "none") { if (FN == "") FN = r " with no case"; return (P2 && !nh[r, e]) ? "none" : P2 ? "not run" : "failed" } if (s == "failed" || gone) return "failed"
    for (k = 1; k <= nh[r, e]; k++) if (!((e, a, hn[r, e, k]) in have)) return "not run"
    return (s == "setup") ? "could not run" : "passed" }
  BEGIN { FS = "\t"; ne = split(CE, en, " "); P2 = (C !~ /^p1c/) }
  $1 == "c" { i = ++nc[$2, $3]; cn[$2, $3, i] = norm($4); cr[$2, $3, i] = $4; cs[$2, $3, i] = $5; cf[$2, $3, i] = $6; have[$2, $3, norm($4)] = 1; if (MAN != "") { havem[$3, norm($4)] = 1; if (!(($2, $3) in sf)) { sf[$2, $3] = 1; fl[$3, ++nf[$3]] = $2 } } next }
  $1 == "u" { ro[++nr] = $2; nt[$2] = $3 + 0; next }
  $1 == "q" { RL[$2] = 1; next } $1 == "v" { CV[$2] = $3; next }
  $1 == "h" && hit(norm($4), $3) && !((e2 = $2 SUBSEP $3 SUBSEP norm($4)) in hs) { hs[e2] = 1; i = ++nh[$3, $2]; hn[$3, $2, i] = norm($4); next }
  END { for (i = 1; i <= nr; i++) { r = ro[i]; for (j = 1; j <= ne; j++) { e = en[j]; v = full(r, e, K)
        if (r in RL) { if (!(r in CV)) { if (MAN == "") v = "not run" } else if (CV[r] + 0 == 0) { v = "failed"; FN = "covers 0" } }   # v0.26.10.26.2 (R4): CS reads a rule row by its covers: line, in every engine
        if (v == "none") { X[++nx] = "x\t" e "\t" r; continue }
        if (v == "could not run") for (a = K - 1; a >= 1; a--) if ((nc[e, a] || nf[a]) && full(r, e, a) == "passed") { v = "passed"; break }   # CK-T-109
        L[++nl] = "row\t" C "\t" e "\t" r "\t" v (v == "failed" ? "\t" FN : ""); if (v == "failed") red = 1; else if (v != "passed") inc = 1 } }
    print "chunk\t" C "\t" (red ? "red" : inc ? "incomplete" : "green") "\t" K; for (i = 1; i <= nl; i++) print L[i]; for (i = 1; i <= nx; i++) print X[i] }'
# acc <row> <engines>: h lines, the cases of the row's newest accepted head report whose head is an ancestor of the close's commit (CK-R-160)
acc() { awk -F'\t' -v r="$1" '($4 == r || index($4, r "-T") == 1) && $5 ~ /^(accepted|accepted by ruling|passing)$/ { print NR "\t" $2 "\t" $3 }' .vid/decide/log 2>/dev/null | sort -rn | while IFS=$TAB read -r _n p h; do
    # FB-5 B1.4: a head accepted on its own pull request is on record at its merge (merges), a squash of it too: it is read by that merge's ancestry
    mh=$(awk -F'\t' -v k="$p-$h" '$1 == k { m = $4 } END { if (m != "") print m }' .vid/decide/merges 2>/dev/null || true); G merge-base --is-ancestor "${mh:-$h}" "$C" 2>/dev/null || continue
    # FB-3 A1.5 (GitHub manual): the accepted reports at the commit the ticket was decided at; an engine's names from a file named cases-<engine>.xml alone
    if [ -n "$MAN" ]; then fh=$(G rev-parse -q --verify "$h^{commit}" 2>/dev/null || true); [ -n "$fh" ] || continue; for q in $(atids "$fh"); do form "$q" "$fh" || continue; for e in $2; do awk -F'\t' -v n="cases-$e.xml" '$4 == n && $2 == 1 { print $1 }' "$T/cx/$q/names" | while read -r x; do awk -F'\t' -v e="$e" -v r="$1" '$1 == "c" { print "h\t" e "\t" r "\t" $2 }' "$T/cx/$q/$x"; done; done; done; break; fi
    case $p in step-*) kq=$p ;; *) kq=pr-$p ;; esac; q=$(newest "$kq-$h"); [ -n "$q" ] || continue; q=$kq-$h-$q   # GM-4 E2: a ticket's too
    for e in $2; do cases "refs/heads/vid-results/$q:$q/cases-$e.xml" | awk -F'\t' -v e="$e" -v r="$1" '$1 == "c" { print "h\t" e "\t" r "\t" $2 }'; done; break; done; }
# v0.26.10.26.1 (R2, R4): stdir <N>, the stage's newest candidate folder; ids, every id of INVENTORY.md, a line each
stdir() { c=''; for d in $(ls ".vid/decide/stage/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f ".vid/decide/stage/$1/$d/ask" ] && c=$d; done; echo ".vid/decide/stage/$1/${c:-0}"; }
# GM-4 E12: in GitHub manual the inventory read at the applied commit (lib.sh applied), so no read carries a pending change
invat_() { if manual; then _a=$(applied); [ -z "$_a" ] || git show "$_a:INVENTORY.md" 2>/dev/null; else cat INVENTORY.md 2>/dev/null; fi; }
invids() { invat_ | sed -n '/^```vid-inventory/,/^```$/p' | awk -F'|' '{ a = $1; gsub(/[ \t]/, "", a); b = $2; gsub(/[ \t]/, "", b); if (a ~ /^ROW-[0-9]+$/) print a; else if (b ~ /^[A-Z]+-[0-9]+$/) print b }'; }
# unmatched <rev> <engine>: the rest chunk's cases whose name holds no id of the inventory, `unmatched <case> <status>`
unmatched() { invids > "$T/ids"; cases "$1" | awk -F'\t' -v I="$T/ids" "$HT"' BEGIN { while ((getline l < I) > 0) W[++n] = l }
    $1 == "c" { c = norm($2); f = 0; for (i = 1; i <= n && !f; i++) f = hit(c, W[i])
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
      if [ -n "$k" ] && form "req-$I-$CH-$k" "$C"; then i=req-$I-$CH-$k; nc=0; if [ -n "$MAN" ]; then nc=$(awk -F'\t' '{ n += $3 } END { print n + 0 }' "$T/cx/$i/names"); else for e in $CE; do nc=$((nc + $(cases "refs/heads/vid-results/$i:$i/cases-$e.xml" | grep -c '^c	' || true))); done; fi
        [ "$nc" -gt 0 ] || G show "refs/heads/vid-results/$i:$i/results.txt" 2>/dev/null | grep -qx 'none left' || WHY='no test case, and results.txt has no line none left'; fi
      if [ -n "$k" ] && [ -z "$WHY" ] && form "req-$I-$CH-$k" "$C"; then printf 'chunk\tp1cx\tgreen\t%s\n' "$k" >> "$T/co"; if [ -n "$MAN" ]; then cut -f4 "$T/cx/req-$I-$CH-$k/names" | while IFS= read -r f; do unmatched "refs/heads/vid-results/req-$I-$CH-$k:req-$I-$CH-$k/$f"; done >> "$T/co"; else for e in $CE; do unmatched "refs/heads/vid-results/req-$I-$CH-$k:req-$I-$CH-$k/cases-$e.xml"; done >> "$T/co"; fi
      else [ -z "$k" ] || printf 'refused\t%s\t%s\n' "req-$I-$CH-$k" "$WHY" >> "$T/co"; printf 'chunk\tp1cx\tabsent\t%s\n' "${k:--}" >> "$T/co"; fi; continue; fi
    if [ -n "$k" ] && form "req-$I-$CH-$k" "$C"; then : > "$T/cc"; j=$k
      while [ "$j" -ge 1 ]; do i=req-$I-$CH-$j; if [ "$j" = "$k" ] || form "$i" "$C"; then if [ -n "$MAN" ]; then while IFS=$TAB read -r x w0 n0 f <&5; do awk -F'\t' -v e="$f" -v a="$j" -v w="$w0" '$1 == "c" && (w == 1 || $3 == "failed" || $3 == "errored") { print "c\t" e "\t" a "\t" $2 "\t" $3 "\t" $4 }' "$T/cx/$i/$x"; done 5< "$T/cx/$i/names" >> "$T/cc"; else for e in $CE; do cases "refs/heads/vid-results/$i:$i/cases-$e.xml" | awk -F'\t' -v e="$e" -v a="$j" '$1 == "c" { print "c\t" e "\t" a "\t" $2 "\t" $3 "\t" $4 }'; done >> "$T/cc"; fi; fi; j=$((j - 1)); done
      for r in $RW; do printf 'u\t%s\t%s\n' "$r" "$(tcount "$r")"; acc "$r" "$CE"
        [ -n "$CS" ] && mark "$r" | grep -qE '(^|[ ;])rule($|[ ;])' && { printf 'q\t%s\n' "$r"; R=refs/heads/vid-results/req-$I-$CH-$k; sl "req-$I-$CH-$k" covers | awk -v r="$r" '$1 == r { print "v\t" $1 "\t" $2 }'; }; done >> "$T/cc"; awk -v C="$CH" -v CE="$CE" -v K="$k" -v MAN="$MAN" "$CL" "$T/cc" >> "$T/co"
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
# FB-2 A4: --kind dn --target staging|production, a take-down, read from <c>/dn-<target>/: `dn down <k>` with `down TAB <target> TAB
# <address>` (report.txt's `outcome: down` and its `down: <target> <address>`), `dn failed <k> <why>` (`outcome: failed down — <why>`), or
# `dn refused <k> <why>`
dnread() { G show "$R:$1/report.txt" | tr -d '\r' | awk -v k="$2" -v tg="$DT" '/^outcome: *down[ \t]*$/ { o = "down"; next }
    /^outcome: *failed down — / { o = "failed"; w = $0; sub(/^outcome: *failed down — */, "", w); next } /^outcome:/ { o = "?" } /^down: / { t = $2; a = $3 }
    END { if (o == "down") { if (t != tg || a == "") printf "dn\trefused\t%s\treport.txt has no down: %s <address> line\n", k, tg; else printf "dn\tdown\t%s\ndown\t%s\t%s\n", k, t, a }
      else if (o == "failed" && w !~ /^[ \t]*$/) printf "dn\tfailed\t%s\t%s\n", k, w
      else printf "dn\trefused\t%s\treport.txt has no outcome: down, nor outcome: failed down — <why>\n", k }'; }
# v0.26.10.27.1 (R1, R4): --kind rh, the rehearsal, and d2, the production deploy, read from <c>/rh/ and <c>/d2/, the stage's newest
# closed candidate's folder (--candidate <c>); prodnow: production's commit, the newest line of .vid/decide/production (none: none yet)
prodnow() { [ -f .vid/decide/production ] || return 0; awk -F'\t' 'NF { c = $1 } END { print c }' .vid/decide/production; }
cmd_deploy() { ST=''; KD=d1; DCA=''; DT=''; while [ $# -ge 2 ]; do case $1 in --stage) ST=$2 ;; --kind) KD=$2 ;; --candidate) DCA=$2 ;; --target) DT=$2 ;; *) die "unknown $1" ;; esac; shift 2; done; [ -n "$ST" ] || die 'usage — sh checks/results.sh deploy --stage <N> [--kind d1|rh|d2|dn] [--target staging|production] [--candidate <c>]'
  case $KD in d1|rh|d2) ;; dn) case $DT in staging|production) ;; *) die 'a take-down is read with --target staging|production' ;; esac ;; *) die "no kind $KD" ;; esac; CD=$(stdir "$ST"); [ -z "$DCA" ] || CD=.vid/decide/stage/$ST/$DCA; CD=$CD/$KD; [ "$KD" != dn ] || CD=$CD-$DT
  [ -f "$CD/ask" ] || die "no okay at $CD/ask"; I=$(sed -n "s/^issue$TAB//p" "$CD/ask" | head -n 1); C=$(sed -n "s/^commit$TAB//p" "$CD/ask" | head -n 1); k=$(newest "deploy-$I")
  [ ! -f "$CD/closed" ] || { printf '%s\tclosed\t-\n' "$KD" > "$T/g" || exit 1; put "$CD/read" < "$T/g" || exit 1; cat "$T/g"; return 0; }   # a closed okay's report is not read
  if [ -z "$k" ]; then printf '%s\tabsent\t-\n' "$KD" > "$T/g"
  elif ! form "deploy-$I-$k" "$C"; then printf '%s\trefused\t%s\t%s\n' "$KD" "$k" "$WHY" > "$T/g"
  elif ! G show "$R:deploy-$I-$k/report.txt" | tr -d '\r' | grep -qE '^(decision: *[^ ]|decisions: *none[[:space:]]*$)'; then printf '%s\trefused\t%s\t%s\n' "$KD" "$k" 'report.txt has no decision: line, nor decisions: none' > "$T/g"   # 0.26.10.29.5 (DP-1 R2)
  elif [ "$KD" = dn ]; then dnread "deploy-$I-$k" "$k" > "$T/g"   # FB-2 A4
  elif [ "$KD" != d1 ]; then deploy2 "$KD" "deploy-$I-$k" "$k" > "$T/g"
  else i=deploy-$I-$k; o=$(G show "$R:$i/report.txt" | sed -n 's/^outcome: *//p' | head -n 1); pc=$(G show "$R:$i/report.txt" | sed -n 's/^product change: *//p' | head -n 1 | tr -d ' \r')
    case $o in
      passed) if ! G cat-file -e "$R:$i/staging.txt" 2>/dev/null; then printf 'd1\trefused\t%s\ta passed deploy has no staging.txt\n' "$k" > "$T/g"
        else G show "$R:$i/staging.txt" | awk -v k="$k" '/^staging: *[^ ]/ { a = $2 } /^signin: / { if (NF >= 3) S[++ns] = $2 "\t" $3; else bad = "a signin: line lacks its role or address" }
            /^differs: *none[ \t]*$/ { none = 1; next } /^differs: / { x = $0; sub(/^differs: */, "", x); n = split(x, p, / — /); if (n != 3) bad = "a differs: line is not <what> — <on staging> — <on production>: " x; else D[++nd] = p[1] "\t" p[2] "\t" p[3] }
            END { if (a == "") bad = "staging.txt has no staging: line"; else if (!none && !nd && bad == "") bad = "staging.txt has no differs: line, nor differs: none"
              if (bad != "") { printf "d1\trefused\t%s\t%s\n", k, bad; exit } printf "d1\tpassed\t%s\nstaging\t%s\n", k, a; for (i = 1; i <= ns; i++) print "signin\t" S[i]; for (i = 1; i <= nd; i++) print "differs\t" D[i] }' > "$T/g"
          if [ "$(head -n 1 "$T/g" | cut -f2)" = passed ]; then d1x "$i" "$CD/ask" > "$T/g2"
            if [ "$(head -n 1 "$T/g2" | cut -f1)" = refused ]; then printf 'd1\trefused\t%s\t%s\n' "$k" "$(head -n 1 "$T/g2" | cut -f2-)" > "$T/g"; else cat "$T/g2" >> "$T/g"; fi; fi; fi ;;
      failed\ ?*) case $pc in yes|no) printf 'd1\tfailed\t%s\t%s\t%s\n' "$k" "${o#failed }" "$pc" > "$T/g" ;; *) printf 'd1\trefused\t%s\ta failed deploy has no product change: yes or no line\n' "$k" > "$T/g" ;; esac ;;
      *) printf 'd1\trefused\t%s\treport.txt has no outcome: passed, nor outcome: failed <step>\n' "$k" > "$T/g" ;;
    esac; fi
  put "$CD/read" < "$T/g" || exit 1; cat "$T/g"; }
# 0.26.11.1.1 (R3): the duties an okay names, by target; duties <id> <list>: the report's duties.txt, `duty TAB <duty> TAB done|not
# needed|not done|missing TAB <words>` for each duty of the list, `bad TAB <line>` for a line of a listed duty in no form, `none` with
# no duties.txt. A line of another duty is not read
DUT1='log-in environments outside-services sending-domain deploy-notes captures'
DUT2='service-switch-on backups point-in-time-recovery storage-versioning dns https monitoring'
# GM-4 E9 (GM M14, D7): dutl <list> <the okay's ask>: in GitHub manual, with the okay listing later work (its `later-work` lines), the
# list and later-work-off, the duty that keeps that work off for the people using the product; else the list as it is
dutl() { if manual && grep -q "^later-work$TAB" "$2" 2>/dev/null; then echo "$1 later-work-off"; else echo "$1"; fi; }
duties() { G cat-file -e "$R:$1/duties.txt" 2>/dev/null || { echo none; return 0; }
  G show "$R:$1/duties.txt" | tr -d '\r' | awk -v L="$2" -v DA=' — ' 'BEGIN { n = split(L, d, " "); for (i = 1; i <= n; i++) W[d[i]] = 1 }
    /^[ \t]*$/ { next } { x = $0; p = index(x, ": "); if (!p) next; k = substr(x, 1, p - 1); if (!(k in W)) next; r = substr(x, p + 2); q = index(r, DA); s = q ? substr(r, 1, q - 1) : ""; w = q ? substr(r, q + length(DA)) : ""
      if ((s != "done" && s != "not needed" && s != "not done") || w ~ /^[ \t]*$/) { print "bad\t" x; next } if (!(k in S)) { S[k] = s; T[k] = w } }
    END { for (i = 1; i <= n; i++) print "duty\t" d[i] "\t" ((d[i] in S) ? S[d[i]] : "missing") "\t" T[d[i]] }'; }
# d1x <id> <the okay's ask> (0.26.11.1.1, R1, R3, R4, R6): a passed D1's further lines, or `refused TAB <why>`: staging.txt's `seed:`
# as the okay's (`seed` in its ask, synthetic when none), one `seam:` line for each row of the okay's `rows`, `stays: up` carried;
# 0.26.11.1.2 (R9): the first `mail: <address> — <how to read it>` and `clock: <address> — <how to move it>` carried, one with no ` — ` refused;
# duties.txt, every staging duty answered, none `not done` but one the owner ruled a known limit (.vid/decide/duties-known);
# 0.26.11.1.3 (R3): for each real check the okay lists (`real <n> <line>` in its ask), a `real: #<the okay's issue>-<n> done — <what was run,
# where>` or `… not done — <why>` line, none missing or `not done` but one the owner ruled (.vid/decide/real-known), each read as `real <n>
# <done|not done|missing> <words>`; a line keyed to another okay is not read, and of one key the newest line stands
d1x() { sk=$(sed -n "s/^seed$TAB//p" "$2" | head -n 1); rw=$(sed -n "s/^rows$TAB//p" "$2" | head -n 1); ri=$(sed -n "s/^issue$TAB//p" "$2" | head -n 1); DL1=$(dutl "$DUT1" "$2")
  { G show "$R:$1/staging.txt" | tr -d '\r' | sed 's/^/S	/'; duties "$1" "$DL1" | sed 's/^/D	/'; } | awk -F'\t' -v seed="${sk:-synthetic}" -v rows="$rw" -v L="$DL1" -v KF=.vid/decide/duties-known -v DA=' — ' -v RA="$2" -v RI="$ri" -v RK=.vid/decide/real-known '
    BEGIN { while ((getline l < KF) > 0) { split(l, y, "\t"); K[y[1]] = 1 } n = split(L, d, " "); m = split(rows, rw, " ")
      while ((getline l < RA) > 0) if (l ~ /^real\t[0-9]+\t/) { split(l, y, "\t"); RN[++nr] = y[2]; RY[y[2]] = substr(l, length(y[1] y[2]) + 3) } while ((getline l < RK) > 0) { split(l, y, "\t"); RD[y[1]] = 1 } }
    function why(s) { if (bad == "") bad = s }
    $1 == "S" { x = substr($0, 3); if (x ~ /^seed:/) { v = x; sub(/^seed: */, "", v); sub(/[ \t]+$/, "", v); if (sd == "") sd = v }
        else if (x ~ /^stays: *up[ \t]*$/) st = 1
        else if (x ~ /^(mail|clock):/) { k = x; sub(/:.*/, "", k); v = x; sub(/^[a-z]+: */, "", v); q = index(v, DA)
          if (!q || q == 1 || substr(v, q + length(DA)) ~ /^[ \t]*$/) why("a " k ": line is not <address> — <how to " (k == "mail" ? "read" : "move") " it>: " x)
          else if (!(k in MC)) { MC[k] = 1; MA[k] = substr(v, 1, q - 1); MH[k] = substr(v, q + length(DA)) } }
        else if (x ~ /^real:/ && match(x, "^real: *#" RI "-[0-9]+ ")) { v = substr(x, RLENGTH + 1); k = substr(x, 1, RLENGTH - 1); sub(/^real: *#[0-9]+-/, "", k); q = index(v, DA)
          s0 = q ? substr(v, 1, q - 1) : ""; w = q ? substr(v, q + length(DA)) : ""
          if ((s0 != "done" && s0 != "not done") || w ~ /^[ \t]*$/) why("a real: line is not real: #<issue>-<n> done — <what was run, where>, nor not done — <why>: " x); else { RX[k] = s0; RW[k] = w } }
        else if (x ~ /^seam: /) { v = x; sub(/^seam: */, "", v); r = v; sub(/ .*/, "", r); t = substr(v, length(r) + 2)
          if (t ~ /^real[ \t]*$/) { SM[r] = "real"; SW[r] = "" } else if (index(t, "stand-in" DA) == 1 && t !~ ("^stand-in" DA "[ \t]*$")) { SM[r] = "stand-in"; SW[r] = substr(t, length("stand-in" DA) + 1) }
          else why("a seam: line is not <row> real, nor <row> stand-in — <why>: " x) } next }
    $1 == "D" && $2 == "none" { nod = 1; next } $1 == "D" && $2 == "bad" { why("a duties.txt line is not <duty>: done, not needed or not done — <words>: " $3); next }
    $1 == "D" && $2 == "duty" { DS[$3] = $4; DW[$3] = $5; next }
    END { if (sd == "") why("staging.txt has no seed: line"); else if (sd != seed) why("staging.txt says seed: " sd ", where the okay says seed: " seed)
      for (i = 1; i <= m; i++) if (!(rw[i] in SM)) why("staging.txt has no seam: line for the outside-service row " rw[i])
      if (nod) why("a passed deploy has no duties.txt")
      for (i = 1; i <= n; i++) { k = d[i]; if (DS[k] == "missing") why("duties.txt has no line for the duty " k); else if (DS[k] == "not done" && !(k in K)) why("the duty " k " is not done: " DW[k]) }
      for (i = 1; i <= nr; i++) { k = RN[i]; if (!(k in RX)) RX[k] = "missing"; if ((RI "-" k) in RD) continue; if (RX[k] == "missing") why("staging.txt has no real: line for #" RI "-" k ": " RY[k]); else if (RX[k] == "not done") why("the real check #" RI "-" k " is not done: " RW[k]) }
      if (bad != "") { print "refused\t" bad; exit }
      print "seed\t" sd; if (st) print "stays\tup"; if ("mail" in MC) print "mail\t" MA["mail"] "\t" MH["mail"]; if ("clock" in MC) print "clock\t" MA["clock"] "\t" MH["clock"]; for (r in SM) print "seam\t" r "\t" SM[r] "\t" SW[r]; for (i = 1; i <= n; i++) print "duty\t" d[i] "\t" DS[d[i]] "\t" DW[d[i]]; for (i = 1; i <= nr; i++) print "real\t" RN[i] "\t" RX[RN[i]] "\t" RW[RN[i]] }'; }
# 0.26.10.29.5 (DP-1 R2): every deploy report, D1, RH and D2, whatever its outcome, states its decisions: `decision: <what> | why: <why>`
# lines, or the one line `decisions: none`; with neither it is refused, as a rehearsal with no drops: line is, and so never read for them
# deploy2 <rh|d2> <id> <k>: the rehearsal's or production deploy's report, its form alone
deploy2() { i=$2; k=$3; G show "$R:$i/report.txt" > "$T/rp"; o=$(sed -n 's/^outcome: *//p' "$T/rp" | head -n 1 | sed 's/[[:space:]]*$//'); pc=$(sed -n 's/^product change: *//p' "$T/rp" | head -n 1 | tr -d ' \r')
  steps=$(G show "$R:$i/deploy.xml" 2>/dev/null | awk 'BEGIN { RS = "<" } /^testcase[ \t\n]/ { n = $0; sub(/.*[ \t\n]name="/, "", n); sub(/".*/, "", n); print n }')
  P=$(prodnow); bad=''
  if [ "$1" = rh ]; then
    G show "$R:$i/change.txt" > "$T/ch" 2>/dev/null || bad='no change.txt'
    [ -n "$bad" ] || bad=$(awk '/^migrates: *(yes|no)[ \t]*$/ { m = 1 } /^drops: *[^ ]/ { d = 1 } /^services: *[^ ]/ { s = 1 } END { if (!m) print "change.txt has no migrates: yes or no line"; else if (!d) print "change.txt has no drops: line, nor drops: none"; else if (!s) print "change.txt has no services: line, nor services: none" }' "$T/ch")
    case $o in
      passed) [ -n "$bad" ] || grep -qx 'sealed: *yes' "$T/rp" || bad='a passed rehearsal is not sealed: yes'; [ -n "$bad" ] || grep -q '^copy: *[^ ]' "$T/rp" || bad='a passed rehearsal has no copy: line'
        for x in restore migrate kept boot; do [ -n "$bad" ] || printf '%s\n' "$steps" | grep -qx "$x" || bad="deploy.xml has no $x step"; done   # 0.26.11.1.1 (R5): the kept step
        [ -n "$bad" ] || bad=$(awk -v DA=' — ' '/^kept:/ { n++; x = $0; sub(/^kept: */, "", x); sub(/[ \t]+$/, "", x); q = index(x, DA); l = q ? substr(x, 1, q - 1) : ""; r = q ? substr(x, q + length(DA)) : ""
            if (b == "" && (l == "" || r == "" || (l != "none" && r !~ /^[0-9]+ rows?$/))) b = "a kept: line is not <table> — <n> rows, nor none — <why>: " $0 }
          END { if (b == "" && !n) b = "a passed rehearsal has no kept: line"; print b }' "$T/rp") ;;
      'no backup yet') [ -z "$P" ] || [ "$P" = none ] || bad="no backup yet, though production runs $P" ;;
      failed\ ?*) case $pc in yes|no) ;; *) bad=${bad:-a failed rehearsal has no product change: yes or no line} ;; esac ;;
      *) bad=${bad:-report.txt has no outcome: passed, failed <step>, nor no backup yet} ;;
    esac
    [ -z "$bad" ] || { printf 'rh\trefused\t%s\t%s\n' "$k" "$bad"; return 0; }
    case $o in passed) printf 'rh\tpassed\t%s\n' "$k"; sed -n 's/^copy: *\([^ ]*\).*/copy\t\1/p' "$T/rp"; awk '/^signin: / && NF >= 3 { print "signin\t" $2 "\t" $3 }' "$T/rp"; sed -n 's/^kept: *\(.*[^[:space:]]\)[[:space:]]*$/kept\t\1/p' "$T/rp" ;;
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
  case $o in passed) printf 'd2\tpassed\t%s\n' "$k"; sed -n 's/^production: *\([^ ]*\).*/production\t\1/p' "$T/rp"; sed -n 's/^logs: *\(.*\)/logs\t\1/p' "$T/rp"
      DL2=$(dutl "$DUT2" "$CD/ask"); dd=$(duties "$i" "$DL2"); if [ "$dd" = none ]; then for x in $DL2; do printf 'duty\t%s\tmissing\t\n' "$x"; done; else printf '%s\n' "$dd" | grep '^duty' || true; fi ;;   # 0.26.11.1.1 (R3): never refused for its duties; a line in no form, or no duties.txt, reads as none
    *) printf 'd2\tfailed\t%s\t%s\t%s\n' "$k" "${o#failed }" "${pc:--}"; sed -n 's/^production: *\([^ ]*\).*/production\t\1/p' "$T/rp" ;; esac; }
CMD=${1:-}; [ $# -gt 0 ] && shift
case $CMD in
  cases) cases "${1:?}" ;;   # FB-3 A1.4: one results file's cases, for checks/review.sh's brief
  grade) cmd_grade "$@" ;; deploy) cmd_deploy "$@" ;;
  check) cmd_check "$@" ;; read) cmd_read "$@" ;; page) cmd_page "$@" ;; declare) cmd_declare "$@" ;; close) cmd_close "$@" ;; skipped) cmd_skipped "$@" ;; missing) cmd_missing "$@" ;; lacks) cmd_lacks "$@" ;; at) cmd_at "$@" ;; team) cmd_team "$@" ;;
  *) die 'usage — sh checks/results.sh check|read|page|declare|close|skipped|at|team …' ;;
esac

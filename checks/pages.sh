#!/bin/sh
# Purpose: ViD's pages (usability, B1 to B11): every document the owner is asked to read as one page, a local file
# always and a private claude.ai page when the session can make one. Each page's markdown is written to
# .vid/pages/<NAME>.md and rendered by the page.sh beside this script to .vid/pages/<NAME>.html; the call prints one
# line a page, `page: <title> | <the html file's full path> | <its link, or ->`, then the words that tell the session
# what to do about publishing (B9). The script publishes nothing itself; only the session can.
#   prd          the PRD (B2): the head's counts from prd.sh --report, the summary, the qualities, the features with
#                every requirement in its latest wording, the decisions (the owner's and ViD's apart), the open
#                questions, the appends as history, when it was agreed
#   foundation   BASELINE.md, ARCHITECTURE.md and DECISIONS.md as written (B3), each decision one line, ViD's proposals
#                marked, the hosting answers by name, the blocks for ViD's own checks folded
#   findings     the PRD's findings rows, grouped by what was done with them (B4)
#   tests        INVENTORY.md (B5): the head (N tests, to approve, not to read line by line; the counts by kind), what
#                needs the owner first (tests waiting on the owner's decision, owed ones with no class, the strength
#                check's open findings), the ways the product could be wrong, each test once in full by feature, the
#                rules, attacks and outside services, what is deliberately not tested, the grading checklist
#   cuts <folder>…   the cuts to choose from (B6): in each rung's scratch copy, what `stages.sh counts` prints, a
#                table a rung with "All stages" its sum, the largest stage in words, the ladder, the cards
#   stages       the committed cut (B6), the same table from the project's STAGES.md; the cuts leave the index
#   plan         the plan's page, made by `planner.sh page`, put into the index; rendered again from
#                .vid/plan/PLAN-PAGE.md when its html is gone (B7). It never runs planner.sh
#   book         the product book (B12, B13): the eight chapters, each its page's markdown made at that moment (the
#                idea is the seed, the design its screens and rulings, the plan .vid/plan/PLAN-PAGE.md), behind a
#                spine marking each written, waiting on you or not written yet; a sitting that waits (`face.sh
#                waiting` beside this script, the panel's) puts a note on its chapter and a mark by each item
#   all          every page whose document exists, then the book; `for <stop>` makes the book after its pages too
#   for <stop>   the pages due at that stop, 2 to 9 (B10)
#   link <page> <address>    records a page's published link, which must start https://claude.ai/ (B9)
#   publish yes|no --words "<what the owner said>"    records the owner's answer on publishing (B9)
# The index, .vid/pages/index: one line a page that exists, five tab-separated fields — id, title, the html's full
# path, the link or -, the stops it is due at (B10) or -; rewritten whole, by rename, at every call, a page whose file
# is gone left out. The answer on publishing and the links live in .vid/pagelinks, outside the pages folder, so
# removing the pages loses neither; neither is saved to the state repository. It writes only .vid/pages/ and
# .vid/pagelinks, changes no document it reads, and runs prd.sh, which writes nothing. A page whose document does not
# exist yet is not made: the call says so in one line and exits 0. Only where .vid/ exists. VID_PAGES_LIMIT (bytes,
# default 15 MB) is the size above which a page's line says it is too large to publish.
# Usage: sh <plugin>/checks/pages.sh prd|foundation|findings|tests|stages|plan|book|all | cuts <folder>… | for <stop> | link <page> <address> | publish yes|no --words "<words>"
# serves: both (usability)
set -eu
LC_ALL=C; export LC_ALL
GIT_OPTIONAL_LOCKS=0; export GIT_OPTIONAL_LOCKS
HERE=$(cd "$(dirname "$0")" && pwd -P); ME=$HERE/pages.sh
TAB=$(printf '\t')
ORDER='prd foundation findings tests cuts stages plan book'
say() { echo "ViD pages: $*"; }
refuse() { echo "ViD pages: refused — $*" >&2; exit 2; }
USAGE="sh $ME prd|foundation|findings|tests|stages|plan|book|all | cuts <folder>… | for <stop> | link <page> <address> | publish yes|no --words \"<words>\""
CMD=${1:-}
case $CMD in
  prd|foundation|findings|plan|all|tests|stages|book) ;;
  cuts) [ $# -gt 1 ] || refuse "the cuts need their folders: $USAGE" ;;
  for) case ${2:-} in [2-9]) ;; *) refuse "the stops are 2 to 9: $USAGE" ;; esac ;;
  link) case " $ORDER " in *" ${2:-none} "*) ;; *) refuse "no page '${2:-}': the pages are $ORDER" ;; esac
    case ${3:-} in https://claude.ai/*) ;; *) refuse "a link starts https://claude.ai/, so '${3:-}' is not recorded" ;; esac
    case ${3:-} in *[[:space:]]*) refuse 'a link holds no space, so it is not recorded' ;; esac ;;
  publish) case ${2:-} in yes|no) ;; *) refuse "the answer is yes or no: $USAGE" ;; esac
    [ "${3:-}" = --words ] && [ -n "${4:-}" ] || refuse "the owner's own words go with the answer: $USAGE" ;;
  *) refuse "$USAGE" ;;
esac
# usability (B6): the rungs' folders, by their full paths, before the call moves to the top of the repository
if [ "$CMD" = cuts ]; then shift; n=$#; i=0
  while [ $i -lt $n ]; do d=$1; shift; [ -d "$d" ] || refuse "no folder $d, so no page of the cuts"; set -- "$@" "$(cd "$d" && pwd -P)"; i=$((i + 1)); done; fi
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
[ -d "$TOP/.vid" ] || { say "no .vid/ in $TOP: not a ViD project, so no page is made"; exit 0; }
cd "$TOP"
P=.vid/pages; IDX=$P/index; LINKS=.vid/pagelinks; LIMIT=${VID_PAGES_LIMIT:-15728640}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
: > "$T/lines"; : > "$T/made"
NAME=$( { sed -n 's/^# //p' PRD.md 2>/dev/null || true; } | head -n 1 | sed -e 's/ — PRD$//' -e 's/ - PRD$//' | tr -d '\t')
[ -n "$NAME" ] || NAME=$(basename "$TOP")

# --- the index and the links (B1, B9) -----------------------------------------------------------------------------
stops_of() { case $1 in prd) echo 3,4,5,6,7,8 ;; findings) echo 5 ;; foundation) echo 6,7 ;; tests) echo 8,9 ;; cuts|stages) echo 9 ;; *) echo - ;; esac; }
link_of() { if [ -f "$LINKS" ]; then awk -F'\t' -v p="$1" '$1 == "link" && $2 == p { l = $3 } END { if (l != "") print l }' "$LINKS"; fi; }
# index_put [<id> <title> <html>]: the index rewritten whole — each line whose html is still there, the given page's
# line put in, each link read again from .vid/pagelinks, in the fixed order
index_put() {
  : > "$T/i0"
  if [ -f "$IDX" ]; then
    while IFS="$TAB" read -r id ti ht _l _s; do
      [ -n "$id" ] && [ -f "$ht" ] || continue; [ $# -eq 3 ] && [ "$id" = "$1" ] && continue; [ "$id" = "${DROP:-}" ] && continue
      printf '%s\t%s\t%s\n' "$id" "$ti" "$ht" >> "$T/i0"; done < "$IDX"; fi
  if [ $# -eq 3 ]; then printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$T/i0"; fi
  [ -s "$T/i0" ] || { rm -f "$IDX"; return 0; }
  mkdir -p "$P"; : > "$P/.index.$$"
  for o in $ORDER; do
    awk -F'\t' -v o="$o" '$1 == o' "$T/i0" | while IFS="$TAB" read -r id ti ht; do
      l=$(link_of "$id"); printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$ti" "$ht" "${l:--}" "$(stops_of "$id")"; done >> "$P/.index.$$"; done
  mv "$P/.index.$$" "$IDX"; }
# line <title> <html> <id>: the page's line, kept until the end of the call
line() { l=$(link_of "$3"); sz=$(wc -c < "$2" | tr -d ' ')
  if [ "$sz" -gt "$LIMIT" ]; then echo "page: $1 | $2 | ${l:--} | too large to publish: give the owner the path"
  else echo "page: $1 | $2 | ${l:--}"; fi >> "$T/lines"; }
# mk <id> <NAME> <title>: $T/<NAME>.md becomes .vid/pages/<NAME>.md, rendered, indexed, its line kept
# usability (B12): while the book is put together (BOOKING), the markdown is kept as the chapter's and nothing else
mk() { if [ -n "${BOOKING:-}" ]; then cp "$T/$2.md" "$T/ch-$1.md"; return 0; fi
  mkdir -p "$P"; cp "$T/$2.md" "$P/.$2.$$"; mv "$P/.$2.$$" "$P/$2.md"; echo "$1" >> "$T/made"
  sh "$HERE/page.sh" "$P/$2.md" > /dev/null; index_put "$1" "$3" "$TOP/$P/$2.html"; line "$3" "$TOP/$P/$2.html" "$1"; }
# advice: what the session does about publishing, by the owner's answer (B9)
advice() {
  a=''; if [ -f "$LINKS" ]; then a=$(awk -F'\t' '$1 == "publish" { a = $2 } END { print a }' "$LINKS"); fi
  case $a in
    # review fix 4: a page too large to publish is never told to be published
    yes) big=$(grep -c ' | too large to publish: ' "$T/lines" || true); all=$(grep -c . "$T/lines")
      if [ "$big" = "$all" ]; then echo "Give the owner each file's full path."
      elif [ "$big" -gt 0 ]; then echo "Publish each page above that is not too large to publish as a private page: at its link where it has one, as a new page where it has none. Record a new link with \`sh $ME link <page> <address>\`. Give the owner the link, and the file's full path of each page too large to publish. Where this session cannot publish, give the file's full path."
      else echo "Publish each page above as a private page: at its link where it has one, as a new page where it has none. Record a new link with \`sh $ME link <page> <address>\`. Give the owner the link. Where this session cannot publish, give the file's full path."; fi ;;
    no) echo "Give the owner each file's full path." ;;
    *) echo "Before anything is published, ask the owner this on its own, as a permission and never inside another answer: \"May ViD put this project's pages on private claude.ai pages, so you get a link? Only you can open them. Without it you get a local file.\" Record the answer with \`sh $ME publish yes|no --words \"<what the owner said>\"\`. Until then, give the owner each file's full path." ;;
  esac; }
# fresh <document>…: the line under the title, "As of …", then each document's last commit or "not committed yet"
fresh() { echo "As of $(date -u '+%Y-%m-%d %H:%M') UTC"; echo
  for f; do
    if [ ! -f "$f" ]; then echo "- \`$f\`: not written yet"; continue; fi
    h=$(git log -1 --format='%h %cd' --date=short -- "$f" 2>/dev/null || true)
    if [ -n "$h" ] && git diff --quiet HEAD -- "$f" 2>/dev/null; then echo "- \`$f\`: commit ${h% *} of ${h#* }"
    else echo "- \`$f\`: not committed yet"; fi; done; echo; }

# --- the PRD and its findings (B2, B4): one reading of PRD.md and prd.sh's own output -----------------------------
PRD_AWK='
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function fid(r,   x) { x = r; sub(/\|.*/, "", x); x = trim(x); sub(/[ \t]+AMENDED$/, "", x); return x }
function fld(r, n,   a) { split(r, a, "|"); return trim(a[n]) }
function lab(r, k,   n, a, i, f) { n = split(r, a, "|"); for (i = 2; i <= n; i++) { f = trim(a[i]); if (index(f, k ":") == 1) return trim(substr(f, length(k) + 2)) } return "" }
function low(s) { return tolower(s) }
function seen(id, r,   s) { s = lab(r, "shown"); return (s != "" && sub(/^pause-[0-9]+[ \t]+/, "", s) && (id in SM) && s == SM[id]) }
function said(id) { return (id in IR) ? (lab(IR[id], "plain") != "" ? lab(IR[id], "plain") : fld(IR[id], NPOS)) : "" }
function arms(s,   d, c, i, L, ch, o) { d = 0; c = ""; o = ""; i = 1; L = length(s)
  while (i <= L) { ch = substr(s, i, 1); if (ch == "(") d++; else if (ch == ")" && d > 0) d--
    if (d == 0) { if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { o = o "- " c "\n"; c = ""; i += 5; continue }
      if (substr(s, i, 4) == " or ") { o = o "- " c "\n"; c = ""; i += 4; continue } }
    c = c ch; i++ }
  return o "- " c "\n" }
function entry(id,   r, o) { r = IR[id]
  o = "{at: " low(id) "}\n**" said(id) "** {id: " id "}\n\n"
  if (id in FI) o = o "It fails if:\n\n" arms(FI[id]) "\n"
  if (fld(r, 3) == "T0") o = o "Must never break\n\n"
  if (lab(r, "authority") == "provisional") o = o "Rests on a ViD decision\n\n"
  return o }
function about(t,   n, a, i, x, o) { n = split(t, a, ","); o = ""
  for (i = 1; i <= n; i++) { x = trim(a[i]); if (x == "") continue; o = o (o == "" ? "" : "; ")
    if (x == "thesis") o = o "the summary"; else if (x == "seed") o = o "the owner'\''s first words"
    else if (x in IR) o = o "the requirement \"" said(x) "\" {id: " x "}"
    else if (x in CR) o = o "the quality \"" fld(CR[x], 2) "\" {id: " x "}"
    else if (x in FR) o = o "the feature \"" fld(FR[x], 3) "\" {id: " x "}"
    else if (x ~ /^INVENTORY\.md:/) { sub(/^INVENTORY\.md:/, "", x); o = o "a test of the list {id: " x "}" }
    else if (x in MR) o = o "how it works: \"" fld(MR[x], 3) "\" {id: " x "}"
    else if (x ~ /^A-[0-9]+$/) o = o "an answer {id: " x "}"
    else if (x ~ /^(design\/|[A-Za-z0-9_-]+\.md(:|$))/) o = o docname(x)
    else o = o "an item the PRD no longer holds {id: " x "}" }
  return o }
# 0.26.10.29.4: another document a finding names (INIT-FIXES-2 R6), in plain words, its part by its hidden id
function docname(x,   d, r) { d = x; r = ""; if (x !~ /^design\// && index(x, ":")) { d = substr(x, 1, index(x, ":") - 1); r = substr(x, index(x, ":") + 1) }
  d = (d == "INVENTORY.md") ? "the test list" : (d == "GRADING-CHECKLIST.md") ? "the grading checklist" : (d == "DESIGN-BRIEF.md" || d ~ /^design\//) ? "the design" : (d == "ARCHITECTURE.md") ? "the architecture" : (d == "DECISIONS.md") ? "the decisions" : (d == "BASELINE.md") ? "the baseline" : (d == "STAGES.md") ? "the stages" : "another document"
  return d ((r != "") ? " {id: " r "}" : (d == "another document" || x ~ /^design\//) ? " {id: " x "}" : "") }
FNR == 1 { file = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : (FILENAME == ARGV[3]) ? 3 : (FILENAME == ARGV[4]) ? 5 : 4 }
file == 5 { t = index($0, "\t"); if (t) SM[substr($0, 1, t - 1)] = substr($0, t + 1); next }
file == 1 { id = fid($0); if (id != "") { IR[id] = $0; IO[++NI] = id } next }
file == 2 { t = index($0, "\t"); if (t) FI[substr($0, 1, t - 1)] = substr($0, t + 1); next }
file == 3 { id = trim(fld($0, 1)); FC[id] = fld($0, 4); FT[id] = fld($0, 5); next }
file == 4 {
  if (inb == "" && $0 ~ /^# / && NAMEL == "") NAMEL = $0
  if (inb == "" && $0 ~ /^## /) { sec = substr($0, 4); if (sec == "Appends" || sec == "Ratifications" || sec == "Thesis") next }
  if (sec == "Appends") { if (inb == "" && $0 ~ /^### /) { APH[++NAP] = substr($0, 5); next } if (NAP) APB[NAP] = APB[NAP] $0 "\n" }
  if (sec == "Thesis") TH = TH $0 "\n"
  if (sec == "Ratifications" && $0 !~ /^[ \t]*$/) RAT = RAT $0 "\n"
  if (inb == "" && $0 ~ /^```vid-prd[a-z-]*[ \t]*$/) { inb = trim(substr($0, 4)); next }
  if (inb != "") { if ($0 ~ /^```/) { inb = ""; next } if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/) next; id = fid($0)
    if (inb == "vid-prd-contract") { if (!(id in CR)) CO[++NC] = id; CR[id] = $0 }
    else if (inb == "vid-prd-features") { if (!(id in FR)) FO[++NF2] = id; FR[id] = $0 }
    else if (inb == "vid-prd-answers") { if (!(id in AR)) AO[++NA] = id; AR[id] = $0 }
    else if (inb == "vid-prd-mechanisms") MR[id] = $0
    else if (inb == "vid-prd-findings") FD[++NFD] = $0
    next }
  if (match($0, /VID-QUESTION: \(OQ-[0-9]+\)/)) { q = substr($0, RSTART + 15, RLENGTH - 16); x = substr($0, RSTART + RLENGTH); x = trim(x)
    if (match(x, /^A-[0-9]+ — /)) x = substr(x, RLENGTH + 1)
    if (!(q in OPEN)) { OPEN[q] = 1; OQ[++NQ] = q; OT[q] = x } }
  next }
END {
  if (mode == "findings") {
    for (i = 1; i <= NFD; i++) { r = FD[i]; d = fld(r, 5); g = 4
      if (d == "") g = 1; else if (d ~ /^routed OQ-/) { q = d; sub(/^routed /, "", q); sub(/[^A-Z0-9-].*/, "", q); g = (q in OPEN) ? 1 : 4 }
      else if (d == "repaired") g = 2; else if (d ~ /^(overruled|accepted) A-/) g = 3
      ps = fld(r, 2); pw = (ps == "red-team") ? "the red team" : (ps == "audit") ? "the completeness audit" : (ps == "review") ? "the review" : (ps == "lens") ? "an expert reading" : (ps == "strength") ? "the strength check" : (ps == "final") ? "the final review" : ps
      sv = fld(r, 3); sw = (sv == "blocking") ? "Blocking" : (sv == "advisory") ? "Advisory" : sv
      ev = lab(r, "evidence"); if (ev == "") ev = "No detail was recorded."
      G[g] = G[g] "- **" sw "**, found by " pw ", about " about(fld(r, 4)) ": " ev " {id: " fid(r) "}\n"; GN[g]++ }
    print "Still open: " GN[1] + 0 " · Fixed: " GN[2] + 0 " · Your rulings: " GN[3] + 0 " · Noted: " GN[4] + 0 "\n"
    print "[[contents]]\n"
    split("Still open|Fixed|Your rulings|Noted", GH, "|")
    for (g = 1; g <= 4; g++) { print "## " GH[g] "\n"; printf "%s\n", (G[g] == "" ? "None.\n" : G[g]) }
    exit }
  print HEADL "\n"
  print "[[contents]]\n"
  print "## The summary\n"; printf "%s\n", TH
  print "## The qualities it must have\n"
  for (i = 1; i <= NC; i++) { r = CR[CO[i]]; if (lab(r, "status") ~ /^na owner/) continue; print "- **" fld(r, 2) "**: Needs it {id: " CO[i] "}" }
  for (i = 1; i <= NC; i++) { r = CR[CO[i]]; if (lab(r, "status") !~ /^na owner/) continue; print "- **" fld(r, 2) "**: Not needed (your ruling) {id: " CO[i] "}" }
  if (NC == 0) print "None are listed yet."
  print "\n## The features\n"
  if (!NI && BLOCKS != "") printf "::: fold The requirements, as written\n%s\n:::\n\n", BLOCKS
  for (i = 1; i <= NF2; i++) { f = FO[i]; h = fld(FR[f], 3); if (f in FC) { pd = FC[f]; sub(/^pilot demand /, "", pd); t0 = FT[f]; sub(/^T0 /, "", t0); h = h " — " pd (pd == 1 ? " requirement" : " requirements") " in the first version, " t0 " must never break" }
    print "::: fold " h " {id: " f "}\n"; for (j = 1; j <= NI; j++) if (lab(IR[IO[j]], "feature") == f) { printf "%s", entry(IO[j]); DONE[IO[j]] = 1 }; print ":::\n" }
  o = ""; for (j = 1; j <= NI; j++) if (!(IO[j] in DONE)) o = o entry(IO[j])
  if (o != "") printf "::: fold Beyond the features\n\n%s:::\n\n", o
  print "## Decisions\n\n### Yours\n"; n = 0
  for (i = 1; i <= NA; i++) { r = AR[AO[i]]; if (fld(r, 2) != "human") continue; print "- **" lab(r, "Q") "** " lab(r, "A") " {id: " AO[i] "}"; n++ }
  if (!n) print "None yet."
  print "\n### ViD'\''s\n"; n = 0
  for (i = 1; i <= NA; i++) { r = AR[AO[i]]; if (fld(r, 2) == "human") continue; print "- **" lab(r, "Q") "** " lab(r, "A") " (" (seen(AO[i], r) ? "you have seen this" : lab(r, "shown") != "" ? "changed since you saw it" : "not shown to you yet") ") {id: " AO[i] "}"; n++ }
  if (!n) print "None yet."
  print "\n## Open questions\n"
  for (i = 1; i <= NQ; i++) print "- " OT[OQ[i]] " {id: " OQ[i] "}"
  if (!NQ) print "None."
  if (NAP) { print "\n## History: what changed after the final wording was agreed\n\nWording here may have been replaced since. Parts 2 to 6 show what holds now.\n"
    for (i = 1; i <= NAP; i++) printf "::: fold %s\n%s\n:::\n\n", APH[i], APB[i] }
  if (RAT != "") printf "\n## When it was agreed\n\n%s", RAT }'
prd_md() {  # prd_md prd|findings: the page's markdown to $T/<NAME>.md
  : > "$T/eff"; : > "$T/fi"; : > "$T/fe"; BL=''
  if grep -q '^```vid-prd$' PRD.md; then
    sh "$HERE/prd.sh" --effective PRD.md > "$T/eff" 2>/dev/null || true
    sh "$HERE/prd.sh" --failifs PRD.md > "$T/fi" 2>/dev/null || true
  else BL=$(sh "$HERE/prd.sh" --effective PRD.md 2>/dev/null || true); fi
  # review fix 2: the grammar line as prd.sh reads it, above the first section only; without it five positions
  NP=5; [ -n "$(awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{print; exit}' PRD.md)" ] && NP=4
  # review fix 3: each ViD answer's sum, as prd.sh takes it (its A: words, white space collapsed, through cksum), so
  # "you have seen this" holds only while the shown: sum still matches what the answer says now
  : > "$T/sums"
  sed -n '/^```vid-prd-answers$/,/^```$/p' PRD.md | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id)
      t = $2; gsub(/^[ \t]+|[ \t]+$/, "", t); if (id !~ /^A-[0-9]+$/) next; a = ""
      for (i = 4; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (f ~ /^A:/) { sub(/^A:[ \t]*/, "", f); gsub(/[ \t\r]+/, " ", f); sub(/ $/, "", f); a = f; break } }
      if (!(id in R)) O[++n] = id; R[id] = (t == "model_proposed") ? a : ""; M[id] = (t == "model_proposed") }
    END { for (k = 1; k <= n; k++) if (M[O[k]]) print O[k] "\t" R[O[k]] }' > "$T/atext"
  while IFS="$TAB" read -r ai at; do printf '%s\t%s\n' "$ai" "$(printf '%s\n' "$at" | cksum | cut -d' ' -f1)" >> "$T/sums"; done < "$T/atext"
  if [ "$1" = prd ]; then
    # one run: --pause prints the pause material and then the very line --report prints
    { sh "$HERE/prd.sh" PRD.md --pause 2>/dev/null || true; } > "$T/pause"
    grep -E '^  FEAT-[0-9]+ \|' "$T/pause" > "$T/fe" || true
    R=$(grep '^prd:' "$T/pause" | tail -n 1 || true)
    rf() { printf '%s\n' "$R" | sed -n "s/.*[ (]$1=\([0-9][0-9]*\).*/\1/p"; }
    if [ -n "$R" ]; then HL="Requirements: $(rf demand) · Features: $(rf features) · Open questions: $(rf open-OQs) · Answers of yours: $(rf human) · Answers of ViD's: $(rf model) · Findings: $(rf findings)"
    else HL="No counts: the PRD's own check printed none."; fi
    N=PRD; TI="$NAME: the product"
  else HL=''; N=FINDINGS; TI="$NAME: the findings"; fi
  { printf '# %s\n\n' "$TI"; fresh PRD.md
    awk -v mode="$1" -v NPOS="$NP" -v HEADL="$HL" -v BLOCKS="$BL" "$PRD_AWK" "$T/eff" "$T/fi" "$T/fe" "$T/sums" PRD.md; } > "$T/$N.md"
}
page_prd() { [ -f PRD.md ] || { say "no PRD.md yet, so no page of the product"; return 0; }; prd_md prd; mk prd PRD "$NAME: the product"; }
page_findings() { [ -f PRD.md ] || { say "no PRD.md yet, so no page of its findings"; return 0; }; prd_md findings; mk findings FINDINGS "$NAME: the findings"; }

# --- the technical foundation (B3) ---------------------------------------------------------------------------------
FOUND_AWK='
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function closef() { if (pf) { print ":::"; print ""; pf = 0 } }
hosting { if ($0 ~ /^```[ \t]*$/) { hosting = 0; print ""; next } if ($0 !~ /^[ \t]*$/) print "- " trim($0); next }
inb { print; if ($0 ~ /^```[ \t]*$/) { inb = 0; if (vid) { print ":::"; print "" } } next }
inc { print; if (index($0, "-->")) { inc = 0; print "```"; print ":::"; print "" } next }
/^```vid-hosting[ \t]*$/ { closef(); print ""; hosting = 1; next }
/^```/ { closef(); inb = 1; vid = ($0 ~ /^```vid-/); if (vid) { print ""; print "::: fold For ViD'\''s checks" } print; next }
/^<!--/ { closef(); print ""; print "::: fold For ViD'\''s checks"; print "```"; print; if (index($0, "-->")) { print "```"; print ":::"; print "" } else inc = 1; next }
doc == "DECISIONS.md" && /^- \*\*D-[0-9]+\*\*/ { closef(); id = $0; sub(/^- \*\*/, "", id); sub(/\*\*.*/, "", id)
  rest = $0; sub(/^- \*\*D-[0-9]+\*\*[ \t]*/, "", rest); n = split(rest, a, "|"); why = ""; prop = 0
  for (i = 2; i <= n; i++) { f = trim(a[i]); if (f ~ /^why:/) why = trim(substr(f, 5)); if (f ~ /^origin:[ \t]*proposal/) prop = 1 }
  print "- " trim(a[1]) (why != "" ? " — why: " why : "") (prop ? " (ViD'\''s proposal)" : "") " {id: " id "}"; next }
/^#{1,3} / { closef(); print "#" $0; next }
doc == "DECISIONS.md" && !/^[ \t]*$/ && !pf { print ""; print "::: fold For ViD'\''s checks"; pf = 1 }
{ print }
END { closef() }'
page_foundation() {
  [ -f BASELINE.md ] || [ -f ARCHITECTURE.md ] || [ -f DECISIONS.md ] || { say "no BASELINE.md, ARCHITECTURE.md or DECISIONS.md yet, so no page of the technical foundation"; return 0; }
  { printf '# %s\n\n' "$NAME: the technical foundation"; fresh BASELINE.md ARCHITECTURE.md DECISIONS.md; printf '[[contents]]\n\n'
    for f in BASELINE.md ARCHITECTURE.md DECISIONS.md; do
      if [ -f "$f" ]; then awk -v doc="$f" "$FOUND_AWK" "$f"; echo; else printf '## %s\n\nNot written yet.\n\n' "${f%.md}"; fi; done; } > "$T/FOUNDATION.md"
  mk foundation FOUNDATION "$NAME: the technical foundation"; }

# --- the plan's page (B7): indexed, rendered again from its saved markdown, never made here -------------------------
page_plan() {
  if [ ! -f "$P/PLAN-PAGE.html" ]; then
    if [ -f .vid/plan/PLAN-PAGE.md ]; then sh "$HERE/page.sh" .vid/plan/PLAN-PAGE.md > /dev/null
    else say 'no plan page yet: /vid plan makes it'; index_put; return 0; fi; fi
  ti=''; [ -f .vid/plan/PLAN-PAGE.md ] && ti=$(sed -n 's/^# //p' .vid/plan/PLAN-PAGE.md | head -n 1 | tr -d '\t')
  [ -n "$ti" ] || ti="$NAME: the plan"
  index_put plan "$ti" "$TOP/$P/PLAN-PAGE.html"; line "$ti" "$TOP/$P/PLAN-PAGE.html" plan; }


# --- the test list (B5): every entry of INVENTORY.md once in full, what needs the owner first, approved, never read --
TESTS_AWK='
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function fid(r,   x) { x = r; sub(/\|.*/, "", x); x = trim(x); sub(/[ \t]+AMENDED$/, "", x); return x }
function fld(r, n,   a) { split(r, a, "|"); return trim(a[n]) }
function lab(r, k,   n, a, i, f) { n = split(r, a, "|"); for (i = 2; i <= n; i++) { f = trim(a[i]); if (index(f, k ":") == 1) return trim(substr(f, length(k) + 2)) } return "" }
function low(s) { return tolower(s) }
function islab(f) { return f ~ /^(origin|proved-red|paid-at|golden|divergence|law-changed|module|match|protects|disable|chosen|credentials|probe|evidence|quirks|paying-step):/ }
function kindw(k) { return k == "behavior" ? "a behaviour" : k == "surface" ? "a screen as drawn" : k == "journey" ? "a journey" : k == "shell" ? "the parts on every page" : k == "reachability" ? "a way to reach a screen" : k == "rule" ? "a rule checked across the product" : k == "hostility" ? "an attack tried" : k == "seam" ? "an outside service'\''s contract" : k }
function why(t) { sub(/^owed:[ \t]*/, "", t); return t }
function cls(t,   c) { t = why(t); if (t ~ /^paid by \/vid deploy gate/) return "deploy"; c = t; sub(/[ \t]+—.*/, "", c)
  return (c ~ /^(guard-first|census-armed|probe-capture|golden-set|fixture-source|prerequisite|spec-only|owner-decision|reverted)$/) ? c : "" }
function full(id,   o, x) { o = "{at: " low(id) "}\n**" TX[id] "** {id: " id "}\n\n"
  if (K[id] != "difference" && K[id] != "exception" && K[id] != "suppression") o = o "Kind: " kindw(K[id]) "\n\n"
  if (X[id] != "") { x = X[id]; while (match(x, /\001[^\002]*\002/)) x = substr(x, 1, RSTART - 1) refnow(substr(x, RSTART + 1, RLENGTH - 2)) substr(x, RSTART + RLENGTH); o = o x }
  if (TS[id] ~ /^owed:/) o = o "Not tested yet: " why(TS[id]) "\n\n"
  return o }
function link(id) { return (id in K) ? "[" TX[id] "](#" low(id) ")" : "No current entry {id: " id "}" }
# what the target of a finding names when it is no test: the summary, the first words of the owner, another document in
# plain words (its part by its hidden id), else a part of the PRD by its hidden id
function about(x,   d, r) { if (x == "thesis") return "the summary"; if (x == "seed") return "the first words of the owner"
  if (x ~ /^(design\/|[A-Za-z0-9_-]+\.md(:|$))/) { d = x; r = ""; if (x !~ /^design\// && index(x, ":")) { d = substr(x, 1, index(x, ":") - 1); r = substr(x, index(x, ":") + 1) }
    d = (d == "INVENTORY.md") ? "the test list" : (d == "GRADING-CHECKLIST.md") ? "the grading checklist" : (d == "DESIGN-BRIEF.md" || d ~ /^design\//) ? "the design" : (d == "ARCHITECTURE.md") ? "the architecture" : (d == "DECISIONS.md") ? "the decisions" : (d == "BASELINE.md") ? "the baseline" : (d == "STAGES.md") ? "the stages" : "another document"
    return d ((r != "") ? " {id: " r "}" : (d == "another document" || x ~ /^design\//) ? " {id: " x "}" : "") }
  return "a part of the PRD {id: " x "}" }
# review fix B2: an id the list or the PRD gives as a field reads in words, the id on request
function ref(x) { return "\001" x "\002" }   # read when the entry is shown, every entry known by then
function refnow(x,   n, a, i, o) { n = split(trim(x), a, /[, ]+/); for (i = 1; i <= n; i++) if (a[i] !~ /^[A-Z]+-[0-9]+$/) { n = 1; a[1] = x; break }   # ids by commas or spaces, as inventory.sh reads them; else the words whole
  o = ""; for (i = 1; i <= n; i++) { x = trim(a[i]); o = o (o == "" ? "" : ", ")
    o = o ((x in K) ? "[" TX[x] "](#" low(x) ")" : (x ~ /^(REQ|INV)-[0-9]+$/) ? "the requirement {id: " x "}" : (x ~ /^[A-Z]+-[0-9]+$/) ? "an entry no longer here {id: " x "}" : x) } return o }
FILENAME == EF { id = fid($0); if (id != "") FE[id] = lab($0, "feature"); next }
FILENAME == PR {
  if (inb == "" && $0 ~ /^```vid-prd[a-z-]*[ \t]*$/) { inb = trim(substr($0, 4)); next }
  if (inb != "") { if ($0 ~ /^```/) { inb = ""; next } if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/) next; id = fid($0)
    if (inb == "vid-prd-features") { if (!(id in FN)) FO[++NFO] = id; FN[id] = fld($0, 3) }
    else if (inb == "vid-prd-findings" && fld($0, 2) == "strength") SF[++NS] = $0
    next }
  if (match($0, /VID-QUESTION: \(OQ-[0-9]+\)/)) OPEN[substr($0, RSTART + 15, RLENGTH - 16)] = 1
  next }
FILENAME == IV {
  if (!ib && $0 ~ /^```vid-inventory[ \t]*$/) { ib = 1; next }
  if (!ib) next
  if ($0 ~ /^```/) { ib = 0; next }
  if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/ || $0 ~ /^grammar:/) next
  n = split($0, a, "|"); for (i = 1; i <= n; i++) a[i] = trim(a[i])
  if (a[1] ~ /^ROW-/) { id = a[1]; K[id] = a[2]; TX[id] = a[6]; TS[id] = a[8]; DR[id] = a[7]; P[id] = 4 }
  else { id = a[2]; k = a[1]; K[id] = k; X[id] = ""; TS[id] = ""
    if (k == "rule") { e = n; while (e > 3 && islab(a[e])) e--; TS[id] = a[e]; c = a[4]; for (i = 5; i <= e - 2; i++) c = c " | " a[i]
      TX[id] = a[3]; X[id] = "Checked over: " c "\n\n"; P[id] = 5 }
    else if (k == "hostility") { TX[id] = a[3]; for (i = 4; i <= n; i++) if (!islab(a[i])) { TS[id] = a[i]; break }
      X[id] = "It protects: " ref(lab($0, "protects")) "\n\nTo try it, take away: " lab($0, "disable") "\n\n"; P[id] = 5 }
    else if (k == "seam") { TX[id] = a[3] " — " a[4]; X[id] = "Probe: " lab($0, "probe") "\n\nEvidence: " lab($0, "evidence") "\n\n"
      if (lab($0, "probe") == "owed") TS[id] = "owed: probe: owed"; P[id] = 5 }
    else if (k == "difference") { TX[id] = a[3]; X[id] = "In the tests: " a[4] "\n\nIn the product: " a[5] "\n\nWhy it is safe: " a[6] "\n\n"
      if (lab($0, "paying-step") != "") X[id] = X[id] "Checked for real at: " lab($0, "paying-step") "\n\n"; P[id] = 6 }
    else if (k == "exception") { TX[id] = a[3]; X[id] = "Not under: " ref(a[4]) "\n\nWhy: " a[5] "\n\n"; P[id] = 6 }
    else if (k == "suppression") { TX[id] = a[3]; X[id] = "Not yet checked by: " ref(a[4]) "\n\nWhy: " a[5] "\n\nUntil: " a[6] "\n\n"; P[id] = 6 }
    else { TX[id] = $0; P[id] = 6 } }
  IO[++NI] = id; next }
FILENAME == GC { if ($0 ~ /^# /) next; if ($0 ~ /^#{2,3} /) $0 = "#" $0; GCT = GCT $0 "\n"; next }
END {
  # where each test of part 4 goes: the feature of the first requirement it names
  for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] != 4) continue; F[id] = ""
    n = split(DR[id], dd, ","); for (j = 1; j <= n; j++) { x = trim(dd[j]); if (x ~ /^(REQ|INV)-/) { if ((x in FE) && (FE[x] in FN)) F[id] = FE[x]; break } } }
  N = 0; for (i = 1; i <= NI; i++) if (P[IO[i]] == 4 || P[IO[i]] == 5) { N++; KC[K[IO[i]]]++ }
  print "This list has " N " tests. You are asked to approve it, not to read every line.\n"
  o = "Behaviours: " KC["behavior"] + 0 " · Screens as drawn: " KC["surface"] + 0 " · Journeys: " KC["journey"] + 0 " · The parts on every page: " KC["shell"] + 0 " · Ways to reach a screen: " KC["reachability"] + 0 " · Rules: " KC["rule"] + 0 " · Attacks tried: " KC["hostility"] + 0 " · Outside services: " KC["seam"] + 0
  ot = N - KC["behavior"] - KC["surface"] - KC["journey"] - KC["shell"] - KC["reachability"] - KC["rule"] - KC["hostility"] - KC["seam"]
  print o (ot > 0 ? " · Other kinds: " ot : "") "\n"
  print "[[contents]]\n"
  print "## Look here first\n"; nl = 0
  for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] == 6 || K[id] == "seam" || TS[id] !~ /^owed:/) continue; c = cls(TS[id]); if (c != "owner-decision" && c != "") continue
    print "- " link(id) " — Not tested yet: " why(TS[id]); nl++ }
  for (i = 1; i <= NS; i++) { r = SF[i]; d = fld(r, 5); op = (d == ""); if (d ~ /^routed OQ-/) { q = d; sub(/^routed /, "", q); sub(/[^A-Z0-9-].*/, "", q); op = (q in OPEN) }
    # review fixes B1, B4, B5: each finding sorted by its own row (open, repaired, the rest: ruled on or noted); "No
    # current entry" only for a target that names the list, the id on request
    t = fld(r, 4); ev = lab(r, "evidence"); if (ev == "") ev = "No detail was recorded."
    # 0.26.10.29.4: the target as the strength check writes it (INIT-FIXES-3 R1): one entry, or every entry of a
    # disagreement comma-separated, each a test (INVENTORY.md:<id>), a part of the PRD, or another document by its name
    nt = split(t, TP, /[ \t]*,[ \t]*/); ab = ""; alltests = 1
    for (j = 1; j <= nt; j++) { x = trim(TP[j]); if (x == "") continue
      if (x ~ /^INVENTORY\.md:/) { sub(/^INVENTORY\.md:/, "", x); w = link(x) }
      else { alltests = 0; w = about(x) }
      ab = ab (ab == "" ? "" : ", ") w }
    AB[i] = ((alltests && ab != "") ? ((nt > 1) ? "the tests it is about: " : "the test it is about: ") : "what it is about: ") ab
    ST[i] = op ? 0 : (d == "repaired") ? 1 : 2; SW[i] = op ? "Nothing catches this yet" : (d == "repaired") ? "Repaired" : (d ~ /^(overruled|accepted) /) ? "Your ruling" : "Noted"; EV[i] = ev
    if (op) { print "- Nothing catches this yet: " ev " — " AB[i]; nl++ } }
  if (!NS) { print (nl ? "\n" : "") "No finding of ViD'\''s strength check is recorded for this list." }
  else if (!nl) print "Nothing here waits on you."
  print ""
  if (NS) { print "## Ways the product could be wrong\n"
    for (s = 0; s <= 2; s++) for (i = 1; i <= NS; i++) if (ST[i] == s) print "- " EV[i] " — " AB[i] " — " SW[i]
    print "" }
  print "## By feature\n"
  for (f = 1; f <= NFO + 1; f++) { fe = (f <= NFO) ? FO[f] : ""; o = ""; n = 0
    for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] == 4 && F[id] == fe) { o = o full(id); n++ } }
    if (n) printf "::: fold %s — %d %s\n\n%s:::\n\n", (fe == "" ? "Across the whole product" : FN[fe]), n, (n == 1 ? "test" : "tests"), o }
  print "## Rules checked across the product, and the attacks tried\n"
  split("rule|hostility|seam", KS, "|"); split("Rules checked across the product|Attacks tried|Outside services", KH, "|")
  for (k = 1; k <= 3; k++) { o = ""; n = 0; for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] == 5 && K[id] == KS[k]) { o = o full(id); n++ } }
    if (n) printf "::: fold %s — %d %s\n\n%s:::\n\n", KH[k], n, (n == 1 ? "test" : "tests"), o }
  print "## What is deliberately not tested\n"; m = 0
  split("exception|suppression|difference", KS, "|"); split("Where a rule does not apply|What a check cannot see yet|Where the tests stand in for the real thing", KH, "|")
  for (k = 1; k <= 3; k++) { o = ""; for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] == 6 && K[id] == KS[k]) o = o full(id) }
    if (o != "") { printf "::: fold %s\n\n%s:::\n\n", KH[k], o; m++ } }
  o = ""; for (i = 1; i <= NI; i++) { id = IO[i]; if (P[id] == 6 && K[id] != "exception" && K[id] != "suppression" && K[id] != "difference") o = o full(id) }
  if (o != "") { printf "::: fold Other entries\n\n%s:::\n\n", o; m++ }
  if (!m) print "Nothing.\n"
  print "## The grading checklist\n"; printf "%s\n", (GCT == "" ? "No grading checklist yet.\n" : GCT) }'
page_tests() {
  [ -f INVENTORY.md ] || { say "no INVENTORY.md yet, so no page of the tests"; return 0; }
  : > "$T/teff"; [ -f PRD.md ] && { sh "$HERE/prd.sh" --effective PRD.md > "$T/teff" 2>/dev/null || true; }
  PRF=PRD.md; [ -f PRD.md ] || PRF="$T/teff"; GCF=GRADING-CHECKLIST.md; [ -f "$GCF" ] || { : > "$T/gc"; GCF="$T/gc"; }
  { printf '# %s\n\n' "$NAME: the tests"; fresh INVENTORY.md GRADING-CHECKLIST.md PRD.md
    awk -v EF="$T/teff" -v PR="$PRF" -v IV=INVENTORY.md -v GC="$GCF" "$TESTS_AWK" "$T/teff" "$PRF" INVENTORY.md "$GCF"; } > "$T/TESTS.md"
  mk tests TESTS "$NAME: the tests"; }

# --- the stage cut (B6): the cuts to choose from, then the committed cut ------------------------------------------
# counts_in <dir>: stages.sh counts in that folder, its own checks/ where it has one
counts_in() { ( cd "$1" && if [ -f checks/stages.sh ]; then sh checks/stages.sh counts; else sh "$HERE/stages.sh" counts; fi ) 2>/dev/null | grep '^stage ' || true; }
# rung <section> <dir>: a section, a row a stage as stages.sh prints it, All stages the sum, the largest stage in
# words, the cards folded; its ladder line kept in $T/ladder
rung() { counts_in "$2" > "$T/cn"
  awk -F'|' -v sec="$1" -v lad="$T/ladder" '
    { s = $1; nm = $0; sub(/^[^|]*\| /, "", nm); if (nm == "-") nm = "One stage"
      k = s; sub(/^stage /, "", k); sub(/ .*/, "", k); q = s; sub(/.* requirements=/, "", q); sub(/ .*/, "", q); w = s; sub(/.* rows=/, "", w); sub(/ .*/, "", w)
      R[++n] = "| " k " | " nm " | " q " | " w " |"; sq += q; sw += w; if (n == 1 || w + 0 > bx) { bx = w + 0; bn = nm } }
    END { print "## " sec "\n"
      if (!n) { print "No stage could be counted here.\n"; exit }
      print "The largest stage is " bn ": " bx " of " sw " tests.\n"
      print "| Stage | Name | Requirements | Tests |"; print "|---|---|---|---|"; for (i = 1; i <= n; i++) print R[i]; print "| | All stages | " sq " | " sw " |"; print ""
      printf "| %s | %d | %s | %d of %d |\n", sec, n, bn, bx, sw >> lad }' "$T/cn"
  if [ -f "$2/STAGES.md" ]; then awk '/^## Stage / { if (on) print ":::\n"; on = 1; print "::: fold " substr($0, 4) "\n"; next }
    /^## / { if (on) print ":::\n"; on = 0; next } on { print } END { if (on) print ":::\n" }' "$2/STAGES.md"; fi; }
page_cuts() {
  for d; do [ -d "$d" ] || refuse "no folder $d, so no page of the cuts"; done
  : > "$T/ladder"; : > "$T/rungs"
  for d; do rung "$(basename "$d")" "$d" >> "$T/rungs"; done
  { printf '# %s\n\n' "$NAME: the cuts to choose from"; fresh; printf '[[contents]]\n\n'
    if [ $# -gt 1 ]; then printf '## The ladder\n\n| Rung | Stages | The largest stage | Tests |\n|---|---|---|---|\n'; cat "$T/ladder"; echo; fi
    cat "$T/rungs"; } > "$T/CUTS.md"
  mk cuts CUTS "$NAME: the cuts to choose from"; }
# cuts_open: the cuts page stands in the index. Its line leaves only when `pages.sh stages` is called by name (the
# pick: "the choice is made"), or when `pages.sh cuts` writes a new one; `for` and `all` never
# take it out
cuts_open() { [ -f "$IDX" ] && awk -F"\t" '$1 == "cuts"' "$IDX" | grep -q . && [ -f "$P/CUTS.md" ]; }
page_stages() {   # page_stages [byname]
  if [ ! -f STAGES.md ]; then
    if [ "${1:-}" = byname ]; then say 'no STAGES.md: the project keeps one stage, so the cuts to choose from are closed'; DROP=cuts; index_put; DROP=''
    else say "no STAGES.md yet, so no page of the stages"; fi; return 0; fi
  : > "$T/ladder"; rung 'The stages' . > "$T/rungs"
  { printf '# %s\n\n' "$NAME: the stages"; fresh STAGES.md PRD.md INVENTORY.md; printf '[[contents]]\n\n'; cat "$T/rungs"; } > "$T/STAGES.md"
  [ "${1:-}" = byname ] && DROP=cuts; mk stages STAGES "$NAME: the stages"; DROP=''; }

# --- the product book (B12, B13): every page in one, in the order the project is defined -----------------------------
BOOKCH='The idea|The product|The technical foundation|The design|The tests|The stages|The plan|The findings'
# chapter <n>: the chapter's markdown to $T/ch-<n>.md, or nothing when its document is not written: a page made in
# this call is taken as it was made; any other is made again here, kept as the chapter and nowhere else
# amends: the amendment record's rows, read as design-join.sh reads them (words after the fence, blank and # lines
# skipped)
amends() { sed -n '/^```vid-design-amendments/,/^```$/p' DESIGN-AMENDMENT-BRIEF.md | sed '1d;$d' | grep -v '^[[:space:]]*$' | grep -v '^[[:space:]]*#' || true; }
chapter() { CHF=$T/ch-$1.md; rm -f "$CHF"
  case $1 in
    # review fix 1: the seed as prd.sh reads it, the `## Seed` section, or after consolidation the file a header line
    # `Seed: <file> (sha256 …)` names
    1) SP=''; [ ! -f PRD.md ] || SP=$(awk '/^## /{exit} /^Seed:[ \t]+[^ \t]+[ \t]+\(sha256 [0-9a-f]+\)/{print; exit}' PRD.md)
       if [ -n "$SP" ]; then SF=$(printf '%s\n' "$SP" | sed -E 's/^Seed:[ \t]+([^ \t]+).*/\1/')
         if [ -f "$SF" ]; then { printf '# %s\n\n' "$NAME: the idea"; cat "$SF"; } > "$CHF"; fi
       elif [ -f PRD.md ] && grep -q '^## Seed$' PRD.md; then { printf '# %s\n\n' "$NAME: the idea"; awk '/^## Seed$/ { on = 1; next } on && /^## / { exit } on' PRD.md; } > "$CHF"; fi ;;
    4) if [ -f DESIGN-BRIEF.md ]; then { printf '# %s\n\n' "$NAME: the design"; fresh DESIGN-BRIEF.md DESIGN-AMENDMENT-BRIEF.md
        printf '## The screens and their states\n\n'
        printf '| Screen | State |\n|---|---|\n'   # one row a state, as the manifest has them
        sed -n '/^```vid-design-manifest/,/^```$/p' DESIGN-BRIEF.md | sed '1d;$d' | grep -v '^[[:space:]]*$' | grep -v '^#' | awk -F'|' '{ s = $1; t = $2; gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", t); if (s == "" || s ~ /^#/) next
            n++; print "| " s " | " t " |" } END { if (!n) print "No screen is listed yet." }'
        printf '\n## The rulings\n\n'
        if [ -f DESIGN-AMENDMENT-BRIEF.md ] && amends | grep -q .; then
          amends | sed 's/^/- /'
        else echo 'No ruling is recorded.'; fi; } > "$CHF"; fi ;;
    6) if cuts_open; then cp "$P/CUTS.md" "$CHF"; elif [ -f STAGES.md ]; then chapter_of stages STAGES; mvch stages; fi ;;
    7) [ ! -f .vid/plan/PLAN-PAGE.md ] || cp .vid/plan/PLAN-PAGE.md "$CHF" ;;
    2) chapter_of prd PRD; mvch prd ;; 3) chapter_of foundation FOUNDATION; mvch foundation ;; 5) chapter_of tests TESTS; mvch tests ;; 8) chapter_of findings FINDINGS; mvch findings ;;
  esac
  return 0; }
mvch() { [ ! -f "$T/ch-$1.md" ] || mv "$T/ch-$1.md" "$CHF"; }
chapter_of() { if grep -qx "$1" "$T/made" && [ -f "$P/$2.md" ]; then cp "$P/$2.md" "$T/ch-$1.md"
  else BOOKING=1; make_one "$1" quiet > /dev/null; BOOKING=''; fi; }
# waiting: the sitting that waits on the owner, from the panel's face.sh beside this script (`face.sh waiting`, its
# spec's P9): its chapter (the stop's: 2 to 5 the product, 6 the foundation, 7 the design, 8 the tests, 9 the stages),
# its title, its items' ids (an id joining two with ~ is both); nothing when face.sh prints nothing or fails
waiting() { WCH=0; WN=0; : > "$T/witems"; WTI=''
  # read only on success: a face.sh without `waiting` (or any failure) means no sitting waits, whatever it printed
  if sh "$HERE/face.sh" waiting > "$T/wait" 2>/dev/null; then :; else : > "$T/wait"; fi
  head -n 1 "$T/wait" | grep -q "^[^$TAB]*$TAB[0-9][0-9]*$TAB" || : > "$T/wait"
  [ -s "$T/wait" ] || return 0
  ws=$(head -n 1 "$T/wait" | cut -f2); WTI=$(head -n 1 "$T/wait" | cut -f3)
  case $ws in 2|3|4|5) WCH=2 ;; 6) WCH=3 ;; 7) WCH=4 ;; 8) WCH=5 ;; 9) WCH=6 ;; *) WCH=0; return 0 ;; esac
  WN=$(sed -n '2,$p' "$T/wait" | grep -c . || true)
  sed -n '2,$p' "$T/wait" | cut -f1 | tr '~' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep . > "$T/witems" || true; }
page_book() {
  waiting
  # review fix 2: each chapter ends with a line break, whatever its source ends with, so none runs into the next
  for n in 1 2 3 4 5 6 7 8; do chapter "$n"; f=$T/ch-$n.md; if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then echo >> "$f"; fi; done
  { printf '# %s\n\n' "$NAME: the product book"; fresh
    printf '## The chapters\n\n'
    for n in 1 2 3 4 5 6 7 8; do nm=$(echo "$BOOKCH" | cut -d'|' -f"$n")
      if [ "$n" = "$WCH" ]; then st='Waiting on you'; elif [ -f "$T/ch-$n.md" ]; then st=Written; else st='Not written yet'; fi
      printf -- '- [%s](#chapter-%s) — %s\n' "$nm" "$n" "$st"; done; echo
    for n in 1 2 3 4 5 6 7 8; do nm=$(echo "$BOOKCH" | cut -d'|' -f"$n"); printf '{chapter: %s}\n' "$n"
      if [ -f "$T/ch-$n.md" ]; then
        if [ "$n" = "$WCH" ]; then awk -v ti="$WTI" -v wn="$WN" -v items="$T/witems" 'BEGIN { while ((getline l < items) > 0) I[l] = 1 }
            { o = ""; s = $0; while (match(s, /\{id: [^}]*\}/)) { x = substr(s, RSTART + 5, RLENGTH - 6); o = o substr(s, 1, RSTART + RLENGTH - 1) ((x in I) ? " {!}" : ""); s = substr(s, RSTART + RLENGTH) } print o s
              if (NR == 1) print "!!! Waiting on you: " ti ", " wn " items. Answer in the panel or in the chat." }' "$T/ch-$n.md"
        else cat "$T/ch-$n.md"; fi
      else case $n in 1) w='the interview' ;; 2|8) w='the summary' ;; 3) w='the technical hints' ;; 4) w='the design' ;; 5) w='the test list' ;; 6) w='the releases' ;; esac
        printf '# %s\n\n' "$nm"
        if [ "$n" = 7 ]; then echo 'Not written yet: it comes when the plan is made, after the releases.'
        else echo "Not written yet: it comes at $w."; fi
        if [ "$n" = "$WCH" ]; then echo; echo "!!! Waiting on you: $WTI, $WN items. Answer in the panel or in the chat."; fi; fi; done; } > "$T/BOOK.md"
  mk book BOOK "$NAME: the product book"; }
make_one() { case $1 in prd) page_prd ;; foundation) page_foundation ;; findings) page_findings ;; plan) page_plan ;; tests) page_tests ;; stages) page_stages ;; book) page_book ;; esac; }
# from_index <id>: a page this call cannot make again, printed from its index line
from_index() { if [ -f "$IDX" ]; then awk -F'\t' -v p="$1" '$1 == p' "$IDX" | while IFS="$TAB" read -r id ti ht _l _s; do line "$ti" "$ht" "$id"; done; fi; }

index_put   # a page whose file is gone leaves the index at every call
case $CMD in
  link)
    mkdir -p "$P"; { if [ -f "$LINKS" ]; then awk -F'\t' -v p="$2" '!($1 == "link" && $2 == p)' "$LINKS"; fi; printf 'link\t%s\t%s\n' "$2" "$3"; } > "$P/.links.$$"
    mv "$P/.links.$$" "$LINKS"; index_put; say "the link of $2 is recorded: $3"; exit 0 ;;
  publish)
    w=$(printf '%s' "$4" | tr '\t\n' '  ')
    mkdir -p "$P"; { if [ -f "$LINKS" ]; then awk -F'\t' '$1 != "publish"' "$LINKS"; fi; printf 'publish\t%s\t%s\t%s\n' "$2" "$w" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; } > "$P/.links.$$"
    mv "$P/.links.$$" "$LINKS"; say "the owner's answer on publishing is recorded: $2"; exit 0 ;;
  all) for p in prd foundation findings tests stages plan; do make_one "$p" quiet; done; page_book ;;
  for)
    case $2 in 2) ids='' ;; 3|4) ids=prd ;; 5) ids='prd findings' ;; 6|7) ids='prd foundation' ;; 8) ids='tests prd' ;; 9) ids='cuts tests' ;; esac
    for p in $ids; do
      if [ "$p" = cuts ]; then if cuts_open; then from_index cuts; fi; [ ! -f STAGES.md ] || make_one stages quiet
      else make_one "$p" quiet; fi; done
    page_book ;;   # usability (B12): the book after the pages, at every stop
  cuts) page_cuts "$@" ;;
  stages) page_stages byname ;;
  *) make_one "$CMD" ;;
esac
if [ -s "$T/lines" ]; then cat "$T/lines"; advice; fi
exit 0

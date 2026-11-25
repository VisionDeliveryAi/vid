#!/bin/sh
# Purpose: ViD's PRD writer (FB-1 A2) — a sitting's rulings applied to PRD.md as data, beside checks/prd-consolidate.sh,
# the other script that writes PRD.md. It reads an edits file, one operation a line from the closed list below, applies
# the operations in order to a copy beside PRD.md, runs checks/prd.sh on the copy (plain, never --before: that is the
# consolidation's check that the mechanism rows stay the same, and a sitting may rule on a mechanism) and replaces PRD.md
# only when the court passes. Otherwise it writes nothing, prints the court's gaps and exits 1. A malformed edits file,
# or an operation the PRD refuses, exits 2 and writes nothing.
# An id's block is told by its prefix, as the court tells it: A- the answers, DIM- the contract, MECH- the mechanisms,
# FEAT- the features, F- the findings, every other id the items.
#   row <full row>                      replace the row with that id in place, or add it at its block's end
#   field <id> <label> [<value>]        set one `<label>: <value>` field, added at the row's end; no value drops it
#   after <id> / row … / end            add those rows after that row
#   drop <id>                           remove a row
#   text / <old lines> / -- / <new lines> / end   replace text outside the machine blocks; the old text occurs once
#   shown pause-<N>                     label each ViD decision the court's --pause lists as not shown, with its sum
#   append "<source>" ["review: …"] / row … / end   one section `### <date> (<source>)` under ## Appends, its
#                                       `carrier VID-QUESTION: (OQ-<n>) <question>` lines open carriers above its blocks
#   ratified <scope> <sha>              one Ratifications line, `- <date> — <scope> — <sha>`
#   resolve OQ-<n> A-<NNN>              the carrier rewritten `RESOLVED: (OQ-n) A-NNN — <its question>`
#   findings "<heading>" ["review: …"] / row F-NN … / end   write or extend that `### ` heading under ## Findings
#   review "<line>"                     set the newest append section's review: line
# Where: the base is everything above ## Appends. Before the final ratification (a Ratifications line whose scope is
# `final`) row, field, after, drop and text act on the base; after it they act on the newest append section alone: an
# id held only elsewhere is refused (restate it there as `<id> AMENDED | …`) and text is refused. append, review,
# resolve, ratified and findings act in both.
# Usage: sh checks/prd-apply.sh [PRD.md] <edits file> [--date YYYY-MM-DD]   (today, UTC, when not given; never after it, FB-5 C1)
# serves: both (FB-1 A2)
set -eu
NL='
'
usage() { echo 'ViD prd-apply: usage — sh checks/prd-apply.sh [PRD.md] <edits file> [--date YYYY-MM-DD]' >&2; exit 2; }
PRD=./PRD.md; ED=''; DATE=''; n=0; A1=''
while [ $# -gt 0 ]; do
  case $1 in --date) [ $# -ge 2 ] || usage; DATE=$2; shift 2 ;; -*) usage ;; *) n=$((n + 1)); if [ "$n" -gt 1 ]; then ED=$1; else A1=$1; fi; shift ;; esac
done
case $n in 1) ED=$A1 ;; 2) PRD=$A1 ;; *) usage ;; esac
TD=$(date -u +%Y-%m-%d); [ -n "$DATE" ] || DATE=$TD
# FB-5 C1: a date after today (UTC) is refused, its year, month and day compared as numbers
! awk -v d="$DATE" -v t="$TD" 'function n(x,   a) { split(x, a, "-"); return a[1] * 10000 + a[2] * 100 + a[3] } BEGIN { exit !(n(d) > n(t)) }' || { echo "ViD prd-apply: refused — --date $DATE is after today, $TD (UTC): leave --date out, and today is written — nothing written." >&2; exit 2; }
[ -f "$PRD" ] || { echo "ViD prd-apply: '$PRD' missing." >&2; exit 1; }
[ -f "$ED" ] || { echo "ViD prd-apply: the edits file '$ED' is missing — nothing written." >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd); COURT="$HERE/prd.sh"
[ -f "$COURT" ] || { echo "ViD prd-apply: $COURT missing — the court gates every write." >&2; exit 1; }
# the copy sits beside PRD.md, so that the court finds the files the PRD points at (its Seed: file)
W="$(cd "$(dirname "$PRD")" && pwd)/.prd-apply.$$"; trap 'rm -f "$W" "$W.n" "$W.c" "$W.s"' EXIT
cp "$PRD" "$W"
PA_OP=''; PA_A=''; PA_B=''; PA_C=''; PA_D=$DATE; PA_E=''; export PA_OP PA_A PA_B PA_C PA_D PA_E
# The engine: one operation (PA_OP, its texts in PA_A to PA_D, read from the environment so no backslash is taken as an
# escape) on the copy, printed whole; a refusal exits 2.
ENG='function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function head1(r,   i) { i = index(r, "|"); if (i) r = substr(r, 1, i - 1); return trim(r) }
function rid(r) { r = head1(r); sub(/[ \t]+AMENDED$/, "", r); return r }
function kind(id) { if (id ~ /^A-/) return "vid-prd-answers"; if (id ~ /^DIM-/) return "vid-prd-contract"; if (id ~ /^MECH-/) return "vid-prd-mechanisms"
  if (id ~ /^FEAT-/) return "vid-prd-features"; if (id ~ /^F-/) return "vid-prd-findings"; return "vid-prd" }
function die(m) { print "ViD prd-apply: " m " — nothing written." > "/dev/stderr"; exit 2 }
function out(i) { return !K[i] && !FO[i] && !FC[i] }
function isrow(i, k) { return K[i] == k && L[i] !~ /^[ \t]*(#|$)/ }
function find(id, k,   i) { for (i = R1; i <= R2; i++) if (isrow(i, k) && rid(L[i]) == id) return i; return 0 }
function region() { if (FINAL && !A1) die("the PRD is ratified final and has no append section — open one with append first") }
function elsewhere(r,   id, k, i) { id = rid(r); k = kind(id); if (!FINAL || head1(r) ~ /[ \t]AMENDED$/) return
  for (i = 1; i <= n; i++) if ((i < R1 || i > R2) && isrow(i, k) && rid(L[i]) == id)
    die(id " stands outside the newest append section, and the PRD is ratified final — restate it there as an AMENDED row, " id " AMENDED | …") }
function lastfc(a, b, k,   i) { for (i = b; i >= a; i--) if (FC[i] == k) return i; return 0 }
function lastline(a, b) { while (b > a && L[b] ~ /^[ \t]*$/) b--; return b }
function secend(h,   i) { for (i = h + 1; i <= n; i++) if (L[i] ~ /^## / && out(i)) return i - 1; return n }
function rvline(a, b,   i) { for (i = a; i <= b; i++) if (out(i) && L[i] ~ /^review:/) return i; return 0 }
function addrow(r,   k, j, p) { k = kind(rid(r)); j = lastfc(R1, R2, k)
  if (j) { INSB[j] = INSB[j] r "\n"; return }
  if (!FINAL) die(k == "vid-prd-findings" ? "a new finding of a review is written with findings \"<heading>\"" : "the base holds no ```" k " block")
  p = R1; for (j = R1; j <= R2; j++) if (FC[j] != "") p = j
  INSA[p] = INSA[p] "\n```" k "\n" r "\n```\n" }
{ L[++n] = $0 }
END {
  OP = ENVIRON["PA_OP"]; A = ENVIRON["PA_A"]; B = ENVIRON["PA_B"]; C = ENVIRON["PA_C"]; D = ENVIRON["PA_D"]; E = ENVIRON["PA_E"]; fen = ""; sec = ""
  for (i = 1; i <= n; i++) { l = L[i]
    if (fen != "") { if (l == "```") { FC[i] = fen; fen = "" } else K[i] = fen; continue }
    if (l ~ /^```/) { fen = substr(l, 4); FO[i] = (fen == "" ? "-" : fen); continue }
    if (l ~ /^## /) { sec = l; if (l == "## Appends" && !APP) APP = i; if (!(l in SH)) SH[l] = i }
    if (APP && i > APP && l ~ /^### /) A1 = i
    if (sec == "## Ratifications" && l ~ /^- / && split(l, P, " — ") >= 3 && trim(P[2]) == "final") FINAL = 1 }
  A2 = 0; if (A1) { A2 = secend(A1); for (i = A1 + 1; i <= A2; i++) if (L[i] ~ /^### / && out(i)) { A2 = i - 1; break } }
  if (FINAL) { R1 = A1; R2 = A2 } else { R1 = 1; R2 = APP ? APP - 1 : n }
  if (OP == "row") { region(); i = find(rid(A), kind(rid(A))); if (i) REP[i] = A; else { elsewhere(A); addrow(A) } }
  else if (OP == "field") { region(); i = find(A, kind(A)); if (!i) { elsewhere(A); die("no row " A " to set " B ": on") }
    m = split(L[i], P, "|"); o = P[1]; done = 0
    for (j = 2; j <= m; j++) { t = trim(P[j])
      if (!done && index(t, B ":") == 1) { done = 1; if (C == "") continue; P[j] = " " B ": " C (j < m ? " " : "") }
      o = o "|" P[j] }
    if (!done && C != "") o = o " | " B ": " C
    sub(/[ \t]+$/, "", o); REP[i] = o }
  else if (OP == "after") { region(); i = find(A, kind(A)); if (!i) { elsewhere(A); die("no row " A " to add rows after") }
    m = split(C, P, "\n"); for (j = 1; j <= m; j++) { if (P[j] == "") continue
      if (kind(rid(P[j])) != kind(A)) die(rid(P[j]) " is not a row of the block " A " stands in")
      if (find(rid(P[j]), kind(A))) die(rid(P[j]) " is there already — row replaces a row in place")
      elsewhere(P[j]); INSA[i] = INSA[i] P[j] "\n" } }
  else if (OP == "drop") { region(); i = find(A, kind(A)); if (!i) { elsewhere(A); die("no row " A " to drop") } DEL[i] = 1 }
  else if (OP == "text") {
    if (FINAL) die("text edits the base, and the PRD is ratified final — an append carries the change")
    if (A == "") die("text names no old text")
    S = ""; for (i = 1; i <= n; i++) S = S L[i] "\n"
    c = 0; off = 0; rest = S; while ((k = index(rest, A)) > 0) { c++; if (c == 1) pos = off + k; off += k; rest = substr(rest, k + 1) }
    if (c != 1) die("the old text of a text edit occurs " c " times — it must occur exactly once")
    t = substr(S, 1, pos - 1); s0 = gsub(/\n/, "", t) + 1; t = A; s1 = s0 + gsub(/\n/, "", t)
    for (i = s0; i <= s1; i++) { if (K[i] ~ /^vid-prd/ || FO[i] ~ /^vid-prd/ || FC[i] ~ /^vid-prd/) die("the old text of a text edit reaches into a machine block — row, field, after and drop edit rows")
      if (APP && i >= APP) die("the old text of a text edit stands below ## Appends — text edits the base") }
    printf "%s", substr(S, 1, pos - 1) B substr(S, pos + length(A)); exit 0 }
  else if (OP == "append") { if (!APP) die("the PRD has no ## Appends section")
    p = lastline(APP, secend(APP)); s = "\n### " D " (" A ")\n"
    m = split(E, P, "\n"); for (j = 1; j <= m; j++) if (P[j] != "") s = s "\n" P[j] "\n"
    split("vid-prd-answers vid-prd-features vid-prd-mechanisms vid-prd-contract vid-prd vid-prd-findings", KS, " ")
    m = split(C, P, "\n"); for (q = 1; q <= 6; q++) { b = ""; for (j = 1; j <= m; j++) if (P[j] != "" && kind(rid(P[j])) == KS[q]) b = b P[j] "\n"
      if (b != "") s = s "\n```" KS[q] "\n" b "```\n" }
    if (B != "") s = s "\n" B "\n"; INSA[p] = INSA[p] s }
  else if (OP == "ratified") { if (!("## Ratifications" in SH)) die("the PRD has no ## Ratifications section")
    h = SH["## Ratifications"]; p = 0; e = secend(h); for (i = h + 1; i <= e; i++) if (L[i] ~ /^- /) p = i
    if (p) INSA[p] = INSA[p] "- " D " — " A " — " B "\n"; else INSA[h] = INSA[h] "\n- " D " — " A " — " B "\n" }
  else if (OP == "resolve") { p = 0; c = 0; t = "VID-QUESTION: (" A ")"
    for (i = 1; i <= n; i++) if (out(i) && index(L[i], t) == 1) { p = i; c++ }
    if (c != 1) die(c " open carriers " A " — resolve rewrites exactly one")
    q = trim(substr(L[p], length(t) + 1)); sub(/^A-[0-9]+ — /, "", q); REP[p] = "RESOLVED: (" A ") " B " — " q }
  else if (OP == "findings") { if (!("## Findings" in SH)) die("the PRD has no ## Findings section")
    m = split(C, P, "\n"); b = ""
    for (j = 1; j <= m; j++) if (P[j] != "") { if (kind(rid(P[j])) != "vid-prd-findings") die(rid(P[j]) " is not a finding (F-NN)"); b = b P[j] "\n" }
    f1 = SH["## Findings"]; f2 = secend(f1); h = 0
    for (i = f1 + 1; i <= f2; i++) if (out(i) && L[i] ~ /^### / && trim(substr(L[i], 5)) == A) h = i
    if (!h) { p = lastline(f1, f2); INSA[p] = INSA[p] "\n### " A "\n" (b != "" ? "\n```vid-prd-findings\n" b "```\n" : "") (B != "" ? "\n" B "\n" : "") }
    else { e = f2; for (i = h + 1; i <= f2; i++) if (out(i) && L[i] ~ /^### /) { e = i - 1; break }
      j = lastfc(h, e, "vid-prd-findings"); r = rvline(h, e)
      if (b != "" && j) INSB[j] = INSB[j] b
      else if (b != "") { j = lastline(h, e); INSA[j] = INSA[j] "\n```vid-prd-findings\n" b "```\n" }
      if (B != "" && r) REP[r] = B; else if (B != "") { if (!j) j = lastline(h, e); INSA[j] = INSA[j] "\n" B "\n" } } }
  else if (OP == "review") { if (!A1) die("the PRD has no append section to carry a review: line")
    r = rvline(A1, A2); if (r) REP[r] = A; else { p = lastline(A1, A2); INSA[p] = INSA[p] "\n" A "\n" } }
  else die("unknown operation " OP)
  for (i = 1; i <= n; i++) { if (i in INSB) printf "%s", INSB[i]; if (!(i in DEL)) print ((i in REP) ? REP[i] : L[i]); if (i in INSA) printf "%s", INSA[i] }
}'
eng() { PA_OP=$1; if LC_ALL=C awk "$ENG" "$W" > "$W.n"; then mv "$W.n" "$W"; else exit 2; fi; }
ln=0; mode=top; op=''; cbuf=''; NOPS=0
bad() { echo "ViD prd-apply: $ED line $ln: $* — nothing written." >&2; exit 2; }
quoted() { # $1 the rest of a line after its opening quote → Q1, and Q2, the optional second quoted text (a review: line)
  case $1 in *\"*) ;; *) bad 'an unclosed quote' ;; esac; Q1=${1%%\"*}; _r=${1#"$Q1"\"}; Q2=''
  case $_r in '') ;; ' "'*'"') Q2=${_r#' "'}; Q2=${Q2%\"} ;; *) bad 'after the quoted text, nothing or one more quoted text' ;; esac
  case $Q1$Q2 in *\"*) bad 'a quote inside a quoted text' ;; esac; [ -n "$Q1" ] || bad 'an empty quoted text'
  [ -z "$Q2" ] || case $Q2 in 'review: '?*) ;; *) bad 'the second quoted text is a review: line' ;; esac; }
while IFS= read -r l || [ -n "$l" ]; do
  ln=$((ln + 1))
  case $mode in
  rows) case $l in end) PA_C=$buf; PA_E=$cbuf; eng "$op"; PA_E=''; mode=top ;; 'row '?*) buf=$buf${l#row }$NL ;;
    'carrier VID-QUESTION: (OQ-'*) [ "$op" = append ] || bad "inside $op, a row line or end: a carrier line belongs to append alone"
      c=${l#carrier }; r=${c#'VID-QUESTION: (OQ-'}; q=${r#*') '}
      case ${r%%')'*} in ''|*[!0-9]*) bad 'carrier VID-QUESTION: (OQ-<n>) <question>' ;; esac; [ -n "$q" ] && [ "$q" != "$r" ] || bad 'carrier VID-QUESTION: (OQ-<n>) <question>'
      cbuf=$cbuf$c$NL ;; *) bad "inside $op, a row line or end" ;; esac; continue ;;
  old) if [ "$l" = -- ]; then mode=new; on=0; PA_B=''; elif [ "$on" = 1 ]; then PA_A=$PA_A$NL$l; else PA_A=$l; on=1; fi; continue ;;
  new) if [ "$l" = end ]; then eng text; mode=top; elif [ "$on" = 1 ]; then PA_B=$PA_B$NL$l; else PA_B=$l; on=1; fi; continue ;;
  esac
  [ -n "$l" ] || continue
  NOPS=$((NOPS + 1)); PA_A=''; PA_B=''; PA_C=''
  case $l in
  'row '?*) PA_A=${l#row }; eng row ;;
  'field '*) r=${l#field }; PA_A=${r%% *}; r=${r#"$PA_A"}; r=${r# }; PA_B=${r%% *}; PA_C=${r#"$PA_B"}; PA_C=${PA_C# }
    case $PA_A in ''|*[!A-Za-z0-9_-]*) bad 'field <id> <label> [<value>]' ;; esac
    case $PA_B in ''|*[!A-Za-z0-9_-]*) bad 'field <id> <label> [<value>]' ;; esac; eng field ;;
  'after '?*) PA_A=${l#after }; op=after; buf=''; mode=rows ;;
  'drop '?*) PA_A=${l#drop }; eng drop ;;
  text) op=text; mode=old; on=0 ;;
  'shown pause-'*) N=${l#shown pause-}; case $N in ''|*[!0-9]*) bad 'shown pause-<N>' ;; esac
    sh "$COURT" "$W" --pause 2>&1 | sed -n 's/^GAP  join 20 (\(A-[0-9][0-9]*\)):.* label it shown: pause-N \([0-9][0-9]*\)\.$/\1 \2/p' > "$W.s" || true
    while read -r PA_A s; do PA_B=shown; PA_C="pause-$N $s"; eng field; done < "$W.s" ;;
  'append "'*) quoted "${l#append \"}"; PA_A=$Q1; PA_B=$Q2; op=append; buf=''; cbuf=''; mode=rows ;;
  'findings "'*) quoted "${l#findings \"}"; PA_A=$Q1; PA_B=$Q2; op=findings; buf=''; mode=rows ;;
  'review "review: '?*'"') PA_A=${l#review \"}; PA_A=${PA_A%\"}; eng review ;;
  'ratified '?*' '?*) r=${l#ratified }; PA_B=${r##* }; PA_A=${r% *}; eng ratified ;;
  'resolve OQ-'*' A-'*) r=${l#resolve }; PA_A=${r%% *}; PA_B=${r#* }
    case ${PA_A#OQ-}/${PA_B#A-} in *[!0-9/]*|/*|*/) bad 'resolve OQ-<n> A-<NNN>' ;; esac; eng resolve ;;
  *) bad "'${l%% *}' is no operation of the list — row, field, after, drop, text, shown, append, ratified, resolve, findings, review" ;;
  esac
done < "$ED"
[ "$mode" = top ] || bad "the file ends inside $op — it closes with end"
if sh "$COURT" "$W" > "$W.c" 2>&1; then
  mv "$W" "$PRD"; echo "ViD prd-apply: $NOPS operation(s) applied; checks/prd.sh passes; $PRD written."; exit 0
fi
echo "ViD prd-apply: refused — checks/prd.sh does not pass on the result; nothing written." >&2
grep '^GAP' "$W.c" >&2 || cat "$W.c" >&2
exit 1

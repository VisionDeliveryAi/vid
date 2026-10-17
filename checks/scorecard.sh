#!/bin/sh
# Purpose: ViD PRD scorecard, the counted half (v0.9.5 part B, R1-R2, R5;
# phase A). Scores a PRD on the nine qualities the owner agreed (2026-09-24)
# with counts only: exact, repeatable, no model. It never convicts, never
# edits the PRD, and exits 0 whatever it finds; it is information for the
# owner at pauses 2 and 3, not a gate. The judged half (the reader, phase B)
# classes the candidates this script lists at the end.
# Reads the PRD's effective item rows and answers (checks/prd.sh
# --effective, and the answers block, latest row per id), the pause
# material of `checks/prd.sh --pause` (near-duplicate pairs, features with
# no demand item, join 19's untraced values under grammar 0.9.4 or later),
# and, with --previous, the previous version's rows and answers: the PRD as
# shown at pause 2 when scoring pause 3, the last ratified PRD after
# ratification. Ids are compared as ids — within one project they persist
# (the effective-set law); two unrelated PRDs are not a previous version.
# Flags only what should be zero (contradictions and losses are the
# reader's): duplicates, rules gone or weaker than in the previous version,
# untraced values, demand items with no fail-if, rules with no plain
# sentence; and one bar the owner approved in 0.9.4 (bar 4, builder
# settings over 20% of ViD decisions), which is judged, so it is the
# reader's. Every other number is shown, never ranged: no size is fixed
# across projects (owner ruling B3).
# Rules are demand items (functional, nfr, ux_flow, data_entity) and
# invariants. Tier order: T0 (must never break) above T1 above T2.
# --candidates <file> also writes the reader's candidate list (phase C):
# `<n> | <quality> | <target> | <text>`, one line per candidate, in the
# order faithful (each rule with an owner answer it cites), honest (each ViD
# decision), complete (each previous rule gone or weaker), coherent (each
# near-duplicate pair), right-grained (each demand item whose fail-if has
# several clauses), testable and product-level (each demand item).
# --tally <candidates> <reader output> counts the reader's classes per
# quality and flags what should be zero (contradicts, lost, weakened,
# duplicate, not observable) and builder settings over 20% of ViD decisions
# (0.9.4 bar 4), with the measured agreement from the reader's brief when
# the plugin's skills/ sits beside this checks/. It judges nothing itself.
# Usage: sh checks/scorecard.sh [PRD.md] [--previous <file>] [--candidates <file>]
#        sh checks/scorecard.sh --tally <candidates> <reader output>
set -u
IFS='
'
PRD=./PRD.md; PREV=''; CANDS=''
HERE=$(cd "$(dirname "$0")" && pwd)
if [ "${1:-}" = --tally ]; then
  [ $# -eq 3 ] && [ -f "$2" ] && [ -f "$3" ] || { echo 'ViD scorecard: --tally <candidates> <reader output>' >&2; exit 2; }
  BRIEF="$HERE/../skills/vid-create-prd/scorecard-reader.md"; [ -f "$BRIEF" ] || BRIEF=/dev/null
  awk -F'|' '
    function trim(s) { gsub(/^[ \t*]+|[ \t*]+$/, "", s); return s }
    FILENAME == ARGV[1] { if ($0 ~ /^\| [a-z-]+ \| [a-z ]+ \| [0-9]+ of [0-9]+ \|$/) { AG[trim($2) "/" trim($3)] = trim($4) } next }
    FILENAME == ARGV[2] { n = trim($1); if (n !~ /^[0-9]+$/) next; Q[n] = trim($2); TG[n] = trim($3); qs[trim($2)] = 1; next }
    { n = trim($1); if (n !~ /^[0-9]+$/ || !(n in Q)) next; c = tolower(trim($2)); if (c in seenc) {} ; K[Q[n] "/" c]++; if (!((Q[n] "/" c) in LI)) ord[++no] = Q[n] "/" c; LI[Q[n] "/" c] = LI[Q[n] "/" c] " " TG[n]; GOT[n] = 1 }
    END { for (n in Q) { tot++; if (!(n in GOT)) { miss++; ml = ml " " n } }
      printf "scorecard, the judged half (the reader'"'"'s classes, counted; agreement is the reader'"'"'s measured hit rate on hand labels, not a limit)\n"
      for (i = 1; i <= no; i++) { k = ord[i]; split(k, kk, "/"); a = (k in AG) ? AG[k] " agreed" : "not yet checked against hand labels"
        printf "%-14s| judged  | %s=%d (%s)\n", kk[1], kk[2], K[k], a }
      hd = K["honest/builder setting"] + 0; ht = 0; for (k in K) if (index(k, "honest/") == 1) ht += K[k]
      fl = ""; split("faithful/contradicts coherent/contradicts complete/lost complete/weakened coherent/duplicate testable/not observable", z, " ")
      for (k in K) if (k ~ /contradicts$|\/lost$|\/weakened$|\/duplicate$|not observable$/) fl = fl ", " k " " K[k] ":" LI[k]
      if (ht > 0 && hd * 100 > ht * 20) fl = fl ", builder settings " hd " of " ht " ViD decisions, over 20% (0.9.4 bar 4)"
      if (miss > 0) fl = fl ", candidates the reader did not answer " miss ":" ml
      sub(/^, /, "", fl); printf "judged flags: %s\n", (fl == "") ? "none" : fl }' "$BRIEF" "$2" "$3"
  exit 0
fi
while [ $# -gt 0 ]; do case "$1" in
  --candidates) [ $# -ge 2 ] || { echo 'ViD scorecard: --candidates needs a file.' >&2; exit 2; }; CANDS=$2; shift 2 ;;
  --previous) [ $# -ge 2 ] || { echo 'ViD scorecard: --previous needs a file.' >&2; exit 2; }; PREV=$2; shift 2 ;;
  --*) echo "ViD scorecard: unknown flag '$1' — the flags are --previous <file>, --candidates <file>, --tally." >&2; exit 2 ;;
  *) PRD=$1; shift ;; esac; done
[ -f "$PRD" ] || { echo "ViD scorecard: no PRD at $PRD." >&2; exit 2; }
[ -z "$PREV" ] || [ -f "$PREV" ] || { echo "ViD scorecard: no previous version at $PREV." >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
if ! grep -q '^```vid-prd$' "$PRD"; then
  if grep -q '^### REQ-' "$PRD"; then echo 'scorecard: not scored — a legacy block-form PRD (### REQ- headings); consolidate it to rows first.'
  else echo 'scorecard: no items yet (the pause-1 PRD) — nothing to score.'; fi
  exit 0
fi
T=$(mktemp -d "${TMPDIR:-/tmp}/vid-scorecard.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT INT TERM

npos() { g=$(awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{print; exit}' "$1"); [ -n "$g" ] && echo 4 || echo 5; }
answers() { sed -n '/^```vid-prd-answers$/,/^```$/p' "$1" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
sh "$HERE/prd.sh" --effective "$PRD" > "$T/cur.rows"
answers "$PRD" > "$T/cur.ans"
NPC=$(npos "$PRD")
if [ -n "$PREV" ] && grep -q '^```vid-prd' "$PREV"; then
  sh "$HERE/prd.sh" --effective "$PREV" > "$T/prev.rows"; answers "$PREV" > "$T/prev.ans"; NPP=$(npos "$PREV"); HASPREV=yes
else : > "$T/prev.rows"; : > "$T/prev.ans"; NPP=4; HASPREV=no; fi
[ -n "$PREV" ] || PREV=none
# the pause material: its counts, never its verdict (the court runs at the commit)
sh "$HERE/prd.sh" "$PRD" --pause > "$T/pause.out" 2>/dev/null || true
NEAR=$(sed -n 's/^near-duplicates (.*): \([0-9][0-9]*\)$/\1/p' "$T/pause.out" | head -n 1)
FNOITEM=$(sed -n 's/^features with no demand item: \([0-9][0-9]*\)$/\1/p' "$T/pause.out" | head -n 1)
NFEAT=$(sed -n 's/^features: \([0-9][0-9]*\)$/\1/p' "$T/pause.out" | head -n 1)
G094=$(sed -n 's/.* grammar=\([0-9.a-z]*\) .*/\1/p' "$T/pause.out" | head -n 1 | awk -F. '$0=="legacy"{print "no";exit} {split("0.9.4",w,"."); for(i=1;i<=3;i++){a=$i+0; if(a>w[i]+0){print "yes";exit} if(a<w[i]+0){print "no";exit}} print "yes"}')
G095=$(sed -n 's/.* grammar=\([0-9.a-z]*\) .*/\1/p' "$T/pause.out" | head -n 1 | awk -F. '$0=="legacy"{print "no";exit} {split("0.9.5",w,"."); for(i=1;i<=3;i++){a=$i+0; if(a>w[i]+0){print "yes";exit} if(a<w[i]+0){print "no";exit}} print "yes"}')
UNTRACED=$(grep -c '^GAP  join 19' "$T/pause.out" || true)
[ "$G094" = yes ] || UNTRACED='- (join 19 applies from grammar 0.9.4)'
WORDS=$(wc -w < "$PRD" | tr -d ' ')

awk -F'|' -v npc="$NPC" -v npp="$NPP" -v hasprev="$HASPREV" -v prev="$PREV" -v near="${NEAR:--}" \
    -v fnoitem="${FNOITEM:--}" -v nfeat="${NFEAT:-0}" -v untraced="$UNTRACED" -v words="$WORDS" -v g095="$G095" '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function lab(f, n, key,   i, x) { for (i = n + 1; i <= f; i++) { x = trim($i); if (index(x, key ":") == 1) return trim(substr(x, length(key) + 2)) } return "" }
  function has(f, n, key,   i, x) { for (i = n + 1; i <= f; i++) { x = trim($i); if (index(x, key ":") == 1) return 1 } return 0 }
  function isrule(t) { return t == "functional" || t == "nfr" || t == "ux_flow" || t == "data_entity" || t == "invariant" }
  function isdemand(t) { return t == "functional" || t == "nfr" || t == "ux_flow" || t == "data_entity" }
  function tnum(t) { return (t ~ /^T[0-9]$/) ? substr(t, 2) + 0 : 9 }
  function arms(s,   d, i, c, L, n) { n = 1; d = 0; L = length(s)
    for (i = 1; i <= L; i++) { c = substr(s, i, 1)
      if (c == "(") d++; else if (c == ")" && d > 0) d--
      if (d == 0) { if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { n++; i += 4; continue }
                    if (substr(s, i, 4) == " or ") { n++; i += 3; continue } } }
    return n }
  function aid(s) { s = trim(s); sub(/[ \t]+AMENDED$/, "", s); return s }
  function atext(f,   i, x) { for (i = 3; i <= f; i++) { x = trim($i); if (index(x, "A:") == 1) return trim(substr(x, 3)) } return "" }
  FILENAME ~ /cur\.rows$/ { id = trim($1); if (id == "") next; t = trim($2); CT[id] = t; CI[id] = trim($3); ci[++nc] = id
    if (isdemand(t)) { ND++; if (!has(NF, npc, "fail-if")) NOFI++
      else { fi_ = lab(NF, npc, "fail-if"); k = arms(fi_); if (k > 1) { MULTI++; mc = mc " " id "(" k ")" } } }
    if (isrule(t)) { NRULE++; if (!has(NF, npc, "plain")) NOPL++ }
    au = lab(NF, npc, "authority"); if (au == "authoritative") { NAUTH++
      src = lab(NF, npc, "source"); n = split(src, e, ","); only = (n > 0)
      for (j = 1; j <= n; j++) { x = trim(e[j]); if (x !~ /^(seed|thesis)/) only = 0 } if (only) SEEDONLY++ }
    src = lab(NF, npc, "source"); CS[id] = src
    next }
  FILENAME ~ /prev\.rows$/ { id = trim($1); if (id == "") next; PT[id] = trim($2); PI[id] = trim($3); pi_[++np] = id; if (isdemand(PT[id])) PND++; next }
  FILENAME ~ /cur\.ans$/ { id = aid($1); if (id !~ /^A-[0-9]+$/) next; if (!(id in CAW)) co[++nca] = id; CAW[id] = trim($2); CAA[id] = atext(NF); next }
  FILENAME ~ /prev\.ans$/ { id = aid($1); if (id !~ /^A-[0-9]+$/) next; if (!(id in PAW)) po[++npa] = id; PAW[id] = trim($2); PAA[id] = atext(NF); next }
  END {
    for (i = 1; i <= nca; i++) { a = co[i]; if (CAW[a] == "model_proposed") { VD++; vd = vd " " a; if (hasprev == "yes" && !(a in PAW)) VDN++ } else if (CAW[a] == "human") NH++
      if (hasprev == "yes") {
        if (!(a in PAW) && CAW[a] == "human") { ADD++; add = add " " a }
        else if ((a in PAW) && PAW[a] == "model_proposed" && CAW[a] == "human") { PRO++; pro = pro " " a }
        else if ((a in PAW) && PAW[a] == "human" && CAW[a] == "human" && PAA[a] != CAA[a]) { CHG++; chg = chg " " a } } }
    for (i = 1; i <= nc; i++) { id = ci[i]; n = split(CS[id], e, ","); hit = 0
      for (j = 1; j <= n; j++) { x = trim(e[j]); if ((x in CAW) && CAW[x] == "human") hit = 1 }
      if (hit && isrule(CT[id])) { FC++; fc = fc " " id } }
    for (i = 1; i <= np; i++) { id = pi_[i]; if (!isrule(PT[id])) continue
      if (!(id in CT)) { GONE++; gone = gone " " id "(" PI[id] ")" }
      else if (tnum(CI[id]) > tnum(PI[id])) { WEAK++; weak = weak " " id "(" PI[id] "→" CI[id] ")" } }
    none = "-"; dash = (hasprev == "yes") ? 0 : none
    printf "scorecard (checks/scorecard.sh, the counted half; the reader judges the candidates below) · previous: %s\n", prev
    printf "faithful      | counted | owner-record changes since the previous version (neutral: the owner'"'"'s rulings make them): added=%s promoted=%s changed=%s · untraced values=%s\n", \
      (hasprev == "yes") ? ADD + 0 : none, (hasprev == "yes") ? PRO + 0 : none, (hasprev == "yes") ? CHG + 0 : none, untraced
    printf "honest        | counted | ViD decisions=%d (new since the previous version=%s) · owner answers=%d\n", VD, (hasprev == "yes") ? VDN + 0 : none, NH
    printf "complete      | counted | features with no demand item=%s · previous rules gone=%s · previous rules weaker=%s\n", fnoitem, (hasprev == "yes") ? GONE + 0 : none, (hasprev == "yes") ? WEAK + 0 : none
    printf "coherent      | counted | near-duplicate pairs=%s\n", near
    printf "product-level | judged  | the reader classes each requirement\n"
    printf "right-grained | counted | demand items whose fail-if has more than one clause=%d\n", MULTI
    printf "testable      | counted | demand items with no fail-if=%d\n", NOFI
    gr = "-"; if (hasprev == "yes" && PND > 0) gr = sprintf("%+d (%+.0f%%)", ND - PND, (ND - PND) * 100 / PND)
    printf "proportionate | counted | requirements=%d · features=%d · per feature=%s · growth since the previous version=%s · authoritative resting only on seed or thesis=%d of %d\n", \
      ND, nfeat, (nfeat > 0) ? sprintf("%.1f", ND / nfeat) : "-", gr, SEEDONLY, NAUTH
    pl = (g095 == "yes") ? sprintf("%d of %d", NOPL, NRULE) : "- (plain sentences apply from grammar 0.9.5)"
    printf "reviewable    | counted | items=%d · words=%d · rules with no plain sentence=%s\n", nc, words, pl
    fl = ""
    if (near != "-" && near + 0 > 0) fl = fl ", near-duplicate pairs " near
    if (GONE > 0) fl = fl ", previous rules gone " GONE
    if (WEAK > 0) fl = fl ", previous rules weaker " WEAK
    if (untraced ~ /^[0-9]+$/ && untraced + 0 > 0) fl = fl ", untraced values " untraced
    if (NOFI > 0) fl = fl ", demand items with no fail-if " NOFI
    if (g095 == "yes" && NOPL > 0) fl = fl ", rules with no plain sentence " NOPL
    if (fnoitem != "-" && fnoitem + 0 > 0) fl = fl ", features with no demand item " fnoitem
    sub(/^, /, "", fl); printf "flags: %s\n", (fl == "") ? "none" : fl
    print "candidates for the reader:"
    printf "  faithful (rules citing an owner answer): %d%s\n", FC, fc
    printf "  honest (ViD decisions):%s\n", (vd == "") ? " none" : vd
    printf "  complete (previous rules gone):%s\n", (gone == "") ? " none" : gone
    printf "  complete (previous rules weaker):%s\n", (weak == "") ? " none" : weak
    printf "  right-grained (fail-ifs with several clauses):%s\n", (mc == "") ? " none" : mc
    if (hasprev == "yes") { printf "  owner-record changes: added%s · promoted%s · changed%s\n", (add == "") ? " none" : add, (pro == "") ? " none" : pro, (chg == "") ? " none" : chg }
  }' "$T/cur.rows" "$T/prev.rows" "$T/cur.ans" "$T/prev.ans"
sed -n '/^near-duplicates (/,/^[a-z]/p' "$T/pause.out" | sed '1d;$d' | sed 's/^/  coherent (near-duplicate pair): /'
if [ -n "$CANDS" ]; then
  sed -n '/^near-duplicates (/,/^[a-z]/p' "$T/pause.out" | sed '1d;$d' | sed -n 's/^[[:space:]]*\([A-Z]*-[0-9]*\) ~ \([A-Z]*-[0-9]*\) .*/\1 \2/p' > "$T/pairs"
  awk -F'|' -v npc="$NPC" -v npp="$NPP" -v hasprev="$HASPREV" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function lab(f, n, key,   i, x) { for (i = n + 1; i <= f; i++) { x = trim($i); if (index(x, key ":") == 1) return trim(substr(x, length(key) + 2)) } return "" }
    function isrule(t) { return t == "functional" || t == "nfr" || t == "ux_flow" || t == "data_entity" || t == "invariant" }
    function isdemand(t) { return t == "functional" || t == "nfr" || t == "ux_flow" || t == "data_entity" }
    function tnum(t) { return (t ~ /^T[0-9]$/) ? substr(t, 2) + 0 : 9 }
    function arms(s,   d, i, c, L, n) { n = 1; d = 0; L = length(s)
      for (i = 1; i <= L; i++) { c = substr(s, i, 1)
        if (c == "(") d++; else if (c == ")" && d > 0) d--
        if (d == 0) { if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { n++; i += 4; continue }
                      if (substr(s, i, 4) == " or ") { n++; i += 3; continue } } }
      return n }
    function aid(s) { s = trim(s); sub(/[ \t]+AMENDED$/, "", s); return s }
    function qa(f,   i, x, o) { o = ""; for (i = 3; i <= f; i++) { x = trim($i); if (index(x, "Q:") == 1 || index(x, "A:") == 1) o = o (o == "" ? "" : " ") x } return o }
    function out(q, t, x) { gsub(/\|/, "/", x); printf "%d | %s | %s | %s\n", ++N, q, t, x }
    FILENAME ~ /cur\.rows$/ { id = trim($1); if (id == "") next; CT[id] = trim($2); CI[id] = trim($3); ci[++nc] = id
      FI[id] = lab(NF, npc, "fail-if"); ST[id] = id " [" CI[id] "]: " trim($npc) (FI[id] == "" ? "" : " fail-if: " FI[id]); SRC[id] = lab(NF, npc, "source"); next }
    FILENAME ~ /prev\.rows$/ { id = trim($1); if (id == "") next; PT[id] = trim($2); PI[id] = trim($3); pi_[++np] = id; PS[id] = id " [" PI[id] "]: " trim($npp); next }
    FILENAME ~ /cur\.ans$/ { id = aid($1); if (id !~ /^A-[0-9]+$/) next; if (!(id in AW)) ao[++na] = id; AW[id] = trim($2); AQ[id] = qa(NF); next }
    FILENAME ~ /pairs$/ { pa[++npr] = $0; next }
    END {
      for (i = 1; i <= nc; i++) { id = ci[i]; if (!isrule(CT[id])) continue; n = split(SRC[id], e, ",")
        for (j = 1; j <= n; j++) { x = trim(e[j]); if ((x in AW) && AW[x] == "human") out("faithful", id "~" x, ST[id] " ~~ " x ": " AQ[x]) } }
      for (i = 1; i <= na; i++) { a = ao[i]; if (AW[a] == "model_proposed") out("honest", a, a ": " AQ[a]) }
      if (hasprev == "yes") for (i = 1; i <= np; i++) { id = pi_[i]; if (!isrule(PT[id])) continue
        if (!(id in CT) || tnum(CI[id]) > tnum(PI[id])) out("complete", id, PS[id]) }
      for (i = 1; i <= npr; i++) { split(pa[i], pp, " "); out("coherent", pp[1] "~" pp[2], ST[pp[1]] " ~~ " ST[pp[2]]) }
      for (i = 1; i <= nc; i++) { id = ci[i]; if (isdemand(CT[id]) && FI[id] != "" && arms(FI[id]) > 1) out("right-grained", id, ST[id]) }
      for (i = 1; i <= nc; i++) { id = ci[i]; if (isdemand(CT[id]) && FI[id] != "") out("testable", id, ST[id]) }
      for (i = 1; i <= nc; i++) { id = ci[i]; if (isdemand(CT[id])) out("product-level", id, ST[id]) }
    }' FS='|' "$T/cur.rows" FS='|' "$T/prev.rows" FS='|' "$T/cur.ans" FS=' ' "$T/pairs" > "$CANDS"
  echo "candidates for the reader: $(grep -c . "$CANDS" | tr -d ' ') lines in $CANDS"
fi
exit 0

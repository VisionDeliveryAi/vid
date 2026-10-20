#!/bin/sh
# Purpose: ViD stages (v0.26.10.5 spec R3, R4, R10–R15) — STAGES.md, the one
# source of the stage cut, read the same way by every stage-aware reader.
# STAGES.md's ```vid-stages block (the law region, checks/lawfiles) holds:
#   STAGE-<n> | <name> | features: FEAT-a FEAT-b …   one line per stage, 1..k; amendment 1 (R1a): `features: -` (or
#                                                  no features: field) for a stage whose requirements come only
#                                                  from split: lines — two usable stages inside one feature
#   split: REQ-x[ REQ-y …] -> STAGE-<n>             requirements a split feature puts in another stage
#   row: <ROW|RULE|DIF|EXC|SUP>-x -> STAGE-<n>       a row placed (a ROW whose items span stages; a census row later)
#   needs: FEAT-a needs FEAT-b — <source>          an ordering edge, with its source
#   STAGE-0 | <name> | technical                   v0.26.10.8 (R2): the technical stage 0 — the walking skeleton, never
#                                                  released; it holds rows only, each placed by a row: line (its rows'
#                                                  requirements keep their own stages). Stages then run 0..k.
# How each thing gets its stage (R3): a PRD item (requirement or invariant) —
# its feature's stage, unless a split: line moves it; `phase: later` has no
# stage (`later`). A ROW — its items' stage (the effective PRD items its
# derived-from names, later ones left out) when they agree, a row: line when
# they don't; all its items later: `later`; no item: stage 1. A census row
# (RULE, DIF, EXC, SUP): stage 1 unless a row: line places it later. A HOS
# row: the stage of the row or item its protects: names. Seam rows have no
# stage reading; the coverage join counts them, as stage 1.
#   (no argument) | check   the court (pre-commit): silent while the index
#                  holds no STAGES.md. Reads the staged STAGES.md, PRD.md and
#                  INVENTORY.md (the working tree outside a repository).
#                  Refuses (exit 1, one `STAGES  <why>` line each): a line
#                  that does not parse; stage numbers not 1..k (0..k with STAGE-0) once each; an
#                  effective pilot feature in no stage or in two, an unknown
#                  feature in a stage (a feature this commit adds to the
#                  PRD may be unplaced at it: its placement is the next, law
#                  commit — every commit after is refused until then); a split: or row: line naming an unknown
#                  id, a later-phase item or an unknown stage; a ROW whose
#                  items span stages with no row: line; a requirement of
#                  stage k whose rows all sit in later stages; a needs: edge
#                  to a later stage, transitively, or a cycle. v0.26.10.8 (R2): `technical` on a stage but
#                  STAGE-0, or STAGE-0 without it; a feature in STAGE-0, or a split: line to it; a STAGE-0
#                  no row: line places a row in; a STAGE-0 line added or removed by any commit but the one that
#                  creates STAGES.md (init's cut only).
#   msg <message file>  commit-msg: a change to stage membership (the STAGE-,
#                  split: and row: lines, STAGES.md created or deleted)
#                  between HEAD and the index whose message cites no owner
#                  answer (an A-NNN token) is refused. Silent while neither
#                  HEAD nor the index holds STAGES.md.
#   scope [--upto N] [--reqs]   every obligation id of stages 1 to N (0 to N with STAGE-0; ROW,
#                  census, HOS), one per line, in the inventory's order; with
#                  --reqs the PRD items (requirements, invariants) of stages
#                  1 to N follow. Without --upto: the current stage. Without
#                  STAGES.md everything not later is stage 1.
#   stage-of <id>  prints the id's stage, or `later`; exit 2 for an unknown id.
#   current        the current stage: RUN-STATE's `stage:` (when absent the lowest stage: 0 with STAGE-0, else 1).
#   counts         amendment 1 (R1a): per stage `stage <k> requirements=<REQ ids> rows=<obligations> | <name>` —
#                  the same numbers as `scope --upto k [--reqs]` minus `--upto k-1` — then `row-lines=<n>`, the
#                  block's row: lines (rows placed by hand). The ladder's counts, run in each rung's scratch copy.
#   deploy [--target staging|production] [--platform none|present] [--tree <dir>]   R11–R15, deploy's
#                  reading; v0.26.10.7 (R2, R11): two targets (see `deploy` below).
#   candidate --target staging|production   v0.26.10.7 (R2): the candidate alone, one line for the readers
#                  (checks/metrics.sh deploy-check).
#   hold --after N --words "<…>" | hold --off [--setup]   v0.26.10.7 (R12, R14): the owner's hold after stage N;
#                  v0.26.10.8 (R3): the setup hold (`--words "staging setup"`) and its release by develop.
#   staging-auth on|off --words "<the owner's words>"   v0.26.10.8 (R6): the standing staging authorization.
# The working tree is read for every subcommand but the court and msg.
set -eu
IFS='
'
CMD=${1:-check}; [ $# -gt 0 ] && shift
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HERE=$(cd "$(dirname "$0")" && pwd)

# src <mode> <file> <out>: the file as the mode reads it — index (`:file`), head (`HEAD:file`) or work (disk)
src() {
  case "$1" in
    index) git show ":$2" > "$3" 2>/dev/null || { if ! git rev-parse --git-dir >/dev/null 2>&1 && [ -f "$2" ]; then cat "$2" > "$3"; else : > "$3"; return 1; fi; } ;;
    head) git show "HEAD:$2" > "$3" 2>/dev/null || { : > "$3"; return 1; } ;;
    work) if [ -f "$2" ]; then cat "$2" > "$3"; else : > "$3"; return 1; fi ;;
  esac
}
block() { sed -n "/^\`\`\`$1\$/,/^\`\`\`\$/p" "$2" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
# load <mode>: $T/stages (the vid-stages block), $T/prd (the effective PRD rows), $T/feat (effective feature ids),
# $T/inv (the vid-inventory block); HASST=yes when STAGES.md is there
load() {
  HASST=no; src "$1" STAGES.md "$T/STAGES.md" && HASST=yes
  block vid-stages "$T/STAGES.md" > "$T/stages"
  src "$1" PRD.md "$T/PRD.md" || true
  : > "$T/prd"
  if [ -s "$T/PRD.md" ] && [ -f "$HERE/prd.sh" ]; then sh "$HERE/prd.sh" --effective "$T/PRD.md" > "$T/prd" 2>/dev/null || : > "$T/prd"; fi
  block vid-prd-features "$T/PRD.md" | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id); if (id ~ /^FEAT-[0-9]+$/ && !(id in s)) { s[id] = 1; print id } }' > "$T/feat"
  # the features HEAD's PRD already had: a feature this very commit adds may be unplaced at it (its placement is a
  # law commit of its own, R5), and every commit after is refused until it is placed
  if [ "$1" = index ] && git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    src head PRD.md "$T/PRD.head" || true
    block vid-prd-features "$T/PRD.head" | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id); if (id ~ /^FEAT-[0-9]+$/) print id }' | sort -u > "$T/hfeat"
  else cp "$T/feat" "$T/hfeat"; fi
  src "$1" INVENTORY.md "$T/INVENTORY.md" || true
  sed -n '/^```vid-inventory/,/^```$/p' "$T/INVENTORY.md" | sed '1d;$d' > "$T/inv" || : > "$T/inv"
}
# resolve: one awk pass over the four inputs → $T/table lines
#   item <id> <stage|later|-> <feature|-> <type>   (an effective PRD item)
#   obl <id> <stage|later> <class> <cites>          (an inventory obligation; cites: its test field's path or -)
#   err <why>                                        (a court refusal)
#   nstages <k>
resolve() {
  awk -F'|' -v sf="$T/stages" -v ff="$T/feat" -v hf="$T/hfeat" -v pf="$T/prd" -v hasst="$HASST" '
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function err(m) { print "err " m }
    function stno(s) { if (s ~ /^STAGE-[0-9]+$/) { sub(/^STAGE-/, "", s); return s + 0 } return 0 }
    BEGIN {
      dem["functional"] = 1; dem["nfr"] = 1; dem["ux_flow"] = 1; dem["data_entity"] = 1
      while ((getline l < ff) > 0) FE[l] = 1
      while ((getline l < hf) > 0) HF[l] = 1
      # the effective PRD: type, feature, phase per item
      while ((getline l < pf) > 0) { n = split(l, F, "|"); id = tr(F[1]); if (id !~ /^[A-Z]+-[0-9]+$/) continue
        IT[id] = 1; TY[id] = tr(F[2]); FT[id] = "-"; PH[id] = "pilot"; IO[++ni] = id
        for (i = 3; i <= n; i++) { x = tr(F[i]); if (x ~ /^feature:/) { sub(/^feature:[ \t]*/, "", x); FT[id] = x } else if (x ~ /^phase:/) { sub(/^phase:[ \t]*/, "", x); PH[id] = x } }
        if (PH[id] == "pilot" && FT[id] != "-" && (dem[TY[id]] || TY[id] == "invariant")) PF[FT[id]] = 1 }
      # the stages block
      while ((getline l < sf) > 0) { ln++; raw = l; t = tr(l)
        if (t ~ /^STAGE-[0-9]+[ \t]*\|/) { n = split(t, F, "|"); s = stno(tr(F[1])); if (s in SD) { err("STAGE-" s " is declared twice"); continue } SD[s] = 1; if (s > K) K = s
          fl = ""; tc = 0; for (i = 3; i <= n; i++) { x = tr(F[i]); if (x ~ /^features:/) { sub(/^features:[ \t]*/, "", x); fl = x } else if (x == "technical") tc = 1 }
          if (fl == "-") fl = ""   # amendment 1 (R1a): a stage fed only by split: lines lists no feature
          # v0.26.10.8 (R2): technical marks STAGE-0 and nothing else; stage 0 holds rows only
          if (tc && s != 0) err("STAGE-" s " is marked technical: only STAGE-0, the walking skeleton, is technical")
          if (!tc && s == 0) err("STAGE-0 is not marked technical: stage 0 is the technical stage (STAGE-0 | <name> | technical)")
          if (s == 0 && fl != "") { err("STAGE-0 lists features (" fl "): stage 0 holds rows only, each placed by a row: line"); continue }
          m = split(fl, a, /[ ,]+/); for (k = 1; k <= m; k++) { if (a[k] == "") continue
            NFS[s]++
            if (!(a[k] in FE)) { err("STAGE-" s " names " a[k] ", which is no feature of the PRD"); continue }
            if (a[k] in FST) { if (FST[a[k]] != s) TWO[a[k]] = TWO[a[k]] " STAGE-" FST[a[k]] " STAGE-" s; continue }
            FST[a[k]] = s }
          continue }
        if (t ~ /^split:/) { x = t; sub(/^split:[ \t]*/, "", x); if (x !~ /->[ \t]*STAGE-[0-9]+$/) { err("split: line does not parse (split: REQ-x[ REQ-y …] -> STAGE-n): \047" t "\047"); continue }
          st = x; sub(/^.*->[ \t]*/, "", st); x2 = x; sub(/[ \t]*->.*$/, "", x2); m = split(x2, a, /[ ,]+/); kk = 0
          for (k = 1; k <= m; k++) if (a[k] != "") { kk++; SPN[++nsp] = a[k]; SPS[nsp] = stno(st) }
          if (!kk) err("split: line names no requirement: \047" t "\047")
          continue }
        if (t ~ /^row:/) { x = t; sub(/^row:[ \t]*/, "", x); if (x !~ /^[A-Z]+-[0-9]+[ \t]*->[ \t]*STAGE-[0-9]+$/) { err("row: line does not parse (row: <id> -> STAGE-n): \047" t "\047"); continue }
          id = x; sub(/[ \t]*->.*$/, "", id); st = x; sub(/^.*->[ \t]*/, "", st)
          if (id in RL) { err("row: " id " is placed twice"); continue } RL[id] = stno(st); RLO[++nrl] = id; continue }
        if (t ~ /^needs:/) { x = t; sub(/^needs:[ \t]*/, "", x); if (x !~ /^FEAT-[0-9]+[ \t]+needs[ \t]+FEAT-[0-9]+[ \t]+(—|--)[ \t]*[^ \t]/) { err("needs: line does not parse (needs: FEAT-a needs FEAT-b — <source>): \047" t "\047"); continue }
          split(x, a, /[ \t]+/); NA[++ne] = a[1]; NB[ne] = a[3]; continue }
        err("line does not parse: \047" t "\047") }
      LO = (0 in SD) ? 0 : 1
      for (s = LO; s <= K; s++) if (!(s in SD)) err("no STAGE-" s ": stages run " LO ".." K ", once each")
      for (f in TWO) err("feature " f " is in two stages:" TWO[f])
      if (hasst == "yes") for (f in PF) if (!(f in FST) && (f in HF)) err("feature " f " (pilot) is in no stage")
      for (k = 1; k <= nsp; k++) { id = SPN[k]; s = SPS[k]
        if (!(id in IT)) { err("split: " id " is no item of the PRD"); continue }
        if (PH[id] == "later") { err("split: " id " is phase: later — a later item has no stage"); continue }
        if (!(s in SD)) { err("split: " id " -> STAGE-" s ", which is no stage"); continue }
        if (s == 0) { err("split: " id " -> STAGE-0: stage 0 holds rows only, never a requirement (its rows\047 requirements keep their own stages)"); continue }
        SP[id] = s; SPIN[s] = 1 }
      for (s = 1; s <= K; s++) if ((s in SD) && !NFS[s] && !(s in SPIN)) err("STAGE-" s " holds nothing: it lists no feature and no split: line moves a requirement to it")
      # each item: its stage
      for (i = 1; i <= ni; i++) { id = IO[i]
        if (PH[id] == "later") ST[id] = "later"
        else if (id in SP) ST[id] = SP[id]
        else if (FT[id] in FST) ST[id] = FST[FT[id]]
        else if (hasst != "yes" && FT[id] != "-") ST[id] = 1
        else ST[id] = "-"
        print "item " id " " ST[id] " " FT[id] " " TY[id] }
      print "nstages " K + 0
      print "lowstage " LO + 0
    }
    # the inventory block: rows in order
    { c1 = tr($1) }
    c1 ~ /^ROW-[0-9]+$/ { id = c1; RO[++nr] = id; RC[id] = "ROW"; RK[id] = tr($2); RI[id] = ""; d = tr($7); m = split(d, a, /[ ,]+/)
      for (k = 1; k <= m; k++) if (a[k] in IT) RI[id] = RI[id] " " a[k]
      t = tr($8); sub(/ .*/, "", t); CI[id] = (t ~ /^tests\//) ? t : "-"; next }
    c1 == "rule" || c1 == "difference" || c1 == "exception" || c1 == "suppression" { id = tr($2); if (id !~ /^(RULE|DIF|EXC|SUP)-[0-9]+$/) next; RO[++nr] = id; RC[id] = toupper(substr(id, 1, index(id, "-") - 1))
      CI[id] = "-"; if (c1 == "rule") { n = NF; while (n > 3 && $n ~ /^[ \t]*(origin|proved-red|paid-at):/) n--; t = tr($n); sub(/ .*/, "", t); if (t ~ /^tests\//) CI[id] = t } next }
    c1 == "hostility" { id = tr($2); if (id !~ /^HOS-[0-9]+$/) next; RO[++nr] = id; RC[id] = "HOS"; PR[id] = ""; CI[id] = "-"
      for (i = 3; i <= NF; i++) { x = tr($i); if (x ~ /^protects:/) { sub(/^protects:[ \t]*/, "", x); sub(/[ \t].*$/, "", x); PR[id] = x } else if (x ~ /^tests\//) { sub(/ .*/, "", x); CI[id] = x } } next }
    END {
      for (k = 1; k <= nrl; k++) { id = RLO[k]
        if (!(id in RC) || RC[id] == "HOS") { err("row: " id " is no ROW or census row of the inventory"); delete RL[id]; continue }
        if (!(RL[id] in SD)) { err("row: " id " -> STAGE-" RL[id] ", which is no stage"); delete RL[id]; continue }
        if (RL[id] == 0) R0++ }
      if ((0 in SD) && !R0) err("STAGE-0 holds no row: no row: line places a row in it (row: ROW-x -> STAGE-0)")
      for (i = 1; i <= nr; i++) { id = RO[i]; c = RC[id]
        if (c == "ROW") {
          m = split(RI[id], a, " "); any = 0; lat = 0; S = ""; mx = 0; split("", seen)
          for (k = 1; k <= m; k++) { if (a[k] == "") continue; any++; s = ST[a[k]]
            if (s == "later") { lat++; continue } if (s == "-") continue
            if (!(s in seen)) { seen[s] = 1; S = S (S == "" ? "" : ",") s } if (s + 0 > mx) mx = s + 0 }
          if (id in RL) { if (any && lat == any) { err("row: " id " is placed, but every item it derives from is phase: later"); OS[id] = "later" } else OS[id] = RL[id] }
          else if (any && lat == any) OS[id] = "later"
          else if (S == "") OS[id] = 1
          else if (index(S, ",")) { err(id " derives from items of stages " S " and no row: line places it"); OS[id] = mx }
          else OS[id] = S + 0
        } else if (c != "HOS") OS[id] = (id in RL) ? RL[id] : 1 }
      for (i = 1; i <= nr; i++) { id = RO[i]; if (RC[id] != "HOS") continue; p = PR[id]
        if (p in OS) OS[id] = OS[p]; else if ((p in ST) && ST[p] != "-") OS[id] = ST[p]; else OS[id] = 1 }
      for (i = 1; i <= nr; i++) print "obl " RO[i] " " OS[RO[i]] " " RC[RO[i]] " " CI[RO[i]]
      # a requirement of stage k whose rows all sit in later stages (a row in no stage — later — is not one of them)
      for (i = 1; i <= nr; i++) { id = RO[i]; if (RC[id] != "ROW" || OS[id] == "later") continue; m = split(RI[id], a, " ")
        for (k = 1; k <= m; k++) if (a[k] ~ /^REQ-/) { HR[a[k]] = 1; if (!((a[k]) in MINS) || OS[id] + 0 < MINS[a[k]]) MINS[a[k]] = OS[id] + 0 } }
      for (r in HR) if (ST[r] != "later" && ST[r] != "-" && MINS[r] > ST[r] + 0) err(r " is in stage " ST[r] " but every row covering it is in a later stage (the earliest: " MINS[r] ") — split the row, bring its prerequisite forward, or move the requirement with a split: line")
      # needs: edges — a later stage, transitively, and cycles
      for (k = 1; k <= ne; k++) { a1 = NA[k]; b1 = NB[k]
        if (!(a1 in FE)) err("needs: " a1 " is no feature of the PRD"); if (!(b1 in FE)) err("needs: " b1 " is no feature of the PRD")
        AD[a1] = AD[a1] " " b1 }
      for (f in AD) { split("", vis); top = 0; m = split(AD[f], a, " "); for (k = 1; k <= m; k++) if (a[k] != "") stk[++top] = a[k]
        while (top > 0) { g = stk[top--]; if (g == f) { CY[f] = 1; continue } if (g in vis) continue; vis[g] = 1
          if ((f in FST) && (g in FST) && FST[g] > FST[f]) LT[f] = LT[f] " " g " (STAGE-" FST[g] ")"
          m2 = split(AD[g], a2, " "); for (k = 1; k <= m2; k++) if (a2[k] != "") stk[++top] = a2[k] } }
      for (f in LT) err("needs: " f " (STAGE-" FST[f] ") needs, directly or through others, a later stage:" LT[f])
      for (f in CY) err("needs: " f " is on a cycle of needs: edges")
    }' "$T/inv" > "$T/table"
}
# has0 <file>: its vid-stages block holds a STAGE-0 line (v0.26.10.8 R2)
has0() { block vid-stages "$1" | grep -qE '^[[:space:]]*STAGE-0+[[:space:]]*\|'; }
# lowest: the lowest stage — 0 when STAGES.md holds STAGE-0, else 1; final: the highest stage number (never the count of
# lines: with STAGE-0 the lines are one more than the final stage)
lowest() { if [ -f STAGES.md ] && has0 STAGES.md; then echo 0; else echo 1; fi; }
final() { block vid-stages "${1:-STAGES.md}" | sed -n 's/^[[:space:]]*STAGE-\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n | tail -n 1; }
# current stage: RUN-STATE's stage: here, else at the run's home; with no stage: line, the lowest stage
current() {
  _rs=.vid/RUN-STATE.md
  if [ ! -f "$_rs" ] && [ -f "$HERE/plan.sh" ]; then _h=$(sh "$HERE/plan.sh" home-of 2>/dev/null) && [ -f "$_h/.vid/RUN-STATE.md" ] && _rs="$_h/.vid/RUN-STATE.md"; fi
  _c=$(sed -n 's/^stage:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$_rs" 2>/dev/null | head -n 1)
  echo "${_c:-$(lowest)}"
}
# membership <file>: the STAGE-, split: and row: lines of a STAGES.md, whitespace normalised
membership() { block vid-stages "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]][[:space:]]*/ /g' | grep -E '^(STAGE-[0-9]+ ?\||split:|row:)' || true; }

case "$CMD" in
  check)
    load index
    [ "$HASST" = yes ] || exit 0
    resolve
    # v0.26.10.8 (R2): stage 0 is offered at init's cut only — its line comes and goes only with STAGES.md itself
    if src head STAGES.md "$T/STAGES.head"; then
      H0=no; I0=no; has0 "$T/STAGES.head" && H0=yes; has0 "$T/STAGES.md" && I0=yes
      case "$H0$I0" in
        noyes) echo 'err STAGE-0 is added to an existing STAGES.md: stage 0 is offered only at init'"'"'s cut, in the commit that creates STAGES.md' >> "$T/table" ;;
        yesno) echo 'err STAGE-0 is removed from STAGES.md: stage 0 stays once the cut holds it (init'"'"'s cut only)' >> "$T/table" ;;
      esac
    fi
    if grep -q '^err ' "$T/table"; then
      echo 'ViD stages: rejected — STAGES.md does not hold (v0.26.10.5 R4):' >&2
      sed -n 's/^err /STAGES  /p' "$T/table"
      exit 1
    fi
    echo "stages: $(( $(sed -n 's/^nstages //p' "$T/table") - $(sed -n 's/^lowstage //p' "$T/table") + 1 )) stages, $(grep -c '^item .* [0-9][0-9]* FEAT' "$T/table" || true) items staged, $(grep -c '^obl ' "$T/table" || true) obligations"
    exit 0 ;;
  msg)
    MF=${1:?message file}
    HH=no; src head STAGES.md "$T/h" && HH=yes
    HI=no; src index STAGES.md "$T/i" && HI=yes
    [ "$HH$HI" = nono ] && exit 0
    if [ "$HH" = "$HI" ] && [ "$(membership "$T/h")" = "$(membership "$T/i")" ]; then exit 0; fi
    if grep -v '^#' "$MF" | grep -qE '(^|[^A-Za-z0-9-])A-[0-9]+([^0-9]|$)'; then exit 0; fi
    case "$HH$HI" in
      yesno) W='deletes STAGES.md' ;; noyes) W='creates STAGES.md' ;; *) W='changes stage membership (a STAGE-, split: or row: line)' ;;
    esac
    echo "ViD commit-msg: rejected — this commit $W and its message cites no owner answer (A-NNN)." >&2
    echo 'Which stage a feature, requirement or row is in is the owner'"'"'s: name the answer that ratified it, e.g. "Stages: A-031 (the owner ratified the cut)".' >&2
    exit 1 ;;
  scope)
    UPTO=''; REQS=no
    while [ $# -gt 0 ]; do case "$1" in --upto) UPTO=${2:?--upto N}; shift 2 ;; --reqs) REQS=yes; shift ;; *) echo 'ViD stages: usage — scope [--upto N] [--reqs]' >&2; exit 2 ;; esac; done
    [ -n "$UPTO" ] || UPTO=$(current)
    case "$UPTO" in ''|*[!0-9]*) echo "ViD stages: --upto takes a stage number, not '$UPTO'" >&2; exit 2 ;; esac
    load work; resolve
    awk -v n="$UPTO" '$1 == "obl" && $3 != "later" && $3 + 0 <= n { print $2 }' "$T/table"
    if [ "$REQS" = yes ]; then awk -v n="$UPTO" '$1 == "item" && $3 != "later" && $3 != "-" && $3 + 0 <= n && ($2 ~ /^(REQ|INV)-/) { print $2 }' "$T/table"; fi
    exit 0 ;;
  stage-of)
    ID=${1:?an id}; load work; resolve
    S=$(awk -v id="$ID" '($1 == "obl" || $1 == "item") && $2 == id { print $3; exit }' "$T/table")
    case "$S" in '') echo "ViD stages: $ID is no PRD item or inventory row" >&2; exit 2 ;; -) echo "ViD stages: $ID has no stage (no feature)" >&2; exit 2 ;; esac
    echo "$S"; exit 0 ;;
  current) current; exit 0 ;;
  counts)
    load work; resolve
    # the block is read in BEGIN: an empty block (no STAGES.md — the single-stage rung) must not swallow the table
    awk -v sf="$T/stages" 'BEGIN { while ((getline l < sf) > 0) { if (l ~ /^[ \t]*STAGE-[0-9]+[ \t]*\|/) { n = split(l, f, "|"); id = f[1]; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/^STAGE-/, "", id); nm = f[2]; gsub(/^[ \t]+|[ \t]+$/, "", nm); NM[id + 0] = nm } if (l ~ /^[ \t]*row:/) rl++ } }
      $1 == "nstages" { K = $2 + 0 } $1 == "item" && $2 ~ /^REQ-/ && $3 ~ /^[0-9]+$/ { R[$3 + 0]++ } $1 == "obl" && $3 ~ /^[0-9]+$/ { O[$3 + 0]++ }
      END { if (K == 0) K = 1; for (k = ((0 in NM) ? 0 : 1); k <= K; k++) printf "stage %d requirements=%d rows=%d | %s\n", k, R[k], O[k], (k in NM ? NM[k] : "-"); printf "row-lines=%d\n", rl + 0 }' "$T/table"
    exit 0 ;;
  deploy|candidate|hold|staging-auth) ;;   # below
  *) echo 'ViD stages: usage — sh checks/stages.sh [check] | msg <file> | scope [--upto N] [--reqs] | stage-of <id> | current | counts | deploy [--target staging|production] [--by develop] [--platform none|present] [--tree <dir>] | candidate --target staging|production [--by develop] | hold --after N --words "<the owner'"'"'s words>" | hold --off [--setup] | staging-auth on|off --words "<the owner'"'"'s words>"' >&2; exit 2 ;;
esac


# --- deploy (v0.26.10.5 R11–R15; v0.26.10.7 R2, R11): what /vid deploy reads at its start --------------------------
#   deploy [--target staging|production] [--platform none|present] [--tree <dir>] — a bare deploy is staging.
#   The candidate (v0.26.10.7 R2):
#     staging — without STAGES.md, or the project complete (RUN-STATE's `run: complete`), or a staged project with the
#       next stage held (`stage-hold n=N state=on`, no `state=off` after it): HEAD, with a clean worktree (outside
#       .vid/). Otherwise stage N's newest candidate — vid/stage-N, or its newest vid/stage-N.k — N the newest
#       `stage-closed n=N … ready`; none closed: no candidate (preparation may proceed; the gates do not open).
#     production — the commit of the newest gate-2 pass (`deploy-gate gate=2 state=start candidate=<c>` with its
#       `state=end result=pass`), which must also be the staging candidate now: equal to it for a tag; for HEAD,
#       `git diff --name-only <c> HEAD` lists nothing outside the deploy's own records (.vid/, DEPLOYMENT.md,
#       tests/probes/captured/, the set `since:` leaves out). Anything else: refused, deploy to staging once more first.
#     A tag is read from its record, never recomputed: vid/stage-N against its `stage-closed sha=`, vid/stage-N.k
#     against its `deploy-check target=production sha=` record.
#   Refused (exit 1, one line): in a staged project, a develop run active or waiting (the gate on), for both targets:
#     say "pause" to the build, deploy, then say "continue". Without STAGES.md production is refused too while develop
#     runs (its full run binds HEAD); staging is not (it pins its commit).
#   R11, production only moves forward (both targets): the deploy log's newest production commit must be the candidate
#     or an ancestor of it (stricter than 0.26.10.5 R14); a commit the repository does not hold is not judged.
#   claim: as today — sh checks/metrics.sh completion (no STAGES.md, or the project complete) · stage N complete (the
#     newest `stage-closed n=N … ready`) · stage N closed and held · no stage closed yet.
#   candidate: <what> <commit, 12> — its tree is what ships (--tree <dir> extracts it with git archive), never the
#     working tree.
#   since: for a stage-tag candidate, the commits after it that change anything but .vid/ and the deploy's own records
#     — the live candidate lacks them; up to 20 named.
#   owed: each deploy-owed row of stages 1 to N (every stage, without STAGES.md) with no paid-at:, and its gate.
#   first-deploy: yes | no (<why>) | unknown (v0.26.10.5 R15).
#   candidate --target staging|production: one line, `candidate <commit, 12> head|tag <tag|-> <stage|->`, exit 0; or
#     `refused <why>` / `none <why>`, exit 1.
#   hold --after N --words "<the owner's words>" (R12): records `stage-hold n=N state=asked words="<…>"`; the stage
#     close (checks/metrics.sh stage-close --record) turns it on. Without STAGES.md, or N no stage: refused, one line.
#   hold --off (R14): records `stage-hold n=N state=off` for the held stage N, then prints one line for develop's reply:
#     `continue: staging runs <c>, <k> commits past stage N's candidate <tag> that no production deploy covers — …` when
#     the newest gate-2 pass is a commit past stage N's newest candidate, else `continue: nothing staging runs is lost`.
#   v0.26.10.8 (R3): the setup hold is the same hold asked with `--words "staging setup"` (stage 0 included); the close
#     then writes `run: stopped staging setup after stage N`. A stage's hold cycle runs from its last `off`: when it
#     holds an asked record with other words too, the owner asked to hold as well. `hold --off --setup` is develop's
#     release once staging is set up: `stage-hold n=N state=off` and one `released:` line — unless the owner also asked
#     to hold after stage N: then nothing is recorded, RUN-STATE's run line becomes the owner's hold, and one `held:`
#     line says so. Refused (one line) when the held stage carries no setup hold.
#   v0.26.10.8 (R5): production refused, one line, while the newest closed stage is stage 0 (it never goes live).
#   v0.26.10.8 (R6): staging-auth on|off --words — records `staging-auth state=on|off words="<…>"`; the newest stands.
#     Without STAGES.md: refused, one line, recording nothing.
#   v0.26.10.8 (R8): --by develop — develop's own staging deploy at a ready stage close, or at "continue" while the setup
#     hold is on. Accepted only with the authorization on, target staging, and the candidate stage N's newest tag for
#     the newest close N (or HEAD at that tag's commit), or HEAD while the setup hold is on; then the "a build is
#     running" refusal does not apply (develop is the caller, at a step boundary). Anything else: refused, one line.
EV=.vid/metrics-events
COMPLETE=no; grep -q '^run:[[:space:]]*complete' .vid/RUN-STATE.md 2>/dev/null && COMPLETE=yes
STAGED=no; [ -f STAGES.md ] && [ "$COMPLETE" = no ] && STAGED=yes
evk() { awk -v k="$1" '{ for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) { print substr($i, length(k) + 2); exit } }'; }
# held_n: the stage held now (the newest `stage-hold … state=on` with no `state=off` for it after), else nothing
held_n() { [ -f "$EV" ] || return 0; awk 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
  $1 == "stage-hold" { n = kv("n"); s = kv("state"); if (s == "on") { H[n] = 1; last = n } else if (s == "off") delete H[n] } END { if (last != "" && (last in H)) print last }' "$EV"; }
# newest_tag N: vid/stage-N's newest supersession vid/stage-N.k, else vid/stage-N, else nothing
newest_tag() { _k=$(git tag -l "vid/stage-$1.*" 2>/dev/null | sed "s#^vid/stage-$1\.##" | grep -E '^[0-9]+$' | sort -n | tail -n 1)
  if [ -n "$_k" ]; then echo "vid/stage-$1.$_k"; elif git rev-parse -q --verify "refs/tags/vid/stage-$1" >/dev/null 2>&1; then echo "vid/stage-$1"; fi; }
# gate2_pass: the candidate of the newest gate-2 pass, as recorded
gate2_pass() { [ -f "$EV" ] || return 0; awk 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
  $1 == "deploy-gate" && kv("gate") == "2" { if (kv("state") == "start") c = kv("candidate"); else if (kv("state") == "end") { if (kv("result") == "pass" && c != "") p = c; c = "" } } END { print p }' "$EV"; }
gate_on() { [ -f "$HERE/plan.sh" ] && sh "$HERE/plan.sh" gate >/dev/null 2>&1; }
dirty() { git status --porcelain -- . ':(exclude).vid' 2>/dev/null | head -n 5 | cut -c4- | paste -sd ',' - | sed 's/,/, /g'; }
# cand <target>: sets CK (head|tag|none|refused), CSHA (12), CTAG, CN (the stage, or -), CWHY, CLAIM
cand() {
  CK=''; CSHA=''; CTAG='-'; CN='-'; CWHY=''; CLAIM='claim: as today — sh checks/metrics.sh completion'
  if [ "$STAGED" = yes ] && [ "$BY" != develop ] && gate_on; then CK=refused; CWHY='deploy: refused — a build is running. Say "pause" to the build, deploy, then say "continue"; the build pauses only for the deploy itself.'; return 0; fi
  if [ "$1" = production ] && [ "$STAGED" = no ] && gate_on; then CK=refused; CWHY='deploy: refused — a build is running, and production'"'"'s full run binds HEAD. Say "pause" to the build, deploy, then say "continue".'; return 0; fi
  HN=$(held_n)
  if [ "$1" = production ] && [ "$STAGED" = yes ] && [ "$HN" = 0 ]; then CK=refused; CWHY='deploy: refused — Stage 0 is technical and never goes live; production takes stage 1 or later.'; return 0; fi   # v0.26.10.8 (R5)
  if [ "$STAGED" = yes ] && [ -n "$HN" ]; then CN=$HN; CLAIM="claim: stage $HN closed and held — corrections to it reach staging on their own (say \"continue\" to start stage $((HN + 1)))"
  elif [ "$STAGED" = yes ]; then
    CL=$( [ -f "$EV" ] && awk '$1 == "stage-closed" && / ready( |$)/ { l = $0 } END { if (l != "") print l }' "$EV" || true)
    if [ -z "$CL" ]; then CK=none; CLAIM='claim: no stage closed yet — preparation may proceed; the gates do not open'; CWHY='candidate: none'; return 0; fi
    CN=$(printf '%s\n' "$CL" | evk n); SSHA=$(printf '%s\n' "$CL" | evk sha)
    # v0.26.10.8 (R5): stage 0 is technical — staging runs it, production never does
    if [ "$1" = production ] && [ "$CN" = 0 ]; then CK=refused; CWHY='deploy: refused — Stage 0 is technical and never goes live; production takes stage 1 or later.'; return 0; fi
    CLAIM="claim: stage $CN complete (stage-closed n=$CN sha=$SSHA ready)"
    CTAG=$(newest_tag "$CN")
    if [ -z "$CTAG" ]; then CK=refused; CWHY="candidate: refused — the tag vid/stage-$CN is missing; the close records sha=$SSHA"; return 0; fi
    TC=$(git rev-parse -q --verify "refs/tags/$CTAG^{commit}" 2>/dev/null || true)
    case "$CTAG" in
      *.*) TS=$(git rev-parse --short=12 "$TC")
        if ! awk -v s="$TS" '$1 == "deploy-check" && / target=production / && / result=ready/ { for (i = 2; i <= NF; i++) if (index($i, "sha=") == 1 && index(s, substr($i, 5)) == 1 && length($i) > 10) f = 1 } END { exit f ? 0 : 1 }' "$EV" 2>/dev/null; then
          CK=refused; CWHY="candidate: refused — $CTAG is at $TS, and no deploy-check target=production record names it"; return 0; fi ;;
      *) case "$TC" in "$SSHA"*) ;; *) CK=refused; CWHY="candidate: refused — vid/stage-$CN is at $(git rev-parse --short=12 "$TC"), the close recorded sha=$SSHA"; return 0 ;; esac ;;
    esac
    CK=tag; CSHA=$(git rev-parse --short=12 "$TC")
  fi
  if [ -z "$CK" ]; then
    _d=$(dirty)
    if [ -n "$_d" ]; then CK=refused; CWHY="candidate: refused — the worktree carries uncommitted changes ($_d); commit first: a deploy ships a commit"; return 0; fi
    if ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then CK=refused; CWHY='candidate: refused — no commit yet'; return 0; fi
    CK=head; CSHA=$(git rev-parse --short=12 HEAD)
  fi
  [ "$1" = production ] || return 0
  # production: the newest gate-2 pass, which must be the staging candidate now
  G2=$(gate2_pass)
  if [ -z "$G2" ]; then CK=refused; CWHY='candidate: refused — no gate-2 pass is recorded: deploy to staging first'; return 0; fi
  GC=$(git rev-parse -q --verify "$G2^{commit}" 2>/dev/null || true)
  if [ -z "$GC" ]; then CK=refused; CWHY="candidate: refused — the newest gate-2 pass names $G2, which is no commit here"; return 0; fi
  GS=$(git rev-parse --short=12 "$GC")
  if [ "$CK" = tag ]; then
    [ "$GS" = "$CSHA" ] || { CK=refused; CWHY="candidate: refused — staging's newest gate-2 pass is on $GS, not on the candidate $CTAG ($CSHA): deploy to staging first"; return 0; }
  else
    _ch=$( { git merge-base --is-ancestor "$GC" HEAD 2>/dev/null && git diff --name-only "$GC" HEAD -- . ':(exclude).vid' ':(exclude)DEPLOYMENT.md' ':(exclude)tests/probes/captured'; } 2>/dev/null || echo '(HEAD does not descend from it)')
    if [ -n "$_ch" ]; then CK=refused; CWHY="candidate: refused — the commit staging runs ($GS) is not HEAD's tree: $(printf '%s\n' "$_ch" | head -n 5 | paste -sd ',' - | sed 's/,/, /g') changed since; deploy to staging once more first"; return 0; fi
    CSHA=$GS
  fi
}
# the deploy log's production rows: the table under "## Deploy log", its Commit column (third)
PRODC=$( [ -f DEPLOYMENT.md ] && awk '/^## /{ on = ($0 ~ /^## Deploy log/) ; next } on && /^\|/ { if ($0 ~ /^\|[ \t:|-]*$/) next; n = split($0, f, "|"); c = f[4]; gsub(/^[ \t`]+|[ \t`]+$/, "", c); if (c == "Commit" || c == "" || c ~ /^\{\{/) next; last = c } END { if (last != "") print last }' DEPLOYMENT.md || true)
# forward <commit>: R11 — refused (CK=refused) when production's newest commit is known here and not the candidate's ancestor
forward() {
  [ -n "$PRODC" ] || return 0
  PC=$(git rev-parse -q --verify "$PRODC^{commit}" 2>/dev/null) || return 0
  git merge-base --is-ancestor "$PC" "$1" 2>/dev/null && return 0
  CK=refused; CWHY="candidate: refused — production runs $PRODC, and the candidate $CSHA does not descend from it; production only moves forward (a newer candidate carries every fix already live)"
}

# hold_kinds N: the kinds of hold asked in stage N's current cycle (its asked records since its last `off`), one per
# line — `setup` (words="staging setup", v0.26.10.8 R3) and `owner` (any other words)
hold_kinds() { [ -f "$EV" ] || return 0; awk -v n="$1" 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
  $1 == "stage-hold" && kv("n") == n { s = kv("state"); if (s == "off") { su = 0; ow = 0 } else if (s == "asked") { if ($0 ~ / words="staging setup"( |$)/) su = 1; else ow = 1 } }
  END { if (su) print "setup"; if (ow) print "owner" }' "$EV"; }
# auth_on: the standing staging authorization stands — the newest `staging-auth` is `state=on` (v0.26.10.8 R6)
auth_on() { [ -f "$EV" ] && [ "$(awk '$1 == "staging-auth" { s = $2 } END { print s }' "$EV")" = state=on ]; }

if [ "$CMD" = staging-auth ]; then
  case "${1:-}" in on|off) ;; *) echo 'ViD stages: usage — staging-auth on|off --words "<the owner'"'"'s words>"' >&2; exit 2 ;; esac
  [ "${2:-}" = --words ] && [ -n "${3:-}" ] || { echo 'ViD stages: usage — staging-auth on|off --words "<the owner'"'"'s words>"' >&2; exit 2; }
  [ -f STAGES.md ] || { echo 'staging-auth: refused — this project has no STAGES.md: no stage closes, so there is nothing to deploy on its own'; exit 1; }
  AW=$(printf '%s' "$3" | tr '"\n' "' ")
  sh "$HERE/event.sh" "staging-auth state=$1 words=\"$AW\"" >/dev/null
  if [ "$1" = on ]; then echo 'staging-auth: recorded on — develop sets staging up and puts each closed stage on it on its own; going live still waits for the owner'
  else echo 'staging-auth: recorded off — staging is deployed only when the owner says so'; fi
  exit 0
fi

if [ "$CMD" = hold ]; then
  [ -f STAGES.md ] || { echo 'hold: refused — this project has no STAGES.md: it is built in one stage, so there is no next stage to hold'; exit 1; }
  case "${1:-}" in
    --after)
      HA=${2:-}; [ "${3:-}" = --words ] && [ -n "${4:-}" ] || { echo 'ViD stages: usage — hold --after N --words "<the owner'"'"'s words>"' >&2; exit 2; }
      case "$HA" in ''|*[!0-9]*) echo "ViD stages: --after takes a stage number, not '$HA'" >&2; exit 2 ;; esac
      [ "$HA" -ge "$(lowest)" ] || { echo "ViD stages: --after takes a stage number, not '$HA'" >&2; exit 2; }
      K=$(final)
      [ "$HA" -lt "${K:-1}" ] || { echo "hold: refused — stage $HA is the last stage ($K): its close is the project's completion, and there is no next stage to hold"; exit 1; }
      HW=$(printf '%s' "$4" | tr '"\n' "' ")
      sh "$HERE/event.sh" "stage-hold n=$HA state=asked words=\"$HW\"" >/dev/null
      echo "hold: recorded stage-hold n=$HA state=asked — develop stops at stage $HA's close; corrections to it then reach staging on their own"
      exit 0 ;;
    --off)
      HN=$(held_n); [ -n "$HN" ] || { echo 'hold: refused — no stage is held'; exit 1; }
      if [ "${2:-}" = --setup ]; then   # v0.26.10.8 (R3): develop's release of the setup hold, staging set up
        HK=$(hold_kinds "$HN")
        printf '%s\n' "$HK" | grep -qx setup || { echo "hold: refused — stage $HN's hold is not the staging setup's: only the owner's \"continue\" ends it"; exit 1; }
        if printf '%s\n' "$HK" | grep -qx owner; then
          if [ -f .vid/RUN-STATE.md ]; then sed "s/^run:.*/run: stopped owner asked to hold after stage $HN/" .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; fi
          echo "held: staging is set up; stage $HN stays held, as the owner asked — say \"continue\" to start stage $((HN + 1))"; exit 0
        fi
        sh "$HERE/event.sh" "stage-hold n=$HN state=off" >/dev/null
        echo "released: staging is set up — stage-hold n=$HN state=off; develop starts stage $((HN + 1))"; exit 0
      fi
      sh "$HERE/event.sh" "stage-hold n=$HN state=off" >/dev/null
      NT=$(newest_tag "$HN"); G2=$(gate2_pass); GC=''; [ -n "$G2" ] && GC=$(git rev-parse -q --verify "$G2^{commit}" 2>/dev/null || true)
      if [ -n "$NT" ] && [ -n "$GC" ] && NC=$(git rev-parse -q --verify "refs/tags/$NT^{commit}") && [ "$NC" != "$GC" ] && git merge-base --is-ancestor "$NC" "$GC" 2>/dev/null; then
        NL=$(git rev-list --count "$NC..$GC")
        echo "continue: staging runs $(git rev-parse --short=12 "$GC"), $NL commits past stage $HN's candidate $NT that no production deploy covers — the next staging deploy goes back to $NT, and production with it, until stage $((HN + 1)) closes"
      else echo 'continue: nothing staging runs is lost'; fi
      exit 0 ;;
    *) echo 'ViD stages: usage — hold --after N --words "<the owner'"'"'s words>" | hold --off [--setup]' >&2; exit 2 ;;
  esac
fi

TGT=staging; PLAT=''; TREE=''; BY=''
while [ $# -gt 0 ]; do case "$1" in --target) TGT=${2:-}; shift 2 ;; --platform) PLAT=${2:-}; shift 2 ;; --tree) TREE=${2:-}; shift 2 ;; --by) BY=${2:-}; shift 2 ;; *) echo 'ViD stages: usage — deploy [--target staging|production] [--by develop] [--platform none|present] [--tree <dir>] | candidate --target staging|production [--by develop]' >&2; exit 2 ;; esac; done
case "$TGT" in staging|production) ;; *) echo "ViD stages: --target takes staging or production, not '$TGT'" >&2; exit 2 ;; esac
case "$PLAT" in ''|none|present) ;; *) echo "ViD stages: --platform takes none or present, not '$PLAT'" >&2; exit 2 ;; esac
case "$BY" in ''|develop) ;; *) echo "ViD stages: --by takes develop, not '$BY' (the owner's deploy carries no --by)" >&2; exit 2 ;; esac
# v0.26.10.8 (R8): develop's own staging deploy — under the standing authorization, staging only
if [ "$BY" = develop ]; then
  [ "$TGT" = staging ] || { echo 'deploy: refused — develop deploys to staging only; production always needs the owner'"'"'s word and yes'; exit 1; }
  auth_on || { echo 'deploy: refused — the standing staging authorization is off: staging is deployed only when the owner says so'; exit 1; }
fi
cand "$TGT"
case "$CK" in head|tag) forward "$(git rev-parse "$CSHA^{commit}")" ;; esac
# v0.26.10.8 (R8): --by develop takes the newest close's tag, or HEAD while the setup hold is on
if [ "$BY" = develop ]; then
  NCL=$( [ -f "$EV" ] && awk '$1 == "stage-closed" && / ready( |$)/ { l = $0 } END { if (l != "") print l }' "$EV" || true)
  NCN=$(printf '%s\n' "$NCL" | evk n); NTC=''
  [ -n "$NCN" ] && NT=$(newest_tag "$NCN") && [ -n "$NT" ] && NTC=$(git rev-parse -q --verify "refs/tags/$NT^{commit}" 2>/dev/null || true)
  case "$CK" in
    tag) [ "$CN" = "$NCN" ] || { CK=refused; CWHY="deploy: refused — develop deploys the newest close's tag, and stage $CN is not the newest closed stage"; } ;;
    head) HC=$(git rev-parse HEAD)
      if [ -n "$HN" ] && hold_kinds "$HN" | grep -qx setup; then :
      elif [ -n "$NTC" ] && [ "$HC" = "$NTC" ]; then :
      else CK=refused; CWHY='deploy: refused — develop deploys HEAD only while the staging setup holds the stage; otherwise the newest close'"'"'s tag'; fi ;;
  esac
fi

if [ "$CMD" = candidate ]; then
  case "$CK" in
    head|tag) echo "candidate $CSHA $CK $CTAG $CN"; exit 0 ;;
    none) echo 'none no stage closed yet'; exit 1 ;;
    *) echo "refused ${CWHY#*refused — }"; exit 1 ;;
  esac
fi

G3=no; [ -f "$EV" ] && grep -E '^deploy-gate ' "$EV" | grep -q ' gate=3 state=start' && G3=yes
case "$CK" in refused) case "$CWHY" in deploy:*) echo "$CWHY"; exit 1 ;; esac ;; esac
echo "$CLAIM"
case "$CK" in
  refused) echo "$CWHY"; exit 1 ;;
  none) echo 'candidate: none' ;;
  *)
    if [ "$TGT" = production ]; then W="the commit staging runs (its gate-2 pass)"; [ "$CK" = tag ] && W="stage $CN $CTAG, the commit staging runs (its gate-2 pass)"
    elif [ "$CK" = tag ]; then W="stage $CN $CTAG"; else W='HEAD'; fi
    echo "candidate: $W $CSHA — ship this commit's tree (git archive $CSHA), never the working tree"
    if [ "$CK" = tag ]; then
      git log --format='%h %s' "$CSHA..HEAD" -- . ':(exclude).vid' ':(exclude)DEPLOYMENT.md' ':(exclude)tests/probes/captured' 2>/dev/null > "$T/since" || : > "$T/since"
      NS=$(grep -c . "$T/since" || true)
      SL="stage $CN's close"; [ "$CTAG" = "vid/stage-$CN" ] || SL=$CTAG
      if [ "$NS" -gt 0 ]; then echo "since: $NS commits since $SL — the live candidate lacks them; they ship with the next stage's close"; head -n 20 "$T/since" | sed 's/^/  /'; [ "$NS" -gt 20 ] && echo "  (+$((NS - 20)) more)"
      else echo "since: 0 commits since $SL"; fi
    fi
    if [ -n "$TREE" ]; then mkdir -p "$TREE" && git archive "$CSHA" | tar -x -C "$TREE" && echo "tree: $CSHA extracted to $TREE"; fi
    # the deploy debt: stages 1 to N (every stage without STAGES.md, or the project complete)
    load work; resolve
    UP=$CN; [ "$UP" = - ] && UP=999999
    awk -v n="$UP" '$1 == "obl" && $3 != "later" && $3 + 0 <= n { print $2 }' "$T/table" > "$T/scope"
    sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md 2>/dev/null | awk -F'|' -v sf="$T/scope" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 }
      { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); if (!(id in S)) next; t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (t !~ /^owed: paid by \/vid deploy gate/ || $0 ~ /\|[ \t]*paid-at:/) next; g = t; sub(/^owed: paid by \/vid deploy gate[ \t]*/, "", g); sub(/[^0-9].*$/, "", g); print "owed: " id " gate " g }' ;;
esac
if [ -n "$PRODC" ]; then echo "first-deploy: no (the deploy log holds a production row: $PRODC) — gate 1 applies"
elif [ "$G3" = yes ]; then echo 'first-deploy: no (a gate-3 start was recorded and the deploy log holds no row: an interrupted cutover) — reconcile first: record in the deploy log what production now runs, then gate 1 applies'
elif [ "$PLAT" = present ]; then echo 'first-deploy: no (the platform shows a production deployment) — reconcile it into the deploy log first, then gate 1 applies'
elif [ "$PLAT" = none ]; then echo 'first-deploy: yes — no production row, no gate-3 start, and the platform shows no production deployment: gate 1 may be skipped (deploy-gate.sh 1 skipped --reason first-deploy)'
else echo 'first-deploy: unknown — ask the platform through its authenticated CLI whether a production deployment exists, then run again with --platform none|present'; fi
exit 0

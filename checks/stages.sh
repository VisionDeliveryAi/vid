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
#                  that does not parse; stage numbers not 1..k once each; an
#                  effective pilot feature in no stage or in two, an unknown
#                  feature in a stage (a feature this commit adds to the
#                  PRD may be unplaced at it: its placement is the next, law
#                  commit — every commit after is refused until then); a split: or row: line naming an unknown
#                  id, a later-phase item or an unknown stage; a ROW whose
#                  items span stages with no row: line; a requirement of
#                  stage k whose rows all sit in later stages; a needs: edge
#                  to a later stage, transitively, or a cycle.
#   msg <message file>  commit-msg: a change to stage membership (the STAGE-,
#                  split: and row: lines, STAGES.md created or deleted)
#                  between HEAD and the index whose message cites no owner
#                  answer (an A-NNN token) is refused. Silent while neither
#                  HEAD nor the index holds STAGES.md.
#   scope [--upto N] [--reqs]   every obligation id of stages 1 to N (ROW,
#                  census, HOS), one per line, in the inventory's order; with
#                  --reqs the PRD items (requirements, invariants) of stages
#                  1 to N follow. Without --upto: the current stage. Without
#                  STAGES.md everything not later is stage 1.
#   stage-of <id>  prints the id's stage, or `later`; exit 2 for an unknown id.
#   current        the current stage: RUN-STATE's `stage:` (1 when absent).
#   counts         amendment 1 (R1a): per stage `stage <k> requirements=<REQ ids> rows=<obligations> | <name>` —
#                  the same numbers as `scope --upto k [--reqs]` minus `--upto k-1` — then `row-lines=<n>`, the
#                  block's row: lines (rows placed by hand). The ladder's counts, run in each rung's scratch copy.
#   deploy [--platform none|present] [--tree <dir>]   R11–R15, deploy's
#                  reading (see `deploy` below).
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
          fl = ""; for (i = 3; i <= n; i++) { x = tr(F[i]); if (x ~ /^features:/) { sub(/^features:[ \t]*/, "", x); fl = x } }
          if (fl == "-") fl = ""   # amendment 1 (R1a): a stage fed only by split: lines lists no feature
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
      for (s = 1; s <= K; s++) if (!(s in SD)) err("no STAGE-" s ": stages run 1.." K ", once each")
      for (f in TWO) err("feature " f " is in two stages:" TWO[f])
      if (hasst == "yes") for (f in PF) if (!(f in FST) && (f in HF)) err("feature " f " (pilot) is in no stage")
      for (k = 1; k <= nsp; k++) { id = SPN[k]; s = SPS[k]
        if (!(id in IT)) { err("split: " id " is no item of the PRD"); continue }
        if (PH[id] == "later") { err("split: " id " is phase: later — a later item has no stage"); continue }
        if (!(s in SD)) { err("split: " id " -> STAGE-" s ", which is no stage"); continue }
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
        if (!(RL[id] in SD)) { err("row: " id " -> STAGE-" RL[id] ", which is no stage"); delete RL[id]; continue } }
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
# current stage: RUN-STATE's stage: here, else at the run's home
current() {
  _rs=.vid/RUN-STATE.md
  if [ ! -f "$_rs" ] && [ -f "$HERE/plan.sh" ]; then _h=$(sh "$HERE/plan.sh" home-of 2>/dev/null) && [ -f "$_h/.vid/RUN-STATE.md" ] && _rs="$_h/.vid/RUN-STATE.md"; fi
  _c=$(sed -n 's/^stage:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$_rs" 2>/dev/null | head -n 1)
  echo "${_c:-1}"
}
# membership <file>: the STAGE-, split: and row: lines of a STAGES.md, whitespace normalised
membership() { block vid-stages "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]][[:space:]]*/ /g' | grep -E '^(STAGE-[0-9]+ ?\||split:|row:)' || true; }

case "$CMD" in
  check)
    load index
    [ "$HASST" = yes ] || exit 0
    resolve
    if grep -q '^err ' "$T/table"; then
      echo 'ViD stages: rejected — STAGES.md does not hold (v0.26.10.5 R4):' >&2
      sed -n 's/^err /STAGES  /p' "$T/table"
      exit 1
    fi
    echo "stages: $(sed -n 's/^nstages //p' "$T/table") stages, $(grep -c '^item .* [0-9][0-9]* FEAT' "$T/table" || true) items staged, $(grep -c '^obl ' "$T/table" || true) obligations"
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
      END { if (K == 0) K = 1; for (k = 1; k <= K; k++) printf "stage %d requirements=%d rows=%d | %s\n", k, R[k], O[k], (k in NM ? NM[k] : "-"); printf "row-lines=%d\n", rl + 0 }' "$T/table"
    exit 0 ;;
  deploy) ;;   # below
  *) echo 'ViD stages: usage — sh checks/stages.sh [check] | msg <file> | scope [--upto N] [--reqs] | stage-of <id> | current | counts | deploy [--platform none|present] [--tree <dir>]' >&2; exit 2 ;;
esac

# --- deploy (R11–R15): what /vid deploy reads at its start ---------------------------------------------------------
#   refused (exit 1): with STAGES.md, a project not complete and a develop run active or waiting (the gate on): one
#     line — say "pause" to the build, deploy, then say "continue".
#   claim: as today (no STAGES.md, or the project complete: sh checks/metrics.sh completion) · stage N complete (the
#     newest `stage-closed n=N … ready` event) · no stage closed yet (preparation may proceed; the gates don't open).
#   candidate: stage N vid/stage-N <commit> — the tag's tree is what ships (--tree <dir> extracts it with git archive),
#     never the working tree. Refused (exit 1) when production holds a newer commit (R14: the deploy log's newest row).
#   since: the commits after the tag that change anything but .vid/ and the deploy's own records — the live candidate
#     lacks them (R10); up to 20 named.
#   owed: each deploy-owed row of stages 1 to N with no paid-at:, and its gate (gate 3 opens with none of gate 1 or 2).
#   first-deploy: yes | no (<why>) | unknown (R15) — yes only when the deploy log holds no production row, no
#     `deploy-gate gate=3 state=start` was recorded, and --platform none (the platform's CLI shows no production).
PLAT=''; TREE=''
while [ $# -gt 0 ]; do case "$1" in --platform) PLAT=${2:-}; shift 2 ;; --tree) TREE=${2:-}; shift 2 ;; *) echo 'ViD stages: usage — deploy [--platform none|present] [--tree <dir>]' >&2; exit 2 ;; esac; done
case "$PLAT" in ''|none|present) ;; *) echo "ViD stages: --platform takes none or present, not '$PLAT'" >&2; exit 2 ;; esac
EV=.vid/metrics-events
COMPLETE=no; grep -q '^run:[[:space:]]*complete' .vid/RUN-STATE.md 2>/dev/null && COMPLETE=yes
STAGED=no; [ -f STAGES.md ] && [ "$COMPLETE" = no ] && STAGED=yes
# the deploy log's production rows: the table under "## Deploy log", its Commit column (third)
PRODC=$( [ -f DEPLOYMENT.md ] && awk '/^## /{ on = ($0 ~ /^## Deploy log/) ; next } on && /^\|/ { if ($0 ~ /^\|[ \t:|-]*$/) next; n = split($0, f, "|"); c = f[4]; gsub(/^[ \t`]+|[ \t`]+$/, "", c); if (c == "Commit" || c == "" || c ~ /^\{\{/) next; last = c } END { if (last != "") print last }' DEPLOYMENT.md || true)
G3=no; [ -f "$EV" ] && grep -E '^deploy-gate ' "$EV" | grep -q ' gate=3 state=start' && G3=yes
if [ "$STAGED" = yes ]; then
  if [ -f "$HERE/plan.sh" ] && sh "$HERE/plan.sh" gate >/dev/null 2>&1; then
    echo 'deploy: refused — a build is running. Say "pause" to the build, deploy, then say "continue"; the build pauses only for the deploy itself.'
    exit 1
  fi
  CL=$( [ -f "$EV" ] && awk '$1 == "stage-closed" && / ready( |$)/ { l = $0 } END { if (l != "") print l }' "$EV" || true)
  if [ -z "$CL" ]; then
    echo 'claim: no stage closed yet — preparation may proceed; the gates do not open'
    echo 'candidate: none'
  else
    N=$(printf '%s\n' "$CL" | tr ' ' '\n' | sed -n 's/^n=//p' | head -n 1); SHA=$(printf '%s\n' "$CL" | tr ' ' '\n' | sed -n 's/^sha=//p' | head -n 1)
    TC=$(git rev-parse -q --verify "refs/tags/vid/stage-$N^{commit}" 2>/dev/null || true)
    echo "claim: stage $N complete (stage-closed n=$N sha=$SHA ready)"
    if [ -z "$TC" ]; then echo "candidate: refused — the tag vid/stage-$N is missing; the close records sha=$SHA"; exit 1; fi
    case "$TC" in "$SHA"*) ;; *) echo "candidate: refused — vid/stage-$N is at $(git rev-parse --short=12 "$TC"), the close recorded sha=$SHA"; exit 1 ;; esac
    if [ -n "$PRODC" ] && PC=$(git rev-parse -q --verify "$PRODC^{commit}" 2>/dev/null) && [ "$PC" != "$TC" ] && git merge-base --is-ancestor "$TC" "$PC" 2>/dev/null; then
      echo "candidate: refused — production runs $PRODC, newer than stage $N ($(git rev-parse --short=12 "$TC")); production only moves forward. Going live means the newest ready stage."
      exit 1
    fi
    echo "candidate: stage $N vid/stage-$N $(git rev-parse --short=12 "$TC") — ship this tag's tree (git archive vid/stage-$N), never the working tree"
    git log --format='%h %s' "$TC..HEAD" -- . ':(exclude).vid' ':(exclude)DEPLOYMENT.md' ':(exclude)tests/probes/captured' 2>/dev/null > "$T/since" || : > "$T/since"
    NS=$(grep -c . "$T/since" || true)
    if [ "$NS" -gt 0 ]; then echo "since: $NS commits since stage $N's close — the live candidate lacks them; they ship with the next stage's close"; head -n 20 "$T/since" | sed 's/^/  /'; [ "$NS" -gt 20 ] && echo "  (+$((NS - 20)) more)"
    else echo "since: 0 commits since stage $N's close"; fi
    if [ -n "$TREE" ]; then mkdir -p "$TREE" && git archive "vid/stage-$N" | tar -x -C "$TREE" && echo "tree: vid/stage-$N extracted to $TREE"; fi
    load work; resolve
    awk -v n="$N" '$1 == "obl" && $3 != "later" && $3 + 0 <= n { print $2 }' "$T/table" > "$T/scope"
    sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md 2>/dev/null | awk -F'|' -v sf="$T/scope" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 }
      { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); if (!(id in S)) next; t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (t !~ /^owed: paid by \/vid deploy gate/ || $0 ~ /\|[ \t]*paid-at:/) next; g = t; sub(/^owed: paid by \/vid deploy gate[ \t]*/, "", g); sub(/[^0-9].*$/, "", g); print "owed: " id " gate " g }'
  fi
else
  echo 'claim: as today — sh checks/metrics.sh completion'
  echo 'candidate: as today'
fi
if [ -n "$PRODC" ]; then echo "first-deploy: no (the deploy log holds a production row: $PRODC) — gate 1 applies"
elif [ "$G3" = yes ]; then echo 'first-deploy: no (a gate-3 start was recorded and the deploy log holds no row: an interrupted cutover) — reconcile first: record in the deploy log what production now runs, then gate 1 applies'
elif [ "$PLAT" = present ]; then echo 'first-deploy: no (the platform shows a production deployment) — reconcile it into the deploy log first, then gate 1 applies'
elif [ "$PLAT" = none ]; then echo 'first-deploy: yes — no production row, no gate-3 start, and the platform shows no production deployment: gate 1 may be skipped (deploy-gate.sh 1 skipped --reason first-deploy)'
else echo 'first-deploy: unknown — ask the platform through its authenticated CLI whether a production deployment exists, then run again with --platform none|present'; fi
exit 0

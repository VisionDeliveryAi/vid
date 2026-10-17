#!/bin/sh
# Purpose: ViD develop's evidence reader (v0.9.6 spec 3.3, R3; 3.11, R11).
# "Current" is read from git and the receipts, never from a new record.
#   rows --at <tree-ish> --map <file> [--legacy] [--until <UTC>]
#     One line per row of the map — `<ROW-id><TAB><state><TAB><detail>` —
#     state one of pass, red, stale, never, owed, deploy-owed, held, later. The map
#     (written by checks/plan.sh) is `<ROW-id><TAB><step><TAB><currency
#     paths>`: the step's own modules, those of every step it builds on
#     (transitively), and the plan's shared paths.
#     A VALID receipt is one checks/test.sh published — a `ledger-run` event
#     with report= not none, the file present, its <receipt>.tree beside it —
#     that no `invalidated … report=<name>` event names. A receipt is CURRENT
#     for a row when `git diff --no-renames --name-only <its tree> <the tree
#     now>` lists no path under the row's currency paths and not the row's
#     own test path (its INVENTORY `test` field), and when the row's latest
#     `amended row=ID sha=S` commit S is the receipt's base= or an ancestor
#     of it. When the harness declares deployed-selector:, a journey or
#     actor `(process)` row reads only deployed-shape receipts and every
#     other row only inline ones (metrics.sh's own rule). A row's cases are
#     the existing join (metrics.sh row_cases: a case under the row's test
#     path naming the row id, else its derived-from REQ), the id also read
#     in the spelling a test function's name must use (`ROW_042` for
#     ROW-042, `REQ_069` for REQ-069); each case takes its
#     newest result among the current, eligible receipts; the row PASSES
#     when it has such cases and every one is passed, and is RED when one
#     is not; with none it is STALE when an eligible valid receipt ran its
#     cases on other code, and NEVER run when none did. Owed, deploy-owed and held rows are
#     read as the row engine reads them (INVENTORY's test field; metrics.sh
#     row-state --table's hold); a LATER row is one whose derived-from REQs
#     are all `phase: later`. --legacy also reads a receipt with no .tree,
#     taking the commit its name starts with as both its tree and its base
#     — an approximation, used only to replay records written before 0.9.6.
#     --until <UTC> reads only the receipts published by then (the progress
#     update's rate).
#     v0.9.6.1 (3.4, R4) — under the gate (`checks/plan.sh gate` on) the map
#     checks/plan.sh writes names no path, so a result goes stale only on
#     the row's own test path or its amendment; and a case's newest result
#     is the one on the NEWEST TESTED COMMIT (the receipt's base=): a result
#     on a descendant commit beats one on an ancestor, whatever their
#     publication order, and publication order decides between commits on
#     unrelated branches (or the same commit). A row passing on a receipt
#     whose tree is not the one judged reads `passed at <base>[,<base>…]
#     (<receipt>)` — never as freshly tested. Outside the gate, 0.9.6's
#     reading holds: publication order, the map's paths.
#     v0.9.6.1 amendment 5 (spec 3.4, revision 11) — under the gate an edit
#     to a row's test file stales the row only when a changed line touches
#     it: the changed lines are the hunks of `git diff -U0 <receipt tree>
#     <now> -- <file>` (new-side lines, read in the file at now; a pure
#     deletion marks the lines either side of it), and the row is stale
#     when a removed or added line names its id (ROW-48 or ROW_48, not
#     followed by a digit), or a changed line falls in the BLOCK of a case
#     the receipt ran for it — from the first line of the file at now
#     containing the case's name (its id after the last `::`, less a
#     trailing `[…]`) to the line before the next start of any other case
#     name of that file. A case name not found at now, or the file gone,
#     falls back to the whole file. Any other changed line (imports,
#     shared helpers, data naming no row) stales nothing: the close's rows
#     file names what it affects.
#   red <receipt>
#     Every red case of a receipt, grouped by where it stops: `setup` (status
#     error) and `failed`, the failures grouped by their first message line
#     when the receipt is JUnit XML (its `message` attribute), ungrouped for
#     another format. Each group: its count, then its cases.
#     v0.9.7.0.7 (3.4, R8): in a JUnit receipt each case's line ends ` at
#     <path>:<line>` — from the failure's text (its message and body): the
#     last `<path>:<n>` whose path is the INVENTORY `test` file of a row the
#     case names (its id as ROW-n or ROW_n, whole), or ends `/` and that
#     path; the deepest frame in the test file, where the assertion is. Else
#     the testcase's `file=` and `line=` attributes, marked ` (declaration)`:
#     some producers give the test's declaration, one counts from zero. With
#     neither, the case prints as before. Nothing parses a language.
#   reach <report> [--shape inline|deployed]   v0.9.7.0.2 (3.3, R7): which
#     rows a report's cases are credited to, by the same join `rows` uses
#     (the row id in the case, under the row's cited test path, else its
#     derived-from REQ; a journey or actor `(process)` row only from a
#     deployed-shape report when the harness declares deployed-selector:,
#     every other row only from an inline one). One `<case><TAB><row>` line
#     per credit; a case credited to no row prints nothing. The shape is
#     --shape, else the report's .tree `shape=`, else its name. The cases
#     are its .cases beside it, else the results reader's.
#     v0.9.7.0.11 (3.1, R1): `reach` is credit-bearing — a report with a
#     `<report>.rows` sidecar (the rows its request was frozen with) prints
#     only the lines of those rows; `--raw` prints every line, and only
#     checks/test.sh's outside() reads it so.
#   credit <report> [--shape inline|deployed]   v0.9.7.0.11 (3.1, R1): the
#     rows a report credits, one per line — its `.rows` when present, else
#     every row its cases reach (raw `reach`). Every reader that credits
#     rows goes through it: `rows` below (a receipt credits a row only when
#     the row is in its credit), the credit-bearing `reach`, checks/metrics.sh
#     claim, and checks/brief.sh's hand-back check (through `reach`).
#   kinds <rows file>   v0.9.7.0.11 (3.9, R9): `<id> <kind> <actor>` for each
#     row of the file found in INVENTORY.md's block (inv_rows); a row not
#     found prints nothing.
# Read at the run's home (checks/plan.sh admission, checks/progress.sh).
# Always a reader: it writes nothing.
# Usage: sh checks/evidence.sh rows --at <tree-ish> --map <file> [--legacy] | red <receipt> | reach <report> [--shape inline|deployed] [--raw] | credit <report> [--shape inline|deployed] | kinds <rows file>
set -u
IFS='
'
usage() { echo 'ViD evidence: usage — sh checks/evidence.sh rows --at <tree-ish> --map <file> [--legacy] | red <receipt> | reach <report> [--shape inline|deployed] [--raw] | credit <report> [--shape inline|deployed] | kinds <rows file>' >&2; exit 2; }
RD=.vid/ledger-results; EV=.vid/metrics-events
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
# the case-to-row join, one code for `rows` and `reach` (v0.9.7.0.2 3.3): CI[i, p, k] and nc[i, p] hold receipt i's cases under test path p
# pick <i> <path> <token>: the case indexes of receipt i under <path> naming <token> — as written, or
# in the identifier spelling a test name must use (ROW_042 for ROW-042); credit <i> <path> <row> <derived>: by the row id, else its derived-from items
AWKJOIN='function pick(i, p, tok,   k, out, alt) { out = ""; alt = tok; gsub(/-/, "_", alt)
        for (k = 1; k <= nc[i, p] + 0; k++) if (index(CI[i, p, k], tok) || index(CI[i, p, k], alt)) out = out k " "; return out }
      function credit(i, p, id, der,   sel, n2, tk, q) { sel = pick(i, p, id)
        if (sel == "") { n2 = split(der, tk, /[ ,]+/); for (q = 1; q <= n2; q++) { if (tk[q] == "") continue; sel = pick(i, p, tk[q]); if (sel != "") break } }
        return sel }'
# inv_rows <out>: the INVENTORY block's rows — id kind actor derived test
inv_rows() { if [ -f INVENTORY.md ]; then sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ {
      for (i = 1; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i); print $1 "\t" $2 "\t" $4 "\t" $7 "\t" $8 }' > "$1" || : > "$1"; else : > "$1"; fi; }
# dd_declared: the harness contract declares deployed-selector:
dd_declared() { [ -f docker-compose.test.yml ] && awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); if (v!="") f=1 } END { exit f?0:1 }' docker-compose.test.yml; }
# cases_of <receipt name>: `case <id> <status> …` lines — the .cases sidecar, else the results reader
cases_of() {
  if [ -f "$RD/$1.cases" ]; then cat "$RD/$1.cases"
  elif [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh "$RD/$1" 2>/dev/null | grep -E '^case ' || true; fi
}

case "${1:-}" in
  rows)
    shift; AT=''; MAP=''; LEG=no; UNTIL=''
    while [ $# -gt 0 ]; do case "$1" in --at) AT=${2:-}; shift 2 ;; --map) MAP=${2:-}; shift 2 ;; --legacy) LEG=yes; shift ;; --until) UNTIL=${2:-}; shift 2 ;; *) usage ;; esac; done
    [ -n "$AT" ] && [ -f "$MAP" ] || usage
    NOW=$(git rev-parse -q --verify "$AT^{tree}" 2>/dev/null) || { echo "ViD evidence: $AT names no tree" >&2; exit 1; }
    # the valid receipts, oldest first: name tree base shape
    : > "$T/rec"
    if [ -f "$EV" ]; then
      awk -v until="$UNTIL" "$AWKAT"' $1 == "invalidated" { r = kv("report"); if (r != "") inv[r] = 1; next }
        $1 == "ledger-run" { r = kv("report"); if (r == "" || r == "none") next; a = lastat(); if (a == "") a = "0000"; if (until != "" && a > until) next; printf "%s\t%09d\t%s\n", a, NR, r; seen[r] = 1 }
        END { for (r in inv) printf "INV\t%s\n", r }' "$EV" > "$T/ev.raw"
      grep '^INV	' "$T/ev.raw" | cut -f2 > "$T/inv" || true
      grep -v '^INV	' "$T/ev.raw" | sort -t "$(printf '\t')" -k1,1 -k2,2n | cut -f3 | awk '!s[$0]++' > "$T/names" || true
      n=0
      while IFS= read -r r; do
        grep -qxF -- "$r" "$T/inv" 2>/dev/null && continue
        [ -f "$RD/$r" ] || continue
        if [ -f "$RD/$r.tree" ]; then
          tr_=$(sed -n 's/^tree=//p' "$RD/$r.tree" | head -n 1); bs=$(sed -n 's/^base=//p' "$RD/$r.tree" | head -n 1); sh_=$(sed -n 's/^shape=//p' "$RD/$r.tree" | head -n 1)
        elif [ "$LEG" = yes ]; then
          c=${r%%.*}; tr_=$(git rev-parse -q --verify "$c^{tree}" 2>/dev/null || true); bs=$c
          case "$r" in *.deployed.*) sh_=deployed ;; *) sh_=inline ;; esac
        else continue; fi
        [ -n "$tr_" ] || continue
        n=$((n + 1))
        git diff --no-renames --name-only "$tr_" "$NOW" -- 2>/dev/null > "$T/diff.$n" || continue
        cases_of "$r" | awk -v i="$n" '$1 == "case" { print i "\t" $2 "\t" $3 }' >> "$T/cases"
        # v0.9.7.0.11 (3.1, R1): a receipt with frozen rows credits only those (the credit function)
        [ -f "$RD/$r.rows" ] && awk -v i="$n" 'NF { print i "\t" $1 }' "$RD/$r.rows" >> "$T/cr"
        printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$r" "$tr_" "${bs:-}" "${sh_:-inline}" >> "$T/rec"
      done < "$T/names"
    fi
    [ -f "$T/cases" ] || : > "$T/cases"
    [ -f "$T/cr" ] || : > "$T/cr"
    # v0.9.6.1 (3.4): under the gate, which base descends from which — `<descendant><TAB><ancestor>`
    : > "$T/desc"
    GATED=no; [ -f checks/plan.sh ] && sh checks/plan.sh gate >/dev/null 2>&1 && GATED=yes
    if [ "$GATED" = yes ] && [ -s "$T/rec" ]; then
      cut -f4 "$T/rec" | grep -v '^$' | sort -u > "$T/bases"
      while IFS= read -r b; do
        git rev-parse -q --verify "$b^{commit}" >/dev/null 2>&1 || continue
        git rev-list "$b" 2>/dev/null | cut -c1-12 | awk -v b="$b" 'NR == FNR { B[$1] = 1; next } ($1 in B) && $1 != substr(b, 1, 12) { print b "\t" $1 }' "$T/bases" - >> "$T/desc"
      done < "$T/bases"
    fi
    # the rows: id kind actor derived test (the INVENTORY block)
    inv_rows "$T/inv.rows"
    # held rows (the row engine), later REQs (PRD phase: later)
    : > "$T/held"
    if [ -f checks/metrics.sh ]; then sh checks/metrics.sh row-state --table 2>/dev/null | awk -F'\t' 'NF >= 9 && $5 != "-" { print $1 }' > "$T/held" || true; fi
    : > "$T/later"
    if [ -f PRD.md ] && grep -q '^```vid-prd$' PRD.md; then
      sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id); ph = "pilot"
        for (i = 3; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/, "", f); ph = f } }
        if (id ~ /^REQ-[0-9]+$/) last[id] = ph } END { for (r in last) if (last[r] == "later") print r }' > "$T/later"
    fi
    # the latest amendment per row, and whether each receipt's base contains it
    : > "$T/amend"; : > "$T/anc"
    [ -f "$EV" ] && awk "$AWKAT"' $1 == "amended" { r = kv("row"); s = kv("sha"); if (r != "" && s != "") am[r] = s } END { for (r in am) print r "\t" am[r] }' "$EV" > "$T/amend"
    if [ -s "$T/amend" ] && [ -s "$T/rec" ]; then
      for s in $(cut -f2 "$T/amend" | sort -u); do
        for b in $(cut -f4 "$T/rec" | sort -u); do
          [ -n "$b" ] || continue
          if git merge-base --is-ancestor "$s" "$b" 2>/dev/null; then printf '%s\t%s\tyes\n' "$s" "$b"; else printf '%s\t%s\tno\n' "$s" "$b"; fi
        done
      done > "$T/anc"
    fi
    # v0.9.6.1 amendment 5: under the gate, the changed lines of each changed test file, and its case blocks at now
    : > "$T/g4"
    if [ "$GATED" = yes ] && [ -s "$T/rec" ]; then
      awk -F'\t' '$5 ~ /^tests\// { p = $5; sub(/ .*/, "", p); print p }' "$T/inv.rows" | sort -u > "$T/tpaths"
      : > "$T/g4paths"
      while IFS='	' read -r n _r tr_ _b _s; do
        grep -xF -f "$T/tpaths" "$T/diff.$n" 2>/dev/null | while IFS= read -r p; do
          printf 'P\t%s\t%s\n' "$n" "$p"
          git diff -U0 --no-renames "$tr_" "$NOW" -- "$p" 2>/dev/null | awk -v i="$n" -v p="$p" '
            /^@@/ { h = $0; sub(/^@@ -[0-9,]+ \+/, "", h); sub(/ @@.*/, "", h); c = split(h, a, ","); s = a[1] + 0; w = (c > 1) ? a[2] + 0 : 1
              if (w == 0) { print "L\t" i "\t" p "\t" s; print "L\t" i "\t" p "\t" s + 1 } else for (k = s; k < s + w; k++) print "L\t" i "\t" p "\t" k; next }
            /^(\+\+\+|---) / { next }
            /^[-+]/ { t = $0; while (match(t, /ROW[-_][0-9]+/)) { m = substr(t, RSTART, RLENGTH); gsub(/_/, "-", m); print "M\t" i "\t" p "\t" m; t = substr(t, RSTART + RLENGTH) } }'
          printf '%s\n' "$p" >> "$T/g4paths"
        done
      done < "$T/rec" >> "$T/g4"
      for p in $(sort -u "$T/g4paths"); do
        if git cat-file -e "$NOW:$p" 2>/dev/null; then
          awk -F'\t' -v p="$p" 'index($2, p "::") == 1 { nm = $2; sub(/\[.*\]$/, "", nm); sub(/.*::/, "", nm); if (nm != "") print nm }' "$T/cases" | sort -u > "$T/g4names"
          git show "$NOW:$p" | awk -v p="$p" -v nf="$T/g4names" 'BEGIN { while ((getline l < nf) > 0) N[l] = 1 }
            { for (nm in N) if (!(nm in S) && index($0, nm)) S[nm] = NR } END { for (nm in S) print "S\t" p "\t" nm "\t" S[nm]; print "N\t" p "\t" NR }' >> "$T/g4"
        else printf 'A\t%s\n' "$p" >> "$T/g4"; fi
      done
    fi
    DD=no; dd_declared && DD=yes
    awk -F'\t' -v T="$T" -v dd="$DD" -v gated="$GATED" -v now="$NOW" "$AWKJOIN"'
      function under(p, pref,   n, k, a) { n = split(pref, a, " "); for (k = 1; k <= n; k++) { if (a[k] == "") continue; if (p == a[k] || index(p, a[k] "/") == 1 || (substr(a[k], length(a[k])) == "/" && index(p, a[k]) == 1)) return 1 } return 0 }
      function stale(i, pref,   key, j) { key = i SUBSEP pref; if (key in ST) return ST[key]; ST[key] = 0
        for (j = 1; j <= nd[i]; j++) if (under(D[i, j], pref)) { ST[key] = 1; break } return ST[key] }
      BEGIN {
        while ((getline l < (T "/desc")) > 0) { split(l, a, "\t"); DESC[a[1], a[2]] = 1 }
        while ((getline l < (T "/rec")) > 0) { split(l, a, "\t"); NR_ = a[1] + 0; if (NR_ > nr) nr = NR_; RN[NR_] = a[2]; RT[NR_] = a[3]; RB[NR_] = a[4]; RSH[NR_] = a[5]
          f = T "/diff." NR_; while ((getline p < f) > 0) { nd[NR_]++; D[NR_, nd[NR_]] = p; DS[NR_, p] = 1 } close(f) }
        while ((getline l < (T "/cases")) > 0) { split(l, a, "\t"); i = a[1] + 0; cp = a[2]; sub(/::.*/, "", cp); k = ++nc[i, cp]; CI[i, cp, k] = a[2]; CS[i, cp, k] = a[3] }
        while ((getline l < (T "/cr")) > 0) { split(l, a, "\t"); HASR[a[1] + 0] = 1; CRW[a[1] + 0, a[2]] = 1 }
        while ((getline l < (T "/inv.rows")) > 0) { split(l, a, "\t"); KIND[a[1]] = a[2]; ACT[a[1]] = a[3]; DER[a[1]] = a[4]; TST[a[1]] = a[5] }
        while ((getline l < (T "/held")) > 0) HELD[l] = 1
        while ((getline l < (T "/later")) > 0) LATER[l] = 1
        while ((getline l < (T "/amend")) > 0) { split(l, a, "\t"); AM[a[1]] = a[2] }
        while ((getline l < (T "/anc")) > 0) { split(l, a, "\t"); ANC[a[1], a[2]] = a[3] }
        while ((getline l < (T "/g4")) > 0) { split(l, a, "\t")
          if (a[1] == "P") G4[a[2], a[3]] = 1; else if (a[1] == "L") CL[a[2], a[3]] = CL[a[2], a[3]] " " a[4]; else if (a[1] == "M") MEN[a[2], a[3], a[4]] = 1
          else if (a[1] == "S") { START[a[2], a[3]] = a[4] + 0; SN[a[2]] = SN[a[2]] "\001" a[3] } else if (a[1] == "N") NL[a[2]] = a[3] + 0; else if (a[1] == "A") ABS[a[2]] = 1 }
        for (pp in SN) { n = split(substr(SN[pp], 2), nn, "\001")
          for (k = 1; k <= n; k++) { e = NL[pp]; for (q = 1; q <= n; q++) if (START[pp, nn[q]] > START[pp, nn[k]] && START[pp, nn[q]] - 1 < e) e = START[pp, nn[q]] - 1; ENDL[pp, nn[k]] = e } }
      }
      # g4stale <i> <path> <row> <case indexes>: under the gate, whether the result receipt i gives the row is stale after an edit to its test file (amendment 5)
      function nmof(c) { sub(/\[.*\]$/, "", c); sub(/.*::/, "", c); return c }
      function g4stale(i, p, id, sel,   n, ix, k, nm, s, e, m, L, q) {
        if (!((i, p) in G4) || (i, p, id) in MEN || (p in ABS)) return 1
        n = split(sel, ix, " ")
        for (k = 1; k <= n; k++) { if (ix[k] == "") continue; nm = nmof(CI[i, p, ix[k]]); if (!((p, nm) in START)) return 1
          s = START[p, nm]; e = ENDL[p, nm]; m = split(CL[i, p], L, " "); for (q = 1; q <= m; q++) if (L[q] != "" && L[q] + 0 >= s && L[q] + 0 <= e) return 1 }
        return 0
      }
      {
        id = $1; pref = $3; t = TST[id]; kind = KIND[id]
        if (!(id in TST)) { print id "\tnever\tnot in INVENTORY.md"; next }
        if (t ~ /^owed: paid by \/vid deploy/) { print id "\tdeploy-owed\t" t; next }
        if (t ~ /^owed:/) { print id "\towed\t" t; next }
        if (id in HELD) { print id "\theld\theld for the owner (metrics.sh row-state)"; next }
        m = split(DER[id], dr, /[ ,]+/); nreq = 0; nl = 0
        for (k = 1; k <= m; k++) if (dr[k] ~ /^REQ-[0-9]+$/) { nreq++; if (dr[k] in LATER) nl++ }
        if (nreq > 0 && nl == nreq) { print id "\tlater\tevery REQ it derives from is phase: later"; next }
        if (t !~ /^tests\//) { print id "\tnever\tno test cited (" t ")"; next }
        p = t; sub(/ .*/, "", p)
        pop = (dd == "yes" && (kind == "journey" || ACT[id] == "(process)"))
        split("", R); split("", RI); ran = ""
        for (i = 1; i <= nr; i++) {
          if (pop && RSH[i] != "deployed") continue
          if (!pop && RSH[i] == "deployed") continue
          if ((i in HASR) && !((i, id) in CRW)) continue   # v0.9.7.0.11 (R1): outside the receipt credit
          sel = credit(i, p, id, DER[id])
          if (sel == "") continue
          ran = RN[i]
          if ((i, p) in DS) { if (gated != "yes" || g4stale(i, p, id, sel)) continue }
          if (stale(i, pref)) continue
          if ((id in AM) && ANC[AM[id], RB[i]] != "yes") continue
          n3 = split(sel, ix, " ")
          for (q = 1; q <= n3; q++) { if (ix[q] == "") continue; c = CI[i, p, ix[q]]
            # v0.9.6.1: under the gate a result on an ancestor commit never overwrites one on its descendant
            if (gated == "yes" && (c in RI) && ((RB[RI[c]], RB[i]) in DESC)) continue
            R[c] = CS[i, p, ix[q]]; RI[c] = i }
        }
        nres = 0; bad = ""; li = 0; split("", OLD); olds = ""
        for (c in R) { nres++; if (R[c] != "passed") bad = bad (bad == "" ? "" : "; ") c " " R[c]; if (RI[c] > li) li = RI[c]
          if (gated == "yes" && RT[RI[c]] != now && !(RB[RI[c]] in OLD)) { OLD[RB[RI[c]]] = 1; olds = olds (olds == "" ? "" : ",") RB[RI[c]] } }
        last = RN[li]
        if (nres == 0) { if (ran != "") print id "\tstale\tnever run on the current code (last run " ran ")" (pop ? " (deployed shape)" : ""); else print id "\tnever\tnever run" (pop ? " (deployed shape)" : ""); next }
        if (bad == "") print id "\tpass\t" (olds != "" ? "passed at " olds " (" last ")" : last)
        else print id "\tred\t" bad " (last current run: " last ")"
      }' "$MAP" || exit 1
    exit 0 ;;
  red)
    R=${2:-}; [ -n "$R" ] || usage
    F=$R; [ -f "$F" ] || F="$RD/$R"
    [ -f "$F" ] || { echo "ViD evidence: no receipt $R" >&2; exit 1; }
    N=${F##*/}; SAVE=$RD; RD=$(dirname "$F"); cases_of "$N" > "$T/cases"; RD=$SAVE
    if grep -q '<testcase' "$F" 2>/dev/null; then
      # JUnit: the first line of each failure's message; errors are setup; v0.9.7.0.7 (3.4): each case's line
      inv_rows "$T/inv.rows"
      awk -v invf="$T/inv.rows" '
        BEGIN { while ((getline l < invf) > 0) { split(l, a, "\t"); t = a[5]; sub(/ .*/, "", t); if (t ~ /^tests\//) TF[a[1]] = t } RS = "<testcase" }
        # the INVENTORY test files of the rows a case names, whole ids, either spelling
        function files(c,   s, o, x, y, id, out) { s = c; o = 0; out = ""
          while (match(s, /ROW[-_][0-9]+/)) { x = (o + RSTART > 1) ? substr(c, o + RSTART - 1, 1) : ""; y = substr(c, o + RSTART + RLENGTH, 1); id = substr(s, RSTART, RLENGTH); gsub(/_/, "-", id)
            if (x !~ /[A-Za-z0-9]/ && y !~ /[A-Za-z0-9]/ && (id in TF) && index(" " out " ", " " TF[id] " ") == 0) out = out (out == "" ? "" : " ") TF[id]
            o += RSTART + RLENGTH - 1; s = substr(c, o + 1) } return out }
        # where: the last <tf>:<n> in the text whose path is one of the files (or ends /<file>); else the declaration
        function where(c, txt, fa, la,   n, f, k, q, o, p, b, r, best, bl, bf) { n = split(files(c), f, " "); best = 0
          for (k = 1; k <= n; k++) { q = txt; o = 0
            while ((p = index(q, f[k] ":")) > 0) { b = (o + p > 1) ? substr(txt, o + p - 1, 1) : ""; r = substr(q, p + length(f[k]) + 1)
              if ((b == "" || b == "/" || b !~ /[A-Za-z0-9_.-]/) && match(r, /^[0-9]+/) && o + p > best) { best = o + p; bl = substr(r, 1, RLENGTH); bf = f[k] }
              o += p; q = substr(txt, o + 1) } }
          if (best) return " at " bf ":" bl
          if (fa != "" && la != "") return " at " fa ":" la " (declaration)"
          return "" }
        NR > 1 {
          hd = $0; sub(/>.*/, "", hd)
          cn = ""; if (match(hd, /[ \t]name="[^"]*"/)) cn = substr(hd, RSTART + 7, RLENGTH - 8)
          cl = ""; if (match(hd, /classname="[^"]*"/)) cl = substr(hd, RSTART + 11, RLENGTH - 12)
          fa = ""; if (match(hd, /[ \t]file="[^"]*"/)) fa = substr(hd, RSTART + 7, RLENGTH - 8)
          la = ""; if (match(hd, /[ \t]line="[^"]*"/)) la = substr(hd, RSTART + 7, RLENGTH - 8)
          if (match($0, /<failure[^>]*/)) { tag = substr($0, RSTART, RLENGTH); txt = substr($0, RSTART); msg = ""; if (match(tag, /message="[^"]*"/)) msg = substr(tag, RSTART + 9, RLENGTH - 10); sub(/&#10;.*/, "", msg); sub(/\n.*/, "", msg); print "F\t" msg "\t" cl "::" cn where(cl "::" cn, txt, fa, la) }
          else if (match($0, /<error/)) print "E\t\t" cl "::" cn where(cl "::" cn, substr($0, RSTART), fa, la) }' "$F" > "$T/red"
    else
      awk '$1 == "case" && $3 == "error" { print "E\t\t" $2 } $1 == "case" && $3 != "passed" && $3 != "error" && $3 != "skipped" { print "F\t\t" $2 }' "$T/cases" > "$T/red"
    fi
    NS=$(grep -c '^E' "$T/red" || true); NF_=$(grep -c '^F' "$T/red" || true)
    echo "red $R setup=$NS failed=$NF_"
    if [ "$NS" -gt 0 ]; then echo "group setup n=$NS"; grep '^E' "$T/red" | cut -f3 | sed 's/^/    /'; fi
    grep '^F' "$T/red" | cut -f2 | sort | uniq -c | sort -rn | sed 's/^ *\([0-9][0-9]*\) /\1	/' | while IFS='	' read -r cnt msg; do
      echo "group failed n=$cnt message=\"$msg\""
      awk -F'\t' -v m="$msg" '$1 == "F" && $2 == m { print "    " $3 }' "$T/red"
    done
    exit 0 ;;
  reach|credit)
    VERB=$1; R=${2:-}; [ -n "$R" ] || usage; SHAPE=''; RAW=no; shift 2
    while [ $# -gt 0 ]; do case "$1" in --shape) SHAPE=${2:-}; shift 2 ;; --raw) [ "$VERB" = reach ] || usage; RAW=yes; shift ;; *) usage ;; esac; done
    F=$R; [ -f "$F" ] || F="$RD/$R"
    [ -f "$F" ] || { echo "ViD evidence: no report $R" >&2; exit 1; }
    N=${F##*/}; SAVE=$RD; RD=$(dirname "$F"); cases_of "$N" > "$T/cases"; RD=$SAVE
    if [ -z "$SHAPE" ]; then
      [ -f "$F.tree" ] && SHAPE=$(sed -n 's/^shape=//p' "$F.tree" | head -n 1)
      [ -n "$SHAPE" ] || case "$N" in *.deployed.*) SHAPE=deployed ;; *) SHAPE=inline ;; esac
    fi
    inv_rows "$T/inv.rows"
    DD=no; dd_declared && DD=yes
    awk -F'\t' -v T="$T" -v dd="$DD" -v shape="$SHAPE" "$AWKJOIN"'
      BEGIN { while ((getline l < (T "/cases")) > 0) { split(l, a, " "); if (a[1] != "case") continue; cp = a[2]; sub(/::.*/, "", cp); k = ++nc[1, cp]; CI[1, cp, k] = a[2] } }
      { id = $1; kind = $2; t = $5; if (t !~ /^tests\//) next; p = t; sub(/ .*/, "", p)
        pop = (dd == "yes" && (kind == "journey" || $3 == "(process)"))
        if (pop && shape != "deployed") next; if (!pop && shape == "deployed") next
        sel = credit(1, p, id, $4); n = split(sel, ix, " ")
        for (q = 1; q <= n; q++) if (ix[q] != "") print CI[1, p, ix[q]] "\t" id }' "$T/inv.rows" > "$T/reach"
    # v0.9.7.0.11 (3.1, R1): the credit — the frozen rows when the report carries them, else every row reached
    if [ -f "$F.rows" ]; then grep -v '^$' "$F.rows" | sort -u > "$T/credit"; else cut -f2 "$T/reach" | sort -u > "$T/credit"; fi
    if [ "$VERB" = credit ]; then cat "$T/credit"
    elif [ "$RAW" = yes ]; then cat "$T/reach"
    else awk -F'\t' 'NR == FNR { C[$1] = 1; next } ($2 in C)' "$T/credit" "$T/reach"; fi
    exit 0 ;;
  kinds)
    [ -f "${2:-}" ] || usage
    inv_rows "$T/inv.rows"
    awk -F'\t' 'NR == FNR { if ($1 != "") W[$1] = 1; next } ($1 in W) { print $1 " " $2 " " ($3 == "" ? "-" : $3) }' "$2" "$T/inv.rows"
    exit 0 ;;
  *) usage ;;
esac

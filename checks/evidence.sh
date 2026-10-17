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
#     v0.9.7.1 (3.2b, R2): --history prints, instead of the row lines, each
#     case's newest result per row of the map — `<ROW-id><TAB><case><TAB>
#     <status><TAB><receipt><TAB><tree>`, or `<ROW-id><TAB>-<TAB>not run` —
#     by the same per-case rule (valid receipts, the credit, the shape, the
#     newest tested commit under the gate) with no staleness and no
#     amendment test: the builder brief's history, never evidence.
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
#     v0.9.7.1 (3.10, R10): every record is read once and git once per kind —
#     the receipts' .tree, .cases and .rows files in one pass each; under the
#     gate with a map naming no path, the rows' test files compared by blob in
#     one object lookup (else one diff per distinct tree); the bases' and the
#     amendments' ancestry from one history walk; one -U0 diff per distinct
#     pair of a test file's versions, only for a file the receipt ran a case
#     of; the files at <at> read in one batch. VID_EVIDENCE_HELD names the held
#     rows a caller already read. The answers are the same (case progress-parity).
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
#   ordinary <receipt>   v0.9.8 (3.4, R15): THE ONE ORDINARY-RECEIPT RULE. A receipt is ordinary unless its
#     name carries `.proof.` — checks/test.sh names every receipt of a `--purpose proof` request so, and only those
#     (its event and its .tree say purpose=proof too). Exit 0 ordinary, 1 a proof receipt, 2 usage. Every reader
#     that credits, claims, briefs, estimates or triggers skips a proof receipt by this mark: here `rows` (and
#     --history) never read one, and `reach` and `credit` credit nothing from one; checks/metrics.sh (claims, close
#     sets, completion), checks/brief.sh (grader and builder receipt inputs, returns), checks/plan.sh (red stamps),
#     checks/progress.sh, checks/test.sh (estimates, analyst triggers) and checks/testenv.sh (the heaviest case) the
#     same. Cost accounting and exports keep them.
# Read at the run's home (checks/plan.sh admission, checks/progress.sh).
# Always a reader: it writes nothing.
# Usage: sh checks/evidence.sh rows --at <tree-ish> --map <file> [--legacy] [--history] | red <receipt> | reach <report> [--shape inline|deployed] [--raw] | credit <report> [--shape inline|deployed] | kinds <rows file> | ordinary <receipt>
set -u
IFS='
'
usage() { echo 'ViD evidence: usage — sh checks/evidence.sh rows --at <tree-ish> --map <file> [--legacy] [--history] | red <receipt> | reach <report> [--shape inline|deployed] [--raw] | credit <report> [--shape inline|deployed] | kinds <rows file> | ordinary <receipt>' >&2; exit 2; }
# proofrcpt <receipt name or path>: the one ordinary-receipt rule (v0.9.8 R15) — a proof receipt's name carries .proof.
proofrcpt() { case "${1##*/}" in *.proof.*) return 0 ;; esac; return 1; }
RD=.vid/ledger-results; EV=.vid/metrics-events
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
# the case-to-row join, one code for `rows` and `reach` (v0.9.7.0.2 3.3): CI[i, p, k] and nc[i, p] hold receipt i's cases under test path p
# pick <i> <path> <token>: the case indexes of receipt i under <path> naming <token> — as written, or
# in the identifier spelling a test name must use (ROW_042 for ROW-042); credit <i> <path> <row> <derived>: by the row id, else its derived-from items
AWKJOIN='function pick(i, p, tok,   k, out, alt) { out = ""; alt = tok; gsub(/-/, "_", alt)
        if (((i, p) in CAT) && !index(CAT[i, p], tok) && !index(CAT[i, p], alt)) return ""   # v0.9.7.1 (R10): none of its cases names it
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
    shift; AT=''; MAP=''; LEG=no; UNTIL=''; HIST=no
    while [ $# -gt 0 ]; do case "$1" in --at) AT=${2:-}; shift 2 ;; --map) MAP=${2:-}; shift 2 ;; --legacy) LEG=yes; shift ;; --until) UNTIL=${2:-}; shift 2 ;; --history) HIST=yes; shift ;; *) usage ;; esac; done
    [ -n "$AT" ] && [ -f "$MAP" ] || usage
    NOW=$(git rev-parse -q --verify "$AT^{tree}" 2>/dev/null) || { echo "ViD evidence: $AT names no tree" >&2; exit 1; }
    # the valid receipts, oldest first: name tree base shape
    : > "$T/rec"
    if [ -f "$EV" ]; then
      # v0.9.8 (R15): never a proof receipt (`ordinary`, below)
      awk -v until="$UNTIL" "$AWKAT"' $1 == "invalidated" { r = kv("report"); if (r != "") inv[r] = 1; next }
        $1 == "ledger-run" { r = kv("report"); if (r == "" || r == "none" || index(r, ".proof.")) next; a = lastat(); if (a == "") a = "0000"; if (until != "" && a > until) next; printf "%s\t%09d\t%s\n", a, NR, r; seen[r] = 1 }
        END { for (r in inv) printf "INV\t%s\n", r }' "$EV" > "$T/ev.raw"
      grep '^INV	' "$T/ev.raw" | cut -f2 > "$T/inv" || true
      grep -v '^INV	' "$T/ev.raw" | sort -t "$(printf '\t')" -k1,1 -k2,2n | cut -f3 | awk '!s[$0]++' > "$T/names" || true
      # v0.9.7.1 (3.10, R10): each record read once — the .tree, .cases and .rows files in one pass each, git once
      # per kind (one object lookup, one history walk, one diff per distinct pair of file versions) — same rules
      ls -1 "$RD" 2>/dev/null > "$T/files" || : > "$T/files"
      awk -v rd="$RD" -v leg="$LEG" 'FILENAME == ARGV[1] { F[$0] = 1; next } FILENAME == ARGV[2] { I[$0] = 1; next }
        { r = $0; if ((r in I) || !(r in F)) next
          if ((r ".tree") in F) { tr = ""; bs = ""; sh = ""; f = rd "/" r ".tree"
            while ((getline l < f) > 0) { if (tr == "" && index(l, "tree=") == 1) tr = substr(l, 6); else if (bs == "" && index(l, "base=") == 1) bs = substr(l, 6); else if (sh == "" && index(l, "shape=") == 1) sh = substr(l, 7) }
            close(f); print "T\t" r "\t" tr "\t" bs "\t" sh }
          else if (leg == "yes") { c = r; sub(/\..*/, "", c); print "L\t" r "\t" c } }' "$T/files" "$T/inv" "$T/names" > "$T/cand"
      # the objects, in one lookup: each legacy name's commit tree, each tree (it must exist to be compared)
      { awk -F'\t' '$1 == "L" { print $3 "^{tree}" } $1 == "T" && $3 != "" { print $3 "^{tree}" }' "$T/cand"; } > "$T/objq"
      if [ -s "$T/objq" ]; then git cat-file --batch-check='%(objectname)' < "$T/objq" > "$T/obja" 2>/dev/null || : > "$T/obja"; else : > "$T/obja"; fi
      awk -F'\t' -v hist="$HIST" 'FILENAME == ARGV[1] { Q[++nq] = $0; next } FILENAME == ARGV[2] { k++; A[Q[k]] = ($0 ~ / missing$/) ? "" : $0; next }
        $1 == "L" { tr = A[$3 "^{tree}"]; if (tr == "") next; sh = ($2 ~ /\.deployed\./) ? "deployed" : "inline"; printf "%d\t%s\t%s\t%s\t%s\n", ++n, $2, tr, $3, sh; next }
        $1 == "T" { if ($3 == "") next; if (hist != "yes" && A[$3 "^{tree}"] == "") next; printf "%d\t%s\t%s\t%s\t%s\n", ++n, $2, $3, $4, ($5 == "" ? "inline" : $5) }' "$T/objq" "$T/obja" "$T/cand" > "$T/rec"
      # the cases (each receipt's .cases, else the results reader) and the frozen rows (.rows), each file read once
      : > "$T/cases"; : > "$T/cr"; : > "$T/cfiles"; : > "$T/rfiles"
      while IFS='	' read -r n r _t _b _s; do
        if [ -f "$RD/$r.cases" ]; then printf '%s\t%s\n' "$n" "$RD/$r.cases" >> "$T/cfiles"
        else cases_of "$r" | awk -v i="$n" '$1 == "case" { print i "\t" $2 "\t" $3 }' >> "$T/cases"; fi
        [ -f "$RD/$r.rows" ] && printf '%s\t%s\n' "$n" "$RD/$r.rows" >> "$T/rfiles"
      done < "$T/rec"
      [ -s "$T/cfiles" ] && awk -F'\t' '{ f = $2; while ((getline l < f) > 0) { split(l, a, " "); if (a[1] == "case") print $1 "\t" a[2] "\t" a[3] } close(f) }' "$T/cfiles" >> "$T/cases"
      [ -s "$T/rfiles" ] && awk -F'\t' '{ f = $2; while ((getline l < f) > 0) if (l ~ /[^ \t]/) { split(l, a, /[ \t]+/); print $1 "\t" (a[1] == "" ? a[2] : a[1]) } close(f) }' "$T/rfiles" >> "$T/cr"
    fi
    [ -f "$T/rec" ] || : > "$T/rec"
    [ -f "$T/cases" ] || : > "$T/cases"
    [ -f "$T/cr" ] || : > "$T/cr"
    GATED=no; [ -f checks/plan.sh ] && sh checks/plan.sh gate >/dev/null 2>&1 && GATED=yes
    # the rows: id kind actor derived test (the INVENTORY block)
    inv_rows "$T/inv.rows"
    awk -F'\t' '$5 ~ /^tests\// { p = $5; sub(/ .*/, "", p); print p }' "$T/inv.rows" | sort -u > "$T/tpaths"
    # each receipt's changed paths since its tree (diff.<n>): under the gate with a map naming no path, only the rows'
    # test files matter — their blobs compared in one lookup; otherwise one diff per distinct tree
    if [ "$HIST" = yes ]; then awk -F'\t' -v T="$T" '{ printf "" > (T "/diff." $1); close(T "/diff." $1) }' "$T/rec"
    elif [ "$GATED" = yes ] && ! awk -F'\t' '$3 ~ /[^ \t]/ { f = 1 } END { exit f ? 0 : 1 }' "$MAP"; then
      { printf '%s\n' "$NOW"; cut -f3 "$T/rec"; } | awk '!s[$0]++' > "$T/trees"
      awk 'NR == FNR { P[++np] = $0; next } { for (k = 1; k <= np; k++) print $0 ":" P[k] }' "$T/tpaths" "$T/trees" > "$T/blobq"
      if [ -s "$T/blobq" ]; then git cat-file --batch-check='%(objectname)' < "$T/blobq" > "$T/bloba" 2>/dev/null || : > "$T/bloba"; else : > "$T/bloba"; fi
      paste "$T/blobq" "$T/bloba" | awk -F'\t' '{ k = $1; v = ($2 ~ / missing$/) ? "-" : $2; print k "\t" v }' > "$T/blobs"
      awk -F'\t' -v T="$T" -v now="$NOW" 'FILENAME == ARGV[1] { p = index($1, ":"); B[substr($1, 1, p - 1), substr($1, p + 1)] = $2; if (substr($1, 1, p - 1) == now) TP[substr($1, p + 1)] = 1; next }
        { f = T "/diff." $1; printf "" > f; for (p in TP) if (B[$3, p] != B[now, p]) { print p > f; print $1 "\t" $3 "\t" p > (T "/dsp") } close(f) }' "$T/blobs" "$T/rec"
    else
      cut -f3 "$T/rec" | sort -u | while IFS= read -r tr_; do git diff --no-renames --name-only "$tr_" "$NOW" -- 2>/dev/null > "$T/dt.$tr_"; done
      awk -F'\t' -v T="$T" '{ f = T "/diff." $1; printf "" > f; s = T "/dt." $3; while ((getline l < s) > 0) print l > f; close(s); close(f) }' "$T/rec"
    fi
    # v0.9.6.1 (3.4): under the gate, which base descends from which — `<descendant><TAB><ancestor>`; and whether each
    # row's latest amendment is an ancestor of each receipt's base — both from one walk of the history
    : > "$T/desc"; : > "$T/amend"; : > "$T/anc"
    [ -f "$EV" ] && awk "$AWKAT"' $1 == "amended" { r = kv("row"); s = kv("sha"); if (r != "" && s != "") am[r] = s } END { for (r in am) print r "\t" am[r] }' "$EV" > "$T/amend"
    DOD=no; [ "$GATED" = yes ] && [ -s "$T/rec" ] && DOD=yes
    DOA=no; [ "$HIST" = no ] && [ -s "$T/amend" ] && [ -s "$T/rec" ] && DOA=yes
    if [ "$DOD" = yes ] || [ "$DOA" = yes ]; then
      cut -f4 "$T/rec" | grep -v '^$' | sort -u > "$T/bases"
      cut -f2 "$T/amend" | sort -u > "$T/amsh"
      cat "$T/bases" "$T/amsh" | awk '!s[$0]++' > "$T/rawc"
      sed 's/$/^{commit}/' "$T/rawc" | git cat-file --batch-check='%(objectname)' 2>/dev/null | paste "$T/rawc" - | awk -F'\t' '$2 !~ / missing$/ && $2 != "" { print $1 "\t" $2 }' > "$T/full"
      awk -F'\t' 'NR == FNR { F[$1] = $2; next } ($1 in F) { print F[$1] }' "$T/full" "$T/bases" | sort -u > "$T/bfull"
      if [ -s "$T/bfull" ]; then git rev-list --parents $(cat "$T/bfull") 2>/dev/null > "$T/graph" || : > "$T/graph"; else : > "$T/graph"; fi
      # reach: `<base full><TAB><commit full>` for every base and every base or amendment commit it reaches (itself too)
      awk -F'\t' 'FILENAME == ARGV[1] { Q[$2] = 1; next } FILENAME == ARGV[2] { n = split($0, a, " "); NP[a[1]] = n - 1; for (k = 2; k <= n; k++) PA[a[1], k - 1] = a[k]; next }
        { b = $1; gen++; sp = 0; ST[++sp] = b; while (sp > 0) { c = ST[sp--]; if (V[c] == gen) continue; V[c] = gen; if (c in Q) print b "\t" c
            for (k = 1; k <= NP[c]; k++) if (V[PA[c, k]] != gen) ST[++sp] = PA[c, k] } }' "$T/full" "$T/graph" "$T/bfull" > "$T/reach"
      if [ "$DOD" = yes ]; then
        awk -F'\t' 'FILENAME == ARGV[1] { F[$1] = $2; next } FILENAME == ARGV[2] { R[$1, $2] = 1; next }
          { B[++nb] = $0 } END { for (i = 1; i <= nb; i++) for (j = 1; j <= nb; j++) { b = B[i]; b2 = B[j]; if (length(b2) != 12 || b2 == substr(b, 1, 12)) continue
              if ((b in F) && (b2 in F) && ((F[b], F[b2]) in R)) print b "\t" b2 } }' "$T/full" "$T/reach" "$T/bases" > "$T/desc"
      fi
      if [ "$DOA" = yes ]; then
        cut -f4 "$T/rec" | grep -v '^$' | sort -u > "$T/rbases"
        awk -F'\t' 'FILENAME == ARGV[1] { F[$1] = $2; next } FILENAME == ARGV[2] { R[$1, $2] = 1; next } FILENAME == ARGV[3] { B[++nb] = $0; next }
          { s = $0; for (i = 1; i <= nb; i++) { b = B[i]; y = ((s in F) && (b in F) && ((F[b], F[s]) in R)) ? "yes" : "no"; print s "\t" b "\t" y } }' "$T/full" "$T/reach" "$T/rbases" "$T/amsh" > "$T/anc"
      fi
    fi
    # held rows (the row engine), later REQs (PRD phase: later)
    : > "$T/held"
    if [ -n "${VID_EVIDENCE_HELD:-}" ] && [ -f "${VID_EVIDENCE_HELD:-}" ]; then cp "$VID_EVIDENCE_HELD" "$T/held"   # v0.9.7.1 (R10): one reading shared by a caller
    elif [ -f checks/metrics.sh ]; then sh checks/metrics.sh row-state --table 2>/dev/null | awk -F'\t' 'NF >= 9 && $5 != "-" { print $1 }' > "$T/held" || true; fi
    : > "$T/later"
    if [ -f PRD.md ] && grep -q '^```vid-prd$' PRD.md; then
      sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id); ph = "pilot"
        for (i = 3; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/, "", f); ph = f } }
        if (id ~ /^REQ-[0-9]+$/) last[id] = ph } END { for (r in last) if (last[r] == "later") print r }' > "$T/later"
    fi
    # v0.9.6.1 amendment 5: under the gate, the changed lines of each changed test file, and its case blocks at now —
    # v0.9.7.1 (R10): one diff per distinct pair of file versions (the blob at the receipt's tree, the blob now)
    : > "$T/g4"
    if [ "$HIST" = no ] && [ "$GATED" = yes ] && [ -s "$T/rec" ]; then
      : > "$T/g4pairs"
      # only a test file the receipt ran a case of: the staleness rule is asked of no other (a credit needs a case there)
      awk -F'\t' '{ p = $2; sub(/::.*/, "", p); print $1 "\t" p }' "$T/cases" | awk '!s[$0]++' > "$T/ran"
      if [ -f "$T/dsp" ]; then cat "$T/dsp"
      else while IFS='	' read -r n _r tr_ _b _s; do
          grep -xF -f "$T/tpaths" "$T/diff.$n" 2>/dev/null | while IFS= read -r p; do printf '%s\t%s\t%s\n' "$n" "$tr_" "$p"; done
        done < "$T/rec"; fi | awk -F'\t' 'NR == FNR { R[$1, $2] = 1; next } ($1, $3) in R' "$T/ran" - > "$T/g4pairs"
      cut -f3 "$T/g4pairs" | sort -u > "$T/g4paths"
      awk -F'\t' '{ print $2 ":" $3; print "'"$NOW"':" $3 }' "$T/g4pairs" | awk '!s[$0]++' > "$T/g4q"
      if [ -s "$T/g4q" ]; then git cat-file --batch-check='%(objectname)' < "$T/g4q" 2>/dev/null | paste "$T/g4q" - > "$T/g4b" || : > "$T/g4b"; else : > "$T/g4b"; fi
      EMPTYB=$(git hash-object -t blob /dev/null)
      awk -F'\t' -v now="$NOW" -v e="$EMPTYB" 'FILENAME == ARGV[1] { B[$1] = ($2 ~ / missing$/) ? e : $2; next } { a = B[$2 ":" $3]; b = B[now ":" $3]; print $1 "\t" $3 "\t" (a == "" ? e : a) "\t" (b == "" ? e : b) }' "$T/g4b" "$T/g4pairs" > "$T/g4v"
      cut -f3,4 "$T/g4v" | sort -u | while IFS='	' read -r a b; do
        git diff -U0 "$a" "$b" 2>/dev/null | awk -v k="$a $b" '
          /^@@/ { h = $0; sub(/^@@ -[0-9,]+ \+/, "", h); sub(/ @@.*/, "", h); c = split(h, x, ","); s = x[1] + 0; w = (c > 1) ? x[2] + 0 : 1
            if (w == 0) { print k "\tL\t" s; print k "\tL\t" s + 1 } else for (q = s; q < s + w; q++) print k "\tL\t" q; next }
          /^(\+\+\+|---) / { next }
          /^[-+]/ { t = $0; while (match(t, /ROW[-_][0-9]+/)) { m = substr(t, RSTART, RLENGTH); gsub(/_/, "-", m); print k "\tM\t" m; t = substr(t, RSTART + RLENGTH) } }'
      done > "$T/g4d"
      awk -F'\t' 'FILENAME == ARGV[1] { D[$1] = D[$1] $2 "\t" $3 "\n"; next } { printf "P\t%s\t%s\n", $1, $2; k = $3 " " $4; n = split(D[k], L, "\n"); for (i = 1; i <= n; i++) if (L[i] != "") { split(L[i], f, "\t"); print f[1] "\t" $1 "\t" $2 "\t" f[2] } }' "$T/g4d" "$T/g4v" >> "$T/g4"
      # each changed test file at now, read in one batch: its case names' first lines (S) and its length (N), or absent (A)
      awk -F'\t' 'NR == FNR { P[$0] = 1; next } { c = $2; p = c; sub(/::.*/, "", p); if (!(p in P)) next; nm = c; sub(/\[.*\]$/, "", nm); sub(/.*::/, "", nm); if (nm != "" && !((p, nm) in S)) { S[p, nm] = 1; print p "\t" nm } }' "$T/g4paths" "$T/cases" > "$T/g4names"
      sed "s#^#$NOW:#" "$T/g4paths" | git cat-file --batch 2>/dev/null | LC_ALL=C awk -v pf="$T/g4paths" -v nf="$T/g4names" '
        BEGIN { while ((getline l < pf) > 0) PL[++np] = l; while ((getline l < nf) > 0) { split(l, a, "\t"); NM[a[1]] = NM[a[1]] "\001" a[2] } k = 0; st = "h" }
        function done_(  i, n, x) { n = split(substr(NM[p], 2), x, "\001"); for (i = 1; i <= n; i++) if (x[i] in S) print "S\t" p "\t" x[i] "\t" S[x[i]]; print "N\t" p "\t" ln }
        st == "s" { st = "h"; if ($0 == "") next }
        st == "h" { if ($0 == "") next; k++; p = PL[k]; if ($NF == "missing") { print "A\t" p; next } rem = $3 + 0; ln = 0; split("", S); n = split(substr(NM[p], 2), cur, "\001"); if (rem == 0) { done_(); st = "s"; next } st = "c"; next }
        st == "c" { ln++; for (i = 1; i <= n; i++) if (!(cur[i] in S) && index($0, cur[i])) S[cur[i]] = ln; rem -= length($0) + 1
          if (rem <= 0) { done_(); st = (rem == 0) ? "s" : "h" } next }' >> "$T/g4"
    fi
    DD=no; dd_declared && DD=yes
    awk -F'\t' -v T="$T" -v dd="$DD" -v gated="$GATED" -v now="$NOW" -v hist="$HIST" "$AWKJOIN"'
      function under(p, pref,   n, k, a) { n = split(pref, a, " "); for (k = 1; k <= n; k++) { if (a[k] == "") continue; if (p == a[k] || index(p, a[k] "/") == 1 || (substr(a[k], length(a[k])) == "/" && index(p, a[k]) == 1)) return 1 } return 0 }
      function stale(i, pref,   key, j) { key = i SUBSEP pref; if (key in ST) return ST[key]; ST[key] = 0
        for (j = 1; j <= nd[i]; j++) if (under(D[i, j], pref)) { ST[key] = 1; break } return ST[key] }
      BEGIN {
        while ((getline l < (T "/desc")) > 0) { split(l, a, "\t"); DESC[a[1], a[2]] = 1 }
        while ((getline l < (T "/rec")) > 0) { split(l, a, "\t"); NR_ = a[1] + 0; if (NR_ > nr) nr = NR_; RN[NR_] = a[2]; RT[NR_] = a[3]; RB[NR_] = a[4]; RSH[NR_] = a[5]
          f = T "/diff." NR_; while ((getline p < f) > 0) { nd[NR_]++; D[NR_, nd[NR_]] = p; DS[NR_, p] = 1 } close(f) }
        while ((getline l < (T "/cases")) > 0) { split(l, a, "\t"); i = a[1] + 0; cp = a[2]; sub(/::.*/, "", cp); k = ++nc[i, cp]; CI[i, cp, k] = a[2]; CS[i, cp, k] = a[3]; CAT[i, cp] = CAT[i, cp] "\001" a[2] }
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
          if (hist != "yes") {
            if ((i, p) in DS) { if (gated != "yes" || g4stale(i, p, id, sel)) continue }
            if (stale(i, pref)) continue
            if ((id in AM) && ANC[AM[id], RB[i]] != "yes") continue }
          n3 = split(sel, ix, " ")
          for (q = 1; q <= n3; q++) { if (ix[q] == "") continue; c = CI[i, p, ix[q]]
            # v0.9.6.1: under the gate a result on an ancestor commit never overwrites one on its descendant
            if (gated == "yes" && (c in RI) && ((RB[RI[c]], RB[i]) in DESC)) continue
            R[c] = CS[i, p, ix[q]]; RI[c] = i }
        }
        if (hist == "yes") { nh = 0; for (c in R) { nh++; print id "\t" c "\t" R[c] "\t" RN[RI[c]] "\t" RT[RI[c]] } if (!nh) print id "\t-\tnot run"; next }
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
    # v0.9.8 (R15): a proof receipt credits nothing — but test.sh's own outside() reads a pending report raw
    if proofrcpt "$F" && [ "$RAW" = no ]; then exit 0; fi
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
  ordinary)   # v0.9.8 (R15): the one rule, for every shell reader
    [ -n "${2:-}" ] || usage
    if proofrcpt "$2"; then exit 1; fi; exit 0 ;;
  kinds)
    [ -f "${2:-}" ] || usage
    inv_rows "$T/inv.rows"
    awk -F'\t' 'NR == FNR { if ($1 != "") W[$1] = 1; next } ($1 in W) { print $1 " " $2 " " ($3 == "" ? "-" : $3) }' "$2" "$T/inv.rows"
    exit 0 ;;
  *) usage ;;
esac

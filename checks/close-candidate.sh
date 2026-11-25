#!/bin/sh
# Purpose: close.sh's part — a stage's candidate, its full run C3 and its grade S1, ViD's own in GitHub manual (FB-2 C3; FB-3 A1.6). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
# --- v0.26.10.26.1 (R1–R5): a stage's candidate, its full run C3 and its grade S1, in .vid/decide/stage/<N>/<c>/ ---
SD=$D/stage; SX=$(mktemp -d "$PWD/.vid/round/stg.XXXXXX"); trap 'rm -rf "$SX"' EXIT
# GM-4 E12 (GM M3: every pending change reaches the team only through the apply): the spec as the team has it. In GitHub manual
# PRD.md, INVENTORY.md, STAGES.md and ARCHITECTURE.md at the applied commit (lib.sh applied), copied once into $SX/spec (a file the
# commit lacks, absent), else the working tree: sf <file>, the path to read; SPD, that folder, where stages.sh runs (it reads them
# from the folder it runs in), each read through lib.sh's mustread, written out where it runs; lrev, the commit whose history is read
if manual; then SPD=$SX/spec; mkdir -p "$SPD"; _sa=$(applied); for _f in PRD.md INVENTORY.md STAGES.md ARCHITECTURE.md; do { [ -n "$_sa" ] && git show "$_sa:./$_f" > "$SPD/$_f" 2>/dev/null; } || rm -f "$SPD/$_f"; done; else SPD=$PWD; fi
sf() { printf '%s/%s\n' "$SPD" "$1"; }
lrev() { if manual; then applied; else echo HEAD; fi; }
snc() { c0=''; for d in $(ls "$SD/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$SD/$1/$d/ask" ] && c0=$d; done; echo "$c0"; }
plr() { [ -f "$SX/plr" ] || { mustread "$SX/plr0" planner rows; grep -v '^#' "$SX/plr0" > "$SX/plr"; }; }   # R6: an unreadable plan stops the close
# upto <N>: every row of stages 1 to N, by the admission's join: planner.sh rows' stage (its moved: counts), else stages.sh's; a seam's is the planner's (FB-4 A2)
upto() { [ -f "$SX/up$1" ] && return 0; plr; ( cd "$SPD" && mustread "$SX/st0" stages scope --upto "$1" )
  awk -F'\t' -v c="$1" 'FILENAME == ARGV[1] { if ($5 ~ /^[0-9]+$/ || $5 == "later") P[$1] = ($5 != "later" && $5 + 0 <= c); next }
    !($1 in P) || P[$1] { print } END { for (r in P) if (P[r]) print r }' "$SX/plr" "$SX/st0" | sort -u > "$SX/up$1"; }
sstages() { plr; x=$(awk -F'\t' '$5 ~ /^[0-9]+$/ { print $5 }' "$SX/plr" | sort -nu); echo "${x:-1}"; }
# psteps: the plan's steps and rows, `<step> TAB <row>`, ranges expanded; sst: each step's stage, the lowest that holds all its rows
psteps() { [ -f "$SX/ps" ] || plan_block | awk "$RNG"' function tr(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
  /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id)
    for (i = 2; i <= n; i++) { x = tr(f[i]); if (x !~ /^rows:/) continue; m = split(substr(x, 6), t, /[ ,\t]+/)
      for (j = 1; j <= m; j++) { y = t[j]; if (y == "") continue; q = split(rng(y), e, " "); for (k = 1; k <= q; k++) print id "\t" e[k] } } }' > "$SX/ps"; }
# GM-4 K4 (D4, GM-3 S2): in GitHub manual a step with a published ticket (not withdrawn) is of the stage its first ticket of kind step
# or skeleton names in its recorded writing's header (`- stage: <k>`), as the planner reads it; the others by the rule above
pubst() { manual && [ -f "$LOG" ] || return 0; awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "withdrawn" { W[$2] = 1 } $1 == "published" && $2 ~ /^[0-9]+$/ && !($2 in K) { O[++n] = $2; K[$2] = kv("kind"); S[$2] = kv("step") }
    END { for (i = 1; i <= n; i++) if (!(O[i] in W) && K[O[i]] ~ /^(step|skeleton)$/ && S[O[i]] != "") print O[i] " " S[O[i]] }' "$LOG" |
  while read -r _pn _ps; do [ -f ".vid/tw/out/issue-$_pn.md" ] || continue; grep -q "^$_ps$TAB" "$SX/sst" && continue
    _pk=$(awk '/^## / { h = ($0 ~ /^## Header[ \t]*$/); next } h && index($0, "- stage: ") == 1 { v = substr($0, 10); sub(/,.*/, "", v); gsub(/[ \t]/, "", v); print v; exit }' ".vid/tw/out/issue-$_pn.md")
    case $_pk in ''|*[!0-9]*) ;; *) printf '%s\t%s\n' "$_ps" "$_pk" >> "$SX/sst" ;; esac; done; }
sst() { [ -f "$SX/sst" ] && return 0; psteps; : > "$SX/sst"; pubst; for N in $(sstages); do upto "$N"
    awk -F'\t' -v N="$N" -v U="$SX/up$N" -v A="$SX/sst" 'BEGIN { while ((getline l < U) > 0) W[l] = 1; while ((getline l < A) > 0) { split(l, x, "\t"); G[x[1]] = 1 } }
      { S[$1] = 1; if (!($2 in W)) out[$1] = 1 } END { for (s in S) if (!(s in out) && !(s in G)) print s "\t" N }' "$SX/ps" >> "$SX/sst"; done; }
stp() { sst; awk -F'\t' -v n="$1" '$2 == n { print $1 }' "$SX/sst"; }
stof() { sst; awk -F'\t' -v s="$1" '$1 == s { print $2 }' "$SX/sst"; }
hstate() { sed -n "s/^row $1 \([^ |]*\).*/\1/p" "$HAND" 2>/dev/null | tail -n 1; }
trows() { awk -v n="$1" '($1 == "published" || $1 == "amended") && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) r = substr($i, 6) } END { print r }' "$LOG" 2>/dev/null | tr , '\n' | grep -v '^-*$' || true; }
anc() { git --git-dir=.vid/code merge-base --is-ancestor "$1" "$2" 2>/dev/null; }
# FB-7 A1: a build is held while a row of its runs landed since its full run was asked and is not settled at a commit the build holds.
# Held, its full run and its staging run are not read as passed, and no okay, staging run, walk or close is owed at it; nothing is withdrawn
# or asked: it ends once the row is settled at a commit it holds, or leaves the stages, or the next build is named.
# tmerge <row>: the merge of the newest merged ticket that holds the row now, its amendments read. lset <row> <commit>: settled (accepted,
# by ruling, owed or paid) at a commit <commit> holds, by that merge; a row no merged ticket holds (accepted outside ViD), by its state
# alone. lout <row> <N>: a row that holds nothing: out of the stages up to N, a known limit, or the plan's limit, later row or record.
# bheld <N> <candidate folder>: the first row that holds the build, else exit 1. lopen <N>: each landed row of the stages up to N that a
# merged ticket holds and that is not settled, whatever build it was settled at
tmerge() { awk -v r="$1" '($1 == "published" || $1 == "amended") { if (!($2 in o)) o[$2] = ++k; for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) R[$2] = substr($i, 6) } END { for (t in R) if (index("," R[t] ",", "," r ",")) print o[t], t }' "$LOG" 2>/dev/null | sort -rn | cut -d' ' -f2 | while read -r _t; do _m=$(mrg "$_t" | cut -d' ' -f2); [ -z "$_m" ] || { echo "$_m"; break; }; done; }
lset() { case $(hstate "$1") in accepted|accepted-by-ruling|owed|paid) ;; *) return 1 ;; esac; [ -n "${2:-}" ] || return 0; _tm=$(tmerge "$1"); [ -z "$_tm" ] || [ "$_tm" = "$2" ] || anc "$_tm" "$2"; }
lout() { ! grep -qxF "$1" "$SX/up$2" || limited "$1" || [ "$(hstate "$1")" = known-limit ] || awk -F'\t' -v r="$1" '$1 == r && $6 ~ /^(limit|later|record)$/ { f = 1 } END { exit !f }' "$SX/plr"; }
bheld() { [ -s "$D/landed" ] && [ -f "$2/ask" ] || return 1; upto "$1"; plr; _ba=$(sed -n "s/^asked$TAB//p" "$2/ask" | head -n 1); _bx=$(cat "$2/commit" 2>/dev/null)
  { cut -d' ' -f1 "$2/rows" "$2/cs/rows" 2>/dev/null; sed -n "s/^left$TAB//p" "$2/ask" | tr ' ' '\n'; awk -F'\t' '$1 == "chunk" { n = split($4, a, " "); for (i = 1; i <= n; i++) print a[i] }' "$2/ask" "$2/cs/ask" 2>/dev/null; } | sort -u > "$SX/lh"
  for _br in $(awk -v a="$_ba" -v LH="$SX/lh" 'BEGIN { while ((getline l < LH) > 0) W[l] = 1 } { r = $1; sub(/-T[0-9]+$/, "", r) } (r in W) && $3 >= a { print r }' "$D/landed" | sort -u); do lset "$_br" "$_bx" || lout "$_br" "$1" || { echo "$_br"; return 0; }; done; return 1; }
lopen() { [ -s "$D/landed" ] || return 0; upto "$1"; plr; for _lr in $(awk '{ r = $1; sub(/-T[0-9]+$/, "", r); print r }' "$D/landed" | sort -u); do lset "$_lr" || lout "$_lr" "$1" || [ -z "$(tmerge "$_lr")" ] || echo "$_lr"; done; return 0; }
# FB-7 A3: packs <folder> <limits file>: its rows (`<row> <secs>`) into packed, chunks of at most $M minutes; a known limit is still run, in
# the shortest chunk of the others', never in a chunk of limits alone (the pass ignores a limit's result, so such a chunk would read green
# unrun); with limits alone the run asks no row
packs() { awk -v m=$((M * 60)) -v LF="$2" 'BEGIN { while ((getline l < LF) > 0) L[l] = 1 } ($1 in L) { q[++nq] = $1; qs[nq] = $2; next } { if (n && t + $2 > m) { n++; t = 0 } else if (!n) n = 1; t += $2; T[n] = t; c[n] = c[n] (c[n] == "" ? "" : " ") $1 }
    END { for (i = 1; n && i <= nq; i++) { b = 1; for (j = 2; j <= n; j++) if (T[j] < T[b]) b = j; c[b] = c[b] " " q[i]; T[b] += qs[i] } for (i = 1; i <= n; i++) print i "\t" c[i] }' "$1/rows" > "$1/packed"; [ -s "$1/packed" ] || : > "$1/rows"; }
# sdue <N> (R1): exit 0 when stage N's candidate is due; else what keeps it, by kind, in $SX/why<N>
sdue() { N=$1; W=$SX/why$N; : > "$W"; plr
  ! manual || [ -n "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" 2>/dev/null | tail -n 1)" ] || echo 'the handed record names no engines yet' >> "$W"   # FB-3 A1.5: not due, so the round's asks never stop on it
  for s in $(stp "$N"); do t=$(tix "$s")
    if [ -z "$t" ]; then awk -F'\t' -v s="$s" '$1 == s { print $2 }' "$SX/ps" | while read -r r; do awk -F'\t' -v r="$r" '$1 == r && $6 ~ /^(limit|later|record)$/ { f = 1 } END { exit !f }' "$SX/plr" || case $(hstate "$r") in known-limit|accepted|accepted-by-ruling) ;; *) false ;; esac || { echo "step $s not merged"; break; }; done >> "$W"; continue; fi   # an owed row, a seam's too, is sent in a ticket; FB-3 A4: a row accepted outside ViD is in
    printf '%s\n' "$t" | while read -r x y; do [ -n "$(mrg "$x")" ] || { echo "step $s not merged"; break; }; done >> "$W"
    ! wdue "$s" || echo "step $s owed a ticket" >> "$W"
    k=$(nk "$s"); [ -z "$k" ] || [ -f "$C/$s/$k/withdrawn" ] || closed "$s" || [ -f "$C/$s/$k/done" ] || echo "close $s out" >> "$W"
    printf '%s\n' "$t" | while read -r x y; do trows "$x"; done | sort -u | while read -r r; do case $(hstate "$r") in accepted|accepted-by-ruling|known-limit|owed|paid) ;; failing) echo "row $r failing" ;; held) echo "row $r held" ;; *) echo "row $r not decided" ;; esac; done >> "$W"; done
  for _sl in $(lopen "$1"); do grep -q "^row $_sl " "$W" || echo "row $_sl landed, not decided" >> "$W"; done   # FB-7 A1: an earlier stage's row too
  [ ! -s "$W" ] || return 1
  sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$N" '$1 > n { f = 1 } END { exit f }' || return 1   # a later stage's C3 covers N
  for e in $(sstages); do [ "$e" -lt "$N" ] || continue; [ -n "$(stp "$e")" ] || continue; set -- $(sclosed "$e"); [ -n "${2:-}" ] && { [ -z "$(snc "$e")" ] || [ "$2" = "$(snc "$e")" ]; } || { echo "stage $e not closed at its newest candidate" >> "$W"; return 1; }; done   # v0.26.10.26.5 (R5a): stages close in order
  c=$(snc "$N"); [ -n "$c" ] || return 0; K=$SD/$N/$c; [ -f "$K/named" ] || return 0   # a post that failed: asked again
  [ ! -f "$K/withdrawn" ] || return 0   # 0.26.10.29.2 (R2): a candidate a re-cut withdrew, its C3 out or not: a new one is due
  # FB-7 A1: a held build, its full run passed or not, is replaced as a passed one is, at a merge of its stages' rows it does not hold
  if [ -f "$K/passed" ] || bheld "$N" "$K" > /dev/null; then X=$(sed -n "s/^commit$TAB//p" "$K/ask" | head -n 1); upto "$N"
    while IFS=$TAB read -r p t H M; do [ "$M" != - ] && [ -n "$M" ] || continue; ! anc "$M" "$X" || continue; trows "$t" | grep -qxF -f "$SX/up$N" && return 0; done < "$D/merges"
    return 1; fi
  [ -f "$K/done" ] && againK "$K"; }
# the candidate: the recorded merge holding every other; FB-3 A4: in GitHub manual, with no merge on record, main's newest commit
newest_merge() { MS=$(cut -f4 "$D/merges" 2>/dev/null | grep -v '^-*$'); last=''; [ -n "$MS" ] || ! manual || MS=$(git --git-dir=.vid/code rev-parse -q --verify refs/heads/main 2>/dev/null)
  for c in $MS; do a=1; for o in $MS; do [ "$o" = "$c" ] || anc "$o" "$c" || a=''; done; [ -z "$a" ] || last=$c; done; [ -n "$last" ] || last=$(printf '%s\n' "$MS" | tail -n 1); echo "$last"; }
# sreqs <N>: the stage's requirements, invariants left out
sreqs() { ( cd "$SPD" && mustread "$SX/sq$1" stages scope --upto "$1" --reqs ); grep '^REQ-' "$SX/sq$1" | sort -u > "$SX/rq$1"; : > "$SX/rp$1"
  [ "$1" -lt 1 ] || { ( cd "$SPD" && mustread "$SX/sp$1" stages scope --upto "$(($1 - 1))" --reqs ); grep '^REQ-' "$SX/sp$1" | sort -u > "$SX/rp$1"; }; comm -23 "$SX/rq$1" "$SX/rp$1"; }
# v0.26.10.27.4 (R1): lreqs, every live requirement of every stage
# (`later` ones apart, in $SX/dfr); pmap, the plan block as `M <step> <module>` and `R <step> <row>` lines, ranges expanded;
# addset <time>, the requirements of every /vid add landed after <time>: its rows', and those of the rows of every step sharing a
# module with the add's steps, by the plan's modules:
lreqs() { sh "$HERE/prd.sh" --effective "$(sf PRD.md)" 2>/dev/null | awk -F'|' -v DF="$SX/dfr" '{ k = $1; gsub(/[ \t]/, "", k); if (k !~ /^REQ-[0-9]/) next; l = 0; for (i = 3; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^phase:[ \t]*later$/) l = 1 } if (l) print k > DF; else print k }' | sort -u; [ -f "$SX/dfr" ] && sort -u "$SX/dfr" -o "$SX/dfr" || : > "$SX/dfr"; }
pmap() { plan_block | awk "$RNG"' function tr(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
  /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id)
    for (i = 2; i <= n; i++) { x = tr(f[i]); if (x ~ /^modules:/) { m = split(substr(x, 9), a, /[ ,\t]+/); for (j = 1; j <= m; j++) if (a[j] != "") print "M", id, a[j] }
      if (x !~ /^rows:/) continue; m = split(substr(x, 6), t, /[ ,\t]+/)
      for (j = 1; j <= m; j++) { y = t[j]; if (y == "") continue; q = split(rng(y), e, " "); for (k = 1; k <= q; k++) print "R", id, e[k] } } }'; }
addset() { pmap > "$SX/pm"; : > "$SX/ar"; for X in $(ls -d "$D"/drafts/* 2>/dev/null); do [ -f "$X/landed" ] && head -n 1 "$X/why" | grep -q '^/vid add:' || continue
    l=$(printf %.12s "$(cat "$X/landed")"); lt=$(awk -v l="$l" '$2 == l { print $3; exit }' "$D/landed" 2>/dev/null); [ -n "$lt" ] && [ "$lt" \> "$1" ] || continue
    awk -F'\t' '($1 == "added" || $1 == "reset") && $3 != "transition" { print $2 }' "$X/sets" >> "$SX/ar"; cut -d' ' -f2 "$X/steps" 2>/dev/null | sort -u > "$SX/as"
    awk -v AS="$SX/as" 'BEGIN { while ((getline l < AS) > 0) S[l] = 1 } $1 == "M" && ($2 in S) { print $3 }' "$SX/pm" | sort -u > "$SX/am"
    awk -v AM="$SX/am" 'BEGIN { while ((getline l < AM) > 0) M[l] = 1 } $1 == "M" && ($3 in M) { print $2 }' "$SX/pm" | sort -u > "$SX/ss"
    awk -v SS="$SX/ss" 'BEGIN { while ((getline l < SS) > 0) S[l] = 1 } $1 == "R" && ($2 in S) { print $3 }' "$SX/pm" >> "$SX/ar"; done
  sort -u "$SX/ar" -o "$SX/ar"; rreqs "$SX/ar"; }
# rreqs: a row's requirements, its derived-from items
rreqs() { sed -n '/^```vid-inventory/,/^```$/p' "$(sf INVENTORY.md)" | awk -F'|' -v I="$1" 'BEGIN { while ((getline l < I) > 0) W[l] = 1 } { a = $1; gsub(/[ \t]/, "", a) } (a in W) { n = split($7, t, /[ ,]+/); for (i = 1; i <= n; i++) if (t[i] ~ /^REQ-/) print t[i] }' | sort -u; }
# FB-7 A1, D3: replaced <N> <c> [say]: the runs of stage N's candidates below c that are out, or red and open until now: the staging run, not
# passed (`withdrawn`), and the full run, replaced while it was held (`done`): told at the naming (say) and closed on GitHub, its mark written only once it
# is closed: a failed close is tried again, the close alone, at each whole owed (reclose). A red one the read no longer shows open is marked alone
rpl1() { [ -f "$3/ask" ] && [ ! -f "$3/passed" ] && [ ! -f "$3/$4" ] || return 0; _ri=$(sed -n "s/^issue$TAB//p" "$3/ask" | head -n 1); awk -F'\t' -v i="$_ri" '$1 == "issue" && $2 == i { f = 1; exit } END { exit !f }' "$RD" 2>/dev/null || { [ ! -f "$3/done" ] || [ ! -f "$RD" ] || { : > "$3/$4"; return 0; }; }
  printf 'vid: withdrawn. Stage %s has a new candidate, %s; its rows run at that candidate'"'"'s %s run. A later report for this one is not read.\n' "$1" "$2" "$5" > .vid/round/wc
  [ -z "${6:-}" ] || gh_ comment "$_ri" --body-file .vid/round/wc > /dev/null 2>&1 || true
  gh_ close "$_ri" > /dev/null 2>&1 || return 0; : > "$3/$4"; if [ "$4" = done ]; then ev "close-done step=stage-$1 issue=$_ri"; else ev "stage-cs-withdrawn stage=$1 issue=$_ri"; fi; }
replaced() { for _ro in $(ls "$SD/$1" 2>/dev/null | grep -E '^[0-9]+$'); do [ "$_ro" -lt "$2" ] || continue; rpl1 "$1" "$2" "$SD/$1/$_ro/cs" withdrawn staging "${3:-}"; [ -f "$SD/$1/$_ro/withdrawn" ] || rpl1 "$1" "$2" "$SD/$1/$_ro" done full "${3:-}"; done; return 0; }
cmd_ask_stage() { N=$1; sdue "$N" || die "no candidate is due for stage $N: $(paste -sd ';' "$SX/why$N")"; E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); [ -n "$E" ] || die 'the handed record names no engines yet'
  set -- $E; P1=$1; shift; P2=$*; M=$(skey close-chunk-minutes); M=${M:-20}; c=$(snc "$N"); if [ -n "$c" ] && [ ! -f "$SD/$N/$c/named" ]; then :; else c=$(( ${c:-0} + 1 )); fi
  K=$SD/$N/$c; mkdir -p "$K"; if [ -f "$K/ask" ]; then X=$(cat "$K/commit"); else X=$(newest_merge); fi; [ -n "$X" ] || die "no merge for stage $N's candidate"; echo "$X" > "$SX/cm" || exit 1; put "$K/commit" < "$SX/cm" || exit 1; upto "$N"
  if [ ! -f "$K/ask" ]; then
    # C3's rows (R2): the rows and regression rows of every ticket merged at or before the candidate, of stages 1 to N
    awk '$1 == "published" { k[$2] = 1 } $1 == "withdrawn" { delete k[$2] } END { for (n in k) print n }' "$LOG" | sort -n | while read -r t; do m=$(mrg "$t" | cut -d' ' -f2); [ -n "$m" ] && { [ "$m" = "$X" ] || anc "$m" "$X"; } || continue
      awk '/^## / { x = substr($0, 4); next } x == "Rows" && /^> / { split(substr($0, 3), a, "|"); i = a[1]; gsub(/[ \t]/, "", i); if (i !~ /^[A-Z]+-[0-9]/) { i = a[2]; gsub(/[ \t]/, "", i) } print i } x == "Regression rows" && /^- [A-Z]+-[0-9]/ { print $2 }' ".vid/tw/out/issue-$t.md" 2>/dev/null; done | awk '!s[$0]++' > "$SX/cr"
    : > "$K/rows"; : > "$SX/dw"; : > "$SX/lm"   # FB-7 A2: none left out for an open ticket or another close's red: red, such a row waits (close-decide.sh)
    while read -r r; do grep -qxF "$r" "$SX/up$N" || continue
      if owed_ "$r"; then echo "$r" >> "$SX/dw"; continue; fi; ! limited "$r" || echo "$r" >> "$SX/lm"; printf '%s %s\n' "$r" "$(secs "$r")" >> "$K/rows"; done < "$SX/cr"
    packs "$K" "$SX/lm"   # FB-7 A3: a known limit is still run
    DW=$(paste -sd ' ' "$SX/dw"); { printf 'close: stage-%s\ncommit: %s\nengines: %s\n\n' "$N" "$X" "$E"
      if manual; then RF='by: and the name of whoever made it, its commit the one above, with one results file or more (.xml), of any name'; else RF='by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk'; fi   # FB-3 A1.5
      printf 'The full run of stage %s'"'"'s candidate: run these rows at the commit above, chunk by chunk, in the engines each chunk names, phase 1, the primary engine, first, then phase 2; and chunk p1cx, every other test case of the suite in the primary engine. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, %s, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`.\n\n' "$N" "$RF"
      while IFS=$TAB read -r k rows; do printf -- '- chunk p1c%s, %s: %s\n' "$k" "$P1" "$rows"; done < "$K/packed"
      [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf -- '- chunk p2c%s, %s: %s\n' "$k" "$P2" "$rows"; done < "$K/packed"
      printf -- '- chunk p1cx, %s: every other test case of the suite, but the cases of the deploy-owed rows %s; when no case is left outside the rows, send the cases file with no test case and the line `none left` in results.txt\n' "$P1" "${DW:-none}"; } > "$K/body"   # v0.26.10.26.7 (R7)
    n=$(gh_ run-ask --step "stage-$N" --commit "$X" --title "Close run: stage $N, candidate $c" --body-file "$K/body") || die 'the C3 ask could not be posted'
    { printf 'issue\t%s\ncommit\t%s\nasked\t%s\n' "$n" "$X" "$(stamp)"; while IFS=$TAB read -r k rows; do printf 'chunk\tp1c%s\t%s\t%s\n' "$k" "$P1" "$rows"; done < "$K/packed"
      [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf 'chunk\tp2c%s\t%s\t%s\n' "$k" "$P2" "$rows"; done < "$K/packed"; printf 'chunk\tp1cx\t%s\t\nleft\t%s\n' "$P1" "$DW"; } > "$K/ask"
    ev "close-asked step=stage-$N issue=$n commit=$X chunks=$(grep -c '^chunk' "$K/ask") ask=$c"; echo "asked $n close stage-$N"; fi
  # S1's requirements (R3): at the first candidate the stage's all; later the touched since the previous candidate, and those with no grade yet
  # v0.26.10.27.4 (R1): at the final stage, the end grade: every live requirement of every stage, `later` ones deferred; after an add, its set too
  FN=no; [ "$N" -ge 1 ] && [ "$N" = "$(finals)" ] && FN=yes; : > "$SX/dfr"
  # 0.26.11.1.2 (R10): at the final stage the full set is asked, and its s1ask marked `end yes`, until an earlier candidate's end grade
  # is done (its s1ask marked and its s1done); the candidate's number no longer decides. Records before the marker: one more full ask
  FULL=no; if [ "$FN" = yes ]; then FULL=yes; for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do [ "$o" -lt "$c" ] && grep -qx "end${TAB}yes" "$SD/$N/$o/s1ask" 2>/dev/null && [ -f "$SD/$N/$o/s1done" ] && FULL=no; done; fi
  if [ ! -f "$K/s1ask" ]; then if [ "$FN" = yes ]; then lreqs > "$SX/all"; else sreqs "$N" > "$SX/all"; fi; if [ "$c" -gt 1 ] && [ "$FULL" = no ]; then PX0=$(cat "$SD/$N/$((c - 1))/commit" 2>/dev/null)
      while IFS=$TAB read -r p t H M2; do [ -n "$M2" ] && [ "$M2" != - ] || continue; [ -z "$PX0" ] || ! anc "$M2" "$PX0" || continue; trows "$t"; done < "$D/merges" | sort -u > "$SX/tr"
      for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do O=$SD/$N/$o; [ "$o" -eq $((c - 1)) ] && [ -f "$O/s1ask" ] && [ ! -f "$O/s1done" ] && sed -n "s/^reqs$TAB//p" "$O/s1ask" | tr ' ' '\n'; done > "$SX/wr"   # the previous candidate's S1, withdrawn or still out, ungraded
      PA=$(sed -n "s/^asked$TAB//p" "$SD/$N/$((c - 1))/ask" 2>/dev/null); [ "$FN" = yes ] && ( addset "${PA:-0}" ) > "$SX/add" || : > "$SX/add"   # a subshell: addset's loop leaves X, the candidate's commit, alone
      { rreqs "$SX/tr"; cat "$SX/wr" "$SX/add"; cut -f1 "$SD/$N/s1" 2>/dev/null | sort -u | comm -13 - "$SX/all"; } | grep . | sort -u | comm -12 - "$SX/all" > "$SX/ask"; else cp "$SX/all" "$SX/ask"; fi
    for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do O=$SD/$N/$o; [ "$o" -lt "$c" ] && [ -f "$O/s1ask" ] && [ ! -f "$O/s1done" ] && [ ! -f "$O/s1withdrawn" ] || continue   # an older S1 still out: withdrawn
      i=$(sed -n "s/^issue$TAB//p" "$O/s1ask"); printf 'vid: withdrawn. Stage %s has a new candidate, %s; this grade is asked again there. A later report for it is not read.\n' "$N" "$c" > .vid/round/wc
      gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || true; gh_ close "$i" > /dev/null 2>&1 || true; : > "$O/s1withdrawn"; done
    if [ -s "$SX/ask" ]; then RQ=$(paste -sd ' ' "$SX/ask"); { printf 'grade: stage-%s\ncommit: %s\nrequirements: %s\n\n' "$N" "$X" "$RQ"
        [ "$FN" != yes ] || { printf 'This is the end grade: grade the joins across stages, every journey whole, and each line of the grading checklist.\n\n'; [ ! -s "$SX/dfr" ] || printf 'Deferred, not asked: %s\n\n' "$(paste -sd ' ' "$SX/dfr")"; }
        printf 'Grade each requirement, in a fresh context, against the grading checklist and its rows'"'"' fail-ifs: pass, partial, facade (looks built, isn'"'"'t) or absent, each with its reason; then each finding, tagged bug or rule. One line per requirement, `REQ-<n> <word> — <reason>`, then `finding: bug|rule — <line>`.'; manual || printf ' Report it as vid-results/grade-<this issue>-<k>, its grade.txt by: GR, its commit the one above, then comment `vid: reported s1-<k>` here. Comment `vid: started` when it starts; send it again only after a comment `vid: again s1`, or a refusal.'; echo; } > "$K/s1body"
      # FB-3 A1.6: in GitHub manual no issue: ViD's own review makes it (review.sh), under a number of its own (lib.sh ownask)
      if manual; then i=$(printf '0900%03d%03d' "$N" "$c"); else i=$(gh_ grade-ask --stage "$N" --commit "$X" --title "Stage grade: stage $N, candidate $c" --body-file "$K/s1body") || die 'the S1 ask could not be posted'; fi
      { printf 'issue\t%s\ncommit\t%s\nasked\t%s\nreqs\t%s\n' "$i" "$X" "$(stamp)" "$RQ"; [ "$FULL" = no ] || printf 'end\tyes\n'; } > "$K/s1ask"; manual || echo "asked $i grade stage-$N"; fi; fi
  # the candidate's line once both are posted, or C3's alone
  # v0.26.10.26.2 (R1): naming a newer candidate withdraws the stage's earlier CS still out, which then counts as done (replaced, below)
  [ -f "$K/named" ] || replaced "$N" "$c" say
  [ -f "$K/named" ] || sh "$HERE/walk.sh" withdraw --stage "$N" --below "$c" 2>/dev/null || true   # v0.26.10.26.4 (R1): and its older W1
  [ -f "$K/named" ] || { echo "candidate $N | stand-in: RM at $(printf %.12s "$X") candidate $c" >> "$HAND"; ev "stage-candidate stage=$N commit=$X candidate=$c"; : > "$K/named"; echo "candidate $N $c"; }
  s1own; }
# s1own (FB-3 A1.6): ViD's own grade at this candidate not recorded yet, its line, said at each read until it is (review.sh due)
s1own() { i=$(sed -n "s/^issue$TAB//p" "$K/s1ask" 2>/dev/null); ownask "${i:-}" && [ ! -f "$K/s1done" ] && [ ! -f "$K/s1withdrawn" ] && [ ! -d "$D/review/grade-$i-1" ] || return 0; echo "review stage-$N $(sed -n "s/^commit$TAB//p" "$K/s1ask" | cut -c1-12)"; }
# stage_green: C3 passed; each of the stage's steps with no closed line closed, but one holding an id landed after the C3 was asked
stage_green() { : > "$K/passed"; : > "$K/done"; a=$(akey asked); c3=$(printf %.12s "$(akey commit)"); psteps
  for x in $(stp "$STG"); do closed "$x" && continue; tix "$x" | while read -r t y; do [ -n "$(mrg "$t")" ] || exit 1; done || continue   # a step with a ticket not merged stays open
    awk -F'\t' -v s="$x" '$1 == s { print $2 }' "$SX/ps" > "$SX/xr"
    awk -v a="$a" 'FILENAME == ARGV[1] { W[$1] = 1; next } { b = $1; sub(/-T[0-9]+$/, "", b) } ($1 in W || b in W) && $3 >= a { f = 1 } END { exit !f }' "$SX/xr" "$D/landed" 2>/dev/null && continue
    echo "closed $x | stand-in: C3 #$n at $c3" >> "$HAND"; ev "close-closed step=$x issue=$n commit=$(akey commit)"; echo "closed $x"; done
  gh_ close "$n" > /dev/null 2>&1 || true; ev "stage-c3 stage=$STG ask=$k result=passed"; echo "stage-c3 $STG passed"; }
# decide --stage <N>: C3 as a step close; S1, its form and its grades; the findings (R4)
cmd_decide_stage() { N=$1; s=stage-$N; CN=$(snc "$N"); [ -n "$CN" ] || die "no candidate for stage $N"; K=$SD/$N/$CN; [ -f "$K/named" ] || return 0
  [ ! -f "$K/withdrawn" ] || return 0   # 0.26.10.29.2 (R2): a candidate a re-cut withdrew: a later report for it is not read
  if [ ! -f "$K/passed" ]; then s=stage-$N; KD=$SD/$N; k=$CN; STG=$N; HL=C3; LB="C3 #$(sed -n "s/^issue$TAB//p" "$K/ask") of stage $N"; RA="--stage $N"; CSM=''; decide_k; fi; c=$CN; K=$SD/$N/$CN
  if [ -f "$K/s1ask" ] && [ ! -f "$K/s1done" ] && [ ! -f "$K/s1withdrawn" ]; then i=$(sed -n "s/^issue$TAB//p" "$K/s1ask"); touch "$K/items" "$K/again"
    prog now "reading the grade of stage $N"   # FB-3 D2
    sh "$HERE/results.sh" grade --stage "$N" > /dev/null 2> .vid/round/ce || die "S1 could not be read: $(tail -n 1 .vid/round/ce)"; set -- $(head -n 1 "$K/s1read" | tr '\t' ' ')
    case $2 in
      read) awk -F'\t' -v c="$c" '$1 == "grade" { print $2 "\t" $3 "\t" $4 > "/dev/stderr"; print $2 "\t" $3 "\t" c }' "$K/s1read" 2> "$SX/s1k" > "$SX/g" || exit 1; put "$K/s1" < "$SX/s1k" || exit 1
        touch "$SD/$N/s1"; awk -F'\t' 'FILENAME == ARGV[1] { n[$1] = $0; next } !($1 in n) { print } END { for (r in n) print n[r] }' "$SX/g" "$SD/$N/s1" | sort > "$SX/s1n" || exit 1; put "$SD/$N/s1" < "$SX/s1n" || exit 1
        grep -v '^lost s1 ' "$K/items" > "$SX/it" || true; put "$K/items" < "$SX/it" || exit 1; : > "$K/s1done"; gh_ close "$i" > /dev/null 2>&1 || true; ev "stage-s1 stage=$N candidate=$c graded=$(grep -c . "$K/s1")"; echo "s1 $N read" ;;
      refused) grep -qx "refused $3" "$K/s1again" 2>/dev/null || { printf 'vid: refused s1-%s\nby: RM\n\n%s\n' "$3" "$(cut -f4- "$K/s1read" | head -n 1)" > .vid/round/again; gh_ comment "$i" --body-file .vid/round/again > /dev/null 2>&1 && echo "refused $3" >> "$K/s1again"; echo "s1-refused $N $3"; } ;;
    esac
    # FB-3 A1.6: a grade of ViD's own is never asked again nor lost
    if [ "$2" != read ] && ownask "$i"; then s1own; elif [ "$2" != read ]; then W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n { print $5 }' .vid/round/read 2>/dev/null); q=$(( $(date +%s) - $(epoch "${u:-$(stamp)}") ))
      if grep -qxF "allow s1" "$K/again" || { [ "$q" -ge "$W" ] && ! grep -q '^s1 ' "$K/again"; }; then wy=$(awk -F'\t' '$1 == "s1" { w = $2 } END { print w }' "$K/againwhy" 2>/dev/null)   # 0.26.10.29.1 (R2): the owner's words, as for a chunk
        { printf 'vid: again s1\nby: RM\n'; [ -z "$wy" ] || printf 'why: %s\n' "$wy"; } > .vid/round/again; gh_ comment "$i" --body-file .vid/round/again > /dev/null 2>&1 || die "the S1 ask #$i could not be commented"
        grep -vxF "allow s1" "$K/again" > .vid/round/ag; put "$K/again" < .vid/round/ag || exit 1; drop s1 "$K/againwhy" || exit 1; echo "s1 again" >> "$K/again"; echo "close-again stage-$N s1"
      elif [ "$q" -ge "$W" ]; then item "lost s1 #$(grep -c '^s1 ' "$K/again")"; echo "close-lost stage-$N s1"; fi; fi; fi
  # 0.26.11.1.1 (R4): the owner's again on a stand-in row: the candidate's d1 and cs moved to numbered folders, as D2's again moves its
  # okay and run, so the round asks D1 and CS afresh at this candidate; the walk and its findings stay
  if [ -f "$K/cs/stand-in-again" ] && { [ ! -f "$K/cs/passed" ] || wfin "$K/w1"; }; then   # the walk over first: it holds staging until its end
    # its staging run's issue closed first; a failed close moves nothing, and the next round tries again
    i0=''; [ -f "$K/cs/issue-closed" ] || i0=$(sed -n "s/^issue$TAB//p" "$K/cs/ask" | head -n 1)
    if [ -n "$i0" ] && ! gh_ close "$i0" > /dev/null 2>&1; then echo "staging-again-waits $N: the staging run's issue #$i0 did not close"
    else [ -f "$K/cs/issue-closed" ] || : > "$K/cs/issue-closed"; j=1; while [ -d "$K/d1-$j" ] || [ -d "$K/cs-$j" ]; do j=$((j + 1)); done; [ ! -d "$K/d1" ] || mv "$K/d1" "$K/d1-$j"; mv "$K/cs" "$K/cs-$j"
      ev "stage-okay-again stage=$N candidate=$CN kind=stand-in"; echo "staging-again $N"; fi; fi
  # v0.26.10.26.2: D1, then CS as C3 is read, its folder <c>/cs
  d1_decide "$N" "$CN"; K=$SD/$N/$CN
  # v0.26.10.27.1: the rehearsal and CR, the production deploy and CP, at this candidate
  kdecide rh "$N" "$CN"; K=$SD/$N/$CN; F=$K
  if [ -f "$K/cr/ask" ] && [ ! -f "$K/cr/passed" ]; then s=rehearsal-$N; KD=$K; k=cr; STG=$N; CSM=$CN; CK=cr; HL=CR; LB="CR #$(sed -n "s/^issue$TAB//p" "$K/cr/ask") of stage $N"; RA="--cr $N"; F=$K; decide_k; CSM=''; CK=''; K=$SD/$N/$CN; fi
  for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do [ -f "$SD/$N/$o/d2/ask" ] && d2_decide "$N" "$o"; done; K=$SD/$N/$CN; F=$K   # an earlier candidate's settlement too
  for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do K=$SD/$N/$o; c=$o
  if [ -f "$K/cp/ask" ] && [ ! -f "$K/cp/passed" ] && [ ! -f "$K/cp/withdrawn" ] && ! psettled "$K"; then s=production-$N; KD=$K; k=cp; STG=$N; CSM=$o; CK=cp; HL=CP; LB="CP #$(sed -n "s/^issue$TAB//p" "$K/cp/ask") of stage $N"; RA="--cp $N --candidate $o"; F=$K; decide_k; CSM=''; CK=''; K=$SD/$N/$o
    # R6: a red CP asks for recovery on the production okay
    if [ -f "$K/cp/done" ] && [ ! -f "$K/cp/passed" ] && [ -f "$K/d2/ask" ] && ! psettled "$K"; then DK=$K/d2; i=$(sed -n "s/^issue$TAB//p" "$DK/ask"); F=$K; askrec "rows $(cut -f1 "$K/cp/acted" 2>/dev/null | paste -sd ' ' -)"; fi; fi; done; K=$SD/$N/$CN; c=$CN
  if [ -f "$K/cs/ask" ] && [ ! -f "$K/cs/passed" ] && [ ! -f "$K/cs/withdrawn" ]; then s=staging-$N; KD=$K; k=cs; STG=$N; CSM=$CN; CK=cs; HL=CS; LB="CS #$(sed -n "s/^issue$TAB//p" "$K/cs/ask") of stage $N"; RA="--cs $N"; decide_k; CSM=''; K=$SD/$N/$CN; fi; c=$CN
  newbuild "$N" "$SD/$N/$CN"
  # R4: each candidate's findings — every grade but pass, every finding line, every unmatched case
  { awk -F'\t' '$2 != "pass" { print "grade " $1 " " $2 " — " $3 }' "$K/s1" 2>/dev/null; sed -n "s/^finding$TAB//p" "$K/s1read" 2>/dev/null; awk -F'\t' '$1 == "unmatched" { print "unmatched " $2 " " $3 }' "$K/read" 2>/dev/null; } > "$SX/fn"; put "$K/findings" < "$SX/fn" || exit 1; return 0; }

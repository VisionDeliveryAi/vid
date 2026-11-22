#!/bin/sh
# Purpose: close.sh's part — the stage close at the newest candidate, its summary and the next plan (FB-2 C3). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
# --- v0.26.10.26.5 (R1, R2, R5): the stage close, at the newest candidate, from 7.1 to 7.4's records ---
# sclosed <N>: the commit12 and candidate of the stage's newest close, `<commit12> <c>`
sclosed() { sed -n "s/^stage-closed $1 | stand-in: RM at \([0-9a-f]*\) candidate \([0-9]*\).*/\1 \2/p" "$HAND" 2>/dev/null | tail -n 1; }
finals() { [ -f "$(sf STAGES.md)" ] || { echo 1; return; }; sed -n '/^```vid-stages/,/^```$/p' "$(sf STAGES.md)" | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); if (k ~ /^STAGE-/) { sub(/^STAGE-0*/, "", k); if (k == "") k = 0; m = k } } END { print m + 0 }'; }
title() { awk -F'|' -v r="$1" '{ a = $1; gsub(/[ \t]/, "", a) } a == r { t = $4; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/\. .*/, ".", t); print t; exit }' "$(sf PRD.md)" 2>/dev/null; }
rname() { q=$(printf '%s\n' "$1" > "$SX/r1"; rreqs "$SX/r1" | head -n 1); if [ -n "$q" ]; then n=$(title "$q"); [ -z "$n" ] || { echo "$n"; return; }; fi; plr; awk -F'\t' -v r="$1" '$1 == r { print $8; exit }' "$SX/plr"; }
# srows <N>: the rows of the stage's steps (planner limits, later rows and records apart)
srows() { psteps; plr; for s in $(stp "$1"); do awk -F'\t' -v s="$s" '$1 == s { print $2 }' "$SX/ps"; done | sort -u | awk -F'\t' 'FILENAME == ARGV[1] { if ($6 ~ /^(limit|later|record)$/) X[$1] = 1; next } !($1 in X)' "$SX/plr" -; }
# stix <N> <commit>: the stage's steps' tickets merged at or before the commit
stix() { for s in $(stp "$1"); do tix "$s" | cut -d' ' -f1; done | sort -u | while read -r t; do m=$(mrg "$t" | cut -d' ' -f2); [ -n "$m" ] && { [ "$m" = "$2" ] || anc "$m" "$2"; } && echo "$t"; done; }
# cconds <N>: each unmet condition of the close at the newest candidate, `<n> <why>` a line in $SX/cc<N>; exit 0 when none
cconds() { N=$1; c=$(snc "$N"); F=$SD/$N/$c; U=$SX/cc$N; : > "$U"; [ -n "$c" ] && [ -f "$F/named" ] || { echo "0 no candidate" > "$U"; return 1; }; [ ! -f "$F/withdrawn" ] || { echo "0 its candidate $c withdrawn by a re-cut" > "$U"; return 1; }; X=$(cat "$F/commit"); plr
  srows "$N" > "$SX/sr$N"; while read -r r; do w=$(hstate "$r"); mk=$(awk -F'\t' -v r="$r" '$1 == r { print $7 }' "$SX/plr")
    case $w in paid|known-limit) ;; accepted|accepted-by-ruling) ! printf '%s\n' "$mk" | grep -qE '(^| )(seam|owed-staging)( |$)' || echo "1 $r $w, not paid at staging" ;; owed) printf '%s\n' "$mk" | grep -qE '(^| )owed-(rehearsal|production)( |$)' || echo "1 $r owed, not paid" ;; '') echo "1 $r not yet decided" ;; *) echo "1 $r $w" ;; esac; done < "$SX/sr$N" >> "$U"
  [ -f "$F/passed" ] || echo "2 C3 not passed" >> "$U"; [ -f "$F/d1/passed" ] || echo "2 D1 not passed" >> "$U"; [ -f "$F/cs/passed" ] || echo "2 CS not passed" >> "$U"
  sreqs "$N" > "$SX/rq.$N"; while read -r q; do g=$(awk -F'\t' -v q="$q" '$1 == q { c = $3 } END { print c }' "$SD/$N/s1" 2>/dev/null); [ -n "$g" ] || { echo "3 $q not graded" >> "$U"; continue; }
    Xg=$(cat "$SD/$N/$g/commit" 2>/dev/null); sed -n '/^```vid-inventory/,/^```$/p' "$(sf INVENTORY.md)" | awk -F'|' -v q="$q" '{ a = $1; gsub(/[ \t]/, "", a); if (index(" " $7 " ", " " q) || index($7, q ",") || index($7, q " ")) print a }' | grep . > "$SX/qr" || true
    while IFS=$TAB read -r p t H M; do [ -n "$M" ] && [ "$M" != - ] || continue; trows "$t" | grep -qxF -f "$SX/qr" || continue; [ "$M" = "$Xg" ] || anc "$M" "$Xg" || { echo "3 $q graded before a merge that touched it" >> "$U"; break; }; done < "$D/merges"; done < "$SX/rq.$N"
  [ -f "$F/w1/done" ] || [ -f "$F/w1/none" ] || [ -f "$F/w1/limit" ] || echo "4 W1 not done" >> "$U"   # 0.26.10.28.6 (R1): no walk owed, or the owner's known limit
  stix "$N" "$X" > "$SX/tk$N"; sh "$HERE/queue.sh" blockers --stage "$N" --tickets "$SX/tk$N" --rows "$SX/sr$N" --steps "$(stp "$N" | tr '\n' ' ')" 2>/dev/null | sed 's/^5 /5 a finding without the owner'"'"'s ruling: /; s/^6 /6 an item for the owner: /' >> "$U"
  [ ! -s "$U" ]; }
# v0.26.10.27.4 (R2): endconds, the project's completion from the records alone, each unmet condition `<n> <why>` a line (every
# unmet row once); exit 0 when none. It writes nothing but its own scratch. 1: the final stage's newest candidate closed, none due;
# 2: every row accepted (or by ruling), paid, a known limit, owed to the rehearsal or production, or a later item's; 3: every live
# requirement's newest S1 grade at a candidate holding every merge touching its rows, and no grade ask out; 4: no ticket open;
# 5: no question open (the PRD's VID-QUESTION lines too; production's items and the offer are none); 6: every finding ruled, a row
# or fix ruling once its draft landed or was declined
endconds() { U=$SX/end; : > "$U"; F=$(finals); [ "$F" -ge 1 ] || F=1; c=$(snc "$F"); set -- $(sclosed "$F")
  if [ -z "$c" ] || [ "${2:-}" != "$c" ]; then echo "1 stage $F's newest candidate${c:+, $c,} is not closed" >> "$U"; fi; ! sdue "$F" || echo "1 a candidate is due for stage $F" >> "$U"
  plr; awk -F'\t' '$2 == "row" { print $1 "\t" $5 "\t" $6 "\t" $7 }' "$SX/plr" | while IFS=$TAB read -r r g cl mk; do case "$g $cl" in *later*|*record*|*limit*) continue ;; esac; w=$(hstate "$r")
      case $w in accepted|accepted-by-ruling|paid|known-limit) ;; owed) printf '%s\n' "$mk" | grep -qE '(^| )owed-(rehearsal|production)( |$)' || echo "2 $r owed, not paid" ;; '') echo "2 $r not yet decided" ;; *) echo "2 $r $w" ;; esac; done >> "$U"
  lreqs > "$SX/lq"; for f in $(ls "$SD"/*/s1 2>/dev/null); do x=${f%/s1}; x=${x##*/}; awk -F'\t' -v x="$x" '{ print $1 "\t" x "\t" $3 }' "$f"; done | sort -t"$TAB" -k1,1 -k2,2n -k3,3n > "$SX/g3"
  while read -r q; do gl=$(awk -F'\t' -v q="$q" '$1 == q { l = $2 " " $3 } END { print l }' "$SX/g3"); [ -n "$gl" ] || { echo "3 $q not graded" >> "$U"; continue; }
    Xg=$(cat "$SD/${gl% *}/${gl#* }/commit" 2>/dev/null); sed -n '/^```vid-inventory/,/^```$/p' "$(sf INVENTORY.md)" | awk -F'|' -v q="$q" '{ a = $1; gsub(/[ \t]/, "", a); n = split($7, t, /[ ,]+/); for (i = 1; i <= n; i++) if (t[i] == q) { print a; break } }' | grep . > "$SX/qr" || true
    while IFS=$TAB read -r p t H M; do [ -n "$M" ] && [ "$M" != - ] || continue; trows "$t" | grep -qxF -f "$SX/qr" || continue; [ "$M" = "$Xg" ] || anc "$M" "$Xg" || { echo "3 $q graded before a merge that touched it" >> "$U"; break; }; done < "$D/merges"; done < "$SX/lq"
  sh "$HERE/grade.sh" out 2>/dev/null | sed 's/^/3 a grade ask out: /' >> "$U"
  for f in $(ls "$SD"/*/*/s1ask 2>/dev/null); do x=${f%/s1ask}; [ -f "$x/s1done" ] || [ -f "$x/s1withdrawn" ] || echo "3 a stage grade out: ${x#$SD/}, #$(sed -n "s/^issue$TAB//p" "$f")"; done >> "$U"
  awk -F'\t' -v T=",${PX}ticket," '$1 == "issue" && index("," $3 ",", T) { print "4 ticket #" $2 " open" }' "$RD" 2>/dev/null >> "$U"; awk -F'\t' '$1 == "open" { print "4 pull request " $2 " open" }' "$RD" 2>/dev/null >> "$U"
  sh "$HERE/queue.sh" keys 2>/dev/null > "$SX/qk" || : > "$SX/qk"
  awk -F'\t' '$1 !~ /^(production|production-lost|finding|findings|stage|grade):/ { print "5 " $2 " open: " substr($3, 1, 80) } $1 ~ /^(finding|findings|stage|grade):/ { print "6 " $2 " not ruled: " substr($3, 1, 80) }' "$SX/qk" >> "$U"
  awk -v I="$D/queue/ids" 'BEGIN { while ((getline l < I) > 0) { split(l, y, "\t"); O[y[2]] = 1 } } /^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+ / && !($2 in O) { print "5 " $2 " open in RUN-STATE: " substr($0, 1, 80) }' .vid/RUN-STATE.md >> "$U"   # the session's own questions
  grep -n '^VID-QUESTION: ' "$(sf PRD.md)" 2>/dev/null | sed 's/^\([0-9]*\):.*VID-QUESTION:*[[:space:]]*/5 PRD.md:\1 VID-QUESTION /' | cut -c1-120 >> "$U"
  awk -F'\t' '$3 == "row" || $3 == "fix" { print $2 }' "$D/queue/answers" 2>/dev/null | sort -u | while read -r k; do grep -qxF "$k" "$D/queue/doors" 2>/dev/null || continue; ok=''
    for f in $(grep -lxF "$k" "$D"/drafts/*/for 2>/dev/null); do X0=${f%/for}; { [ -f "$X0/landed" ] || [ -f "$X0/declined" ]; } && ok=1; done; [ -n "$ok" ] || echo "6 $k ruled, its draft not landed or declined"; done >> "$U"
  [ ! -s "$U" ]; }
# wwords <w1 folder> (0.26.10.28.6, R1): the walk's words, when W1 is none or a limit: none's line, or the limit's words with who answered and when
wwords() { if [ -f "$1/none" ]; then head -n 1 "$1/none"; elif [ -f "$1/limit" ]; then printf '%s (%s)\n' "$(sed -n 1p "$1/limit")" "$(sed -n 2p "$1/limit")"; fi; }
# summary --stage <N> (R2): the facts the summary must name, <c>/facts.txt: `working`, `went-back`, `decided <id> <words>` (0.26.10.29.5,
# DP-1 R4: every answer not given by the owner, `<words> (by <who>)`; each DECISIONS.md line; each model_proposed PRD answer), `walk`
cmd_summary() { N=${2:?}; c=$(snc "$N"); F=$SD/$N/$c; [ -n "$c" ] || die "no candidate for stage $N"; P=$(awk '$1 == "stage-closed" { for (i = 2; i <= NF; i++) if ($i ~ /^at=/) t = substr($i, 4) } $1 == "stage" && / name=run / && / state=start / && r == "" { for (i = 2; i <= NF; i++) if ($i ~ /^at=/) r = substr($i, 4) } END { print (t != "" ? t : r) }' .vid/metrics-events 2>/dev/null); PX=$(grep -c '^stage-closed ' .vid/metrics-events 2>/dev/null || true); [ "${PX:-0}" -gt 0 ] && PX=1 || PX=''   # since the newest close of any stage, else the run's start
  { sreqs "$N" | while read -r q; do [ "$(awk -F'\t' -v q="$q" '$1 == q { print $2 }' "$SD/$N/s1" 2>/dev/null)" = pass ] && printf 'working\t%s\t%s\n' "$q" "$(title "$q")"; done
    # went back: the regressions of the stage's closes and its candidates' C3 and CS, and its rows' resets at a landing
    for x in $(stp "$N"); do ls -d "$C/$x"/[0-9]* 2>/dev/null; done > "$SX/fd"; ls -d "$SD/$N"/[0-9]* "$SD/$N"/[0-9]*/cs 2>/dev/null >> "$SX/fd"
    while read -r f; do [ -f "$f/result" ] || continue; d=$(dirname "$f"); case $f in */cs) pf='' ;; *) pf=$(for j in $(ls "$d" | grep -E '^[0-9]+$' | sort -n); do [ "$j" -lt "${f##*/}" ] && [ -f "$d/$j/result" ] && echo "$d/$j"; done | tail -n 1) ;; esac; [ -n "$pf" ] || continue
      awk -F'\t' 'NR == FNR { b[$1] = $2; next } $2 == "red" && b[$1] == "green" { print $1 }' "$pf/result" "$f/result" | while read -r r; do printf 'went-back\t%s\t%s\t%s\n' "$r" "$(rname "$r")" "a regression at ${f#.vid/decide/}"; done; done < "$SX/fd"
    srows "$N" > "$SX/srs"; for x in $(ls "$D/drafts" 2>/dev/null | grep -E '^[0-9]+$'); do [ -f "$D/drafts/$x/landed" ] || continue; awk -F'\t' '$1 == "reset" { print $2 }' "$D/drafts/$x/sets" 2>/dev/null | grep -xF -f "$SX/srs" | while read -r r; do printf 'went-back\t%s\t%s\t%s\n' "$r" "$(rname "$r")" "reset at draft $x's landing"; done; done
    # decided for you: the answers not given by the owner since the newest close of any stage, and each D-NNN added to DECISIONS.md since
    # 0.26.10.29.5 (DP-1 R4): lib.sh's notowner, the queue's answers and the held-row rulings alike (a delegate's, RM's, a stand-in's, the
    # round's own), each with who gave it; a held row by its Q line, or by its row when it has none (the round's own ruling is asked of nobody)
    notowner | awk -F'\t' -v p="$P" -v x="$PX" -v I=.vid/decide/queue/ids 'BEGIN { while ((getline l < I) > 0) { split(l, y, "\t"); Q[y[1]] = y[2] } } (x ? $1 > p : $1 >= p) { k = $2; if (k ~ /^held:/) k = (k in Q) ? Q[k] : substr(k, 6); print "decided\t" k "\t" ($4 == "" ? $3 : $4) " (by " $5 ")" }'   # strictly after a close
    git log --since="${P:-1970-01-01T00:00:00Z}" -p -- DECISIONS.md 2>/dev/null | sed -n 's/^+- \*\*\(D-[0-9][0-9]*\)\*\* \(.*\)/decided\t\1\t\2/p'
    # 0.26.10.29.5 (DP-1 R4): each PRD answer row marked model_proposed added since, read from PRD.md's history as DECISIONS.md's, its answer's words
    git log "$(lrev)" --since="${P:-1970-01-01T00:00:00Z}" -p -- PRD.md 2>/dev/null | grep -E '^\+[[:space:]]*A-[0-9]+([[:space:]]+AMENDED)?[[:space:]]*\|[[:space:]]*model_proposed[[:space:]]*\|' | awk -F'|' '{ k = $1; sub(/^\+[ \t]*/, "", k); sub(/[ \t].*/, "", k); a = ""; for (i = 2; i <= NF; i++) { y = $i; gsub(/^[ \t]+|[ \t]+$/, "", y); if (y ~ /^A:/) { a = y; sub(/^A:[ \t]*/, "", a) } } print "decided\t" k "\t" a " (model_proposed, PRD.md)" }'
    # 0.26.10.28.6 (R1): the walk, when no screen walk was owed or the owner closed without it; the summary carries the words as they stand
    wwords "$F/w1" | while IFS= read -r l; do printf 'walk\t%s\n' "$l"; done
  } | awk -F'\t' '!s[($1 == "decided") ? $0 : $1 FS $2 FS $4]++' > "$SX/facts"   # 0.26.10.29.5 (DP-1 R4): a decided fact by its whole line, so two rulings on one row are two facts and only one written alike is dropped
  # a went-back fact once only: not one an earlier close of this stage already named
  for o in $(sed -n "s/^stage-closed $N | stand-in: RM at [0-9a-f]* candidate \([0-9]*\).*/\1/p" "$HAND" 2>/dev/null); do [ "$o" = "$c" ] || cat "$SD/$N/$o/facts.txt" 2>/dev/null; done | awk -F'\t' '$1 == "went-back" { print $2 "\t" $4 }' | sort -u > "$SX/old"   # an earlier close's facts alone
  awk -F'\t' 'FILENAME == ARGV[1] { O[$1 FS $2] = 1; next } !($1 == "went-back" && (($2 FS $4) in O))' "$SX/old" "$SX/facts" > "$SX/ft" || exit 1; put "$F/facts.txt" < "$SX/ft" || exit 1; echo "facts $N $(grep -c . "$F/facts.txt") at $F/facts.txt"; }
# the summary's three checks (CK-R-139 to 141): its words name every went-back requirement and every decision's id
sumcheck() { S=$F/summary.md; [ -s "$S" ] || { echo "no summary at $S"; return 1; }
  awk -F'\t' '$1 == "walk" { print $2 }' "$F/facts.txt" | while IFS= read -r w; do grep -qF -- "$w" "$S" || { echo "the summary does not say the walk's outcome: $w"; exit 1; }; done || return 1   # 0.26.10.28.6 (R1)
  awk '{ t = t $0 "\n" } END { a = index(t, "Went back"); if (!a) exit; t = substr(t, a); b = index(t, "Decided for you"); print (b ? substr(t, 1, b - 1) : t) }' "$S" > "$SX/wb"   # the text between Went back and Decided for you
  awk -F'\t' '$1 == "went-back" { print $3 }' "$F/facts.txt" | sort -u | while IFS= read -r n; do grep -qiF -- "$n" "$SX/wb" || { echo "the summary's went back misses: $n"; exit 1; }; done || return 1
  awk -F'\t' '$1 == "decided" { print $2 }' "$F/facts.txt" | sort -u | while IFS= read -r i; do awk -v i="$i" '{ t = $0; while ((p = index(t, i)) > 0) { a = substr(t, p + length(i), 1); b = p > 1 ? substr(t, p - 1, 1) : ""; if (a !~ /[0-9A-Za-z:]/ && b !~ /[0-9A-Za-z:]/) { f = 1; exit } t = substr(t, p + 1) } } END { exit !f }' "$S" || { echo "the summary misses the decision $i"; exit 1; }; done || return 1; return 0; }
cmd_close_stage() { N=${2:?}; cconds "$N" || die "stage $N cannot close: $(paste -sd ';' "$SX/cc$N")"; c=$(snc "$N"); F=$SD/$N/$c; X=$(cat "$F/commit"); X12=$(printf %.12s "$X")
  set -- $(sclosed "$N"); [ "${2:-}" != "$c" ] || { echo "stage $N closed already at $X12"; return 0; }
  cmd_summary x "$N" > /dev/null; why=$(sumcheck) || { [ ! -f "$F/summary.md" ] || mv "$F/summary.md" "$F/summary.refused.$(date +%s)"; echo "summary-refused $N $why"; ev "stage-summary-refused n=$N"; return 0; }
  r=$(grep -c . "$SX/sr$N"); dbt=$(while read -r q; do [ "$(hstate "$q")" = owed ] && echo "$q"; done < "$SX/sr$N" | grep -c .)
  { printf '# Stage %s, closed at %s (candidate %s)\n\n## What it holds\n\n' "$N" "$X12" "$c"; for s in $(stp "$N"); do printf -- '- %s: %s rows\n' "$s" "$(awk -F'\t' -v s="$s" '$1 == s' "$SX/ps" | grep -c .)"; done
    printf '\n## C3\n\n%s\n\n## The deploy debt\n\n' "$(cat "$F/numbers" 2>/dev/null || echo 'its first candidate: no earlier close to count against')"
    while read -r q; do [ "$(hstate "$q")" = owed ] && printf -- '- %s: %s\n' "$q" "$(awk -F'\t' -v r="$q" '$1 == r { print $8 }' "$SX/plr")"; done < "$SX/sr$N"
    printf '\n## The findings and their rulings\n\n'; awk -F'\t' -v p="stage:$N:" -v TF="$SX/tk$N" 'BEGIN { while ((getline l < TF) > 0) T[l] = 1 } { split($2, k, ":") } index($2, p) == 1 || (k[1] == "finding" && (k[2] in T)) { print "- " $2 ": " $3 " — " $4 }' .vid/decide/queue/answers 2>/dev/null   # the stage's findings and its tickets' 
    printf '\n## The next stage\n\n'; s2=$(stp "$((N + 1))" | tr '\n' ' '); printf '%s\n' "${s2:-none planned yet, or the final stage}"; } > "$SX/rpt" || exit 1; put "$F/report.md" < "$SX/rpt" || exit 1
  echo "stage-closed $N | stand-in: RM at $X12 candidate $c" >> "$HAND"; ev "stage-closed n=$N sha=$X12 ready rows=$r debt=$dbt"
  cu=$(sed -n 's/^stage:[[:space:]]*\([0-9][0-9]*\).*/\1/p' .vid/RUN-STATE.md | head -n 1)
  if [ "$N" -lt "$(finals)" ] && [ "${cu:-0}" -le "$N" ]; then rs_edit sed "s/^stage:[[:space:]]*[0-9][0-9]*/stage: $((N + 1))/" || exit 1; fi
  hn=$(sed -n 's/^held-after:[[:space:]]*//p' .vid/RUN-STATE.md | head -n 1)
  if [ "$hn" = "$N" ]; then rs_edit sed "s/^run:.*/run: stopped owner asked to hold after stage $N/" || exit 1; ev "stage-hold n=$N state=on"; echo "held after stage $N: the run stops"; fi
  echo "stage-closed $N at $X12"; }
# nextplan (v0.26.10.26.5 R4): N+1, when stage N's candidate is named, N is not the final stage, no hold is recorded, and the plan holds
# no step of stage N+1
cmd_nextplan() { grep -q '^held-after:' .vid/RUN-STATE.md && return 0; n=''; for x in $(ls "$SD" 2>/dev/null | sort -n); do c=$(snc "$x"); [ -n "$c" ] && [ -f "$SD/$x/$c/named" ] && n=$x; done
  [ -n "$n" ] && [ "$n" -lt "$(finals)" ] || return 0; [ -n "$(stp "$((n + 1))")" ] || echo "$((n + 1))"; return 0; }

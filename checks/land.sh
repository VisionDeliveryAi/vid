#!/bin/sh
# Purpose: ViD's landing of a counted change to the spec during a run (v0.26.10.25.5, R1–R5). /vid fix's and /vid add's
# ticket-mode branch drafts the change and asks the owner once; the owner's yes lands it, here, inside /vid run's session, so
# the run's stage stays the newest and plan.sh stays on. It commits ViD's spec files alone and reads no code. Run at the top
# of ViD's repository.
#   draft --review <file> [--why "<one line>"] [--plan <file>] [--for <item key>[,…]] [--replaces <n>]   (--for, v0.26.10.26.5: the findings it answers, for the stage close) the working tree's uncommitted changes to the spec files become draft <n>,
#       .vid/decide/drafts/<n>/ (base, files/, plan: the whole new vid-plan block when the change places rows, why, count,
#       sets), and the tree is put back as HEAD holds it: the draft commits nothing. Prints `draft <n>`, then its count.
#       v0.26.10.26.7 (R4): the landing's dry run first; refused, no draft is made and the tree stays. --replaces <n> marks
#       draft n replaced (`replaced <n>`), and its Q line closes. --review <file> (R5) is required: the fresh-agent review's
#       output, `none` or `finding <row id> | <why>` lines naming the draft's rows, kept as <n>/review
#       IR I5: --map <file>, an incorporation's map, kept beside the review as <n>/map: required when the why begins
#       `/vid incorporate:` (as /vid add's begins `/vid add:`), refused on any other draft. Its entries, one a line (a blank line
#       or one beginning # skipped): a change `<file> | <where> | today: … | change: … | record: …`, `left: …` or `open: …`
#   count <n>                     the draft's count, and the Q line's words; a draft with a map adds `map: <c> changes, <l> left,
#       <o> open` before its words line, and the words name the same counts
#   <n> --words "<the owner's yes>"   lands draft n. Refused, nothing landed: exit 3 while plan.sh's gate is off, a pause or
#       any stop (it waits for continue); exit 4 when HEAD is not the draft's base (stale: SP redrafts); exit 1 when the dry
#       run on a scratch copy refuses (a court, plan.sh change, rule A or B, planner.sh check). Then: the records (R4, R5),
#       the commits as develop makes them (IR I5: ARCHITECTURE.md and BASELINE.md first, so a decision labelled with a module the
#       draft adds finds it in the staged module table; then the PRD with GRADING-CHECKLIST.md and DECISIONS.md; one law commit of
#       INVENTORY.md and STAGES.md; PLAN.md alone; a group the draft holds no file of makes no commit; each with `Decisions: admits <the draft's why> (<its count
#       line>) — the owner's yes`, 0.26.10.29.5, DP-1 R7), the plan change, planner.sh reratify in the owner's
#       words, and last each withdrawn ask's issue closed on GitHub
# Records: .vid/decide/landed (`<id> <the landing, 12> <time>`, each reset or added line, a journey's transitions with it);
# for each: its counts, limits, halted, record and state lines gone, a `reset` ruling, its handed row line dropped, every
# unpublished fix line without it; `reached <row> <item> <landing> | stand-in: SP` for a reached row a ticket holds; a
# reopened step's closed line dropped and its newest ask withdrawn (.vid/decide/close/<step>/<k>/withdrawn). v0.26.10.26.7 (R9): a
# reached row a published ticket holds withdraws every newest live close whose rows hold it, recorded in <k>/reached.
# 0.26.10.29.2 (R2): /vid stage's re-cut, a draft whose why begins `/vid stage:`, carries a deleted STAGES.md (<n>/deleted) and the
# owner's answer row (refused without one); the dry run refuses it when it changes a stage closed (its stage-closed line) or deployed
# (a candidate's D1 passed, or a production line covering it) or leaves a stage with no row; its landing withdraws every candidate
# of each stage it changes (.vid/decide/stage/<N>/<c>/withdrawn, with its C3, S1 and D1 okay still out), its plan change is a
# scope-change, RUN-STATE's stage: moves to the new cut's current stage, and it records the stage-cut event.
# In GitHub manual (GM-1 S1) draft and the landing refuse, exit 1, naming the hand path; count still reads a draft.
# Usage: sh checks/land.sh draft --review <file> [--why "<…>"] [--plan <file>] [--for <keys>] [--replaces <n>] [--map <file>] | count <n> | <n> --words "<the owner's yes>"
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
D=.vid/decide; DR=$D/drafts; HAND=.vid/tw/handed; LOG=.vid/tw/log
die() { echo "ViD land: $*" >&2; exit 2; }
ref() { echo "ViD land: refused — $1" >&2; exit "${2:-1}"; }
# putd <folder> <copy>: a folder replaced in four steps — the copy beside it as .put.$$.<name>, the live one aside as .old.$$.<name>,
# the copy in, the old one removed; a step that fails stops it with the live folder whole (v0.26.10.28.1, R6); each rename through mvr (0.26.11.1.4, R6)
putd() { _q=$(dirname "$1")/.put.$$.$(basename "$1"); _o=$(dirname "$1")/.old.$$.$(basename "$1"); rm -rf "$_q" && cp -R "$2" "$_q" || { rm -rf "$_q"; return 1; }
  if [ -e "$1" ]; then mvr "$1" "$_o" || { rm -rf "$_q"; return 1; }; fi; mvr "$_q" "$1" || { [ ! -e "$_o" ] || mvr "$_o" "$1"; rm -rf "$_q"; return 1; }; rm -rf "$_o" || true; }   # the copy is in: an old folder left behind is no failed restore
# a roll-back stopped between its two renames left .vid/.old.<pid>.<name> and no live folder: it is renamed back first
for _o in .vid/.old.*.decide .vid/.old.*.plans .vid/.old.*.plan; do [ -d "$_o" ] && [ ! -e ".vid/${_o##*.}" ] || continue; mvr "$_o" ".vid/${_o##*.}"; done
[ -f .vid/RUN-STATE.md ] && [ -f INVENTORY.md ] || die "run it at the top of ViD's repository"
SPEC='PRD.md GRADING-CHECKLIST.md DECISIONS.md INVENTORY.md STAGES.md ARCHITECTURE.md PLAN.md BASELINE.md'   # IR I5: BASELINE.md carried too
HASHF='PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# pblock <file>: the vid-plan block's body
pblock() { sed -n '/^```vid-plan[[:space:]]*$/,/^```[[:space:]]*$/p' "$1" | sed '1d;$d'; }
# stepsof <ids file> <block file>: `<id> <step>` for each id a step's rows hold, ranges expanded
stepsof() { awk -v IDS="$1" "$RNG"' function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } BEGIN { while ((getline l < IDS) > 0) W[l] = 1 }
  /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id)
    for (i = 2; i <= n; i++) { x = tr(f[i]); if (x !~ /^rows:/) continue; m = split(substr(x, 6), t, /[ ,\t]+/)
      for (j = 1; j <= m; j++) { y = t[j]; if (y == "") continue; q = split(rng(y), e, " "); for (k = 1; k <= q; k++) if (e[k] in W) print e[k], id } } }' "$2"; }
# the draft's block: its plan, else RUN-STATE's
dblock() { if [ -s "$1/plan" ]; then cat "$1/plan"; else plan_block; fi; }   # RUN-STATE's by plan.sh's form (lib.sh); a draft's own plan file keeps pblock
# 0.26.10.29.2 (R2): the owner's re-cut of the stages, /vid stage's ticket-mode draft, its why beginning `/vid stage:` (as /vid add's
# begins `/vid add:`). gone <draft dir> <file>: the draft deletes the file; recut <draft dir>: the draft is a re-cut
SD=$D/stage
gone() { grep -qxF "$2" "$1/deleted" 2>/dev/null; }
recut() { head -n 1 "$1/why" 2>/dev/null | grep -q '^/vid stage:'; }
# cutd <draft dir> <base>: each stage the draft's cut changes, one number a line: a stage whose rows or PRD items differ between the base's
# STAGES.md and the draft's (none: one stage), read by stages.sh scope, as every court reads them. 0.26.10.29.4 (phase 4 R5): the base cut
# over the base's PRD.md and INVENTORY.md, the draft cut over the draft's (the base's where the draft carries none), so a requirement the
# draft adds to a closed stage's feature and splits to an open stage changes the open stage alone; a move of an existing one still changes both
cutd() { for s in a b; do rm -rf "$T/c$s"; mkdir -p "$T/c$s"; for f in PRD.md INVENTORY.md; do if [ "$s" = b ] && [ -f "$1/files/$f" ]; then cp "$1/files/$f" "$T/c$s/"; else git show "$2:$f" > "$T/c$s/$f" 2>/dev/null || true; fi; done; done
  git show "$2:STAGES.md" > "$T/ca/STAGES.md" 2>/dev/null || rm -f "$T/ca/STAGES.md"; if [ -f "$1/files/STAGES.md" ]; then cp "$1/files/STAGES.md" "$T/cb/"; elif ! gone "$1" STAGES.md; then cp "$T/ca/STAGES.md" "$T/cb/" 2>/dev/null || true; fi
  for s in a b; do ( cd "$T/c$s" || exit 1; m=1; [ ! -f STAGES.md ] || m=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | sed -n 's/^[[:space:]]*STAGE-0*\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n | tail -n 1); [ -n "$m" ] || m=1
      k=0; while [ "$k" -le "$m" ]; do lread "$T/q$s" stages scope --upto "$k" --reqs || exit 1; sed "s/\$/ $k/" "$T/q$s"; k=$((k + 1)); done ) > "$T/m0$s" || return 1   # R6: a read that fails is no empty cut
    awk '!s[$1]++' "$T/m0$s" > "$T/m$s"; done
  awk 'FILENAME == ARGV[1] { A[$1] = $2; next } { B[$1] = $2 } END { for (i in A) if (!(i in B) || A[i] != B[i]) { print A[i]; if (i in B) print B[i] } for (i in B) if (!(i in A)) print B[i] }' "$T/ma" "$T/mb" | sort -nu; }
# deployed <N>: any candidate of stage N, not withdrawn, has its D1 passed, or a production line covers stage N; closed <N>: its stage-closed line.
# The `staged <N>` line is no test: only the run's first passed D1 writes one
deployed() { for c in $(ls "$SD/$1" 2>/dev/null | grep -E '^[0-9]+$'); do [ -f "$SD/$1/$c/d1/passed" ] && [ ! -f "$SD/$1/$c/withdrawn" ] && return 0; done
  sed -n 's/^production \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$1" '$1 >= n { f = 1 } END { exit !f }'; }
sclosed_() { grep -q "^stage-closed $1 " "$HAND" 2>/dev/null; }
# cutn <STAGES.md>: its stage numbers, lowest first; none, with no file (one stage: 1)
cutn() { if [ -f "$1" ]; then sed -n '/^```vid-stages/,/^```$/p' "$1" | sed -n 's/^[[:space:]]*STAGE-0*\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n; else echo 1; fi; }
# hollow <stages file>: each stage it names that the landed cut holds and that holds no row by its effective stage, planner.sh rows'
# (a PLAN.md `moved:` counted), as close.sh's sstages and admission read it; run where the cut has landed (the dry run's copy)
hollow() { lread "$T/hr0" planner rows || return 1; grep -v '^#' "$T/hr0" > "$T/hr"; cutn STAGES.md > "$T/hn"
  for k in $(cat "$1"); do grep -qx "$k" "$T/hn" || continue; awk -F'\t' -v k="$k" '$5 ~ /^[0-9]+$/ && $5 + 0 == k + 0 { f = 1 } END { exit !f }' "$T/hr" || echo "$k"; done; }
# curst: the new cut's current stage, as close.sh's stage close moves RUN-STATE's stage: on — its lowest stage with no stage-closed
# line, the final one when each is closed
curst() { k=''; for n in $(cutn STAGES.md); do k=$n; sclosed_ "$n" || break; done; echo "${k:-1}"; }
# stmove: RUN-STATE's stage: moved to curst, printing `stage <k>` when it moved; run where the cut has landed, before its plan change,
# so the re-cut's own change is judged at the stage it lands in
stmove() { k=$(curst); grep -q '^stage:' .vid/RUN-STATE.md || return 0; ! grep -q "^stage:[[:space:]]*$k\$" .vid/RUN-STATE.md || return 0
  rs_edit sed "s/^stage:[[:space:]]*[0-9][0-9]*/stage: $k/" && echo "stage $k"; }

# v0.26.10.26.5: --for records the items a draft answers, in <draft>/for
# v0.26.10.26.7 (R4, W-5): the landing's dry run runs at draft time, the re-ratifying in its check-only form (placeholder words, in
# the scratch copy alone); a refused draft is not made, its refusal names the check, and the tree is kept for SP to correct.
# --replaces <n>: once the new draft is made, draft n is marked replaced (<n>/replaced, the new number), its Q line closed
cmd_draft() { WHY=''; PL=''; FOR=''; RPL=''; RV=''; MP=''; while [ $# -ge 2 ]; do case $1 in --why) WHY=$2 ;; --plan) PL=$2 ;; --for) FOR=$2 ;; --replaces) RPL=$2 ;; --review) RV=$2 ;; --map) MP=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -z "$PL" ] || [ -f "$PL" ] || die "no plan block file at $PL"
  # IR I5: an incorporation's draft carries its map; no other draft does
  case $WHY in '/vid incorporate:'*) [ -n "$MP" ] || ref 'no --map: an incorporation drafts with its map, every place the record changes and every place left'; [ -s "$MP" ] || ref "--map $MP: no map there" ;;
    *) [ -z "$MP" ] || ref '--map is an incorporation'"'"'s, whose why begins /vid incorporate:' ;; esac
  [ -n "$RV" ] || ref 'no --review: a fresh agent reviews the change over the rows it touches first, and its output (finding <row id> | <why> lines, or none) is the draft'"'"'s record'
  [ -s "$RV" ] || ref "--review $RV: no review output there"
  if [ -n "$RPL" ]; then O=$DR/$RPL; [ -f "$O/base" ] || die "--replaces $RPL: no draft $RPL"; for z in landed declined replaced; do [ ! -f "$O/$z" ] || ref "--replaces $RPL: draft $RPL is $z already"; done; fi
  CH=''; for f in $SPEC; do [ -z "$(git status --porcelain -- "$f" 2>/dev/null)" ] || CH="$CH $f"; done
  [ -n "$CH" ] || ref 'no spec file differs from HEAD: draft the change in the working tree first'
  mkdir -p "$DR"; n=$(( $(ls "$DR" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1 | grep . || echo 0) + 1 )); X=$DR/$n; mkdir -p "$X/files"
  git rev-parse HEAD > "$X/base"; printf '%s\n' "${WHY:-a change to the spec}" > "$X/why"; [ -z "$MP" ] || cp "$MP" "$X/map"; [ -z "$FOR" ] || printf '%s\n' "$FOR" | tr ',' '\n' | grep . > "$X/for"; [ -z "$PL" ] || pblock "$PL" > "$X/plan" 2>/dev/null; [ -z "$PL" ] || [ -s "$X/plan" ] || cp "$PL" "$X/plan"
  # 0.26.10.29.2 (R2): a spec file the tree deletes (STAGES.md, a re-cut back to one stage) is carried as a line of <n>/deleted
  for f in $CH; do if [ -f "$f" ]; then cp "$f" "$X/files/$f"; else echo "$f" >> "$X/deleted"; fi; done
  ( count "$X" ) || { rm -rf "$X"; exit 1; }
  # v0.26.10.26.7 (R5 b, W-6): the review's record, as planner.sh review --in records the planner's: `none` alone, or one
  # `finding <row id> | <why>` a line naming a row the draft resets, adds, reaches or records
  awk -F'\t' '{ print $2 }' "$X/sets" > "$T/sid"; RB=$(awk -v S="$T/sid" 'BEGIN { while ((getline l < S) > 0) I[l] = 1 } !NF { next } { n++ }
      /^none[ \t]*$/ { z++; next } /^finding [A-Z][A-Z0-9]*-[0-9][0-9A-Z-]* \| ./ { if (!($2 in I)) { print "line " NR " names " $2 ", no row of the draft"; exit } next }
      { print "line " NR " is out of form: " substr($0, 1, 40); exit } END { if (!n) print "it is empty"; else if (z && n > 1) print "none with findings" }' "$RV")
  [ -z "$RB" ] || { rm -rf "$X"; ref "--review $RV: $RB"; }; cp "$RV" "$X/review"
  DT=$(date -u '+%Y-%m-%dT%H:%M:%S+0000'); export DT
  ( dryrun "$X" "$(cat "$X/base")" 'draft check: the owner has not answered yet' ) 2> "$T/dre" || { rm -rf "$X"; w=$(sed -n 's/^ViD land: refused — //p' "$T/dre" | head -n 1); ref "the draft could not land, so it is not made, and the tree is kept to correct: ${w:-$(tail -n 1 "$T/dre")}"; }
  for f in $CH; do if git cat-file -e "HEAD:$f" 2>/dev/null; then git checkout -q HEAD -- "$f"; else rm -f "$f"; fi; done
  [ -z "$RPL" ] || { echo "$n" > "$DR/$RPL/replaced"; ev "draft-replaced n=$RPL by=$n"; echo "replaced $RPL"; }
  ev "draft n=$n files=$(echo $CH | tr ' ' ,)"; echo "draft $n"; cat "$X/count"; }
# count <draft dir>: the count (inventory.sh impact --tickets), the sets, and the Q line's words
count() { X=$1; P=PRD.md; I=INVENTORY.md; [ ! -f "$X/files/PRD.md" ] || P=$X/files/PRD.md; [ ! -f "$X/files/INVENTORY.md" ] || I=$X/files/INVENTORY.md; B=$(cat "$X/base")
  sh "$HERE/inventory.sh" impact --tickets --base "$B" --prd "$P" --inventory "$I" > "$T/cn" 2> "$T/ie" || ref "the count failed: $(tail -n 1 "$T/ie")"; put "$X/count" < "$T/cn" || ref "the count failed: $(tail -n 1 "$T/ie")"
  sh "$HERE/inventory.sh" impact --tickets --detail --base "$B" --prd "$P" --inventory "$I" > "$T/se" 2> /dev/null || true; put "$X/sets" < "$T/se" || exit 1
  awk -F'\t' '$1 == "added" && $3 != "transition" { print $2 }' "$X/sets" > "$T/ad"; dblock "$X" > "$T/blk"; stepsof "$T/ad" "$T/blk" > "$T/sq" || exit 1; put "$X/steps" < "$T/sq" || exit 1
  r=$(awk -F'\t' '$1 == "reset" && $3 != "transition"' "$X/sets" | grep -c . || true); a=$(grep -c . "$T/ad" || true); m=$(awk -F'\t' '$1 == "reached"' "$X/sets" | grep -c . || true)
  st=$(cut -d' ' -f2 "$X/steps" | sort -u | paste -sd ',' - | sed 's/,/, /g'); ms=$(awk -F'\t' '$1 == "reached" { print $2 }' "$X/sets" | paste -sd ',' - | sed 's/,/, /g')
  # IR I5: a draft's map, its counts (form 2): changes, left: lines and open: lines, a blank line or a # line skipped
  mc=''; if [ -f "$X/map" ]; then mc=$(awk '/^[ \t]*(#|$)/ { next } /^left:/ { l++; next } /^open:/ { o++; next } { c++ } END { printf "map: %d changes, %d left, %d open", c, l, o }' "$X/map"); echo "$mc" >> "$X/count"; fi
  printf 'This changes %s, adds %s%s, and reaches %s more%s%s. Land it?\n' "$r row$([ "$r" = 1 ] || echo s)" "$a" "${st:+ in $st}" "$m" "${ms:+: $ms}" "${mc:+; $mc}" > "$T/wo" || exit 1; put "$X/words" < "$T/wo" || exit 1; echo "words $(cat "$X/words")" >> "$X/count"; }

# fkey <line>: a fix line's key, the cksum of its text less its stand-in label (writer.sh, close.sh: v0.26.10.25.4 R2)
fkey() { printf '%s' "$1" | sed 's/[[:space:]]*[|][[:space:]]*stand-in.*$//' | tr -d '\n' | cksum | cut -d' ' -f1; }
# records <root> <landing, 12> <draft dir>: R4's and R5's records under <root>; the asks it withdrew in $T/wd (`<step> <k> <issue>`)
records() { ( cd "$1" || exit 1; L=$2; X=$3; W=$(now); mkdir -p "$D" .vid/tw; touch "$D/counts" "$D/limits" "$D/halted" "$D/record" "$D/state" "$D/rulings" "$D/landed" "$HAND"
  awk -F'\t' '$1 == "reset" || $1 == "added" { print $2 }' "$X/sets" | awk '!s[$0]++' > "$T/x"
  printf 'landed %s ids=%s at=%s\n' "$(basename "$X")" "$(paste -sd , "$T/x")" "$W" >> "$LOG"   # the log's order: tickets published before it, and after
  while read -r i; do printf '%s %s %s\n' "$i" "$L" "$W" >> "$D/landed"; printf '%s\t%s\treset\tlanded at %s\tSP\n' "$W" "$i" "$L" >> "$D/rulings"; done < "$T/x"
  for f in counts limits; do awk -v X="$T/x" 'BEGIN { while ((getline l < X) > 0) R[l] = 1 } { split($0, a, " ") } !(a[1] in R)' "$D/$f" > "$T/f" || exit 1; put "$D/$f" < "$T/f" || exit 1; done
  awk -F'\t' -v X="$T/x" 'BEGIN { while ((getline l < X) > 0) R[l] = 1 } !($2 in R)' "$D/halted" > "$T/f" || exit 1; put "$D/halted" < "$T/f" || exit 1
  awk -F'\t' -v X="$T/x" 'BEGIN { while ((getline l < X) > 0) R[l] = 1 } !($1 in R)' "$D/state" > "$T/f" || exit 1; put "$D/state" < "$T/f" || exit 1
  grep -vxF -f "$T/x" "$D/record" > "$T/f" || true; put "$D/record" < "$T/f" || exit 1
  # the handed record: its row lines dropped; out of every fix line not yet published, which is then known by its new text
  grep '^published ' "$LOG" 2>/dev/null | tr ' ' '\n' | sed -n 's/^fix=//p' | sort -u > "$T/pf"
  : > "$T/h"; : > "$T/mv"; while IFS= read -r l; do case $l in
      "row "*) r=${l#row }; r=${r%% *}; ! grep -qxF "$r" "$T/x" || continue ;;
      "fix "*'|'*) k=$(fkey "$l"); grep -qxF "$k" "$T/pf" && { printf '%s\n' "$l" >> "$T/h"; continue; }
        nl=$(printf '%s\n' "$l" | awk -v X="$T/x" 'BEGIN { while ((getline l < X) > 0) R[l] = 1 }
          { split($0, p, /[ \t]*[|][ \t]*/); n = split(p[1], w, /[ \t]+/); o = ""; c = 0; for (i = 2; i <= n; i++) if (w[i] in R) c++; else o = o " " w[i]
            if (!c) { print; exit } if (o == "") { print "-"; exit } m = split(p[2], q, /; /); r = ""; for (i = 1; i <= m; i++) { x = q[i]; sub(/:.*/, "", x); if (!(x in R)) r = r (r == "" ? "" : "; ") q[i] }
            l = "fix" o " | " r; for (i = 3; i in p; i++) l = l " | " p[i]; print l }')
        if [ "$nl" = - ]; then printf '%s\t-\t\n' "$k" >> "$T/mv"; continue; fi
        [ "$nl" = "$l" ] || printf '%s\t%s\t%s\n' "$k" "$(fkey "$nl")" "$(printf '%s' "${nl%% |*}" | sed 's/^fix //')" >> "$T/mv"; l=$nl ;;
    esac; printf '%s\n' "$l" >> "$T/h"; done < "$HAND" || exit 1; put "$HAND" < "$T/h" || exit 1
  touch "$T/mv"; for f in $(ls "$D"/close/*/*/fixes "$D"/stage/*/*/fixes "$D"/stage/*/*/cs/fixes 2>/dev/null); do awk -F'\t' -v MV="$T/mv" 'BEGIN { while ((getline l < MV) > 0) { split(l, a, "\t"); N[a[1]] = a[2]; R[a[1]] = a[3] } }
      ($1 in N) { if (N[$1] != "-") print N[$1] "\t" R[$1]; else print $1 "\t"; next } { print }' "$f" > "$T/f" || exit 1; put "$f" < "$T/f" || exit 1; done
  # the reached rows a published ticket holds, one line each item
  awk '($1 == "published" || $1 == "amended") { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) { n = split(substr($i, 6), a, ","); for (j = 1; j <= n; j++) print a[j] } }' "$LOG" 2>/dev/null | sort -u > "$T/tk"
  awk -F'\t' '$1 == "reached" { n = split($3, a, " "); for (i = 1; i <= n; i++) print $2, a[i] }' "$X/sets" | while read -r r it; do grep -qxF "$r" "$T/tk" || continue
    grep -q "^reached $r $it $L " "$HAND" || printf 'reached %s %s %s | stand-in: SP\n' "$r" "$it" "$L" >> "$HAND"; done
  # R5: a step that gains a row is open again: its closed line dropped, its newest ask withdrawn, whatever its state
  awk -F'\t' '($1 == "reset" || $1 == "added") && $3 != "transition" { print $2 }' "$X/sets" > "$T/xb"; dblock "$X" > "$T/blk"; stepsof "$T/xb" "$T/blk" | cut -d' ' -f2 | sort -u > "$T/rs"
  # 0.26.10.29.2 (R9): but a closed step of a stage with a candidate keeps its closed line and its ask: that stage's re-close C3,
  # or a later stage's C3, covers its rows, and rule B and the graded gate hold its dependents until every row it holds is settled
  # again (plan.sh's tclosed). Its stage is close.sh's (step-stages, its sst), read as the spec stands once the draft lands: the
  # spec files with the draft's over them, less a file the draft deletes (R2's <n>/deleted), and the draft's block, in a view of their
  # own; a step of a stage with no candidate reopens
  if grep -q '^candidate ' "$HAND" && [ -s "$T/rs" ]; then V=$T/view; rm -rf "$V"; mkdir -p "$V/.vid"; for f in $HASHF; do if [ -f "$X/files/$f" ]; then cp "$X/files/$f" "$T/view/$f"; elif [ -f "$f" ] && ! gone "$X" "$f"; then cp "$f" "$T/view/$f"; fi; done
    { printf '## The plan\n\n```vid-plan\n'; cat "$T/blk"; printf '```\n'; } > "$V/.vid/RUN-STATE.md"; ( cd "$V" && sh "$HERE/close.sh" step-stages ) > "$T/sst" 2>/dev/null || : > "$T/sst"
    while read -r s; do grep -q "^closed $s " "$HAND" || continue; x=$(awk -F'\t' -v s="$s" '$1 == s { print $2; exit }' "$T/sst")
      [ -n "$x" ] && grep -q "^candidate $x " "$HAND" && echo "$s"; done < "$T/rs" > "$T/kc"; grep -vxF -f "$T/kc" "$T/rs" > "$T/rs2" || :; cp "$T/rs2" "$T/rs"; fi
  : > "$T/wd"; while read -r s; do grep -v "^closed $s " "$HAND" > "$T/h" || true; cmp -s "$T/h" "$HAND" || { put "$HAND" < "$T/h" || exit 1; echo "reopened $s"; }
    k=''; for j in $(ls "$D/close/$s" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/close/$s/$j/ask" ] && k=$j; done
    [ -n "$k" ] && [ ! -f "$D/close/$s/$k/withdrawn" ] || continue; printf '%s %s\n' "$L" "$W" > "$D/close/$s/$k/withdrawn"
    printf '%s %s %s\n' "$s" "$k" "$(sed -n 's/^issue	//p' "$D/close/$s/$k/ask" | head -n 1)" >> "$T/wd"; echo "withdrawn $s $k"; done < "$T/rs"
  # v0.26.10.26.7 (R9, W-11): a reached row a published ticket holds withdraws every newest live close whose rows (its
  # own, its dependencies', its regression rows, as its ask recorded them) hold it, a closed step's apart; the rows that did, in
  # <k>/reached, gathered over the landings while it stays withdrawn, for close.sh's wait and commit
  grep "^reached [^ ]* [^ ]* $L | stand-in: SP\$" "$HAND" | cut -d' ' -f2 | sort -u > "$T/rr"
  if [ -s "$T/rr" ]; then for s in $(ls "$D/close" 2>/dev/null); do grep -q "^closed $s " "$HAND" && continue
      k=''; for j in $(ls "$D/close/$s" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/close/$s/$j/ask" ] && k=$j; done; K=$D/close/$s/$k
      [ -n "$k" ] && [ -f "$K/rows" ] || continue
      awk -v RR="$T/rr" 'BEGIN { while ((getline l < RR) > 0) W[l] = 1 } { r = $1; b = r; sub(/-T[0-9]+$/, "", b); if (r in W) print r; else if (b in W) print b }' "$K/rows" | sort -u > "$T/rk"; [ -s "$T/rk" ] || continue
      if [ ! -f "$K/withdrawn" ]; then printf '%s %s\n' "$L" "$W" > "$K/withdrawn"; printf '%s %s %s\n' "$s" "$k" "$(sed -n 's/^issue	//p' "$K/ask" | head -n 1)" >> "$T/wd"; echo "withdrawn $s $k"; fi
      cat "$K/reached" "$T/rk" 2>/dev/null | sort -u > "$T/rk2" || exit 1; put "$K/reached" < "$T/rk2" || exit 1; done; fi
  # 0.26.10.29.2 (R2): a re-cut withdraws every candidate of each stage it changes (dryrun refused a closed or deployed one), the newest
  # and any older one, with the asks made at it still out: its C3, its S1, its D1 okay; close.sh then names a new candidate once one is
  # due. The asks, in $T/ws (`<N> <c> <c3|s1|d1> <issue>`), have their issues closed last
  # 0.26.11.1.2 (R10): and the candidates of a stage the re-cut makes final, neither closed nor deployed, so its next asks the end grade
  : > "$T/ws"; if recut "$X"; then cutd "$X" "$(cat "$X/base")" > "$T/cut" || exit 1
    fa=$(cutn "$T/ca/STAGES.md" | tail -n 1); fb=$(cutn "$T/cb/STAGES.md" | tail -n 1); cp "$T/cut" "$T/wcut" || exit 1   # $T/cut stays the cut's own, which hollow reads
    [ "$fa" = "$fb" ] || sclosed_ "$fb" || deployed "$fb" || { echo "$fb" >> "$T/wcut"; sort -nu "$T/wcut" -o "$T/wcut"; }
    for N in $(cat "$T/wcut"); do for c in $(ls "$SD/$N" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do F=$SD/$N/$c; [ -f "$F/ask" ] && [ -f "$F/named" ] && [ ! -f "$F/withdrawn" ] || continue
      printf '%s %s\n' "$L" "$W" > "$F/withdrawn"; ev "stage-candidate-withdrawn stage=$N candidate=$c by=$L"; echo "withdrawn stage-$N $c"
      [ -f "$F/passed" ] || [ -f "$F/done" ] || printf '%s %s c3 %s\n' "$N" "$c" "$(sed -n 's/^issue	//p' "$F/ask" | head -n 1)" >> "$T/ws"
      if [ -f "$F/s1ask" ] && [ ! -f "$F/s1done" ] && [ ! -f "$F/s1withdrawn" ]; then : > "$F/s1withdrawn"; printf '%s %s s1 %s\n' "$N" "$c" "$(sed -n 's/^issue	//p' "$F/s1ask" | head -n 1)" >> "$T/ws"; fi
      if [ -f "$F/d1/ask" ] && [ ! -f "$F/d1/passed" ] && [ ! -f "$F/d1/closed" ]; then printf 'withdrawn by the landing %s %s\n' "$L" "$W" > "$F/d1/closed"; printf '%s %s d1 %s\n' "$N" "$c" "$(sed -n 's/^issue	//p' "$F/d1/ask" | head -n 1)" >> "$T/ws"; fi; done; done; fi
  ev "landed draft=$(basename "$X") at=$L ids=$(grep -c . "$T/x") reopened=$(paste -sd , "$T/rs" | grep . || echo -)" ) || return 1; }

# commits <draft dir>: the commits as develop makes them, the draft's files alone, at the fixed date DT; prints each sha
# answers <draft dir>: the owner's answers the draft's PRD adds, `A-1, A-2`
answers() { [ ! -f "$1/files/PRD.md" ] || git show "$(cat "$1/base"):PRD.md" 2>/dev/null | diff - "$1/files/PRD.md" | sed -n 's/^> //p' | grep -oE '(^|[^A-Za-z0-9-])A-[0-9]+' | grep -oE 'A-[0-9]+' | sort -u | paste -sd ',' - | sed 's/,/, /g'; }
commits() { X=$1; why=$(cat "$X/why"); n=$(basename "$X")
  # the owner's answers the draft's PRD adds, cited in each message, as a placement's law commit must (commit-msg, stages.sh msg)
  # 0.26.10.29.3 (R2): and the owner's yes as the Owner: trailer commit-msg asks of a commit adding a human answer
  AN=$(answers "$X")
  # 0.26.10.29.5 (DP-1 R7): the Decisions: line states what the landing admits, the draft's why on one line and its count's first line,
  # passed to printf as arguments, never as its format, so a per cent sign, a quote or a backslash in the why is written as it stands
  DW=$(printf '%s' "$why" | tr '\r\n' '  '); CL=$(sed -n 1p "$X/count" 2>/dev/null); [ -n "$CL" ] || CL='no count'
  # IR I5: the architecture first (a law commit of its own when it changes ARCHITECTURE.md's or BASELINE.md's law regions, both law files)
  for g in 'ARCHITECTURE.md BASELINE.md|the architecture' 'PRD.md GRADING-CHECKLIST.md DECISIONS.md|the PRD' 'INVENTORY.md STAGES.md|the law' 'PLAN.md|the plan file'; do fs=''
    for f in ${g%%|*}; do if gone "$X" "$f"; then git rm -q -- "$f" || return 1; fs="$fs $f"; continue; fi   # 0.26.10.29.2 (R2): a deletion the draft carries
      [ -f "$X/files/$f" ] || continue; put "$f" < "$X/files/$f" || return 1; git add -- "$f" || return 1; fs="$fs $f"; done; [ -n "$fs" ] || continue
    printf 'Land draft %s, %s: %s\n\nThe owner'"'"'s yes, during the run: "%s"%s\n\nDecisions: admits %s (%s) — the owner'"'"'s yes\nOwner: "%s"\n' "$n" "${g#*|}" "$why" "$WORDS" "${AN:+
Answers: $AN}" "$DW" "$CL" "$WORDS" > "$T/msg"
    GIT_AUTHOR_DATE=$DT GIT_COMMITTER_DATE=$DT git commit -q -F "$T/msg" -- $fs > "$T/ce" 2>&1 || { cat "$T/ce" >&2; return 1; }; git rev-parse HEAD; done; }   # the draft's paths alone, whatever else is staged
# plan_change <draft dir> <landing>: the draft's block in RUN-STATE, then plan.sh change rows
# 0.26.10.29.2 (R2): a re-cut's change is a scope-change, the rows of a moved stage taken out of their open tickets by the plan
# PCX: the body of RUN-STATE's plan block, the first vid-plan fence under "## The plan", replaced by the file P's lines, every other line as it was
# (9.3 R2: the landing's one change to the run record, and its roll-back's; a vid-plan fence in the prose is no plan)
PCX='/^## / { t = ($0 ~ /^## The plan/) } t && !d && /^```vid-plan[ \t]*$/ { print; while ((getline l < P) > 0) print l; s = 1; d = 1; next } s && /^```[ \t]*$/ { s = 0 } !s { print }'
plan_change() { X=$1; if [ -s "$X/plan" ]; then rs_edit awk -v P="$X/plan" "$PCX" || return 1; fi
  ids=$(awk -F'\t' '($1 == "reset" || $1 == "added") && $3 != "transition" { print $2 }' "$X/sets" | paste -sd ' ' -); st=$(dblock "$X" > "$T/blk"; awk -F'\t' '($1 == "reset" || $1 == "added") && $3 != "transition" { print $2 }' "$X/sets" > "$T/xb"; stepsof "$T/xb" "$T/blk" | cut -d' ' -f2 | sort -u | paste -sd ' ' -)
  sh "$HERE/plan.sh" change rows "the owner's yes to draft $(basename "$X"): $(cat "$X/why")" --trigger "$(recut "$X" && echo scope-change || echo owner-answer)" --evidence "commit:$2" --expect "${ids:+a new ticket of ${st:-its step} for $ids}${ids:-no row changes: the spec export carries it}" > "$T/pc" 2>&1; }

# dryrun <draft dir> <base> <words>: the landing's checks on a scratch copy, nothing landed; sets LD, XA and HD
dryrun() { X=$1; B=$2; WORDS=$3
  # 0.26.10.29.2 (R2): a re-cut never changes a stage closed or deployed, at draft time and again at the landing
  if recut "$X"; then [ -n "$(answers "$X")" ] || ref "the re-cut adds no owner answer to PRD.md's vid-prd-answers block, which its law commit cites: nothing landed"
    cutd "$X" "$B" > "$T/cut" || ref "the re-cut's stages could not be read: nothing landed"
    for N in $(cat "$T/cut"); do ! sclosed_ "$N" || ref "the re-cut changes stage $N, which is closed: a closed stage stands as it is (a new rule row sits in stage 1 unless the cut places it: give it a line \`row: <id> -> STAGE-<k>\` for an open stage, or cut with \`rules: by-origin\` where its requirements are in an open stage); nothing landed"
      ! deployed "$N" || ref "the re-cut changes stage $N, which is deployed (a candidate's D1 passed, or it runs in production): a deployed stage stands as it is (a new rule row sits in stage 1 unless the cut places it: give it a line \`row: <id> -> STAGE-<k>\` for an open stage, or cut with \`rules: by-origin\` where its requirements are in an open stage); nothing landed"; done; fi
  # the dry run: a scratch copy, the records and commits made there with the hooks on, the plan change, planner.sh check
  SC=$T/sc; git clone -q --no-hardlinks . "$SC" 2> "$T/ge" || ref "no scratch copy: $(tail -n 1 "$T/ge")"
  BR=$(git symbolic-ref -q --short HEAD || true); if [ -n "$BR" ]; then git -C "$SC" checkout -q -B "$BR" "$B"; else git -C "$SC" checkout -q --detach "$B"; fi
  for k in core.hooksPath core.filemode user.name user.email; do v=$(git config --get "$k" || true); [ -z "$v" ] || git -C "$SC" config "$k" "$v"; done   # core.filemode: 0.26.11.1.4 (R5), below
  [ ! -d checks ] || cp -R checks "$SC/"   # the hooks and courts as the working tree holds them, committed or not
  # 0.26.11.1.4 (R5): each of the copy's hooks executable as the live tree's is, since cp keeps a file's mode where it exists: on a synced
  # folder the live tree runs them whatever their recorded mode, and a hook checked out 100644 would be skipped in the dry run alone. With
  # the live core.filemode copied above, the copy reads that mode as no change, as the live tree does
  for h in checks/hooks/*; do [ -f "$h" ] && [ -f "$SC/$h" ] || continue; if [ -x "$h" ]; then chmod +x "$SC/$h"; else chmod -x "$SC/$h"; fi; done
  mkdir -p "$SC/.vid"; for e in .vid/* .vid/.[!.]*; do [ -e "$e" ] || continue; case ${e#.vid/} in code|spec.git|results|*.lock|*.lock.steal) continue ;; esac; cp -R "$e" "$SC/.vid/"; done   # no live lock into the dry run
  XA=$(cd "$X" && pwd)
  records "$SC" "$(printf %.12s "$B")" "$XA" > /dev/null || ref "the dry run's records failed: nothing landed"
  ( cd "$SC" && commits "$XA" ) > "$T/shas" || ref "the dry run's commits were refused (above): nothing landed"
  LD=$(tail -n 1 "$T/shas"); [ -n "$LD" ] || ref 'the draft holds no file to commit'
  # 0.26.10.29.2 (R2): a re-cut's stage: moved first, as the landing moves it, so its own plan change is judged at the stage it lands in
  if recut "$X"; then ( cd "$SC" && stmove ) > /dev/null || ref "the dry run could not move RUN-STATE's stage: nothing landed"; fi
  ( cd "$SC" && sed "s/ $(printf %.12s "$B") / $(printf %.12s "$LD") /" "$D/landed" > "$T/ld" && put "$D/landed" < "$T/ld" && plan_change "$XA" "$LD" ) || ref "the dry run's plan change was refused: $(grep -m 1 'refused' "$T/pc" || tail -n 1 "$T/pc"); nothing landed"
  # 0.26.10.29.2 (R2): a stage the re-cut changes and leaves with no row, by each row's effective stage, would never get a candidate,
  # and the stages after it would wait for good; a stage it never touched is not its concern
  if recut "$X"; then ( cd "$SC" && hollow "$T/cut" ) > "$T/hol" || ref "the re-cut's rows could not be read: nothing landed"; e=$(head -n 1 "$T/hol"); [ -z "$e" ] || ref "the re-cut leaves stage $e with no row (each row by its stage, a PLAN.md moved: line counted): a stage holds at least one row, or the cut drops it; nothing landed"; fi
  ( cd "$SC" && sh "$HERE/planner.sh" check ) > "$T/pk" 2>&1 || ref "the dry run's planner.sh check flags the plan: $(head -n 1 "$T/pk"); nothing landed"
  HD=$(for f in $HASHF; do { [ -f "$X/files/$f" ] || gone "$X" "$f"; } && printf '%s,' "$f"; done)   # 0.26.10.29.2 (R2): a deleted file is held too
  ( cd "$SC" && sh "$HERE/planner.sh" reratify --words "$WORDS" --base "$B" --to "$LD" --held "${HD%,}" ) > "$T/rr" 2>&1 || ref "the dry run's reratify refuses: $(sed -n 's/^ViD planner: reratify refused — //p' "$T/rr" | head -n 1); nothing landed"
}

cmd_land() { n=${1:-}; shift; WORDS=''; [ "${1:-}" = --words ] && WORDS=${2:-}; [ -n "$WORDS" ] || die 'usage — sh checks/land.sh <n> --words "<the owner'"'"'s yes>"'
  X=$DR/$n; [ -f "$X/base" ] || die "no draft $n"; [ ! -f "$X/landed" ] || ref "draft $n landed already, at $(cat "$X/landed")"
  [ ! -f "$X/replaced" ] || ref "draft $n was replaced by draft $(cat "$X/replaced"): ask that one"
  # 1. the refusals first
  G=$(sh "$HERE/plan.sh" gate 2>/dev/null); run=$(sed -n 's/^run:[[:space:]]*//p' .vid/RUN-STATE.md | head -n 1)
  case "$G" in on*) ;; *) ref "the run's gate is off (${G#off }): draft $n waits for continue, and nothing lands" 3 ;; esac
  case "$run" in active*|waiting*|'stopped owner asked to hold after stage '*) ;; *) ref "run: $run — draft $n waits for continue, and nothing lands" 3 ;; esac   # v0.26.10.26.5 (R3): a hold is no stop for its stage's corrections
  B=$(cat "$X/base"); [ "$(git rev-parse HEAD)" = "$B" ] || ref "HEAD moved since draft $n was drafted on $(printf %.12s "$B"): it is stale, and SP redrafts it" 4
  for f in $SPEC; do [ -z "$(git status --porcelain -- "$f" 2>/dev/null)" ] || ref "$f has an uncommitted change: draft it, or put it back"; done
  DT=$(date -u '+%Y-%m-%dT%H:%M:%S+0000'); export DT
  dryrun "$X" "$B" "$WORDS"
  # 3. the records, then the commits, the plan change and the ratification
  L=$(printf %.12s "$LD"); cp -R "$D" "$T/bk-decide"; for f in "$HAND" "$LOG" .vid/RUN-STATE.md .vid/metrics-events; do cp "$f" "$T/bk-$(basename "$f")" 2>/dev/null || : > "$T/bk-$(basename "$f")"; done
  mkdir -p .vid/plans .vid/plan; cp -R .vid/plans "$T/bk-plans"; cp -R .vid/plan "$T/bk-plan"
  # 9.3 R2: RUN-STATE is rolled back in the one block the landing changes, its plan, so another writer's lines since stand
  awk '/^## / { t = ($0 ~ /^## The plan/) } t && !d && /^```vid-plan[ \t]*$/ { s = 1; d = 1; next } s && /^```[ \t]*$/ { exit } s' .vid/RUN-STATE.md > "$T/bk-planblk" || exit 1
  back() { BF=''; putd "$D" "$T/bk-decide" || BF="$BF $D"; for f in "$HAND" "$LOG" .vid/metrics-events; do put "$f" < "$T/bk-$(basename "$f")" || BF="$BF $f"; done; rs_edit awk -v P="$T/bk-planblk" "$PCX" || BF="$BF .vid/RUN-STATE.md"; putd .vid/plans "$T/bk-plans" || BF="$BF .vid/plans"; putd .vid/plan "$T/bk-plan" || BF="$BF .vid/plan"
    [ -z "${OST:-}" ] || rs_edit sed "s/^stage:[[:space:]]*[0-9][0-9]*/stage: $OST/" || BF="$BF .vid/RUN-STATE.md"   # 0.26.10.29.2 (R2): a re-cut's stage: put back
    # a restore that failed keeps the backup where it is, the EXIT trap disarmed, and says so with the base
    [ -z "$BF" ] || { trap - EXIT; die "$1 after the dry run passed, and the roll-back could not restore$BF: their backup is kept in $T (bk-*), and nothing is reset — the base is $(printf %.12s "$B")"; }   # kept in place, never copied
    git reset -q --soft "$B"; for f in $SPEC; do git reset -q "$B" -- "$f" 2>/dev/null; if git cat-file -e "$B:$f" 2>/dev/null; then git checkout -q "$B" -- "$f"; else rm -f "$f"; fi; done
    die "$1 after the dry run passed: rolled back to $(printf %.12s "$B"), nothing landed"; }
  records "$PWD" "$L" "$XA" > "$T/rec" || back 'the records failed'
  commits "$XA" > "$T/shas2" || back 'a commit was refused' 
  LR=$(tail -n 1 "$T/shas2"); L2=$(printf %.12s "$LR")
  if [ "$L2" != "$L" ]; then for f in "$D/landed" "$HAND" $(ls "$D"/close/*/*/withdrawn "$D"/stage/*/*/withdrawn "$D"/stage/*/*/d1/closed 2>/dev/null); do sed "s/ $L / $L2 /; s/^$L /$L2 /" "$f" > "$T/f" || back 'a record could not be rewritten'; put "$f" < "$T/f" || back 'a record could not be rewritten'; done; sed "s/	landed at $L	/	landed at $L2	/" "$D/rulings" > "$T/f" || back 'a record could not be rewritten'; put "$D/rulings" < "$T/f" || back 'a record could not be rewritten'; L=$L2; fi
  # 0.26.10.29.2 (R2): a re-cut moves RUN-STATE's stage: to the new cut's current stage before its own plan change, so the change and
  # every admission after read the new cut; the roll-back puts the old stage: back
  : > "$T/stm"; if recut "$X"; then OST=$(sed -n 's/^stage:[[:space:]]*\([0-9][0-9]*\).*/\1/p' .vid/RUN-STATE.md | head -n 1); stmove > "$T/stm" || back "RUN-STATE's stage: could not be moved"; fi
  plan_change "$XA" "$LR" || back "the plan change was refused ($(grep -m 1 refused "$T/pc" || tail -n 1 "$T/pc"))"
  sh "$HERE/planner.sh" reratify --words "$WORDS" --base "$B" --to "$LR" --held "${HD%,}" > "$T/rr" 2>&1 || back "reratify refused ($(tail -n 1 "$T/rr"))"
  ev "publish-approved words=\"$WORDS\""   # the owner's go in the same words, so the writer's gate opens; through event.sh (9.3 R1)
  echo "$LR" > "$X/landed"; ev "land-landed draft=$n at=$L"
  # 0.26.10.29.2 (R2): a re-cut's stage-cut event, as /vid stage records one outside ticket mode: the new cut's stages (1 with no
  # STAGES.md), the answer its law commit cites, STAGES.md's blob
  if recut "$X"; then ns=1; bl=''; if [ -f STAGES.md ]; then ns=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | grep -cE '^[[:space:]]*STAGE-[0-9]+[[:space:]]*\|'); bl=" blob=$(git rev-parse "$LR:STAGES.md")"; fi
    ev "stage-cut n=$ns answer=$(answers "$X" | sed 's/,.*//')$bl"; fi
  # 4. last, each withdrawn ask's issue closed on GitHub, with a comment naming the landing
  while read -r s k i; do [ -n "$i" ] || continue; printf 'vid: withdrawn. The landing %s changed rows of %s; this close is asked again once its new tickets merge. A later report for it is not read.\n' "$L" "$s" > "$T/wc"
    sh "$HERE/github.sh" comment "$i" --body-file "$T/wc" > /dev/null 2>&1 && sh "$HERE/github.sh" close "$i" > /dev/null 2>&1 && echo "issue $i" >> "$D/close/$s/$k/withdrawn" || echo "ask-open $s $i"; done < "$T/wd"
  # 0.26.10.29.2 (R2): and each ask a re-cut withdrew at a stage's candidate
  while read -r N c w i; do [ -n "$i" ] || continue; printf 'vid: withdrawn. The landing %s re-cut the stages and changed stage %s; its candidate %s is withdrawn, and a new one is named once one is due. A later report for this one is not read.\n' "$L" "$N" "$c" > "$T/wc"
    sh "$HERE/github.sh" comment "$i" --body-file "$T/wc" > /dev/null 2>&1 && sh "$HERE/github.sh" close "$i" > /dev/null 2>&1 || echo "ask-open stage-$N $i"; done < "$T/ws"
  cat "$T/rec" "$T/stm" 2>/dev/null; echo "landed $n at $L: $(sed -n 1p "$X/count")"; }

CMD=${1:-}; [ $# -eq 0 ] || shift
# GM-1 S1: in GitHub manual the door neither drafts nor lands: a landing re-ratifies on its own, which the applied version
# refuses while anything is pending. The owner changes the spec by hand, as today, and the change shows as pending
case $CMD in draft|[0-9]*) if manual; then ref 'In GitHub manual the door does not change the spec: change it by hand, as today, and the change shows as pending at /vid next.'; fi ;; esac
case $CMD in
  draft) cmd_draft "$@" ;;
  count) X=$DR/${1:-}; [ -f "$X/base" ] || die "no draft ${1:-}"; count "$X"; cat "$X/count" ;;
  [0-9]*) cmd_land "$CMD" "$@" ;;
  *) echo 'usage: sh checks/land.sh draft --review <file> [--why "<…>"] [--plan <file>] [--for <keys>] [--replaces <n>] [--map <file>] | count <n> | <n> --words "<the owner'"'"'s yes>"' >&2; exit 2 ;;
esac

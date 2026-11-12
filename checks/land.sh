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
#   count <n>                     the draft's count, and the Q line's words
#   <n> --words "<the owner's yes>"   lands draft n. Refused, nothing landed: exit 3 while plan.sh's gate is off, a pause or
#       any stop (it waits for continue); exit 4 when HEAD is not the draft's base (stale: SP redrafts); exit 1 when the dry
#       run on a scratch copy refuses (a court, plan.sh change, rule A or B, planner.sh check). Then: the records (R4, R5),
#       the commits as develop makes them (the PRD with GRADING-CHECKLIST.md and DECISIONS.md; one law commit of
#       INVENTORY.md, STAGES.md and ARCHITECTURE.md; PLAN.md alone), the plan change, planner.sh reratify in the owner's
#       words, and last each withdrawn ask's issue closed on GitHub
# Records: .vid/decide/landed (`<id> <the landing, 12> <time>`, each reset or added line, a journey's transitions with it);
# for each: its counts, limits, halted, record and state lines gone, a `reset` ruling, its handed row line dropped, every
# unpublished fix line without it; `reached <row> <item> <landing> | stand-in: SP` for a reached row a ticket holds; a
# reopened step's closed line dropped and its newest ask withdrawn (.vid/decide/close/<step>/<k>/withdrawn). v0.26.10.26.7 (R9): a
# reached row a published ticket holds withdraws every newest live close whose rows hold it, recorded in <k>/reached.
# Usage: sh checks/land.sh draft --review <file> [--why "<…>"] [--plan <file>] [--for <keys>] [--replaces <n>] | count <n> | <n> --words "<the owner's yes>"
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
D=.vid/decide; DR=$D/drafts; HAND=.vid/tw/handed; LOG=.vid/tw/log
die() { echo "ViD land: $*" >&2; exit 2; }
ref() { echo "ViD land: refused — $1" >&2; exit "${2:-1}"; }
# putd <folder> <copy>: a folder replaced in four steps — the copy beside it as .put.$$.<name>, the live one aside as .old.$$.<name>,
# the copy in, the old one removed; a step that fails stops it with the live folder whole (v0.26.10.28.1, R6)
putd() { _q=$(dirname "$1")/.put.$$.$(basename "$1"); _o=$(dirname "$1")/.old.$$.$(basename "$1"); rm -rf "$_q" && cp -R "$2" "$_q" || { rm -rf "$_q"; return 1; }
  if [ -e "$1" ]; then mv "$1" "$_o" || { rm -rf "$_q"; return 1; }; fi; mv "$_q" "$1" || { [ ! -e "$_o" ] || mv "$_o" "$1"; rm -rf "$_q"; return 1; }; rm -rf "$_o" || true; }   # the copy is in: an old folder left behind is no failed restore
# a roll-back stopped between its two renames left .vid/.old.<pid>.<name> and no live folder: it is renamed back first
for _o in .vid/.old.*.decide .vid/.old.*.plans .vid/.old.*.plan; do [ -d "$_o" ] && [ ! -e ".vid/${_o##*.}" ] || continue; mv "$_o" ".vid/${_o##*.}"; done
[ -f .vid/RUN-STATE.md ] && [ -f INVENTORY.md ] || die "run it at the top of ViD's repository"
SPEC='PRD.md GRADING-CHECKLIST.md DECISIONS.md INVENTORY.md STAGES.md ARCHITECTURE.md PLAN.md'
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

# v0.26.10.26.5: --for records the items a draft answers, in <draft>/for
# v0.26.10.26.7 (R4, W-5): the landing's dry run runs at draft time, the re-ratifying in its check-only form (placeholder words, in
# the scratch copy alone); a refused draft is not made, its refusal names the check, and the tree is kept for SP to correct.
# --replaces <n>: once the new draft is made, draft n is marked replaced (<n>/replaced, the new number), its Q line closed
cmd_draft() { WHY=''; PL=''; FOR=''; RPL=''; RV=''; while [ $# -ge 2 ]; do case $1 in --why) WHY=$2 ;; --plan) PL=$2 ;; --for) FOR=$2 ;; --replaces) RPL=$2 ;; --review) RV=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ -z "$PL" ] || [ -f "$PL" ] || die "no plan block file at $PL"
  [ -n "$RV" ] || ref 'no --review: a fresh agent reviews the change over the rows it touches first, and its output (finding <row id> | <why> lines, or none) is the draft'"'"'s record'
  [ -s "$RV" ] || ref "--review $RV: no review output there"
  if [ -n "$RPL" ]; then O=$DR/$RPL; [ -f "$O/base" ] || die "--replaces $RPL: no draft $RPL"; for z in landed declined replaced; do [ ! -f "$O/$z" ] || ref "--replaces $RPL: draft $RPL is $z already"; done; fi
  CH=''; for f in $SPEC; do [ -z "$(git status --porcelain -- "$f" 2>/dev/null)" ] || CH="$CH $f"; done
  [ -n "$CH" ] || ref 'no spec file differs from HEAD: draft the change in the working tree first'
  mkdir -p "$DR"; n=$(( $(ls "$DR" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1 | grep . || echo 0) + 1 )); X=$DR/$n; mkdir -p "$X/files"
  git rev-parse HEAD > "$X/base"; printf '%s\n' "${WHY:-a change to the spec}" > "$X/why"; [ -z "$FOR" ] || printf '%s\n' "$FOR" | tr ',' '\n' | grep . > "$X/for"; [ -z "$PL" ] || pblock "$PL" > "$X/plan" 2>/dev/null; [ -z "$PL" ] || [ -s "$X/plan" ] || cp "$PL" "$X/plan"
  for f in $CH; do cp "$f" "$X/files/$f"; done
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
  printf 'This changes %s, adds %s%s, and reaches %s more%s. Land it?\n' "$r row$([ "$r" = 1 ] || echo s)" "$a" "${st:+ in $st}" "$m" "${ms:+: $ms}" > "$T/wo" || exit 1; put "$X/words" < "$T/wo" || exit 1; echo "words $(cat "$X/words")" >> "$X/count"; }

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
  ev "landed draft=$(basename "$X") at=$L ids=$(grep -c . "$T/x") reopened=$(paste -sd , "$T/rs" | grep . || echo -)" ) || return 1; }

# commits <draft dir>: the commits as develop makes them, the draft's files alone, at the fixed date DT; prints each sha
commits() { X=$1; why=$(cat "$X/why"); n=$(basename "$X")
  # the owner's answers the draft's PRD adds, cited in each message, as a placement's law commit must (commit-msg, stages.sh msg)
  AN=''; [ ! -f "$X/files/PRD.md" ] || AN=$(git show "$(cat "$X/base"):PRD.md" 2>/dev/null | diff - "$X/files/PRD.md" | sed -n 's/^> //p' | grep -oE '(^|[^A-Za-z0-9-])A-[0-9]+' | grep -oE 'A-[0-9]+' | sort -u | paste -sd ',' - | sed 's/,/, /g')
  for g in 'PRD.md GRADING-CHECKLIST.md DECISIONS.md|the PRD' 'INVENTORY.md STAGES.md ARCHITECTURE.md|the law' 'PLAN.md|the plan file'; do fs=''
    for f in ${g%%|*}; do [ -f "$X/files/$f" ] || continue; put "$f" < "$X/files/$f" || return 1; git add -- "$f" || return 1; fs="$fs $f"; done; [ -n "$fs" ] || continue
    printf 'Land draft %s, %s: %s\n\nThe owner'"'"'s yes, during the run: "%s"%s\n\nDecisions: none — the owner'"'"'s yes to a counted change (checks/land.sh)\n' "$n" "${g#*|}" "$why" "$WORDS" "${AN:+
Answers: $AN}" > "$T/msg"
    GIT_AUTHOR_DATE=$DT GIT_COMMITTER_DATE=$DT git commit -q -F "$T/msg" -- $fs > "$T/ce" 2>&1 || { cat "$T/ce" >&2; return 1; }; git rev-parse HEAD; done; }   # the draft's paths alone, whatever else is staged
# plan_change <draft dir> <landing>: the draft's block in RUN-STATE, then plan.sh change rows
# PCX: the body of RUN-STATE's plan block, the first vid-plan fence under "## The plan", replaced by the file P's lines, every other line as it was
# (9.3 R2: the landing's one change to the run record, and its roll-back's; a vid-plan fence in the prose is no plan)
PCX='/^## / { t = ($0 ~ /^## The plan/) } t && !d && /^```vid-plan[ \t]*$/ { print; while ((getline l < P) > 0) print l; s = 1; d = 1; next } s && /^```[ \t]*$/ { s = 0 } !s { print }'
plan_change() { X=$1; if [ -s "$X/plan" ]; then rs_edit awk -v P="$X/plan" "$PCX" || return 1; fi
  ids=$(awk -F'\t' '($1 == "reset" || $1 == "added") && $3 != "transition" { print $2 }' "$X/sets" | paste -sd ' ' -); st=$(dblock "$X" > "$T/blk"; awk -F'\t' '($1 == "reset" || $1 == "added") && $3 != "transition" { print $2 }' "$X/sets" > "$T/xb"; stepsof "$T/xb" "$T/blk" | cut -d' ' -f2 | sort -u | paste -sd ' ' -)
  sh "$HERE/plan.sh" change rows "the owner's yes to draft $(basename "$X"): $(cat "$X/why")" --trigger owner-answer --evidence "commit:$2" --expect "${ids:+a new ticket of ${st:-its step} for $ids}${ids:-no row changes: the spec export carries it}" > "$T/pc" 2>&1; }

# dryrun <draft dir> <base> <words>: the landing's checks on a scratch copy, nothing landed; sets LD, XA and HD
dryrun() { X=$1; B=$2; WORDS=$3
  # the dry run: a scratch copy, the records and commits made there with the hooks on, the plan change, planner.sh check
  SC=$T/sc; git clone -q --no-hardlinks . "$SC" 2> "$T/ge" || ref "no scratch copy: $(tail -n 1 "$T/ge")"
  BR=$(git symbolic-ref -q --short HEAD || true); if [ -n "$BR" ]; then git -C "$SC" checkout -q -B "$BR" "$B"; else git -C "$SC" checkout -q --detach "$B"; fi
  for k in core.hooksPath user.name user.email; do v=$(git config --get "$k" || true); [ -z "$v" ] || git -C "$SC" config "$k" "$v"; done
  [ ! -d checks ] || cp -R checks "$SC/"   # the hooks and courts as the working tree holds them, committed or not
  mkdir -p "$SC/.vid"; for e in .vid/* .vid/.[!.]*; do [ -e "$e" ] || continue; case ${e#.vid/} in code|spec.git|results|*.lock|*.lock.steal) continue ;; esac; cp -R "$e" "$SC/.vid/"; done   # no live lock into the dry run
  XA=$(cd "$X" && pwd)
  records "$SC" "$(printf %.12s "$B")" "$XA" > /dev/null || ref "the dry run's records failed: nothing landed"
  ( cd "$SC" && commits "$XA" ) > "$T/shas" || ref "the dry run's commits were refused (above): nothing landed"
  LD=$(tail -n 1 "$T/shas"); [ -n "$LD" ] || ref 'the draft holds no file to commit'
  ( cd "$SC" && sed "s/ $(printf %.12s "$B") / $(printf %.12s "$LD") /" "$D/landed" > "$T/ld" && put "$D/landed" < "$T/ld" && plan_change "$XA" "$LD" ) || ref "the dry run's plan change was refused: $(grep -m 1 'refused' "$T/pc" || tail -n 1 "$T/pc"); nothing landed"
  ( cd "$SC" && sh "$HERE/planner.sh" check ) > "$T/pk" 2>&1 || ref "the dry run's planner.sh check flags the plan: $(head -n 1 "$T/pk"); nothing landed"
  HD=$(for f in $HASHF; do [ -f "$X/files/$f" ] && printf '%s,' "$f"; done)
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
    # a restore that failed keeps the backup where it is, the EXIT trap disarmed, and says so with the base
    [ -z "$BF" ] || { trap - EXIT; die "$1 after the dry run passed, and the roll-back could not restore$BF: their backup is kept in $T (bk-*), and nothing is reset — the base is $(printf %.12s "$B")"; }   # kept in place, never copied
    git reset -q --soft "$B"; for f in $SPEC; do git reset -q "$B" -- "$f" 2>/dev/null; if git cat-file -e "$B:$f" 2>/dev/null; then git checkout -q "$B" -- "$f"; else rm -f "$f"; fi; done
    die "$1 after the dry run passed: rolled back to $(printf %.12s "$B"), nothing landed"; }
  records "$PWD" "$L" "$XA" > "$T/rec" || back 'the records failed'
  commits "$XA" > "$T/shas2" || back 'a commit was refused' 
  LR=$(tail -n 1 "$T/shas2"); L2=$(printf %.12s "$LR")
  if [ "$L2" != "$L" ]; then for f in "$D/landed" "$HAND" $(ls "$D"/close/*/*/withdrawn 2>/dev/null); do sed "s/ $L / $L2 /; s/^$L /$L2 /" "$f" > "$T/f" || back 'a record could not be rewritten'; put "$f" < "$T/f" || back 'a record could not be rewritten'; done; sed "s/	landed at $L	/	landed at $L2	/" "$D/rulings" > "$T/f" || back 'a record could not be rewritten'; put "$D/rulings" < "$T/f" || back 'a record could not be rewritten'; L=$L2; fi
  plan_change "$XA" "$LR" || back "the plan change was refused ($(grep -m 1 refused "$T/pc" || tail -n 1 "$T/pc"))"
  sh "$HERE/planner.sh" reratify --words "$WORDS" --base "$B" --to "$LR" --held "${HD%,}" > "$T/rr" 2>&1 || back "reratify refused ($(tail -n 1 "$T/rr"))"
  ev "publish-approved words=\"$WORDS\""   # the owner's go in the same words, so the writer's gate opens; through event.sh (9.3 R1)
  echo "$LR" > "$X/landed"; ev "land-landed draft=$n at=$L"
  # 4. last, each withdrawn ask's issue closed on GitHub, with a comment naming the landing
  while read -r s k i; do [ -n "$i" ] || continue; printf 'vid: withdrawn. The landing %s changed rows of %s; this close is asked again once its new tickets merge. A later report for it is not read.\n' "$L" "$s" > "$T/wc"
    sh "$HERE/github.sh" comment "$i" --body-file "$T/wc" > /dev/null 2>&1 && sh "$HERE/github.sh" close "$i" > /dev/null 2>&1 && echo "issue $i" >> "$D/close/$s/$k/withdrawn" || echo "ask-open $s $i"; done < "$T/wd"
  cat "$T/rec"; echo "landed $n at $L: $(sed -n 1p "$X/count")"; }

CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in
  draft) cmd_draft "$@" ;;
  count) X=$DR/${1:-}; [ -f "$X/base" ] || die "no draft ${1:-}"; count "$X"; cat "$X/count" ;;
  [0-9]*) cmd_land "$CMD" "$@" ;;
  *) echo 'usage: sh checks/land.sh draft --review <file> [--why "<…>"] [--plan <file>] [--for <keys>] [--replaces <n>] | count <n> | <n> --words "<the owner'"'"'s yes>"' >&2; exit 2 ;;
esac

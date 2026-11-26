#!/bin/sh
# Purpose: close.sh's part — the one reader of an ask, for the step close and a stage's C3, CS, CR and CP (FB-2 C3). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
akey() { sed -n "s/^$1$TAB//p" "$K/ask" | head -n 1; }
# drop <key> <file>: the file's lines keyed <key> (its first tab field) removed (0.26.10.29.1, R2)
drop() { [ -f "$2" ] || return 0; awk -F'\t' -v c="$1" '$1 != c' "$2" > .vid/round/dr && put "$2" < .vid/round/dr; }
item() { grep -qxF "$1" "$K/items" 2>/dev/null || { echo "$1" >> "$K/items"; ev "close-item step=$s what=$(printf %s "$1" | cut -d' ' -f1-2 | tr ' ' '-')"; }; }
# a red row's one line in the handed record, its mark kept
hfail() { m=$(sed -n "s/^row $1 [^ ]* \(fault-proven\).*/\1/p" "$HAND" | tail -n 1); { grep -v "^row $1 " "$HAND" || true; printf 'row %s failing%s | stand-in: %s #%s\n' "$1" "${m:+ $m}" "${HL:-close}" "$n"; } > .vid/round/h || exit 1; put "$HAND" < .vid/round/h || exit 1; }
# PB-5: a stage's staging run whose tests cannot run there, GitHub auto. cnl <row>: the row's could-not-run fix line of this stage, its
# stand-in apart: the handed fix line whose words for it begin `could not run there:` and whose label is `CS #<n> of stage <N>:`, matched
# whole. cnst <row>: none, unpublished, open <n>, merged <n> (held by the run's commit), after <n> (merged, not in it), withdrawn <n> (by a
# plan change, or an amendment that took the row out)
cnl() { awk -v r="$1" -v L="^CS #[0-9]+ of stage $STG:" '/^fix / { l = $0; sub(/[ \t]*[|][ \t]*stand-in.*$/, "", l); n = split(l, p, /[ \t]*[|][ \t]*/); if (n < 3 || !index(" " p[1] " ", " " r " ") || p[3] !~ L) next
    m = split(p[2], q, "; "); for (i = 1; i <= m; i++) if (index(q[i], r ": could not run there: ") == 1) c = l } END { if (c != "") print c }' "$HAND" 2>/dev/null; }
cnst() { _l=$(cnl "$1"); [ -n "$_l" ] || { echo none; return 0; }; _t=$(fixt "$(printf '%s' "$_l" | cksum | cut -d' ' -f1)"); [ -n "$_t" ] || { echo unpublished; return 0; }
  if gone "$_t" || ! awk -v n="$_t" -v r="$1" '($1 == "published" || $1 == "amended") && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) w = substr($i, 6) } END { exit !index("," w ",", "," r ",") }' "$LOG"; then echo "withdrawn $_t"; return 0; fi
  _m=$(mrg "$_t" | cut -d' ' -f2); if [ -z "$_m" ]; then echo "open $_t"; elif anc "$_m" "$(akey commit)"; then echo "merged $_t"; else echo "after $_t"; fi; }
# unrun <chunk> <attempt> <its unfinished rows>: at the second loss, R the rows that could not run in this attempt and the one before; every
# unfinished row in R and none the owner's: the fix line written (or kept), the chunk in waits-fix, `close-unrun`; else exit 1, UW the
# words for the owner, row by row, when a row of R has a fix
unrun() { UW=''; { [ -n "$CSM" ] && [ "${CK:-cs}" = cs ] && ! manual; } || return 1
  R=$(awk -v c="$1" -v a="$2" '$1 == c && $2 == a { u = $4 } $1 == c && $2 != a { p = $4 } END { n = split(u, x, ","); m = split(p, y, ","); for (j = 1; j <= m; j++) P[y[j]] = 1; for (i = 1; i <= n; i++) if (x[i] in P) print x[i] }' "$K/lostsig" | sort -u)
  R=$(for x in $R; do limited "$x" || echo "$x"; done)
  [ -n "$R" ] && for x in $3; do printf '%s\n' "$R" | grep -qxF "$x" || return 1; done || return 1
  awk -F'\t' -v c="$1" -v SF="$D/state" "$LIMB"'$1 == "row" && $2 == c && !($4 in L) && $5 != "passed" && $5 != "failed" && $5 != "could not run" { f = 1 } END { exit f }' "$K/read" || return 1   # every engine's: none not run
  hrows "$s" "$(akey commit)" > .vid/round/ow0; o=''; nw=''; tk=''; for r in $R; do st=$(cnst "$r"); w=$(sed -n "s/^row $r \([^ |]*\).*/\1/p" "$HAND" | tail -n 1)
    case $st in none) UW="$UW; $r: no fix yet"; nw="$nw $r" ;; merged*) UW="$UW; $r still cannot run after its fix #${st#* }"; o=1 ;; withdrawn*) UW="$UW; $r: its fix ticket #${st#* } was withdrawn"; o=1 ;; after*) UW="$UW; $r: its fix #${st#* } merged after this build was named"; tk=${tk:-${st#* }} ;; unpublished) UW="$UW; $r: its fix line is not published yet" ;; *) UW="$UW; $r: its fix #${st#* } is open"; tk=${tk:-${st#* }} ;; esac
    { awk -F'\t' -v r="$r" '$3 == r { f = 1 } END { exit !f }' "$K/failed" || [ "$w" = failing ] || [ "$w" = held ] || { grep -qxF "$r" .vid/round/ow0 && case $st in open*|after*) false ;; *) true ;; esac; }; } && o=1; done
  [ -z "$o" ] || { printf '%s' "$UW" | grep -q 'fix #\|fix line\|fix ticket' || UW=''; UW=${UW#; }; return 1; }
  if [ -n "$nw" ]; then wh=''; for r in $nw; do wh="$wh${wh:+; }$r: could not run there: its test in $(awk -F'\t' -v r="$r" '$1 == "row" && $4 == r && $5 == "could not run" && !s[$3]++ { printf "%s%s", (c++ ? ", " : ""), $3 }' "$K/read")"; done
    lk=$(awk -F'\t' -v R=" $nw " -v n="$n" 'FILENAME == ARGV[1] { split($0, x, "|"); at[x[1]] = x[3]; next } $1 == "row" && $5 == "could not run" && index(R, " " $4 " ") && !s[$2]++ { printf "%sreq-%s-%s-%s", (c++ ? ", " : ""), n, $2, at[$2] }' "$K/chunks" "$K/read")
    echo "fix$nw | $wh | $LB: $lk | stand-in: RM" >> "$HAND"; ev "close-unrun-fix step=$s issue=$n rows=$(echo $nw | tr ' ' ,)"; fi
  awk -v c="$1" '!($1 == "lost" && $2 == c)' "$K/items" > .vid/round/ui && put "$K/items" < .vid/round/ui || exit 1   # an earlier loss of the chunk, its question, goes with it
  printf '%s\t%s\n' "$1" "$(echo $R)" >> "$K/waits-fix"; ev "close-unrun step=$s chunk=$1"; echo "close-unrun $s $1 $(echo $R) #${tk:-unpublished}"; }
# R4: each row of the ask green or red; after the first ask, against the step's last close
numbers() { awk -F'\t' -v SF="$D/state" "$LIMB"' $1 == "row" && !($4 in L) { if ($5 == "failed") r[$4] = "red"; else if (r[$4] != "red") r[$4] = ($5 == "passed" && r[$4] != "-") ? "green" : "-" } END { for (y in r) if (r[y] != "-") print y "\t" r[y] }' "$K/read" | sort > "$SX/nr" || exit 1; put "$K/result" < "$SX/nr" || exit 1
  p=$(for P in $(prior); do [ -f "$P/result" ] && echo "$P"; done | tail -n 1); [ -n "$p" ] || return 0
  awk -F'\t' 'NR == FNR { b[$1] = $2; next } { if ($2 == "red" && b[$1] == "green") g++; else if ($2 == "red" && b[$1] == "red") o++; else if ($2 == "green" && b[$1] == "red") f++ } END { printf "regressions introduced %d · defects still open %d · fixed %d\n", g, o, f }' "$p/result" "$K/result" > "$SX/nn" || exit 1; put "$K/numbers" < "$SX/nn" || exit 1
  echo "close-numbers $s $k $(cat "$K/numbers")"; ev "close-numbers step=$s ask=$k $(tr -d '·' < "$K/numbers" | awk '{ print "regressions=" $3, "open=" $7, "fixed=" $9 }')"; }   # fields: regressions= open= fixed=
# FB-7 A1: heldrow: the row that holds the build of this full run or staging run (bheld), else exit 1. heldsay: such a run is not read as
# passed, what it paid apart: `close-held <run> <row>`, said once a row
heldrow() { [ -n "$STG" ] && { [ -z "$CSM" ] || [ "${CK:-cs}" = cs ]; } || return 1; _hf=$K; [ -z "$CSM" ] || _hf=$SD/$STG/$CSM; bheld "$STG" "$_hf"; }
heldsay() { [ -n "$HR" ] || return 1; _hr=$HR
  [ -z "$CSM" ] || cs_paid; grep -qxF "$_hr" "$K/held" 2>/dev/null || { echo "$_hr" >> "$K/held"; echo "close-held $s $_hr"; }; return 0; }
cmd_decide() { s=$1; KD=$C/$s; k=$(nk "$s"); [ -n "$k" ] || die "no close is out for $s"; closed "$s" && return 0; STG=''; HL=''; LB=''; EVS=''; CSM=''; RA="--step $s"; decide_k; }
# prior: the folders of the earlier asks, oldest first: a step's or C3's by number; CS's (v0.26.10.26.2) the stage's earlier candidates' cs
prior() { if [ -n "$CSM" ]; then for j in $(ls "$SD/$STG" | grep -E '^[0-9]+$' | sort -n); do [ "$j" -lt "$CSM" ] && [ -f "$SD/$STG/$j/${CK:-cs}/ask" ] && echo "$SD/$STG/$j/${CK:-cs}"; done
  else for j in $(ls "$KD" | grep -E '^[0-9]+$' | sort -n); do [ "$j" -lt "$k" ] && echo "$KD/$j"; done; fi; return 0; }
# decide_k: the newest ask k of the folder KD, as a step close (STG empty) or a stage's C3 (STG its number)
decide_k() { K=$KD/$k; [ ! -f "$K/withdrawn" ] || return 0; n=$(akey issue); touch "$K/again" "$K/items" "$K/acted" "$K/lined" "$K/fixes"; : > "$SX/fo"
  prog now "reading the run report of $([ -z "$STG" ] && echo "step $s's close" || echo "stage $STG")"   # FB-3 D2
  sh "$HERE/results.sh" close $RA > /dev/null 2> .vid/round/ce || die "the close could not be read: $(tail -n 1 .vid/round/ce)"
  # a known limit leaves the close; a chunk's state is that of its other rows: a row not run makes it incomplete, red or not
  awk -F'\t' -v SF="$D/state" -v FO="$SX/fo" "$LIMB"'
    $1 == "chunk" { st[$2] = $3; at[$2] = $4; o[++n] = $2; next } $1 == "row" && !($4 in L) { if ($5 == "failed") { f[$2] = f[$2] " " $3 ":" $4; print $2 "\t" $3 "\t" $4 "\t" $6 > FO } else if ($5 != "passed") x[$2] = x[$2] " " $4 }
    $1 == "row" && ($4 in L) { lim[$2] = 1 } $1 == "row" && !($4 in L) { own[$2] = 1 }
    END { for (i = 1; i <= n; i++) { c = o[i]; s = (st[c] == "absent") ? ((lim[c] && !own[c]) ? "green" : "absent") : (x[c] != "") ? "incomplete" : (f[c] != "") ? "red" : "green"; print c "|" s "|" at[c] "|" f[c] "|" x[c] } }' "$K/read" > "$SX/ch" || exit 1; put "$K/chunks" < "$SX/ch" || exit 1; put "$K/failed" < "$SX/fo" || exit 1
  HR=$(heldrow) || HR=''   # FB-7 A1: held, no question of the run goes, its rows landed or not
  [ -n "$HR" ] || awk -F'|' 'NR == FNR { if ($2 == "green" || $2 == "red") R[$1] = 1; next } { split($0, w, " ") } !(w[1] == "lost" && (w[2] in R))' "$K/chunks" "$K/items" > .vid/round/it || exit 1; [ -n "$HR" ] || put "$K/items" < .vid/round/it || exit 1   # a late report ends its chunk's loss
  if [ -s "$K/chunks" ] && ! awk -F'|' '$2 != "green" { exit 1 }' "$K/chunks"; then :; elif [ -s "$K/chunks" ] && heldsay; then return 0; elif [ -s "$K/chunks" ] && [ -n "$CSM" ]; then numbers; cs_green; return 0; elif [ -s "$K/chunks" ] && [ -n "$STG" ]; then numbers; stage_green; return 0; elif [ -s "$K/chunks" ]; then numbers
    c=$(akey commit); echo "closed $s | stand-in: close #$n at $(printf %.12s "$c")" >> "$HAND"; ev "close-closed step=$s issue=$n commit=$c"
    gh_ close "$n" > /dev/null 2>&1 || true; echo "closed $s"; tclose "$s" "$c"; return 0; fi
  # splits, from the close
  awk -F'\t' '$1 == "split" { print $2 "\t" $3 }' "$K/read" | while IFS=$TAB read -r r e; do ! limited "$r" || continue; grep -q "^engine-split $r " "$HAND" 2>/dev/null || { echo "engine-split $r | stand-in: $e" >> "$HAND"; ev "engine-split row=$r from=close step=$s"; echo "split $r"; }; done
  W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { print $5 }' .vid/round/read 2>/dev/null); q=$(( $(date +%s) - $(epoch "${u:-$(stamp)}") ))
  # v0.26.10.28.2 (R2): said <chunk>: DevAgent's `vid: lost <chunk> <k>` on the issue, k the current generation (the issue's count of `vid: again <chunk>`), newer than
  # the chunk's newest `vid: reported`: the chunk lost now, asked again or made the owner's at once, with no quiet time; an older generation's changes nothing
  said() { awk -F'\t' -v n="$n" -v c="$1" '$1 == "issue" && $2 == n { m = split($4, h, "\001"); for (i = 1; i <= m; i++) { if (h[i] == "vid: again " c) A++; else if (h[i] ~ ("^vid: reported " c "-[0-9]+$")) r = i
      else if (h[i] ~ ("^vid: lost " c " [0-9]+$")) { split(h[i], w, " "); k[i] = w[4] } } for (i in k) if (i + 0 > r && k[i] == A + 0) f = 1 } END { exit !f }' .vid/round/read 2>/dev/null; }
  # 0.26.10.28.10 (R2): lsig <chunk>, the chunk's rows that could not run, by engine and state, messages apart; each attempt's in lostsig
  # (`<chunk> <attempt> <sig>`); lost with the sig of the attempt before, the chunk is `same` (queue.sh refuses a bare again);
  # an again's words, againwhy (`<chunk> TAB <words>`), go out with it as `why:`
  lsig() { awk -F'\t' -v c="$1" -v SF="$D/state" "$LIMB"'$1 == "row" && $2 == c && $5 != "passed" && $5 != "failed" && !($4 in L) { print $3 ":" $4 ":" $5 }' "$K/read" | sort | cksum | tr -d ' '; }
  # PB-5: a chunk read green or red no longer waits on its fix; one that waits asks nothing, unless every fix of its rows is gone
  if [ -s "$K/waits-fix" ]; then awk -F'|' 'NR == FNR { if ($2 == "incomplete" || $2 == "absent") I[$1] = 1; next } { split($0, x, "\t") } (x[1] in I)' "$K/chunks" "$K/waits-fix" > .vid/round/wf && put "$K/waits-fix" < .vid/round/wf || exit 1; fi
  while IFS='|' read -r ch st a fr xr; do case $st in
      red) item "red $ch$fr"; echo "close-red $s $ch$fr" ;;
      incomplete|absent) if grep -q "^$ch$TAB" "$K/waits-fix" 2>/dev/null; then gw=''; for r in $(sed -n "s/^$ch$TAB//p" "$K/waits-fix"); do st=$(cnst "$r")
            case $st in none) awk -v r="$r" '/^fix / { split($0, p, /[ \t]*[|][ \t]*/); if (index(" " p[1] " ", " " r " ")) f = 1 } END { exit !f }' "$HAND" || gw="$gw; its fix line was cut" ;; withdrawn*) gw="$gw; its fix ticket #${st#* } was withdrawn" ;; *) gw=''; break ;; esac; done
          [ -n "$gw" ] || continue; drop "$ch" "$K/waits-fix" || exit 1; item "lost $ch$xr · ${gw#; } #$(grep -c "^$ch " "$K/again")"; echo "$ch ${a:--} #$(grep -c "^$ch " "$K/again")" >> "$K/lostat"; echo "close-lost $s $ch"; continue; fi   # PB-5 §2.7: gone, the owner's
        LS=''; ! said "$ch" || LS=1; [ "$st" = incomplete ] || [ "$q" -ge "$W" ] || [ -n "$LS" ] || grep -qxF "allow $ch" "$K/again" || continue; g=$(awk -v c="$ch" '$1 == c { print $2 }' "$K/again" | tail -n 1)
        sg=''; [ "$st" != incomplete ] || [ "${a:--}" = - ] || grep -q "^$ch $a " "$K/lostsig" 2>/dev/null || { sg=$(lsig "$ch"); echo "$ch $a $sg $(awk -F'\t' -v c="$ch" -v SF="$D/state" "$LIMB"'$1 == "row" && $2 == c && $5 == "could not run" && !($4 in L) { printf "%s%s", (n++ ? "," : ""), $4 } END { if (!n) printf "-" }' "$K/read")" >> "$K/lostsig"; }   # an attempt's first reading, from a report, never a refused or missing one; PB-5: its rows that could not run
        if [ -z "$g" ] || grep -qxF "allow $ch" "$K/again"; then wy=$(awk -F'\t' -v c="$ch" '$1 == c { w = $2 } END { print w }' "$K/againwhy" 2>/dev/null)
          { printf 'vid: again %s\nby: RM\n' "$ch"; [ -z "$wy" ] || printf 'why: %s\n' "$wy"; } > .vid/round/again; gh_ comment "$n" --body-file .vid/round/again > /dev/null 2>&1 || die "the ask #$n could not be commented"
          grep -vxF "allow $ch" "$K/again" > .vid/round/ag; put "$K/again" < .vid/round/ag || exit 1; drop "$ch" "$K/againwhy" || exit 1; drop "$ch" "$K/same" || exit 1
          echo "$ch ${a:--}" >> "$K/again"; ev "close-again step=$s chunk=$ch"; echo "close-again $s $ch"
        elif [ "$a" != "$g" ] || [ "$q" -ge "$W" ] || [ -n "$LS" ]; then
          pv=$(awk -v c="$ch" -v a="${a:--}" '$1 == c && $2 != a { p = $3 } END { print p }' "$K/lostsig" 2>/dev/null)   # the attempt before's sig
          [ -z "$sg" ] || [ -z "$pv" ] || [ "$pv" != "$sg" ] || grep -qxF "$ch" "$K/same" 2>/dev/null || echo "$ch" >> "$K/same"
          la="$ch ${a:--} #$(grep -c "^$ch " "$K/again")"; if grep -qxF "$la" "$K/lostat" 2>/dev/null; then echo "close-lost $s $ch"; continue; fi   # PB-5: the owner's at this attempt, once
          ! unrun "$ch" "${a:--}" "$xr" || continue   # PB-5 §2.2: ViD's fix, no question
          item "lost $ch$xr${UW:+ · $UW} #$(grep -c "^$ch " "$K/again")"; [ -z "$CSM" ] || echo "$la" >> "$K/lostat"; echo "close-lost $s $ch"; fi ;;
    esac; done < "$K/chunks"
  # R1: once no chunk waits on a report, each green, red, or lost to the owner
  awk -F'|' -v IT="$K/items" -v WF="$K/waits-fix" 'BEGIN { while ((getline l < IT) > 0) { split(l, x, " "); if (x[1] == "lost") G[x[2]] = 1 } while ((getline l < WF) > 0) { split(l, x, "\t"); G[x[1]] = 1 } } ($2 == "incomplete" || $2 == "absent") && !($1 in G) { f = 1 } END { exit f }' "$K/chunks" || return 0
  [ -z "$CSM" ] || [ "${CK:-cs}" = cp ] || cs_paid   # v0.26.10.26.2 (R5): CS's passed deploy-owed rows paid, red ones failing below; CP's only when green (v0.26.10.27.1)
  # its red rows, each once: failing, with one count; a row red at an earlier ask of the step is the owner's, unless the owner allowed another
  # fix; the others in one fix line, in words the writer's check passes, the failures' messages staying in the reports the line links
  awk -F'\t' 'function wd(n,   k, i, o, a) { sub(/.*::/, "", n); sub(/.*\//, "", n); sub(/^test_/, "", n); gsub(/_/, " ", n); gsub(/[^A-Za-z0-9 -]/, " ", n); k = split(n, a, " "); o = ""
      for (i = 1; i <= k; i++) { sub(/^-+/, "", a[i]); if (a[i] == "") continue; if (a[i] ~ /^[A-Z]+$/ && a[i + 1] ~ /^[0-9]+$/) { a[i + 1] = a[i] "-" a[i + 1]; continue } o = o (o == "" ? "" : " ") a[i] } return o == "" ? "its test" : o }
    { if (!($3 in w)) o[++m] = $3; w[$3] = w[$3] (w[$3] == "" ? "" : ", ") wd($4) " in " $2; c[$3] = c[$3] " " $1 } END { for (i = 1; i <= m; i++) print o[i] "\t" w[o[i]] "\t" c[o[i]] }' "$K/failed" > .vid/round/red
  new=''; why=''; lk=''; touch "$K/waits"; if [ -z "$CSM" ] || [ "${CK:-cs}" = cs ]; then hrows "$s" "$(akey commit)"; else cmd_owned "$s"; fi > .vid/round/ow   # FB-7 A2: held at the run's commit; the rehearsal and production runs as before
  # 0.26.10.29.2 (R7): a close asked again after the fix tickets of the close before it merged must shrink its red set, over the rows that
  # close's ask covered (its own, its dependencies' and its regression rows) less those landed since it was asked (close-twice's test):
  # its red rows now a strict subset of its red rows then. Else no fix line, and one item for the owner naming both, holding the close as
  # a twice item does; the owner's again (`allow shrink`) writes the fix line, limit rules the rows known limits. A step's close and a
  # stage's C3, never a CS, CR or CP; a withdrawn close before it is not compared. It is judged at every decide over the close's whole
  # red set as it stands, however its chunks arrive: a chunk that reports late, after rows of the set had their fix line, can still
  # make the set not shrink, and then no further row gets one
  SHR=''; P=$(prior | tail -n 1)
  if [ -z "$CSM" ] && [ -n "$P" ] && [ ! -f "$P/withdrawn" ] && [ -s "$P/fixes" ] && [ -s "$P/failed" ] && [ -f "$P/rows" ] && ! grep -qxF 'allow shrink' "$K/again"; then
    pa=$(sed -n "s/^asked$TAB//p" "$P/ask" | head -n 1)
    awk -v a="$pa" -v LF="$D/landed" 'BEGIN { while ((getline l < LF) > 0) { split(l, x, " "); if (x[3] > L[x[1]]) L[x[1]] = x[3] } } { r = $1 } !(r in L) || a > L[r] { print r }' "$P/rows" | sort -u > "$SX/su0"
    cut -f1 "$K/acted" | sort -u > "$SX/aa"; grep -vxF -f "$SX/aa" .vid/round/ow | sort -u > "$SX/ho"; comm -23 "$SX/su0" "$SX/ho" > "$SX/su"   # FB-7 A2: a held row is in neither set, the ones this close acted on apart
    cut -f3 "$P/failed" | sort -u | comm -12 - "$SX/su" > "$SX/sp"; cut -f1 .vid/round/red | sort -u | comm -12 - "$SX/su" > "$SX/sk"
    # the same set, every row of it acted on then, is close-twice's alone: each row is its item already
    cut -f1 "$P/acted" 2>/dev/null | sort -u > "$SX/sa"
    if [ -s "$SX/sk" ] && { [ -n "$(comm -23 "$SX/sk" "$SX/sp")" ] || { cmp -s "$SX/sk" "$SX/sp" && [ -n "$(comm -23 "$SX/sk" "$SX/sa")" ]; }; }; then SHR=1
      # one open shrink item a close, `shrink <P>@<rows now,> <rows now> · before: <rows then>`: keyed by its rows, so a set that grew
      # since, or a new one after an answered one, is a new question to the owner; a grown open one replaces the old
      sl="shrink $(basename "$P")@$(paste -sd ',' "$SX/sk") $(paste -sd ' ' "$SX/sk") · before: $(paste -sd ' ' "$SX/sp")"
      grep -qxF "$sl" "$K/items" 2>/dev/null || { grep -v "^shrink $(basename "$P")@" "$K/items" > "$SX/si" 2>/dev/null || true; put "$K/items" < "$SX/si" || exit 1; }; item "$sl"; echo "close-shrink $s $(paste -sd ' ' "$SX/sk")"; fi; fi
  # PB-5 §2.4: a red row's unpublished could-not-run fix line is cut, and the red path writes its fix
  if [ -n "$CSM" ] && [ "${CK:-cs}" = cs ] && ! manual; then cut -f1 .vid/round/red | while read -r r; do [ "$(cnst "$r")" = unpublished ] || continue; l=$(cnl "$r")
    awk -v l="$l" -v r="$r" '{ x = $0; sub(/[ \t]*[|][ \t]*stand-in.*$/, "", x) } x != l { print; next } { n = split(x, p, /[ \t]*[|][ \t]*/); m = split(p[1], w, " "); o = "fix"; for (i = 2; i <= m; i++) if (w[i] != r) o = o " " w[i]; if (o == "fix") next
      k = split(p[2], q, "; "); y = ""; for (i = 1; i <= k; i++) if (index(q[i], r ": ") != 1) y = y (y == "" ? "" : "; ") q[i]; o = o " | " y; for (i = 3; i <= n; i++) o = o " | " p[i]; print o " | stand-in: RM" }' "$HAND" > .vid/round/hc && put "$HAND" < .vid/round/hc || exit 1; ev "close-unrun-cut step=$s row=$r"; done || exit 1; fi   # its row alone: the others keep their fix
  while IFS=$TAB read -r r w cs; do
    if ! grep -q "^$r$TAB" "$K/acted" && grep -qxF "$r" .vid/round/ow; then grep -qxF "$r" "$K/waits" || { echo "$r" >> "$K/waits"; echo "close-waits $s $r"; }; continue; fi   # another close's fix, or another ticket, holds it
    if ! grep -q "^$r$TAB" "$K/acted"; then printf '%s\t%s\n' "$r" "$w" >> "$K/acted"; hfail "$r"; grep -qxF "$r close#$n" "$D/counts" 2>/dev/null || echo "$r close#$n" >> "$D/counts"; ev "close-failing step=$s row=$r issue=$n"; echo "failing $r"; fi
    [ -z "$SHR" ] || continue   # R7: the owner's first
    grep -qxF "$r" "$K/lined" && continue
    lt=$(awk -v r="$r" '$1 == r { t = $3 } END { print t }' "$D/landed" 2>/dev/null)   # R4: a close asked before the row's landing is no earlier close
    b=$(for P in $(prior); do [ -z "$lt" ] || awk -v a="$(sed -n "s/^asked$TAB//p" "$P/ask" 2>/dev/null)" -v b="$lt" 'BEGIN { exit !(a > b) }' || continue; sed -n "s/^$r$TAB//p" "$P/acted" 2>/dev/null; done | tail -n 1)
    if [ -n "$b" ] && ! grep -qxF "allow $r" "$K/again" && ! grep -qxF 'allow shrink' "$K/again"; then item "twice $r now: $w · before: $b"; echo "close-twice $s $r"; continue; fi
    echo "$r" >> "$K/lined"; new="$new $r"; why="$why${why:+; }$r: $w"; for c in $cs; do lk="$lk req-$n-$c-$(awk -F'|' -v c="$c" '$1 == c { print $3 }' "$K/chunks")"; done
  done < .vid/round/red
  if [ -n "$new" ]; then lk=$(printf '%s\n' $lk | awk '!s[$0]++' | paste -sd ',' - | sed 's/,/, /g'); l="fix$new | $why | ${LB:-close #$n of $s}: $lk"; f=$(printf '%s' "$l" | cksum | cut -d' ' -f1)
    echo "$l | stand-in: RM" >> "$HAND"; printf '%s\t%s\n' "$f" "${new# }" >> "$K/fixes"; ev "close-fix step=$s issue=$n rows=$(echo $new | tr ' ' ,)"; echo "close-fix $s$new"
    [ -z "$STG" ] || { psteps; EVS=$(awk -F'\t' -v r="$(echo $new | cut -d' ' -f1)" '$2 == r { print $1; exit }' "$SX/ps"); }   # C3's fix: the step of its first red row
    sh "$HERE/plan.sh" change other "a red close of $s:$new" --trigger test-evidence --evidence "step:${EVS:-$s}" --expect 'a fix ticket, then the close again' > .vid/round/pc 2>&1 || echo "plan-refused $s: $(tail -n 1 .vid/round/pc)"; fi
  # the ask's issue closed once nothing waits under it; the numbers; FB-7 D3: but a staging run's, open while its run can still pass at this build
  [ -f "$K/done" ] || [ -s "$K/waits-fix" ] || grep '^lost ' "$K/items" | grep -qv '^lost s1 ' || { numbers; { [ -n "$CSM" ] && [ "${CK:-cs}" = cs ]; } || gh_ close "$n" > /dev/null 2>&1 || true; : > "$K/done"; ev "close-done step=$s issue=$n"; echo "close-done $s"; }; return 0; }

#!/bin/sh
# Purpose: close.sh's part — the step close: the published tickets of a step, what is owed and out, the reclose and the ask (FB-2 C3). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
# the published tickets of a step and kind, withdrawn ones apart: `<n> <kind>`
tix() { awk -v s="step=$1" '$1 == "published" { k = ""; f = 0; for (i = 3; i <= NF; i++) { if ($i == s) f = 1; if ($i ~ /^kind=/) k = substr($i, 6) } if (f) K[$2] = k } $1 == "withdrawn" { delete K[$2] } END { for (n in K) print n, K[n] }' "$LOG" 2>/dev/null; }
# the merge of a ticket, `<pr> <merge commit>`, from the merges kept and the round's read
mrg() { { cat "$D/merges" 2>/dev/null; awk -F'\t' '$1 == "merged" { print $2 "\t" $3 "\t" $4 "\t" $5 }' "$RD" 2>/dev/null; } | awk -F'\t' -v t="$1" -v M="$D/merged-prs" 'BEGIN { while ((getline l < M) > 0) m[l] = 1 } $2 == t && ($1 in m) && $4 != "-" { print $1, $4; exit }'; }
closed() { grep -q "^closed $1 " "$HAND" 2>/dev/null; }
steps() { awk '$1 == "published" { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) print substr($i, 6) }' "$LOG" 2>/dev/null | sort -u; }
# R3: a step's asks by number, each with its ask file, the newest k; a step's records of 0.26.10.25.3 move to ask 1
nk() { k0=''; for d in $(ls "$C/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$C/$1/$d/ask" ] && k0=$d; done; echo "$k0"; }
mig() { [ -f "$C/$1/ask" ] || return 0; mkdir -p "$C/$1/1"; for f in "$C/$1"/*; do [ -f "$f" ] && mv "$f" "$C/$1/1/"; done; return 0; }
for d in "$C"/*; do [ -d "$d" ] && mig "$(basename "$d")"; done
# a known limit leaves the close, and a journey whose every transition is one
LIMB='BEGIN { while ((getline l < SF) > 0) { split(l, x, "\t"); b = x[1]; sub(/-T[0-9]+$/, "", b); if (b != x[1]) { nt[b]++; if (x[2] == "known limit") lt[b]++ } if (x[2] == "known limit") L[x[1]] = 1 } for (b in nt) if (lt[b] == nt[b]) L[b] = 1 }'
limited() { awk -F'\t' -v r="$1" '$1 == r && $2 == "known limit" { f = 1 } index($1, r "-T") == 1 { n++; if ($2 == "known limit") k++ } END { exit !(f || (n && n == k)) }' "$D/state" 2>/dev/null; }   # a journey, by its transitions too
# a fix line's ticket, by the line's key in the log; live: a row of the line that is no known limit
fixt() { awk -v k="fix=$1" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == k) n = $2 } END { print n }' "$LOG" 2>/dev/null; }
live() { for r in $1; do limited "$r" || { echo y; return 0; }; done; }
# owed again (R3): the newest ask done, with a fix line, each line's ticket merged or every row of it a known limit, nothing for the owner
# a row another step's close owned waits for that fix, then the close is owed again too
again1() { againK "$C/$1/$2"; }
# GM-4 K3: WHY, what holds it, for `step`'s refusal
againK() { K=$1; WHY="its close ask ${K##*/} has ended with no fix line to wait on"; [ -f "$K/done" ] || WHY="its close ask ${K##*/} is out"
  [ -f "$K/done" ] && { [ -s "$K/fixes" ] || [ -s "$K/waits" ]; } || return 1; WHY="its close ask ${K##*/} waits on the owner's answer"; ! grep -qE '^(twice|lost|shrink) ' "$K/items" 2>/dev/null || return 1   # 0.26.10.29.2 (R7): a shrink item holds it too
  WHY="a row its close ask ${K##*/} found red waits on another close's fix, not yet merged"; [ ! -s "$K/waits" ] || ! cmd_owned | grep -qxF -f "$K/waits" || return 1
  # 0.26.10.29.2 (R11): a fix line whose ticket a plan change withdrew (every row of it moved out of its step, so the step
  # that now holds them carries them and its own close covers them) is waited on no longer; a closed-outside one is written again (R4)
  while IFS=$TAB read -r f rs; do [ -n "$(live "$rs")" ] || continue; t=$(fixt "$f"); [ -z "$t" ] || ! awk -v t="$t" '$1 == "withdrawn" && $2 == t && $3 != "decision=closed-outside" { f = 1 } END { exit !f }' "$LOG" 2>/dev/null || continue
    WHY="its fix ${t:+#$t }has no merge on record"; [ -z "$t" ] && WHY='its fix line has no ticket yet'; [ -n "$t" ] && [ -n "$(mrg "$t")" ] || return 1; done < "$K/fixes"; WHY=''; return 0; }
# v0.26.10.26.7 (R9, W-11): rrows <step>, the rows its tickets hold and those its newest ask recorded as reached (land.sh);
# rtix <file>, the published tickets, never withdrawn, whose reached rows (a reached-rows ticket: its rows) meet the file's;
# rwait <step>, one of those tickets not yet merged; rpend <step>, a reached row no ticket holds yet meets its rows or is its own
rrows() { awk -v s="step=$1" '$1 == "published" { f = 0; r = ""; for (i = 3; i <= NF; i++) { if ($i == s) f = 1; if ($i ~ /^rows=/) r = substr($i, 6) } if (f) print r }' "$LOG" 2>/dev/null | tr , '\n' | grep -v '^-*$' || true
  k0=$(nk "$1"); [ -z "$k0" ] || cat "$C/$1/$k0/reached" 2>/dev/null || true; }
rtix() { awk -v RF="$1" -v RR="${2:-/dev/null}" 'BEGIN { while ((getline l < RF) > 0) W[l] = 1; while ((getline l < RR) > 0) H[l] = 1 } $1 == "published" || $1 == "amended" { k = ""; r = ""; x = ""
    for (i = 3; i <= NF; i++) { if ($i ~ /^kind=/) k = substr($i, 6); if ($i ~ /^rows=/) r = substr($i, 6); if ($i ~ /^reached=/) x = substr($i, 9) } if (k == "reached") x = x "," r
    n = split(r, a, ","); for (j = 1; j <= n; j++) if (a[j] in H) T[$2] = 1   # a recorded reached row any ticket holds, an open one not yet amended too
    n = split(x, a, ","); for (j = 1; j <= n; j++) if (a[j] in W) T[$2] = 1 } $1 == "withdrawn" { delete T[$2] } END { for (t in T) print t }' "$LOG" 2>/dev/null; }
rwait() { rrows "$1" | sort -u > .vid/round/rr; [ -s .vid/round/rr ] || return 1; k0=$(nk "$1"); : > .vid/round/rh; [ -z "$k0" ] || cat "$C/$1/$k0/reached" > .vid/round/rh 2>/dev/null || true
  for n in $(rtix .vid/round/rr .vid/round/rh); do [ -n "$(mrg "$n")" ] || return 0; done; return 1; }
rpend() { [ -n "${PEND+x}" ] || PEND=$(sh "$HERE/writer.sh" pending 2>/dev/null || true); [ -n "$PEND" ] || return 1
  { rrows "$1"; k0=$(nk "$1"); [ -z "$k0" ] || cut -d' ' -f1 "$C/$1/$k0/rows" 2>/dev/null || true; } | sort -u > .vid/round/rp
  printf '%s\n' "$PEND" | awk -v s="$1" -v RF=.vid/round/rp 'BEGIN { while ((getline l < RF) > 0) W[l] = 1 } ($1 in W) || $2 == s { f = 1 } END { exit !f }'; }
# v0.26.10.25.5 (R5): wdue <step>, the writer owes the step a new ticket (its others have all merged when a close is owed);
# v0.26.10.26.7 (R9): or a reached row of its close is not yet in a published ticket
wdue() { ! rpend "$1" || return 0; [ -n "${WDUE+x}" ] || WDUE=$(sh "$HERE/writer.sh" due 2>/dev/null || true); [ -n "$WDUE" ] || return 1
  sk=$(plan_block | awk -F' [|] ' -v s="step $1" '$1 == s { for (i = 2; i <= NF; i++) if ($i == "kind: skeleton") print "y" }')
  cat "$C/$1"/*/fixes 2>/dev/null | cut -f1 > .vid/round/fk; printf '%s\n' "$WDUE" | awk -v s="$1" -v sk="$sk" -v FK=.vid/round/fk 'BEGIN { while ((getline l < FK) > 0) K[l] = 1 }
    ($1 == "new" && $2 == "step" && $3 == s) || ($1 == "new" && $2 == "skeleton" && sk != "") || ($1 == "new" && $2 == "fix" && ($3 in K)) { f = 1 } END { exit !f }'; }
# GM-4 K3: WHY, the first thing it found missing, for `step`'s refusal. GitHub manual (GM M3): an ask a landing withdrew waits,
# owed by no rule, until the applied commit holds that landing (lwait)
owed1() { WHY='closed already'; closed "$1" && return 1; k=$(nk "$1"); [ -z "$k" ] || [ -f "$C/$1/$k/withdrawn" ] || { again1 "$1" "$k"; return; }
  if [ -n "$k" ] && lwait "$C/$1/$k/withdrawn"; then WHY="its close ask $k was withdrawn by the landing $LW, which the applied commit does not hold yet"; return 1; fi
  t=$(tix "$1"); WHY="no ticket of $1 is published"; [ -n "$t" ] || return 1
  WHY="no step ticket of $1 is published"; printf '%s\n' "$t" | grep -qE ' (step|skeleton)$' || return 1
  u=$(printf '%s\n' "$t" | while read -r n x; do [ -n "$(mrg "$n")" ] || echo "$n"; done | sort -n | sed 's/^/#/' | paste -sd ' ' -)
  WHY="$u has no merge on record"; case $u in *' '*) WHY="$u have no merge on record" ;; esac; [ -z "$u" ] || return 1
  WHY='a ticket holding its reached rows has no merge on record'; ! rwait "$1" || return 1; WHY="the ticket writer owes $1 a ticket"; ! wdue "$1" || return 1
  # FB-3 A1.5: in GitHub manual no close is owed while no engines are named, so round.sh asks never stops on it
  if manual; then WHY='the handed record names no engines yet'; [ -n "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" 2>/dev/null | tail -n 1)" ] || return 1; fi; WHY=''; }
# lwait <withdrawn file> (GM-4 K3, GM M3): in GitHub manual, the landing that withdrew the ask (its first word, a commit of this
# repository) is pending: the applied commit does not hold it. LW, that landing. A closed-outside withdrawal waits on nothing
lwait() { manual || return 1; LW=$(head -n 1 "$1" 2>/dev/null | cut -d' ' -f1); [ -n "$LW" ] && git cat-file -e "$LW^{commit}" 2>/dev/null || return 1
  _ap=$(applied); [ -z "$_ap" ] || ! git merge-base --is-ancestor "$LW" "$_ap" 2>/dev/null; }
cmd_owed() { reclose; for x in $(steps); do [ -f "$C/$x/tickets" ] && closed "$x" && tclose "$x" > /dev/null; done   # GM-4 K3: a closed step's tickets left open, tried again, silent
  WOWED=$(sh "$HERE/walk.sh" owed 2>/dev/null || true)   # 0.26.10.28.6 (R1 (a)): first, so a walk recorded none frees staging and the close this round
  SDUE=''; for x in $(sstages); do ! sdue "$x" || { echo "stage $x"; SDUE="$SDUE $x"; }; done
  for s in $(steps); do x=$(stof "$s"); if [ -n "$x" ]; then case " $SDUE " in *" $x "*) continue ;; esac; grep -q "^candidate $x " "$HAND" 2>/dev/null && continue; fi; owed1 "$s" && echo "close $s"; done
  # v0.26.10.26.2 (R1, R4): one okay, the highest stage's due; a CS once its D1 passed
  o=''; for x in $(ls "$SD" 2>/dev/null | sort -n); do ! okdue "$x" || o=$x; done; [ -z "$o" ] || echo "okay staging $o"
  for x in $(ls "$SD" 2>/dev/null); do c=$(snc "$x"); [ -n "$c" ] && [ -f "$SD/$x/$c/d1/passed" ] && [ ! -f "$SD/$x/$c/cs/ask" ] && [ ! -f "$SD/$x/$c/cs/done" ] && echo "cs $x"; done
  [ -z "$WOWED" ] || printf '%s\n' "$WOWED"
  for x in $(ls "$SD" 2>/dev/null | sort -n); do c=$(snc "$x"); [ -n "$c" ] || continue; set -- $(sclosed "$x"); [ "${2:-}" = "$c" ] && continue; ! cconds "$x" || echo "close-stage $x"; done   # v0.26.10.26.5 (R1)
  # v0.26.10.27.1 (R1, R2, R4, R5): the rehearsal, CR, the production okay and CP, at the newest closed candidate
  ! rhdue || echo "okay rehearsal $N"; set -- $(lastc); if [ $# = 2 ]; then N=$1; c=$2; F=$SD/$N/$c
    [ -f "$F/rh/passed" ] && [ ! -f "$F/rh/nobackup" ] && rhcounts "$F" && [ ! -f "$F/cr/ask" ] && [ ! -f "$F/cr/done" ] && echo "cr $N"
    ! pdue || echo "okay production $N"; fi
  for O in $(ls -d "$SD"/*/*/d2 2>/dev/null); do G=${O%/d2}; [ -f "$O/passed" ] && [ ! -f "$G/cp/ask" ] && [ ! -f "$G/cp/done" ] && ! psettled "$G" && { G=${G#"$SD"/}; echo "cp ${G%/*}"; }; done | sort -u; return 0; }   # v0.26.10.26.4 (R1): `walk <N>`, for the run manager to brief and start   # R1: no C1 once the stage's candidate is due or named
cmd_out() { for s in $(ls "$C" 2>/dev/null); do k=$(nk "$s"); [ -n "$k" ] && [ ! -f "$C/$s/$k/withdrawn" ] && ! closed "$s" && echo "out $s"; done
  for x in $(ls "$SD" 2>/dev/null); do c=$(snc "$x"); F=$SD/$x/$c; [ -n "$c" ] && [ -f "$F/named" ] && [ ! -f "$F/withdrawn" ] || continue; { [ ! -f "$F/passed" ] || { [ -f "$F/s1ask" ] && [ ! -f "$F/s1done" ] && [ ! -f "$F/s1withdrawn" ]; } || dout "$F" || { [ -f "$F/cs/ask" ] && [ ! -f "$F/cs/passed" ] && [ ! -f "$F/cs/withdrawn" ]; } || wout "$F" || [ -f "$F/cs/stand-in-again" ] || pout "$F" || for o in $(ls "$SD/$x" | grep -E '^[0-9]+$'); do [ "$o" != "$c" ] && pprod "$SD/$x/$o" && break; done; } && echo "out stage-$x"; done; return 0; }   # 0.26.10.29.2 (R2): a withdrawn candidate is out no more
# pout <folder> (v0.26.10.27.1): its rehearsal, CR, production okay or CP out
pout() { [ -f "$1/rh/ask" ] && [ ! -f "$1/rh/closed" ] && [ ! -f "$1/rh/passed" ] && return 0; pprod "$1" && return 0
  [ -f "$1/cr/ask" ] && [ ! -f "$1/cr/passed" ] && [ ! -f "$1/cr/withdrawn" ] && return 0; [ -f "$1/rh/closed" ] && grep -q '^failed ' "$1/rh/closed"; }
# wfin <w1 folder> (0.26.10.28.6, R1): W1 has an outcome — done, withdrawn, none (no screens, no journey) or limit (no browser, the owner's
# "close without the walk"), as checks/walk.sh records them
wfin() { [ -f "$1/done" ] || [ -f "$1/withdrawn" ] || [ -f "$1/none" ] || [ -f "$1/limit" ]; }
# wout <folder> (v0.26.10.26.4): its walk started and not read
wout() { ! wfin "$1/w1" || return 1; ws=$(ls "$1/w1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1); [ -n "$ws" ] && [ -s "$1/w1/$ws/pid" ] && [ ! -f "$1/w1/$ws/read" ]; }
# dout <folder>: its okay out, or closed failed for a product change and not yet asked again
dout() { [ -f "$1/d1/ask" ] && [ ! -f "$1/d1/passed" ] && { [ ! -f "$1/d1/closed" ] || grep -q '^failed ' "$1/d1/closed"; }; }
# R3 (v0.26.10.25.5): a withdrawn ask whose issue is still open, its issue closed again, at each owed; silent. reclose <step>, that
# step's alone (GM-4 K3, `step`). GitHub manual (GM M3): one a pending landing withdrew waits for the apply (lwait), told and closed after; FB-1 C3:
# a stage candidate's withdrawn asks too, at a whole owed
reclose() { for W in $(ls "$C"/${1:-*}/*/withdrawn 2>/dev/null); do s=$(basename "$(dirname "$(dirname "$W")")"); ! grep -q '^issue ' "$W" || continue; ! lwait "$W" || continue; i=$(sed -n "s/^issue$TAB//p" "$(dirname "$W")/ask" | head -n 1); [ -n "$i" ] || continue
    w1=$(head -n 1 "$W" | cut -d' ' -f1); if [ "$w1" = closed-outside ]; then printf 'vid: withdrawn. Ticket %s of %s was closed outside ViD; its rows come in a new ticket, and this close is asked again once it merges. A later report for it is not read.\n' "$(head -n 1 "$W" | cut -d' ' -f2)" "$s" > .vid/round/wc
    else printf 'vid: withdrawn. The landing %s changed rows of %s; this close is asked again once its new tickets merge. A later report for it is not read.\n' "$w1" "$s" > .vid/round/wc; fi
    gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 && gh_ close "$i" > /dev/null 2>&1 && echo "issue $i" >> "$W"; done
  # FB-1 C3: and, at a whole owed, each ask a re-cut withdrew at a stage's candidate (land.sh's: its C3 unless passed or done, its S1
  # when s1withdrawn, its D1 when d1/closed says the landing withdrew it), by the step's rule: the read shows it open, no `issue <i>`
  # line records it yet; commented with the landing's text unless the read shows that comment on it already, closed, recorded
  [ -z "${1:-}" ] || return 0
  for W in $(ls "$SD"/*/*/withdrawn 2>/dev/null); do F=${W%/withdrawn}; ! lwait "$W" || continue; L0=$(head -n 1 "$W" | cut -d' ' -f1); c=${F##*/}; N=${F%/*}; N=${N##*/}
    { [ -f "$F/passed" ] || [ -f "$F/done" ] || sed -n "s/^issue$TAB//p" "$F/ask" 2>/dev/null | head -n 1
      [ ! -f "$F/s1withdrawn" ] || sed -n "s/^issue$TAB//p" "$F/s1ask" 2>/dev/null | head -n 1
      ! grep -q '^withdrawn by the landing ' "$F/d1/closed" 2>/dev/null || sed -n "s/^issue$TAB//p" "$F/d1/ask" 2>/dev/null | head -n 1; } > .vid/round/wi
    while read -r i; do [ -n "$i" ] && ! grep -qx "issue $i" "$W" || continue
      h=$(awk -F'\t' -v i="$i" '$1 == "issue" && $2 == i { print $4; f = 1; exit } END { exit !f }' "$RD" 2>/dev/null) || continue   # open, as the read shows it
      printf 'vid: withdrawn. The landing %s re-cut the stages and changed stage %s; its candidate %s is withdrawn, and a new one is named once one is due. A later report for this one is not read.\n' "$L0" "$N" "$c" > .vid/round/wc
      printf '%s\n' "$h" | tr '\001' '\n' | grep -qF "vid: withdrawn. The landing $L0 " || gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || continue
      gh_ close "$i" > /dev/null 2>&1 && echo "issue $i" >> "$W"; done < .vid/round/wi; done; return 0; }
# owned [<step>]: each row the newest ask of a step, but that one, found red whose fix line's ticket has not merged; in a subshell, so
# its loop leaves the caller's variables
cmd_owned() ( { for s in $(ls "$C" 2>/dev/null); do echo "$s $C/$s/$(nk "$s")"; done; for x in $(ls "$SD" 2>/dev/null); do echo "stage-$x $SD/$x/$(snc "$x")"; echo "cs-$x $SD/$x/$(snc "$x")/cs"; done; } | while read -r s F; do [ "$s" != "${1:-}" ] || continue; [ -f "$F/acted" ] || continue   # v0.26.10.26.1: a stage's newest C3 too
    a=$(sed -n "s/^asked$TAB//p" "$F/ask" | head -n 1); cut -f1 "$F/acted" | while read -r r; do   # v0.26.10.25.5: a row landed since the ask is no one's
      awk -v r="$r" -v a="$a" '$1 == r { t = $3 } END { exit !(t != "" && t > a) }' "$D/landed" 2>/dev/null && continue
      f=$(awk -F'\t' -v r="$r" '{ n = split($2, a, " "); for (i = 1; i <= n; i++) if (a[i] == r) k = $1 } END { print k }' "$F/fixes" 2>/dev/null)
      if [ -n "$f" ]; then t=$(fixt "$f"); [ -n "$t" ] && [ -n "$(mrg "$t")" ] && continue; fi; limited "$r" || echo "$r"; done; done | sort -u )
# the rows of the open fix tickets, whatever wrote their fix lines
fxo() { awk '$1 == "published" { k = ""; r = ""; for (i = 3; i <= NF; i++) { if ($i ~ /^kind=/) k = substr($i, 6); if ($i ~ /^rows=/) r = substr($i, 6) } if (k == "fix") F[$2] = r } $1 == "withdrawn" { delete F[$2] } END { for (n in F) print n, F[n] }' "$LOG" 2>/dev/null | while read -r n r; do [ -n "$(mrg "$n")" ] || printf '%s\n' "$r" | tr , '\n'; done; }
# a row's marks and kind in its ticket file; deploy-owed rows and known limits are left out
tfile() { n=$(awk -v r="$1" '($1 == "published" || $1 == "amended") { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/ && index("," substr($i, 6) ",", "," r ",")) n = $2 } END { print n }' "$LOG" 2>/dev/null)
  if [ -n "$n" ] && [ -f ".vid/tw/out/issue-$n.md" ]; then echo ".vid/tw/out/issue-$n.md"; else ls .vid/tw/out/issue-*.md 2>/dev/null; fi; }   # the newest ticket holding the row (R4)
owed_() { grep -h "^- $1 marks: " $(tfile "$1") /dev/null 2>/dev/null | head -n 1 | grep -qE '(^|[ ;])(owed-[a-z-]*|seam)($|[ ;])'; }
procs() { grep -h "^- $1 marks: " $(tfile "$1") /dev/null 2>/dev/null | head -n 1 | grep -q "run with the product's processes"; }
# a row's case seconds in its newest head report's primary cases file: 30 a case, or a row, with none
secs() { l=$(awk -F'\t' -v r="$1" '$4 == r { p = $2; h = $3 } END { if (p != "") print p, h }' "$D/log" 2>/dev/null); set -- "$1" $l; [ $# = 3 ] || { echo 30; return; }
  case $2 in step-*) _sk=$2 ;; *) _sk=pr-$2 ;; esac   # GM-4 E2: a ticket's decision, its reports under step-<n>
  k=$(git --git-dir=.vid/code for-each-ref --format='%(refname:lstrip=3)' "refs/heads/vid-results/$_sk-$3-*" 2>/dev/null | sed 's/.*-//' | sort -n | tail -n 1); [ -n "$k" ] || { echo 30; return; }
  git --git-dir=.vid/code show "refs/heads/vid-results/$_sk-$3-$k:$_sk-$3-$k/cases-$P1.xml" 2>/dev/null | awk -v id="$1" 'BEGIN { RS = "<"; gsub(/[-_.]/, "-", id) }
    /^testcase[ \t\n]/ { n = $0; sub(/.*[ \t\n]name="/, "", n); sub(/".*/, "", n); gsub(/[-_.]/, "-", n); p = index(n, id); if (!p || substr(n, p + length(id), 1) ~ /[A-Za-z0-9]/) next
      t = $0; if (sub(/.*[ \t\n]time="/, "", t)) { sub(/".*/, "", t); s += (t + 0 > 0) ? t : 30 } else s += 30; c++ } END { print (c ? int(s + 0.999) : 30) }'; }
# FB-3 A1.5: crep, how a chunk's report is made, in its ask: in GitHub manual by anyone, its results files of any name
crep() { if manual; then printf 'its results.txt beginning by: and the name of whoever made it, its commit the one above, with one results file or more (.xml), of any name'; else printf 'by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk'; fi; }
cmd_ask() { s=$1; owed1 "$s" || die "no close is owed for $s"; E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); [ -n "$E" ] || die 'the handed record names no engines yet'
  set -- $E; P1=$1; shift; P2=$*; M=$(skey close-chunk-minutes); M=${M:-20}; p=$(nk "$s"); k=$(( ${p:-0} + 1 )); K=$C/$s/$k
  # the commit: the merge of the step's tickets, its fix tickets too, that holds every other's, whatever order they were read in
  MS=$(for n in $(tix "$s" | cut -d' ' -f1); do mrg "$n" | cut -d' ' -f2; done; rrows "$s" | sort -u > .vid/round/rr; { [ -z "$p" ] || cat "$C/$s/$p/reached" 2>/dev/null; } > .vid/round/rh; for n in $(rtix .vid/round/rr .vid/round/rh); do mrg "$n" | cut -d' ' -f2; done); last=''   # R9: and the tickets that held its reached rows
  for c in $MS; do a=1; for o in $MS; do [ "$o" = "$c" ] || git --git-dir=.vid/code merge-base --is-ancestor "$o" "$c" 2>/dev/null || a=''; done; [ -z "$a" ] || last=$c; done
  [ -n "$last" ] || last=$(printf '%s\n' "$MS" | tail -n 1); [ -n "$last" ] || die "no merge commit for $s"
  # the rows: its tickets' and the steps' it builds on, rows and regression rows, and every row an earlier ask covered; less deploy-owed rows,
  # known limits, and rows an open fix ticket holds or another close found red (V2 §5.3 step 18)
  B=$(plan_block | awk -F' [|] ' -v s="step $s" '$1 == s { for (i = 2; i <= NF; i++) if ($i ~ /^builds-on: /) { sub(/^builds-on: /, "", $i); print $i } }' | tr ' ' '\n' | grep -v '^-$' | grep .)
  # 0.26.11.1.4 (R4): a ticket with no merge is skipped: its code is not at the close's commit, and its own decision and the stage's C3 cover its rows
  R=$( { for n in $(for x in "$s" $B; do tix "$x" | cut -d' ' -f1; done); do [ -n "$(mrg "$n")" ] || continue; awk '/^## / { x = substr($0, 4); next } x == "Rows" && /^> / { split(substr($0, 3), a, "|"); i = a[1]; gsub(/[ \t]/, "", i); if (i !~ /^[A-Z]+-[0-9]/) { i = a[2]; gsub(/[ \t]/, "", i) } print i } x == "Regression rows" && /^- [A-Z]+-[0-9]/ { print $2 }' ".vid/tw/out/issue-$n.md"; done
    [ -z "$p" ] || cut -d' ' -f1 "$C/$s/$p/rows"; } | awk '!s[$0]++')
  { cmd_owned "$s"; fxo; } > .vid/round/cx   # v0.26.10.25.5: another step's close owns a row, never this step's own
  mkdir -p "$K"; : > "$K/rows"; for r in $R; do owed_ "$r" || limited "$r" || grep -qxF "$r" .vid/round/cx || printf '%s %s\n' "$r" "$(secs "$r")" >> "$K/rows"; done
  [ -s "$K/rows" ] || { echo "closed $s | stand-in: close, no row to run" >> "$HAND"; ev "close-closed step=$s rows=0"; echo "closed $s"; tclose "$s" "$last"; return 0; }
  awk -v m=$((M * 60)) '{ if (n && t + $2 > m) { n++; t = 0 } else if (!n) n = 1; t += $2; c[n] = c[n] (c[n] == "" ? "" : " ") $1 } END { for (i = 1; i <= n; i++) print i "\t" c[i] }' "$K/rows" > "$K/packed"
  name=$(plan_block | awk -F' [|] ' -v s="step $s" '$1 == s { sub(/^name: /, "", $2); print $2 }')
  { printf 'close: %s\ncommit: %s\nengines: %s\n\n' "$s" "$last" "$E"
    printf 'Run these rows at the commit above, chunk by chunk, in the engines each chunk names: phase 1, the primary engine, first, then phase 2. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, %s, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`. A chunk may wait while a ticket'"'"'s run needs the slot.\n\n' "$(crep)"
    while IFS=$TAB read -r c rows; do printf -- '- chunk p1c%s, %s: %s\n' "$c" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r c rows; do printf -- '- chunk p2c%s, %s: %s\n' "$c" "$P2" "$rows"; done < "$K/packed"
    w=''; for r in $(cut -d' ' -f1 "$K/rows"); do procs "$r" && w="$w $r"; done; [ -z "$w" ] || printf -- '- with the product'"'"'s own declared processes:%s\n' "$w"; } > "$K/body"
  n=$(gh_ run-ask --step "$s" --commit "$last" --title "Close run: ${name:-$s}" --body-file "$K/body") || die 'the ask could not be posted'
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\n' "$n" "$last" "$(stamp)"; while IFS=$TAB read -r c rows; do printf 'chunk\tp1c%s\t%s\t%s\n' "$c" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r c rows; do printf 'chunk\tp2c%s\t%s\t%s\n' "$c" "$P2" "$rows"; done < "$K/packed"; } > "$K/ask"
  ev "close-asked step=$s issue=$n commit=$last chunks=$(grep -c '^chunk' "$K/ask") ask=$k"; echo "asked $n close $s"; }

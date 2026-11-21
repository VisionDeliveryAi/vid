#!/bin/sh
# Purpose: ViD's step close in ticket mode (v0.26.10.25.3, R8, R10; v0.26.10.25.4, R1, R3, R4). It reads ViD's records, the round's read and the
# results reader's close read; it reads no code and runs nothing: DevAgent runs every chunk, on the ask's words. Run at the top of ViD's repository.
#   owed            each step owing a close, one line `close <step>`: every ticket merged, with no `closed <step>` line and no ask; or its newest
#                   ask red, done, with a fix line, every fix line's ticket merged or every row of it a known limit, and nothing waiting on the owner
#   out             each step with an ask and no `closed <step>` line
#   step <step>     (GM-4 K3, /vid:vid-step-close) the step's close, its one entry in both modes: its withdrawn asks told; out, the reports
#                   fetched and the one read made, then read as decide reads it (its lines, `closed <step>` when it closed, else
#                   `out <step> #<ask>`); owed, asked as ask asks it (`asked <n> close <step>`, or `closed <step>` with no row to run);
#                   else `refused <step>: <what is missing>`, nothing posted, exit 1. GitHub manual (GM M8, M3): once closed, each open
#                   ticket of the step closed with one comment (`ticket-closed #<n>`); an ask a landing withdrew is neither told, closed
#                   nor asked again until the applied commit holds that landing
#   stage <N>       (GM-4 K4, /vid:vid-stage-close) the stage's end, its one entry in both modes, whichever is next: the full run and
#                   grade asked when due; the walk started (walk.sh start) when due, or read once its walker ended; every condition met,
#                   the summary's facts written (`summary <N>`) while there is no summary.md, else the stage closed; otherwise
#                   `refused stage <N>: <what is missing>`, nothing posted, exit 1. walk <N>, read-walk <N> and summary <N>: one alone.
#                   GM-4 E12: in GitHub manual PRD.md, INVENTORY.md, STAGES.md and ARCHITECTURE.md are read at the applied commit;
#                   D4: a published step is of the stage its ticket's header names
#   deploy staging [<N>] | deploy production "<words>"   (GM-4 K5, /vid:vid-deploy, both GitHub modes) the staging okay posted when
#                   due, else `refused staging: <what is missing>`; the owner's production yes in their words, the one way to give it,
#                   `yes production <N> <c>`, else `refused production: <why>`; each refusal exit 1, nothing posted. GM-4 E9 (GM M14,
#                   D7), in GitHub manual: each okay of stage N's candidate X lists the later work X holds; the staging and production
#                   okays add the duty later-work-off with the list, the rehearsal's names both; nothing listed, no such duty. D4: in
#                   GitHub manual no hold sentence in the staging okay
#   ask <step>      packs the step's rows into chunks and posts the ask, an issue labelled <prefix>run; .vid/decide/close/<step>/<k>/ask
#   decide <step>   reads the newest ask: every chunk green closes the step; a chunk with a row not run, or absent past close-wait-minutes: of
#                   quiet, is asked again once, and lost again it is an item for the owner (0.26.10.28.10, R2: `same` when its rows could not run as
#                   at the attempt before; an owner's again goes out with their words, `why:`); a red chunk is an item; a split is written. Once no
#                   chunk waits on a report, its red rows read failing, with one count; a row red at an earlier ask of the step is an item for the
#                   owner, and the others get one fix line; a plan change; the ask's issue closed; after the first ask, the three numbers
#   (v0.26.10.25.5, R5) a step that gains a row at a landing is open again: its newest ask withdrawn (withdrawn), read no more, and a
#                   close owed again by the first rule, once the writer owes the step no ticket; the writer owing it one holds any close
#   owned           the rows a close found red whose fix has not merged, one a line: a ticket that lists one as a regression row lets it stand
#   (v0.26.10.26.2) owed also prints `okay staging <N>` once the newest candidate's C3 passed and staging is free, and `cs <N>` once its
#                   D1 passed; okay --stage <N> posts the okay for DevAgent's deploy, labelled <prefix>deploy, in <c>/d1/; ask --cs <N> asks
#                   CS, the staging run, in <c>/cs/; decide --stage <N> reads both too; a seam or staging-owed row CS passes is paid
#   (0.26.11.1.1, R3 to R6) the staging okay names its seed (the owner's newest `control seed` word), its outside-service rows (the
#                   seam rows CS would ask), the hosting and the staging duties; the production okay the hosting and the production
#                   duties; the rehearsal okay asks the kept: lines; a seam row is paid only when the passed D1 marks it real, else a
#                   stand-in item, whose again asks D1 and CS afresh at the candidate; the owner's yes names the records kept
#   (0.26.11.1.3, R3)    the staging okay lists the stage's open real checks (stage 0's skeleton line always, and each `finding: real` line
#                   of its tickets), recorded `real <n> <line>` in its ask; a D1 refused twice for one is the owner's `notreal` item
# Settings: close-chunk-minutes: (20), close-wait-minutes: (180). Records: .vid/decide/close/<step>/<k>/ (ask, again, items, read, chunks, failed,
# acted, lined, fixes, result, numbers, done), k the ask's number, the newest read.
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
CSM=''; CK=''; D=.vid/decide; C=$D/close; LOG=.vid/tw/log; HAND=.vid/tw/handed; RD=.vid/round/read; TAB=$(printf '\t'); mkdir -p "$C" .vid/round
die() { echo "ViD close: $*" >&2; exit 1; }
PX=$(skey labels-prefix)
gh_() { sh "$HERE/github.sh" "$@"; }
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
  WHY='a ticket holding its reached rows has no merge on record'; ! rwait "$1" || return 1; WHY="the ticket writer owes $1 a ticket"; ! wdue "$1" || return 1; WHY=''; }
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
# step's alone (GM-4 K3, `step`). GitHub manual (GM M3): one a pending landing withdrew waits for the apply (lwait), told and closed after
reclose() { for W in $(ls "$C"/${1:-*}/*/withdrawn 2>/dev/null); do s=$(basename "$(dirname "$(dirname "$W")")"); ! grep -q '^issue ' "$W" || continue; ! lwait "$W" || continue; i=$(sed -n "s/^issue$TAB//p" "$(dirname "$W")/ask" | head -n 1); [ -n "$i" ] || continue
    w1=$(head -n 1 "$W" | cut -d' ' -f1); if [ "$w1" = closed-outside ]; then printf 'vid: withdrawn. Ticket %s of %s was closed outside ViD; its rows come in a new ticket, and this close is asked again once it merges. A later report for it is not read.\n' "$(head -n 1 "$W" | cut -d' ' -f2)" "$s" > .vid/round/wc
    else printf 'vid: withdrawn. The landing %s changed rows of %s; this close is asked again once its new tickets merge. A later report for it is not read.\n' "$w1" "$s" > .vid/round/wc; fi
    gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 && gh_ close "$i" > /dev/null 2>&1 && echo "issue $i" >> "$W"; done; return 0; }
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
    printf 'Run these rows at the commit above, chunk by chunk, in the engines each chunk names: phase 1, the primary engine, first, then phase 2. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`. A chunk may wait while a ticket'"'"'s run needs the slot.\n\n'
    while IFS=$TAB read -r c rows; do printf -- '- chunk p1c%s, %s: %s\n' "$c" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r c rows; do printf -- '- chunk p2c%s, %s: %s\n' "$c" "$P2" "$rows"; done < "$K/packed"
    w=''; for r in $(cut -d' ' -f1 "$K/rows"); do procs "$r" && w="$w $r"; done; [ -z "$w" ] || printf -- '- with the product'"'"'s own declared processes:%s\n' "$w"; } > "$K/body"
  n=$(gh_ run-ask --step "$s" --commit "$last" --title "Close run: ${name:-$s}" --body-file "$K/body") || die 'the ask could not be posted'
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\n' "$n" "$last" "$(stamp)"; while IFS=$TAB read -r c rows; do printf 'chunk\tp1c%s\t%s\t%s\n' "$c" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r c rows; do printf 'chunk\tp2c%s\t%s\t%s\n' "$c" "$P2" "$rows"; done < "$K/packed"; } > "$K/ask"
  ev "close-asked step=$s issue=$n commit=$last chunks=$(grep -c '^chunk' "$K/ask") ask=$k"; echo "asked $n close $s"; }
akey() { sed -n "s/^$1$TAB//p" "$K/ask" | head -n 1; }
# drop <key> <file>: the file's lines keyed <key> (its first tab field) removed (0.26.10.29.1, R2)
drop() { [ -f "$2" ] || return 0; awk -F'\t' -v c="$1" '$1 != c' "$2" > .vid/round/dr && put "$2" < .vid/round/dr; }
item() { grep -qxF "$1" "$K/items" 2>/dev/null || { echo "$1" >> "$K/items"; ev "close-item step=$s what=$(printf %s "$1" | cut -d' ' -f1-2 | tr ' ' '-')"; }; }
# a red row's one line in the handed record, its mark kept
hfail() { m=$(sed -n "s/^row $1 [^ ]* \(fault-proven\).*/\1/p" "$HAND" | tail -n 1); { grep -v "^row $1 " "$HAND" || true; printf 'row %s failing%s | stand-in: %s #%s\n' "$1" "${m:+ $m}" "${HL:-close}" "$n"; } > .vid/round/h || exit 1; put "$HAND" < .vid/round/h || exit 1; }
# R4: each row of the ask green or red; after the first ask, against the step's last close
numbers() { awk -F'\t' -v SF="$D/state" "$LIMB"' $1 == "row" && !($4 in L) { if ($5 == "failed") r[$4] = "red"; else if (r[$4] != "red") r[$4] = ($5 == "passed" && r[$4] != "-") ? "green" : "-" } END { for (y in r) if (r[y] != "-") print y "\t" r[y] }' "$K/read" | sort > "$SX/nr" || exit 1; put "$K/result" < "$SX/nr" || exit 1
  p=$(for P in $(prior); do [ -f "$P/result" ] && echo "$P"; done | tail -n 1); [ -n "$p" ] || return 0
  awk -F'\t' 'NR == FNR { b[$1] = $2; next } { if ($2 == "red" && b[$1] == "green") g++; else if ($2 == "red" && b[$1] == "red") o++; else if ($2 == "green" && b[$1] == "red") f++ } END { printf "regressions introduced %d · defects still open %d · fixed %d\n", g, o, f }' "$p/result" "$K/result" > "$SX/nn" || exit 1; put "$K/numbers" < "$SX/nn" || exit 1
  echo "close-numbers $s $k $(cat "$K/numbers")"; ev "close-numbers step=$s ask=$k $(tr -d '·' < "$K/numbers" | awk '{ print "regressions=" $3, "open=" $7, "fixed=" $9 }')"; }   # fields: regressions= open= fixed=
cmd_decide() { s=$1; KD=$C/$s; k=$(nk "$s"); [ -n "$k" ] || die "no close is out for $s"; closed "$s" && return 0; STG=''; HL=''; LB=''; EVS=''; CSM=''; RA="--step $s"; decide_k; }
# prior: the folders of the earlier asks, oldest first: a step's or C3's by number; CS's (v0.26.10.26.2) the stage's earlier candidates' cs
prior() { if [ -n "$CSM" ]; then for j in $(ls "$SD/$STG" | grep -E '^[0-9]+$' | sort -n); do [ "$j" -lt "$CSM" ] && [ -f "$SD/$STG/$j/${CK:-cs}/ask" ] && echo "$SD/$STG/$j/${CK:-cs}"; done
  else for j in $(ls "$KD" | grep -E '^[0-9]+$' | sort -n); do [ "$j" -lt "$k" ] && echo "$KD/$j"; done; fi; return 0; }
# decide_k: the newest ask k of the folder KD, as a step close (STG empty) or a stage's C3 (STG its number)
decide_k() { K=$KD/$k; [ ! -f "$K/withdrawn" ] || return 0; n=$(akey issue); touch "$K/again" "$K/items" "$K/acted" "$K/lined" "$K/fixes"; : > "$SX/fo"
  sh "$HERE/results.sh" close $RA > /dev/null 2> .vid/round/ce || die "the close could not be read: $(tail -n 1 .vid/round/ce)"
  # a known limit leaves the close; a chunk's state is that of its other rows: a row not run makes it incomplete, red or not
  awk -F'\t' -v SF="$D/state" -v FO="$SX/fo" "$LIMB"'
    $1 == "chunk" { st[$2] = $3; at[$2] = $4; o[++n] = $2; next } $1 == "row" && !($4 in L) { if ($5 == "failed") { f[$2] = f[$2] " " $3 ":" $4; print $2 "\t" $3 "\t" $4 "\t" $6 > FO } else if ($5 != "passed") x[$2] = x[$2] " " $4 }
    $1 == "row" && ($4 in L) { lim[$2] = 1 } $1 == "row" && !($4 in L) { own[$2] = 1 }
    END { for (i = 1; i <= n; i++) { c = o[i]; s = (st[c] == "absent") ? ((lim[c] && !own[c]) ? "green" : "absent") : (x[c] != "") ? "incomplete" : (f[c] != "") ? "red" : "green"; print c "|" s "|" at[c] "|" f[c] "|" x[c] } }' "$K/read" > "$SX/ch" || exit 1; put "$K/chunks" < "$SX/ch" || exit 1; put "$K/failed" < "$SX/fo" || exit 1
  awk -F'|' 'NR == FNR { if ($2 == "green" || $2 == "red") R[$1] = 1; next } { split($0, w, " ") } !(w[1] == "lost" && (w[2] in R))' "$K/chunks" "$K/items" > .vid/round/it || exit 1; put "$K/items" < .vid/round/it || exit 1   # a late report ends its chunk's loss
  if [ -s "$K/chunks" ] && ! awk -F'|' '$2 != "green" { exit 1 }' "$K/chunks"; then :; elif [ -s "$K/chunks" ] && [ -n "$CSM" ]; then numbers; cs_green; return 0; elif [ -s "$K/chunks" ] && [ -n "$STG" ]; then numbers; stage_green; return 0; elif [ -s "$K/chunks" ]; then numbers
    c=$(akey commit); echo "closed $s | stand-in: close #$n at $(printf %.12s "$c")" >> "$HAND"; ev "close-closed step=$s issue=$n commit=$c"
    gh_ close "$n" > /dev/null 2>&1 || true; echo "closed $s"; tclose "$s" "$c"; return 0; fi
  # splits, from the close
  awk -F'\t' '$1 == "split" { print $2 "\t" $3 }' "$K/read" | while IFS=$TAB read -r r e; do grep -q "^engine-split $r " "$HAND" 2>/dev/null || { echo "engine-split $r | stand-in: $e" >> "$HAND"; ev "engine-split row=$r from=close step=$s"; echo "split $r"; }; done
  W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { print $5 }' .vid/round/read 2>/dev/null); q=$(( $(date +%s) - $(epoch "${u:-$(stamp)}") ))
  # v0.26.10.28.2 (R2): said <chunk>: DevAgent's `vid: lost <chunk> <k>` on the issue, k the current generation (the issue's count of `vid: again <chunk>`), newer than
  # the chunk's newest `vid: reported`: the chunk lost now, asked again or made the owner's at once, with no quiet time; an older generation's changes nothing
  said() { awk -F'\t' -v n="$n" -v c="$1" '$1 == "issue" && $2 == n { m = split($4, h, "\001"); for (i = 1; i <= m; i++) { if (h[i] == "vid: again " c) A++; else if (h[i] ~ ("^vid: reported " c "-[0-9]+$")) r = i
      else if (h[i] ~ ("^vid: lost " c " [0-9]+$")) { split(h[i], w, " "); k[i] = w[4] } } for (i in k) if (i + 0 > r && k[i] == A + 0) f = 1 } END { exit !f }' .vid/round/read 2>/dev/null; }
  # 0.26.10.28.10 (R2): lsig <chunk>, the chunk's rows that could not run, by engine and state, messages apart; each attempt's in lostsig
  # (`<chunk> <attempt> <sig>`); lost with the sig of the attempt before, the chunk is `same` (queue.sh refuses a bare again);
  # an again's words, againwhy (`<chunk> TAB <words>`), go out with it as `why:`
  lsig() { awk -F'\t' -v c="$1" '$1 == "row" && $2 == c && $5 != "passed" && $5 != "failed" { print $3 ":" $4 ":" $5 }' "$K/read" | sort | cksum | tr -d ' '; }
  while IFS='|' read -r ch st a fr xr; do case $st in
      red) item "red $ch$fr"; echo "close-red $s $ch$fr" ;;
      incomplete|absent) LS=''; ! said "$ch" || LS=1; [ "$st" = incomplete ] || [ "$q" -ge "$W" ] || [ -n "$LS" ] || grep -qxF "allow $ch" "$K/again" || continue; g=$(awk -v c="$ch" '$1 == c { print $2 }' "$K/again" | tail -n 1)
        sg=''; [ "$st" != incomplete ] || [ "${a:--}" = - ] || grep -q "^$ch $a " "$K/lostsig" 2>/dev/null || { sg=$(lsig "$ch"); echo "$ch $a $sg" >> "$K/lostsig"; }   # an attempt's first reading, from a report, never a refused or missing one
        if [ -z "$g" ] || grep -qxF "allow $ch" "$K/again"; then wy=$(awk -F'\t' -v c="$ch" '$1 == c { w = $2 } END { print w }' "$K/againwhy" 2>/dev/null)
          { printf 'vid: again %s\nby: RM\n' "$ch"; [ -z "$wy" ] || printf 'why: %s\n' "$wy"; } > .vid/round/again; gh_ comment "$n" --body-file .vid/round/again > /dev/null 2>&1 || die "the ask #$n could not be commented"
          grep -vxF "allow $ch" "$K/again" > .vid/round/ag; put "$K/again" < .vid/round/ag || exit 1; drop "$ch" "$K/againwhy" || exit 1; drop "$ch" "$K/same" || exit 1
          echo "$ch ${a:--}" >> "$K/again"; ev "close-again step=$s chunk=$ch"; echo "close-again $s $ch"
        elif [ "$a" != "$g" ] || [ "$q" -ge "$W" ] || [ -n "$LS" ]; then
          pv=$(awk -v c="$ch" -v a="${a:--}" '$1 == c && $2 != a { p = $3 } END { print p }' "$K/lostsig" 2>/dev/null)   # the attempt before's sig
          [ -z "$sg" ] || [ -z "$pv" ] || [ "$pv" != "$sg" ] || grep -qxF "$ch" "$K/same" 2>/dev/null || echo "$ch" >> "$K/same"
          item "lost $ch$xr #$(grep -c "^$ch " "$K/again")"; echo "close-lost $s $ch"; fi ;;
    esac; done < "$K/chunks"
  # R1: once no chunk waits on a report, each green, red, or lost to the owner
  awk -F'|' -v IT="$K/items" 'BEGIN { while ((getline l < IT) > 0) { split(l, x, " "); if (x[1] == "lost") G[x[2]] = 1 } } ($2 == "incomplete" || $2 == "absent") && !($1 in G) { f = 1 } END { exit f }' "$K/chunks" || return 0
  [ -z "$CSM" ] || [ "${CK:-cs}" = cp ] || cs_paid   # v0.26.10.26.2 (R5): CS's passed deploy-owed rows paid, red ones failing below; CP's only when green (v0.26.10.27.1)
  # its red rows, each once: failing, with one count; a row red at an earlier ask of the step is the owner's, unless the owner allowed another
  # fix; the others in one fix line, in words the writer's check passes, the failures' messages staying in the reports the line links
  awk -F'\t' 'function wd(n,   k, i, o, a) { sub(/.*::/, "", n); sub(/.*\//, "", n); sub(/^test_/, "", n); gsub(/_/, " ", n); gsub(/[^A-Za-z0-9 -]/, " ", n); k = split(n, a, " "); o = ""
      for (i = 1; i <= k; i++) { sub(/^-+/, "", a[i]); if (a[i] == "") continue; if (a[i] ~ /^[A-Z]+$/ && a[i + 1] ~ /^[0-9]+$/) { a[i + 1] = a[i] "-" a[i + 1]; continue } o = o (o == "" ? "" : " ") a[i] } return o == "" ? "its test" : o }
    { if (!($3 in w)) o[++m] = $3; w[$3] = w[$3] (w[$3] == "" ? "" : ", ") wd($4) " in " $2; c[$3] = c[$3] " " $1 } END { for (i = 1; i <= m; i++) print o[i] "\t" w[o[i]] "\t" c[o[i]] }' "$K/failed" > .vid/round/red
  new=''; why=''; lk=''; cmd_owned "$s" > .vid/round/ow; touch "$K/waits"
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
    awk -v a="$pa" -v LF="$D/landed" 'BEGIN { while ((getline l < LF) > 0) { split(l, x, " "); if (x[3] > L[x[1]]) L[x[1]] = x[3] } } { r = $1 } !(r in L) || a > L[r] { print r }' "$P/rows" | sort -u > "$SX/su"
    cut -f3 "$P/failed" | sort -u | comm -12 - "$SX/su" > "$SX/sp"; cut -f1 .vid/round/red | sort -u | comm -12 - "$SX/su" > "$SX/sk"
    # the same set, every row of it acted on then, is close-twice's alone: each row is its item already
    cut -f1 "$P/acted" 2>/dev/null | sort -u > "$SX/sa"
    if [ -s "$SX/sk" ] && { [ -n "$(comm -23 "$SX/sk" "$SX/sp")" ] || { cmp -s "$SX/sk" "$SX/sp" && [ -n "$(comm -23 "$SX/sk" "$SX/sa")" ]; }; }; then SHR=1
      # one open shrink item a close, `shrink <P>@<rows now,> <rows now> · before: <rows then>`: keyed by its rows, so a set that grew
      # since, or a new one after an answered one, is a new question to the owner; a grown open one replaces the old
      sl="shrink $(basename "$P")@$(paste -sd ',' "$SX/sk") $(paste -sd ' ' "$SX/sk") · before: $(paste -sd ' ' "$SX/sp")"
      grep -qxF "$sl" "$K/items" 2>/dev/null || { grep -v "^shrink $(basename "$P")@" "$K/items" > "$SX/si" 2>/dev/null || true; put "$K/items" < "$SX/si" || exit 1; }; item "$sl"; echo "close-shrink $s $(paste -sd ' ' "$SX/sk")"; fi; fi
  while IFS=$TAB read -r r w cs; do
    if ! grep -q "^$r$TAB" "$K/acted" && grep -qxF "$r" .vid/round/ow; then grep -qxF "$r" "$K/waits" || { echo "$r" >> "$K/waits"; echo "close-waits $s $r"; }; continue; fi   # another close's fix holds it
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
  # the ask's issue closed once nothing waits under it; the numbers
  [ -f "$K/done" ] || grep '^lost ' "$K/items" | grep -qv '^lost s1 ' || { numbers; gh_ close "$n" > /dev/null 2>&1 || true; : > "$K/done"; ev "close-done step=$s issue=$n"; echo "close-done $s"; }; return 0; }
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
# upto <N>: every row of stages 1 to N, by the admission's join: planner.sh rows' stage (its moved: counts), else stages.sh's; a seam stage 1
upto() { [ -f "$SX/up$1" ] && return 0; plr; ( cd "$SPD" && mustread "$SX/st0" stages scope --upto "$1" )
  awk -F'\t' -v c="$1" 'FILENAME == ARGV[1] { if ($5 ~ /^[0-9]+$/ || $5 == "later") P[$1] = ($5 != "later" && $5 + 0 <= c); if ($1 ~ /^SEAM-/ && c >= 1) S[$1] = 1; next }
    !($1 in P) || P[$1] { print } END { for (r in P) if (P[r]) print r; for (r in S) print r }' "$SX/plr" "$SX/st0" | sort -u > "$SX/up$1"; }
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
# sdue <N> (R1): exit 0 when stage N's candidate is due; else what keeps it, by kind, in $SX/why<N>
sdue() { N=$1; W=$SX/why$N; : > "$W"; plr
  for s in $(stp "$N"); do t=$(tix "$s")
    if [ -z "$t" ]; then awk -F'\t' -v s="$s" '$1 == s { print $2 }' "$SX/ps" | while read -r r; do awk -F'\t' -v r="$r" '$1 == r && $6 ~ /^(limit|later|record)$/ { f = 1 } END { exit !f }' "$SX/plr" || [ "$(hstate "$r")" = known-limit ] || { echo "step $s not merged"; break; }; done >> "$W"; continue; fi   # an owed row, a seam's too, is sent in a ticket
    printf '%s\n' "$t" | while read -r x y; do [ -n "$(mrg "$x")" ] || { echo "step $s not merged"; break; }; done >> "$W"
    ! wdue "$s" || echo "step $s owed a ticket" >> "$W"
    k=$(nk "$s"); [ -z "$k" ] || [ -f "$C/$s/$k/withdrawn" ] || closed "$s" || [ -f "$C/$s/$k/done" ] || echo "close $s out" >> "$W"
    printf '%s\n' "$t" | while read -r x y; do trows "$x"; done | sort -u | while read -r r; do case $(hstate "$r") in accepted|accepted-by-ruling|known-limit|owed|paid) ;; failing) echo "row $r failing" ;; held) echo "row $r held" ;; *) echo "row $r not decided" ;; esac; done >> "$W"; done
  [ ! -s "$W" ] || return 1
  sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$N" '$1 > n { f = 1 } END { exit f }' || return 1   # a later stage's C3 covers N
  for e in $(sstages); do [ "$e" -lt "$N" ] || continue; [ -n "$(stp "$e")" ] || continue; set -- $(sclosed "$e"); [ -n "${2:-}" ] && { [ -z "$(snc "$e")" ] || [ "$2" = "$(snc "$e")" ]; } || { echo "stage $e not closed at its newest candidate" >> "$W"; return 1; }; done   # v0.26.10.26.5 (R5a): stages close in order
  c=$(snc "$N"); [ -n "$c" ] || return 0; K=$SD/$N/$c; [ -f "$K/named" ] || return 0   # a post that failed: asked again
  [ ! -f "$K/withdrawn" ] || return 0   # 0.26.10.29.2 (R2): a candidate a re-cut withdrew, its C3 out or not: a new one is due
  if [ -f "$K/passed" ]; then X=$(sed -n "s/^commit$TAB//p" "$K/ask" | head -n 1); upto "$N"
    while IFS=$TAB read -r p t H M; do [ "$M" != - ] && [ -n "$M" ] || continue; ! anc "$M" "$X" || continue; trows "$t" | grep -qxF -f "$SX/up$N" && return 0; done < "$D/merges"; return 1; fi
  [ -f "$K/done" ] && againK "$K"; }
# the candidate: the recorded merge holding every other
newest_merge() { MS=$(cut -f4 "$D/merges" 2>/dev/null | grep -v '^-*$'); last=''
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
cmd_ask_stage() { N=$1; sdue "$N" || die "no candidate is due for stage $N: $(paste -sd ';' "$SX/why$N")"; E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); [ -n "$E" ] || die 'the handed record names no engines yet'
  set -- $E; P1=$1; shift; P2=$*; M=$(skey close-chunk-minutes); M=${M:-20}; c=$(snc "$N"); if [ -n "$c" ] && [ ! -f "$SD/$N/$c/named" ]; then :; else c=$(( ${c:-0} + 1 )); fi
  K=$SD/$N/$c; mkdir -p "$K"; if [ -f "$K/ask" ]; then X=$(cat "$K/commit"); else X=$(newest_merge); fi; [ -n "$X" ] || die "no merge for stage $N's candidate"; echo "$X" > "$SX/cm" || exit 1; put "$K/commit" < "$SX/cm" || exit 1; upto "$N"
  if [ ! -f "$K/ask" ]; then
    # C3's rows (R2): the rows and regression rows of every ticket merged at or before the candidate, of stages 1 to N, whose newest ticket has merged
    awk '$1 == "published" { k[$2] = 1 } $1 == "withdrawn" { delete k[$2] } END { for (n in k) print n }' "$LOG" | sort -n | while read -r t; do m=$(mrg "$t" | cut -d' ' -f2); [ -n "$m" ] && { [ "$m" = "$X" ] || anc "$m" "$X"; } || continue
      awk '/^## / { x = substr($0, 4); next } x == "Rows" && /^> / { split(substr($0, 3), a, "|"); i = a[1]; gsub(/[ \t]/, "", i); if (i !~ /^[A-Z]+-[0-9]/) { i = a[2]; gsub(/[ \t]/, "", i) } print i } x == "Regression rows" && /^- [A-Z]+-[0-9]/ { print $2 }' ".vid/tw/out/issue-$t.md" 2>/dev/null; done | awk '!s[$0]++' > "$SX/cr"
    { cmd_owned "stage-$N"; fxo; } > .vid/round/cx; : > "$K/rows"; : > "$SX/dw"
    # a row's newest ticket is the newest that holds it now, its amendments read
    while read -r r; do grep -qxF "$r" "$SX/up$N" || continue; nt=$(awk -v r="$r" '($1 == "published" || $1 == "amended") { if (!($2 in o)) o[$2] = ++k; for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) R[$2] = substr($i, 6) } END { for (t in R) if (index("," R[t] ",", "," r ",") && o[t] > b) { b = o[t]; n = t } print n }' "$LOG"); [ -z "$nt" ] || [ -n "$(mrg "$nt")" ] || continue
      if owed_ "$r"; then echo "$r" >> "$SX/dw"; continue; fi; limited "$r" || grep -qxF "$r" .vid/round/cx || printf '%s %s\n' "$r" "$(secs "$r")" >> "$K/rows"; done < "$SX/cr"
    awk -v m=$((M * 60)) '{ if (n && t + $2 > m) { n++; t = 0 } else if (!n) n = 1; t += $2; c[n] = c[n] (c[n] == "" ? "" : " ") $1 } END { for (i = 1; i <= n; i++) print i "\t" c[i] }' "$K/rows" > "$K/packed"
    DW=$(paste -sd ' ' "$SX/dw"); { printf 'close: stage-%s\ncommit: %s\nengines: %s\n\n' "$N" "$X" "$E"
      printf 'The full run of stage %s'"'"'s candidate: run these rows at the commit above, chunk by chunk, in the engines each chunk names, phase 1, the primary engine, first, then phase 2; and chunk p1cx, every other test case of the suite in the primary engine. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`.\n\n' "$N"
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
        printf 'Grade each requirement, in a fresh context, against the grading checklist and its rows'"'"' fail-ifs: pass, partial, facade (looks built, isn'"'"'t) or absent, each with its reason; then each finding, tagged bug or rule. One line per requirement, `REQ-<n> <word> — <reason>`, then `finding: bug|rule — <line>`. Report it as vid-results/grade-<this issue>-<k>, its grade.txt by: GR, its commit the one above, then comment `vid: reported s1-<k>` here. Comment `vid: started` when it starts; send it again only after a comment `vid: again s1`, or a refusal.\n'; } > "$K/s1body"
      i=$(gh_ grade-ask --stage "$N" --commit "$X" --title "Stage grade: stage $N, candidate $c" --body-file "$K/s1body") || die 'the S1 ask could not be posted'
      { printf 'issue\t%s\ncommit\t%s\nasked\t%s\nreqs\t%s\n' "$i" "$X" "$(stamp)" "$RQ"; [ "$FULL" = no ] || printf 'end\tyes\n'; } > "$K/s1ask"; echo "asked $i grade stage-$N"; fi; fi
  # the candidate's line once both are posted, or C3's alone
  # v0.26.10.26.2 (R1): naming a newer candidate withdraws the stage's earlier CS still out, which then counts as done
  [ -f "$K/named" ] || for o in $(ls "$SD/$N" | grep -E '^[0-9]+$'); do O=$SD/$N/$o/cs; [ "$o" -lt "$c" ] && [ -f "$O/ask" ] && [ ! -f "$O/done" ] && [ ! -f "$O/withdrawn" ] || continue
    i=$(sed -n "s/^issue$TAB//p" "$O/ask"); printf 'vid: withdrawn. Stage %s has a new candidate, %s; its rows run at that candidate'"'"'s staging run. A later report for this one is not read.\n' "$N" "$c" > .vid/round/wc
    gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || true; gh_ close "$i" > /dev/null 2>&1 || true; : > "$O/withdrawn"; ev "stage-cs-withdrawn stage=$N issue=$i"; done
  [ -f "$K/named" ] || sh "$HERE/walk.sh" withdraw --stage "$N" --below "$c" 2>/dev/null || true   # v0.26.10.26.4 (R1): and its older W1
  [ -f "$K/named" ] || { echo "candidate $N | stand-in: RM at $(printf %.12s "$X") candidate $c" >> "$HAND"; ev "stage-candidate stage=$N commit=$X candidate=$c"; : > "$K/named"; echo "candidate $N $c"; }; }
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
    sh "$HERE/results.sh" grade --stage "$N" > /dev/null 2> .vid/round/ce || die "S1 could not be read: $(tail -n 1 .vid/round/ce)"; set -- $(head -n 1 "$K/s1read" | tr '\t' ' ')
    case $2 in
      read) awk -F'\t' -v c="$c" '$1 == "grade" { print $2 "\t" $3 "\t" $4 > "/dev/stderr"; print $2 "\t" $3 "\t" c }' "$K/s1read" 2> "$SX/s1k" > "$SX/g" || exit 1; put "$K/s1" < "$SX/s1k" || exit 1
        touch "$SD/$N/s1"; awk -F'\t' 'FILENAME == ARGV[1] { n[$1] = $0; next } !($1 in n) { print } END { for (r in n) print n[r] }' "$SX/g" "$SD/$N/s1" | sort > "$SX/s1n" || exit 1; put "$SD/$N/s1" < "$SX/s1n" || exit 1
        grep -v '^lost s1 ' "$K/items" > "$SX/it" || true; put "$K/items" < "$SX/it" || exit 1; : > "$K/s1done"; gh_ close "$i" > /dev/null 2>&1 || true; ev "stage-s1 stage=$N candidate=$c graded=$(grep -c . "$K/s1")"; echo "s1 $N read" ;;
      refused) grep -qx "refused $3" "$K/s1again" 2>/dev/null || { printf 'vid: refused s1-%s\nby: RM\n\n%s\n' "$3" "$(cut -f4- "$K/s1read" | head -n 1)" > .vid/round/again; gh_ comment "$i" --body-file .vid/round/again > /dev/null 2>&1 && echo "refused $3" >> "$K/s1again"; echo "s1-refused $N $3"; } ;;
    esac
    if [ "$2" != read ]; then W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n { print $5 }' .vid/round/read 2>/dev/null); q=$(( $(date +%s) - $(epoch "${u:-$(stamp)}") ))
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
  # R4: each candidate's findings — every grade but pass, every finding line, every unmatched case
  { awk -F'\t' '$2 != "pass" { print "grade " $1 " " $2 " — " $3 }' "$K/s1" 2>/dev/null; sed -n "s/^finding$TAB//p" "$K/s1read" 2>/dev/null; awk -F'\t' '$1 == "unmatched" { print "unmatched " $2 " " $3 }' "$K/read" 2>/dev/null; } > "$SX/fn"; put "$K/findings" < "$SX/fn" || exit 1; return 0; }
# --- v0.26.10.26.2 (R1–R6): staging. D1, DevAgent's deploy on ViD's okay, in <c>/d1/; CS, the staging run, in <c>/cs/ ---
# sfree: staging holds no other candidate: every okay whose D1 passed has its CS done (or its candidate is no longer the stage's
# newest), and no okay is started with no report yet
sfree() { for O in $(ls -d "$SD"/*/*/d1 2>/dev/null); do [ -f "$O/ask" ] || continue; P=${O%/d1}; fx=${P%/*}; fx=${fx##*/}; fo=${P##*/}
    [ "$fo" = "$(snc "$fx")" ] || continue   # a superseded candidate's okay holds nothing: the next okay withdraws it
    if [ -f "$O/passed" ]; then [ -f "$P/cs/done" ] || [ -f "$P/cs/withdrawn" ] || return 1
      [ ! -f "$P/cs/passed" ] || wfin "$P/w1" || return 1   # v0.26.10.26.4 (R1): and its walk, where CS passed (0.26.10.28.6: any outcome)
    elif [ ! -f "$O/closed" ]; then i=$(sed -n "s/^issue$TAB//p" "$O/ask"); case $(head -n 1 "$O/read" 2>/dev/null | cut -f2) in ''|absent|refused) ;; *) continue ;; esac
      ! grep -q '^lost d1 ' "$O/items" 2>/dev/null || continue   # lost: it holds no more
      awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n && index($4, "vid: started") { f = 1 } END { exit !f }' "$RD" 2>/dev/null && return 1; fi; done; return 0; }
# okdue <N>: the newest candidate's C3 passed, it has no okay yet, and staging is free
okdue() { sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$1" '$1 > n { f = 1 } END { exit f }' || return 1; c=$(snc "$1"); F=$SD/$1/$c; [ -n "$c" ] && [ -f "$F/named" ] && [ ! -f "$F/withdrawn" ] && [ -f "$F/passed" ] && [ ! -f "$F/d1/ask" ] && afirst "$1" && sfree; }   # 0.26.10.29.2 (R2): none at a withdrawn candidate
# afirst <N> (v0.26.10.26.4 R4): once rows of stage N itself landed through the door since the previous candidate, or before the
# first, the okay waits for this candidate's S1 report read, when one was asked, and each of its S1 findings ruled
afirst() { [ -s "$D/landed" ] || return 0; upto "$1"; [ "$1" -lt 1 ] && : > "$SX/upa" || { upto "$(($1 - 1))"; cp "$SX/up$(($1 - 1))" "$SX/upa"; }; grep -vxF -f "$SX/upa" "$SX/up$1" > "$SX/own$1" || true; pa=''; [ "$c" -le 1 ] || pa=$(sed -n "s/^asked$TAB//p" "$SD/$1/$((c - 1))/ask" 2>/dev/null); b=$(sed -n "s/^asked$TAB//p" "$F/ask")
  awk -v a="$pa" -v b="$b" -v U="$SX/own$1" 'BEGIN { while ((getline l < U) > 0) W[l] = 1 } { id = $1; sub(/-T[0-9]+$/, "", id) } (id in W) && $3 >= a && $3 <= b { f = 1 } END { exit !f }' "$D/landed" || return 0
  [ -f "$F/s1ask" ] || return 0; [ -f "$F/s1done" ] || return 1; [ -f "$F/findings" ] || return 0; k=0
  while IFS= read -r l; do k=$((k + 1)); case $l in 'grade '*|'finding: '*) awk -F'\t' -v q="stage:$1:$c:$k" '$2 == q { f = 1 } END { exit !f }' "$D/queue/answers" 2>/dev/null || return 1 ;; esac; done < "$F/findings"; return 0; }
# 0.26.11.1.1 (R3): the hosting, quoted as the skeleton ticket quotes it (ARCHITECTURE.md's vid-hosting block, a `> ` line each), and
# the duties an okay names, `- <duty>: <what is asked>`, in plain words for an outside team; R6: the owner's newest seed word
hostq() { printf 'The hosting:\n'; { if manual; then cat "$(sf ARCHITECTURE.md)" 2>/dev/null; else git show HEAD:ARCHITECTURE.md 2>/dev/null || cat ARCHITECTURE.md 2>/dev/null; fi || true; } | sed -n '/^```vid-hosting[[:space:]]*$/,/^```[[:space:]]*$/p' | grep -v '^```' | grep '[^[:space:]]' | sed 's/^/> /' > "$SX/hq" || true
  if [ -s "$SX/hq" ]; then cat "$SX/hq"; else echo '> none'; fi; }
dutyq() { printf 'Duties:\n'; if [ "$1" = staging ]; then
    printf -- '- log-in: the log-in to the host works\n- environments: staging and production exist on the host, their versions pinned from the stack\n'
    printf -- '- outside-services: each outside service'"'"'s settings set by name, never a value, and its state recorded\n- sending-domain: the email domain'"'"'s records published, or each one named\n'
    printf -- '- deploy-notes: the deploy notes written: the services and their states, the allowed differences, rollback, the deploy log\n'
    printf -- '- captures: each real answer the last staging run'"'"'s outside-service tests got saved, and your tests of that service built on the saved answers from then on; before any staging run, not needed\n'
  else printf -- '- service-switch-on: each outside service changing moved one step, stand-in to limited to live, and recorded\n- backups: the host'"'"'s managed backups of production'"'"'s data on\n'
    printf -- '- point-in-time-recovery: point-in-time recovery on for production'"'"'s data\n- storage-versioning: versioning on for the files production stores\n- dns: the product'"'"'s domain points at production\n'
    printf -- '- https: production answers over https with a valid certificate\n- monitoring: production watched, and someone told when it stops answering\n'; fi
  # GM-4 E9 (GM M14, D7): in GitHub manual, with later work in the candidate (laterw), one duty more, the list under it
  [ ! -s "$SX/lw" ] || { printf -- '- later-work-off: the work listed below is off for the people using the product\n'; sed 's/^/  /' "$SX/lw"; }; }
# GM-4 E9 (GM M14, D7): laterw <N> <X>, in GitHub manual, the later work stage N's candidate X holds, one `- ` line each, into $SX/lw:
# each published ticket of a later stage, withdrawn or not (a withdrawal takes no merged work out of X) (its recorded writing's header, `- stage: <k>`) accepted at a commit X holds
# (its `step-` merge line, E4) or merged through a pull request in GitHub auto before the switch (its numeric merge line, in
# merged-prs), and each pull request of .vid/decide/unit-merges merged into X whose ticket, as E4 maps it (its sub-issues too), is of
# a later stage, by ticket. A pull request tied to no ticket is not listed. Empty outside GitHub manual
hstg() { awk '/^## / { h = ($0 ~ /^## Header[ \t]*$/); next } h && index($0, "- stage: ") == 1 { v = substr($0, 10); sub(/,.*/, "", v); gsub(/[ \t]/, "", v); print v; exit }' ".vid/tw/out/issue-$1.md" 2>/dev/null; }
laterw() { : > "$SX/lw"; manual || return 0; : > "$SX/lws"
  awk '$1 == "published" { P[$2] = 1 } END { for (n in P) print n }' "$LOG" 2>/dev/null | sort -n | while read -r t; do k=$(hstg "$t"); case $k in ''|*[!0-9]*) continue ;; esac; [ "$k" -gt "$1" ] && echo "$t $k"; done > "$SX/lws" || true
  # the merges on record, each of merged-prs: an acceptance (E4's `step-` line), or a pull request GitHub auto merged before the switch,
  # its ticket by the pull request's ticket line as auto recorded it
  [ ! -f "$D/merges" ] || while read -r t k; do awk -F'\t' -v t="$t" -v M="$D/merged-prs" 'BEGIN { while ((getline l < M) > 0) m[l] = 1 } ($1 in m) && $2 == t && $4 != "-" && $4 != "" { print $1 "\t" $4 }' "$D/merges" | while IFS=$TAB read -r p m; do
      if [ "$m" = "$2" ] || anc "$m" "$2"; then case $p in step-*) printf -- '- #%s, a stage %s ticket, accepted at %.12s\n' "$t" "$k" "$m" ;; *) printf -- '- pull request #%s, of #%s (stage %s), merged at %.12s\n' "$p" "$t" "$k" "$m" ;; esac; fi; done; done < "$SX/lws" >> "$SX/lw"
  # the units by their ticket as E4 maps them, decide.sh umap's one rule (its sub-issues too), a withdrawn ticket kept: its merged work is in X still
  [ ! -f "$D/unit-merges" ] || sh "$HERE/decide.sh" umap --withdrawn > "$SX/lwu" || exit 1
  [ ! -f "$D/unit-merges" ] || while IFS=$TAB read -r p t h m; do [ -n "$m" ] && [ "$m" != - ] || continue; k=$(awk -v t="$t" '$1 == t { print $2; exit }' "$SX/lws"); [ -n "$k" ] || continue
      if [ "$m" = "$2" ] || anc "$m" "$2"; then printf -- '- pull request #%s, of #%s (stage %s), merged at %.12s\n' "$p" "$t" "$k" "$m"; fi; done < "$SX/lwu" >> "$SX/lw"
  awk '!s[$0]++' "$SX/lw" > "$SX/lw1" && mv "$SX/lw1" "$SX/lw"; }
lwrec() { sed "s/^/later-work$TAB/" "$SX/lw"; }   # the okay's ask keeps the list, for the reader (results.sh: the duty later-work-off)
seedw() { w=$(awk -F'\t' '$2 == "control:seed" { v = $3 } END { print v }' "$D/queue/answers" 2>/dev/null); echo "${w:-synthetic}"; }
# 0.26.11.1.3 (R3): reals, stage N's open real checks at the candidate X, one a line, into $SX/real: stage 0's skeleton line always, then each
# `finding: real` line of the stage's tickets merged at or before X (each one's newest evidence), less each one an earlier okay of the
# stage listed whose D1 passed (a D1 passes only with each listed line done, or ruled by the owner)
SKL="skeleton: the skeleton's journey, end to end, where the product's people run it (their kind of machine, or the hosted site), on the real outside services and a real sign-in"
reals() { for O in $(ls -d "$SD/$N"/*/d1* 2>/dev/null); do [ -f "$O/passed" ] && sed -n "s/^real$TAB[0-9]*$TAB//p" "$O/ask" 2>/dev/null; done > "$SX/rk"
  { [ "$N" != 0 ] || echo "$SKL"; stix "$N" "$X" | while read -r t; do p=$(mrg "$t" | cut -d' ' -f1); case $p in step-*) [ ! -f ".vid/results/$p.txt" ] || echo ".vid/results/$p.txt" ;; ?*) ls -t .vid/results/pr-"$p"-*.txt 2>/dev/null | head -n 1 ;; esac; done | while read -r f; do sed -n 's/^finding: real — //p' "$f"; done | awk -v K="$SX/rk" 'BEGIN { while ((getline l < K) > 0) k[l] = 1 } !($0 in k)'; } | awk '!s[$0]++' > "$SX/real"; }
cmd_okay() { N=$1; okdue "$N" || die "no okay is due for stage $N"; X=$(cat "$F/commit"); DK=$F/d1; mkdir -p "$DK"
  # 0.26.11.1.1 (R4, R6): the seam rows CS would ask now, and the owner's newest seed word
  E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); set -- $E; P1=${1:-}; KN=cs; DW='owed-staging|seam'; mkdir -p "$SX/ok"; cssel "$SX/ok"
  RW=$(paste -sd ' ' "$SX/ok/seam"); SW=$(seedw); reals; laterw "$N" "$X"
  { printf 'okay: staging\ncommit: %s\nseed: %s\noutside-service rows: %s\n\n' "$X" "$SW" "${RW:-none}"
    printf 'Deploy this commit to staging, within the downtime tolerance the skeleton ticket'"'"'s hosting states. Report it as vid-results/deploy-<this issue>-<k>, by: DP, its commit the one above: report.txt with `outcome: passed` or `outcome: failed <step>`, and for a failed step `product change: yes` or `product change: no`; deploy.xml, one case per deploy step; and for a passed deploy staging.txt, with `staging: <address>`, one `signin: <role> <address>` line for each role you can sign in as, and one `differs: <what> — <on staging> — <on production>` line for each way staging differs from production beyond the head reports'"'"' stand-in: lines, or `differs: none`. Then comment `vid: reported d1-<k>` here; `vid: started` when you start. An owner-only step is your question here, labelled blocked.\n'
    # 0.26.11.1.1 (R1, R3, R4, R6): the further lines of a passed deploy, the seed's sentence, the hosting and the duties
    printf '\nIn staging.txt also: `seed: synthetic` or `seed: production`, as the seed above; for each outside-service row above, `seam: <row> real` when its outside service is the real one on this staging, or `seam: <row> stand-in — <why>`; and `stays: up` when staging stays up between deploys. When the product sends mail, also `mail: <address> — <how to read it>`, and when it acts on time, `clock: <address> — <how to move it>`: where the walker reads the mail and moves the clock on this staging, in your words. For a passed deploy also duties.txt: for each duty below, one line `<duty>: done — <what and where>`, `<duty>: not needed — <why>` or `<duty>: not done — <why>`.\n'
    [ "$SW" != production ] || printf '\nLoad a copy of production'"'"'s newest backup into staging in place of the made-up data, before the migration. It holds real customers'"'"' data: keep every outside service on staging limited, so nothing reaches a real person.\n'
    printf '\n'; hostq; printf '\n'; dutyq staging
    # 0.26.11.1.3 (R3): the real checks, each answered in staging.txt by a real: line keyed by this okay's issue
    [ ! -s "$SX/real" ] || { printf '\nProve it real: each check below shows only where the product'"'"'s people run it, so no test here can show it. Run each there, on their kind of machine or the hosted site, with the real outside services and a real sign-in, and answer it in staging.txt, one line each: `real: #<this issue>-<n> done — <what was run, where>`, or `real: #<this issue>-<n> not done — <why>`. On a hosted staging, deploy first, run the checks on it, then report again as this okay'"'"'s next attempt.\n'; awk '{ printf "- %d. %s\n", NR, $0 }' "$SX/real"; }
    manual || grep -q '^staged ' "$HAND" 2>/dev/null || grep -q '^setup-hold off ' "$HAND" 2>/dev/null || if [ "$((N + 1))" -le "$(finals)" ]; then printf '\nUntil this deploy passes, or the owner says continue, no ticket of stage %s is published.\n' "$((N + 1))"
      else printf '\nStage %s is the last stage: no later stage waits on this deploy.\n' "$N"; fi; } > "$DK/body"   # v0.26.10.26.7 (R2); v0.26.10.28.8 (R9): no stage named that does not exist; GM-4 K5 (D4): no hold in GitHub manual
  n=$(gh_ deploy-ask --stage "$N" --commit "$X" --title "Deploy to staging: stage $N, candidate $c" --body-file "$DK/body") || die 'the okay could not be posted'
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\nseed\t%s\nrows\t%s\n' "$n" "$X" "$(stamp)" "$SW" "$RW"; awk '{ printf "real\t%d\t%s\n", NR, $0 }' "$SX/real"; lwrec; } > "$DK/ask"; ev "stage-okay stage=$N candidate=$c issue=$n commit=$X"; echo "asked $n okay stage-$N"
  # an earlier okay still out with no D1 passed is withdrawn (V2 §5.7)
  for O in $(ls -d "$SD"/*/*/d1 2>/dev/null); do [ "$O" != "$DK" ] && [ -f "$O/ask" ] && [ ! -f "$O/passed" ] && [ ! -f "$O/closed" ] || continue; i=$(sed -n "s/^issue$TAB//p" "$O/ask")
    printf 'vid: withdrawn. A newer okay, #%s, takes staging; a later report for this one is not read.\n' "$n" > .vid/round/wc; gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || true; gh_ close "$i" > /dev/null 2>&1 || true
    echo "withdrawn by #$n" > "$O/closed"; ev "stage-okay-withdrawn issue=$i by=$n"; done; }
# nneed <kind> <read> (0.26.11.1.1, R3): the report's `not needed` duties, with their words, in one line, said once beside its passed line
nneed() { w=$(awk -F'\t' '$1 == "duty" && $3 == "not needed" { printf "%s%s — %s", (n++ ? "; " : ""), $2, $4 }' "$2"); [ -z "$w" ] || echo "not-needed $1 $N: $w"; }
# ditem <words> <n>: an item for the owner, numbered (#<issue * 1000 + n>) so one answered never hides a later one
ditem() { set -- "$1 #$((i * 1000 + $2))"; grep -qxF "$1" "$DK/items" 2>/dev/null || { echo "$1" >> "$DK/items"; ev "close-item step=staging-$N what=$(printf %s "$1" | cut -d' ' -f1-2 | tr ' ' '-')"; echo "d1-item $N $1"; }; }
dcom() { printf '%s\nby: RM\n%s' "$1" "${2:+
$2
}" > .vid/round/again; gh_ comment "$i" --body-file .vid/round/again > /dev/null 2>&1 || die "the okay #$i could not be commented"; }
allow() { grep -qxF "allow $1" "$DK/again" && { grep -vxF "allow $1" "$DK/again" > .vid/round/ag || true; put "$DK/again" < .vid/round/ag || exit 1; }; }
# d1_decide <N> <c>: the okay's newest report, on its form alone (R1, R3, R6)
kdecide() { KN=$1; shift; N=$1; F=$SD/$1/$2; DK=$F/$KN; [ -f "$DK/ask" ] && [ ! -f "$DK/passed" ] || return 0; i=$(sed -n "s/^issue$TAB//p" "$DK/ask"); touch "$DK/items" "$DK/again"
  if [ -f "$DK/closed" ]; then grep -q '^failed ' "$DK/closed" || return 0; st=$(sed -n 's/^failed //p' "$DK/closed")   # R3: a product change, through the door
    if allow declined; then j=1; while [ -d "$F/$KN-$j" ]; do j=$((j + 1)); done; mv "$DK" "$F/$KN-$j"; ev "stage-okay-again stage=$N candidate=$2 kind=$KN"; echo "$KN-again $N"; return 0; fi
    for W in $(grep -l "^$(echo "$KN" | tr a-z A-Z) #$i failed:" "$D"/drafts/*/why 2>/dev/null); do [ -f "${W%/why}/declined" ] && ditem "declined $KN at $st" 0; done; return 0; fi
  sh "$HERE/results.sh" deploy --stage "$N" --kind "$KN" --candidate "${F##*/}" > /dev/null 2> .vid/round/ce || die "$KN could not be read: $(tail -n 1 .vid/round/ce)"; set -- $(head -n 1 "$DK/read" | tr '\t' ' ')
  case $2 in
    no-backup) : > "$DK/passed"; : > "$DK/nobackup"; gh_ close "$i" > /dev/null 2>&1 || true; ev "stage-rh stage=$N issue=$i result=no-backup"; echo "rh $N no backup yet"; yesask; return 0 ;;   # v0.26.10.27.1 (R1): a first deploy
    passed) : > "$DK/passed"; X=$(sed -n "s/^commit$TAB//p" "$DK/ask"); [ "$KN" = d1 ] || gh_ close "$i" > /dev/null 2>&1 || true; [ "$KN" = d1 ] || { ev "stage-rh stage=$N issue=$i result=passed attempt=$3"; echo "rh $N passed"; return 0; }
      gh_ close "$i" > /dev/null 2>&1 || true; ev "stage-d1 stage=$N issue=$i result=passed attempt=$3"; echo "d1 $N passed"; nneed d1 "$DK/read"
      grep -q '^staged ' "$HAND" 2>/dev/null || { echo "staged $N | stand-in: D1 #$i at $(printf %.12s "$X")" >> "$HAND"; ev "stage-staged stage=$N issue=$i"; echo "staged $N"; }
      # R6: each new difference, by its <what>, against earlier D1s' differs: lines: one door line a D1
      ls "$SD"/*/*/d1*/read 2>/dev/null | grep -vxF "$DK/read" | while read -r f; do awk -F'\t' '$1 == "differs" { print $2 }' "$f"; done | sort -u > .vid/round/dk
      nw=$(awk -F'\t' 'FILENAME == ARGV[1] { K[$0] = 1; next } $1 == "differs" && !($2 in K) { printf "%s%s", (n++ ? "; " : ""), $2 " (production: " $4 ")" }' .vid/round/dk "$DK/read")
      [ -z "$nw" ] || { echo "$nw" > "$DK/door"; ev "stage-differs stage=$N issue=$i"; echo "door differs $N #$i: $nw"; } ;;
    failed) k=$3; st=$(head -n 1 "$DK/read" | cut -f4); pc=$(head -n 1 "$DK/read" | cut -f5)   # a step may hold spaces
      if [ "$pc" = yes ]; then echo "failed $st" > "$DK/closed"; dcom "vid: failed at $st" "It needs a product change, by your report: this okay is closed, and the change comes as a row the owner rules."; gh_ close "$i" > /dev/null 2>&1 || true
        ev "stage-$KN stage=$N issue=$i result=failed step=$(printf %s "$st" | tr ' ' '-') change=yes"; echo "door $KN-failed $N #$i at $st"; return 0; fi   # fields: stage-d1 stage-rh
      if grep -qxF "failed $k $st" "$DK/again"; then LATE=1
      elif awk -v s="$st" '$1 == "failed" { x = $0; sub(/^failed [0-9]+ /, "", x); if (x == s) f = 1 } END { exit !f }' "$DK/again" && ! allow failed; then ditem "failed $KN at $st" "$k"; return 0
      else dcom "vid: failed at $st: deploy again and report as attempt $((k + 1))" "Failed at $st, which you say needs no product change."; echo "failed $k $st" >> "$DK/again"; ev "stage-$KN stage=$N issue=$i result=failed step=$(printf %s "$st" | tr ' ' '-') change=no"; echo "$KN-failed $N $st"; fi ;;   # fields: stage-d1 stage-rh
    refused) k=$3; if ! grep -qx "refused $k" "$DK/again"; then
      if grep -q '^refused ' "$DK/again" && ! allow refused; then wr=$(cut -f4- "$DK/read" | head -n 1)
        case $KN:$wr in d1:'the duty '*' is not done: '*) du=${wr#the duty }; du=${du%% *}; ditem "notdone $du $wr" "$k" ;;
          d1:'the real check #'*' is not done: '*|d1:'staging.txt has no real: line for #'*) rn=${wr#*#}; rn=${rn#*-}; rn=${rn%%[!0-9]*}; ditem "notreal $rn $wr" "$k" ;;   # 0.26.11.1.3 (R3): a real check, keyed by its number
          *) ditem "refused $KN twice: $wr" "$k" ;; esac; return 0; fi   # 0.26.11.1.1 (R3): a duty not done, keyed by its duty
      dcom "vid: refused $KN-$k" "$(cut -f4- "$DK/read" | head -n 1)"; echo "refused $k" >> "$DK/again"; echo "$KN-refused $N $k"; return 0; fi; LATE=1 ;;
    absent) LATE=1 ;;
  esac
  # lateness (R1): no report, or a refused one already posted back, quiet past close-wait-minutes: `vid: again d1` once, then the owner's
  [ "${LATE:-}" = 1 ] || return 0; LATE=''; W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n { print $5 }' "$RD" 2>/dev/null); q=$(( $(date +%s) - $(epoch "${u:-$(stamp)}") ))
  if allow lost || { [ "$q" -ge "$W" ] && ! grep -qx "again $KN" "$DK/again"; }; then dcom "vid: again $KN"; echo "again $KN" >> "$DK/again"; echo "close-again staging-$N $KN"
  elif [ "$q" -ge "$W" ]; then ditem "lost $KN" "$(grep -c "^again $KN\$" "$DK/again")"; fi; return 0; }
d1_decide() { kdecide d1 "$@"; }
# cssel <folder> (0.26.11.1.1, R4): the rows the KN run of stage N asks at the candidate commit X, into <folder>/rows (`<row> <secs>`),
# its deploy-owed ones into owed and its seam rows into seam; the staging okay reads seam for its outside-service rows
cssel() { upto "$N"; psteps
  G0=$(plan_block | awk -F' [|] ' '{ for (i = 2; i <= NF; i++) if ($i == "kind: skeleton") { s = $1; sub(/^[ \t]*step[ \t]+/, "", s); print s; exit } }')
  awk -F'\t' -v s="$G0" '$1 == s { print $2 }' "$SX/ps" > "$SX/gp"
  awk '$1 == "published" { k[$2] = 1 } $1 == "withdrawn" { delete k[$2] } END { for (n in k) print n }' "$LOG" | sort -n | while read -r t; do m=$(mrg "$t" | cut -d' ' -f2); [ -n "$m" ] && { [ "$m" = "$X" ] || anc "$m" "$X"; } || continue
    awk '/^## / { x = substr($0, 4); next } x == "Rows" && /^> / { split(substr($0, 3), a, "|"); i = a[1]; gsub(/[ \t]/, "", i); if (i !~ /^[A-Z]+-[0-9]/) { i = a[2]; gsub(/[ \t]/, "", i) } print i } x == "Regression rows" && /^- [A-Z]+-[0-9]/ { print $2 }' ".vid/tw/out/issue-$t.md" 2>/dev/null; done | awk '!s[$0]++' > "$SX/cr"
  { cmd_owned "$KN-$N"; fxo; } > .vid/round/cx; : > "$1/rows"; : > "$1/owed"; : > "$1/seam"
  while read -r r; do mk=$(grep -h "^- $r marks: " $(tfile "$r") /dev/null 2>/dev/null | head -n 1); dw=''; printf '%s\n' "$mk" | grep -qE "(^|[ ;])($DW)(\$|[ ;])" && dw=1
    # v0.26.10.27.1 (R2, R5): CR's and CP's golden path is its rows that are not deploy-owed at all
    if [ -n "$dw" ]; then grep -qxF "$r" "$SX/up$N" || continue; else grep -qxF "$r" "$SX/gp" || continue; if [ "$KN" = cs ]; then ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])owed-(production|rehearsal)($|[ ;])' || continue; else ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])(owed-[a-z-]*|seam)($|[ ;])' || continue; fi; fi
    nt=$(awk -v r="$r" '($1 == "published" || $1 == "amended") { if (!($2 in o)) o[$2] = ++k; for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) R[$2] = substr($i, 6) } END { for (t in R) if (index("," R[t] ",", "," r ",") && o[t] > b) { b = o[t]; n = t } print n }' "$LOG"); if [ -n "$nt" ]; then nm=$(mrg "$nt" | cut -d' ' -f2); [ -n "$nm" ] && { [ "$nm" = "$X" ] || anc "$nm" "$X"; } || continue; fi
    limited "$r" || grep -qxF "$r" .vid/round/cx || { printf '%s %s\n' "$r" "$(secs "$r")" >> "$1/rows"; [ -z "$dw" ] || echo "$r" >> "$1/owed"; ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])seam($|[ ;])' || echo "$r" >> "$1/seam"; }; done < "$SX/cr"; }
# ask --cs <N> (R4): the golden path, and the seam and staging-owed rows of stages up to N; each of a ticket merged at or before the
# candidate whose newest ticket has merged, less limits and rows an open fix holds; chunked as C3, against staging
cmd_ask_cs() { N=$1; KN=${2:-cs}; c=$(snc "$N"); [ "$KN" != cp ] || c=$(for o in $(ls "$SD/$N" | grep -E '^[0-9]+$' | sort -n); do [ -f "$SD/$N/$o/d2/passed" ] && [ ! -f "$SD/$N/$o/cp/ask" ] && echo "$o"; done | tail -n 1); F=$SD/$N/$c; case $KN in cs) PQ=d1; DW='owed-staging|seam'; HD=staging; TL='Staging run' ;; cr) PQ=rh; DW='owed-rehearsal'; HD=rehearsal; TL='Rehearsal run' ;; cp) PQ=d2; DW='owed-production'; HD=production; TL='Production run' ;; esac
  [ -n "$c" ] && [ -f "$F/$PQ/passed" ] && [ ! -f "$F/$PQ/nobackup" ] || die "no $PQ has passed for stage $N's newest candidate"; K=$F/$KN; [ ! -f "$K/ask" ] || die "$KN is asked already for stage $N"
  E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); [ -n "$E" ] || die 'the handed record names no engines yet'; set -- $E; P1=$1; shift; P2=$*; M=$(skey close-chunk-minutes); M=${M:-20}
  X=$(cat "$F/commit"); case $KN in cs) A=$(sed -n "s/^staging$TAB//p" "$F/d1/read" | head -n 1) ;; cr) A=$(sed -n "s/^copy$TAB//p" "$F/rh/read" | head -n 1) ;; cp) A=$(sed -n "s/^production$TAB//p" "$F/d2/read" 2>/dev/null | head -n 1); [ -n "$A" ] || A=$(ls -t "$SD"/*/*/d2*/read 2>/dev/null | while read -r f; do sed -n "s/^production$TAB//p" "$f"; done | head -n 1) ;; esac; [ -n "$A" ] || die "no address for $KN"; mkdir -p "$K"; cssel "$K"
  [ -s "$K/rows" ] || { STG=$N; CK=$KN; n=none; : > "$K/passed"; : > "$K/done"; ev "stage-$KN stage=$N result=passed rows=0"; echo "$KN $N passed, no row to run"; [ "$KN" != cp ] || pgreen; [ "$KN" != cr ] || yesask; return 0; }   # fields: stage-cs stage-cr stage-cp
  awk -v m=$((M * 60)) '{ if (n && t + $2 > m) { n++; t = 0 } else if (!n) n = 1; t += $2; c[n] = c[n] (c[n] == "" ? "" : " ") $1 } END { for (i = 1; i <= n; i++) print i "\t" c[i] }' "$K/rows" > "$K/packed"
  { printf 'close: %s-%s\ncommit: %s\nagainst: %s\n' "$HD" "$N" "$X" "$A"; [ "$KN" = cp ] || awk -F'\t' '$1 == "signin" { print "signin: " $2 " " $3 }' "$F/$PQ/read"; printf 'engines: %s\n\n' "$E"
    [ "$KN" = cs ] || printf 'The %s run of stage %s'"'"'s closed candidate: against %s. %s\n\n' "$HD" "$N" "$([ "$KN" = cr ] && echo "the rehearsal copy's address, signed in through the lines above" || echo "production's address, signed in through your own production test accounts, which ViD never sees")" "Run the rows below as a staging run's, chunk by chunk, each chunk its own results report, vid-results/req-<this issue>-<chunk>-<k>, then comment \`vid: reported <chunk>-<k>\` here."
    printf 'The staging run of stage %s'"'"'s candidate: run these rows against the address above, signed in through the lines above, not in a clean checkout of your own; chunk by chunk, in the engines each chunk names, phase 1, the primary engine, first, then phase 2. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, by: TM, its commit the one above, a cases-<engine>.xml for each engine of the chunk, and a covers: line for each rule row, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`. Keep the staging up until this issue closes: ViD'"'"'s walk of the staging, W1, comes after this run.\n\n' "$N"
    while IFS=$TAB read -r k rows; do printf -- '- chunk p1c%s, %s: %s\n' "$k" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf -- '- chunk p2c%s, %s: %s\n' "$k" "$P2" "$rows"; done < "$K/packed"; } > "$K/body"
  n=$(gh_ run-ask --step "$HD-$N" --commit "$X" --title "$TL: stage $N, candidate $c" --body-file "$K/body") || die "the $KN ask could not be posted"
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\nagainst\t%s\n' "$n" "$X" "$(stamp)" "$A"; while IFS=$TAB read -r k rows; do printf 'chunk\tp1c%s\t%s\t%s\n' "$k" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf 'chunk\tp2c%s\t%s\t%s\n' "$k" "$P2" "$rows"; done < "$K/packed"; } > "$K/ask"
  ev "close-asked step=$HD-$N issue=$n commit=$X chunks=$(grep -c '^chunk' "$K/ask") ask=$c"; echo "asked $n $KN stage-$N"; }
# cs_paid (R5): each seam or staging-owed row the CS passed in every engine, paid; once each
cs_paid() { awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "chunk") { n = split($4, R, " "); m = split($3, E, " "); for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) W[R[i] SUBSEP E[j]] = 1 } next }
    $1 == "row" { if ($5 == "passed") P[$4 SUBSEP $3] = 1; else X[$4] = 1 }
    END { for (k in W) { split(k, a, SUBSEP); if (!(k in P)) X[a[1]] = 1; else Y[a[1]] = 1 } for (y in Y) if (!(y in X)) print y }' "$K/ask" "$K/read" | grep -xF -f "$K/owed" | while read -r r; do [ "$(hstate "$r")" = paid ] && continue
    # 0.26.11.1.1 (R4): at staging, a seam row is paid only when the candidate's passed D1 marks it real; else a stand-in item for the owner
    if [ "${CK:-cs}" = cs ] && grep -h "^- $r marks: " $(tfile "$r") /dev/null 2>/dev/null | head -n 1 | grep -qE '(^|[ ;])seam($|[ ;])' && ! awk -F'\t' -v r="$r" '$1 == "seam" && $2 == r && $3 == "real" { f = 1 } END { exit !f }' "$SD/$STG/$CSM/d1/read" 2>/dev/null; then
      wy=$(awk -F'\t' -v r="$r" '$1 == "seam" && $2 == r && $4 != "" { w = $4 } END { print (w == "" ? "not answered" : w) }' "$SD/$STG/$CSM/d1/read" 2>/dev/null)
      grep -q "^stand-in $r " "$K/items" 2>/dev/null || { echo "stand-in $r $wy #$n" >> "$K/items"; ev "close-item step=staging-$STG what=stand-in-$r"; echo "stand-in $STG $r — $wy"; }; continue; fi
    { grep -v "^row $r " "$HAND" || true; printf 'row %s paid | stand-in: %s #%s\n' "$r" "$(echo "${CK:-cs}" | tr a-z A-Z)" "$n"; } > .vid/round/h || exit 1; put "$HAND" < .vid/round/h || exit 1; ev "stage-paid stage=$STG row=$r issue=$n"; echo "paid $r"; done || exit 1; }
cs_green() { cs_paid; : > "$K/passed"; : > "$K/done"; [ "${CK:-cs}" = cs ] || gh_ close "$n" > /dev/null 2>&1 || true
  # 0.26.11.1.1 (R4): a CS asked afresh after the walk ended (a stand-in's again) closes its issue once read
  [ "${CK:-cs}" != cs ] || ! wfin "$SD/$STG/$CSM/w1" || { gh_ close "$n" > /dev/null 2>&1 && : > "$K/issue-closed"; }; ev "stage-${CK:-cs} stage=$STG result=passed issue=$n"; echo "stage-${CK:-cs} $STG passed"; [ "${CK:-cs}" != cp ] || pgreen; [ "${CK:-cs}" != cr ] || yesask; }   # v0.26.10.27.3 (8.1b R4): CS's issue closes at W1's end (walk.sh csclose) · # fields: stage-cs stage-cr stage-cp
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
# --- v0.26.10.27.1 (R1–R6): production. The rehearsal (RH, <c>/rh/), CR (<c>/cr/), the owner's yes (<c>/yes), the production okay
# (D2, <c>/d2/), CP (<c>/cp/), recovery and the interrupted deploy, at the newest closed candidate of any stage ---
PR=$D/production
pnow() { awk -F'\t' 'NF { c = $1 } END { print c }' "$PR" 2>/dev/null; }
pat() { awk -F'\t' 'NF { t = $3 } END { print t }' "$PR" 2>/dev/null; }
prec() { printf '%s\t%s\t%s\n' "$1" "$2" "$(stamp)" >> "$PR"; ev "production-commit commit=$1"; }
# lastc: `<N> <c>`, the newest closed candidate of any stage
lastc() { sed -n 's/^stage-closed \([0-9]*\) | stand-in: RM at [0-9a-f]* candidate \([0-9]*\).*/\1 \2/p' "$HAND" 2>/dev/null | tail -n 1; }
# rhcounts <folder>: its rehearsal was asked after production's commit was last recorded
rhcounts() { [ -f "$1/rh/ask" ] || return 1; a=$(sed -n "s/^asked$TAB//p" "$1/rh/ask"); p=$(pat); [ -z "$p" ] || [ "$a" \> "$p" ]; }
# rhdue: an okay rehearsal is owed at the newest closed candidate, not stage 0's, that has no rehearsal that counts
rhdue() { set -- $(lastc); [ $# = 2 ] && [ "$1" != 0 ] || return 1; N=$1; c=$2; F=$SD/$N/$c; [ "$c" = "$(snc "$N")" ] || return 1; ! rhcounts "$F" || return 1; [ ! -f "$F/d2/ask" ]; }
# prodnew <commit>: it descends from production's commit, or is it, or no production exists yet
prodnew() { p=$(pnow); [ -z "$p" ] || [ "$p" = none ] || [ "$1" = "$p" ] || anc "$p" "$1"; }
# pinhand: an earlier production okay still in hand (waiting on a report, or passed with its CP not green, or failed and not reconciled)
# psettled <candidate folder>: its production okay settled for good (recovered to another commit, or the owner's known); pdone: that,
# or its D2 (or a recovery to its own commit) passed and CP green; pinhand: an okay of any candidate not done
psettled() { [ -f "$1/d2/closed" ] && [ ! -f "$1/d2/atcand" ]; }
pdone() { psettled "$1" || { [ -f "$1/d2/passed" ] && [ -f "$1/cp/passed" ]; }; }
pinhand() { for O in $(ls -d "$SD"/*/*/d2 2>/dev/null); do [ -f "$O/ask" ] || continue; pdone "${O%/d2}" || return 0; done; return 1; }
# pprod <candidate folder>: its production okay out: not done, or settled with an `again` to act on
pprod() { [ -f "$1/d2/ask" ] || return 1; ! pdone "$1" || { psettled "$1" && grep -qxF 'allow again' "$1/d2/again" 2>/dev/null; }; }
# psettle <issue>: the interrupted deploy's line, if any, settled
psettle() { ! grep -q "^$1$TAB" "$D/production-lost" 2>/dev/null || awk -F'\t' -v i="$1" '$1 == i { l = $0 } END { split(l, x, "\t"); print x[1] "\t" x[2] "\t" x[3] "\tsettled" }' "$D/production-lost" >> "$D/production-lost"; }
yeskey() { echo "production:$N:$c:$(sed -n "s/^issue$TAB//p" "$F/rh/ask")"; }
yesd() { awk -F'\t' -v k="$(yeskey)" -v a="$(sed -n "s/^asked$TAB//p" "$F/rh/ask")" '$2 == k && $3 == "yes" && $5 != "RM" && $1 >= a { f = 1 } END { exit !f }' "$D/queue/answers" 2>/dev/null; }
pdue() { set -- $(lastc); [ $# = 2 ] && [ "$1" != 0 ] || return 1; N=$1; c=$2; F=$SD/$N/$c; [ "$c" = "$(snc "$N")" ] || return 1; [ ! -f "$F/d2/ask" ] || return 1
  X=$(cat "$F/commit"); prodnew "$X" || return 1; [ -f "$F/d1/passed" ] && [ -f "$F/cs/passed" ] && rhcounts "$F" || return 1
  if [ -f "$F/rh/nobackup" ]; then p=$(pnow); [ -z "$p" ] || [ "$p" = none ] || return 1; else [ -f "$F/rh/passed" ] && [ -f "$F/cr/passed" ] || return 1; fi
  yesd || return 1; ! pinhand; }
# yesask (R3): the owner's yes item, its words from the rehearsal's change.txt, at <c>/yes
yesask() { R0=$F/rh/read; [ -f "$R0" ] || return 0; X=$(cat "$F/commit")
  w=$(awk -F'\t' -v c="$(printf %.12s "$X")" '$1 == "migrates" { m = $2 } $1 == "drops" { d = d "; drops " $2 " — confirm" } $1 == "rewrites" { r = r "; rewrites " $2 " — confirm" } $1 == "services" { s = s (s == "" ? "" : ", ") $2 }
    $1 == "rh" && $2 == "no-backup" { nb = 1 } $1 == "kept" && $2 !~ /^none( |$)/ { k = k (k == "" ? "" : ", ") $2 }   # 0.26.11.1.1 (R5): the records kept
    END { printf "Rehearsal of %s: %smigrates %s%s%s; outside services changing: %s; records kept: %s. Deploy to production? yes or no", c, nb ? "no backup yet, the first deploy; " : "", (m == "" ? "no" : m), d, r, (s == "" ? "none" : s), (k == "" ? "none" : k) }' "$R0")
  printf '%s\t%s\n' "$(yeskey)" "$w" > "$SX/ys" || exit 1; put "$F/yes" < "$SX/ys" || exit 1; ev "production-asked stage=$N candidate=$c"; echo "production-yes-asked $N $c"; }
# okay --rehearsal|--production <N>: posted as 7.2's okay, at the newest closed candidate; staging's rules apply to staging okays alone
cmd_okay_p() { KN=$1; N=$2; set -- $(lastc); [ "${1:-}" = "$N" ] || die "stage $N has no newest closed candidate"; c=$2; F=$SD/$N/$c; X=$(cat "$F/commit")
  if [ "$KN" = rh ]; then rhdue || die "no rehearsal is owed for stage $N"; [ ! -d "$F/rh" ] || { j=1; while [ -d "$F/rh-$j" ]; do j=$((j + 1)); done; mv "$F/rh" "$F/rh-$j"; rm -rf "$F/cr" "$F/yes"; }
    B="Restore the newest production backup somewhere that is not production, sealed: no connection from it to anything outside it. Make it reachable only from where TM runs. Migrate it, boot it, and report vid-results/deploy-<this issue>-<k>, then \`vid: reported rh-<k>\`; \`vid: started\` when you start. Destroy the copy once its run is read or withdrawn. A first deploy, with no backup yet, reports so: \`outcome: no backup yet\`.

Before the migration, note every row of each table the product only ever adds to. After it, check each of those rows is still there, word for word, and report \`kept:\` lines. Report.txt holds one \`kept: <table> — <n> rows\` line a table, or the one line \`kept: none — <why>\`, and the step \`kept\` in deploy.xml, after migrate and before boot. A lost or changed row is \`outcome: failed kept\`."; T0=rehearsal
  else pdue || die "no production okay is owed for stage $N"
    B="Back up production first, and report it as the \`backup\` step. Deploy within the downtime tolerance the skeleton ticket's hosting states. Before any restore, ask here with the recovery point and the writes at risk. Report deploy-<this issue>-<k>, then \`vid: reported d2-<k>\`; \`vid: started\` when you start. For a passed deploy also duties.txt: for each duty below, one line \`<duty>: done — <what and where>\`, \`<duty>: not needed — <why>\` or \`<duty>: not done — <why>\`."; T0=production; fi
  laterw "$N" "$X"   # GM-4 E9: the later work the candidate holds, in GitHub manual
  mkdir -p "$F/$KN"; { printf 'okay: %s\ncommit: %s\n\n%s\n' "$T0" "$X" "$B"; [ "$KN" = rh ] || { printf '\n'; hostq; printf '\n'; dutyq production; }
    # GM-4 E9: the rehearsal deploys to a copy no one uses: it names the list and the duty, which its production okay carries to answer
    [ "$KN" != rh ] || [ ! -s "$SX/lw" ] || { printf '\nThis commit holds later work, listed below. Production'"'"'s okay will carry the duty later-work-off: the work listed below is off for the people using the product.\n'; cat "$SX/lw"; }; } > "$F/$KN/body"   # 0.26.11.1.1 (R3)
  i=$(gh_ deploy-ask --stage "$N" --commit "$X" --title "Deploy to $T0: stage $N, candidate $c" --body-file "$F/$KN/body") || die "the $T0 okay could not be posted"
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\n' "$i" "$X" "$(stamp)"; lwrec; } > "$F/$KN/ask"; ev "stage-okay stage=$N candidate=$c issue=$i commit=$X kind=$KN"; echo "asked $i okay $T0-$N"; }
# recovered <issue>: the commit of its newest `vid: recovered <commit|none> — …` comment
recovered() { awk -F'\t' -v n="$1" '$1 == "issue" && $2 == n { k = split($4, x, "\001"); for (j = 1; j <= k; j++) if (x[j] ~ /^vid: recovered /) { y = x[j]; sub(/^vid: recovered /, "", y); sub(/[ \t].*/, "", y); r = y } } END { print r }' "$RD" 2>/dev/null; }
# paddr: production's address, from the newest D2 report that names one; cpwd <candidate folder> <why>: an open CP withdrawn
paddr() { ls -t "$SD"/*/*/d2*/read 2>/dev/null | while read -r f; do sed -n "s/^production$TAB//p" "$f"; done | head -n 1; }
cpwd() { [ -f "$1/cp/ask" ] && [ ! -f "$1/cp/done" ] && [ ! -f "$1/cp/withdrawn" ] || return 0; j0=$(sed -n "s/^issue$TAB//p" "$1/cp/ask"); echo "$2" > "$1/cp/withdrawn"
  printf 'vid: withdrawn. %s: this run is not read.\nby: RM\n' "$2" > .vid/round/wc; gh_ comment "$j0" --body-file .vid/round/wc > /dev/null 2>&1 || true; gh_ close "$j0" > /dev/null 2>&1 || true; }
nrec() { awk -F'\t' -v n="$1" '$1 == "issue" && $2 == n { k = split($4, x, "\001"); for (j = 1; j <= k; j++) if (x[j] ~ /^vid: recovered /) r++ } END { print r + 0 }' "$RD" 2>/dev/null; }
started_() { awk -F'\t' -v n="$1" '$1 == "issue" && $2 == n && index($4, "vid: started") { f = 1 } END { exit !f }' "$RD" 2>/dev/null; }
# askrec: RM asks for recovery once on the okay
askrec() { [ -f "$DK/recovery-asked" ] && return 0; rm -f "$DK/recovery-lost"; dcom "Production failed at $1. Recover as you judge; before any restore, ask here first, with the recovery point and the writes at risk; comment \`vid: recovered <the commit production runs now, or none if no production exists yet> — <what you did>\` here." ""; : > "$DK/recovery-asked"; ev "production-recovery-asked stage=$N issue=$i"; echo "recovery-asked $N #$i"; }
# d2_decide <N> <c> (R4, R6): the report; a recovery or the owner's known settles it, final; a lost one the owner's at once
d2_decide() { N=$1; F=$SD/$1/$2; c=$2; DK=$F/d2; [ -f "$DK/ask" ] || return 0
  i=$(sed -n "s/^issue$TAB//p" "$DK/ask"); X=$(sed -n "s/^commit$TAB//p" "$DK/ask"); touch "$DK/items" "$DK/again"
  # settled for good (a recovery elsewhere, or the owner's known): its item; `again` re-arms an okay for c
  if psettled "$F"; then case $(cat "$DK/closed") in known*) ditem "production of $(printf %.12s "$X") reconciled at $(cut -d' ' -f2 "$DK/closed" | cut -c1-12): again re-arms its okay" 0 ;; esac
    allow again || return 0; j=1; while [ -d "$F/d2-$j" ]; do j=$((j + 1)); done; mv "$DK" "$F/d2-$j"; [ ! -d "$F/cp" ] || mv "$F/cp" "$F/cp-$j"; ev "stage-okay-again stage=$N candidate=$c kind=d2"; echo "d2-again $N"; return 0; fi
  # R6: the start comment's time, as first read, for the 25-hour wait
  if [ ! -f "$DK/started" ] && started_ "$i"; then : > "$DK/started"; fi
  # R6: a `vid: recovered` comment newer than the last one read: production's commit; closed as withdrawn; at the okay's own
  # candidate it counts as its D2, and a CP is owed again; elsewhere it is settled for good
  n=$(nrec "$i"); s0=$(cat "$DK/rseen" 2>/dev/null || echo 0); if [ "$n" -gt "$s0" ]; then echo "$n" > "$SX/rsn" || exit 1; put "$DK/rseen" < "$SX/rsn" || exit 1; rc=$(recovered "$i")
    [ "$rc" = none ] || git --git-dir=.vid/code rev-parse -q --verify "$rc^{commit}" > /dev/null 2>&1 || { echo "recovered-unread $N #$i: no commit named"; return 0; }   # a commit of the code, or none
    [ "$rc" = none ] && prec none "recovered #$i" || prec "$(git --git-dir=.vid/code rev-parse "$rc" 2>/dev/null || echo "$rc")" "recovered #$i"
    echo "recovered $rc" > "$SX/cl" || exit 1; put "$DK/closed" < "$SX/cl" || exit 1; rm -f "$DK/recovery-asked"; psettle "$i"; ev "production-recovered stage=$N issue=$i commit=$rc"; echo "recovered $N #$i at $rc"
    # at the okay's own commit: open until its CP is green, so a later recovery here is read; elsewhere: closed as withdrawn
    case $X in "$rc"*) [ "$rc" != none ] && [ -n "$(paddr)" ] && { : > "$DK/passed"; : > "$DK/atcand"; cpwd "$F" "a new production run follows the recovery"; [ ! -d "$F/cp" ] || mv "$F/cp" "$F/cp-r$n"
      printf 'Read: production runs this okay'"'"'s commit, %s, by your recovery; CP follows on it. Do not deploy this okay again.\nby: RM\n' "$rc" > .vid/round/wc; gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || true; return 0; } ;; esac
    printf 'vid: withdrawn. Do not deploy this okay again: production is recovered at %s.\nby: RM\n' "$rc" > .vid/round/wc; gh_ comment "$i" --body-file .vid/round/wc > /dev/null 2>&1 || true; gh_ close "$i" > /dev/null 2>&1 || true
    rm -f "$DK/atcand"; cpwd "$F" "production is recovered at $rc"; ditem "production of $(printf %.12s "$X") reconciled at $rc: again re-arms its okay" 0; return 0; fi
  # R6: a recovery asked and not commented after the run wait (25 hours) is the owner's, as a lost deploy is; its deploy reported
  if [ -f "$DK/recovery-asked" ] && [ ! -f "$DK/recovery-lost" ] && [ $(( $(date +%s) - $(stat -f %m "$DK/recovery-asked" 2>/dev/null || stat -c %Y "$DK/recovery-asked") )) -ge 90000 ]; then
    : > "$DK/recovery-lost"; printf '%s\t%s\t%s\treported\n' "$i" "$N" "$c" >> "$D/production-lost"; ev "production-lost stage=$N issue=$i"; echo "production-lost $N #$i"; fi
  [ ! -f "$DK/passed" ] && [ ! -f "$DK/failed" ] || return 0   # after a failed report, only a recovery or the owner settles it
  sh "$HERE/results.sh" deploy --stage "$N" --kind d2 --candidate "$c" > /dev/null 2> .vid/round/ce || die "D2 could not be read: $(tail -n 1 .vid/round/ce)"; set -- $(head -n 1 "$DK/read" | tr '\t' ' ')
  case $2 in
    passed) : > "$DK/passed"; prec "$X" "D2 #$i"; psettle "$i"; ev "stage-d2 stage=$N issue=$i result=passed"; echo "d2 $N passed"
      lg=$(sed -n "s/^logs$TAB//p" "$DK/read"); [ -z "$lg" ] || echo "logs $N: $lg"
      # 0.26.11.1.1 (R3): never refused for its duties; each missing or not done one the owner's (queue.sh), not needed said once
      awk -F'\t' -v n="$N" '$1 == "duty" && ($3 == "missing" || $3 == "not done") { print "production-duty " n " " $2 ": " ($3 == "missing" ? "not answered" : $4) }' "$DK/read"; nneed d2 "$DK/read" ;;
    failed) st=$(head -n 1 "$DK/read" | cut -f4); pc=$(head -n 1 "$DK/read" | cut -f5); echo "$st" > "$DK/failed"; askrec "$st"; ! grep -q "^$i$TAB" "$D/production-lost" 2>/dev/null || printf '%s\t%s\t%s\treported\n' "$i" "$N" "$c" >> "$D/production-lost"
      [ "$pc" != yes ] || [ -f "$DK/door" ] || { : > "$DK/door"; echo "door d2-failed $N #$i at $st"; } ;;
    refused) k=$3; grep -qx "refused $k" "$DK/again" || { dcom "vid: refused d2-$k" "$(cut -f4- "$DK/read" | head -n 1)"; echo "refused $k" >> "$DK/again"; echo "d2-refused $N $k"; } ;;
    absent) if [ -f "$DK/started" ]; then h=25; e=$(stat -f %m "$DK/started" 2>/dev/null || stat -c %Y "$DK/started"); else h=24; e=$(epoch "$(sed -n "s/^asked$TAB//p" "$DK/ask")"); fi
      [ $(( $(date +%s) - e )) -ge $((h * 3600)) ] || return 0
      grep -q "^$i$TAB" "$D/production-lost" 2>/dev/null && return 0; printf '%s\t%s\t%s\t%s\n' "$i" "$N" "$c" "$([ -f "$DK/started" ] && echo started || echo not-started)" >> "$D/production-lost"
      dcom "Production's deploy of $(printf %.12s "$X") has not reported: what does production run now? Comment \`vid: recovered <commit, or none> — <what you did>\` here." ""; ev "production-lost stage=$N issue=$i"; echo "production-lost $N #$i" ;;
  esac; return 0; }
# pgreen (R5): CP green: stages up to N in production
pgreen() { i0=$(sed -n "s/^issue$TAB//p" "$F/d2/ask"); X=$(cat "$F/commit"); cs_paid; gh_ close "$i0" > /dev/null 2>&1 || true   # v0.26.10.27.3: the production okay closes once CP is green
  grep -q "^production $STG | stand-in: D2 #$i0 " "$HAND" 2>/dev/null || { echo "production $STG | stand-in: D2 #$i0 at $(printf %.12s "$X")" >> "$HAND"; ev "production stage=$STG commit=$X"; echo "in production $STG at $(printf %.12s "$X")"; }; }
# why (R5): each stage with no candidate named and none due, what keeps it, counted by kind
cmd_why() { for x in $(sstages); do c=$(snc "$x"); [ -z "$c" ] || [ ! -f "$SD/$x/$c/named" ] || continue; ! sdue "$x" || continue; [ -s "$SX/why$x" ] || continue
    awk -v n="$x" '/ not merged$/ { a++ } / owed a ticket$/ { b++ } / failing$/ { c++ } / held$/ { d++ } / not decided$/ { e++ } / out$/ { f++ }
      END { printf "%s: no candidate yet", n; if (a) printf " · steps not merged %d", a; if (b) printf " · steps owed a ticket %d", b; if (c) printf " · rows failing %d", c; if (d) printf " · rows held %d", d; if (e) printf " · rows not yet decided %d", e; if (f) printf " · closes out %d", f; print "" }' "$SX/why$x"; done; }
# tclose <step> [<commit>] (GM-4 K3, GM M8: a step is decided on its ticket, so its tickets stay open until its close): in GitHub
# manual, once the step is closed, each open published ticket of it closed on GitHub with one comment, `vid: closed — the step's
# close passed at <commit12>`. Its record, <step>/tickets: `commit <c12>`, `commented <n>` once a ticket's comment posted, then
# `closed <n>` for each one closed, or found closed in the read (the team's, after the acceptance), so each is told once;
# `ticket-closed #<n>`, or `ticket-open #<n>` when the close failed, tried again at each owed and step. A ticket is open while the read shows it so (its `ticket` line, else an `issue` line),
# or when no read is kept
tclose() { manual || return 0; TF=$C/$1/tickets; mkdir -p "$C/$1"; [ -z "${2:-}" ] || [ -f "$TF" ] || printf 'commit %.12s\n' "$2" > "$TF"; [ -f "$TF" ] || return 0
  c12=$(sed -n 's/^commit //p' "$TF" | head -n 1); printf "vid: closed — the step's close passed at %s\n" "$c12" > .vid/round/tc
  for n in $(tix "$1" | cut -d' ' -f1 | sort -n); do grep -qx "closed $n" "$TF" && continue
    if [ -f "$RD" ] && ! awk -F'\t' -v n="$n" '$1 == "ticket" && $2 == n { t = 1; o = ($3 == "OPEN") } $1 == "issue" && $2 == n { i = 1 } END { exit !(t ? o : i) }' "$RD"; then echo "closed $n" >> "$TF"; continue; fi
    # the comment and the close recorded apart (`commented <n>`), so a close that failed after its comment posted is retried alone
    if { grep -qx "commented $n" "$TF" || { gh_ comment "$n" --body-file .vid/round/tc > /dev/null 2>&1 && echo "commented $n" >> "$TF"; }; } && gh_ close "$n" > /dev/null 2>&1; then echo "closed $n" >> "$TF"; ev "close-ticket-closed step=$1 issue=$n"; echo "ticket-closed #$n"; else echo "ticket-open #$n"; fi; done; return 0; }
# step <step> (GM-4 K3, /vid:vid-step-close): the step's close, its one entry in both modes. The step's withdrawn asks told first
# (reclose); out: the reports fetched (github.sh results-fetch) and the one read (round.sh read), then read as decide reads it, its
# lines as decide prints them; then, owed (owed1, its stage's candidate neither due nor named), asked as ask asks it. Neither:
# `refused <step>: <what is missing>`, nothing posted, exit 1. A closed step: its tickets' close finished (tclose), then refused
cmd_step() { reclose "$1"; s=$1; D0=''
  if closed "$s"; then tclose "$s"; echo "refused $s: closed already"; exit 1; fi
  if cmd_out | grep -qx "out $s"; then sh "$HERE/github.sh" results-fetch > /dev/null 2> .vid/round/se || { echo "refused $s: the reports could not be fetched: $(tail -n 1 .vid/round/se)"; exit 1; }
    sh "$HERE/round.sh" read 2> .vid/round/se || { echo "refused $s: the read failed: $(grep -v '^[[:space:]]*$' .vid/round/se | head -n 1)"; exit 1; }
    cmd_decide "$s"; D0=1; closed "$s" && return 0; fi
  if owed1 "$s"; then x=$(stof "$s")
    if [ -n "$x" ] && { sdue "$x" || grep -q "^candidate $x " "$HAND" 2>/dev/null; }; then WHY="stage $x's candidate is due or named: its close runs the step's rows"
    elif [ -z "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1)" ]; then WHY='the handed record names no engines yet'
    else cmd_ask "$1"; return 0; fi; fi   # $1: sdue sets s
  [ -z "$D0" ] || { echo "out $1 #$(akey issue)"; return 0; }
  echo "refused $1: ${WHY:-no close is owed}"; exit 1; }
# GM-4 K4 (/vid:vid-stage-close): the stage's end, in both modes. stage <N>, whichever is next by this file's conditions: the full run
# and the grade asked when due (sdue; ask --stage's lines); the walk started when due (walk.sh due; walk's lines), or read once its
# walker ended (walk.sh ended; walk.sh read's line); every close condition met (cconds), the summary's facts written while the
# candidate has no summary.md (summary's line, then `summary <N>`: its words are the skill's, from the facts), else the stage closed
# (close-stage's lines). Otherwise `refused stage <N>: <what is missing>`, nothing posted or written, exit 1. Each action alone:
# walk <N> (walk.sh brief, then walk.sh start, the walker a session of its own that no call waits for: `walk-brief <N> <folder>`,
# `walk-started <N> <pid>`), read-walk <N>, summary <N>
sref() { echo "refused stage $1: $2"; exit 1; }
num() { case ${1:-} in ''|*[!0-9]*) die "usage — $2 <N>: the stage by its number" ;; esac; }
sccw() { sed 's/^[0-9]* //' "$SX/cc$1" | paste -sd ';' - | sed 's/;/; /g'; }   # cconds's reasons, their numbers left out
wwhy() { c=$(snc "$1"); F=$SD/$1/$c; if [ -z "$c" ] || [ ! -f "$F/named" ]; then echo 'no candidate'; elif [ ! -f "$F/cs/passed" ]; then echo "its candidate $c's staging run, CS, has not passed"
  elif [ -f "$F/w1/none" ]; then echo "no walk is owed: $(head -n 1 "$F/w1/none")"; elif sh "$HERE/walk.sh" fin "$1" 2>/dev/null; then echo "candidate $c's walk has its outcome"; else rc=0; sh "$HERE/walk.sh" ended "$1" 2>/dev/null || rc=$?
    case $rc in 0) echo "candidate $c's walker ended: its walk is read next (read-walk $1)" ;; 3) echo "candidate $c's walker still runs" ;; *) echo "candidate $c's walk waits on the owner's answer" ;; esac; fi; }
cmd_walk() { num "$1" walk; N=$1; sh "$HERE/walk.sh" none "$N" > /dev/null 2>&1 || true; sh "$HERE/walk.sh" due "$N" 2>/dev/null || sref "$N" "no walk is due: $(wwhy "$N")"
  sh "$HERE/walk.sh" brief --stage "$N" > "$SX/wb" 2>&1 || sref "$N" "the walk's brief was not made: $(tail -n 1 "$SX/wb")"
  sh "$HERE/walk.sh" start --stage "$N" > "$SX/ws" 2>&1 || sref "$N" "the walker did not start: $(tail -n 1 "$SX/ws")"
  echo "walk-brief $N $(tail -n 1 "$SX/wb")"; echo "walk-started $N $(sed -n 's/^started //p' "$SX/ws")"; }
cmd_readwalk() { num "$1" read-walk; N=$1; sh "$HERE/walk.sh" ended "$N" 2>/dev/null || sref "$N" "no walk to read: $(wwhy "$N")"; sh "$HERE/walk.sh" read --stage "$N"; }
cmd_sumfacts() { num "$1" summary; N=$1; cconds "$N" || sref "$N" "$(sccw "$N")"; cmd_summary x "$N"; echo "summary $N"; }
cmd_stage() { num "$1" stage; N=$1
  if sdue "$N"; then [ -n "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1)" ] || sref "$N" 'the handed record names no engines yet'; cmd_ask_stage "$N"; return 0; fi
  WY=$(paste -sd ';' "$SX/why$N" | sed 's/;/; /g'); N=$1; c=$(snc "$N"); set -- $(sclosed "$N"); [ -z "$c" ] || [ "${2:-}" != "$c" ] || sref "$N" "closed already at $1"
  [ -n "$c" ] && [ -f "$SD/$N/$c/named" ] || sref "$N" "no candidate is due: ${WY:-its steps have no ticket on record}"
  if sh "$HERE/walk.sh" due "$N" 2>/dev/null; then sh "$HERE/walk.sh" none "$N" > /dev/null 2>&1 || true; ! sh "$HERE/walk.sh" due "$N" 2>/dev/null || { cmd_walk "$N"; return 0; }; fi   # the no-walk check first: no screens records W1 none
  if sh "$HERE/walk.sh" ended "$N" 2>/dev/null; then sh "$HERE/walk.sh" read --stage "$N"; return 0; fi
  if cconds "$N"; then if [ -s "$SD/$N/$c/summary.md" ]; then cmd_close_stage x "$N"; else cmd_summary x "$N"; echo "summary $N"; fi; return 0; fi
  sref "$N" "$(sccw "$N")"; }
# GM-4 K5 (/vid:vid-deploy, in both GitHub modes): deploy staging [<N>], the staging okay posted when one is due (okdue; the highest
# stage's, or stage N's), its lines as okay --stage prints them; else `refused staging: <what is missing>`, nothing posted, exit 1.
# deploy production "<words>": the owner's production yes, the one way to give it here: the open `production:<N>:<c>:<issue>` item of
# the newest closed candidate (its rehearsal passed, `production-yes-asked`) answered yes in the owner's words (queue.sh answer, the
# owner's alone), `yes production <N> <c>`; the next round's owed lines post the production okay (okay production <N>). Else
# `refused production: <why>`, exit 1
okwhy() { c=$(snc "$1"); F=$SD/$1/$c
  if sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$1" '$1 > n { f = 1 } END { exit !f }'; then echo "a later stage's candidate is named: its okay takes staging"
  elif [ -z "$c" ] || [ ! -f "$F/named" ]; then echo "stage $1 has no candidate named"; elif [ -f "$F/withdrawn" ]; then echo "its candidate $c was withdrawn by a re-cut"
  elif [ ! -f "$F/passed" ]; then echo "its candidate $c's full run, C3, has not passed"; elif [ -f "$F/d1/ask" ]; then echo "its candidate $c's staging okay, #$(sed -n "s/^issue$TAB//p" "$F/d1/ask"), is asked already"
  elif ! afirst "$1"; then echo "rows of stage $1 landed since its previous candidate: the okay waits for candidate $c's grade read and each of its findings ruled"
  else echo "staging is taken: another candidate's okay, staging run or walk is not done"; fi; }
cmd_deploy() { case ${1:-} in
  staging) shift; if [ -n "${1:-}" ]; then num "$1" 'deploy staging'; o=$1; okdue "$o" || { echo "refused staging: stage $o: $(okwhy "$o")"; exit 1; }
    else o=''; for x in $(ls "$SD" 2>/dev/null | sort -n); do ! okdue "$x" || o=$x; done
      if [ -z "$o" ]; then x=''; for y in $(ls "$SD" 2>/dev/null | sort -n); do [ -n "$(snc "$y")" ] && x=$y; done
        [ -n "$x" ] || { echo 'refused staging: no stage has a candidate yet'; exit 1; }; echo "refused staging: stage $x: $(okwhy "$x")"; exit 1; fi; fi
    cmd_okay "$o" ;;
  production) shift; [ $# -eq 1 ] && [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ] || { echo "refused production: the production yes is given only with the owner's own words, as deploy production \"<words>\""; exit 1; }
    set -- "$1" $(lastc); [ $# = 3 ] && [ "$2" != 0 ] || { echo 'refused production: no stage is closed: its candidate goes to production once closed and rehearsed'; exit 1; }
    W0=$1; N=$2; c=$3; F=$SD/$N/$c; [ "$c" = "$(snc "$N")" ] || { echo "refused production: stage $N has a newer candidate than the closed one, $c"; exit 1; }
    [ ! -f "$F/d2/ask" ] || { echo "refused production: stage $N's production okay, #$(sed -n "s/^issue$TAB//p" "$F/d2/ask"), is posted already"; exit 1; }
    [ -f "$F/rh/ask" ] && [ -s "$F/yes" ] || { echo "refused production: no production yes is asked: stage $N's rehearsal has not passed"; exit 1; }
    ! yesd || { echo "refused production: stage $N's production yes is given already: the next round posts the production okay"; exit 1; }
    k=$(cut -f1 "$F/yes"); sh "$HERE/queue.sh" sync > /dev/null 2>&1 || true; sh "$HERE/queue.sh" answer "$k" yes "$W0" > "$SX/py" 2>&1 || { echo "refused production: $(grep -v '^[[:space:]]*$' "$SX/py" | tail -n 1 | sed 's/^ViD queue: //')"; exit 1; }
    echo "yes production $N $c: in the owner's words; the next round's owed lines post the production okay" ;;
  *) die 'usage — deploy staging [<N>] | deploy production "<words>"' ;; esac; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in owed) cmd_owed ;; out) cmd_out ;; owned) cmd_owned ;; why) cmd_why ;;
  ask) [ -n "${1:-}" ] || die 'usage — ask <step> | --stage <N> | --cs <N>'; case $1 in --stage) cmd_ask_stage "${2:?}" ;; --cs) cmd_ask_cs "${2:?}" ;; --cr) cmd_ask_cs "${2:?}" cr ;; --cp) cmd_ask_cs "${2:?}" cp ;; *) cmd_ask "$1" ;; esac ;;
  okay) case ${1:-} in --stage) cmd_okay "${2:?}" ;; --rehearsal) cmd_okay_p rh "${2:?}" ;; --production) cmd_okay_p d2 "${2:?}" ;; *) die 'usage — okay --stage|--rehearsal|--production <N>' ;; esac ;;
  close-stage) [ "${1:-}" = --stage ] || die 'usage — close-stage --stage <N>'; cmd_close_stage "$@" ;;
  summary) if [ "${1:-}" = --stage ]; then cmd_summary "$@"; else [ $# -eq 1 ] || die 'usage — summary --stage <N> | summary <N>'; cmd_sumfacts "$1"; fi ;;
  stage) [ $# -eq 1 ] || die 'usage — stage <N>'; cmd_stage "$1" ;;   # GM-4 K4
  deploy) cmd_deploy "$@" ;;   # GM-4 K5
  walk) [ $# -eq 1 ] || die 'usage — walk <N>'; cmd_walk "$1" ;;
  read-walk) [ $# -eq 1 ] || die 'usage — read-walk <N>'; cmd_readwalk "$1" ;;
  conds) cconds "${1:?}"; cat "$SX/cc$1" ;;
  endconds) endconds && rc=0 || rc=1; cat "$SX/end"; exit $rc ;;   # v0.26.10.27.4 (R2)
  nextplan) cmd_nextplan ;;
  step-stages) sst; cat "$SX/sst" ;;   # 0.26.10.29.2 (R9): `<step> TAB <stage>`, each step's stage by this file's rule (sst), for land.sh
  corrected) N0=${1:?}; set -- $(sclosed "$N0") ; [ -n "${1:-}" ] || exit 1; X=$(git --git-dir=.vid/code rev-parse "$1" 2>/dev/null); srows "$N0" > "$SX/crw"
    while IFS=$TAB read -r p t H M; do [ -n "$M" ] && [ "$M" != - ] || continue; [ "$M" = "$X" ] || anc "$M" "$X" && continue; trows "$t" | grep -qxF -f "$SX/crw" && exit 0; done < "$D/merges"; exit 1 ;;
  step) [ $# -eq 1 ] || die 'usage — step <step>'; cmd_step "$1" ;;
  decide) [ -n "${1:-}" ] || die 'usage — decide <step> | --stage <N>'; case $1 in --stage) cmd_decide_stage "${2:?}" ;; stage-*) cmd_decide_stage "${1#stage-}" ;; *) cmd_decide "$1" ;; esac ;;
  *) echo 'usage: sh checks/close.sh owed|out|owned|step <step>|stage <N>|walk <N>|read-walk <N>|summary <N>|deploy staging [<N>]|deploy production "<words>"|ask <step>|--stage <N>|--cs <N>|okay --stage <N>|decide <step>|--stage <N>' >&2; exit 2 ;; esac

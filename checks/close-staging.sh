#!/bin/sh
# Purpose: close.sh's part — staging: D1, DevAgent's deploy on ViD's okay, and CS, the staging run (FB-2 C3). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
# --- v0.26.10.26.2 (R1–R6): staging. D1, DevAgent's deploy on ViD's okay, in <c>/d1/; CS, the staging run, in <c>/cs/ ---
# sfree: staging holds no other candidate: every okay whose D1 passed has its CS done (or its candidate is no longer the stage's
# newest), and no okay is started with no report yet; FB-2 A4: nor a take-down of the test site posted and not read. SWHY says what holds it
sfree() { SWHY=''; i0=$(dnin staging) && { SWHY="its take-down, #$i0, is not reported yet"; return 1; }
  for O in $(ls -d "$SD"/*/*/d1 2>/dev/null); do [ -f "$O/ask" ] || continue; P=${O%/d1}; fx=${P%/*}; fx=${fx##*/}; fo=${P##*/}
    [ "$fo" = "$(snc "$fx")" ] || continue   # a superseded candidate's okay holds nothing: the next okay withdraws it
    if [ -f "$O/passed" ]; then [ -f "$P/cs/done" ] || [ -f "$P/cs/withdrawn" ] || { SWHY="stage $fx's candidate $fo's staging run, CS, is not done"; return 1; }
      [ ! -f "$P/cs/passed" ] || wfin "$P/w1" || { SWHY="stage $fx's candidate $fo's walk is not done"; return 1; }   # v0.26.10.26.4 (R1): and its walk, where CS passed (0.26.10.28.6: any outcome)
    elif [ ! -f "$O/closed" ]; then i=$(sed -n "s/^issue$TAB//p" "$O/ask"); case $(head -n 1 "$O/read" 2>/dev/null | cut -f2) in ''|absent|refused) ;; *) continue ;; esac
      ! grep -q '^lost d1 ' "$O/items" 2>/dev/null || continue   # lost: it holds no more
      awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n && index($4, "vid: started") { f = 1 } END { exit !f }' "$RD" 2>/dev/null && { SWHY="the staging okay #$i is started and not reported yet"; return 1; }; fi; done; return 0; }
# okdue <N>: the newest candidate's C3 passed, it has no okay yet, and staging is free
okdue() { sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" 2>/dev/null | awk -v n="$1" '$1 > n { f = 1 } END { exit f }' || return 1; c=$(snc "$1"); F=$SD/$1/$c; [ -n "$c" ] && [ -f "$F/named" ] && [ ! -f "$F/withdrawn" ] && [ -f "$F/passed" ] && [ ! -f "$F/d1/ask" ] && ! bheld "$1" "$F" > /dev/null && afirst "$1" && sfree; }   # 0.26.10.29.2 (R2): none at a withdrawn candidate
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
  if [ "$KN" = cs ]; then : > .vid/round/cx; else { cmd_owned "$KN-$N"; fxo; } > .vid/round/cx; fi; : > "$1/rows"; : > "$1/owed"; : > "$1/seam"; : > "$SX/lm"
  while read -r r; do mk=$(grep -h "^- $r marks: " $(tfile "$r") /dev/null 2>/dev/null | head -n 1); dw=''; printf '%s\n' "$mk" | grep -qE "(^|[ ;])($DW)(\$|[ ;])" && dw=1
    # v0.26.10.27.1 (R2, R5): CR's and CP's golden path is its rows that are not deploy-owed at all
    # FB-7 A3: a known limit is still run; CP's golden path asks one marked owed-staging or seam too, what could not be shown on the test site
    lim=''; ! limited "$r" || { lim=1; echo "$r" >> "$SX/lm"; }; lp=''; [ "$KN" != cp ] || [ -z "$lim" ] || ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])(owed-staging|seam)($|[ ;])' || lp=1
    if [ -n "$dw$lp" ]; then grep -qxF "$r" "$SX/up$N" || continue; else grep -qxF "$r" "$SX/gp" || continue; if [ "$KN" = cs ]; then ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])owed-(production|rehearsal)($|[ ;])' || continue; else ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])(owed-[a-z-]*|seam)($|[ ;])' || continue; fi; fi
    nt=$(awk -v r="$r" '($1 == "published" || $1 == "amended") { if (!($2 in o)) o[$2] = ++k; for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) R[$2] = substr($i, 6) } END { for (t in R) if (index("," R[t] ",", "," r ",") && o[t] > b) { b = o[t]; n = t } print n }' "$LOG"); if [ -n "$nt" ]; then nm=$(mrg "$nt" | cut -d' ' -f2); if [ -n "$nm" ] || [ "$KN" != cs ]; then [ -n "$nm" ] && { [ "$nm" = "$X" ] || anc "$nm" "$X"; } || continue; fi; fi   # FB-7 A2: the staging run asks a row whose newest ticket is open
    grep -qxF "$r" .vid/round/cx || { printf '%s %s\n' "$r" "$(secs "$r")" >> "$1/rows"; [ -z "$dw" ] || echo "$r" >> "$1/owed"; [ -n "$lim" ] || ! printf '%s\n' "$mk" | grep -qE '(^|[ ;])seam($|[ ;])' || echo "$r" >> "$1/seam"; }; done < "$SX/cr"; }
# ask --cs <N> (R4): the golden path, and the seam and staging-owed rows of stages up to N; each of a ticket merged at or before the
# candidate, less, in CR and CP, rows whose newest ticket has not merged or an open fix holds (FB-7 A2); chunked as C3, against staging
cmd_ask_cs() { N=$1; KN=${2:-cs}; c=$(snc "$N"); [ "$KN" != cp ] || c=$(for o in $(ls "$SD/$N" | grep -E '^[0-9]+$' | sort -n); do [ -f "$SD/$N/$o/d2/passed" ] && [ ! -f "$SD/$N/$o/cp/ask" ] && echo "$o"; done | tail -n 1); F=$SD/$N/$c; case $KN in cs) PQ=d1; DW='owed-staging|seam'; HD=staging; TL='Staging run' ;; cr) PQ=rh; DW='owed-rehearsal'; HD=rehearsal; TL='Rehearsal run' ;; cp) PQ=d2; DW='owed-production'; HD=production; TL='Production run' ;; esac
  [ -n "$c" ] && [ -f "$F/$PQ/passed" ] && [ ! -f "$F/$PQ/nobackup" ] || die "no $PQ has passed for stage $N's newest candidate"; K=$F/$KN; [ ! -f "$K/ask" ] || die "$KN is asked already for stage $N"
  [ "$KN" != cs ] || ! _hr=$(bheld "$N" "$F") || die "no staging run for stage $N's candidate: row $_hr landed, not decided"   # FB-7 A1
  E=$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' "$HAND" | tail -n 1); [ -n "$E" ] || die 'the handed record names no engines yet'; set -- $E; P1=$1; shift; P2=$*; M=$(skey close-chunk-minutes); M=${M:-20}
  X=$(cat "$F/commit"); case $KN in cs) A=$(sed -n "s/^staging$TAB//p" "$F/d1/read" | head -n 1) ;; cr) A=$(sed -n "s/^copy$TAB//p" "$F/rh/read" | head -n 1) ;; cp) A=$(sed -n "s/^production$TAB//p" "$F/d2/read" 2>/dev/null | head -n 1); [ -n "$A" ] || A=$(ls -t "$SD"/*/*/d2*/read 2>/dev/null | while read -r f; do sed -n "s/^production$TAB//p" "$f"; done | head -n 1) ;; esac; [ -n "$A" ] || die "no address for $KN"; mkdir -p "$K"; cssel "$K"; packs "$K" "$SX/lm"   # FB-7 A3: with known limits alone, no row
  [ -s "$K/rows" ] || { STG=$N; CK=$KN; n=none; : > "$K/passed"; : > "$K/done"; ev "stage-$KN stage=$N result=passed rows=0"; echo "$KN $N passed, no row to run"; [ "$KN" != cp ] || pgreen; [ "$KN" != cr ] || yesask; return 0; }   # fields: stage-cs stage-cr stage-cp
  { printf 'close: %s-%s\ncommit: %s\nagainst: %s\n' "$HD" "$N" "$X" "$A"; [ "$KN" = cp ] || awk -F'\t' '$1 == "signin" { print "signin: " $2 " " $3 }' "$F/$PQ/read"; printf 'engines: %s\n\n' "$E"
    [ "$KN" = cs ] || printf 'The %s run of stage %s'"'"'s closed candidate: against %s. %s\n\n' "$HD" "$N" "$([ "$KN" = cr ] && echo "the rehearsal copy's address, signed in through the lines above" || echo "production's address, signed in through your own production test accounts, which ViD never sees")" "Run the rows below as a staging run's, chunk by chunk, each chunk its own results report, vid-results/req-<this issue>-<chunk>-<k>, then comment \`vid: reported <chunk>-<k>\` here."
    printf 'The staging run of stage %s'"'"'s candidate: run these rows against the address above, signed in through the lines above, not in a clean checkout of your own; chunk by chunk, in the engines each chunk names, phase 1, the primary engine, first, then phase 2. Report each chunk as its own results report, vid-results/req-<this issue>-<chunk>-<k>, %s, and a covers: line for each rule row, then comment `vid: reported <chunk>-<k>` here. Comment `vid: started` when the first chunk starts. Run a chunk again only after a comment `vid: again <chunk>`. Keep the staging up until this issue closes: ViD'"'"'s walk of the staging, W1, comes after this run.\n\n' "$N" "$(crep)"   # FB-3 A1.5
    while IFS=$TAB read -r k rows; do printf -- '- chunk p1c%s, %s: %s\n' "$k" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf -- '- chunk p2c%s, %s: %s\n' "$k" "$P2" "$rows"; done < "$K/packed"; } > "$K/body"
  n=$(gh_ run-ask --step "$HD-$N" --commit "$X" --title "$TL: stage $N, candidate $c" --body-file "$K/body") || die "the $KN ask could not be posted"
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\nagainst\t%s\n' "$n" "$X" "$(stamp)" "$A"; while IFS=$TAB read -r k rows; do printf 'chunk\tp1c%s\t%s\t%s\n' "$k" "$P1" "$rows"; done < "$K/packed"
    [ -z "$P2" ] || while IFS=$TAB read -r k rows; do printf 'chunk\tp2c%s\t%s\t%s\n' "$k" "$P2" "$rows"; done < "$K/packed"; } > "$K/ask"
  ev "close-asked step=$HD-$N issue=$n commit=$X chunks=$(grep -c '^chunk' "$K/ask") ask=$c"; echo "asked $n $KN stage-$N"; }
# cs_paid (R5): each seam or staging-owed row the CS passed in every engine, paid; once each
cs_paid() { awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "chunk") { n = split($4, R, " "); m = split($3, E, " "); for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) W[R[i] SUBSEP E[j]] = 1 } next }
    $1 == "row" { if ($5 == "passed") P[$4 SUBSEP $3] = 1; else X[$4] = 1 }
    END { for (k in W) { split(k, a, SUBSEP); if (!(k in P)) X[a[1]] = 1; else Y[a[1]] = 1 } for (y in Y) if (!(y in X)) print y }' "$K/ask" "$K/read" | grep -xF -f "$K/owed" | while read -r r; do [ "$(hstate "$r")" = paid ] && continue; ! limited "$r" || continue   # FB-7 A3: nothing is paid by a known limit, nor a stand-in of it asked
    # 0.26.11.1.1 (R4): at staging, a seam row is paid only when the candidate's passed D1 marks it real; else a stand-in item for the owner
    if [ "${CK:-cs}" = cs ] && grep -h "^- $r marks: " $(tfile "$r") /dev/null 2>/dev/null | head -n 1 | grep -qE '(^|[ ;])seam($|[ ;])' && ! awk -F'\t' -v r="$r" '$1 == "seam" && $2 == r && $3 == "real" { f = 1 } END { exit !f }' "$SD/$STG/$CSM/d1/read" 2>/dev/null; then
      wy=$(awk -F'\t' -v r="$r" '$1 == "seam" && $2 == r && $4 != "" { w = $4 } END { print (w == "" ? "not answered" : w) }' "$SD/$STG/$CSM/d1/read" 2>/dev/null)
      grep -q "^stand-in $r " "$K/items" 2>/dev/null || { echo "stand-in $r $wy #$n" >> "$K/items"; ev "close-item step=staging-$STG what=stand-in-$r"; echo "stand-in $STG $r — $wy"; }; continue; fi
    { grep -v "^row $r " "$HAND" || true; printf 'row %s paid | stand-in: %s #%s\n' "$r" "$(echo "${CK:-cs}" | tr a-z A-Z)" "$n"; } > .vid/round/h || exit 1; put "$HAND" < .vid/round/h || exit 1; ev "stage-paid stage=$STG row=$r issue=$n"; echo "paid $r"; done || exit 1; }
cs_green() { cs_paid; : > "$K/passed"; : > "$K/done"; [ "${CK:-cs}" = cs ] || gh_ close "$n" > /dev/null 2>&1 || true
  # 0.26.11.1.1 (R4): a CS asked afresh after the walk ended (a stand-in's again) closes its issue once read
  [ "${CK:-cs}" != cs ] || ! wfin "$SD/$STG/$CSM/w1" || { gh_ close "$n" > /dev/null 2>&1 && : > "$K/issue-closed"; }; ev "stage-${CK:-cs} stage=$STG result=passed issue=$n"; echo "stage-${CK:-cs} $STG passed"; [ "${CK:-cs}" != cp ] || pgreen; [ "${CK:-cs}" != cr ] || yesask; }   # v0.26.10.27.3 (8.1b R4): CS's issue closes at W1's end (walk.sh csclose) · # fields: stage-cs stage-cr stage-cp

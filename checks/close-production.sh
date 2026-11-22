#!/bin/sh
# Purpose: close.sh's part — production: the rehearsal RH, CR, the owner's yes, D2 and CP (FB-2 C3), then the take-down of the test site or the live copy (FB-2 A4). Sourced by checks/close.sh beside it, never run alone: its functions share close.sh's shell, records and variables.
# serves: tickets
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
# or its D2 (or a recovery to its own commit) passed and CP green; pinhand: an okay of any candidate not done, or (FB-2 A4) a take-down
# of the live copy posted and not read
psettled() { [ -f "$1/d2/closed" ] && [ ! -f "$1/d2/atcand" ]; }
pdone() { psettled "$1" || { [ -f "$1/d2/passed" ] && [ -f "$1/cp/passed" ]; }; }
pinhand() { dnin production > /dev/null && return 0; for O in $(ls -d "$SD"/*/*/d2 2>/dev/null); do [ -f "$O/ask" ] || continue; pdone "${O%/d2}" || return 0; done; return 1; }
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
# --- FB-2 A4: the take-down, `deploy down staging "<words>" | deploy down production "<words>"`, at the owner's explicit word alone: an okay labelled <prefix>deploy for the dev side's
# take-down of the test site, or of the live copy where it is a copy on this machine, in <c>/dn-<target>/ (ask, body, read, again, done,
# down or failed); an earlier one of that target at that candidate moved to dn-<target>-<j>. A real live product on a host is never taken down ---
# dnin <target>: the issue of a take-down of that target posted and its report not read yet
dnin() { for O in $(ls -d "$SD"/*/*/dn-"$1" 2>/dev/null); do [ -f "$O/ask" ] && [ ! -f "$O/done" ] && { sed -n "s/^issue$TAB//p" "$O/ask"; return 0; }; done; return 1; }
# dndown <candidate folder> <target> <since>: a take-down of that target there read down, asked at or after since
dndown() { for O in "$1/dn-$2" "$1/dn-$2"-*; do [ -f "$O/down" ] && ! [ "$(sed -n "s/^asked$TAB//p" "$O/ask")" \< "$3" ] && return 0; done; return 1; }
# sup: the test site up, SUPF its candidate folder and SUPA its address: the newest passed D1, by its ask's time, while its site runs as
# queue.sh's addresses read it (it stays up, or its staging run's issue is neither closed nor withdrawn) and no take-down of it was read down
# since; else SWHY says why nothing is up
sup() { SUPF=''; b=''; for O in $(ls -d "$SD"/*/*/d1 2>/dev/null); do [ -f "$O/passed" ] || continue; a=$(sed -n "s/^asked$TAB//p" "$O/ask"); [ -z "$SUPF" ] || [ "$a" \> "$b" ] || continue; SUPF=${O%/d1}; b=$a; done
  [ -n "$SUPF" ] || { SWHY='no staging deploy has passed'; return 1; }; SUPA=$(sed -n "s/^staging$TAB//p" "$SUPF/d1/read" | head -n 1)
  ! dndown "$SUPF" staging "$b" || { SWHY="the test site at $SUPA was taken down at the owner's word"; return 1; }
  grep -q "^stays${TAB}up\$" "$SUPF/d1/read" 2>/dev/null || { [ ! -f "$SUPF/cs/issue-closed" ] && [ ! -f "$SUPF/cs/withdrawn" ]; } || { SWHY="the test site at $SUPA was taken down after its run"; return 1; }; }
# pup: the live copy up, PUPF the candidate folder of the newest production okay of the commit production runs, PUPA production's address;
# else PWHY says why nothing is up
pup() { p=$(pnow); [ -n "$p" ] && [ "$p" != none ] || { PWHY='no production deploy has run'; return 1; }
  PUPF=''; b=''; for O in $(ls -d "$SD"/*/*/d2 2>/dev/null); do [ -f "$O/ask" ] && [ "$(cat "${O%/d2}/commit" 2>/dev/null)" = "$p" ] || continue; a=$(sed -n "s/^asked$TAB//p" "$O/ask"); [ -z "$PUPF" ] || [ "$a" \> "$b" ] || continue; PUPF=${O%/d2}; b=$a; done
  [ -n "$PUPF" ] || { PWHY="no production okay is of the commit production runs, $(printf %.12s "$p")"; return 1; }; PUPA=$(paddr); [ -n "$PUPA" ] || { PWHY='no production report names its address'; return 1; }
  t=$(pat); for O in $(ls -d "$SD"/*/* 2>/dev/null); do ! dndown "$O" production "$t" || { PWHY="the live copy at $PUPA was taken down at the owner's word"; return 1; }; done; }
# pheld: what holds production, once pinhand says so
pheld() { i0=$(dnin production) && { echo "its take-down, #$i0, is not reported yet"; return 0; }
  for O in $(ls -d "$SD"/*/*/d2 2>/dev/null); do [ -f "$O/ask" ] && ! pdone "${O%/d2}" || continue; echo "the production okay #$(sed -n "s/^issue$TAB//p" "$O/ask"): its report, or its production run, CP, is not done"; return 0; done; }
# lcl <address>: an address on this machine
lcl() { case $1 in *://127.0.0.1|*://127.0.0.1[:/]*|*://localhost|*://localhost[:/]*|*://\[::1\]*) return 0 ;; esac; return 1; }
# dnpost <target> <candidate folder> <commit> <address> <words>: the take-down posted, the owner's words kept in its ask and on its
# event, never in the body the dev side reads
dnpost() { DK=$2/dn-$1; if [ -d "$DK" ]; then j=1; while [ -d "$DK-$j" ]; do j=$((j + 1)); done; mv "$DK" "$DK-$j"; fi; mkdir -p "$DK"; N=${2%/*}; N=${N##*/}; c=${2##*/}
  { printf 'okay: down %s\ncommit: %s\naddress: %s\n\n' "$1" "$3" "$4"
    if [ "$1" = staging ]; then printf 'Take the test site at the address above down: stop what serves it. Delete no data: keep its data store, its backups and every report.'
    else printf 'Take the live copy at the address above down: stop it, on this machine. Keep its data store, its backups and every report.'; fi
    printf ' Report it as vid-results/deploy-<this issue>-<k>, by: DP, its commit the one above: report.txt with `outcome: down` once the address no longer answers, or `outcome: failed down — <why>` when it could not be taken down; `decisions: none`; and `down: %s <the address>`. Then comment `vid: reported dn-<k>` here; `vid: started` when you start. An owner-only step is your question here, labelled blocked.\n' "$1"; } > "$DK/body"
  n=$(gh_ deploy-ask --stage "$N" --commit "$3" --title "Take down $([ "$1" = staging ] && echo 'the test site' || echo 'the live copy'): stage $N, candidate $c" --body-file "$DK/body") || die 'the take-down could not be posted'
  { printf 'issue\t%s\ncommit\t%s\nasked\t%s\ntarget\t%s\naddress\t%s\n' "$n" "$3" "$(stamp)" "$1" "$4"; printf 'words\t%s\n' "$(printf '%s' "$5" | tr '\t\n\r' '   ')"; } > "$DK/ask"
  ev "stage-okay stage=$N candidate=$c issue=$n commit=$3 kind=dn words=\"$(dnwq)\""; echo "asked $n down $1"; }
# dnw <words>: the owner's own words, one argument, not blank (FB-2 A4: every take-down, staging's too, at the owner's explicit word);
# dnwq: the take-down's words for an event's last field, words="…", a double quote in them made a single one
dnw() { [ $# -eq 1 ] && [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }
dnwq() { sed -n "s/^words$TAB//p" "$DK/ask" | tr '"' "'"; }
# deploy down staging "<words>" | deploy down production "<words>" (/vid:vid-deploy down, both GitHub modes): posted, or `refused down
# <target>: <why>`, nothing posted, exit 1: no words, or blank ones; nothing up; staging taken (sfree: a candidate's okay, staging run or walk not done, or a take-down in hand), or a
# staging okay posted and not reported; a production okay in hand (pinhand: its report or CP not done, or a take-down in hand);
# a live copy that is not on this machine
cmd_down() { case ${1:-} in
  staging) shift; dnw "$@" || { echo "refused down staging: the take-down of the test site is asked only with the owner's own words, as deploy down staging \"<words>\""; exit 1; }
    sup || { echo "refused down staging: nothing is up: $SWHY"; exit 1; }; sfree || { echo "refused down staging: staging is taken: $SWHY"; exit 1; }
    for O in $(ls -d "$SD"/*/*/d1 2>/dev/null); do [ -f "$O/ask" ] && [ ! -f "$O/passed" ] && [ ! -f "$O/closed" ] && ! grep -q '^lost d1 ' "$O/items" 2>/dev/null || continue
      echo "refused down staging: staging is taken: the staging okay #$(sed -n "s/^issue$TAB//p" "$O/ask") is posted and not reported yet"; exit 1; done
    dnpost staging "$SUPF" "$(sed -n "s/^commit$TAB//p" "$SUPF/d1/ask")" "$SUPA" "$1" ;;
  production) shift; dnw "$@" || { echo "refused down production: the take-down of the live copy is asked only with the owner's own words, as deploy down production \"<words>\""; exit 1; }
    pup || { echo "refused down production: nothing is up: $PWHY"; exit 1; }; ! pinhand || { echo "refused down production: a production okay is in hand: $(pheld)"; exit 1; }
    lcl "$PUPA" || { echo "refused down production: the live copy at $PUPA is not a copy on this machine: a real live product on a host is switched off by the owner, on its platform"; exit 1; }
    dnpost production "$PUPF" "$(pnow)" "$PUPA" "$1" ;;
  *) die 'usage — deploy down staging "<words>" | deploy down production "<words>"' ;; esac; }
# out (FB-2 A4): `out down-<target>` for each take-down whose report is not read yet; decide down-<target>: its newest report, on its form
# alone: `down <target> <N>` (closed, `down`, a deploy-down event), `down-failed <target>: <why>` (closed), `dn-refused <target> <k>`
# (posted back once), or quiet past close-wait-minutes, with no report or after a refused one posted back: `vid: again dn` once; then,
# quiet again past it, `down-lost <target>` (closed, `lost`: nothing taken down, the target free for the owner to ask again)
cmd_dnout() { for t in staging production; do ! dnin "$t" > /dev/null || echo "out down-$t"; done; }
cmd_dnread() { TG=$1; DK=$(ls -d "$SD"/*/*/dn-"$TG" 2>/dev/null | while read -r O; do [ -f "$O/ask" ] && [ ! -f "$O/done" ] && echo "$O"; done | head -n 1); [ -n "$DK" ] || return 0
  P=${DK%/*}; N=${P%/*}; N=${N##*/}; c=${P##*/}; i=$(sed -n "s/^issue$TAB//p" "$DK/ask"); X=$(sed -n "s/^commit$TAB//p" "$DK/ask"); touch "$DK/again"
  sh "$HERE/results.sh" deploy --stage "$N" --kind dn --target "$TG" --candidate "$c" > /dev/null 2> .vid/round/ce || die "the take-down could not be read: $(tail -n 1 .vid/round/ce)"; set -- $(head -n 1 "$DK/read" | tr '\t' ' ')
  case $2 in
    down) dnclose; : > "$DK/down"; : > "$DK/done"; ev "deploy-down target=$TG at=$X stage=$N issue=$i result=down words=\"$(dnwq)\""; echo "down $TG $N" ;;
    failed) dnclose; w=$(head -n 1 "$DK/read" | cut -f4-); echo "$w" > "$DK/failed"; : > "$DK/done"; ev "deploy-down target=$TG at=$X stage=$N issue=$i result=failed words=\"$(dnwq)\""; echo "down-failed $TG: $w" ;;
    refused) if ! grep -qx "refused $3" "$DK/again"; then dcom "vid: refused dn-$3" "$(cut -f4- "$DK/read" | head -n 1)"; echo "refused $3" >> "$DK/again"; echo "dn-refused $TG $3"
      else dnq && dnagain; fi ;;   # FB-2 A4: posted back and quiet past the wait after it, asked again once, then lost
    *) dnq && dnagain ;;
  esac; return 0; }
# dnagain (FB-2 A4): quiet past the wait: `vid: again dn` once; asked again already, it is lost
dnagain() { if grep -qx 'again dn' "$DK/again"; then dnlost; else dcom 'vid: again dn'; echo 'again dn' >> "$DK/again"; echo "close-again down-$TG dn"; fi; }
# dnq: the take-down's issue quiet past close-wait-minutes (its updated time, which a comment of ViD's moves)
dnq() { W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$i" '$1 == "issue" && $2 == n { print $5 }' "$RD" 2>/dev/null); [ $(( $(date +%s) - $(epoch "${u:-$(stamp)}") )) -ge "$W" ]; }
# dnlost (FB-2 A4): asked again and quiet past the wait after it: done with nothing taken down, the issue closed, the target free for
# the owner to ask again
dnlost() { dnclose; : > "$DK/lost"; : > "$DK/done"; echo "down-lost $TG"; }
# dnclose (FB-2 A4): the take-down's issue closed first; a close that fails stops the read with nothing written, the take-down still out and
# holding its target, and the next round's read closes it
dnclose() { gh_ close "$i" > /dev/null 2> .vid/round/ce || die "the take-down #$i could not be closed: $(tail -n 1 .vid/round/ce)"; }

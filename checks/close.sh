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
#   deploy down staging "<words>" | deploy down production "<words>"   (FB-2 A4, /vid:vid-deploy down, both GitHub modes) at the owner's
#                   own words alone, which its ask and its events keep (never its body), the take-down okay of the test site, or of the live copy where it is a copy on this machine, posted for the dev side, `asked <n> down
#                   <target>`; else `refused down <target>: <why>`, nothing posted, exit 1. out lists `out down-<target>` while its
#                   report is not read, and decide down-<target> reads it: `down <target> <N>`, `down-failed <target>: <why>`, or,
#                   asked again once (after no report or a refused one posted back) and quiet after it, `down-lost <target>`, nothing taken down
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
. "$HERE/close-step.sh"         # FB-2 C3: the step close
. "$HERE/close-decide.sh"       # FB-2 C3: the one reader of an ask
. "$HERE/close-candidate.sh"    # FB-2 C3: a stage's candidate, C3 and S1
. "$HERE/close-staging.sh"      # FB-2 C3: staging, D1 and CS
. "$HERE/close-end.sh"          # FB-2 C3: the stage close
. "$HERE/close-production.sh"   # FB-2 C3: production, RH, CR, D2 and CP
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
  elif ! sfree && [ -n "$SWHY" ]; then echo "staging is taken: $SWHY"   # FB-2 A4: what holds it
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
  down) shift; cmd_down "$@" ;;   # FB-2 A4: close-production.sh's take-down
  *) die 'usage — deploy staging [<N>] | deploy production "<words>" | deploy down staging "<words>" | deploy down production "<words>"' ;; esac; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in owed) cmd_owed ;; out) cmd_out; cmd_dnout ;; owned) cmd_owned ;; why) cmd_why ;;
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
  decide) [ -n "${1:-}" ] || die 'usage — decide <step> | --stage <N>'; case $1 in --stage) cmd_decide_stage "${2:?}" ;; stage-*) cmd_decide_stage "${1#stage-}" ;; down-staging|down-production) cmd_dnread "${1#down-}" ;; *) cmd_decide "$1" ;; esac ;;
  *) echo 'usage: sh checks/close.sh owed|out|owned|step <step>|stage <N>|walk <N>|read-walk <N>|summary <N>|deploy staging [<N>]|deploy production "<words>"|deploy down staging "<words>"|deploy down production "<words>"|ask <step>|--stage <N>|--cs <N>|okay --stage <N>|decide <step>|--stage <N>' >&2; exit 2 ;; esac

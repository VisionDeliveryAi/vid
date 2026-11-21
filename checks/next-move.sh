#!/bin/sh
# Purpose: /vid next's moves (GitHub manual, GM-2 T10, T4; GM M16 steps 5 to 7): what the call showed kept, each move the owner
# named checked and done in the order named, each saved before the next, and the plan page written. Run from the top of ViD's
# repository in GitHub manual alone (lib.sh manual), after vid-read and vid-triggers (the call's steps 3 and 4) and before
# vid-connect's end, inside the call's lock. Every script it calls is marked as the call's own (VID_CALLER=next). It holds no
# rule of a move: each is the script's it calls.
#   call [<move> [-- <move>]…]   in order:
#     1. the call's lines (next.sh triggers, from the records and the call's read, .vid/round/read);
#     2. each move named, in the order named: checked against the listing (a move of the call's lines whose hash is the one the
#        last call raised, GM-4 F4: .vid/decide/queue/raised; else `again`, its move and warning lines printed, and not done); done;
#        the records saved (github.sh state-save) before the next starts. Before each later move the call's lines are made again
#        from the records, with no new read, and the call's lock renewed (github.sh lock-renew). A `done` of a to-do that is a move
#        of the lines is checked as that move. A refusal stops that move alone, naming its step and its words; a save that fails
#        stops the call, the moves after it not done;
#        GM-3 U6 (lane C's review): when the lines list implement-replan with its own proposal, that proposal and its page are
#        made first (replan.sh own; `proposal: …`), unless the one kept is its own and fresh (its target HEAD, its hash replan.sh
#        hash's), so the owner has seen the page; so too after the moves, when a move ran;
#     3. after the moves the call's lines (made again when a move ran, and then printed, `counted` lines left out), and what they
#        raise kept in the owner's queue (GM-4 F4: queue.sh raise), each trigger and move a `Q<n>` line;
#     4. the plan page (next-page.sh write on the call's last lines): its `page <path>` line; then (GM-4 K6, I6) each open `Q<n>`
#        line of the owner's queue with the answers it takes, as queue.sh list prints it.
#   shell <page>   the plan page's fixed shell (GM-2 T12), plan-shell.html beside the page: it shows plan.html, the data file the
#                  vid-next skill publishes to the same link; prints `shell <path>`
# The moves (GM-2 T10's table), named by kind and subject, never by a number, the owner's words their last argument. GM-4 K11
# (step 6): each runs the script entry of the skill it belongs to; next-move.sh holds only the listing check (A20) and the call's
# order, never a move's rule:
#   publish <step> "<words>" [--title "<title>"]   (T4; vid-tickets, GM-4 K1, J1) github.sh tw-hand publish <step> --words "<words>"
#        [--title "<title>"], the one ticket path: its lock (the call's, borrowed), the export, the sync, the read, the handovers,
#        the admission (plan.sh start, a hold its exit 3), the write and its check, the post and the save, all tw-hand's. Then, once
#        the log holds the post, the warnings the listing showed kept with the words in .vid/next/published (GM-2 §5), and the call's
#        read read again (the new ticket's line and its body as posted). Never refused for a warning. GM-4 F2 (I4): the call's stage
#        is the connect's, opened at its start, never opened here
#   amend #<n> "<words>"   (T5; vid-tickets) github.sh tw-hand amend <n> --words "<words>"
#   withdraw #<n> "<words>"   (T6; vid-tickets) github.sh tw-hand withdraw <n> --words "<words>"
#   reopen #<n> "<words>"   (GM-4 K1, E6; vid-tickets) github.sh tw-hand reopen <n> --words "<words>", once the call's lines list it
#   engines "<primary> <other>…" "<words>"   (T4; vid-accept-step's, GM-4 F16) results.sh declare --engines "<them>" --words
#        "<words>", the one writer of .vid/tw/handed's engines line: `engines <them> | stand-in: owner at <now>, words "<words>"`
#   own-work on|off "<words>"   (GM-4 K11, L1; GM §6: the phase's first write is one the owner names) the owner's switch of /vid next's
#        step 2, ViD's own work: `setup-answered key=own-work value="on|off" words="<words>" at=<now>` in .vid/plan/setup; next.sh
#        own-work reads it. Step 2 writes nothing until it reads on
#   walk-stage <N> "<words>" | read-walk <N> "<words>" | write-summary <N> "<words>"   (GM-4 K4, GM M16; vid-stage-close) once the call's
#        lines list it: close.sh walk <N> (the brief, then the walker started by walk.sh start, a session of its own no call waits for),
#        close.sh read-walk <N>, close.sh summary <N> (the summary's facts; its words are the skill's); its line then taken out of
#        .vid/next/stage-moves, an event `stage-move` keeping the owner's words
#   answer <#<n>:<k>|Q<n>> [<its answer>…] "<words>"   (T8; vid-answer, GM-4 K6) queue.sh answer, the one entry of every answer: a
#        team question by its place (`there` when the owner answered it on GitHub), any `Q<n>` line with the answer it takes; queue.sh
#        refuses one it does not hold open
#   decline <what> [<subject>] "<words>"   (T9; vid-answer, GM-4 F4) queue.sh answer … decline "<words>" for each `Q<n>` line of a
#        trigger of that what (and subject) the last call raised and no answer closed
#   done "<kind> <subject>" "<words>"   (T12; vid-answer, GM-4 F4) queue.sh answer … done "<words>" for the `Q<n>` line of that move,
#        or of that critical trigger, the last call raised: off the to-do list
#   team-change #<n> <id> yes|no "<words>"   (T7; vid-answer) team-change.sh <n> <id> yes|no "<words>", which amends or withdraws
#        each ticket the change reaches through the one ticket path
#   After any move, each ticket it amended, withdrew or reopened is read back from GitHub (the one read, next.sh read) into
#   .vid/round/read (T10)
#   GM-3 U6, the re-plan's three moves (vid-replan), each checked against the listing as every move is:
#   planning-analysis [<kind> [<subject>]]… [without #<n> <id> | without <step>]…   (U3, U5) the last move named, if named: checked
#        here alone (`checked planning-analysis -: …`, its arguments named); the analysis itself is the vid-replan skill's, which the
#        conversation runs after the call's moves with those arguments, since it writes the candidate. Records nothing
#   implement-replan "<words>" [--review <file>]   (U4) named once a call at most; replan.sh apply --words "<words>" [--review <file>]: --review the fresh
#        agent's review the call makes when the line says the rows ViD's planner adds need one. Its exit 3, a post left owed, is done
#        (the owed post a move of the next call); 4, the proposal stale, is shown again, not done
#   GM-4 F9 (I5): a draft of the door is asked through the owner's queue (queue.sh ask draft) and landed by the owner's answer yes
#   (answer Q<n> yes "<words>"); no move of its own
# Prints a line a move: `done <kind> <subject>: <what>`, `refused <kind> <subject> at <step>: <its words>` (the step's output
#   under it, indented), `again <kind> <subject>: <why>; shown again, not done` (then its move and warning lines), `not done <kind>
#   <subject>: <why>`, `not saved: …`; then `after the moves:` and the lines, when a move ran; then `page <path>`; then the
#   queue's open lines, `Q<n> TAB <key> TAB <the answers it takes> TAB <its words>`.
#   Exit 0; 1 when the call's lines cannot be made, a save fails or the page cannot be written; 2 a usage error, before anything.
#   GM-4 F5, K1: the apply posts through github.sh tw-hand itself; the `post` entry made for it is cut
# Usage: sh checks/next-move.sh call [<move> [-- <move>]…] | shell <page>
# serves: tickets
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
VID_CALLER=next; export VID_CALLER
W=$(mktemp -d); MK=''; MS=''; QD=.vid/decide/queue
trap 'rm -rf "$W"' EXIT; trap 'exit 1' INT TERM
TAB=$(printf '\t')
usage() { sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2; }
ref() { echo "ViD next-move: refused — $*" >&2; exit 1; }
one() { printf '%s' "$1" | tr '\t\n' '  ' | tr '"' "'"; }   # the owner's words on one line (GM-2 §5)

case ${1:-} in
  shell) [ $# -eq 2 ] && [ -f "$2" ] || usage; D=$(cd "$(dirname "$2")" && pwd); [ "$(basename "$2")" = plan.html ] || ref "the page is plan.html, not $(basename "$2")"
    cat > "$W/sh" <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Plan page</title>
<style>
:root { color-scheme: light dark; --bg: #ffffff; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg: #16161a; } }
:root[data-theme="dark"] { --bg: #16161a; }
html, body { margin: 0; height: 100%; background: var(--bg); }
iframe { display: block; border: 0; width: 100%; height: 100%; }
</style>
</head>
<body>
<iframe src="plan.html" title="The plan page"></iframe>
</body>
</html>
HTML
    put "$D/plan-shell.html" < "$W/sh" || exit 1; echo "shell $D/plan-shell.html"; exit 0 ;;
  call) shift ;;
  *) usage ;;
esac

# the moves named, one file each, an argument a line (a newline or tab in one written as a space), `--` between two
mkdir "$W/m"; NM=0; NEW=1; NIR=0
for a in "$@"; do if [ "$a" = -- ]; then [ "$NEW" = 0 ] || usage; NEW=1; continue; fi
  [ "$NEW" = 0 ] || { NM=$((NM + 1)); : > "$W/m/$NM"; NEW=0; }; printf '%s\n' "$(printf '%s' "$a" | tr '\t\n' '  ')" >> "$W/m/$NM"; done
[ $# -eq 0 ] || [ "$NEW" = 0 ] || usage
arg() { sed -n "$1p" "$F"; }
# the grammar of each, checked before anything is done
i=0; while [ $i -lt "$NM" ]; do i=$((i + 1)); F=$W/m/$i; na=$(grep -c '' "$F"); k=$(arg 1); s=$(arg 2)
  case $k in
    publish) { [ "$na" = 3 ] || { [ "$na" = 5 ] && [ "$(arg 4)" = --title ]; }; } && printf '%s' "$s" | grep -Eq '^[A-Za-z0-9._-]+$' && ! printf '%s' "$s" | grep -Eq '^[0-9]+$' ||
               { echo "ViD next-move: usage — publish <step> \"<words>\" [--title \"<title>\"]: the step by its id, never by a number" >&2; exit 2; } ;;
    engines|done) [ "$na" = 3 ] || { echo "ViD next-move: usage — $k \"<…>\" \"<words>\"" >&2; exit 2; } ;;
    own-work) [ "$na" = 3 ] && case $s in on|off) true ;; *) false ;; esac || { echo 'ViD next-move: usage — own-work on|off "<words>"' >&2; exit 2; } ;;
    walk-stage|read-walk|write-summary) [ "$na" = 3 ] && printf '%s' "$s" | grep -Eq '^[0-9]+$' || { echo "ViD next-move: usage — $k <N> \"<words>\": the stage by its number" >&2; exit 2; } ;;   # GM-4 K4
    answer) [ "$na" -ge 3 ] && printf '%s' "$s" | grep -Eq '^(#?[0-9]+:[0-9]+|Q[0-9]+)$' || { echo 'ViD next-move: usage — answer <#<n>:<k>|Q<n>> [<its answer>…] "<words>"' >&2; exit 2; } ;;
    decline) [ "$na" = 3 ] || [ "$na" = 4 ] || { echo 'ViD next-move: usage — decline <what> [<subject>] "<words>"' >&2; exit 2; } ;;
    amend|withdraw|reopen) [ "$na" = 3 ] && printf '%s' "$s" | grep -Eq '^#?[0-9]+$' || { echo "ViD next-move: usage — $k #<n> \"<words>\"" >&2; exit 2; } ;;
    team-change) [ "$na" = 5 ] && printf '%s' "$s" | grep -Eq '^#?[0-9]+$' && case $(arg 4) in yes|no) true ;; *) false ;; esac || { echo 'ViD next-move: usage — team-change #<n> <id> yes|no "<words>"' >&2; exit 2; } ;;
    # GM-3 U6: planning-analysis's arguments are replan.sh scope's to judge; it is the last move named, since its analysis runs after them
    planning-analysis) [ "$i" = "$NM" ] || { echo 'ViD next-move: usage — planning-analysis is the last move named: its analysis runs after the call'"'"'s other moves' >&2; exit 2; } ;;
    implement-replan) [ "$na" = 2 ] || { [ "$na" = 4 ] && [ "$(arg 3)" = --review ]; } || { echo 'ViD next-move: usage — implement-replan "<words>" [--review <file>]' >&2; exit 2; }
      # named once a call, so a second never acts on words given before the first one's findings were shown
      NIR=$((NIR + 1)); [ "$NIR" = 1 ] || { echo 'ViD next-move: usage — implement-replan is named once a call: a second would act on words given before the first one was shown' >&2; exit 2; } ;;
    # GM-4 K11 (step 6): each move named with the skill whose entry it runs
    *) echo "ViD next-move: usage — $k is no move: publish, amend, withdraw and reopen (vid-tickets); answer, done, decline and team-change (vid-answer); planning-analysis and implement-replan (vid-replan); engines and own-work (vid-accept-step); walk-stage, read-walk and write-summary (vid-stage-close), each by its kind and subject" >&2; exit 2 ;;
  esac; done

manual || ref 'the moves are GitHub manual'"'"'s (/vid next): this project is not in it'
[ -f .vid/round/read ] || ref "no read of this call (.vid/round/read): the call's read comes first (vid-read)"
# lines <file>: the call's lines, next.sh triggers from the records
lines() { sh "$HERE/next.sh" triggers > "$1" 2> "$W/te" && return 0; sed 's/^/    /' "$W/te" >&2; return 1; }
lines "$W/L" || ref "the call's lines could not be made (next.sh triggers): no move is done"
# GM-3 U6 (lane C's review): an implement-replan the lines list with its own proposal has that proposal and its page made first
# (replan.sh own), unless the one kept is its own and fresh, so the owner sees the page before naming it; the line does not change
ownp() { awk -F'\t' '$1 == "move" && $2 == "implement-replan" && $5 ~ /^applies the pending changes with its own proposal/ { f = 1 } END { exit !f }' "$1" || return 0
  _p=.vid/next/proposal; if [ "$(cat "$_p/made" 2> /dev/null)" = own ] && [ "$(cat "$_p/target" 2> /dev/null)" = "$(git rev-parse HEAD)" ] &&
    [ "$(cat "$_p/hash" 2> /dev/null)" = "$(sh "$HERE/replan.sh" hash 2> /dev/null)" ]; then return 0; fi
  if sh "$HERE/replan.sh" own > "$W/ow" 2>&1; then echo "proposal: implement-replan's own proposal made, its page .vid/pages/REPLAN-PAGE.html"
  else echo "proposal: implement-replan's own proposal could not be made: $(grep -v '^[[:space:]]*$' "$W/ow" | tail -n 1)"; fi; }
ownp "$W/L"

# no <step> <words>: the move refused at its step, its output under it
NOK=''; no() { NOK=1; echo "refused $MK $MS at $1: $2"; [ ! -s "$W/so" ] || grep -v '^[[:space:]]*$' "$W/so" | head -n 20 | sed 's/^/    /'; : > "$W/so"; }
# step <what> <command…>: the command run, its output kept; a failure refuses the move at that step, its words its last line
step() { _w=$1; shift; "$@" > "$W/so" 2>&1 && return 0; no "$_w" "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 1; }
# raised <kind> <subject>: the queue keys of what the last call raised for that move (`move <kind> <subject>`) or trigger
# (`trigger <what> [<subject>]`), each with its raising, `<key>@<since>` a line (GM-4 F4, .vid/decide/queue/raised)
raised() { awk -F'\t' -v w="$1" -v k="$2" -v s="${3-}" 'BEGIN { x = (w == "move") ? 3 : 4 }
  { n = split($1, a, ":"); if (a[1] != w || a[2] != k) next; sb = $1; for (i = 1; i <= x; i++) sub(/^[^:]*:/, "", sb); if (s != "" && sb != s) next; print $1 "@" $2 "\t" a[3] "\t" a[4] }' "$QD/raised" 2> /dev/null; }
# chk <kind> <subject>: 0 when the call's lines hold the move with the hash the last call raised; 1 no such move now; 2 changed
chk() { _h=$(awk -F'\t' -v k="$1" -v s="$2" '$1 == "move" && $2 == k && $3 == s { print $4; exit }' "$W/L")
  _o=$(raised move "$1" "$2" | cut -f2 | head -n 1)
  [ -n "$_h" ] || { WHY="it is no move of the call's lines now"; return 1; }
  [ -n "$_o" ] || { WHY='the listing the owner saw did not show it'; return 2; }
  [ "$(printf %.12s "$_h")" = "$_o" ] || { WHY='what it would do, or its warnings, changed since the listing'; return 2; }; return 0; }
# open_ <key>: the queue holds the item open (no answer closed it)
open_() { ! awk -F'\t' -v k="$1" '$2 == k { f = 1 } END { exit !f }' "$QD/answers" 2> /dev/null; }
mvlines() { awk -F'\t' -v k="$1" -v s="$2" '($1 == "move" || $1 == "warning") && $2 == k && $3 == s' "$W/L"; }
# rread <why>: the call's read read again after a move posted, through the one read (GM-4 F3, next.sh read, round.sh read's), so the
# next move and the page read GitHub as it holds the tickets now; a read that fails leaves the call's read as it was, said once
rread() { sh "$HERE/next.sh" read > "$W/rr" 2>&1 || echo "    the call's read could not be read again after $1: it stays as it was before the move ($(grep -v '^[[:space:]]*$' "$W/rr" | tail -n 1))"; }
# radd <n>: after a publish, the new ticket's `ticket` line and its body as GitHub holds them, by the one read
radd() { rread "#$1's publish"; }
# GM-4 K1 (J1): hand <kind> <n or step> <its options…>: the move through the one ticket path, github.sh tw-hand, the vid-tickets
# skill's entry (its preparation, its checks, the post and the save its own), the owner's words given; its output kept, HRC its exit,
# HL the log's line count before it
hand() { HL=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0); HRC=0; sh "$HERE/github.sh" tw-hand "$@" > "$W/so" 2>&1 || HRC=$?; }
# logged <what> <n>: the log holds a `<what> <n>` line since the move began
logged() { awk -v n0="$HL" -v w="$1" -v n="$2" 'NR > n0 && $1 == w && $2 == n { f = 1 } END { exit !f }' .vid/tw/log 2> /dev/null; }
lastl() { grep -v '^[[:space:]]*$' "$W/so" | tail -n 1; }

# rback <the log's line count before the move>: when the move amended, withdrew or reopened a ticket (its `amended`, `withdrawn` or `reopened` lines in the
# log since), the call's read read again through the one read (rread), so the next move and the page read each issue as GitHub holds
# it; a withdrawn one the read leaves out, as the log withdraws it
rback() { awk -v n0="$1" 'NR > n0 && ($1 == "amended" || $1 == "withdrawn" || $1 == "reopened") { f = 1 } END { exit !f }' .vid/tw/log 2> /dev/null || return 0; rread 'the move'; }
# GM-4 K1 (J1): amend, withdraw and reopen through tw-hand; done once the log holds the act, though a later part of it failed
mv_tick() { _l=$1; _d=$2; N=${MS#\#}; hand "$MK" "$N" --words "$(arg 3)"
  logged "$_l" "$N" || { no 'the ticket path' "$(lastl)"; return 0; }
  if [ "$HRC" = 0 ]; then echo "done $MK $MS: $_d in the owner's words"; else echo "done $MK $MS: $_d and recorded; then refused: $(lastl)"; fi; }
mv_team() { N=${MS%% *}; N=${N#\#}; ID=$(arg 3); AN=$(arg 4); WD=$(arg 5); NA=$(grep -c '' .vid/next/team-answers 2> /dev/null || echo 0); PRC=0
  sh "$HERE/team-change.sh" "$N" "$ID" "$AN" "$WD" > "$W/so" 2>&1 || PRC=$?
  awk -F'\t' -v n0="$NA" -v n="$N" -v id="$ID" 'NR > n0 && $1 == n && $3 == id { f = 1 } END { exit !f }' .vid/next/team-answers 2> /dev/null || { no 'the team change' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  if [ "$PRC" = 0 ]; then echo "done team-change $MS: $AN, in the owner's words"; else echo "done team-change $MS: $AN recorded; then: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; fi
  [ ! -s "$W/so" ] || grep -v '^[[:space:]]*$' "$W/so" | sed 's/^/    /'; }
mv_publish() { S=$MS; WD=$(arg 3); if [ "$na" -ge 5 ]; then set -- --title "$(arg 5)"; else set --; fi
  hand publish "$S" --words "$WD" "$@"
  N=$(awk -v n0="$HL" 'NR > n0 && $1 == "published" { print $2 }' .vid/tw/log 2> /dev/null | tail -n 1)
  # tw-hand's exit 3 is the admission's hold, its line printed
  [ -n "$N" ] || { if [ "$HRC" = 3 ]; then no 'the admission' "$(lastl)"; else no 'the ticket path' "$(lastl)"; fi; return 0; }
  PE=$(lastl); WS=$(awk -F'\t' -v s="$S" '$1 == "warning" && $2 == "publish" && $3 == s { printf "%s%s %s", p, $4, $5; p = " | " }' "$W/L")
  mkdir -p .vid/next; printf '%s\t%s\t%s\t%s\t%s\n' "$N" "$S" "${WS:--}" "$(now)" "$(one "$WD")" >> .vid/next/published
  radd "$N"
  if [ "$HRC" = 0 ]; then echo "done publish $S: #$N posted, in the owner's words"; else echo "done publish $S: #$N posted and recorded; then refused: $PE"; fi
  }
# GM-4 F16: the engines through results.sh declare, the one writer of the handed record's engines line, with the owner's words
mv_engines() { E=$(arg 2); WD=$(arg 3)
  step 'the engines' sh "$HERE/results.sh" declare --engines "$E" --words "$WD" || return 0; echo "done engines $E: on record, the owner its stand-in"; }
# GM-4 K11 (L1): own work's switch, the owner's words recorded as a setup line
mv_ownwork() { WD=$(arg 3); [ -n "$(printf '%s' "$WD" | tr -d '[:space:]')" ] || { no 'the words' "own work is switched only in the owner's words"; return 0; }
  mkdir -p .vid/plan; printf 'setup-answered key=own-work value="%s" words="%s" at=%s\n' "$MS" "$(one "$WD")" "$(now)" >> .vid/plan/setup
  echo "done own-work $MS: in the owner's words; /vid next's step 2 $( [ "$MS" = on ] && echo 'does ViD'"'"'s own work from the next call' || echo 'writes nothing')"; }
# GM-4 K4 (GM M16): the stage's walk and summary, moves the owner names, each close.sh's action of the vid-stage-close skill (walk,
# read-walk, summary <N>); once done, its line is taken out of .vid/next/stage-moves, so the call lists it no more
mv_stage() { WD=$(arg 3); [ -n "$(printf '%s' "$WD" | tr -d '[:space:]')" ] || { no 'the words' "the stage's moves go only on the owner's words"; return 0; }
  case $MK in walk-stage) _a=walk; _l=walk ;; read-walk) _a=read-walk; _l=walk-read ;; *) _a=summary; _l=summary ;; esac
  step "the stage's $_a" sh "$HERE/close.sh" "$_a" "$MS" || return 0; cp "$W/so" "$W/sto"
  { grep -vx "$_l $MS" .vid/next/stage-moves 2> /dev/null || true; } > "$W/smv"; put .vid/next/stage-moves < "$W/smv" || true
  ev "stage-move kind=$MK stage=$MS words=\"$(one "$WD")\""
  case $MK in walk-stage) echo "done walk-stage $MS: the walker started (pid $(sed -n 's/^walk-started [0-9]* //p' "$W/sto")), a session of its own; no call waits for it" ;;
    read-walk) echo "done read-walk $MS: $(grep -v '^[[:space:]]*$' "$W/sto" | tail -n 1)" ;;
    *) echo "done write-summary $MS: $(grep '^facts ' "$W/sto" | tail -n 1); its summary, in plain product words from those facts, is the vid-stage-close skill's" ;; esac; : > "$W/so"; }
# GM-4 K6: the answer, the owner's queue's one entry (queue.sh answer), its arguments as named
mv_answer() { set -- "${MS#\#}"; _j=2; while [ "$_j" -lt "$na" ]; do _j=$((_j + 1)); set -- "$@" "$(arg "$_j")"; done
  step 'the answer' sh "$HERE/queue.sh" answer "$@" || return 0; echo "done answer $MS: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; }
# GM-4 F4: a decline answers each open `Q<n>` line of a trigger of that what (and subject) the last call raised
mv_decline() { WD=$(arg "$na"); DS=''; [ "$na" != 4 ] || DS=$(arg 3); raised trigger "$MS" "$DS" | cut -f1 > "$W/dk"; n=0
  while IFS= read -r _k; do open_ "$_k" || continue; step 'the decline' sh "$HERE/queue.sh" answer "$_k" decline "$WD" < /dev/null || return 0; n=$((n + 1)); done < "$W/dk"
  [ "$n" -gt 0 ] || { no 'the decline' "no $MS trigger${DS:+ for $DS} the last call raised waits on you: none is raised, or each is answered already"; return 0; }
  echo "done decline $MS${DS:+ $DS}: $n declined, in the owner's words"; }
# GM-3 U6: the re-plan's three moves, each the script's that holds its rules
mv_analysis() { _a=$(i=1; while [ "$i" -lt "$na" ]; do i=$((i + 1)); printf ' %s' "$(arg "$i")"; done)
  echo "checked planning-analysis -: as the listing showed it; the vid-replan skill runs the analysis after the call's moves, with ${_a:+the arguments$_a}${_a:-no arguments}"; }
mv_apply() { WD=$(arg 2); if [ "$na" = 4 ]; then set -- --review "$(arg 4)"; else set --; fi; PRC=0
  sh "$HERE/replan.sh" apply --words "$WD" "$@" > "$W/so" 2>&1 || PRC=$?
  case $PRC in
    0|3) if [ "$PRC" = 0 ]; then echo "done implement-replan -: applied in the owner's words"; else echo "done implement-replan -: applied in the owner's words; a post is left owed, a move of the next call"; fi
       grep -v '^[[:space:]]*$' "$W/so" | sed 's/^/    /'; : > "$W/so" ;;
    4) echo "again implement-replan -: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1 | sed 's/^ViD replan: refused — //'); shown again, not done"; : > "$W/so"; mvlines planning-analysis -; return 0 ;;
    *) no 'the apply' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0 ;;
  esac; }
# GM-4 F4: done answers the open `Q<n>` line of that move, or that critical trigger, the last call raised: off the to-do list
mv_done() { WD=$(arg 3); DK=${MS%% *}; DS=${MS#* }; [ "$DS" != "$MS" ] || DS=''
  { raised move "$DK" "$DS"; raised trigger "$DK" "$DS" | awk -F'\t' '$2 == "critical"'; } | cut -f1 | while IFS= read -r _k; do open_ "$_k" && echo "$_k"; done > "$W/dk"
  [ -s "$W/dk" ] || { no 'the to-do' "\"$MS\" is no to-do on your list: the last call raised no such move or critical trigger, or it is answered already"; return 0; }
  while IFS= read -r _k; do step 'the to-do' sh "$HERE/queue.sh" answer "$_k" done "$WD" < /dev/null || return 0; done < "$W/dk"; echo "done done $MS: off the to-do list, in the owner's words"; }

i=0; RAN=''; while [ $i -lt "$NM" ]; do i=$((i + 1)); F=$W/m/$i; na=$(grep -c '' "$F"); MK=$(arg 1); MS=$(arg 2)
  [ -z "$RAN" ] || lines "$W/L" || { echo "not done $MK $MS: the call's lines could not be made again; the moves after it are not done"; exit 1; }
  # the call's lock renewed before each move after the first, so a long call keeps it
  [ "$i" = 1 ] || sh "$HERE/github.sh" lock-renew > "$W/lr" 2>&1 || { sed 's/^/    /' "$W/lr"; echo "not done $MK $MS: the call's lock could not be renewed; the moves after it are not done"; exit 1; }
  case $MK in
    planning-analysis|implement-replan) MS=- ;;
    answer) case $MS in Q*) ;; *) MS="#${MS#\#}" ;; esac ;; amend|withdraw|reopen) MS="#${MS#\#}" ;; team-change) MS="#${MS#\#} $(arg 3)" ;;
  esac
  case $MK in
    publish|amend|withdraw|reopen|team-change|planning-analysis|implement-replan|walk-stage|read-walk|write-summary) rc=0; chk "$MK" "$MS" || rc=$?
      # GM-3 U6: an implement-replan the lines no longer list has no fresh proposal now: planning-analysis says why
      if [ "$rc" = 1 ] && [ "$MK" = implement-replan ]; then echo "again implement-replan -: no proposal is ready to apply now; planning-analysis says why; shown again, not done"; mvlines planning-analysis -; continue; fi
      if [ "$rc" = 1 ]; then echo "not done $MK $MS: $WHY"; continue; fi
      if [ "$rc" = 2 ]; then echo "again $MK $MS: $WHY; shown again, not done"; mvlines "$MK" "$MS"; continue; fi
      # planning-analysis: checked, and done by the vid-replan skill after the call's moves; nothing here records or saves
      if [ "$MK" = planning-analysis ]; then mv_analysis; continue; fi ;;
    # a to-do that is a move of the call's lines is checked as its move is; a trigger's, and a decline, answer the queue's line,
    # whose key holds the evidence the owner saw (GM-4 F4)
    done) DK=${MS%% *}; DS=${MS#* }; [ "$DS" != "$MS" ] || DS=''
      if awk -F'\t' -v k="$DK" -v s="$DS" '$1 == "move" && $2 == k && $3 == s { f = 1 } END { exit !f }' "$W/L"; then rc=0; chk "$DK" "$DS" || rc=$?
        if [ "$rc" != 0 ]; then echo "again $MK $MS: $WHY; shown again, not done"; mvlines "$DK" "$DS"; continue; fi; fi ;;
  esac
  : > "$W/so"; RAN=1; NL0=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0)
  case $MK in publish) mv_publish ;; engines) mv_engines ;; own-work) mv_ownwork ;; answer) mv_answer ;; decline) mv_decline ;; done) mv_done ;; amend) mv_tick amended amended ;; withdraw) mv_tick withdrawn withdrawn ;; reopen) mv_tick reopened reopened ;; team-change) mv_team ;;
    implement-replan) mv_apply ;; walk-stage|read-walk|write-summary) mv_stage ;; esac
  rback "$NL0"
  sh "$HERE/github.sh" state-save > "$W/sv" 2>&1 || { sed 's/^/    /' "$W/sv"; echo "not saved: the records after $MK $MS could not be saved ($(tail -n 1 "$W/sv")); the moves after it are not done"; exit 1; }
done

if [ "$NM" -gt 0 ]; then [ -z "$RAN" ] || lines "$W/L" || ref "the call's lines after the moves could not be made (next.sh triggers): the page is not written"
  [ -z "$RAN" ] || ownp "$W/L"
  [ -z "$RAN" ] || { echo 'after the moves:'; grep -v "^counted$TAB" "$W/L"; }; fi
# GM-4 F4: what the call raised kept in the owner's queue, each trigger and move a `Q<n>` line
sh "$HERE/queue.sh" raise "$W/L" > "$W/so" 2>&1 || { sed 's/^/    /' "$W/so" >&2; ref 'what the call raised could not be kept (queue.sh raise)'; }
sh "$HERE/next-page.sh" write "$W/L" > "$W/pg" 2>&1 || { sed 's/^/    /' "$W/pg"; echo 'page: not written (the lines above)'; exit 1; }
cat "$W/pg"
# GM-4 K6, I6: each open `Q<n>` line with the answers it takes
sh "$HERE/queue.sh" list 2> "$W/so" || { sed 's/^/    /' "$W/so" >&2; echo "queue: not listed (queue.sh list)"; exit 1; }; exit 0

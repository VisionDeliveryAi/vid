#!/bin/sh
# Purpose: /vid next's moves (GitHub manual, GM-2 T10, T4; GM M16 steps 5 to 7): what the call showed kept, each move the owner
# named checked and done in the order named, each saved before the next, and the plan page written. Run from the top of ViD's
# repository in GitHub manual alone (lib.sh manual), after vid-read and vid-triggers (the call's steps 3 and 4) and before
# vid-connect's end, inside the call's lock. Every script it calls is marked as the call's own (VID_CALLER=next). It holds no
# rule of a move: each is the script's it calls.
#   call [<move> [-- <move>]…]   in order:
#     1. the call's lines (next.sh triggers, from the records and the call's read, .vid/next/read); the listing the owner saw, the
#        last call's .vid/next/moves, set aside first; then next.sh shown on the lines (GM-2 T9, T10);
#     2. each move named, in the order named: checked against the listing (a move of the call's lines whose hash is the one the
#        listing showed; else `again`, its move and warning lines printed, and not done); done; its to-do logged done
#        (next-page.sh todo-done … move); the records saved (github.sh state-save) before the next starts. Before each later
#        move the call's lines are made again from the records, with no new read, and the call's lock renewed (github.sh
#        lock-renew). A `done` of a to-do that is a move of the lines is checked as that move; a `decline`, and a `done` of a
#        critical trigger's to-do, each trigger it reaches as the lines stand then against .vid/next/shown as the listing left it
#        (its tier and evidence key; a minor one keeps no entry). A refusal stops that move alone, naming its
#        step and its words; a save that fails stops the call, the moves after it not done;
#     3. with moves named, .vid/next/shown put back as the last call left it once step 1's `shown` wrote .vid/next/moves, and
#        after the moves the call's lines (made again when a move ran, and then printed, `counted` lines left out) kept as shown;
#     4. the plan page (next-page.sh write on the call's last lines): its `page <path>` line.
#   shell <page>   the plan page's fixed shell (GM-2 T12), plan-shell.html beside the page: it shows plan.html, the data file the
#                  vid-next skill publishes to the same link; prints `shell <path>`
# The moves (GM-2 T10's table), named by kind and subject, never by a number, the owner's words their last argument:
#   publish <step> "<words>" [--title "<title>"]   (T4) in order: a step ticket other than the skeleton's with no engines in the
#        handed record refused, naming the engines move; its own replan stage opened (T2), unless a stage is open already;
#        github.sh spec-export (it pushes only when what it holds changed); github.sh tw-sync; github.sh round-read into
#        .vid/round/read, and github.sh tw-handovers; plan.sh start <step>; writer.sh write skeleton for the plan's skeleton step
#        (kind: skeleton), else write step <step>, which checks what it writes; github.sh tw-post --words (and --title); then,
#        once the log holds the post, the warnings the listing showed kept with the words in .vid/next/published (GM-2 §5), the
#        new ticket's `ticket <n> OPEN - <now>` line and its body as posted (the form at its recorded hash, filled from
#        .vid/tw/form/issue-<n>) added to .vid/next/read; its stage ended; the records saved. Never refused for a warning
#   engines "<primary> <other>…" "<words>"   (T4) `engines <them> | stand-in: owner at <now>, words "<words>"` in .vid/tw/handed
#   answer #<n>:<k> [there] "<words>"   (T8) queue.sh answer <n>:<k> [there] "<words>"
#   decline <what> [<subject>] "<words>"   (T9) next.sh decline; each critical trigger it reaches, its to-do logged done
#   done "<kind> <subject>" "<words>"   (T12) next-page.sh todo-done <kind> <subject> words "<words>"
#   amend #<n> "<words>"   (T5) the preparation a publish makes (the export, the sync, the round's read, the handovers); writer.sh
#        write amend <n>; github.sh tw-post --amend <n> --words "<words>"
#   withdraw #<n> "<words>"   (T6) the same preparation; github.sh tw-close --words "<words>" <n>
#   team-change #<n> <id> yes|no "<words>"   (T7) team-change.sh <n> <id> yes|no "<words>", which makes its own preparation and
#        amends or withdraws each ticket the change reaches
#   After any move, each ticket it amended is read back from GitHub (github.sh next-read) into .vid/next/read, and each it
#   withdrew is closed there (T10)
#   analyse, apply   done from phase 3
# Prints a line a move: `done <kind> <subject>: <what>`, `refused <kind> <subject> at <step>: <its words>` (the step's output
#   under it, indented), `again <kind> <subject>: <why>; shown again, not done` (then its move and warning lines), `not done <kind>
#   <subject>: <why>`, `not saved: …`; then `after the moves:` and the lines, when a move ran; then `page <path>`.
#   Exit 0; 1 when the call's lines cannot be made, a save fails or the page cannot be written; 2 a usage error, before anything.
# Usage: sh checks/next-move.sh call [<move> [-- <move>]…] | shell <page>
# serves: tickets
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
VID_CALLER=next; export VID_CALLER
W=$(mktemp -d); SIT=''; SN=''; MK=''; MS=''
# stend: the move's own replan stage ended, when one is open (every path, a refusal and an exit too)
stend() { [ -n "$SIT" ] || return 0; SIT=''; sh "$HERE/event.sh" "stage name=replan state=end session=$SN" > /dev/null 2>&1 || echo "ViD next-move: the end of the move's replan stage was not recorded (session $SN)" >&2; }
trap 'stend; rm -rf "$W"' EXIT; trap 'exit 1' INT TERM
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
mkdir "$W/m"; NM=0; NEW=1
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
    answer) { [ "$na" = 3 ] || { [ "$na" = 4 ] && [ "$(arg 3)" = there ]; }; } && printf '%s' "$s" | grep -Eq '^#?[0-9]+:[0-9]+$' || { echo 'ViD next-move: usage — answer #<n>:<k> [there] "<words>"' >&2; exit 2; } ;;
    decline) [ "$na" = 3 ] || [ "$na" = 4 ] || { echo 'ViD next-move: usage — decline <what> [<subject>] "<words>"' >&2; exit 2; } ;;
    amend|withdraw) [ "$na" = 3 ] && printf '%s' "$s" | grep -Eq '^#?[0-9]+$' || { echo "ViD next-move: usage — $k #<n> \"<words>\"" >&2; exit 2; } ;;
    team-change) [ "$na" = 5 ] && printf '%s' "$s" | grep -Eq '^#?[0-9]+$' && case $(arg 4) in yes|no) true ;; *) false ;; esac || { echo 'ViD next-move: usage — team-change #<n> <id> yes|no "<words>"' >&2; exit 2; } ;;
    analyse|apply) ;;
    *) echo "ViD next-move: usage — $k is no move: publish, amend, withdraw, team-change, answer, done, decline or engines, each by its kind and subject" >&2; exit 2 ;;
  esac; done

manual || ref 'the moves are GitHub manual'"'"'s (/vid next): this project is not in it'
[ -f .vid/next/read ] || ref "no read of this call (.vid/next/read): the call's read comes first (vid-read)"
# lines <file>: the call's lines, next.sh triggers from the records
lines() { sh "$HERE/next.sh" triggers > "$1" 2> "$W/te" && return 0; sed 's/^/    /' "$W/te" >&2; return 1; }
cp .vid/next/moves "$W/moves0" 2> /dev/null || : > "$W/moves0"
lines "$W/L" || ref "the call's lines could not be made (next.sh triggers): no move is done"
# .vid/next/shown as the last call left it, set aside; with moves named it is put back after this `shown`, so the
# lines made again after the moves still show what this call raises first (the page is written from them); the closing `shown`
# keeps them. .vid/next/moves stays as this `shown` wrote it, the hashes todo-done reads
if [ -f .vid/next/shown ]; then cp .vid/next/shown "$W/shown0"; SH0=1; else : > "$W/shown0"; SH0=''; fi
sh "$HERE/next.sh" shown "$W/L" > "$W/so" 2>&1 || { sed 's/^/    /' "$W/so" >&2; ref 'what the call showed could not be kept (next.sh shown): no move is done'; }
if [ "$NM" -gt 0 ]; then if [ -n "$SH0" ]; then put .vid/next/shown < "$W/shown0" || exit 1; else rm -f .vid/next/shown; fi; fi

# no <step> <words>: the move refused at its step, its output under it
no() { echo "refused $MK $MS at $1: $2"; [ ! -s "$W/so" ] || grep -v '^[[:space:]]*$' "$W/so" | head -n 20 | sed 's/^/    /'; : > "$W/so"; }
# step <what> <command…>: the command run, its output kept; a failure refuses the move at that step, its words its last line
step() { _w=$1; shift; "$@" > "$W/so" 2>&1 && return 0; no "$_w" "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 1; }
# ston: the move's own replan stage (GM-2 T2), unless a stage holds the gate open already
ston() { SIT=''; ! sh "$HERE/plan.sh" gate > /dev/null 2>&1 || return 0; SN=${CLAUDE_CODE_SESSION_ID:-next-$$-$(date +%s)}
  sh "$HERE/event.sh" "stage name=replan state=start session=$SN records=29" > "$W/so" 2>&1 || { no 'its stage' 'its replan stage could not be opened (event.sh)'; return 1; }; SIT=1; }
# chk <kind> <subject>: 0 when the call's lines hold the move with the hash the listing showed; 1 no such move now; 2 changed
chk() { _h=$(awk -F'\t' -v k="$1" -v s="$2" '$1 == "move" && $2 == k && $3 == s { print $4; exit }' "$W/L")
  _o=$(awk -F'\t' -v k="$1" -v s="$2" '$1 == k && $2 == s { print $3; exit }' "$W/moves0")
  [ -n "$_h" ] || { WHY="it is no move of the call's lines now"; return 1; }
  [ -n "$_o" ] || { WHY='the listing the owner saw did not show it'; return 2; }
  [ "$_h" = "$_o" ] || { WHY='what it would do, or its warnings, changed since the listing'; return 2; }; return 0; }
# shownow: the tier and evidence key of each trigger of the call's lines now, as next.sh shown keeps them, into $W/shownN; the
# records shown writes (.vid/next/shown, moves, declined) put back as they were (the lines as they stand before
# the move, so a subject an earlier move of the call brought in is compared too)
shownow() { for _f in shown moves declined; do if [ -f ".vid/next/$_f" ]; then cp ".vid/next/$_f" "$W/sv.$_f"; else rm -f "$W/sv.$_f"; fi; done
  _r=0; sh "$HERE/next.sh" shown "$W/L" > "$W/so" 2>&1 || _r=1; cp .vid/next/shown "$W/shownN" 2> /dev/null || : > "$W/shownN"
  for _f in shown moves declined; do if [ -f "$W/sv.$_f" ]; then put ".vid/next/$_f" < "$W/sv.$_f" || _r=1; else rm -f ".vid/next/$_f"; fi; done; : > "$W/so"; return $_r; }
# dchk <what> [<subject>]: 0 when each trigger a decline (or a done of a critical trigger's to-do) reaches, a `trigger` or `quiet`
# line of that what and subject in the call's lines now, stands in .vid/next/shown as the listing left it (the copy set aside) at
# the tier and evidence key it has now (shownow); a trigger with no entry now (a minor one) is not compared
dchk() { awk -F'\t' -v w="$1" -v s="${2:-}" -v A="$W/shown0" -v B="$W/shownN" 'BEGIN { while ((getline l < A) > 0) { split(l, a, "\t"); O[a[1] SUBSEP a[2]] = a[3] SUBSEP a[4] }
    while ((getline l < B) > 0) { split(l, a, "\t"); N[a[1] SUBSEP a[2]] = a[3] SUBSEP a[4] } }
    ($1 == "trigger" || $1 == "quiet") && $3 == w && (s == "" || $4 == s) { k = $3 SUBSEP $4; if ((k in N) && (!(k in O) || O[k] != N[k])) bad = 1 } END { exit bad }' "$W/L"; }
dlines() { awk -F'\t' -v w="$1" -v s="${2:-}" '($1 == "trigger" || $1 == "quiet") && $3 == w && (s == "" || $4 == s)' "$W/L"; }
mvlines() { awk -F'\t' -v k="$1" -v s="$2" '($1 == "move" || $1 == "warning") && $2 == k && $3 == s' "$W/L"; }
later() { awk -F'\t' -v k="$1" -v s="$2" '$1 == "move" && $2 == k && $3 == s && $5 ~ /done from phase 3$/ { f = 1 } END { exit !f }' "$W/L"; }
tdone() { sh "$HERE/next-page.sh" todo-done "$@" move > "$W/td" 2>&1 || echo "    its to-do was not logged done: $(tail -n 1 "$W/td")"; }
# skeleton: the plan's skeleton step (kind: skeleton)
skel() { plan_block | awk -F'|' '/^[ \t]*step[ \t]/ { for (i = 2; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "kind: skeleton") { s = $1; sub(/^[ \t]*step[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); print s; exit } } }'; }
# radd <n>: the new ticket's `ticket` line and its body as posted, added to the call's read after its last ticket or body line
radd() { _l=$(awk -v n="$1" '$1 == "published" && $2 == n { l = $0 } END { print l }' .vid/tw/log | sed 's/ words=".*$//'); _fh=$(printf '%s' "$_l" | sed -n 's/.* form=\([0-9a-f]*\)$/\1/p')
  printf 'ticket\t%s\tOPEN\t-\t%s\n' "$1" "$(now)" > "$W/ra"
  if [ -n "$_fh" ] && git cat-file blob "$_fh" > "$W/fo" 2> /dev/null && [ -f ".vid/tw/form/issue-$1" ]; then
    tr -d '\r' < "$W/fo" | awk -v R=".vid/tw/form/issue-$1" 'BEGIN { while ((getline l < R) > 0) { n++; i = index(l, "\t"); P[n] = substr(l, 1, i - 1); V[n] = substr(l, i + 1) } }
      NR == 1 { next } { t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) } k < n && t == P[k + 1] { k++; if (V[k] != "") B[++m] = V[k]; next } { B[++m] = $0 }
      END { while (m > 0 && B[m] == "") m--; for (i = 1; i <= m; i++) print B[i] }' | sed "s/^/body$TAB$1$TAB/" >> "$W/ra"
  else echo "    #$1's body is not added to the call's read: no form or form record of it"; fi
  awk -F'\t' -v A="$W/ra" '{ L[NR] = $0; if ($1 == "ticket" || $1 == "body") k = NR; else if (!f && ($1 == "sub" || $1 == "assigned" || $1 == "abody")) f = NR }
    END { if (!k) k = (f ? f - 1 : NR); for (i = 1; i <= k; i++) print L[i]; while ((getline l < A) > 0) print l; for (i = k + 1; i <= NR; i++) print L[i] }' .vid/next/read > "$W/rn" && put .vid/next/read < "$W/rn"; }

# prep: the preparation every move that writes a ticket makes (GM-2 T4, T5): the export, the sync, the round's read, the handovers
prep() { step 'the export' sh "$HERE/github.sh" spec-export || return 1
  step 'the sync' sh "$HERE/github.sh" tw-sync || return 1
  mkdir -p .vid/round; sh "$HERE/github.sh" round-read > "$W/rr" 2> "$W/so" || { no "the round's read" "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 1; }; put .vid/round/read < "$W/rr"
  step 'the handovers' sh "$HERE/github.sh" tw-handovers || return 1; }
# rback <the log's line count before the move>: each ticket the move amended or withdrew (its `amended` or `withdrawn` lines in
# the log since) read back from GitHub through github.sh next-read, phase 1's read, its `ticket` and `body` lines in the call's
# read replaced with what came back, so the next move and the page read the issue as GitHub holds it; a withdrawn
# one, which that read leaves out, has its ticket line closed, as tw-close closed it
rback() { _ns=$(awk -v n0="$1" 'NR > n0 && ($1 == "amended" || $1 == "withdrawn") { print $2 }' .vid/tw/log | sort -un); [ -n "$_ns" ] || return 0
  _rd=''; for _n in $_ns; do
    if grep -q "^withdrawn $_n " .vid/tw/log; then awk -F'\t' -v OFS='\t' -v n="$_n" '$1 == "ticket" && $2 == n { $3 = "CLOSED" } { print }' .vid/next/read > "$W/rn" && put .vid/next/read < "$W/rn"; continue; fi
    [ -n "$_rd" ] || { sh "$HERE/github.sh" next-read > "$W/rb" 2> /dev/null || :; _rd=1; }
    if awk -F'\t' -v n="$_n" '$1 == "unread" && $3 == n { f = 1 } END { exit !f }' "$W/rb" || ! awk -F'\t' -v n="$_n" '$1 == "ticket" && $2 == n { f = 1 } END { exit !f }' "$W/rb"; then
      echo "    #$_n could not be read back from GitHub: the call's read keeps it as it was before the move"; continue; fi
    awk -F'\t' -v n="$_n" -v B="$W/rb" 'BEGIN { while ((getline l < B) > 0) { split(l, a, "\t"); if ((a[1] == "ticket" || a[1] == "body") && a[2] == n) R[++k] = l } }
      ($1 == "ticket" || $1 == "body") && $2 == n { if (!d) { for (i = 1; i <= k; i++) print R[i]; d = 1 } next } { print }' .vid/next/read > "$W/rn" && put .vid/next/read < "$W/rn"
  done; }
mv_amend() { N=${MS#\#}; WD=$(arg 3); prep || return 0
  TF=$(sh "$HERE/writer.sh" write amend "$N" 2> "$W/so") || { no 'the write and its check' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  TF=$(printf '%s\n' "$TF" | tail -n 1); NL=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0); PRC=0
  sh "$HERE/github.sh" tw-post --amend "$N" --words "$WD" "$TF" > "$W/so" 2>&1 || PRC=$?
  awk -v n0="$NL" -v n="$N" 'NR > n0 && $1 == "amended" && $2 == n { f = 1 } END { exit !f }' .vid/tw/log || { no 'the post' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  if [ "$PRC" = 0 ]; then echo "done amend $MS: amended in the owner's words"; else echo "done amend $MS: amended and recorded; then refused: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; fi
  tdone amend "$MS"; }
mv_withdraw() { N=${MS#\#}; WD=$(arg 3); prep || return 0; NL=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0); PRC=0
  sh "$HERE/github.sh" tw-close --words "$WD" "$N" > "$W/so" 2>&1 || PRC=$?
  awk -v n0="$NL" -v n="$N" 'NR > n0 && $1 == "withdrawn" && $2 == n { f = 1 } END { exit !f }' .vid/tw/log || { no 'the withdrawal' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  if [ "$PRC" = 0 ]; then echo "done withdraw $MS: withdrawn in the owner's words"; else echo "done withdraw $MS: withdrawn and recorded; then refused: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; fi
  tdone withdraw "$MS"; }
mv_team() { N=${MS%% *}; N=${N#\#}; ID=$(arg 3); AN=$(arg 4); WD=$(arg 5); NA=$(grep -c '' .vid/next/team-answers 2> /dev/null || echo 0); PRC=0
  sh "$HERE/team-change.sh" "$N" "$ID" "$AN" "$WD" > "$W/so" 2>&1 || PRC=$?
  awk -F'\t' -v n0="$NA" -v n="$N" -v id="$ID" 'NR > n0 && $1 == n && $3 == id { f = 1 } END { exit !f }' .vid/next/team-answers 2> /dev/null || { no 'the team change' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  if [ "$PRC" = 0 ]; then echo "done team-change $MS: $AN, in the owner's words"; else echo "done team-change $MS: $AN recorded; then: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; fi
  [ ! -s "$W/so" ] || grep -v '^[[:space:]]*$' "$W/so" | sed 's/^/    /'; tdone team-change "$MS"; }
mv_publish() { S=$MS; WD=$(arg 3); TI=''; [ "$na" -lt 5 ] || TI=$(arg 5); SK=$(skel)
  if [ "$S" != "$SK" ] && [ -z "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' .vid/tw/handed 2> /dev/null | tail -n 1)" ]; then
    no 'the engines' 'no engines on record, which a step ticket names: record them first, /vid next engines "<primary> <other>…" "<your words>"'; return 0; fi
  ston || return 0
  prep || return 0
  step 'the admission' sh "$HERE/plan.sh" start "$S" || return 0
  if [ "$S" = "$SK" ]; then set -- skeleton; else set -- step "$S"; fi
  TF=$(sh "$HERE/writer.sh" write "$@" 2> "$W/so") || { no 'the write and its check' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  TF=$(printf '%s\n' "$TF" | tail -n 1); NL=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0); PRC=0
  if [ -n "$TI" ]; then sh "$HERE/github.sh" tw-post --words "$WD" --title "$TI" "$TF" > "$W/so" 2>&1 || PRC=$?; else sh "$HERE/github.sh" tw-post --words "$WD" "$TF" > "$W/so" 2>&1 || PRC=$?; fi
  N=$(awk -v n0="$NL" 'NR > n0 && $1 == "published" { print $2 }' .vid/tw/log | tail -n 1)
  [ -n "$N" ] || { no 'the post' "$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; return 0; }
  PE=$(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)
  WS=$(awk -F'\t' -v s="$S" '$1 == "warning" && $2 == "publish" && $3 == s { printf "%s%s %s", p, $4, $5; p = " | " }' "$W/L")
  mkdir -p .vid/next; printf '%s\t%s\t%s\t%s\t%s\n' "$N" "$S" "${WS:--}" "$(now)" "$(one "$WD")" >> .vid/next/published
  radd "$N"; stend
  if [ "$PRC" = 0 ]; then echo "done publish $S: #$N posted, in the owner's words"; else echo "done publish $S: #$N posted and recorded; then refused at the post's links: $PE"; fi
  tdone publish "$S"; }
mv_engines() { E=$(arg 2); WD=$(arg 3)
  printf '%s' "$E" | grep -Eq '^[A-Za-z0-9._+-]+( [A-Za-z0-9._+-]+)*$' || { no 'the engines' "\"$E\" is not the engines' names, the primary first, a space between"; return 0; }
  [ -n "$(printf '%s' "$WD" | tr -d '[:space:]')" ] || { no 'the words' 'the engines go on record only in the owner'"'"'s words'; return 0; }
  mkdir -p .vid/tw; printf 'engines %s | stand-in: owner at %s, words "%s"\n' "$E" "$(now)" "$(one "$WD")" >> .vid/tw/handed; echo "done engines $E: on record, the owner its stand-in"; }
mv_answer() { WD=$(arg "$na"); set -- "${MS#\#}"; [ "$na" = 3 ] || set -- "$1" there
  step 'the answer' sh "$HERE/queue.sh" answer "$@" "$WD" || return 0; echo "done answer $MS: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"; tdone answer "$MS"; }
mv_decline() { WD=$(arg "$na"); if [ "$na" = 4 ]; then set -- "$MS" "$(arg 3)"; else set -- "$MS"; fi
  step 'the decline' sh "$HERE/next.sh" decline "$@" "$WD" || return 0; echo "done decline $*: $(grep -v '^[[:space:]]*$' "$W/so" | tail -n 1)"
  awk -F'\t' -v w="$1" -v s="${2:-}" '$1 == "trigger" && $2 == "critical" && $3 == w && (s == "" || $4 == s) { print $4 }' "$W/L" | while IFS= read -r x; do tdone "$1" $x; done; }
mv_done() { WD=$(arg 3); set -- $MS; step 'the to-do' sh "$HERE/next-page.sh" todo-done "$@" words "$WD" || return 0; echo "done done $MS: off the to-do list, in the owner's words"; }

i=0; RAN=''; while [ $i -lt "$NM" ]; do i=$((i + 1)); F=$W/m/$i; na=$(grep -c '' "$F"); MK=$(arg 1); MS=$(arg 2)
  [ -z "$RAN" ] || lines "$W/L" || { echo "not done $MK $MS: the call's lines could not be made again; the moves after it are not done"; exit 1; }
  # the call's lock renewed before each move after the first, so a long call keeps it
  [ "$i" = 1 ] || sh "$HERE/github.sh" lock-renew > "$W/lr" 2>&1 || { sed 's/^/    /' "$W/lr"; echo "not done $MK $MS: the call's lock could not be renewed; the moves after it are not done"; exit 1; }
  case $MK in
    analyse|apply) echo "not done $MK: done from phase 3"; continue ;;
    answer) MS="#${MS#\#}" ;; amend|withdraw) MS="#${MS#\#}" ;; team-change) MS="#${MS#\#} $(arg 3)" ;;
  esac
  case $MK in
    publish|answer|amend|withdraw|team-change) rc=0; chk "$MK" "$MS" || rc=$?
      if [ "$rc" = 1 ]; then echo "not done $MK $MS: $WHY"; continue; fi
      if [ "$rc" = 2 ]; then echo "again $MK $MS: $WHY; shown again, not done"; mvlines "$MK" "$MS"; continue; fi
      if later "$MK" "$MS"; then echo "not done $MK $MS: done from phase 3, as its line says"; continue; fi ;;
    # a to-do that is a move of the call's lines is checked as its move is; a decline, each trigger it reaches
    done) DK=${MS%% *}; DS=${MS#* }; [ "$DS" != "$MS" ] || DS=''
      if awk -F'\t' -v k="$DK" -v s="$DS" '$1 == "move" && $2 == k && $3 == s { f = 1 } END { exit !f }' "$W/L"; then rc=0; chk "$DK" "$DS" || rc=$?
        if [ "$rc" != 0 ]; then echo "again $MK $MS: $WHY; shown again, not done"; mvlines "$DK" "$DS"; continue; fi
      # a critical trigger's to-do, checked against the tier and evidence key the listing showed
      elif awk -F'\t' -v w="$DK" -v s="$DS" '$1 == "trigger" && $2 == "critical" && $3 == w && $4 == s { f = 1 } END { exit !f }' "$W/L"; then
        shownow || { echo "not done $MK $MS: the call's lines could not be compared with the listing (next.sh shown)"; continue; }
        dchk "$DK" "$DS" || { echo "again $MK $MS: its trigger's evidence changed since the listing; shown again, not done"; dlines "$DK" "$DS"; continue; }; fi ;;
    decline) if [ "$na" = 4 ]; then DS=$(arg 3); else DS=''; fi
      shownow || { echo "not done $MK $MS: the call's lines could not be compared with the listing (next.sh shown)"; continue; }
      dchk "$MS" "$DS" || { echo "again $MK $MS${DS:+ $DS}: a trigger it reaches was not shown at the listing, or changed since; shown again, not done"; dlines "$MS" "$DS"; continue; } ;;
  esac
  : > "$W/so"; RAN=1; NL0=$(grep -c '' .vid/tw/log 2> /dev/null || echo 0)
  case $MK in publish) mv_publish ;; engines) mv_engines ;; answer) mv_answer ;; decline) mv_decline ;; done) mv_done ;; amend) mv_amend ;; withdraw) mv_withdraw ;; team-change) mv_team ;; esac
  stend; rback "$NL0"
  sh "$HERE/github.sh" state-save > "$W/sv" 2>&1 || { sed 's/^/    /' "$W/sv"; echo "not saved: the records after $MK $MS could not be saved ($(tail -n 1 "$W/sv")); the moves after it are not done"; exit 1; }
done

if [ "$NM" -gt 0 ]; then [ -z "$RAN" ] || lines "$W/L" || ref "the call's lines after the moves could not be made (next.sh triggers): the page is not written"
  sh "$HERE/next.sh" shown "$W/L" > "$W/so" 2>&1 || { sed 's/^/    /' "$W/so" >&2; ref 'what the call showed after the moves could not be kept (next.sh shown)'; }
  [ -z "$RAN" ] || { echo 'after the moves:'; grep -v "^counted$TAB" "$W/L"; }; fi
sh "$HERE/next-page.sh" write "$W/L" > "$W/pg" 2>&1 || { sed 's/^/    /' "$W/pg"; echo 'page: not written (the lines above)'; exit 1; }
cat "$W/pg"; exit 0

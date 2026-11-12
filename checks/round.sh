#!/bin/sh
# Purpose: ViD's round (v0.26.10.25.1 R4, R5, R10): what the run manager does that needs no judgement, so a long session spends almost nothing
# while nothing is new. It reads no code, runs nothing and starts no agent. The session, skills/vid-run, does what does need judgement.
#   wait   R3's read each VID_WAIT_TICK seconds (60), with no model. Prints `new` as soon as something is new from the dev side, or `timeout` after
#          VID_WAIT_MAX seconds (540); either way it renews the lock. ViD's own posts never end a wait.
#   step   renews the lock; reads; fetches if anything is new; stops on an open ticket issue the log does not hold; records each merge, closes its
#          ticket's issue, and writes the interim `closed <step>` when it was the step's last open ticket; withdraws a ticket closed outside ViD
#          (`closed-outside <n> …`, 8.1b R1) and reopens a closed step a reopened ticket reaches (`step-reopened <s> #<n>`, or `closed-stage-rows
#          <s> <N>` for a stage already closed, R3); answers each unanswered `vid: decide <head>`, saving before it posts; the closes owed
#          (close.sh owed, each step's `close.sh decide`), the walk's pending acts (walk.sh pending) and the owner's grade asks (grade.sh step);
#          `summary <N>` for a stage close owed with no summary yet, `plan-stage <N>` while the next stage has no step; the queue's lines
#          (queue.sh sync) and `update` when the progress update is due; the alarms; RUN-STATE.md; the save. One line for each thing done and
#          each thing that waits: `decided`, `merged`, `held <row>`, `question <n>`, `flag <word>`, `nothing-left` (no ticket open and no step
#          can start) or `idle`, and `progress:`.
#   next   renews the lock; nothing if the run is stopped, which a recorded pause is; the export; the sync; each line `writer.sh due` owes, in order;
#          then each step in plan order `plan.sh start` passes, up to the open-ticket limit. A save follows each post. `published <n>`; a refusal is
#          a line once, tried again only after the plan or the handed record changed.
# An error names its step and exits 1; a lost lock prints `lock-lost` and exits 3; an open ticket the log does not hold prints `stop stray …` and exits 4, in step and in next, and nothing more is written.
# `stand-in: on` in .vid/tw/settings, off by default and never written by ViD: a held row with only its evidence missing is accepted, a held weak
# test ruled a known limit, each --by stand-in, a line in .vid/tw/stood-in-answers.txt. A held product failure waits, switch or no switch.
# Settings: ticket-hours: (8), quiet-hours: (2), open-tickets:. Records: .vid/decide/merged-prs, refused, flags, accepted-log, saved; .vid/round/, not.
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
[ -f .vid/RUN-STATE.md ] && [ -f .vid/tw/settings ] || { echo "ViD round: run it at the top of ViD's repository, in ticket mode" >&2; exit 2; }
D=.vid/decide; L=.vid/round; LOG=.vid/tw/log; HAND=.vid/tw/handed; mkdir -p "$D" "$L"; touch "$D/merged-prs" "$D/refused" "$D/flags" "$D/accepted-log" "$D/rulings"
TAB=$(printf '\t'); DID=''
gh_() { sh "$HERE/github.sh" "$@"; }; dec() { sh "$HERE/decide.sh" "$@"; }; wr() { sh "$HERE/writer.sh" "$@"; }
PX=$(skey labels-prefix)
fail() { n=$(($(cat .vid/round-errors 2>/dev/null || echo 0) + 1)); echo "$n" > "$L/re" || exit 1; put .vid/round-errors < "$L/re" || exit 1; ev "round-error step=$1 count=$n"; echo "error $1 ($n running): $2"; exit 1; }
stray() { for n in $(tickets); do grep -qE "^(published|asked) $n " "$LOG" 2>/dev/null || { ev "round-stop stray=$n"; echo "stop stray: #$n is an open ticket the log does not hold: a publication's save was lost, so nothing more is published"; exit 4; }; done; }
renew() { rc=0; gh_ lock-renew > "$L/e" 2>&1 || rc=$?; [ "$rc" != 3 ] || { echo 'lock-lost'; exit 3; }; [ "$rc" = 0 ] || fail lock-renew "$(tail -n 1 "$L/e")"; }
read_() { gh_ round-read > "$L/rd" 2> "$L/e" || fail round-read "$(tail -n 1 "$L/e")"; put "$L/read" < "$L/rd" || fail round-read "$(tail -n 1 "$L/e")"; }
# what is new from the dev side: unanswered asks, unrecorded merges, blocked questions
sig_() { awk -F'\t' -v M="$D/merged-prs" -v B=",${PX}blocked," -v W=" $(cow | tr '\n' ' ') " 'BEGIN { while ((getline l < M) > 0) m[l] = 1 } $1 == "open" && $7 + 0 > $8 + 0 && index(W, " " $3 " ") == 0 { print "ask", $2, $4 } $1 == "merged" && !($2 in m) { print "merged", $2 } $1 == "issue" && index("," $3 ",", B) { print "question", $2 } $1 == "open" && index("," $6 ",", B) { print "question", $2 }
  function cnt(h, p,   c, i, n, k) { n = split(h, c, "\001"); for (i = 1; i <= n; i++) if (c[i] ~ p) k++; return k + 0 }
  $1 == "issue" && (index("," $3 ",", RUN) || index("," $3 ",", GRD) || index("," $3 ",", DPL)) { print "reported", $2, cnt($4, "^vid: reported ") }
  $1 == "issue" { q = cnt($4, "^(Question:|[A-Z][A-Z]: [Qq]uestion)"); if (q) print "qs", $2, q } $1 == "open" { q = cnt($10, "^(Question:|[A-Z][A-Z]: [Qq]uestion)"); if (q) print "qs", $2, q }
  $1 == "main" { print "main", $2 }
  $1 == "result" && ($2 ~ /^stopped-/ || ST) { print "result", $2, $3 }' RUN=",${PX}run," GRD=",${PX}grade," DPL=",${PX}deploy," ST="$(grep -q '^devagent-stopped ' "$D/flags" 2>/dev/null && echo 1)" "$L/read"; }   # v0.26.10.28.2 (R4): the code repository's main, so a wait notices it
# v0.26.10.28.6 (R3): the dev side's stopped reports, and while devagent-stopped stands every report, so a stop, and the report that clears it, end a wait
tickets() { awk -F'\t' -v T=",${PX}ticket," -v U=",${PX}run," -v G=",${PX}grade," -v P=",${PX}deploy," '$1 == "issue" && (index("," $3 ",", T) || index("," $3 ",", U) || index("," $3 ",", G) || index("," $3 ",", P)) { print $2 }' "$L/read"; }
open_() { for n in $(tickets); do m=$(awk -F'\t' -v n="$n" '$1 == "merged" && $3 == n { print $2 }' "$L/read" | head -n 1); [ -n "$m" ] && grep -qx "$m" "$D/merged-prs" || echo "$n"; done; }
plan_steps() { plan_block | sed -n 's/^step \([^ |]*\).*/\1/p'; }
started() { grep '^step-start ' .vid/metrics-events 2>/dev/null | grep -q " step=$1 "; }
# change_: the refusal key, the plan block, the handed record and (v0.26.10.28.2, R4) the newest tw-sync's main, so a ticket refused for want of main is tried again
change_() { rkey; }   # lib.sh (0.26.10.28.4)
refused() { grep -qxF "$1 $(change_)" "$D/refused"; }
refuse() { refused "$1" || { echo "$1 $(change_)" >> "$D/refused"; ev "round-refused what=$(printf %s "$1" | tr ' ' '-')"; echo "refused $1: $2"; }; }
said() { printf '%s\t%s\t%s\t%s\n' "$(stamp)" "$1" "$2" "$3" >> .vid/tw/stood-in-answers.txt; }
# the switch: never a held product failure
table() { awk -F'\t' '$3 == "held" { print $1 "\t" $4 "\t" ($8 == "" ? "-" : $8) "\t" $6 }' "$D/pr-$1-$2.rows" > "$L/rows"
  while IFS=$TAB read -r r un t3 l <&3; do case $l in *'a product failure'*) continue ;; esac
    if [ "$un" = 'evidence missing' ] && [ "$t3" = passed ]; then w=accept; c='held, its tests passing, only its evidence missing'; else case $l in *'a weak test'*) w=limit; c='a held weak test' ;; *) continue ;; esac; fi
    dec rule "$r" "$w" --by stand-in > /dev/null 2>&1 && said "$r" "$w" "$c"; done 3< "$L/rows"; }
# ask <ticket> <pr> <head> ask|re: `ask`, a `vid: decide` newer than its answer, is always answered, unchanged or not; `re`, a re-decide a ruling
# or an answer started, is posted only when it differs from the decision posted at that head (v0.26.10.28.6, R4)
ask() { t=$1; p=$2; H=$3; h=$(printf %s "$H" | cut -c1-12); m=${4:-ask}
  sh "$HERE/results.sh" read --ticket "$t" --pr "$p" --head "$H" > /dev/null 2> "$L/e" || fail results "$(tail -n 1 "$L/e")"
  dec decide --ticket "$t" --pr "$p" --head "$H" > /dev/null 2> "$L/e" || fail decide "$(tail -n 1 "$L/e")"; dec queue > /dev/null 2>&1
  if [ "$(skey stand-in)" = on ]; then table "$p" "$h"; dec decide --ticket "$t" --pr "$p" --head "$H" > /dev/null 2> "$L/e" || fail decide "$(tail -n 1 "$L/e")"; dec queue > /dev/null 2>&1; fi
  gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; [ "$m" = re ] || rm -f "$D/posted-pr-$p-$h"   # an ask always gets its answer
  b=''; [ ! -f "$D/posted-pr-$p-$h" ] || b=$(cksum < "$D/posted-pr-$p-$h")
  dec decide --ticket "$t" --pr "$p" --head "$H" --post > /dev/null 2> "$L/e" || fail post "$(tail -n 1 "$L/e")"
  a=''; [ ! -f "$D/posted-pr-$p-$h" ] || a=$(cksum < "$D/posted-pr-$p-$h")
  [ "$m" = ask ] || [ "$a" != "$b" ] || return 0; echo "decided $p $h $(sed -n 2p "$D/posted-pr-$p-$h")"; DID=1; }
# touch_ (R4): what the rulings and answers added since the last step touch, in $L/touch: `row <id>` for a ruling's row and a held row's answer,
# `on <n>` for a question's issue or pull request, `ticket <n>` for a finding's ticket. `ruled` holds the two files' line counts; an older
# one-number form that matches their sum reads as nothing new, and any other as everything new. Only the lines there now are read, and
# ruled_ saves these counts, so a line written while the step runs, by its own decisions or by an answer, is the next step's
touch_() { a1=$(wc -l < "$D/rulings" | tr -d ' '); a2=$(cat "$D/queue/answers" 2>/dev/null | wc -l | tr -d ' '); set -- $(cat "$D/ruled" 2>/dev/null || echo 0)
  if [ $# -ge 2 ]; then r0=$1; q0=$2; elif [ "${1:-0}" = $((a1 + a2)) ]; then r0=$a1; q0=$a2; else r0=0; q0=0; fi
  { [ "$r0" -ge "$a1" ] || sed -n "$((r0 + 1)),${a1}p" "$D/rulings" | awk -F'\t' 'NF >= 2 && $2 != "" { print "row\t" $2 }'
    [ "$q0" -ge "$a2" ] || sed -n "$((q0 + 1)),${a2}p" "$D/queue/answers" 2>/dev/null | awk -F'\t' '{ n = split($2, x, ":"); if (x[1] == "held") print "row\t" substr($2, 6); else if (x[1] == "question" && n >= 2) print "on\t" x[2]; else if ((x[1] == "finding" || x[1] == "findings") && n >= 2) print "ticket\t" x[2] }'; } > "$L/touch"
  printf '%s %s\n' "$a1" "$a2" > "$L/ru" || exit 1; }
ruled_() { put "$D/ruled" < "$L/ru" || exit 1; }
# the step close (v0.26.10.25.3, R8, R10): owed once a step's tickets have all merged, asked by next, decided at every step
cl() { sh "$HERE/close.sh" "$@" 2> "$L/e" || fail close "$(tail -n 1 "$L/e")"; }
plan_stage() { sh "$HERE/close.sh" nextplan 2>/dev/null || true; }   # v0.26.10.26.5 (R4)
merged_() { awk -F'\t' '$1 == "merged"' "$L/read" | sort -t"$TAB" -k2,2n > "$L/m"; while IFS=$TAB read -r x p t H M _r <&3; do grep -qx "$p" "$D/merged-prs" && continue
    if dec merged --pr "$p" > "$L/o" 2>&1; then [ "$t" = - ] || { gh_ close "$t" > /dev/null 2> "$L/e" || fail close "$(tail -n 1 "$L/e")"; }; printf '%s\t%s\t%s\t%s\n' "$p" "$t" "$H" "$M" >> "$D/merges"; echo "merged $p"
    elif grep -q 'no decision for pull request' "$L/o"; then ev "round-merged pr=$p decision=none"; echo "merged $p, no decision"; else fail merged "$(tail -n 1 "$L/o")"; fi; echo "$p" >> "$D/merged-prs"; DID=1; done 3< "$L/m"; }
# v0.26.10.27.3 (8.1b R1): a published ticket not withdrawn, not open in the read and no merged pull request naming it (merges, merged-prs
# with the read's merged lines, merged-tickets): its issue read once by tw-outside; CLOSED is withdrawn closed-outside, and its open pull
# request, no longer decided, gets one comment
cow() { awk '$1 == "withdrawn" && $3 == "decision=closed-outside" { print $2 }' "$LOG" 2>/dev/null | sort -u; }
outside_() { awk '$1 == "published" { p[$2] = 1 } $1 == "withdrawn" { delete p[$2] } END { for (n in p) print n }' "$LOG" 2>/dev/null | sort > "$L/pub"
  awk -F'\t' '$1 == "issue" { print $2 }' "$L/read" | sort -u > "$L/oi"
  { cut -f2 "$D/merges" 2>/dev/null; awk -F'\t' -v M="$D/merged-prs" 'BEGIN { while ((getline l < M) > 0) m[l] = 1 } $1 == "merged" && ($2 in m) { print $3 }' "$L/read"; cut -f1 "$D/merged-tickets" 2>/dev/null; } | sort -u > "$L/mt"
  for n in $(comm -23 "$L/pub" "$L/oi" | comm -23 - "$L/mt"); do o=$(gh_ tw-outside "$n" 2> "$L/e") || continue
    case $o in closed-outside*) s=$(awk -v n="$n" '$1 == "published" && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) s = substr($i, 6) } END { print s }' "$LOG"); echo "closed-outside $n $s"; DID=1 ;; esac; done
  for n in $(cow); do awk -F'\t' -v n="$n" '$1 == "open" && $3 == n { print $2 }' "$L/read" | while read -r p; do grep -qx "$p" "$D/outside-commented" 2>/dev/null && continue
      printf 'vid: ticket #%s was closed outside ViD and is withdrawn; its rows come in a new ticket.\n' "$n" > "$L/oc"; gh_ decide-post "$p" "$L/oc" > /dev/null 2>&1 && echo "$p" >> "$D/outside-commented"; done; done; }
# v0.26.10.27.3 (8.1b R3): once a ticket, its step reopened as a landing does (land.sh R5): the `closed <s>` line dropped, the newest
# close ask withdrawn, no handed line; a step of a closed stage stays closed, the owner told once
reopen_() { touch "$D/reopened"; DU=''; for n in $(cow); do
    s=$(awk -v n="$n" '$1 == "published" && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) s = substr($i, 6) } END { print s }' "$LOG"); [ -n "$s" ] || continue
    g=$(sed -n 's/^- stage: \([0-9]*\).*/\1/p' ".vid/tw/out/issue-$n.md" 2>/dev/null | head -n 1)
    if [ -n "$g" ] && grep -q "^stage-closed $g " "$HAND" 2>/dev/null; then grep -qx "$n" "$D/reopened" || { echo "$n" >> "$D/reopened"; echo "closed-stage-rows $s $g"; }; continue; fi
    # the state, not the round it was seen in: closed while the writer owes the step a new ticket
    grep -q "^closed $s " "$HAND" 2>/dev/null || continue
    # owed: `new step <s>`, or `new skeleton` for the skeleton's own step
    [ -n "$DU" ] || DU=$(wr due 2>/dev/null | tr '\n' '|'); SK=$(plan_block | awk -F' [|] ' '{ for (i = 2; i <= NF; i++) if ($i == "kind: skeleton") { s = $1; sub(/^[ \t]*step[ \t]+/, "", s); print s; exit } }')
    case "|$DU" in *"|new step $s|"*) ;; *"|new skeleton|"*) [ "$s" = "$SK" ] || continue ;; *) continue ;; esac
    grep -v "^closed $s " "$HAND" > "$L/h" || true; cat "$HAND" > "$L/h0"; put "$HAND" < "$L/h" || exit 1
    k=''; for j in $(ls "$D/close/$s" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/close/$s/$j/ask" ] && k=$j; done
    if [ -n "$k" ]; then [ -f "$D/close/$s/$k/withdrawn" ] || printf 'closed-outside #%s %s\n' "$n" "$(stamp)" > "$D/close/$s/$k/withdrawn"
    elif [ -f "$D/close/$s/ask" ] && [ ! -f "$D/close/$s/withdrawn" ]; then printf 'closed-outside #%s %s\n' "$n" "$(stamp)" > "$D/close/$s/withdrawn"; fi   # an ask not yet in a numbered folder
    ev "close-reopened step=$s ticket=$n"; echo "step-reopened $s #$n"; DID=1; done; }
flag() { F=$F" $1|$2"; grep -qxF "$1 $2" "$D/flags" && return 0; echo "$1 $2" >> "$D/flags"; ev "flag word=$1 on=$2"; echo "$(stamp) round: FLAG $1 $2${3:+: $3}" >> .vid/HEARTBEAT.md; echo "flag $1 $2${3:+: $3}"; }
# stopped_ (v0.26.10.28.6, R3): the dev side's newest report, by its commit's time, when it is a stopped one: its id and the stop's words
stopped_() { s=$(git --git-dir=.vid/code for-each-ref --sort=-refname --sort=-committerdate --format='%(refname:lstrip=3)' 'refs/heads/vid-results/' 2>/dev/null | head -n 1)
  case $s in stopped-*) w=$(git --git-dir=.vid/code show "refs/heads/vid-results/$s:$s/results.txt" 2>/dev/null | sed -n 's/^stopped: *//p' | head -n 1); printf '%s\t%s\n' "$s" "${w:-no reason given}" ;; esac; }
# R10: each once until it clears
alarms() { F=''; N=$(date +%s); H1=$(($(skey ticket-hours | grep . || echo 8) * 3600)); Q1=$(($(skey quiet-hours | grep . || echo 2) * 3600))
  for n in $(open_); do a=$(awk -v n="$n" '$1 == "published" && $2 == n' "$LOG" | tail -n 1 | tr ' ' '\n' | sed -n 's/^at=//p'); [ -z "$a" ] || [ $((N - $(epoch "$a"))) -le "$H1" ] || flag ticket-hours "$n"
    u=$(awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { print $5 } $1 == "open" && $3 == n { print $9 }' "$L/read" | sort | tail -n 1); [ -z "$u" ] || [ $((N - $(epoch "$u"))) -le "$Q1" ] || flag ticket-quiet "$n"; done
  # v0.26.10.28.3 (R2): no dev side answers: work tickets open (<prefix>ticket alone), none with a `vid: claimed` comment or a pull request naming it, and the newest `published` line older than quiet-hours
  q=$(awk -F'\t' -v T=",${PX}ticket," -v O=" $(open_ | tr '\n' ' ') " '$1 == "issue" && index("," $3 ",", T) && index(O, " " $2 " ") { t[$2] = 1; m = split($4, c, "\001"); for (i = 1; i <= m; i++) if (c[i] == "vid: claimed") s = 1 }
    $1 == "open" || $1 == "merged" { p[$3] = 1 } END { for (x in t) { k++; if (x in p) s = 1 } if (k && !s) print k }' "$L/read")
  a=$(awk '$1 == "published"' "$LOG" | tail -n 1 | tr ' ' '\n' | sed -n 's/^at=//p'); [ -z "$q" ] || [ -z "$a" ] || [ $((N - $(epoch "$a"))) -le "$Q1" ] || flag devagent-quiet "$q"
  # v0.26.10.28.6 (R3): the dev side stopped, its newest report a stopped one; a later report of any kind clears it
  s=$(stopped_); [ -z "$s" ] || flag devagent-stopped "${s%%	*}" "${s#*	}"
  A=$(awk -F'\t' '$2 == "accepted" || $2 == "accepted by ruling" { c++ } END { print c + 0 }' "$D/state" 2>/dev/null); A=${A:-0}; echo "$N $A" >> "$D/accepted-log"
  P=$(awk -v t=$((N - 3600)) '$1 >= t && $2 > m { m = $2 } END { print m + 0 }' "$D/accepted-log"); [ $((P - A)) -lt 20 ] || flag row-drop accepted
  for k in $(awk '{ print $1 "|" $2 }' "$D/flags"); do case " $F " in *" $k "*) ;; *) w=${k%%|*}; o=${k#*|}; grep -vxF "$w $o" "$D/flags" > "$L/f"; put "$D/flags" < "$L/f" || exit 1; ev "flag-cleared word=$w on=$o" ;; esac; done
  for r in $(sed -n 's/^unreleased //p' "$L/q" 2>/dev/null); do flag answer-not-released "$r"; done
  I=$(grep -cE '^(died|round-error|round-stop) ' .vid/metrics-events 2>/dev/null); echo "progress: accepted=$A open=$(open_ | grep -c .) incidents=$I"; }
held_() { for p in $(awk -F'\t' '$1 == "open" { print $2 "|" substr($4, 1, 12) }' "$L/read"); do f=$D/pr-${p%|*}-${p#*|}.rows; [ -f "$f" ] && awk -F'\t' '$3 == "held" { print $1 }' "$f"; done; }
skeep() { if grep -q "^$1:" "$L/rs"; then sed "s/^$1:.*/$1: $2/" "$L/rs" > "$L/rs2"; else sed "1a\\
$1: $2" "$L/rs" > "$L/rs2"; fi || return 1; [ -s "$L/rs2" ] && mv "$L/rs2" "$L/rs"; }   # never an empty RUN-STATE (R6)
# 0.26.10.28.4 (9.3 R2): the now: and held: lines through the run record's one writer, read inside its lock
rskeep() { cat > "$L/rs" || return 1; skeep now "$NW" || return 1; skeep held "${H:--}" || return 1; cat "$L/rs"; }
state_() { H=$(held_ | sort -u | paste -sd ' ' -); NW="accepted=$A open=$(open_ | grep -c .)"; rs_edit rskeep || exit 1; }
# v0.26.10.28.6 (R6): a wait records its start and its limit in .vid/round/wait, and removes it at its end, so the watcher counts it as activity;
# one a signal ends may leave it, and the watcher reads it as nothing past the limit and its margin
cmd_wait() { M=${VID_WAIT_MAX:-540}; T=${VID_WAIT_TICK:-60}; t0=$(date +%s); printf 'start=%s\nmax=%s\n' "$t0" "$M" > "$L/wait" || exit 1; trap 'rm -f "$L/wait"' EXIT; while :; do read_; sig_ > "$L/now"; if ! cmp -s "$L/now" "$L/seen"; then r=new; break; fi; [ $(($(date +%s) - t0 + T)) -le "$M" ] || { r=timeout; break; }; sleep "$T"; done; renew; echo "$r"; }
fetch_() { gh_ results-fetch > /dev/null 2> "$L/e" || fail results-fetch "$(tail -n 1 "$L/e")"; FT=1; }
cmd_step() { FT=''; renew; read_; sig_ > "$L/now"; cmp -s "$L/now" "$L/seen" || fetch_
  stray
  # v0.26.10.28.2 (R4): `main-changed` when the code repository's main differs from the last step's (never at the first), so vid-run runs next
  MN=$(grep '^main ' "$L/now" || true); MS=$(grep '^main ' "$L/seen" 2>/dev/null || true); [ -z "$MN" ] || [ -z "$MS" ] || [ "$MN" = "$MS" ] || { ev "round-main-changed main=${MN#main }"; echo main-changed; DID=1; }
  # an ask, or a ruling or answer made since the last step: rule leaves no comment, so a decided head it touches is decided again (R4,
  # v0.26.10.28.6: only the open pull requests it touches, by their head's rows, their ticket, or the issue or pull request asked on;
  # on results fetched first, and posted only when the decision changed)
  merged_; outside_; reopen_; touch_; awk -F'\t' -v OFS='\t' -v D="$D" -v TF="$L/touch" -v W=" $(cow | tr '\n' ' ') " 'BEGIN { while ((getline l < TF) > 0) { split(l, x, "\t"); if (x[1] == "row") { R[x[2]] = 1; b = x[2]; sub(/-T[0-9]+$/, "", b); R[b] = 1 } else if (x[1] == "on") O[x[2]] = 1; else K[x[2]] = 1 } }
    function hit(p, t, h,   f, l, y, r, b, n, i) { if ((p in O) || (t in O) || (t in K)) return 1; f = D "/pr-" p "-" h ".rows"; while ((getline l < f) > 0) { split(l, y, "\t"); r = y[1]; b = r; sub(/-T[0-9]+$/, "", b); if ((r in R) || (b in R)) { close(f); return 1 } } close(f)
      # the head evidence too: a row a landing reset out of the rows file can still stand in its grade lines
      f = ".vid/results/pr-" p "-" h ".txt"; while ((getline l < f) > 0) { gsub(/[^A-Za-z0-9-]+/, " ", l); n = split(l, y, " "); for (i = 1; i <= n; i++) if (y[i] in R) { close(f); return 1 } } close(f); return 0 }
    $1 == "open" && $3 != "-" && index(W, " " $3 " ") == 0 { if ($7 + 0 > $8 + 0) print $3, $2, $4, "ask"; else if ($8 + 0 > 0 && hit($2, $3, substr($4, 1, 12))) print $3, $2, $4, "re" }' "$L/read" > "$L/a"
  ! grep -q '	re$' "$L/a" || [ -n "$FT" ] || fetch_; while IFS=$TAB read -r t p H m <&3; do ask "$t" "$p" "$H" "$m"; done 3< "$L/a"; ruled_
  for r in $(held_ | sort -u); do echo "held $r"; done; sig_ | grep '^question '
  cl owed > "$L/ow2"; cat "$L/ow2"; for s in $(cl out | cut -d' ' -f2); do cl decide "$s"; done; sh "$HERE/walk.sh" pending 2>/dev/null || true
  sh "$HERE/grade.sh" step 2> "$L/e" || fail grade "$(tail -n 1 "$L/e")"   # v0.26.10.27.2: the owner's grade asks, read
  # v0.26.10.26.5: `summary <N>` while a close is owed with no summary yet (its facts written); `plan-stage <N+1>` while the next stage has no step
  sed -n 's/^close-stage //p' "$L/ow2" | while read -r x; do c=$(ls ".vid/decide/stage/$x" | grep -E '^[0-9]+$' | sort -n | tail -n 1); [ -s ".vid/decide/stage/$x/$c/summary.md" ] || { cl summary --stage "$x" > /dev/null; echo "summary $x"; }; done
  PS=$(plan_stage); [ -z "$PS" ] || echo "plan-stage $PS"   # v0.26.10.26.4: walk-read <N>, the walker ended
  sh "$HERE/queue.sh" sync > "$L/q" 2> "$L/e" || fail queue "$(tail -n 1 "$L/e")"; grep -v '^unreleased ' "$L/q"
  U=$(cat "$D/queue/update-at" 2>/dev/null); c=$(plan_block | cksum | tr -d ' '); case "$U" in '') u=1 ;; *) [ $(($(date +%s) - ${U%% *})) -ge 3600 ] || [ "${U#* }" != "$c" ] && u=1 || u='' ;; esac
  [ -z "$u" ] || { echo "$(date +%s) $c" > "$L/ua" || exit 1; put "$D/queue/update-at" < "$L/ua" || exit 1; echo update; }
  alarms; state_; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; sig_ | grep -v '^ask ' > "$L/sn" || true; put "$L/seen" < "$L/sn" || exit 1; rm -f .vid/round-errors
  left=''; for s in $(plan_steps); do started "$s" || refused "start $s" || left=1; done
  if [ -z "$(open_ | awk -v L=" $(sh "$HERE/grade.sh" lost 2>/dev/null | tr '\n' ' ') " 'index(L, " " $1 " ") == 0')" ] && [ -z "$left" ] && [ -z "$PS" ] && [ -z "$(wr due 2>/dev/null)" ] && [ -z "$(cl owed)$(cl out)" ] && [ -z "$(sh "$HERE/grade.sh" out 2>/dev/null)" ]; then echo nothing-left; elif [ -z "$DID" ]; then echo idle; fi; }
post_() { gh_ "$@" > "$L/o" 2> "$L/e" || fail post "$(tail -n 1 "$L/e")"; sed -n -e 's/.*published ticket #\([0-9]*\).*/published \1/p' -e 's/.*amended ticket #\([0-9]*\).*/amended \1/p' -e 's/.*withdrew ticket #\([0-9]*\).*/withdrawn \1/p' "$L/o"; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; }
due_() { wr due > "$L/due" 2> "$L/e" || fail due "$(tail -n 1 "$L/e")"; while IFS= read -r w <&3; do refused "$w" && continue; set -- $w
    case $1 in withdraw) post_ tw-close "$2" ;;
      amend) if F=$(wr write amend "$2" 2> "$L/e"); then post_ tw-post --amend "$2" "$F"; else refuse "$w" "$(tail -n 1 "$L/e")"; fi ;;
      new) shift; if F=$(wr write "$@" 2> "$L/e"); then post_ tw-post "$F"; else refuse "$w" "$(tail -n 1 "$L/e")"; fi ;; esac; done 3< "$L/due"; }
cmd_next() { renew; read_; stray; case $(sed -n 's/^run:[[:space:]]*//p' .vid/RUN-STATE.md | head -n 1) in 'stopped owner asked to hold after stage '*) ;; stopped*) echo 'stopped: nothing is published'; return 0 ;; esac   # v0.26.10.26.5 (R3): a hold stops the next stage alone
  cl owed > "$L/ow"; while read -r w s x <&3; do case $w in stage) cl ask --stage "$s" ;; okay) case $s in rehearsal) cl okay --rehearsal "$x" ;; production) cl okay --production "$x" ;; *) cl okay --stage "$x" ;; esac ;; cs) cl ask --cs "$s" ;; cr) cl ask --cr "$s" ;; cp) cl ask --cp "$s" ;; walk) continue ;;
      close-stage) [ -s ".vid/decide/stage/$s/$(ls ".vid/decide/stage/$s" | grep -E '^[0-9]+$' | sort -n | tail -n 1)/summary.md" ] || continue; cl close-stage --stage "$s"; gh_ state-save > /dev/null 2>&1 || true; return 0 ;;   # v0.26.10.26.5 (R1): nothing more in this call
      *) cl ask "$s" ;; esac; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; done 3< "$L/ow"
  gh_ spec-export > /dev/null 2> "$L/e" || fail spec-export "$(tail -n 1 "$L/e")"; gh_ tw-sync > "$L/o" 2> "$L/e" || fail tw-sync "$(tail -n 1 "$L/e")"; due_
  gh_ tw-sync > "$L/o" 2> "$L/e" || fail tw-sync "$(tail -n 1 "$L/e")"; O=$(sed -n 's/.*open tickets //p' "$L/o" | tr ',' '\n' | grep -c '^[0-9]'); C=$(skey open-tickets); C=${C:-0}
  for s in $(plan_steps); do started "$s" && continue; refused "start $s" && continue; [ "$C" = 0 ] || [ "$O" -lt "$C" ] || break
    if sh "$HERE/plan.sh" start "$s" > "$L/o" 2>&1; then due_; O=$((O + 1)); else refuse "start $s" "$(tr '\n' ' ' < "$L/o" | cut -c1-200)"; fi; done; }
CMD=${1:-}
case $CMD in wait) cmd_wait ;; step) cmd_step ;; next) cmd_next ;; *) echo 'usage: sh checks/round.sh wait|step|next' >&2; exit 2 ;; esac

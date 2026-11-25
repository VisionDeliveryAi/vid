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
#          (queue.sh sync) and `update` when the progress update is due; the alarms; RUN-STATE.md; the save. 0.26.10.29.5 (DP-1 R2): after the
#          grade asks, `decisions.sh record`, its lines as they are. One line for each thing done and
#          each thing that waits: `decided`, `merged`, `held <row>`, `question <n>`, `flag <word>`, `nothing-left` (no ticket open and no step
#          can start) or `idle`, and `progress:`. FB-1 B5: in GitHub auto, `retry spec-publish <12>` in place of both while
#          .vid/tw/spec-owed holds a folder publish left unfinished.
#   next   renews the lock; nothing if the run is stopped, which a recorded pause is; the export (0.26.10.29.5, DP-1 R2: before the owed asks),
#          then with layout: one its publish into the code repository's folder (GM-4 K13, github.sh spec-publish; FB-1 B5: a failed
#          GitHub call there `failed spec-publish <12>: …`, recorded under no key);
#          the closes' owed asks; the sync; each line `writer.sh due` owes, in order;
#          then each step in plan order `plan.sh start` passes, up to the open-ticket limit, published through github.sh tw-publish (GM-4 K1:
#          the steps every publish takes, the admission first). A save follows each post. `published <n>`; a refusal is
#          a line once, tried again only after the plan or the handed record changed.
#   read   (GM-4 F3) the one read of GitHub, github.sh round-read, written whole to .vid/round/read (lib.sh put); in GitHub manual with
#          --bodies, the ticket bodies, sub-issues and assignees after it, as /vid next reads them. A read that fails leaves the file as it
#          was, names the failure and exits 1. It prints nothing when the read succeeds, and writes nothing under .vid/ but .vid/round/
#          (FB-4 B1: in GitHub manual with layout: one, the folder's names and ids among it, github.sh spec-folder; that one failing is said and stops nothing)
#          (FB-3 D2: and its part in .vid/face, where a call named its parts; the read done, the next part, for next.sh triggers writes nothing).
#   asks   (GM-4 E5) next's first part alone: renews the lock, reads, the export, then the owed asks, okays and stage close; next calls it,
#          so GitHub auto is unchanged (a stage close ends next there). In GitHub manual no export (a write to the spec repository, done only
#          inside a move the owner names, GM-2 T1); the owed asks, okays and stage close as in GitHub auto (GM-4 K11: the stage's too).
#          Its lines as close.sh prints them
#   accept <ticket> [<commit>]   (GM-4 E13) the one entry of every GitHub manual decision, /vid:vid-accept-step's: renews the lock;
#          the read and results-fetch first, so a report just pushed is seen; the commit checked on the code repository's main, its
#          first-parent line (git rev-list --first-parent refs/heads/main in .vid/code): one off it is answered `ticket: not yet` with
#          the one line `not on main — <commit>`, no row moved; with no commit, the newest commit of that line at which a result report holds a case of one of
#          the ticket's rows (`refused #<n> no results on main` with none, nothing posted; FB-3 A1.3: at a commit named with none, `refused #<n> no
#          results at <c12>`; FB-3 A4: either ends naming the command that records it accepted outside ViD; after either, each of the ticket's report branches left out or refused, `report left out — …`); when the decision
#          would be accepted but for ViD's own review, `review #<n> <c12>`, nothing decided or posted and the ask still owed; results.sh read --ticket <n> --at <c>,
#          decide.sh decide --ticket <n> --at <c> --post (an unanswered ask at c always answered, else posted only when changed), the
#          queue synced and the records saved. On `ticket: accepted` the acceptance is the ticket's merge (E4): decide.sh merged
#          --ticket <n>, `step-<n>-<c12> <n> <c> <c>` in .vid/decide/merges and its id in merged-prs. An accepted ticket asked again
#          is answered `ticket: accepted at <its merge's commit12>; its close runs there`, nothing decided again; a closed ticket not
#          accepted is refused, naming /vid:vid-tickets reopen and withdraw (E6). Lines: `decided #<n> <c12> <the ticket line>`,
#          `accepted #<n> <c12>`, `refused #<n> <why>`; FB-1 C2: after each `decided` line, in step and accept alike, one `weak <row>
#          <#n or pull request> <head 12> — <the row's text>` line for each row of that decision reading `failing, a weak test`. In GitHub auto it decides the open pull request naming the ticket at its
#          head, as step does, at the owner's word (`decided <p> <head12> …`)
#   accept <ticket> <commit> --outside "<words>" | accept --rows "<ids>" --outside "<words>"   FB-3 A4, both modes: what the owner accepted outside
#          ViD, recorded by their words (decide.sh outside): a ticket, at a commit of main's first-parent line, its merge line as an
#          acceptance's; or rows of no published ticket, with no commit. Nothing posted. `left <row>: <why>`, `recorded <k> rows …`,
#          `accepted #<n> <c12>, outside ViD, by the owner's words`, `refused [#<n>] <why>`
#   accept --tickets "<n>[@<commit>] …" --outside "<words>"   FB-3 E1: several tickets so, one lock, read and save; each at the commit named, else
#          its accepting decision comment's (github.sh ticket-decided), when main's first-parent line holds it, else at main's newest, its
#          line and its record saying so; one refused stops no other. FB-3 E2: after a record, with no engines on the handed record,
#          `engines not named — /vid:vid-accept-step engines "<primary> <other>…" "<words>"`
# GM-4 E5, in GitHub manual: step, asks and accept run; wait and next (its publishing on its own) refuse at the start (GM-1 S1), in one
# line naming /vid next, exit 2, writing nothing. step there, by GM M8 (only a ticket is decided, at a commit of main): the asks are
# the tickets' (a `vid: decide <a full commit>` comment on a published ticket's issue, unanswered while no `vid: decision <it>` follows),
# and step decides none: `decide #<n> <commit>` for each ticket owed a decision (an unanswered ask; a ruling or answer touching its
# newest asked commit), for accept; a unit's pull request asking `vid: decide` is never answered, listed once a head, `context
# unit-ask #<p> <its ticket line's number or -> <head12>`; each merge not recorded goes to .vid/decide/unit-merges (`<p> <ticket line's
# number or -> <head> <merge>`), deciding and closing nothing, `unit-merged <p> <ticket or ->`; a published ticket closed on GitHub, not
# withdrawn and not accepted, is told at every call, `closed #<n> not accepted — …` naming K1's two commands (E6) and A4's record (FB-3 E1), never withdrawn, no
# step reopened; no stray stop (it guards the round's own publishing); the alarms ticket-hours, ticket-quiet, devagent-quiet,
# devagent-stopped and ticket-left (FB-2 A3) not raised; no `update`. GM-4 K4: `summary <N>` writes no facts (the move write-summary does), and the step's walk,
# walk-read and summary lines are kept in .vid/next/stage-moves for the call to list as the owner's moves.
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
# GM-1 S1: /vid run's loop does not drive a project in GitHub manual; the backstop of the run skill's own refusal, before anything is written
# GM-4 E5: in GitHub manual step, asks and accept run when the call runs them; wait and next's publishing on its own still refuse
if manual; then case ${1:-} in wait|next) echo "ViD round: refused — this project is in GitHub manual: /vid run does not drive it; call /vid next" >&2; exit 2 ;; esac; fi
D=.vid/decide; L=.vid/round; LOG=.vid/tw/log; HAND=.vid/tw/handed; mkdir -p "$L"
[ "${1:-}" = read ] || { mkdir -p "$D"; touch "$D/merged-prs" "$D/refused" "$D/flags" "$D/accepted-log" "$D/rulings" "$D/unit-merges"; }   # GM-4 F3: the read writes its file alone
TAB=$(printf '\t'); DID=''
gh_() { VID_CALLER=round sh "$HERE/github.sh" "$@"; }; dec() { sh "$HERE/decide.sh" "$@"; }; wr() { sh "$HERE/writer.sh" "$@"; }   # 0.26.10.29.2 (R12): the round marks its own calls
PX=$(skey labels-prefix)
fail() { n=$(($(cat .vid/round-errors 2>/dev/null || echo 0) + 1)); echo "$n" > "$L/re" || exit 1; put .vid/round-errors < "$L/re" || exit 1; ev "round-error step=$1 count=$n"; rneed; echo "error $1 ($n running): $2"; exit 1; }
# FB-3 D2: a call that ends here leaves its part stopped, with what it needs; not one marked as another script's (VID_CALLER: /vid mode
# says its own stop, and next-move.sh goes on after a read that fails)
rneed() { [ -n "${VID_CALLER:-}" ] || pneed "${1:-a look at the chat, which says why it stopped}"; }
stray() { for n in $(tickets); do grep -qE "^(published|asked) $n " "$LOG" 2>/dev/null || { ev "round-stop stray=$n"; echo "stop stray: #$n is an open ticket the log does not hold: a publication's save was lost, so nothing more is published"; exit 4; }; done; }
renew() { rc=0; gh_ lock-renew > "$L/e" 2>&1 || rc=$?; [ "$rc" != 3 ] || { echo 'lock-lost'; exit 3; }; [ "$rc" = 0 ] || fail lock-renew "$(tail -n 1 "$L/e")"; }
# GM-4 F3: rd_, the one read into .vid/round/read, with --bodies in GitHub manual (E4: the sub-issues a merge there is mapped by); read_, the
# round's own, a failure its error
rd_() { RB=''; ! manual || RB=--bodies; gh_ round-read $RB > "$L/rd" 2> "$L/e" && put "$L/read" < "$L/rd"; }
# FB-4 B1: folder_, in GitHub manual with one repository, the read of the folder's names and ids (github.sh spec-folder, .vid/round/folder); one that
# fails is said and stops nothing
folder_() { manual && [ "$(skey layout)" = one ] || return 0; gh_ spec-folder > /dev/null 2> "$L/fe" || echo "ViD round: the folder's read failed, and the call goes on without it: $(tail -n 1 "$L/fe")" >&2; }
read_() { rd_ || fail round-read "$(tail -n 1 "$L/e")"; }
# what is new from the dev side: unanswered asks, unrecorded merges, blocked questions
# GM-4 E1: in GitHub manual (MA) the asks are the tickets', `ask #<n> <commit>` (tasks_), never a pull request's; a merge in unit-merges
# is recorded (E4)
sig_() { { [ -z "$(man_)" ] || tasks_ | sed 's/^/ask #/; s/\t/ /'; }; awk -F'\t' -v M="$D/merged-prs" -v U="$D/unit-merges" -v MA="$(man_)" -v B=",${PX}blocked," -v W=" $(wdn | tr '\n' ' ') " 'BEGIN { while ((getline l < M) > 0) m[l] = 1; while ((getline l < U) > 0) { split(l, x, "\t"); m[x[1]] = 1 } } !MA && $1 == "open" && $7 + 0 > $8 + 0 && index(W, " " $3 " ") == 0 { print "ask", $2, $4 } $1 == "merged" && !($2 in m) { print "merged", $2 } $1 == "issue" && index("," $3 ",", B) { print "question", $2 } $1 == "open" && index("," $6 ",", B) { print "question", $2 }
  function cnt(h, p,   c, i, n, k) { n = split(h, c, "\001"); for (i = 1; i <= n; i++) if (c[i] ~ p) k++; return k + 0 }
  $1 == "issue" && (index("," $3 ",", RUN) || index("," $3 ",", GRD) || index("," $3 ",", DPL)) { print "reported", $2, cnt($4, "^vid: reported ") }
  $1 == "issue" { q = cnt($4, "^(Question:|[A-Z][A-Z]: [Qq]uestion)"); if (q) print "qs", $2, q } $1 == "open" { q = cnt($10, "^(Question:|[A-Z][A-Z]: [Qq]uestion)"); if (q) print "qs", $2, q }
  $1 == "main" { print "main", $2 }
  NR == 1 { while ((getline l < RSK) > 0) { split(l, x, "\t"); RS_[x[1]] = 1 } }
  $1 == "result" && ($2 ~ /^stopped-/ || ST || ($2 in RS_)) { print "result", $2, $3 }' RUN=",${PX}run," GRD=",${PX}grade," DPL=",${PX}deploy," RSK="$L/reports-skipped" ST="$(grep -q '^devagent-stopped ' "$D/flags" 2>/dev/null && echo 1)" "$L/read"; }   # v0.26.10.28.2 (R4): the code repository's main, so a wait notices it
# FB-3 A2: a left-out report branch's newest commit too, so one put right is fetched
# v0.26.10.28.6 (R3): the dev side's stopped reports, and while devagent-stopped stands every report, so a stop, and the report that clears it, end a wait
man_() { ! manual || echo 1; }
# GM-4 E1: tasks_, each published ticket not withdrawn whose newest `vid: decide <a full commit>` comment no `vid: decision <it>` follows:
# `<n> TAB <commit>`, from the read's issue lines (their comments' first lines)
tasks_() { awk -F'\t' -v L="$LOG" 'BEGIN { while ((getline l < L) > 0) { split(l, x, " "); if (x[1] == "published") P[x[2]] = 1; else if (x[1] == "withdrawn") delete P[x[2]] } }
  $1 == "issue" && ($2 in P) { n = split($4, c, "\001"); a = ""; for (i = 1; i <= n; i++) { if (c[i] ~ /^vid: decide [0-9a-f]+[ \t]*$/) { y = c[i]; sub(/^vid: decide /, "", y); sub(/[ \t]*$/, "", y); if (length(y) == 40) { a = y; k = i } } }
    if (a == "") next; for (i = k + 1; i <= n; i++) if (c[i] ~ ("^vid: decision " a)) next; print $2 "\t" a }' "$L/read"; }
# GM-4 E2: accepted <n>, the ticket's merge on record in merges (E4's acceptance line, or a merge recorded in GitHub auto): its commit
accepted() { awk -F'\t' -v n="$1" '$2 == n { c = $4 } END { if (c != "") print c }' "$D/merges" 2>/dev/null; }
tickets() { awk -F'\t' -v O=" $(onrec | tr '\n' ' ') " -v T=",${PX}ticket," -v U=",${PX}run," -v G=",${PX}grade," -v P=",${PX}deploy," '$1 == "issue" && (index(O, " " $2 " ") || index("," $3 ",", T) || index("," $3 ",", U) || index("," $3 ",", G) || index("," $3 ",", P)) { print $2 }' "$L/read"; }
open_() { if manual; then for n in $(tickets); do [ -n "$(accepted "$n")" ] || echo "$n"; done; return 0; fi
  # GM-4 E2, F13: in GitHub auto too, a ticket whose merge is on record (a GitHub manual acceptance's step- line) is not open
  for n in $(tickets); do [ -z "$(accepted "$n")" ] || continue; m=$(awk -F'\t' -v n="$n" '$1 == "merged" && $3 == n { print $2 }' "$L/read" | head -n 1); [ -n "$m" ] && grep -qx "$m" "$D/merged-prs" || echo "$n"; done; }
plan_steps() { plan_block | sed -n 's/^step \([^ |]*\).*/\1/p'; }
started() { grep '^step-start ' .vid/metrics-events 2>/dev/null | grep -q " step=$1 "; }
# keys: KR, the refusal key (lib.sh rkey: the plan block, the handed record and (v0.26.10.28.2, R4) the newest tw-sync's main, so a ticket refused
# for want of main is tried again), and KS, the stage key (lib.sh stkey, low-1 R3), each computed once and cleared by each loop and each post
KR=''; KS=''; keys() { [ -n "$KR" ] || KR=$(rkey); [ -n "$KS" ] || KS=$(stkey); }
refused() { keys; grep -qxF -e "$1 $KR" -e "$1 $KS" "$D/refused"; }
# refuse <what> <why> [stage]: recorded under the refusal key, or under the stage key for a start refused for its stage (low-1, R3)
refuse() { refused "$1" || { k=$KR; [ "${3:-}" != stage ] || k=$KS; echo "$1 $k" >> "$D/refused"; ev "round-refused what=$(printf %s "$1" | tr ' ' '-')"; echo "refused $1: $2"; }; }
said() { printf '%s\t%s\t%s\t%s\n' "$(stamp)" "$1" "$2" "$3" >> .vid/tw/stood-in-answers.txt; }
# the switch: never a held product failure
table() { awk -F'\t' '$3 == "held" { print $1 "\t" $4 "\t" ($8 == "" ? "-" : $8) "\t" $6 }' "$D/pr-$1-$2.rows" > "$L/rows"
  while IFS=$TAB read -r r un t3 l <&3; do case $l in *'a product failure'*) continue ;; esac
    if [ "$un" = 'evidence missing' ] && [ "$t3" = passed ]; then w=accept; c='held, its tests passing, only its evidence missing'; else case $l in *'a weak test'*) w=limit; c='a held weak test' ;; *) continue ;; esac; fi
    dec rule "$r" "$w" --by stand-in > /dev/null 2>&1 && said "$r" "$w" "$c"; done 3< "$L/rows"; }
# FB-1 C2: weak_ <posted decision> <#n or pull request> <head 12>, right after a `decided` line: one `weak <row> <#n or pull request>
# <head 12> — <the row's text>` line for each row line of the posted decision reading `failing, a weak test`, so the session runs
# the lesson (vid-accept-step)
weak_() { awk -v w="$2" -v h="$3" 'NR > 2 && index($0, "failing, a weak test") { t = substr($0, length($1) + 2); print "weak " $1 " " w " " h " — " t }' "$1" 2>/dev/null || true; }
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
  [ "$m" = ask ] || [ "$a" != "$b" ] || return 0; echo "decided $p $h $(sed -n 2p "$D/posted-pr-$p-$h")"; weak_ "$D/posted-pr-$p-$h" "$p" "$h"; DID=1; }
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
    cut -f1 "$D/unit-merges" | grep -qx "$p" && continue   # GM-4 E4: a unit's merge GitHub manual recorded is recorded
    if dec merged --pr "$p" > "$L/o" 2>&1; then [ "$t" = - ] || { gh_ close "$t" > /dev/null 2> "$L/e" || fail close "$(tail -n 1 "$L/e")"; }; printf '%s\t%s\t%s\t%s\n' "$p" "$t" "$H" "$M" >> "$D/merges"; echo "merged $p"
    elif grep -q 'no decision for pull request' "$L/o"; then ev "round-merged pr=$p decision=none"; ev "decisions-recorded pr=$p n=missing"; echo "merged $p, no decision"; else fail merged "$(tail -n 1 "$L/o")"; fi; echo "$p" >> "$D/merged-prs"; DID=1; done 3< "$L/m"; }
# GM-4 E4 (GitHub manual): umerged_, each merge not recorded into unit-merges, `<p> <its ticket line's number or -> <head> <merge>`:
# no row decided, no issue closed, no close owed
umerged_() { awk -F'\t' '$1 == "merged"' "$L/read" | sort -t"$TAB" -k2,2n > "$L/m"; while IFS=$TAB read -r x p t H M _r <&3; do grep -qx "$p" "$D/merged-prs" && continue
    cut -f1 "$D/unit-merges" | grep -qx "$p" && continue; printf '%s\t%s\t%s\t%s\n' "$p" "$t" "$H" "$M" >> "$D/unit-merges"; echo "unit-merged $p $t"; DID=1; done 3< "$L/m"; }
# GM-4 E6 (GitHub manual): told_, each published ticket not withdrawn, closed on GitHub (no issue line in the read) and not accepted,
# told at every call with K1's two commands and the record of an acceptance outside ViD (FB-3 E1); nothing withdrawn, nothing reopened
told_() { awk '$1 == "published" { p[$2] = 1 } $1 == "withdrawn" { delete p[$2] } END { for (n in p) print n }' "$LOG" 2>/dev/null | sort -n > "$L/pub"
  awk -F'\t' '$1 == "issue" { print $2 }' "$L/read" | sort -u > "$L/oi"; for n in $(cat "$L/pub"); do grep -qx "$n" "$L/oi" && continue; [ -z "$(accepted "$n")" ] || continue
    echo "closed #$n not accepted — closed on GitHub before its acceptance: /vid:vid-tickets reopen #$n \"<your words>\" reopens it, /vid:vid-tickets withdraw #$n \"<your words>\" withdraws it, /vid:vid-accept-step $n <commit> accepted \"<your words>\" records it as accepted outside ViD"; done; }
# GM-4 E13 (GitHub manual): mdec_, `decide #<n> <commit>` for each ticket owed a decision: an unanswered ask (tasks_), or a ruling or
# answer since the last step touching its newest asked commit (last-step-<n>): its rows, its ticket, its evidence
mdec_() { tasks_ > "$L/ta"; awk -F'\t' '{ print "decide #" $1 " " $2 }' "$L/ta"
  for f in $(ls "$D" 2>/dev/null | sed -n 's/^last-step-\([0-9][0-9]*\)$/\1/p' | sort -n); do grep -q "^$f$TAB" "$L/ta" && continue; c=$(head -n 1 "$D/last-step-$f"); h=$(printf %s "$c" | cut -c1-12)
    grep -qE "^(withdrawn) $f " "$LOG" 2>/dev/null && continue; [ -z "$(accepted "$f")" ] || continue
    awk -F'\t' -v n="$f" -v RF="$D/step-$f-$h.rows" -v EF=".vid/results/step-$f-$h.txt" 'BEGIN { hit = 0 } { if ($1 == "row") { R[$2] = 1; b = $2; sub(/-T[0-9]+$/, "", b); R[b] = 1 } else if ($2 == n) hit = 1 }
      END { if (!hit) { while ((getline l < RF) > 0) { split(l, y, "\t"); b = y[1]; sub(/-T[0-9]+$/, "", b); if ((y[1] in R) || (b in R)) hit = 1 } while (!hit && (getline l < EF) > 0) { gsub(/[^A-Za-z0-9-]+/, " ", l); m = split(l, y, " "); for (i = 1; i <= m; i++) if (y[i] in R) hit = 1 } } exit !hit }' "$L/touch" && echo "decide #$f $c"; done; }
# GM-4 E1 (GitHub manual): uask_, a unit's pull request asking `vid: decide` at its head, never answered: listed once a head
uask_() { touch "$D/unit-asks"; awk -F'\t' '$1 == "open" && $7 + 0 > 0 { print $2 "\t" $3 "\t" substr($4, 1, 12) }' "$L/read" | while IFS=$TAB read -r p t h; do grep -qxF "$p $h" "$D/unit-asks" && continue
    echo "$p $h" >> "$D/unit-asks"; echo "context unit-ask #$p $t $h"; done; }
# 0.26.10.29.5 (DP-1 R2): a merge with no decision of ViD's states no decisions ViD reads (decisions-recorded n=missing, as a description
# with no section); record_, the dev side's decisions of the merges recorded and of the deploy reports read, into DECISIONS.md (decisions.sh
# record): its lines as they are, `decisions recorded`, `decisions refused pr=<p> …` (RM's own defect) or `decisions wait draft=<n>`
record_() { sh "$HERE/decisions.sh" record > "$L/dr" 2> "$L/e" || fail decisions "$(cat "$L/dr" "$L/e" | tail -n 1)"; cat "$L/dr"; ! grep -qE '^decisions (recorded|refused) ' "$L/dr" || DID=1; }
# v0.26.10.27.3 (8.1b R1): a published ticket not withdrawn, not open in the read and no merged pull request naming it (merges, merged-prs
# with the read's merged lines, merged-tickets): its issue read once by tw-outside; CLOSED is withdrawn closed-outside, and its open pull
# request, no longer decided, gets one comment
cow() { awk '$1 == "withdrawn" && $3 == "decision=closed-outside" { print $2 }' "$LOG" 2>/dev/null | sort -u; }
# 0.26.10.29.2 (R3): wdn, every withdrawn ticket, closed outside or by a plan change: its pull request is never decided again (sig_, step)
wdn() { awk '$1 == "withdrawn" { print $2 }' "$LOG" 2>/dev/null | sort -u; }
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
  # FB-3 A2: a report branch left out, in both modes: flagged to the owner until it is put right, or gone
  if [ -s "$L/reports-skipped" ]; then sh "$HERE/results.sh" skipped > "$L/sk" || exit 1; while IFS=$TAB read -r i w; do flag report-skipped "$i" "$w"; done < "$L/sk"; fi
  # GM-4 E5: in GitHub manual ticket-hours, ticket-quiet, devagent-quiet, devagent-stopped and ticket-left watch no DevAgent of ViD's: not raised
  if ! manual; then
  for n in $(open_); do a=$(awk -v n="$n" '$1 == "published" && $2 == n' "$LOG" | tail -n 1 | tr ' ' '\n' | sed -n 's/^at=//p'); [ -z "$a" ] || [ $((N - $(epoch "$a"))) -le "$H1" ] || flag ticket-hours "$n"
    u=$(awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { print $5 } $1 == "open" && $3 == n { print $9 }' "$L/read" | sort | tail -n 1); [ -z "$u" ] || [ $((N - $(epoch "$u"))) -le "$Q1" ] || flag ticket-quiet "$n"; done
  # v0.26.10.28.3 (R2): no dev side answers: work tickets open (<prefix>ticket alone), none with a `vid: claimed` comment or a pull request naming it, and the newest `published` line older than quiet-hours
  q=$(awk -F'\t' -v T=",${PX}ticket," -v R=" $(onrec | tr '\n' ' ') " -v O=" $(open_ | tr '\n' ' ') " '$1 == "issue" && (index(R, " " $2 " ") || index("," $3 ",", T)) && index(O, " " $2 " ") { t[$2] = 1; m = split($4, c, "\001"); for (i = 1; i <= m; i++) if (c[i] == "vid: claimed") s = 1 }
    $1 == "open" || $1 == "merged" { p[$3] = 1 } END { for (x in t) { k++; if (x in p) s = 1 } if (k && !s) print k }' "$L/read")
  a=$(awk '$1 == "published"' "$LOG" | tail -n 1 | tr ' ' '\n' | sed -n 's/^at=//p'); [ -z "$q" ] || [ -z "$a" ] || [ $((N - $(epoch "$a"))) -le "$Q1" ] || flag devagent-quiet "$q"
  # v0.26.10.28.6 (R3): the dev side stopped, its newest report a stopped one; a later report of any kind clears it
  s=$(stopped_); [ -z "$s" ] || flag devagent-stopped "${s%%	*}" "${s#*	}"
  # FB-2 A3: a ticket DevAgent left, each open one whose newest `DM: left: <why>` comment has no reopen after it; a reopen clears it
  awk -F'\t' -v O=" $(open_ | tr '\n' ' ') " '$1 == "issue" && index(O, " " $2 " ") { m = split($4, c, "\001"); w = ""; for (i = 1; i <= m; i++) { if (c[i] ~ /^DM: left: /) w = substr(c[i], 11); else if (c[i] == "vid: reopened at the owner'"'"'s word") w = "" } if (w != "") print $2 "\t" w }' "$L/read" > "$L/lf"
  while IFS=$TAB read -r n w; do flag ticket-left "$n" "$w"; done < "$L/lf"; fi
  A=$(awk -F'\t' '$2 == "accepted" || $2 == "accepted by ruling" { c++ } END { print c + 0 }' "$D/state" 2>/dev/null); A=${A:-0}; echo "$N $A" >> "$D/accepted-log"
  P=$(awk -v t=$((N - 3600)) '$1 >= t && $2 > m { m = $2 } END { print m + 0 }' "$D/accepted-log"); [ $((P - A)) -lt 20 ] || flag row-drop accepted
  for k in $(awk '{ print $1 "|" $2 }' "$D/flags"); do case " $F " in *" $k "*) ;; *) w=${k%%|*}; o=${k#*|}; grep -vxF "$w $o" "$D/flags" > "$L/f"; put "$D/flags" < "$L/f" || exit 1; ev "flag-cleared word=$w on=$o" ;; esac; done
  for r in $(sed -n 's/^unreleased //p' "$L/q" 2>/dev/null); do flag answer-not-released "$r"; done
  I=$(grep -cE '^(died|round-error|round-stop) ' .vid/metrics-events 2>/dev/null); echo "progress: accepted=$A open=$(open_ | grep -c .) incidents=$I"; }
held_() { for p in $(awk -F'\t' '$1 == "open" { print $2 "|" substr($4, 1, 12) }' "$L/read"); do f=$D/pr-${p%|*}-${p#*|}.rows; [ -f "$f" ] && awk -F'\t' '$3 == "held" { print $1 }' "$f"; done
  # GM-4 E2: the newest decision of each ticket with an ask, in both modes, an accepted one aside
  for n in $(ls "$D" 2>/dev/null | sed -n 's/^last-step-\([0-9][0-9]*\)$/\1/p'); do [ -z "$(accepted "$n")" ] || continue; f=$D/step-$n-$(cut -c1-12 "$D/last-step-$n").rows; [ ! -f "$f" ] || awk -F'\t' '$3 == "held" { print $1 }' "$f"; done; }
skeep() { if grep -q "^$1:" "$L/rs"; then sed "s/^$1:.*/$1: $2/" "$L/rs" > "$L/rs2"; else sed "1a\\
$1: $2" "$L/rs" > "$L/rs2"; fi || return 1; [ -s "$L/rs2" ] && mv "$L/rs2" "$L/rs"; }   # never an empty RUN-STATE (R6)
# 0.26.10.28.4 (9.3 R2): the now: and held: lines through the run record's one writer, read inside its lock
rskeep() { cat > "$L/rs" || return 1; skeep now "$NW" || return 1; skeep held "${H:--}" || return 1; cat "$L/rs"; }
state_() { H=$(held_ | sort -u | paste -sd ' ' -); NW="accepted=$A open=$(open_ | grep -c .)"; rs_edit rskeep || exit 1; }
# v0.26.10.28.6 (R6): a wait records its start and its limit in .vid/round/wait, and removes it at its end, so the watcher counts it as activity;
# one a signal ends may leave it, and the watcher reads it as nothing past the limit and its margin
cmd_wait() { M=${VID_WAIT_MAX:-540}; T=${VID_WAIT_TICK:-60}; t0=$(date +%s); printf 'start=%s\nmax=%s\n' "$t0" "$M" > "$L/wait" || exit 1; trap 'rm -f "$L/wait"' EXIT; while :; do read_; sig_ > "$L/now"; if ! cmp -s "$L/now" "$L/seen"; then r=new; break; fi; [ $(($(date +%s) - t0 + T)) -le "$M" ] || { r=timeout; break; }; sleep "$T"; done; renew; echo "$r"; }
fetch_() { gh_ results-fetch > /dev/null 2> "$L/e" || fail results-fetch "$(tail -n 1 "$L/e")"; FT=1; }
cmd_step() { prog on "ViD's own work"; FT=''; renew; read_; sig_ > "$L/now"; cmp -s "$L/now" "$L/seen" || fetch_
  manual || stray   # GM-4 E5: it guards the round's own publishing, which GitHub manual's call does not do
  # v0.26.10.28.2 (R4): `main-changed` when the code repository's main differs from the last step's (never at the first), so vid-run runs next
  MN=$(grep '^main ' "$L/now" || true); MS=$(grep '^main ' "$L/seen" 2>/dev/null || true); [ -z "$MN" ] || [ -z "$MS" ] || [ "$MN" = "$MS" ] || { ev "round-main-changed main=${MN#main }"; echo main-changed; DID=1; }
  # an ask, or a ruling or answer made since the last step: rule leaves no comment, so a decided head it touches is decided again (R4,
  # v0.26.10.28.6: only the open pull requests it touches, by their head's rows, their ticket, or the issue or pull request asked on;
  # on results fetched first, and posted only when the decision changed)
  # GM-4 E5: in GitHub manual the merges are E4's, a ticket closed early is told (E6), and nothing is decided: each ticket owed a
  # decision is a `decide` line for round.sh accept (E13)
  if manual; then umerged_; told_; touch_; mdec_; uask_; ruled_; else
  merged_; outside_; reopen_; touch_; awk -F'\t' -v OFS='\t' -v D="$D" -v TF="$L/touch" -v W=" $(wdn | tr '\n' ' ') " 'BEGIN { while ((getline l < TF) > 0) { split(l, x, "\t"); if (x[1] == "row") { R[x[2]] = 1; b = x[2]; sub(/-T[0-9]+$/, "", b); R[b] = 1 } else if (x[1] == "on") O[x[2]] = 1; else K[x[2]] = 1 } }
    function hit(p, t, h,   f, l, y, r, b, n, i) { if ((p in O) || (t in O) || (t in K)) return 1; f = D "/pr-" p "-" h ".rows"; while ((getline l < f) > 0) { split(l, y, "\t"); r = y[1]; b = r; sub(/-T[0-9]+$/, "", b); if ((r in R) || (b in R)) { close(f); return 1 } } close(f)
      # the head evidence too: a row a landing reset out of the rows file can still stand in its grade lines
      f = ".vid/results/pr-" p "-" h ".txt"; while ((getline l < f) > 0) { gsub(/[^A-Za-z0-9-]+/, " ", l); n = split(l, y, " "); for (i = 1; i <= n; i++) if (y[i] in R) { close(f); return 1 } } close(f); return 0 }
    $1 == "open" && $3 != "-" && index(W, " " $3 " ") == 0 { if ($7 + 0 > $8 + 0) print $3, $2, $4, "ask"; else if ($8 + 0 > 0 && hit($2, $3, substr($4, 1, 12))) print $3, $2, $4, "re" }' "$L/read" > "$L/a"
  ! grep -q '	re$' "$L/a" || [ -n "$FT" ] || fetch_; while IFS=$TAB read -r t p H m <&3; do ask "$t" "$p" "$H" "$m"; done 3< "$L/a"; ruled_; fi
  for r in $(held_ | sort -u); do echo "held $r"; done; sig_ | grep '^question '
  cl owed > "$L/ow2"; cat "$L/ow2"; for s in $(cl out | cut -d' ' -f2); do cl decide "$s"; done; sh "$HERE/walk.sh" pending > "$L/wp" 2>/dev/null || true; cat "$L/wp"
  sh "$HERE/grade.sh" step 2> "$L/e" || fail grade "$(tail -n 1 "$L/e")"   # v0.26.10.27.2: the owner's grade asks, read
  record_   # 0.26.10.29.5 (DP-1 R2): after the merges and the deploy reports this step read, before a stage summary's facts
  # v0.26.10.26.5: `summary <N>` while a close is owed with no summary yet (its facts written); `plan-stage <N+1>` while the next stage has no step
  # GM-4 K4 (GM M16): in GitHub manual the walk and the summary are moves the owner names: `summary <N>` writes no facts here, and
  # this step's `walk <N>`, `walk-read <N>` and `summary <N>` lines are kept in .vid/next/stage-moves, whole, for the call's listing
  # (next.sh: walk-stage, read-walk, write-summary)
  sed -n 's/^close-stage //p' "$L/ow2" | while read -r x; do c=$(ls ".vid/decide/stage/$x" | grep -E '^[0-9]+$' | sort -n | tail -n 1); [ -s ".vid/decide/stage/$x/$c/summary.md" ] || { manual || cl summary --stage "$x" > /dev/null; echo "summary $x"; }; done > "$L/sm"; cat "$L/sm"
  if manual; then mkdir -p .vid/next; { grep -E '^walk [0-9]+$' "$L/ow2"; grep -E '^walk-read [0-9]+$' "$L/wp"; grep -E '^summary [0-9]+$' "$L/sm"; } > "$L/smv" || true; put .vid/next/stage-moves < "$L/smv" || exit 1; fi
  PS=$(plan_stage); [ -z "$PS" ] || echo "plan-stage $PS"   # v0.26.10.26.4: walk-read <N>, the walker ended
  sh "$HERE/queue.sh" sync > "$L/q" 2> "$L/e" || fail queue "$(tail -n 1 "$L/e")"; grep -v '^unreleased ' "$L/q"
  U=$(cat "$D/queue/update-at" 2>/dev/null); c=$(plan_block | cksum | tr -d ' '); case "$U" in '') u=1 ;; *) [ $(($(date +%s) - ${U%% *})) -ge 3600 ] || [ "${U#* }" != "$c" ] && u=1 || u='' ;; esac
  manual || [ -z "$u" ] || { echo "$(date +%s) $c" > "$L/ua" || exit 1; put "$D/queue/update-at" < "$L/ua" || exit 1; echo update; }   # GM-4 E5: the call shows its own lines
  alarms; state_; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; sig_ | grep -v '^ask ' > "$L/sn" || true; put "$L/seen" < "$L/sn" || exit 1; rm -f .vid/round-errors
  left=''; KR=''; KS=''; for s in $(plan_steps); do started "$s" || refused "start $s" || left=1; done
  # FB-1 B5: in GitHub auto, while .vid/tw/spec-owed holds a folder publish left unfinished (and not refused since), `retry spec-publish
  # <12>` in place of idle and nothing-left, so /vid run goes on to next, which tries it again
  SO=''; if ! manual && [ -s .vid/tw/spec-owed ] && [ "$(skey layout)" = one ]; then SO=$(head -n 1 .vid/tw/spec-owed); X12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' "$LOG" 2>/dev/null); ! refused "spec-publish $X12" || SO=''; fi
  if [ -n "$SO" ]; then echo "retry spec-publish $SO"
  elif [ -z "$(open_ | awk -v L=" $(sh "$HERE/grade.sh" lost 2>/dev/null | tr '\n' ' ') " 'index(L, " " $1 " ") == 0')" ] && [ -z "$left" ] && [ -z "$PS" ] && [ -z "$(wr due 2>/dev/null)" ] && [ -z "$(cl owed)$(cl out)" ] && [ -z "$(sh "$HERE/grade.sh" out 2>/dev/null)" ]; then echo nothing-left; elif [ -z "$DID" ]; then echo idle; fi; }
# 0.26.10.29.2 (R3): the handovers of what is owed are logged before any ticket is written, so their order never matters. GM-4 K1:
# each owed line goes out by tw-hand's own steps, github.sh tw-act (the write, a fix or reached ticket's warnings, the post), under
# the round's lock, after its export, sync and read
due_() { KR=''; KS=''; wr due > "$L/due" 2> "$L/e" || fail due "$(tail -n 1 "$L/e")"; ! grep -qE '^(withdraw|amend) ' "$L/due" || gh_ tw-handovers > /dev/null 2> "$L/e" || fail handovers "$(tail -n 1 "$L/e")"; while IFS= read -r w <&3; do refused "$w" && continue; set -- $w
    case $1 in withdraw|tell|amend) act_ "$w" "$1" "$2" ;;   # 0.26.10.29.2 (R11): tell
      new) shift; act_ "$w" new "$@" ;; esac; done 3< "$L/due"; }
# act_ <the owed line> <tw-act's arguments>: posted, its lines and a save; a write tw-act refuses (4) the round's refusal, retried on
# change; any other failure the round's error
act_() { _w=$1; shift; KR=''; KS=''; ac=0; gh_ tw-act "$@" > "$L/o" 2> "$L/e" || ac=$?
  case $ac in 0) sed -n -e 's/.*published ticket #\([0-9]*\).*/published \1/p' -e 's/.*amended ticket #\([0-9]*\).*/amended \1/p' -e 's/.*withdrew ticket #\([0-9]*\).*/withdrawn \1/p' -e 's/.*told ticket #\([0-9]*\).*/told \1/p' "$L/o"; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")" ;;
    4) refuse "$_w" "$(tail -n 1 "$L/e")" ;;
    *) fail post "$(tail -n 1 "$L/e")" ;; esac; }
# GM-4 E5: asks_, next's first part: the export, then the owed asks, okays and stage close; 1 when a stage close ended it (next's
# return 0 there). In GitHub manual no export; the owed asks, okays and stage close as in GitHub auto (GM-4 K11), the walk the owner's move
asks_() {
  if ! manual; then
  # 0.26.10.29.5 (DP-1 R2): the export before any owed ask is posted, so a grade asked after a merge reads that merge's decisions
  gh_ spec-export > /dev/null 2> "$L/e" || fail spec-export "$(tail -n 1 "$L/e")"
  # GM-4 K13: with one repository, the export mirrored into the code repository's folder after it (nothing more when published already,
  # one line while the code repository has no main); a refusal is the round's one line, retried on change, never a stop of its tickets
  # keyed on the newest export too, so a new export is tried at once and a refused one waits for a change
  if [ "$(skey layout)" = one ]; then X12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' "$LOG" 2>/dev/null)
    # FB-1 B5: a failed GitHub call (exit 5) is `failed spec-publish <12>: …`, recorded under no key, so the next call tries it again;
    # FB-2 B1: any GitHub or git network call of spec-publish that fails is exit 5, and only a rule's refusal (exit 1) is keyed
    refused "spec-publish $X12" || { spc=0; gh_ spec-publish > /dev/null 2> "$L/e" || spc=$?
      case $spc in 0) ;; 5) echo "failed spec-publish $X12: $(tail -n 1 "$L/e")" ;; *) refuse "spec-publish $X12" "$(tail -n 1 "$L/e")" ;; esac; }; fi; fi   # the second fi: GitHub auto alone (GM-4 E5)
  cl owed > "$L/ow"; while read -r w s x <&3; do case $w in stage) cl ask --stage "$s" ;; okay) case $s in rehearsal) cl okay --rehearsal "$x" ;; production) cl okay --production "$x" ;; *) cl okay --stage "$x" ;; esac ;; cs) cl ask --cs "$s" ;; cr) cl ask --cr "$s" ;; cp) cl ask --cp "$s" ;; walk) continue ;;
      close-stage) [ -s ".vid/decide/stage/$s/$(ls ".vid/decide/stage/$s" | grep -E '^[0-9]+$' | sort -n | tail -n 1)/summary.md" ] || continue; cl close-stage --stage "$s"; gh_ state-save > /dev/null 2>&1 || true; return 1 ;;   # v0.26.10.26.5 (R1): nothing more in this call
      *) cl ask "$s" ;; esac; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; done 3< "$L/ow"; return 0; }
cmd_asks() { renew; read_; asks_ || true; }
cmd_next() { renew; read_; stray; case $(sed -n 's/^run:[[:space:]]*//p' .vid/RUN-STATE.md | head -n 1) in 'stopped owner asked to hold after stage '*) ;; stopped*) echo 'stopped: nothing is published'; return 0 ;; esac   # v0.26.10.26.5 (R3): a hold stops the next stage alone
  asks_ || return 0
  gh_ tw-sync > "$L/o" 2> "$L/e" || fail tw-sync "$(tail -n 1 "$L/e")"; due_
  gh_ tw-sync > "$L/o" 2> "$L/e" || fail tw-sync "$(tail -n 1 "$L/e")"; O=$(sed -n 's/.*open tickets //p' "$L/o" | tr ',' '\n' | grep -c '^[0-9]'); C=$(skey open-tickets); C=${C:-0}
  KR=''; KS=''; for s in $(plan_steps); do started "$s" && continue; refused "start $s" && continue; [ "$C" = 0 ] || [ "$O" -lt "$C" ] || break
    # GM-4 K1: the publish through the steps every publish takes (github.sh tw-publish: the admission, the write, its check, the post);
    # held (3) a refusal of its start, as plan.sh start's was; admitted with the write refused (4), due_ writes it again and refuses it
    pc=0; gh_ tw-publish "$s" > "$L/o" 2>&1 || pc=$?
    case $pc in 0) sed -n 's/.*published ticket #\([0-9]*\).*/published \1/p' "$L/o"; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; due_; O=$((O + 1)) ;;
      3) grep -v '^ViD github: held — ' "$L/o" > "$L/oh" || true; refuse "start $s" "$(tr '\n' ' ' < "$L/oh" | cut -c1-200)" "$(grep -q 'holds rows outside stages' "$L/oh" && echo stage)" ;;   # low-1 (R3): a stage refusal waits for its stage
      4) due_; O=$((O + 1)) ;;
      *) fail post "$(tail -n 1 "$L/o")" ;; esac; done; }
# FB-3 A4: outs --ticket <n> --at <commit> | --rows "<ids>": the record (decide.sh outside), a ticket's merge lines as an acceptance writes
# them; OD, something was recorded. outf: then the queue and the records saved, once, and (FB-3 E2) the engines asked when none is named
OD=''; NT=''; outs() { r=0; dec outside "$@" --words "$OW" > "$L/o" 2> "$L/e" || r=$?; case $r in 0) ;; 1) grep -q '^ViD decide: refused — ' "$L/e" || fail outside "$(tail -n 1 "$L/e")"; echo "refused ${n:+#$n }$(sed -n 's/^ViD decide: refused — //p' "$L/e" | head -n 1)"; return 0 ;; *) fail outside "$(tail -n 1 "$L/e")" ;; esac
  cat "$L/o"; OD=1; if [ -n "$n" ]; then printf 'step-%s-%s\t%s\t%s\t%s\n' "$n" "$h" "$n" "$C" "$C" >> "$D/merges"; echo "step-$n-$h" >> "$D/merged-prs"; echo "accepted #$n $h, outside ViD, by the owner's words${NT:+, $NT}"; fi; }
outf() { [ -n "$OD" ] || return 0
  dec queue > /dev/null 2>&1; sh "$HERE/queue.sh" sync > /dev/null 2> "$L/e" || fail queue "$(tail -n 1 "$L/e")"; gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; DID=1; ! engnone || echo "$ENGASK"; }
# GM-4 E13: accept <ticket> [<commit>], the one entry of every decision in GitHub manual; in GitHub auto a pull request's head
mpost() { printf '%s\n' "$2" > "$L/mp" || exit 1; gh_ comment "$1" --body-file "$L/mp" > /dev/null 2> "$L/e" || fail post "$(tail -n 1 "$L/e")"; }
acuse() { echo 'usage: sh checks/round.sh accept <ticket> [<commit>] | accept <ticket> <commit> --outside "<words>" | accept --rows "<ids>" --outside "<words>" | accept --tickets "<n>[@<commit>] …" --outside "<words>"' >&2; exit 2; }
# outfp: main's first-parent line, the newest first, in $L/fp. outp <n>: ticket n is published and not withdrawn
outfp() { git --git-dir=.vid/code rev-list --first-parent refs/heads/main > "$L/fp" 2>/dev/null || : > "$L/fp"; }
outp() { awk -v n="$1" '$1 == "published" && $2 == n { p = 1 } $1 == "withdrawn" && $2 == n { p = 0 } END { exit !p }' "$LOG" 2>/dev/null; }
cmd_accept() { OS=''; OW=''; RS=''; RW=''; TS=''; TL=''; n=''; c=''; k=0; while [ $# -gt 0 ]; do case $1 in --outside) [ $# -ge 2 ] || acuse; OS=1; OW=$2; shift 2 ;; --rows) [ $# -ge 2 ] || acuse; RS=1; RW=$2; shift 2 ;; --tickets) [ $# -ge 2 ] || acuse; TS=1; TL=$2; shift 2 ;; -*) acuse ;; *) k=$((k + 1)); case $k in 1) n=${1#\#} ;; 2) c=$1 ;; *) acuse ;; esac; shift ;; esac; done
  # FB-3 A4: rows in no published ticket, accepted outside ViD: the owner's words alone, no commit
  if [ -n "$RS" ]; then [ -n "$OS" ] && [ "$k$TS" = 0 ] || acuse; renew; outs --rows "$RW"; outf; return 0; fi
  # FB-3 E1: several tickets accepted outside ViD, each at its commit of main, in one read and one save
  if [ -n "$TS" ]; then [ -n "$OS" ] && [ "$k" = 0 ] || acuse; printf '%s\n' "$TL" | tr ' \t,' '\n\n\n' | sed 's/^#//' | grep . > "$L/tl" || acuse
    ! grep -vqE '^[0-9]+(@[0-9a-f]{7,40})?$' "$L/tl" || acuse; renew; read_; fetch_; ! manual || umerged_; outfp; : > "$L/td"
    while IFS= read -r x <&4; do n=${x%%@*}; c=''; case $x in *@*) c=${x#*@} ;; *) if outp "$n" && [ -z "$(accepted "$n")" ]; then gh_ ticket-decided "$n" > "$L/o" 2> "$L/e" || fail ticket-decided "$(tail -n 1 "$L/e")"; c=$(cut -f2 "$L/o"); [ "$c" != - ] || c=''; fi ;; esac; printf '%s\t%s\n' "$n" "$c" >> "$L/td"; done 4< "$L/tl"
    while IFS=$TAB read -r n c <&4; do outp "$n" || { echo "refused #$n no published ticket that is not withdrawn"; continue; }
      M=$(accepted "$n"); [ -z "$M" ] || { echo "refused #$n accepted already, at $(printf %.12s "$M")"; continue; }
      NT=''; C=''; [ -z "$c" ] || C=$(git --git-dir=.vid/code rev-parse -q --verify "$c^{commit}" 2>/dev/null || echo "$c")
      if [ -z "$C" ] || ! grep -qxF -e "$C" "$L/fp"; then NT="at main's newest commit ($([ -n "$C" ] && echo "$(printf %.12s "$C") is not on main" || echo 'no commit was named'))"; C=$(head -n 1 "$L/fp"); fi
      [ -n "$C" ] || { echo "refused #$n main holds no commit"; continue; }
      h=$(printf %.12s "$C"); if [ -n "$NT" ]; then outs --ticket "$n" --at "$C" --note "$NT"; else outs --ticket "$n" --at "$C"; fi; done 4< "$L/td"
    outf; return 0; fi
  case $n in ''|*[!0-9]*) acuse ;; esac; [ -z "$OS" ] || [ -n "$c" ] || acuse
  renew; read_; fetch_
  ! manual || umerged_   # GM-4 E4: the units merged since the last step, so the Decisions-section gate reads them
  outp "$n" || { echo "refused #$n no published ticket that is not withdrawn"; return 0; }
  # FB-3 A4: the ticket accepted outside ViD, at a commit of main, by the owner's words, in both modes; nothing is posted
  if [ -n "$OS" ]; then outfp
    M=$(accepted "$n"); [ -z "$M" ] || { echo "refused #$n accepted already, at $(printf %.12s "$M")"; return 0; }
    C=$(git --git-dir=.vid/code rev-parse -q --verify "$c^{commit}" 2>/dev/null || echo "$c"); h=$(printf %.12s "$C"); grep -qxF -e "$C" "$L/fp" || { echo "refused #$n $h is not on main"; return 0; }
    outs --ticket "$n" --at "$C"; outf; return 0; fi
  if ! manual; then   # GitHub auto: the open pull request naming the ticket, at its head, as step decides it
    awk -F'\t' -v n="$n" '$1 == "open" && $3 == n { print $2 "\t" $4 "\t" (($7 + 0 > $8 + 0) ? "ask" : "re"); exit }' "$L/read" > "$L/ap"; [ -s "$L/ap" ] || { echo "refused #$n no open pull request names it"; return 0; }
    IFS=$TAB read -r p H am < "$L/ap"; [ -z "$c" ] || case $H in "$c"*) ;; *) echo "refused #$n $c is not the head of pull request $p, $(printf %s "$H" | cut -c1-12)"; return 0 ;; esac
    # an unanswered ask at the head is always answered; else the decision is posted only when it changed
    ask "$n" "$p" "$H" "$am"; [ -n "$DID" ] || { h=$(printf %s "$H" | cut -c1-12); echo "decided $p $h $(sed -n 2p "$D/posted-pr-$p-$h")"; weak_ "$D/posted-pr-$p-$h" "$p" "$h"; }; return 0; fi
  G() { git --git-dir=.vid/code "$@"; }; G rev-list --first-parent refs/heads/main > "$L/fp" 2>/dev/null || : > "$L/fp"
  tasks_ > "$L/ta"; AQ=$(awk -F'\t' -v n="$n" '$1 == n { print $2 }' "$L/ta")   # the ticket's unanswered ask, when it has one
  # the ask by the 12 characters the call's lines show it by is that ask, its full commit, even one .vid/code lacks
  [ -z "$c" ] || [ -z "$AQ" ] || case $AQ in "$c"*) c=$AQ ;; esac
  # an accepted ticket: its unanswered ask answered at the commit asked, nothing decided again; with no ask, nothing posted
  M=$(accepted "$n"); if [ -n "$M" ]; then m12=$(printf %s "$M" | cut -c1-12); C=$AQ
    if [ -n "$C" ]; then mpost "$n" "$(printf 'vid: decision %s\nticket: accepted at %s; its close runs there' "$C" "$m12")"; : > "$D/posted-step-$n-$(printf %s "$C" | cut -c1-12)"; fi
    echo "accepted #$n at $m12; its close runs there"; return 0; fi
  # a ticket closed on GitHub before its acceptance: K1's two commands (E6), and FB-3 E1's third
  awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { f = 1 } END { exit !f }' "$L/read" || { echo "refused #$n closed on GitHub before its acceptance: /vid:vid-tickets reopen #$n \"<your words>\" reopens it, /vid:vid-tickets withdraw #$n \"<your words>\" withdraws it, /vid:vid-accept-step $n <commit> accepted \"<your words>\" records it as accepted outside ViD"; return 0; }
  # E13: with no commit, the newest commit of main's first-parent line at which a result report holds a case of one of the ticket's
  # rows (FB-3 A1.3, results.sh at), an unanswered ask or not; the
  # round's own decide lines name their commit
  if [ -z "$c" ]; then c=$(sh "$HERE/results.sh" at "$n" 2> "$L/e") || fail results "$(tail -n 1 "$L/e")"
    [ -n "$c" ] || { echo "refused #$n no results on main; accepted outside ViD: /vid:vid-accept-step $n <commit> accepted \"<your words>\""; sh "$HERE/results.sh" skipped --ticket "$n"; return 0; }; fi
  C=$(G rev-parse -q --verify "$c^{commit}" 2>/dev/null || true); [ -n "$C" ] || C=$c; h=$(printf %s "$C" | cut -c1-12)
  # E1: a commit off main's first-parent line moves no row
  # answered only to the ticket's unanswered ask at it; a direct call names it and posts nothing
  if ! grep -qx "$C" "$L/fp"; then [ "$C" = "$AQ" ] || { echo "refused #$n $h is not on main"; return 0; }
    mpost "$n" "$(printf 'vid: decision %s\nticket: not yet\nnot on main — %s' "$C" "$C")"; : > "$D/posted-step-$n-$h"
    echo "decided #$n $h ticket: not yet — not on main"; DID=1; return 0; fi
  sh "$HERE/results.sh" at "$n" "$C" > "$L/at" 2> "$L/e" || fail results "$(tail -n 1 "$L/e")"; [ -s "$L/at" ] || { echo "refused #$n no results at $h; accepted outside ViD: /vid:vid-accept-step $n $h accepted \"<your words>\""; sh "$HERE/results.sh" skipped --ticket "$n" --at "$C"; return 0; }
  sh "$HERE/results.sh" read --ticket "$n" --at "$C" > /dev/null 2> "$L/e" || fail results "$(tail -n 1 "$L/e")"
  # FB-3 A1.3: a decision that would be accepted but for ViD's own review: nothing decided, nothing posted, the ask still owed
  dec decide --ticket "$n" --at "$C" --dry > "$L/dry" 2> "$L/e" || fail decide "$(tail -n 1 "$L/e")"; ! grep -qx review "$L/dry" || { echo "review #$n $h"; return 0; }
  dec decide --ticket "$n" --at "$C" > /dev/null 2> "$L/e" || fail decide "$(tail -n 1 "$L/e")"; dec queue > /dev/null 2>&1
  gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"; [ "$C" != "$AQ" ] || rm -f "$D/posted-step-$n-$h"   # an ask always gets its answer
  b=''; [ ! -f "$D/posted-step-$n-$h" ] || b=$(cksum < "$D/posted-step-$n-$h")
  dec decide --ticket "$n" --at "$C" --post > /dev/null 2> "$L/e" || fail post "$(tail -n 1 "$L/e")"
  [ "$(cat "$D/review/none-step-$n" 2>/dev/null)" != "$C" ] || rm -f "$D/review/none-step-$n"   # the review that found no pull request is answered: the next ask looks again
  a=$(cksum < "$D/posted-step-$n-$h"); TL=$(sed -n 2p "$D/posted-step-$n-$h")
  if [ "$TL" = 'ticket: accepted' ]; then dec merged --ticket "$n" > "$L/o" 2>&1 || fail merged "$(tail -n 1 "$L/o")"   # E4: the acceptance is its merge
    printf 'step-%s-%s\t%s\t%s\t%s\n' "$n" "$h" "$n" "$C" "$C" >> "$D/merges"; echo "step-$n-$h" >> "$D/merged-prs"; fi
  sh "$HERE/queue.sh" sync > /dev/null 2> "$L/e" || fail queue "$(tail -n 1 "$L/e")"   # K6: a held row a Q line
  gh_ state-save > /dev/null 2> "$L/e" || fail state-save "$(tail -n 1 "$L/e")"
  [ "$a" = "$b" ] && [ "$C" != "$AQ" ] || { echo "decided #$n $h $TL"; weak_ "$D/posted-step-$n-$h" "#$n" "$h"; }; [ "$TL" != 'ticket: accepted' ] || echo "accepted #$n $h"; DID=1; }
CMD=${1:-}
cmd_read() { [ $# -eq 0 ] || { echo 'usage: sh checks/round.sh read' >&2; exit 2; }; prog on 'Reading GitHub'; rd_ || { rneed 'a look at the chat: GitHub could not be read'; sed 's/^/    /' "$L/e" >&2; echo 'ViD round: the read failed (the lines above) — .vid/round/read is as it was' >&2; exit 1; }; folder_; prog on 'Working out what changed'; }
case $CMD in wait) cmd_wait ;; step) cmd_step ;; next) cmd_next ;; asks) cmd_asks ;; accept) shift; cmd_accept "$@" ;; read) shift; cmd_read "$@" ;; *) echo 'usage: sh checks/round.sh wait|step|next|asks|accept <ticket> [<commit>]|accept <ticket> <commit> --outside "<words>"|accept --rows "<ids>" --outside "<words>"|accept --tickets "<n>[@<commit>] …" --outside "<words>"|read' >&2; exit 2 ;; esac

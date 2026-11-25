#!/bin/sh
# Purpose: /vid mode's steps (GitHub manual, GM-1 S2; GM M2, M3, M15; GM-4 F13): the switch to GitHub manual, and, run in GitHub
# manual, the re-take of stock; the switch back to GitHub auto, and, run in GitHub auto, its take-stock. It writes ViD's own records alone, in the project's folder and in state-repo: (the lock and the saved
# records); it posts nothing to the code repository or the spec repository. Every call it makes is marked as /vid mode's
# (VID_CALLER=mode), so the planner and the GitHub adapter read under GitHub manual's rules before the mode is recorded.
#   manual [--register <file>] [--plan <file>] [--plan-md <file>] [--applied <commit>] [--devagent "<words>"] [--to-place "<words>"]
#          [--review <file>] [--words "<words>"] [--from <folder>] [--take-over "<words>"]
#     --register  one line per published step ticket, `<issue number> <step id>` (`#` lines and blank lines skipped)
#     --plan      the plan block in main's plan grammar (its ```vid-plan fences optional), written into RUN-STATE's ## The plan
#     --plan-md   the project's PLAN.md, written in place and committed alone when it changed
#     --applied   the commit of the spec the published tickets were written from (.vid/tw/applied); on a re-take only when it moves
#     --devagent  the owner's words that DevAgent is stopped, needed coming from GitHub auto alone
#     --to-place  the owner's words accepting the rows to place: the check's `place` flags, in no step or in another stage's step
#     --review    the fresh-agent review of the rows ViD added (planner.sh review --in), recorded when no review has this hash
#     --words     the owner's yes to the ratification; without it the call stops, refused, once the page is written (FB-3 C4: but a
#                 take-stock whose ratification stands, the spec files and the plan those ratified: nothing is asked, `ratified-kept <at>`)
#     --refresh-yes  the owner's yes to the local edits the refresh of checks/ lists (connect.sh start --yes)
#   auto [--register <file>] [--plan <file>] [--plan-md <file>] [--review <file>] [--words "<words>"] [--refresh-yes]   (GM-4 F13,
#     GM M2) from GitHub manual the switch to GitHub auto; in GitHub auto its take-stock; from any other mode refused. Steps 1 to 6
#     below run as the re-take runs them (the applied version is the one recorded; --applied, --from, --take-over, --devagent and
#     --to-place are the switch to manual's, refused here), read under GitHub manual's rules from manual. Then, at the switch, GM
#     M2's refusals, each listed as a `no-auto <what>` line: it "is refused while any open ticket has sub-issues, since DevAgent
#     works whole tickets" (the call's one read, round.sh read, its open `sub` lines under each open `ticket`: a closed sub-issue is done work, GM-4 proof D4); "while any change is
#     pending" (next.sh pending, against the applied version) "or any row is to place" (.vid/tw/to-place, or the check's `place`
#     flags under manual's rules); "and until the plan is ratified again in auto, in the owner's words": steps 7 and 8 under GitHub
#     auto's rules (VID_CALLER=mode-auto, lib.sh's manual false), so the check, page and ratification are auto's, with no to-place
#     reading. Last, github-mode auto through planner.sh setup and the `mode name=auto from=manual words=` event, then `publish-approved` in the same words (GM-4 proof D5: the writer's gate reads it; a take-stock in auto records it too); I3's
#     `owner-questions: all` taken out of .vid/tw/settings, .vid/tw/applied removed (GitHub auto keeps no record of it: F8;
#     .vid/tw/applied.log stays, its history), and what the last /vid next raised, .vid/decide/queue/raised, removed (F4). In GitHub auto (a take-stock) every step reads under auto's rules and nothing
#     is refused but by the check and the words: `mode-retake` recorded, the mode unchanged
#   GM-3 S1: --register, --plan, --plan-md and --applied are optional; each given overrides what is found. At step 4, after the
#   records are restored: the register, every issue labelled <prefix>ticket and (FB-3 C3) every ticket on record whatever its labels,
#   open or closed, its step from its newest writing's header
#   (github.sh tickets; a list that may be cut is not found, and one on record GitHub no longer has is `not-found <n>`, kept); PLAN.md, HEAD's, refused when it has changes not committed; the plan block, RUN-STATE's when it holds one, else
#   .vid/plans/<plan>.plan for the newest published ticket's `- plan:` (the newest by the order of .vid/metrics-events' plan-change
#   lines, then the highest issue number); the applied version, the one recorded (.vid/tw/applied), else the H of the newest
#   published ticket's export, or (GM-4 K13, with layout: one) the export the code repository's folder's stamp names (github.sh
#   spec-stamp; a candidate as a ticket's export is, losing a tie to one) (the newest by .vid/tw/log's export lines when it pushed each, else the one the others are ancestors of in ViD's copy of the
#   spec repository, .vid/spec.git, else the highest issue number's), read from the log's `export <C> from=<H> state=pushed` line, or `state=local` (FB-3 B2; never an unchanged one), else from that
#   copy's commit message (`from: <H>`), the copy first fetched from the spec repository (github.sh spec-fetch, read only), and only when H is a commit of this repository. Each found is printed `found <register|plan|
#   plan-md|applied> <what> — <where it came from>` before it is used; each not found is a line `need <--register|--plan|--plan-md|
#   --applied> — <where ViD looked>`, all of them, then a refusal naming them, exit 5. Each ticket's writing is read once. A read of
#   GitHub that fails is a refusal (exit 1, run again), never a need.
#   FB-4 B1: with layout: one, before a ticket is read, one line `folder <path> …`: the applied version's spec, another commit's (which,
#   and --applied <it> as the answer, a range its newest and oldest), no one commit's, or not on main (github.sh spec-folder's names and
#   ids, lib.sh foldersay); a warning, never a refusal, and never taken as the applied version; `need --applied` names it
#   GM-3 U4: each applied commit set here is a line of .vid/tw/applied.log, `<commit>\t<at>\t<by>` (by: mode; the one in force
#   before it, `seed`, first, when the log is empty and the commit moves); the apply (checks/replan.sh) writes its own lines
#   GM-3 S2, at a switch alone (on a re-take --from and --take-over are refused; the applied version moves only by the apply, GM M3):
#     --from       the copy the published tickets were written from, a folder: PLAN.md, when HEAD holds none, is its PLAN.md; the
#                  plan block, when the project holds none, its .vid/RUN-STATE.md's, else its .vid/plans/<plan>.plan
#     --take-over  the owner's yes to write into the spec the rows the tickets quote that INVENTORY.md lacks at the applied commit
#   Those rows, at step 4 once the inputs are found: without --from a `need --from` naming each; with it, each row's line from the
#   copy's INVENTORY.md, taken only when that line, cut as next.sh differ cuts it, matches every ticket's quote of it (a row with no
#   matching line `take-over-refused <row> #<n> — <why>`, and the switch refused, nothing written); listed `take-over-row`, and on
#   the yes alone, before the applied version is recorded: the take-over commit, made on the tickets' commit (the applied commit
#   found or given) with those rows and, when HEAD holds no PLAN.md, the copy's, its message and an event line carrying the owner's
#   words, kept under refs/vid/applied/<k> and recorded as the applied version. Then, at every switch whose applied version is such
#   a commit, the rows it adds that no commit since the tickets' commit has held are added at HEAD by a commit of their own (a row
#   held since and gone stays gone: `held <row>`). A rerun finds the take-over commit recorded, one --applied naming the commit it
#   was made on included, and makes none again. At step 7, a row a step not yet published names that the applied inventory lacks
#   is taken out of the block, `dropped <row> <step>` (a step left with none taken out too, `dropped-step <step>`), kept in
#   .vid/tw/dropped for the page.
#   In order: (1) the run state, made when missing, `run: waiting`; (2) the setup keys not answered, each an `ask <key>` line,
#   exit 3 (GM-2 §5: issue-form, issue-parent and plan-page among them); (3) vid-connect's start (connect.sh start:
#   the refresh, each repository the setup names and the log does not made, the state repository among them (GM-2 T10, the connect's
#   since GM-4 F2; FB-2 A1: the switch's own state-setup cut), the records restored, the
#   lock taken, github.sh access, the call's stage opened, so plan.sh's gate is on for the sitting; the refresh waiting on the owner
#   exit 4, a line not ready a refusal); (4) the inputs not given, found (GM-3 S1), then the
#   applied version; (5) the register's tickets: one the record lacks taken over at its newest writing (github.sh
#   ticket-writing), its `published … taken-over=` line written from its header; one the record holds kept, or, on a re-take,
#   brought to a newer writing (`amended … taken-over=`); a recorded ticket the register lacks listed and kept; (6) each row a
#   ticket taken over here quotes that differs at the applied commit (next.sh differ), listed; (7) the planning sitting, in the call's stage
#   (GM-4 F12: vid-plan's sitting through its own entries, in its order, plan.sh change, planner.sh review --in, check, page and
#   ratify, no rule of it written here; the review itself is the row review's skill, run before the call, its file --review): the
#   block and PLAN.md written, the plan change recorded when the block is not the newest recorded
#   plan (create, trigger initial, with none recorded; else other, trigger scope-change, evidence commit:<HEAD>), the review
#   recorded, the page; (8) the `place` flags recorded in .vid/tw/to-place in the --to-place words, any other flag a refusal,
#   then planner.sh ratify in the --words; (9) on a switch, github-mode manual through planner.sh setup and the `mode
#   name=manual from=<auto|team|none> words=` event. On every path the records are saved and the lock freed
#   once taken. A refused switch changes no mode; the next call goes on from what it wrote.
# Prints one line per thing recorded: taken-over <n> <step> <body|comments>, from-body <n>, not-taken-over <n> <why>, newer <n>
#   <hash>, kept <n> not in the register, register <n> <its step> writing <its step>, differs <n> <row>, to-place <row> <kind>;
#   looks-accepted #<n> <step> <commit or -> <why> (FB-3 E1, GitHub manual alone: a closed ticket on record, not accepted; it ends nothing),
#   (GM-3 S2) take-over-row <row> #<n> — <where>, take-over-refused <row> #<n> — <why>, take-over <commit> on <commit> — <ref>,
#   at-head <commit> <row>…, held <row> — <why>, dropped <row> <step>, dropped-step <step>;
#   `engines not named — <the command>` (FB-3 E2, GitHub manual alone, with no engines on the handed record);
#   then `mode: GitHub manual, recorded` or `mode: GitHub manual, re-taken` (auto: `mode: GitHub auto, recorded` or `… re-taken`).
#   GM-4 F4 (I3, D6): every switch to or re-take of GitHub manual writes `owner-questions: all` in .vid/tw/settings: every question
#   is the owner's; the switch to auto takes it out. Exit 0; 1 refused; 2 usage; 3 setup keys to ask; 4 the
#   refresh waits for the owner's yes; 5 (GM-3 S1) inputs not found, each a `need` line, to ask of the owner.
# Usage: sh checks/mode.sh auto [--register <file>] [--plan <file>] [--plan-md <file>] [--review <file>] [--words "<words>"] [--refresh-yes]
# Usage: sh checks/mode.sh manual [--register <file>] [--plan <file>] [--plan-md <file>] [--applied <commit>] [--from <folder>] [--take-over "<words>"] [--devagent "<words>"] [--to-place "<words>"] [--review <file>] [--words "<words>"] [--refresh-yes]
# serves: tickets
set -u
IFS='
'
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
VID_CALLER=mode; export VID_CALLER
W=$(mktemp -d); LK=''
usage() { sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2; }
gh_() { sh "$HERE/github.sh" "$@"; }; pl() { sh "$HERE/planner.sh" "$@"; }
# FB-3 D2: the take-stock's progress beside the chat (lib.sh prog): PN, its parts are named; PST, what a stop needs
PN=''; PST='a look at the chat, which says why it stopped'
# done_ <rc>: the end of every path once the lock is taken: the records saved, the lock freed and the call's stage ended (connect.sh end)
done_() { rc=$1; trap - EXIT INT TERM
  [ "$rc" = 0 ] || [ ! -f "$W/tp0" ] || put .vid/tw/to-place < "$W/tp0"
  [ "$rc" != 0 ] || prog on 'Saving the records'
  if [ -n "$LK" ]; then
    sh "$HERE/connect.sh" end > "$W/lf" 2>&1 || { sed 's/^/    /' "$W/lf" >&2; echo 'ViD mode: the records could not be saved or the lock freed (the lines above)' >&2; [ "$rc" != 0 ] || rc=1; }
  # stopped while connect.sh held a lock it had taken for this call (its lock-session written since), that lock is freed
  elif [ -n "${LS0+x}" ] && [ "$(cat .vid/lock-session 2>/dev/null || true)" != "$LS0" ] && [ -s .vid/lock-session ]; then sh "$HERE/github.sh" lock-free > /dev/null 2>&1 || :; fi
  [ -z "$PN" ] || if [ "$rc" = 0 ]; then prog 'done'; else prog stop "$PST"; fi
  rm -rf "$W"; exit "$rc"; }
ref() { echo "ViD mode: refused — $*" >&2; done_ 1; }
trap 'done_ 1' INT TERM; trap 'done_ $?' EXIT
case ${1:-} in manual|auto) TG=$1 ;; *) usage ;; esac; shift
RG=''; PB=''; PM=''; AP=''; DW=''; TW=''; RV=''; WD=''; RY=''; TF=''; TO=''; PMC=''
while [ $# -ge 1 ]; do [ "$1" != --refresh-yes ] || { RY=--yes; shift; continue; }; [ $# -ge 2 ] || usage; case $1 in --register) RG=$2 ;; --plan) PB=$2 ;; --plan-md) PM=$2 ;; --applied) AP=$2 ;; --devagent) DW=$2 ;; --to-place) TW=$2 ;; --review) RV=$2 ;; --words) WD=$2 ;; --from) TF=$2 ;; --take-over) TO=$2 ;; *) usage ;; esac; shift 2; done
[ $# -eq 0 ] && { [ -z "$RG" ] || [ -f "$RG" ]; } && { [ -z "$PB" ] || [ -f "$PB" ]; } && { [ -z "$PM" ] || [ -f "$PM" ]; } || usage; [ -z "$RV" ] || [ -f "$RV" ] || usage
[ -z "$TF" ] || { [ -f "$TF/INVENTORY.md" ] && TF=$(cd "$TF" && pwd -P); } || usage   # GM-3 S2: the copy, a folder holding its INVENTORY.md
for w in "$DW" "$TW" "$WD" "$TO"; do case "$w" in *'
'*) ref "the owner's words are recorded on one line; these span several" ;; esac; done
FROM=$(ghmode); RT=''; [ "$FROM" != manual ] || RT=1
# GM-4 F13: the switch to auto (SWA) and the take-stock in auto read as a re-take: the applied version moves only by the apply
SWA=''; if [ "$TG" = auto ]; then
  case $FROM in manual) SWA=1 ;; auto) VID_CALLER=mode-auto; export VID_CALLER ;; team) ref "/vid mode auto switches a project from GitHub manual; this one is in GitHub team, which is retired: /vid mode manual moves it to GitHub manual first (FB-1 C1)" ;; *) ref "/vid mode auto switches a project from GitHub manual, and takes stock in GitHub auto; this one is in GitHub $FROM, whose mode is /vid plan's setup" ;; esac
  [ -z "$AP$TF$TO$DW$TW" ] || ref '--applied, --from, --take-over, --devagent and --to-place are the switch to GitHub manual'"'"'s; the switch to GitHub auto takes none of them'
  RT=1; fi
[ -z "$RT" ] || [ -z "$TF$TO" ] || ref '--from and --take-over are the switch'"'"'s (GM-3 S2): on a re-take the applied version moves only by the apply, so a row the tickets quote that the spec lacks is refused'
SN=${CLAUDE_CODE_SESSION_ID:-mode-$$-$(date +%s)}

# 1. the run state
if [ ! -f .vid/RUN-STATE.md ]; then mkdir -p .vid; printf 'mode: tickets\nplan: required\nrun: waiting\n\n## The plan\n\n```vid-plan\n```\n' > .vid/RUN-STATE.md
else grep -q '^mode:[[:space:]]*tickets[[:space:]]*$' .vid/RUN-STATE.md || ref "RUN-STATE does not say mode: tickets: this project is not planned for tickets, and GitHub manual is a ticket mode (/vid plan first)"
  rs_edit awk 'BEGIN { d = 0 } /^run:/ && !d { print "run: waiting"; d = 1; next } { print } END { if (!d) print "run: waiting" }' || ref 'RUN-STATE.md could not be written'; fi

# 2. the setup
: > "$W/ask"; for k in layout team split repo spec-repo slack-channels state-repo issue-form issue-parent plan-page; do   # GM-2 (§5): the form's keys; GM-4 J5: spec-repo in both layouts
  # FB-3 B2: but with one repository it is GitHub auto's alone, asked again at the switch to auto when dropped or become the state repository
  if [ "$k" = spec-repo ] && [ "$(skey layout)" = one ]; then [ "$TG" = auto ] || continue; [ -n "$SWA" ] && { [ -z "$(skey spec-repo)" ] || [ "$(skey spec-repo)" = "$(skey state-repo)" ]; } && { echo "ask $k" >> "$W/ask"; continue; }; fi
  grep -q "^setup-answered key=$k " .vid/plan/setup 2>/dev/null || echo "ask $k" >> "$W/ask"; done
if [ -s "$W/ask" ]; then cat "$W/ask"; echo "ViD mode: the setup keys above have no answer of the owner's: ask each, record it (sh checks/planner.sh setup <key> <answer> --words \"<their words>\"), then run this again" >&2; trap - EXIT; rm -rf "$W"; prog 'done'; prog stop 'your answers to the setup'; exit 3; fi
PN=1; prog parts 'Connecting and checking the project' 'Finding the published tickets' 'Reading each ticket' 'Comparing their tests with the spec' 'Writing the plan down' 'Checking the plan' 'Recording your approval' 'Saving the records'
prog on 'Connecting and checking the project'
[ "$TG" = auto ] || [ "$FROM" != auto ] || [ -n "$DW" ] || { PST='your words that DevAgent is stopped'; ref "a switch from GitHub auto needs the owner's words that DevAgent is stopped (--devagent \"<their words>\")"; }
# 3. vid-connect's start (connect.sh): the refresh, the records restored, the lock and GitHub's access check
LS0=$(cat .vid/lock-session 2>/dev/null || true); rc=0; sh "$HERE/connect.sh" start $RY > "$W/cn" 2>&1 || rc=$?
case $rc in 0) LK=1; cat "$W/cn" ;; 3) cat "$W/cn"; echo "ViD mode: the refresh of checks/ waits for the owner: on a yes run this again with --refresh-yes; on a no, sh checks/connect.sh refresh-no \"<their words>\"" >&2; trap - EXIT; rm -rf "$W"; prog stop "your yes to update the project's checks"; exit 4 ;;
  *) sed 's/^/    /' "$W/cn" >&2; ref 'the connection is not ready (the lines above); no lock is held' ;; esac
[ -z "$DW" ] || [ "$TG" = auto ] || [ "$FROM" != auto ] || ev "mode-devagent words=\"$(printf %s "$DW" | tr '"' "'")\""

# 4. the inputs not given, found (GM-3 S1): each printed `found …` before it is used, each not found a `need …` line, then exit 5
prog on 'Finding the published tickets'
# FB-4 B1: which commit's spec the folder holds (github.sh spec-folder, lib.sh foldersay), said before a ticket is read, against the applied
# version given or recorded; with neither, as it is, FK set and FN its words for the need line. A failed read is said and stops nothing
FN=''; FK=''; fsay() { foldersay "$1" > "$W/fs"; [ ! -s "$W/fs" ] || echo "folder $(cut -f2 "$W/fs")"; }
if [ "$TG" = manual ] && [ "$(skey layout)" = one ]; then
  if gh_ spec-folder > /dev/null 2> "$W/fe"; then FC=${AP:-$(applied)}; fsay "$FC"; [ -n "$FC" ] || { FK=1; [ ! -s "$W/fs" ] || FN="; the code repository's folder $(cut -f2 "$W/fs")"; }
  else echo "folder $(folderpath) could not be read (the take-stock goes on without it): $(tail -n 1 "$W/fe")"; fi; fi
mkdir -p "$W/tk"; : > "$W/need"; FA=''; PX=$(skey labels-prefix); GL="GitHub, the code repository's issues labelled ${PX}ticket, open or closed"
nd() { echo "need $1 — $2$([ "$1" != --applied ] || printf %s "$FN")" >> "$W/need"; }
hv() { awk -v k="$2" '/^## / { s = substr($0, 4); next } s == "Header" && index($0, "- " k ": ") == 1 { print substr($0, length(k) + 5); exit }' "$1" 2>/dev/null; }
# rd <n>: ticket n's newest writing read once (github.sh ticket-writing, or kept by github.sh tickets): $W/tk/<n>.line, and .md when whole
rd() { [ -f "$W/tk/$1.line" ] && return 0; gh_ ticket-writing "$1" "$W/tk/$1.md" > "$W/tk/$1.l0" 2> "$W/we" || { sed 's/^/    /' "$W/we" >&2; ref "#$1 could not be read"; }; mv "$W/tk/$1.l0" "$W/tk/$1.line"; }
# heads: `<n> <plan> <export>` of each register ticket with a whole writing, in $W/hd
heads() { [ ! -f "$W/hd" ] || return 0; : > "$W/hd"; TH='none names one'; [ -n "$RG" ] || { TH='not read, the register not found'; return 0; }; i=0
  for n in $(grep -v '^[[:space:]]*\(#\|$\)' "$RG" | awk '$1 ~ /^[0-9]+$/ { print $1 }'); do i=$((i + 1)); [ $((i % 5)) != 0 ] || gh_ lock-renew > /dev/null 2>&1 || ref 'the lock could not be renewed'
    rd "$n"; [ "$(cut -d' ' -f1 "$W/tk/$n.line")" = writing ] || continue; p=$(hv "$W/tk/$n.md" plan); x=$(hv "$W/tk/$n.md" export); echo "$n ${p:--} ${x:--}" >> "$W/hd"; done; }
# newest <field> <records file> <first word> <key or ->: the $W/hd line whose field is latest in the records (`<first word> … <key>=<v>`, or
# with - its second word), then of the highest issue number; a value no record names is older than every one named
newest() { awk -v f="$1" -v E="$2" -v w="$3" -v k="$4" 'BEGIN { while ((getline l < E) > 0) { c = split(l, a, " "); if (a[1] != w) continue; if (k == "-") P[a[2]] = ++m; else for (i = 2; i <= c; i++) if (index(a[i], k "=") == 1) P[substr(a[i], length(k) + 2)] = ++m } }
  $f != "-" { r = ($f in P) ? P[$f] : 0; if (b == "" || r > br || (r == br && $1 + 0 > bn)) { br = r; bn = $1 + 0; b = $0 " " r } } END { print b }' "$W/hd"; }
# PLAN.md, HEAD's, and never over changes not committed
if [ -z "$PM" ]; then
  if git cat-file -e HEAD:PLAN.md 2>/dev/null; then git diff --quiet HEAD -- PLAN.md 2>/dev/null || ref 'PLAN.md has changes not committed: commit them, or name the file with --plan-md'
    git show HEAD:PLAN.md > "$W/pmf"; PM=$W/pmf; echo "found plan-md PLAN.md — HEAD's ($(git rev-parse --short HEAD))"
  elif [ -n "$TF" ] && [ -f "$TF/PLAN.md" ]; then cp "$TF/PLAN.md" "$W/pmf"; PM=$W/pmf; PMC=1; echo "found plan-md PLAN.md — the copy's, $TF/PLAN.md (HEAD holds none; GM-3 S2)"
  else nd --plan-md "PLAN.md at HEAD: HEAD holds none$([ -z "$TF" ] || echo ", nor the copy, $TF")"; fi; fi
if [ -z "$RG" ]; then
  if gh_ tickets "$W/tk" > "$W/tl" 2> "$W/te"; then
    if grep -q '^cut ' "$W/tl"; then nd --register "$GL: $(sed -n 's/^cut [0-9]* //p' "$W/tl")"
    else awk '$1 == "ticket" { print $2, $4 }' "$W/tl" > "$W/rgf"; RG=$W/rgf; grep -E '^(not-taken-over|not-found) ' "$W/tl" || :
      echo "found register $(grep -c . "$W/rgf" | tr -d ' ') tickets, $(grep -c '^ticket [0-9]* open ' "$W/tl" | tr -d ' ') open and $(grep -c '^ticket [0-9]* closed ' "$W/tl" | tr -d ' ') closed — $GL, and the tickets on record in .vid/tw/log whatever their labels, each its step from its newest writing's header (github.sh tickets)"; fi
  else sed 's/^/    /' "$W/te" >&2; ref "the published tickets could not be read from GitHub (the lines above): run this again"; fi; fi   # a failed read is no need
if [ -z "$PB" ]; then
  if [ -n "$(plan_block)" ]; then plan_block > "$W/pbf"; PB=$W/pbf; echo "found plan the plan block, $(grep -c . "$W/pbf" | tr -d ' ') lines — RUN-STATE.md's plan, the newest recorded"
  else heads; set -- $(newest 2 .vid/metrics-events plan-change hash | tr ' ' '\n')
    if [ $# -ge 2 ] && [ -s ".vid/plans/$2.plan" ]; then cp ".vid/plans/$2.plan" "$W/pbf"; PB=$W/pbf; echo "found plan $2 — .vid/plans/$2.plan, the plan of #$1, the newest published ticket's (RUN-STATE.md holds none)"
    # GM-3 S2: with nothing found in the project, the copy's own plan records, its newest first
    elif [ -n "$TF" ] && [ -n "$(plan_block "$TF/.vid/RUN-STATE.md")" ]; then plan_block "$TF/.vid/RUN-STATE.md" > "$W/pbf"; PB=$W/pbf; echo "found plan the plan block, $(grep -c . "$W/pbf" | tr -d ' ') lines — the copy's RUN-STATE.md's plan, $TF/.vid/RUN-STATE.md (the project holds none)"
    elif [ -n "$TF" ] && [ $# -ge 2 ] && [ -s "$TF/.vid/plans/$2.plan" ]; then cp "$TF/.vid/plans/$2.plan" "$W/pbf"; PB=$W/pbf; echo "found plan $2 — the copy's $TF/.vid/plans/$2.plan, the plan of #$1, the newest published ticket's (the project holds none)"
    elif [ $# -ge 2 ]; then nd --plan "RUN-STATE.md's plan (none), then .vid/plans/$2.plan, the plan of #$1, the newest published ticket's (not there)"
    else nd --plan "RUN-STATE.md's plan (none), then the published tickets' headers ($TH)"; fi; fi; fi
if [ "$TG" = auto ]; then :   # GM-4 F13: the applied version as it is, below
elif [ -z "$AP" ] && [ -n "$(applied)" ]; then echo "found applied $(applied) — .vid/tw/applied, the applied version recorded"
elif [ -z "$AP" ]; then heads; SG=.vid/spec.git; SF=''
  # sf: the spec repository's main fetched into ViD's copy once, read only (github.sh spec-fetch); a failed read a refusal
  sf() { [ -z "$SF" ] || return 0; SF=1; gh_ spec-fetch > "$W/sf" 2>&1 || { sed 's/^/    /' "$W/sf" >&2; ref 'the spec repository could not be read into ViD'"'"'s copy (the lines above): run this again'; }; }
  # GM-4 K13: with one repository the folder's stamp on the code repository's main (github.sh spec-stamp) names the export a publish
  # into the folder holds, ViD's or one by hand: read as a published ticket's export is, a candidate numbered 0 (so a ticket wins a
  # tie), its export the full commit the log's export lines or ViD's copy of the spec repository give for it
  STX=$(gh_ spec-stamp 2> "$W/sse") || { sed 's/^/    /' "$W/sse" >&2; ref "the folder's stamp could not be read (the lines above): run this again"; }
  case $STX in *[!0-9a-f]*|'') STX='' ;; esac
  if [ -n "$STX" ]; then SPX=$(awk -v x="$STX" '$1 == "export" && index($2, x) == 1 { print $2; exit }' .vid/tw/log 2> /dev/null)
    [ -n "$SPX" ] || { sf; SPX=$(git --git-dir="$SG" rev-parse -q --verify "$STX^{commit}" 2> /dev/null) || SPX=$STX; }; echo "0 - $SPX" >> "$W/hd"; fi
  set -- $(newest 3 .vid/tw/log export - | tr ' ' '\n')
  # the log's order decides only when it holds a pushed (FB-3 B2: or local) line for every export the tickets name; else the export the
  # others are ancestors of in ViD's copy of the spec repository, read first, when it holds them all; else the highest issue number's
  MX=$(awk -v E=.vid/tw/log 'BEGIN { while ((getline l < E) > 0) if (l ~ /^export / && l ~ / state=(pushed|local)( |$)/) { split(l, a, " "); P[a[2]] = 1 } } $3 != "-" && !($3 in P) { m = 1 } END { print m + 0 }' "$W/hd")
  [ $# -lt 3 ] || [ "$MX" = 0 ] || sf
  if [ $# -ge 3 ] && [ "$MX" = 1 ]; then AX=''; [ ! -d "$SG" ] || for x in $(awk '$3 != "-" { print $3 }' "$W/hd" | sort -u); do o=1
      for y in $(awk '$3 != "-" { print $3 }' "$W/hd" | sort -u); do git --git-dir="$SG" merge-base --is-ancestor "$y" "$x" 2>/dev/null || { o=''; break; }; done
      [ -z "$o" ] || { AX=$x; break; }; done
    if [ -n "$AX" ]; then set -- $(awk -v x="$AX" '$3 == x { l = $0 } END { print l }' "$W/hd" | tr ' ' '\n'); else set -- $(newest 3 /dev/null export - | tr ' ' '\n'); fi; fi
  if [ $# -lt 3 ]; then nd --applied ".vid/tw/applied (none recorded), then the published tickets' headers ($TH)"
  else XN=$1; XC=$3; XD="#$XN, the newest published ticket's"; [ "$XN" != 0 ] || XD="the stamp $(skey spec-path | grep . || echo docs/specs)/$(skey spec-stamp) on the code repository's main"; XH=$(awk -v c="$XC" '$1 == "export" && $2 == c && h == "" { p = ""; f = ""; for (i = 3; i <= NF; i++) { if (index($i, "from=") == 1) f = substr($i, 6); if ($i == "state=pushed" || $i == "state=local") p = 1 } if (p) h = f } END { print h }' .vid/tw/log 2>/dev/null)
    XW=".vid/tw/log's line export $XC from=$XH $(grep "^export $XC " .vid/tw/log 2>/dev/null | grep -oE 'state=(pushed|local)' | head -n 1)"   # its push's line, never a later unchanged export's
    [ -n "$XH" ] || sf
    if [ -z "$XH" ] && git --git-dir="$SG" merge-base --is-ancestor "$XC" refs/heads/main 2>/dev/null; then XH=$(git --git-dir="$SG" log -1 --format=%B "$XC" | sed -n 's/^from: //p' | head -n 1); XW="the export's message, from the spec repository read into ViD's copy, $SG (from: $XH)"; fi
    if [ -z "$XH" ]; then nd --applied ".vid/tw/applied (none recorded), then the export $XC of $XD: .vid/tw/log has no export line for it, and the spec repository, read into ViD's copy ($SG), does not hold it"
    elif FA=$(git rev-parse -q --verify "$XH^{commit}" 2>/dev/null); then echo "found applied $FA — the export $XC of $XD: $XW"
    else FA=''; nd --applied "the export $XC of $XD, names $XH ($XW), no commit of this repository"; fi; fi; fi
[ -z "$FK" ] || [ -z "$FA" ] || fsay "$FA"   # FB-4 B1: the applied version just found
# GM-3 S2: at a switch, the rows the published tickets quote that INVENTORY.md lacks at the commit they were written from (LB)
IK='function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } function key(l,   a, k) { split(l, a, "|"); k = tr(a[1]); return (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr(a[2]) : k }'
# ikeys: an INVENTORY.md on stdin, `<id><TAB><its ```vid-inventory block, 1 the first><TAB><its line>`, each id once, its first line
ikeys() { awk "$IK"' /^```vid-inventory/ { b = 1; o++; next } b && /^```/ { b = 0; next } b && !/^[ \t]*(#|$|grammar:)/ { k = key($0); if (k != "" && !(k in s)) { s[k] = 1; print k "\t" o "\t" $0 } }'; }
tko() { [ -n "$1" ] && git for-each-ref --format='%(objectname)' refs/vid/applied/ | grep -qx "$1"; }   # a take-over commit, kept under refs/vid/applied/
wf() { if grep -q "^published $1 " .vid/tw/log 2>/dev/null; then echo ".vid/tw/out/issue-$1.md"; else echo "$W/tk/$1.md"; fi; }   # ticket n's writing, as step 5 reads it
LB=''; : > "$W/lk"
if [ -z "$RT" ] && [ -n "$RG" ]; then
  if [ -n "$AP" ]; then LB=$(git rev-parse -q --verify "$AP^{commit}" 2>/dev/null) || LB=''; A0=$(applied)
    # a rerun: the take-over commit recorded stands for the commit it was made on
    if [ -n "$LB" ] && tko "$A0" && [ "$(git rev-parse -q --verify "$A0^1" 2>/dev/null)" = "$LB" ]; then echo "found applied $A0 — .vid/tw/applied, the take-over commit made on $LB, which --applied names (GM-3 S2)"; AP=''; LB=$A0; fi
  elif [ -n "$FA" ]; then LB=$FA; else LB=$(applied); fi
  if [ -n "$LB" ]; then git show "$LB:INVENTORY.md" 2>/dev/null | ikeys | cut -f1 > "$W/lbk"
    i=0; for n in $(grep -v '^[[:space:]]*\(#\|$\)' "$RG" | awk '$1 ~ /^[0-9]+$/ { print $1 }' | sort -un); do i=$((i + 1)); [ $((i % 5)) != 0 ] || gh_ lock-renew > /dev/null 2>&1 || ref 'the lock could not be renewed'; grep -q "^published $n " .vid/tw/log 2>/dev/null || { rd "$n"; [ "$(cut -d' ' -f1 "$W/tk/$n.line")" = writing ] || continue; }
      awk '$0 == "## Rows" { on = 1; next } on && /^## / { exit } on' "$(wf "$n")" 2>/dev/null | sed -n 's/^> \{0,1\}//p' | awk "$IK"' { k = key($0); if (k != "" && !(k in s)) { s[k] = 1; print k } }' | while read -r r; do grep -qxF "$r" "$W/lbk" || echo "$r $n"; done; done >> "$W/lk"
    [ ! -s "$W/lk" ] || [ -n "$TF" ] || nd --from "the copy the published tickets were written from: they quote rows INVENTORY.md at $(git rev-parse --short "$LB") lacks, $(awk '{ print $1 " (#" $2 ")" }' "$W/lk" | paste -sd ',' - | sed 's/,/, /g')"; fi; fi
if [ -s "$W/need" ]; then PST="what ViD could not find: $(awk 'BEGIN { W["--register"] = "the register of the published tickets"; W["--plan"] = "the plan"; W["--plan-md"] = "PLAN.md"; W["--applied"] = "the commit the tickets were written from"; W["--from"] = "the copy they were written from" }
    ($2 in W) && !s[$2]++ { K[$2] = 1 } END { n = split("--register --plan --plan-md --applied --from", o, " "); for (i = 1; i <= n; i++) if (o[i] in K) { printf "%s%s", p, W[o[i]]; p = ", " } }' "$W/need")"
  cat "$W/need"; echo "ViD mode: refused — not found, so asked of the owner: $(awk '{ print $2 }' "$W/need" | paste -sd ' ' - | sed 's/ /, /g') (where ViD looked, each line above); run this again with them" >&2; done_ 5; fi
# GM-3 S2: the take-over. ins <inventory> <lines>: the inventory with each `<block>\t<line>` at the end of that ```vid-inventory block
# (the last, past their count)
ins() { awk -v L="$2" -v nb="$(grep -c '^```vid-inventory' "$1")" 'BEGIN { while ((getline x < L) > 0) { t = index(x, "\t"); o = substr(x, 1, t - 1) + 0; if (o > nb) o = nb; A[o] = A[o] substr(x, t + 1) "\n" } }
  /^```vid-inventory/ { b = 1; n++; print; next } b && /^```/ { b = 0; printf "%s", A[n] } { print }' "$1"; }
if [ -s "$W/lk" ]; then
  git diff --quiet HEAD -- INVENTORY.md 2>/dev/null || ref 'INVENTORY.md has changes not committed: commit them, then run this again'
  ikeys < "$TF/INVENTORY.md" > "$W/ck"; : > "$W/tkr"; : > "$W/tkx"
  # each ticket's quotes read against the copy's INVENTORY.md by next.sh differ itself, in a folder of their own
  for n in $(cut -d' ' -f2 "$W/lk" | sort -un); do D=$W/m$n; mkdir -p "$D/.vid/tw/out"; cp "$TF/INVENTORY.md" "$D/INVENTORY.md"; cp "$(wf "$n")" "$D/.vid/tw/out/issue-$n.md"
    ( cd "$D" && sh "$HERE/next.sh" differ "$n" ) > "$W/md" 2> "$W/me" || { sed 's/^/    /' "$W/me" >&2; ref "the rows #$n quotes could not be read against the copy's INVENTORY.md"; }
    for r in $(awk -v n="$n" '$2 == n { print $1 }' "$W/lk"); do
      if ! awk -F'\t' -v r="$r" '$1 == r { f = 1 } END { exit !f }' "$W/ck"; then echo "take-over-refused $r #$n — the copy's INVENTORY.md ($TF) holds no line for it" >> "$W/tkx"
      elif awk -F'\t' -v r="$r" '$1 == "differ" && $3 == r { f = 1 } END { exit !f }' "$W/md"; then echo "take-over-refused $r #$n — the copy's line, cut as next.sh differ cuts it, differs from the ticket's quote" >> "$W/tkx"
      else echo "take-over-row $r #$n — the copy's line ($TF/INVENTORY.md), as the ticket quotes it" >> "$W/tkr"; fi; done; done
  [ ! -s "$W/tkx" ] || { cat "$W/tkx"; ref "$(grep -c . "$W/tkx" | tr -d ' ') rows the published tickets quote have no line in the copy matching the quote (above): none is written into the spec"; }
  cat "$W/tkr"; TR=$(awk '{ print $2 }' "$W/tkr" | awk '!s[$0]++' | paste -sd ' ' -)
  [ -n "$TO" ] || { PST="your yes to write $(grep -c . "$W/tkr" | tr -d ' ') rows into the spec"; ref "the rows above, $TR, are to be written into the spec on the commit the tickets were written from: the owner's yes, --take-over \"<their words>\""; }
  # the take-over commit: the tickets' commit with those rows and, when HEAD holds no PLAN.md, the copy's; made off the branch
  # each row's block and its whole line, the line all that follows ikeys' second tab (a tab inside it kept)
  for r in $(echo "$TR" | tr ' ' '\n'); do awk -F'\t' -v r="$r" '$1 == r { l = $0; sub(/^[^\t]*\t[^\t]*\t/, "", l); print $2 "\t" l; exit }' "$W/ck"; done > "$W/tl"
  git show "$LB:INVENTORY.md" > "$W/bi" 2>/dev/null && [ "$(grep -c '^```vid-inventory' "$W/bi")" -gt 0 ] || ref "INVENTORY.md at $LB holds no vid-inventory block to take the rows into"
  ins "$W/bi" "$W/tl" > "$W/ti"; OW=$(printf %s "$TO" | tr '"' "'")
  printf 'The take-over: the rows the published tickets quote, on the commit they were written from\n\nREQs: none\nDecisions: none — %s, quoted by the published tickets and missing from INVENTORY.md here, each from the copy they were written from, its line matching the quote, taken over by /vid mode manual in the owner'"'"'s words (checks/mode.sh, GM-3 S2)\nSeams: none\nOwner: "%s"\n' "$(echo "$TR" | sed 's/ /, /g')" "$OW" > "$W/tm"
  rm -f "$W/ix"; TT=$(GIT_INDEX_FILE=$W/ix; export GIT_INDEX_FILE; git read-tree "$LB" && git update-index --add --cacheinfo "100644,$(git hash-object -w "$W/ti"),INVENTORY.md" \
    && { [ -z "$PMC" ] || git update-index --add --cacheinfo "100644,$(git hash-object -w "$PM"),PLAN.md"; } && git write-tree) && TC=$(git commit-tree "$TT" -p "$LB" -F "$W/tm") || ref 'the take-over commit could not be made'
  K=$(git for-each-ref --format='%(refname)' refs/vid/applied/ | sed 's#.*/##' | awk '$1 ~ /^[0-9]+$/ && $1 + 0 > m { m = $1 + 0 } END { print m + 1 }')
  git update-ref "refs/vid/applied/$K" "$TC" '' || ref "refs/vid/applied/$K could not be made"
  ev "mode-take-over commit=$TC on=$LB ref=refs/vid/applied/$K rows=$(echo "$TR" | tr ' ' ',') words=\"$OW\""
  echo "take-over $TC on $LB — refs/vid/applied/$K, the applied version: $TR"; AP=''; FA=$TC; fi

# the applied version
# GM-3 U4: alog, each applied commit with the time it was set, in .vid/tw/applied.log (`<commit>\t<at>\t<by>`): the one in force
# first, when the log has none yet and it moves (seed), then the new one, set by the switch (mode); a commit already newest stays
alog() { _c=$(applied); [ -n "$_c" ] || return 0; mkdir -p .vid/tw; touch .vid/tw/applied.log
  if [ -n "${1:-}" ] && [ "$1" != "$_c" ] && [ ! -s .vid/tw/applied.log ]; then printf '%s\t%s\tseed\n' "$1" "$(now)" >> .vid/tw/applied.log; fi
  [ "$(tail -n 1 .vid/tw/applied.log | cut -f1)" = "$_c" ] || printf '%s\t%s\tmode\n' "$_c" "$(now)" >> .vid/tw/applied.log; }
A0=$(applied)
if [ "$TG" = auto ]; then [ -n "$A0" ] || ref "no applied version is recorded: in GitHub manual every change reaches the team through the apply (/vid next), so the switch to GitHub auto starts from the one the team has"
elif [ -n "$AP" ]; then C=$(git rev-parse -q --verify "$AP^{commit}" 2>/dev/null) || ref "--applied $AP names no commit"; echo "$C" > "$W/ap"; put .vid/tw/applied < "$W/ap" || ref '.vid/tw/applied could not be written'
elif [ -n "$FA" ]; then echo "$FA" > "$W/ap"; put .vid/tw/applied < "$W/ap" || ref '.vid/tw/applied could not be written'
elif [ -z "$(applied)" ]; then ref "no applied version is recorded: --applied <the commit the published tickets were written from>"; fi
[ "$TG" = auto ] || alog "$A0" || ref '.vid/tw/applied.log could not be written'
AC=$(applied)
# GM-3 S2: at a switch whose applied version is a take-over commit, the rows it adds at HEAD by a commit of their own: each row no
# commit since the tickets' commit has held, so a change made since stays pending (a row retired since stays retired); every
# commit is read, a side branch merged back included (--full-history)
if [ -z "$RT" ] && tko "$AC"; then B=$(git rev-parse "$AC^1") || ref "the take-over commit $AC has no parent"
  git show "$AC:INVENTORY.md" | ikeys > "$W/ak"; git show "$B:INVENTORY.md" 2>/dev/null | ikeys | cut -f1 > "$W/bk"; git show HEAD:INVENTORY.md 2>/dev/null | ikeys | cut -f1 > "$W/hk"
  for c in $(git rev-list --full-history "$B..HEAD" -- INVENTORY.md); do git show "$c:INVENTORY.md" 2>/dev/null | ikeys | cut -f1; done | sort -u > "$W/held"; : > "$W/hl"; HR=''
  while IFS='	' read -r r o l; do grep -qxF "$r" "$W/bk" && continue; grep -qxF "$r" "$W/hk" && continue
    if grep -qxF "$r" "$W/held"; then echo "held $r — a commit since the tickets' commit held it, and HEAD does not: not added, so what was done to it since stays pending"
    else printf '%s\t%s\n' "$o" "$l" >> "$W/hl"; HR="$HR $r"; fi; done < "$W/ak"
  if [ -s "$W/hl" ]; then git diff --quiet HEAD -- INVENTORY.md 2>/dev/null || ref 'INVENTORY.md has changes not committed: commit them, then run this again'
    git show HEAD:INVENTORY.md > "$W/hi0" && ins "$W/hi0" "$W/hl" > "$W/hi" && cat "$W/hi" > INVENTORY.md || ref 'INVENTORY.md could not be written'
    { printf 'INVENTORY.md: the rows the published tickets quote, taken over by /vid mode manual\n\nREQs: none\nDecisions: none — %s, the rows of the take-over commit %s that no commit since the tickets'"'"' commit has held, added at HEAD (checks/mode.sh, GM-3 S2)\nSeams: none\n' "$(echo "$HR" | sed 's/^ //; s/ /, /g')" "$(git rev-parse --short "$AC")"
      git log -1 --format=%B "$AC" | grep '^Owner: '; } > "$W/hm"
    git add INVENTORY.md && git commit -q -F "$W/hm" -- INVENTORY.md > "$W/cm" 2>&1 || { sed 's/^/    /' "$W/cm" >&2; git checkout -q HEAD -- INVENTORY.md 2>/dev/null; ref 'the taken-over rows could not be committed at HEAD'; }
    echo "at-head $(git rev-parse HEAD)$HR"; fi; fi

# 5. the tickets
prog on 'Reading each ticket'
mkdir -p .vid/tw/out; touch .vid/tw/log; [ -f .vid/tw/handed ] || : > .vid/tw/handed; : > "$W/new"   # GM-2 lane B review: an empty handed record, so writer.sh due runs on a switched project
hdr() { awk -v k="$2" '/^## / { s = substr($0, 4); next } s == "Header" && index($0, "- " k ": ") == 1 { v = substr($0, length(k) + 5); print v; exit }' "$1"; }
take() { # take <n> <file> <hash> <src> <parts> <published|amended>: the writing recorded, its hash kept on its log line
  tk=$(hdr "$2" kind); ts=$(hdr "$2" step); tr_=$(hdr "$2" rows | tr ' ' ',' | sed 's/,,*/,/g; s/^,//; s/,$//'); tp=$(hdr "$2" plan); tb=$(hdr "$2" base); te=$(hdr "$2" export)
  put ".vid/tw/out/issue-$1.md" < "$2" || ref "the writing of #$1 could not be recorded"
  printf '%s %s kind=%s step=%s rows=%s plan=%s base=%s export=%s parts=%s taken-over=%s writing=%s at=%s\n' "$6" "$1" "${tk:--}" "${ts:--}" "${tr_:--}" "${tp:--}" "${tb:--}" "${te:--}" "$5" "$4" "$3" "$(now)" >> .vid/tw/log
  echo "$1" >> "$W/new"; [ "$4" != body ] || echo "from-body $1"; SH=$ts; }
# whash <n>: the hash of the writing ViD's record holds: its newest log line's writing=, else (a ticket ViD posted) its text's
whash() { _wh=$(awk -v n="$1" '($1 == "published" || $1 == "amended") && $2 == n { h = "" ; for (i = 3; i <= NF; i++) if ($i ~ /^writing=/) h = substr($i, 9) } END { print h }' .vid/tw/log)
  [ -n "$_wh" ] || _wh=$(git hash-object ".vid/tw/out/issue-$1.md" | cut -c1-12); printf '%s' "$_wh"; }
grep -v '^[[:space:]]*\(#\|$\)' "$RG" > "$W/rg" || :
i=0; while IFS=' ' read -r n s _; do case "$n" in ''|*[!0-9]*) ref "the register's line \"$n $s\" is not <issue number> <step id>" ;; esac; [ -n "$s" ] || ref "the register's line for #$n names no step"
  i=$((i + 1)); [ $((i % 5)) != 0 ] || gh_ lock-renew > /dev/null 2>&1 || ref 'the lock could not be renewed'
  prog now "ticket $i of $(grep -c . "$W/rg" | tr -d ' '), $(grep -c . "$W/new" | tr -d ' ') new so far"
  if grep -q "^published $n " .vid/tw/log; then
    [ -n "$RT" ] || continue
    rd "$n"; cp "$W/tk/$n.line" "$W/wl"; [ ! -f "$W/tk/$n.md" ] || cp "$W/tk/$n.md" "$W/tw"
    set -- $(tr ' ' '\n' < "$W/wl"); [ "$1" = writing ] || continue; h=$3
    [ "$h" = "$(whash "$n")" ] || { take "$n" "$W/tw" "$h" "$4" "$5" amended; echo "newer $n $h"; }; continue; fi
  rd "$n"; cp "$W/tk/$n.line" "$W/wl"; [ ! -f "$W/tk/$n.md" ] || cp "$W/tk/$n.md" "$W/tw"
  set -- $(tr ' ' '\n' < "$W/wl"); if [ "$1" != writing ]; then echo "not-taken-over $n $(cut -d' ' -f3- "$W/wl")"; continue; fi
  take "$n" "$W/tw" "$3" "$4" "$5" published; echo "taken-over $n $SH $4"; [ "$SH" = "$s" ] || echo "register $n $s writing $SH"
done < "$W/rg"
awk '$1 == "published" { print $2 }' .vid/tw/log | sort -un | while read -r n; do grep -q "^withdrawn $n " .vid/tw/log && continue; awk -v n="$n" '$1 == n { f = 1 } END { exit !f }' "$W/rg" || echo "kept $n not in the register"; done

# 6. the rows each ticket taken over here quotes, at the applied commit
prog on 'Comparing their tests with the spec'
for n in $(cat "$W/new"); do sh "$HERE/next.sh" differ "$n" "$AC" > "$W/df" 2> "$W/de" || { sed 's/^/    /' "$W/de" >&2; ref "the rows of #$n could not be read at the applied commit"; }
  awk '$1 == "differ" { print "differs " $2 " " $3 }' "$W/df"; done

# FB-3 E1: at a switch to or take-stock in GitHub manual, each ticket on record, not withdrawn and not accepted (round.sh accepted's own
# test), whose issue is closed: one line each, which ends nothing and records nothing; one read a ticket, none for one found open above
if [ "$TG" = manual ]; then i=0; for n in $(onrec); do
    [ -z "$(awk -F'\t' -v n="$n" '$2 == n { c = $4 } END { if (c != "") print c }' .vid/decide/merges 2>/dev/null)" ] || continue
    ! grep -q "^ticket $n open " "$W/tl" 2>/dev/null || continue
    i=$((i + 1)); [ $((i % 5)) != 0 ] || gh_ lock-renew > /dev/null 2>&1 || ref 'the lock could not be renewed'
    gh_ ticket-decided "$n" > "$W/td" 2> "$W/te" || { sed 's/^/    /' "$W/te" >&2; ref "#$n could not be read for its acceptance: run this again"; }
    LS_=$(awk -v n="$n" '($1 == "published" || $1 == "amended") && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) s = substr($i, 6) } END { print (s == "" ? "-" : s) }' .vid/tw/log)
    awk -F'\t' -v n="$n" -v s="$LS_" '$1 == "closed" { print "looks-accepted #" n " " s " " $2 " " ($2 == "-" ? "closed, no decision comment" : "ticket: accepted, by " $3 " on " $4) }' "$W/td"; done; fi

# GM-4 F13 (GM M2): the switch to auto's refusals, each listed, then steps 7 and 8 under GitHub auto's rules
if [ -n "$SWA" ]; then : > "$W/no"; WA='the switch to GitHub auto'
  sh "$HERE/round.sh" read > "$W/rr" 2>&1 || { sed 's/^/    /' "$W/rr" >&2; ref "GitHub could not be read for the open tickets' sub-issues (round.sh read): run this again"; }
  awk -F'\t' '$1 == "unread" && ($2 == "round" || $2 == "ticket" || $2 == "sub") { print $2 " " $3 }' .vid/round/read > "$W/ur"
  [ ! -s "$W/ur" ] || ref "GitHub was not read whole for the open tickets' sub-issues (unread: $(paste -sd ',' - < "$W/ur")): run this again"
  # GM-4 proof D4: "while any open ticket has sub-issues" read as sub-issues still open: one the team closed is done work, and
  # vid-mode tells the team to close or merge them first
  awk -F'\t' '$1 == "ticket" && toupper($3) == "OPEN" { o[$2] = 1 } $1 == "sub" && toupper($5) == "OPEN" { s[$2] = s[$2] " #" $4 } END { for (n in o) if (n in s) print "#" n " (sub-issues" s[n] ")" }' .vid/round/read | sort > "$W/sb"
  [ ! -s "$W/sb" ] || echo "no-auto sub-issues — $WA is refused while any open ticket has sub-issues, since DevAgent works whole tickets: $(paste -sd ',' - < "$W/sb" | sed 's/,/, /g')" >> "$W/no"
  # read as the project's own mode, GitHub manual, with no caller mark, so its scratch reads of the applied spec run as a call's do
  VID_CALLER='' sh "$HERE/next.sh" pending > "$W/pe" 2> "$W/pee" || { sed 's/^/    /' "$W/pe" "$W/pee" >&2; ref 'the pending changes could not be read (next.sh pending): run this again'; }
  awk -F'\t' 'NF { $1 = $1; print }' "$W/pe" > "$W/pn"
  [ ! -s "$W/pn" ] || echo "no-auto pending — $WA is refused while any change is pending: $(paste -sd ',' - < "$W/pn" | sed 's/,/; /g') (the apply sends them to the team: /vid next)" >> "$W/no"
  { awk -F'\t' 'NF { print $1 }' .vid/tw/to-place 2>/dev/null; pl check 2>/dev/null | awk '$1 == "place" { print $2 }'; } | awk '!s[$0]++' > "$W/tpa"
  [ ! -s "$W/tpa" ] || echo "no-auto to-place — $WA is refused while any row is to place: $(paste -sd ' ' - < "$W/tpa") (place each in a step: /vid next's re-plan)" >> "$W/no"
  [ ! -s "$W/no" ] || { cat "$W/no"; ref "$WA is refused (the lines above): the mode stays GitHub manual"; }
  # FB-3 C3: the switch posts nothing, so a ticket on record without the label is one DevAgent will not see: said, one line each
  for n in $(onrec); do awk -F'\t' -v n="$n" -v T=",${PX}ticket," -v L="${PX}ticket" '$1 == "issue" && $2 == n && !index("," $3 ",", T) { print "unlabelled #" n " — an open ticket on record without the label " L ": DevAgent works only issues labelled " L }' .vid/round/read; done
  VID_CALLER=mode-auto; export VID_CALLER; fi

# 7. the plan, in a planning sitting
prog on 'Writing the plan down'
if grep -q '^```vid-plan' "$PB"; then awk '/^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' "$PB"; else cat "$PB"; fi > "$W/blk"
# GM-3 S2: at a switch, a row a step not yet published names that the applied inventory lacks is taken out of the block (and out of
# its needs line), since such a step may change freely (GM M10, rule 3); a range <PREFIX>-a..<PREFIX>-b holding such a row is
# written out, as plan.sh reads it, less that row (a range holding none is left as written); a step left with no row is taken
# out, `dropped-step <step>`, and where another step's builds-on: or fakes:, or a needs line, names it, its own builds-on takes
# its place (a fakes: only loses it), so the order stays, and a step's fakes: loses any step its builds-on: so rewritten names;
# the rows of a rows: field and a needs line are split on spaces and commas, as planner.sh reads them
: > "$W/dr"; if [ -z "$RT" ]; then git show "$AC:INVENTORY.md" 2>/dev/null | ikeys | cut -f1 > "$W/aik"
  awk '$1 == "published" { k = ""; s = ""; for (i = 3; i <= NF; i++) { if ($i ~ /^kind=/) k = substr($i, 6); if ($i ~ /^step=/) s = substr($i, 6) } if (k == "step" || k == "skeleton") P[$2] = s } $1 == "withdrawn" { X[$2] = 1 }
    END { for (n in P) if (!(n in X)) print P[n] }' .vid/tw/log | sort -u > "$W/pst"
  awk -v A="$W/aik" -v PS="$W/pst" -v D="$W/dr" 'BEGIN { while ((getline l < A) > 0) I[l] = 1; while ((getline l < PS) > 0) P[l] = 1 }
    # ids <token>: a range of one prefix written out, each id zero-padded to its first id'"'"'s width as plan.sh pads it, else the token
    function ids(x,   a, b, pa, pb, lo, hi, w, k, r) { if (x !~ /^[A-Z]+-[0-9]+\.\.[A-Z]+-[0-9]+$/) return x
      a = x; sub(/\.\..*/, "", a); b = x; sub(/.*\.\./, "", b); pa = a; sub(/-[0-9]+$/, "", pa); pb = b; sub(/-[0-9]+$/, "", pb)
      lo = a; sub(/^[A-Z]+-/, "", lo); hi = b; sub(/^[A-Z]+-/, "", hi); w = length(lo); if (pa != pb || hi + 0 < lo + 0 || hi - lo > 20000) return x
      r = ""; for (k = lo + 0; k <= hi + 0; k++) r = r (r == "" ? "" : " ") sprintf("%s-%0" w "d", pa, k); return r }
    # keep <token>: the token less the ids taken out (c set when any is), a range none of whose ids is taken out as written
    function keep(x,   n, e, i, r, h) { n = split(ids(x), e, " "); r = ""; h = 0; for (i = 1; i <= n; i++) if (e[i] in X) h = 1; else r = r (r == "" ? "" : " ") e[i]
      if (!h) return x; c = 1; return r }
    # up <step>: the steps a step taken out builds on, each one taken out read through to its own; sref <steps> <dashed>: the
    # steps, each one taken out replaced by up (a dashed link only losing it), c set, "-" when none is left; as written when none is
    function up(s, d,   n, a, i, o) { if (d > 50) return ""; n = split(BO[s], a, /[ \t,]+/); o = ""; for (i = 1; i <= n; i++) if (a[i] != "" && a[i] != "-") o = o " " ((a[i] in E) ? up(a[i], d + 1) : a[i]); return o }
    function sref(v, dash,   n, a, i, h, o, u, m, b, j) { n = split(v, a, /[ \t,]+/); h = 0; for (i = 1; i <= n; i++) if (a[i] in E) h = 1; if (!h) return v; c = 1; o = ""
      for (i = 1; i <= n; i++) { if (a[i] == "" || a[i] == "-") continue; if (a[i] in E) { if (dash) continue; m = split(up(a[i], 0), b, " ") } else { m = 1; b[1] = a[i] }
        for (j = 1; j <= m; j++) if (b[j] != "" && !(b[j] in u)) { u[b[j]] = 1; o = o (o == "" ? "" : " ") b[j] } }
      return (o == "" ? "-" : o) }
    FNR == NR { if ($1 != "step") next; n = split($0, f, "|"); for (i = 1; i <= n; i++) if (f[i] ~ /^[ \t]*builds-on:/) { x = f[i]; sub(/^[ \t]*builds-on:[ \t]*/, "", x); BO[$2] = x }
      if ($2 in P) next; h = 0; kp = 0
      for (i = 1; i <= n; i++) if (f[i] ~ /^[ \t]*rows:/) { h = 1; m = split(f[i], t, /[ \t,]+/)
        for (j = 1; j <= m; j++) { q = split(ids(t[j]), e, " "); for (g = 1; g <= q; g++) if (e[g] ~ /^[A-Z]+-[0-9]+$/ && !(e[g] in I)) { X[e[g]] = 1; print "dropped " e[g] " " $2 > D } else if (e[g] != "rows:") kp++ } }
      if (h && !kp) { E[$2] = 1; print "dropped-step " $2 > D } next }
    $1 == "step" && ($2 in E) { next }
    $1 == "step" { n = split($0, f, "|"); o = ""; c = 0; nb = ""; fk = 0; for (i = 1; i <= n; i++) { if (!($2 in P) && f[i] ~ /^[ \t]*rows:/) { m = split(f[i], t, /[ \t,]+/); v = " rows:"
          for (j = 1; j <= m; j++) if (t[j] != "" && t[j] != "rows:") { k = keep(t[j]); if (k != "") v = v " " k } f[i] = v " " }
        else if (f[i] ~ /^[ \t]*(builds-on|fakes):/) { x = f[i]; sub(/^[ \t]*/, "", x); y = x; sub(/:.*/, "", y); x = substr(x, length(y) + 2); z = sref(x, y == "fakes"); if (z != x) f[i] = " " y ": " z (i < n ? " " : "")
          if (y == "fakes") fk = i; else if (z != x) nb = z } }
      # a fakes: link to a step the rewritten builds-on: now names taken out of it, "-" when none is left
      if (nb != "" && fk) { x = f[fk]; sub(/^[ \t]*fakes:/, "", x); m = split(x, t, /[ \t,]+/); q = split(nb, e, " "); v = ""; d = 0
        for (j = 1; j <= m; j++) { if (t[j] == "" || t[j] == "-") continue; h = 0; for (g = 1; g <= q; g++) if (e[g] == t[j]) h = 1; if (h) d = 1; else v = v (v == "" ? "" : " ") t[j] }
        if (d) { c = 1; f[fk] = " fakes: " (v == "" ? "-" : v) (fk < n ? " " : "") } }
      for (i = 1; i <= n; i++) o = o (i > 1 ? "|" : "") f[i]; print (c ? o : $0); next }
    $1 == "needs" { p = index($0, "|"); if (!p) { print; next } m = split(substr($0, 1, p - 1), t, /[ \t,]+/); v = ""; c = 0
      for (j = 1; j <= m; j++) if (t[j] != "" && t[j] != "needs") { k = keep(t[j]); if (k != "") v = v " " k }
      w = substr($0, p + 1); z = sref(w, 0); if (z != w) w = " " z
      if (!c) print; else if (v != "") print "needs" v " |" w; next }
    { print }' "$W/blk" "$W/blk" > "$W/blk2" && mv "$W/blk2" "$W/blk" || ref 'the plan block could not be read for the rows to take out'; fi
rs_edit awk -v B="$W/blk" 'function blk(  l) { print "```vid-plan"; while ((getline l < B) > 0) print l; print "```" }
  /^## The plan/ { print; s = 1; d = 1; next } s && /^## / { if (!w) { print ""; blk(); print "" } s = 0; w = 1 }
  s && /^```vid-plan[ \t]*$/ { if (!w) blk(); w = 1; b = 1; next } b { if (/^```[ \t]*$/) b = 0; next } { print }
  END { if (s && !w) { print ""; blk() } if (!d) { print ""; print "## The plan"; print ""; blk() } }' || ref "RUN-STATE's plan could not be written"
[ ! -s "$W/dr" ] || { cat "$W/dr"; awk -v t="$(now)" '{ print $0 " at=" t }' "$W/dr" >> .vid/tw/dropped; }   # GM-3 S2: for the page
if [ ! -f PLAN.md ] || ! cmp -s "$PM" PLAN.md; then cp "$PM" PLAN.md || ref 'PLAN.md could not be written'; fi
if ! git diff --quiet HEAD -- PLAN.md 2>/dev/null || ! git cat-file -e HEAD:PLAN.md 2>/dev/null; then
  git add PLAN.md && git commit -q -m 'PLAN.md: the plan of the published tickets, taken over by /vid mode manual' -m 'REQs: none
Decisions: none — the project'"'"'s PLAN.md as the owner brought it to /vid mode manual (checks/mode.sh)
Seams: none' -- PLAN.md > "$W/cm" 2>&1 || { sed 's/^/    /' "$W/cm" >&2; ref 'PLAN.md could not be committed'; }; fi
EXP="the register's $(grep -c . "$W/rg" | tr -d ' ') tickets, each ticket's rows in its step"
R=$(grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p')
if [ -z "$R" ]; then sh "$HERE/plan.sh" change create 'the take-over of the published tickets' --trigger initial --expect "$EXP" > "$W/pc" 2>&1 || { sed 's/^/    /' "$W/pc" >&2; ref 'the plan change was refused'; }
elif [ ! -f ".vid/plans/$R.plan" ] || [ "$(plan_block | sh "$HERE/plan.sh" canon)" != "$(sh "$HERE/plan.sh" canon < ".vid/plans/$R.plan")" ]; then
  if [ -n "$SWA" ]; then WY='the switch to GitHub auto'; elif [ -n "$RT" ]; then WY='the re-take'; else WY='the take-over of the published tickets'; fi
  sh "$HERE/plan.sh" change other "$WY" --trigger scope-change --evidence "commit:$(git rev-parse HEAD)" --expect "$EXP" > "$W/pc" 2>&1 || { sed 's/^/    /' "$W/pc" >&2; ref 'the plan change was refused'; }; fi
H=$(pl hash) || ref 'the spec could not be read at the applied commit'
# with no row ViD added there is nothing to review, and the review that ratify needs says so
if [ -z "$RV" ] && [ -z "$(pl rows --added)" ]; then printf 'none\n' > "$W/rv0"; RV=$W/rv0; fi
if [ -n "$RV" ] && ! grep -qs "^review [0-9]* hash=$H " .vid/plan/review; then pl review --in "$RV" > "$W/rv" 2>&1 || { sed 's/^/    /' "$W/rv" >&2; ref 'the review was refused'; }; fi

prog on 'Checking the plan'
# 8. the ratification: the list of rows to place written whole, so the check first sees every place flag
# the list as last ratified kept aside, and put back by done_ on any refusal
# FB-3 C4: on a take-stock (never at a switch, which asks), what the owner accepted stands while it is unchanged. KR: the newest
# ratification's time, while planner.sh ratified holds and its plan= is the block's, with no --words given: nothing is asked or written
# again but the page. Else each no-step row of the list is kept, its time and words, while the check flags it so and its inventory line
# is the one at the commit in force when last ratified (.vid/tw/applied.log); the rest are listed and asked
KR=''; if [ -n "$RT" ] && [ -z "$SWA" ] && [ -z "$WD" ] && pl ratified > "$W/rk" 2>/dev/null; then
  KR=$(tail -n 1 .vid/plan/ratified | awk -v p="plan=$(sed -n 's/.*, plan //p' "$W/rk")" '$3 == p && $4 ~ /^at=/ { print substr($4, 4) }'); fi
if [ -z "$KR" ]; then
[ ! -f .vid/tw/to-place ] || { cp .vid/tw/to-place "$W/tp0" && : > .vid/tw/to-place; }
pl check > "$W/ck" 2>&1; grep -v '^planner: clean' "$W/ck" | grep -v '^place ' > "$W/of" || :
[ ! -s "$W/of" ] || { sed 's/^/    /' "$W/of" >&2; pl page > /dev/null 2>&1; ref "the check flags the plan beyond the rows to place (the lines above): change the plan or the spec, then run this again$(! grep -q '^stages STAGES' "$W/of" || echo "; a STAGES.md the stage court refuses: fix it in a commit and give it with --applied")"; }
awk '$1 == "place" { print $2 "\t" (index($0, " — in no step") ? "no-step" : "other-stage") }' "$W/ck" > "$W/pf"
# kept: $W/kp, the list's lines that stand; asked: $W/nw, the rest of the flagged rows
: > "$W/kp"; if [ -n "$RT" ] && [ -z "$SWA" ] && [ -s "$W/tp0" ]; then RA=$(tail -n 1 .vid/plan/ratified 2>/dev/null | awk '$4 ~ /^at=/ { print substr($4, 4) }')
  C0=$(awk -F'\t' -v t="$RA" 't != "" && $2 <= t { c = $1 } END { print c }' .vid/tw/applied.log 2>/dev/null)
  if [ -n "$C0" ] && git show "$C0:INVENTORY.md" > "$W/iv0" 2>/dev/null && git show "$AC:INVENTORY.md" > "$W/iv1" 2>/dev/null; then
    ikeys < "$W/iv0" | cut -f1,3- > "$W/ik0"; ikeys < "$W/iv1" | cut -f1,3- > "$W/ik1"
    awk -F'\t' -v I0="$W/ik0" -v I1="$W/ik1" -v PF="$W/pf" 'BEGIN { while ((getline l < I0) > 0) { k = l; sub(/\t.*/, "", k); A[k] = l } while ((getline l < I1) > 0) { k = l; sub(/\t.*/, "", k); B[k] = l } while ((getline l < PF) > 0) F[l] = 1 }
      $2 == "no-step" && (($1 "\t" $2) in F) && ($1 in A) && A[$1] == B[$1]' "$W/tp0" > "$W/kp"; fi; fi
awk -F'\t' -v K="$W/kp" 'BEGIN { while ((getline l < K) > 0) { split(l, x, "\t"); S[x[1]] = 1 } } !($1 in S)' "$W/pf" > "$W/nw"
if [ -s "$W/pf" ]; then [ -n "$TW" ] || [ ! -s "$W/nw" ] || { n=$(grep -c . "$W/nw" | tr -d ' '); PST="your words for $n $([ "$n" = 1 ] && echo test || echo tests) to place"; sed 's/^/    place /' "$W/nw" >&2; pl page > /dev/null 2>&1; ref "$(grep -c . "$W/nw" | tr -d ' ') rows are to place (above): the owner's words accepting them, --to-place \"<their words>\""; }
  { cat "$W/kp"; awk -F'\t' -v t="$(now)" -v w="$TW" -v OFS='\t' '{ print $1, $2, t, w }' "$W/nw"; } > "$W/tp"; put .vid/tw/to-place < "$W/tp" || ref '.vid/tw/to-place could not be written'
  awk -F'\t' '{ print "to-place " $1 " " $2 }' "$W/nw"; [ ! -s "$W/kp" ] || echo "to-place-kept $(grep -c . "$W/kp" | tr -d ' ') — accepted before, unchanged"
  pl check > "$W/ck2" 2>&1 || { sed 's/^/    /' "$W/ck2" >&2; ref 'the check still flags the plan with the rows to place recorded'; }
else : > "$W/tp"; [ ! -f .vid/tw/to-place ] || put .vid/tw/to-place < "$W/tp"; fi; fi
pl page > "$W/pg" 2>&1 || { sed 's/^/    /' "$W/pg" >&2; ref 'the page could not be written'; }
[ -z "$KR" ] || echo "ratified-kept $KR — the spec and the plan are as ratified then; $({ cat .vid/tw/to-place 2>/dev/null || :; } | grep -c . || :) rows to place stay accepted: nothing asked"
prog on 'Recording your approval'
[ -n "$WD$KR" ] || { PST='your yes to the plan'; ref "the page is written (.vid/plan/PLAN-PAGE.md, .vid/pages/PLAN-PAGE.html): show it to the owner, then run this again with their yes, --words \"<their words>\"$([ -z "$SWA" ] || echo "; $WA is refused until the plan is ratified again in auto, in the owner's words")"; }
[ -n "$KR" ] || pl ratify --words "$WD" > "$W/ra" 2>&1 || { sed 's/^/    /' "$W/ra" >&2; ref 'the ratification was refused (the lines above)'; }

# 9. the mode, last; GM-4 F4 (I3, D6): GitHub manual's owner-questions: all written, the switch to auto's taking it out
oq() { { grep -v '^owner-questions:' .vid/tw/settings 2>/dev/null || :; [ "$1" = off ] || echo 'owner-questions: all'; } > "$W/oq"; cmp -s "$W/oq" .vid/tw/settings || put .vid/tw/settings < "$W/oq"; }
if [ -n "$SWA" ]; then pl setup github-mode auto --words "$WD" > "$W/su" 2>&1 || { sed 's/^/    /' "$W/su" >&2; ref 'github-mode auto could not be recorded'; }
  ev "mode name=auto from=manual words=\"$(printf %s "$WD" | tr '"' "'")\""
  # GM-4 proof D5: the owner's go in the ratification's own words, as a landing in GitHub auto records it, so the writer's gate opens
  ev "publish-approved words=\"$WD\""
  oq off || ref ".vid/tw/settings could not be written (owner-questions)"; rm -f .vid/tw/applied || ref '.vid/tw/applied could not be removed'
  # GM-4 F4: what the last /vid next raised (its moves and triggers) is GitHub manual's call's alone, so no open Q line keeps it in auto
  rm -f .vid/decide/queue/raised || ref '.vid/decide/queue/raised could not be removed'
  echo 'mode: GitHub auto, recorded'
elif [ "$TG" = auto ]; then ev "mode-retake words=\"$(printf %s "$WD" | tr '"' "'")\"${KR:+ ratified-kept=$KR}"; [ -n "$KR" ] || ev "publish-approved words=\"$WD\""; echo 'mode: GitHub auto, re-taken'   # GM-4 proof D5: the take-stock ratified again
elif [ -z "$RT" ]; then pl setup github-mode manual --words "$WD" > "$W/su" 2>&1 || { sed 's/^/    /' "$W/su" >&2; ref 'github-mode manual could not be recorded'; }
  oq all || ref ".vid/tw/settings could not be written (owner-questions)"
  ev "mode name=manual from=$FROM words=\"$(printf %s "$WD" | tr '"' "'")\""; echo 'mode: GitHub manual, recorded'
else oq all || ref ".vid/tw/settings could not be written (owner-questions)"; ev "mode-retake words=\"$(printf %s "$WD" | tr '"' "'")\"${KR:+ ratified-kept=$KR}"; echo 'mode: GitHub manual, re-taken'; fi
# FB-3 E2: the engines asked, in GitHub manual, while none is named; it ends nothing
[ "$TG" = auto ] || ! engnone || echo "$ENGASK"
# FB-3 A3: the text telling the team what its reports hold, written for the owner to hand over, with what differs from the one handed
# FB-5 B1.7: none while the owner has put the team's own rules on record (team-rules)
if [ "$TG" != auto ] && [ -z "$(skey team-rules)" ]; then F=.vid/plan/TEAM-REPORTS.md; w=new; [ ! -f "$F" ] || { w=unchanged; sh "$HERE/results.sh" team 2> /dev/null | cmp -s - "$F" || w=changed; }
  if sh "$HERE/results.sh" team --hand > /dev/null 2> "$W/tr"; then echo "team-reports $F $w"; else sed 's/^/    /' "$W/tr" >&2; echo "ViD mode: the text for the team could not be written; /vid:vid-accept-step reports writes it" >&2; fi; fi
done_ 0

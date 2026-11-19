#!/bin/sh
# Purpose: /vid mode's steps (GitHub manual, GM-1 S2; GM M2, M3, M15): the switch to GitHub manual, and, run in GitHub manual,
# the re-take of stock. It writes ViD's own records alone, in the project's folder and in state-repo: (the lock and the saved
# records); it posts nothing to the code repository or the spec repository. Every call it makes is marked as /vid mode's
# (VID_CALLER=mode), so the planner and the GitHub adapter read under GitHub manual's rules before the mode is recorded.
#   manual --register <file> --plan <file> --plan-md <file> [--applied <commit>] [--devagent "<words>"] [--to-place "<words>"]
#          [--review <file>] [--words "<words>"]
#     --register  one line per published step ticket, `<issue number> <step id>` (`#` lines and blank lines skipped)
#     --plan      the plan block in main's plan grammar (its ```vid-plan fences optional), written into RUN-STATE's ## The plan
#     --plan-md   the project's PLAN.md, written in place and committed alone when it changed
#     --applied   the commit of the spec the published tickets were written from (.vid/tw/applied); on a re-take only when it moves
#     --devagent  the owner's words that DevAgent is stopped, needed coming from GitHub auto alone
#     --to-place  the owner's words accepting the rows to place: the check's `place` flags, in no step or in another stage's step
#     --review    the fresh-agent review of the rows ViD added (planner.sh review --in), recorded when no review has this hash
#     --words     the owner's yes to the ratification; without it the call stops, refused, once the page is written
#     --refresh-yes  the owner's yes to the local edits the refresh of checks/ lists (connect.sh start --yes)
#   In order: (1) the run state, made when missing, `run: waiting`; (2) the setup keys not answered, each an `ask <key>` line,
#   exit 3, then state-setup; (3) vid-connect's start (connect.sh start: the refresh, the records restored, the lock taken, github.sh
#   access; the refresh waiting on the owner exit 4, a line not ready a refusal); (4) the
#   applied version; (5) the register's tickets: one the record lacks taken over at its newest writing (github.sh
#   ticket-writing), its `published … taken-over=` line written from its header; one the record holds kept, or, on a re-take,
#   brought to a newer writing (`amended … taken-over=`); a recorded ticket the register lacks listed and kept; (6) each row a
#   ticket taken over here quotes that differs at the applied commit (next.sh differ), listed; (7) the planning sitting: `stage
#   name=plan state=start`, the block and PLAN.md written, the plan change recorded when the block is not the newest recorded
#   plan (create, trigger initial, with none recorded; else other, trigger scope-change, evidence commit:<HEAD>), the review
#   recorded, the page; (8) the `place` flags recorded in .vid/tw/to-place in the --to-place words, any other flag a refusal,
#   then planner.sh ratify in the --words; (9) on a switch, github-mode manual through planner.sh setup and the `mode
#   name=manual from=<auto|team|none> words=` event; the sitting ended. On every path the records are saved and the lock freed
#   once taken. A refused switch changes no mode; the next call goes on from what it wrote.
# Prints one line per thing recorded: taken-over <n> <step> <body|comments>, from-body <n>, not-taken-over <n> <why>, newer <n>
#   <hash>, kept <n> not in the register, register <n> <its step> writing <its step>, differs <n> <row>, to-place <row> <kind>;
#   then `mode: GitHub manual, recorded` or `mode: GitHub manual, re-taken`. Exit 0; 1 refused; 2 usage; 3 setup keys to ask; 4 the
#   refresh waits for the owner's yes.
# Usage: sh checks/mode.sh manual --register <file> --plan <file> --plan-md <file> [--applied <commit>] [--devagent "<words>"] [--to-place "<words>"] [--review <file>] [--words "<words>"] [--refresh-yes]
# serves: tickets
set -u
IFS='
'
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
VID_CALLER=mode; export VID_CALLER
W=$(mktemp -d); LK=''; SIT=''
usage() { sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2; }
gh_() { sh "$HERE/github.sh" "$@"; }; pl() { sh "$HERE/planner.sh" "$@"; }
# done_ <rc>: the end of every path once the lock is taken: the sitting ended, the records saved, the lock freed
done_() { rc=$1; trap - EXIT INT TERM
  [ "$rc" = 0 ] || [ ! -f "$W/tp0" ] || put .vid/tw/to-place < "$W/tp0"
  [ -z "$SIT" ] || ev "stage name=plan state=end session=$SN"
  if [ -n "$LK" ]; then
    sh "$HERE/connect.sh" end > "$W/lf" 2>&1 || { sed 's/^/    /' "$W/lf" >&2; echo 'ViD mode: the records could not be saved or the lock freed (the lines above)' >&2; [ "$rc" != 0 ] || rc=1; }
  # stopped while connect.sh held a lock it had taken for this call (its lock-session written since), that lock is freed
  elif [ -n "${LS0+x}" ] && [ "$(cat .vid/lock-session 2>/dev/null || true)" != "$LS0" ] && [ -s .vid/lock-session ]; then sh "$HERE/github.sh" lock-free > /dev/null 2>&1 || :; fi
  rm -rf "$W"; exit "$rc"; }
ref() { echo "ViD mode: refused — $*" >&2; done_ 1; }
trap 'done_ 1' INT TERM; trap 'done_ $?' EXIT
[ "${1:-}" = manual ] || usage; shift
RG=''; PB=''; PM=''; AP=''; DW=''; TW=''; RV=''; WD=''; RY=''
while [ $# -ge 1 ]; do [ "$1" != --refresh-yes ] || { RY=--yes; shift; continue; }; [ $# -ge 2 ] || usage; case $1 in --register) RG=$2 ;; --plan) PB=$2 ;; --plan-md) PM=$2 ;; --applied) AP=$2 ;; --devagent) DW=$2 ;; --to-place) TW=$2 ;; --review) RV=$2 ;; --words) WD=$2 ;; *) usage ;; esac; shift 2; done
[ $# -eq 0 ] && [ -f "$RG" ] && [ -f "$PB" ] && [ -f "$PM" ] || usage; [ -z "$RV" ] || [ -f "$RV" ] || usage
for w in "$DW" "$TW" "$WD"; do case "$w" in *'
'*) ref "the owner's words are recorded on one line; these span several" ;; esac; done
FROM=$(ghmode); RT=''; [ "$FROM" != manual ] || RT=1
SN=${CLAUDE_CODE_SESSION_ID:-mode-$$-$(date +%s)}

# 1. the run state
if [ ! -f .vid/RUN-STATE.md ]; then mkdir -p .vid; printf 'mode: tickets\nplan: required\nrun: waiting\n\n## The plan\n\n```vid-plan\n```\n' > .vid/RUN-STATE.md
else grep -q '^mode:[[:space:]]*tickets[[:space:]]*$' .vid/RUN-STATE.md || ref "RUN-STATE does not say mode: tickets: this project is not planned for tickets, and GitHub manual is a ticket mode (/vid plan first)"
  rs_edit awk 'BEGIN { d = 0 } /^run:/ && !d { print "run: waiting"; d = 1; next } { print } END { if (!d) print "run: waiting" }' || ref 'RUN-STATE.md could not be written'; fi

# 2. the setup
: > "$W/ask"; for k in layout team split repo spec-repo slack-channels state-repo; do [ "$k:$(skey layout)" != spec-repo:one ] || continue
  grep -q "^setup-answered key=$k " .vid/plan/setup 2>/dev/null || echo "ask $k" >> "$W/ask"; done
if [ -s "$W/ask" ]; then cat "$W/ask"; echo "ViD mode: the setup keys above have no answer of the owner's: ask each, record it (sh checks/planner.sh setup <key> <answer> --words \"<their words>\"), then run this again" >&2; trap - EXIT; rm -rf "$W"; exit 3; fi
[ "$FROM" != auto ] || [ -n "$DW" ] || ref "a switch from GitHub auto needs the owner's words that DevAgent is stopped (--devagent \"<their words>\")"
gh_ state-setup > "$W/ss" 2>&1 || { sed 's/^/    /' "$W/ss" >&2; ref 'the state repository is not ready'; }

# 3. vid-connect's start (connect.sh): the refresh, the records restored, the lock and GitHub's access check
LS0=$(cat .vid/lock-session 2>/dev/null || true); rc=0; sh "$HERE/connect.sh" start $RY > "$W/cn" 2>&1 || rc=$?
case $rc in 0) LK=1; cat "$W/cn" ;; 3) cat "$W/cn"; echo "ViD mode: the refresh of checks/ waits for the owner: on a yes run this again with --refresh-yes; on a no, sh checks/connect.sh refresh-no \"<their words>\"" >&2; trap - EXIT; rm -rf "$W"; exit 4 ;;
  *) sed 's/^/    /' "$W/cn" >&2; ref 'the connection is not ready (the lines above); no lock is held' ;; esac
[ -z "$DW" ] || [ "$FROM" != auto ] || ev "mode-devagent words=\"$(printf %s "$DW" | tr '"' "'")\""

# 4. the applied version
if [ -n "$AP" ]; then C=$(git rev-parse -q --verify "$AP^{commit}" 2>/dev/null) || ref "--applied $AP names no commit"; echo "$C" > "$W/ap"; put .vid/tw/applied < "$W/ap" || ref '.vid/tw/applied could not be written'
elif [ -z "$(applied)" ]; then ref "no applied version is recorded: --applied <the commit the published tickets were written from>"; fi
AC=$(applied)

# 5. the tickets
mkdir -p .vid/tw/out; touch .vid/tw/log; : > "$W/new"
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
  if grep -q "^published $n " .vid/tw/log; then
    [ -n "$RT" ] || continue
    gh_ ticket-writing "$n" "$W/tw" > "$W/wl" 2> "$W/we" || { sed 's/^/    /' "$W/we" >&2; ref "#$n could not be read"; }
    set -- $(tr ' ' '\n' < "$W/wl"); [ "$1" = writing ] || continue; h=$3
    [ "$h" = "$(whash "$n")" ] || { take "$n" "$W/tw" "$h" "$4" "$5" amended; echo "newer $n $h"; }; continue; fi
  gh_ ticket-writing "$n" "$W/tw" > "$W/wl" 2> "$W/we" || { sed 's/^/    /' "$W/we" >&2; ref "#$n could not be read"; }
  set -- $(tr ' ' '\n' < "$W/wl"); if [ "$1" != writing ]; then echo "not-taken-over $n $(cut -d' ' -f3- "$W/wl")"; continue; fi
  take "$n" "$W/tw" "$3" "$4" "$5" published; echo "taken-over $n $SH $4"; [ "$SH" = "$s" ] || echo "register $n $s writing $SH"
done < "$W/rg"
awk '$1 == "published" { print $2 }' .vid/tw/log | sort -un | while read -r n; do grep -q "^withdrawn $n " .vid/tw/log && continue; awk -v n="$n" '$1 == n { f = 1 } END { exit !f }' "$W/rg" || echo "kept $n not in the register"; done

# 6. the rows each ticket taken over here quotes, at the applied commit
for n in $(cat "$W/new"); do sh "$HERE/next.sh" differ "$n" "$AC" > "$W/df" 2> "$W/de" || { sed 's/^/    /' "$W/de" >&2; ref "the rows of #$n could not be read at the applied commit"; }
  awk '$1 == "differ" { print "differs " $2 " " $3 }' "$W/df"; done

# 7. the plan, in a planning sitting
ev "stage name=plan state=start session=$SN records=29"; SIT=1
if grep -q '^```vid-plan' "$PB"; then awk '/^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' "$PB"; else cat "$PB"; fi > "$W/blk"
rs_edit awk -v B="$W/blk" 'function blk(  l) { print "```vid-plan"; while ((getline l < B) > 0) print l; print "```" }
  /^## The plan/ { print; s = 1; d = 1; next } s && /^## / { if (!w) { print ""; blk(); print "" } s = 0; w = 1 }
  s && /^```vid-plan[ \t]*$/ { if (!w) blk(); w = 1; b = 1; next } b { if (/^```[ \t]*$/) b = 0; next } { print }
  END { if (s && !w) { print ""; blk() } if (!d) { print ""; print "## The plan"; print ""; blk() } }' || ref "RUN-STATE's plan could not be written"
if [ ! -f PLAN.md ] || ! cmp -s "$PM" PLAN.md; then cp "$PM" PLAN.md || ref 'PLAN.md could not be written'; fi
if ! git diff --quiet HEAD -- PLAN.md 2>/dev/null || ! git cat-file -e HEAD:PLAN.md 2>/dev/null; then
  git add PLAN.md && git commit -q -m 'PLAN.md: the plan of the published tickets, taken over by /vid mode manual' -m 'REQs: none
Decisions: none — the project'"'"'s PLAN.md as the owner brought it to /vid mode manual (checks/mode.sh)
Seams: none' -- PLAN.md > "$W/cm" 2>&1 || { sed 's/^/    /' "$W/cm" >&2; ref 'PLAN.md could not be committed'; }; fi
EXP="the register's $(grep -c . "$W/rg" | tr -d ' ') tickets, each ticket's rows in its step"
R=$(grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p')
if [ -z "$R" ]; then sh "$HERE/plan.sh" change create 'the take-over of the published tickets' --trigger initial --expect "$EXP" > "$W/pc" 2>&1 || { sed 's/^/    /' "$W/pc" >&2; ref 'the plan change was refused'; }
elif [ ! -f ".vid/plans/$R.plan" ] || [ "$(plan_block | sh "$HERE/plan.sh" canon)" != "$(sh "$HERE/plan.sh" canon < ".vid/plans/$R.plan")" ]; then
  if [ -n "$RT" ]; then WY='the re-take'; else WY='the take-over of the published tickets'; fi
  sh "$HERE/plan.sh" change other "$WY" --trigger scope-change --evidence "commit:$(git rev-parse HEAD)" --expect "$EXP" > "$W/pc" 2>&1 || { sed 's/^/    /' "$W/pc" >&2; ref 'the plan change was refused'; }; fi
H=$(pl hash) || ref 'the spec could not be read at the applied commit'
# with no row ViD added there is nothing to review, and the review that ratify needs says so
if [ -z "$RV" ] && [ -z "$(pl rows --added)" ]; then printf 'none\n' > "$W/rv0"; RV=$W/rv0; fi
if [ -n "$RV" ] && ! grep -qs "^review [0-9]* hash=$H " .vid/plan/review; then pl review --in "$RV" > "$W/rv" 2>&1 || { sed 's/^/    /' "$W/rv" >&2; ref 'the review was refused'; }; fi

# 8. the ratification: the list of rows to place written whole, so the check first sees every place flag
# the list as last ratified kept aside, and put back by done_ on any refusal
[ ! -f .vid/tw/to-place ] || { cp .vid/tw/to-place "$W/tp0" && : > .vid/tw/to-place; }
pl check > "$W/ck" 2>&1; grep -v '^planner: clean' "$W/ck" | grep -v '^place ' > "$W/of" || :
[ ! -s "$W/of" ] || { sed 's/^/    /' "$W/of" >&2; pl page > /dev/null 2>&1; ref "the check flags the plan beyond the rows to place (the lines above): change the plan or the spec, then run this again"; }
awk '$1 == "place" { print $2 "\t" (index($0, " — in no step") ? "no-step" : "other-stage") }' "$W/ck" > "$W/pf"
if [ -s "$W/pf" ]; then [ -n "$TW" ] || { sed 's/^/    place /' "$W/pf" >&2; pl page > /dev/null 2>&1; ref "$(grep -c . "$W/pf" | tr -d ' ') rows are to place (above): the owner's words accepting them, --to-place \"<their words>\""; }
  awk -F'\t' -v t="$(now)" -v w="$TW" -v OFS='\t' '{ print $1, $2, t, w }' "$W/pf" > "$W/tp"; put .vid/tw/to-place < "$W/tp" || ref '.vid/tw/to-place could not be written'
  awk -F'\t' '{ print "to-place " $1 " " $2 }' "$W/pf"
  pl check > "$W/ck2" 2>&1 || { sed 's/^/    /' "$W/ck2" >&2; ref 'the check still flags the plan with the rows to place recorded'; }
else : > "$W/tp"; [ ! -f .vid/tw/to-place ] || put .vid/tw/to-place < "$W/tp"; fi
pl page > "$W/pg" 2>&1 || { sed 's/^/    /' "$W/pg" >&2; ref 'the page could not be written'; }
[ -n "$WD" ] || ref "the page is written (.vid/plan/PLAN-PAGE.md, .vid/pages/PLAN-PAGE.html): show it to the owner, then run this again with their yes, --words \"<their words>\""
pl ratify --words "$WD" > "$W/ra" 2>&1 || { sed 's/^/    /' "$W/ra" >&2; ref 'the ratification was refused (the lines above)'; }

# 9. the mode, last
if [ -z "$RT" ]; then pl setup github-mode manual --words "$WD" > "$W/su" 2>&1 || { sed 's/^/    /' "$W/su" >&2; ref 'github-mode manual could not be recorded'; }
  ev "mode name=manual from=$FROM words=\"$(printf %s "$WD" | tr '"' "'")\""; echo 'mode: GitHub manual, recorded'
else ev "mode-retake words=\"$(printf %s "$WD" | tr '"' "'")\""; echo 'mode: GitHub manual, re-taken'; fi
done_ 0

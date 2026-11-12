#!/bin/sh
# Purpose: ViD's walk of a stage's candidate on staging, W1 (v0.26.10.26.4 R1). The walker, WA, uses the staged product as a user
# would, in a session of its own, from a brief that holds the golden path, the journeys and the screens in plain words, and
# nothing of fail-ifs, results, grades, findings, tickets, code or earlier walks. It reads no code and fails no row: what it
# sees reaches a row only through the owner's ruling on a finding (R2). Run at the top of ViD's repository.
#   owed                    `walk <N>` for each stage whose walk is due: the newest candidate's CS passed, W1 not done, not
#                           withdrawn, and no walk out; no start yet, or `again` answered after the newest start, or the newest
#                           return refused, the first refusal
#   pending                 `walk-read <N>` for each stage whose newest start's recorded pid is gone and its return unread
#   brief --stage <N>       the newest candidate's brief, in a fresh folder outside the project (brief.md and the canvases it
#                           names), recorded as the next start, <c>/w1/<s>/ (folder, brief.md); prints the folder
#   start --stage <N>       runs the walker (checks/walker.md, its role) as a session of its own on claude-opus-5-5, its working
#                           directory the brief's folder, its pid recorded in <c>/w1/<s>/pid; prints `started <pid>`
#   read --stage <N>        reads the newest start's walk.txt, copied into <c>/w1/<s>/: `w1 done`, `w1 not-done <why>` (an item for
#                           the owner, answered again), or `w1 refused <why>` (a missing walk.txt too; the second an item, again).
#                           A differs screen and each finding: line go to <c>/w1/findings, `<s> TAB <line>`, a line once
#   withdraw --stage <N> --below <c>   every older candidate's W1 of the stage withdrawn: due, out or not done (its walker stopped)
# 0.26.10.28.6 (R1, R-8): two more outcomes, each a record every reader of W1 takes as it takes done and withdrawn (wfin):
#   none    no screens, no walk: the design has no screens and no row of the stage is a journey, so no screen walk is owed
#           (written by owed, before any start; its line the stage summary's words)
#   limit   screens, but no browser: after a walk read `browser: none`, the owner's answer "close without the walk" (queue.sh)
#           records it as a known limit, its words and who answered when
# Records: .vid/decide/stage/<N>/<c>/w1/ (<s>/ a start; done, withdrawn, none, limit, findings, items, again). Env: VID_WALKER (the claude
# command, for the self-test), VID_WALK_TMP (where a brief's folder is made; default the system's temporary folder).
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
D=.vid/decide; SD=$D/stage; HAND=.vid/tw/handed; LOG=.vid/tw/log; TAB=$(printf '\t'); MODEL=claude-opus-5-5
die() { echo "ViD walk: $*" >&2; exit 1; }
snc() { c0=''; for d in $(ls "$SD/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$SD/$1/$d/ask" ] && c0=$d; done; echo "$c0"; }
ns() { n0=''; for d in $(ls "$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do n0=$d; done; echo "$n0"; }   # the newest start
anc() { git --git-dir=.vid/code merge-base --is-ancestor "$1" "$2" 2>/dev/null; }
alive() { [ -f "$1/pid" ] && kill -0 "$(cat "$1/pid")" 2>/dev/null && [ "$(ps -o lstart= -p "$(cat "$1/pid")" 2>/dev/null)" = "$(cat "$1/lstart" 2>/dev/null)" ]; }
allow() { grep -qxF "allow $1" "$W/again" 2>/dev/null; }
item() { grep -qxF "$1" "$W/items" 2>/dev/null || { echo "$1" >> "$W/items"; ev "close-item step=walk-$N what=$(printf %s "$1" | cut -d' ' -f1-2 | tr ' ' '-')"; echo "walk-item $N $1"; }; }
# wfin <w1 folder> (0.26.10.28.6, R1): exit 0 when W1 has an outcome: done, withdrawn, none (no screens, no journey) or limit (no browser,
# the owner's "close without the walk")
wfin() { [ -f "$1/done" ] || [ -f "$1/withdrawn" ] || [ -f "$1/none" ] || [ -f "$1/limit" ]; }
# wdue <N>: exit 0 when stage N's walk is due; sets c, F, W
wdue() { N=$1; c=$(snc "$N"); [ -n "$c" ] || return 1; F=$SD/$N/$c; W=$F/w1; [ -f "$F/cs/passed" ] || return 1; ! wfin "$W" || return 1
  s=$(ns "$W"); [ -n "$s" ] || return 0; [ -f "$W/$s/read" ] || { [ ! -s "$W/$s/pid" ]; return; }   # a brief never started, or a start that failed: due again
  case $(cut -f1 "$W/$s/read") in
    not-done) allow again ;;
    refused) [ "$(refusals)" -lt 2 ] || allow again ;;
    *) return 1 ;; esac; }
# refusals: the refused returns since the owner's newest again (`again-at <s>` in again)
refusals() { a=$(sed -n 's/^again-at //p' "$W/again" 2>/dev/null | tail -n 1); for d in $(ls "$W" | grep -E '^[0-9]+$'); do [ "$d" -gt "${a:-0}" ] && [ -f "$W/$d/read" ] && cut -f1 "$W/$d/read"; done | grep -c '^refused' || true; }
cmd_owed() { for x in $(ls "$SD" 2>/dev/null | sort -n); do wnone "$x" || true; ! wdue "$x" || echo "walk $x"; done; return 0; }
cmd_pending() { for F0 in $(ls -d "$SD"/*/* 2>/dev/null); do wfin "$F0/w1" || continue; csclose "$F0"; done   # v0.26.10.27.3 (8.1b R4): a failed close tried again
  for x in $(ls "$SD" 2>/dev/null | sort -n); do c=$(snc "$x"); [ -n "$c" ] || continue; W=$SD/$x/$c/w1; [ ! -f "$W/withdrawn" ] || continue
    s=$(ns "$W"); [ -n "$s" ] && [ -f "$W/$s/pid" ] && [ ! -f "$W/$s/read" ] || continue; alive "$W/$s" || echo "walk-read $x"; done; return 0; }
# --- the brief's scope (R1) ---
SX=$(mktemp -d "$PWD/.vid/round/walk.XXXXXX" 2>/dev/null || mktemp -d); trap 'rm -rf "$SX"' EXIT
plr() { [ -f "$SX/plr" ] || { sh "$HERE/planner.sh" rows 2>/dev/null || true; } | grep -v '^#' > "$SX/plr"; }
# inv: `<id> TAB <kind> TAB <screen state or n/a> TAB <promise>` for each row of INVENTORY.md's block
inv() { [ -f "$SX/inv" ] || sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' 'function t(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x } t($1) ~ /^[A-Z]+-[0-9]+$/ { print t($1) "\t" t($2) "\t" t($5) "\t" t($6) }' > "$SX/inv"; }
# upto <N>: the rows of stages 1 to N, as the admission's join reads them
upto() { [ -f "$SX/up$1" ] && return 0; plr; { sh "$HERE/stages.sh" scope --upto "$1" 2>/dev/null || true; } > "$SX/st0"
  awk -F'\t' -v c="$1" 'FILENAME == ARGV[1] { if ($5 ~ /^[0-9]+$/ || $5 == "later") P[$1] = ($5 != "later" && $5 + 0 <= c); next } !($1 in P) || P[$1] { print } END { for (r in P) if (P[r]) print r }' "$SX/plr" "$SX/st0" | sort -u > "$SX/up$1"; }
golden() { plan_block | awk -F' [|] ' '{ for (i = 2; i <= NF; i++) if ($i == "kind: skeleton") for (j = 2; j <= NF; j++) if ($j ~ /^rows: /) { x = $j; sub(/^rows: /, "", x); print x } }' | tr ' ' '\n' | grep . |
  awk "$RNG"' { q = split(rng($0), e, " "); for (k = 1; k <= q; k++) print e[k] }' || true; }   # a range expanded, as the plan reads it
journeys() { plr; awk -F'\t' '$2 == "row" && $7 ~ /(^| )journey( |$)/ { print $1 }' "$SX/plr"; }
screened() { inv; awk -F'\t' '$3 ~ /^[A-Z]+[0-9]*\// { print $1 }' "$SX/inv"; }   # a row that cites a screen of the design
# touched <commit>: the rows of every ticket merged since that commit
touched() { while IFS=$TAB read -r p t h m; do [ -n "$m" ] && [ "$m" != - ] || continue; anc "$m" "$1" && continue
    awk -v n="$t" '($1 == "published" || $1 == "amended") && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) r = substr($i, 6) } END { print r }' "$LOG" | tr , '\n'; done < "$D/merges" 2>/dev/null | grep . | sort -u; }
# wnone <N> (0.26.10.28.6, R1 (a)): no screens, no walk. The newest candidate's CS passed, W1 has no outcome and no start, the design
# has no screens (no canvas under design/screens/, no inventory row citing one) and no row of the stage is a journey: W1 is recorded
# `none`, its words the summary's, and the CS issue kept open for the walk closes. A screen walk is the kind not owed; another kind of
# walk, for a product with no screens, would slot in here
wnone() { N=$1; c=$(snc "$N"); [ -n "$c" ] || return 1; F=$SD/$N/$c; W=$F/w1; [ -f "$F/cs/passed" ] || return 1; ! wfin "$W" || return 1; [ -z "$(ns "$W")" ] || return 1
  for f in design/screens/*.html; do [ ! -f "$f" ] || return 1; done; [ -z "$(screened)" ] || return 1
  upto "$N"; if [ "$N" -lt 1 ]; then : > "$SX/upp"; else upto "$((N - 1))"; cp "$SX/up$((N - 1))" "$SX/upp"; fi
  ! journeys | grep -xF -f "$SX/up$N" | grep -qvxF -f "$SX/upp" || return 1
  mkdir -p "$W"; printf 'no walk: this stage has no screens and no journey\n' > "$SX/wn" || exit 1; put "$W/none" < "$SX/wn" || exit 1
  csclose "$F" > /dev/null; ev "walk-none stage=$N candidate=$c"; return 0; }
canvas() { id=${1%%/*}; for f in design/screens/*.dc.html design/screens/*.html; do [ -f "$f" ] || continue; b=$(basename "$f"); case $b in "$id "*|"$id.dc.html"|"$id.html") echo "$f"; return 0 ;; esac; done
  l=$(printf %s "$id" | sed 's/[0-9].*//'); for f in design/screens/*.dc.html; do [ -f "$f" ] || continue; case $(basename "$f") in "$l "*) echo "$f"; return 0 ;; esac; done; return 1; }
cmd_brief() { [ "${1:-}" = --stage ] && [ -n "${2:-}" ] || die 'usage — brief --stage <N>'; wdue "$2" || die "no walk is due for stage $2"
  A=$(sed -n "s/^staging$TAB//p" "$F/d1/read" | head -n 1); [ -n "$A" ] || die "stage $N's D1 names no staging address"; X=$(cat "$F/commit")
  s=$(( $(ns "$W" | grep . || echo 0) + 1 )); B=$(mktemp -d "${VID_WALK_TMP:-${TMPDIR:-/tmp}}/vid-walk.XXXXXX") || die 'no folder for the brief'; B=$(cd "$B" && pwd -P)
  case $B/ in "$(pwd -P)"/*) rmdir "$B"; die "the brief's folder would sit inside the project ($B): set VID_WALK_TMP outside it" ;; esac; mkdir -p "$W/$s"   # the walker never sits beside the records
  upto "$N"; golden > "$SX/g"; journeys > "$SX/j"; screened > "$SX/sc"; inv
  # the last W1 done of the stage, an earlier candidate's
  L=''; for o in $(ls "$SD/$N" | grep -E '^[0-9]+$' | sort -n); do [ "$o" -lt "$c" ] && [ -f "$SD/$N/$o/w1/done" ] && L=$o; done
  if [ -n "$L" ]; then touched "$(cat "$SD/$N/$L/commit")" | grep -xF -f "$SX/up$N" > "$SX/t" || true; cat "$SX/j" "$SX/sc" | sort -u | grep -xF -f "$SX/t" > "$SX/scope" || true
  else
    [ "$N" -lt 1 ] && : > "$SX/upp" || { upto "$((N - 1))"; cp "$SX/up$((N - 1))" "$SX/upp"; }
    grep -xF -f "$SX/up$N" "$SX/j" | grep -vxF -f "$SX/upp" > "$SX/scope" || true   # the stage's journeys
    grep -xF -f "$SX/up$N" "$SX/sc" >> "$SX/scope" || true                         # the rows of stages up to N that cite a screen
    if [ "$c" -gt 1 ]; then touched "$(cat "$SD/$N/1/commit")" | grep -xF -f "$SX/upp" > "$SX/t" || true; cat "$SX/j" "$SX/sc" | sort -u | grep -xF -f "$SX/t" >> "$SX/scope" || true; fi
  fi
  grep -vxF -f "$SX/g" "$SX/scope" | sort -u > "$SX/rs" || true
  promise() { awk -F'\t' -v r="$1" '$1 == r { p = $8; if (p ~ /^[ \t]*(never|fail-if|fails if)[: ]/ || tolower(p) ~ /fails? if /) p = "(walk it as a user would, by its screen)"; print p; exit }' "$SX/plr"; }   # the planner's promise; a clause in fail-if form is kept from the walker
  { printf '# The walk\n\ncandidate: %s\nstaging: %s\n' "$X" "$A"; awk -F'\t' '$1 == "signin" { print "signin: " $2 " " $3 }' "$F/d1/read"
    printf '\nUse the product at the address above as a user would, signed in through the lines above. Walk each item below, then wander. Write walk.txt in this folder, in the form your instructions give, one line for each item here.\n\n## The golden path\n\n'
    while read -r r; do printf -- '- %s: %s\n' "$r" "$(promise "$r")"; done < "$SX/g"
    [ ! -s "$SX/rs" ] || { printf '\n## The rows\n\n'; while read -r r; do printf -- '- %s: %s\n' "$r" "$(promise "$r")"; done < "$SX/rs"; }
    cat "$SX/g" "$SX/rs" | grep -xF -f "$SX/sc" | while read -r r; do awk -F'\t' -v r="$r" '$1 == r { print $3 }' "$SX/inv"; done | sort -u > "$SX/scr"
    while read -r v; do f=$(canvas "$v") || continue; cp "$f" "$B/" 2>/dev/null || continue; printf -- '- screen %s: the canvas %s\n' "$v" "$(basename "$f")"; done < "$SX/scr" > "$SX/scl"
    [ ! -s "$SX/scl" ] || { printf '\n## The screens\n\nEach beside its canvas, in this folder: matches, or differs and how.\n\n'; cat "$SX/scl"; }   # none with no canvas
    printf '\n## The wander\n\nUse the product as a user would: unusual inputs, interrupted flows, the same thing done twice.\n'; } > "$B/brief.md"
  cp "$B/brief.md" "$W/$s/brief.md"; echo "$B" > "$W/$s/folder"; if allow again; then grep -vxF 'allow again' "$W/again" > "$SX/ag" 2>/dev/null || true; echo "again-at $((s - 1))" >> "$SX/ag" || exit 1; put "$W/again" < "$SX/ag" || exit 1; fi
  ev "walk-brief stage=$N candidate=$c start=$s"; echo "$B"; }
cmd_start() { [ "${1:-}" = --stage ] && [ -n "${2:-}" ] || die 'usage — start --stage <N>'; N=$2; c=$(snc "$N"); W=$SD/$N/$c/w1; s=$(ns "$W"); [ -n "$s" ] && [ -f "$W/$s/folder" ] || die "no brief for stage $N's walk"
  [ ! -f "$W/$s/pid" ] || die "the walk $s of stage $N is started already"; B=$(cat "$W/$s/folder"); [ -f "$B/brief.md" ] || die "no brief at $B"
  WK=${VID_WALKER:-claude}; R=$(cat "$HERE/walker.md" 2>/dev/null) || die 'no checks/walker.md'; [ -n "$R" ] || die 'no checks/walker.md'
  WA=$PWD/$W/$s; set -m; ( cd "$B" || exit 1; exec nohup sh -c 'echo $$ > "$1/pid"; ps -o lstart= -p $$ > "$1/lstart"; shift; exec "$@"' sh "$WA" "$WK" -p 'Read brief.md in this folder whole, and walk as your instructions and the brief say; write walk.txt here.' \
      --model "$MODEL" --append-system-prompt "$R" --tools Bash Read Write --allowedTools Bash Read Write --settings '{"enabledPlugins":{"vid@vid":false}}' --output-format stream-json --verbose ) > "$W/$s/log" 2> "$W/$s/err" < /dev/null &
  set +m; n=0; while [ ! -s "$W/$s/pid" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; [ -s "$W/$s/pid" ] || die 'the walker did not start'
  ev "walk-start stage=$N candidate=$c start=$s"; echo "started $(cat "$W/$s/pid")"; }
cmd_read() { [ "${1:-}" = --stage ] && [ -n "${2:-}" ] || die 'usage — read --stage <N>'; N=$2; c=$(snc "$N"); F=$SD/$N/$c; W=$F/w1; s=$(ns "$W"); [ -n "$s" ] || die "no walk of stage $N"
  [ ! -f "$W/withdrawn" ] || { echo "w1 withdrawn"; return 0; }; [ ! -f "$W/limit" ] || { echo "w1 limit"; return 0; }; [ ! -f "$W/$s/read" ] || { cat "$W/$s/read"; return 0; }; ! alive "$W/$s" || die "the walker of stage $N still runs"
  B=$(cat "$W/$s/folder"); touch "$W/items" "$W/again" "$W/findings"; X=$(cat "$F/commit")
  if [ -f "$B/walk.txt" ]; then put "$W/$s/walk.txt" < "$B/walk.txt" || exit 1; why=$(awk -v X="$X" -v BR="$W/$s/brief.md" 'BEGIN { while ((getline l < BR) > 0) { if (l ~ /^## The golden path/) sec = "g"; else if (l ~ /^## The rows/) sec = "r"; else if (l ~ /^## The screens/) sec = "s"
          if (l ~ /^- / && sec == "r") { x = substr(l, 3); sub(/:.*/, "", x); need[x] = 1; nn++ } else if (l ~ /^- screen / && sec == "s") { x = substr(l, 10); sub(/:.*/, "", x); need["screen " x] = 1; nn++ } }
          need["golden path"] = 1; need["wander"] = 1 }
        NR == 1 && $0 != "by: WA" { bad = "the first line is not by: WA" } /^candidate:/ { cd = $2 } /^browser:[ \t]*[^ \t]/ { br = 1 }
        /^finding: (bug|rule) — / { next } /^(by|candidate|browser):/ { next } /^[ \t]*$/ { next }
        { k = $0; sub(/:.*/, "", k); if (k in need) { got[k] = 1; v = $0; sub(/^[^:]*:[ \t]*/, "", v); if (k ~ /^screen / ? v !~ /^(matches|differs — .+|not done( — .+)?)$/ : v !~ /^(done|not done( — .+)?)$/) bad = bad (bad == "" ? "" : "; ") k (k ~ /^screen / ? " reads neither matches, differs nor not done" : " reads neither done nor not done") } }
        END { if (cd != X) bad = bad (bad == "" ? "" : "; ") "the candidate is not " X; if (!br) bad = bad (bad == "" ? "" : "; ") "no browser: line naming what drove it, or none"
          for (k in need) if (!(k in got)) bad = bad (bad == "" ? "" : "; ") "no line for " k; print bad }' "$W/$s/walk.txt")
  else why='no walk.txt'; fi
  if [ -n "$why" ]; then printf 'refused\t%s\n' "$why" > "$W/$s/read"; ev "walk-read stage=$N start=$s result=refused"
    [ "$(refusals)" -lt 2 ] || item "refused walk twice: $why #$s"; echo "w1 refused $why"; return 0; fi
  # the findings: a differs screen and each finding: line, keyed by the line, once
  { grep '^screen [^:]*: differs — ' "$W/$s/walk.txt" | sed 's/^/W1 /'; sed -n 's/^\(finding: .*\)/W1 \1/p' "$W/$s/walk.txt"; } | while IFS= read -r l; do cut -f2- "$W/findings" | grep -qxF "$l" || printf '%s\t%s\n' "$s" "$l" >> "$W/findings"; done
  nd=$(awk '/^browser:[ \t]*none[ \t]*$/ { print "browser: none"; exit } /^[^:]+:[ \t]*not done/ { x = $0; sub(/^[^:]+:[ \t]*not done[ \t]*(— )?/, "", x); print (x == "" ? "not done" : x); exit }' "$W/$s/walk.txt")
  if [ -n "$nd" ]; then printf 'not-done\t%s\n' "$nd" > "$W/$s/read"; item "not done — $nd #$s"; ev "walk-read stage=$N start=$s result=not-done"; echo "w1 not-done $nd"; return 0; fi
  printf 'done\n' > "$W/$s/read"; : > "$W/done"; csclose "$F"; ev "walk-read stage=$N start=$s result=done"; echo "w1 done"; }
# csclose <candidate folder> (v0.26.10.27.3, 8.1b R4): its green CS's issue, kept open for the walk, closed once W1 has an outcome (wfin)
csclose() { [ -f "$1/cs/passed" ] && [ -f "$1/cs/ask" ] && [ ! -f "$1/cs/issue-closed" ] || return 0; j0=$(sed -n "s/^issue$(printf '\t')//p" "$1/cs/ask" | head -n 1); [ -n "$j0" ] || return 0
  sh "$HERE/github.sh" close "$j0" > /dev/null 2>&1 && : > "$1/cs/issue-closed" && echo "cs-closed #$j0"; return 0; }
cmd_withdraw() { [ "${1:-}" = --stage ] && [ "${3:-}" = --below ] || die 'usage — withdraw --stage <N> --below <c>'; N=$2
  for o in $(ls "$SD/$N" 2>/dev/null | grep -E '^[0-9]+$'); do [ "$o" -lt "$4" ] || continue; W=$SD/$N/$o/w1; [ -f "$SD/$N/$o/cs/passed" ] || [ -d "$W" ] || continue
    ! wfin "$W" || continue; mkdir -p "$W"; s=$(ns "$W"); [ -z "$s" ] || ! alive "$W/$s" || kill -s TERM -- "-$(cat "$W/$s/pid")" 2>/dev/null || kill "$(cat "$W/$s/pid")" 2>/dev/null || true
    : > "$W/withdrawn"; : > "$W/items"; csclose "$SD/$N/$o"; ev "walk-withdrawn stage=$N candidate=$o"; echo "walk-withdrawn $N $o"; done; return 0; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in owed) cmd_owed ;; pending) cmd_pending ;; brief) cmd_brief "$@" ;; start) cmd_start "$@" ;; read) cmd_read "$@" ;; withdraw) cmd_withdraw "$@" ;;
  due) wdue "${1:?}" ;;
  fin) c=$(snc "${1:?}"); [ -n "$c" ] && wfin "$SD/$1/$c/w1" ;;
  *) echo 'usage: sh checks/walk.sh owed|pending|brief --stage <N>|start --stage <N>|read --stage <N>|withdraw --stage <N> --below <c>|due <N>|fin <N>' >&2; exit 2 ;; esac

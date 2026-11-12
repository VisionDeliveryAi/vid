#!/bin/sh
# Usage: devagent/README.md says how a person starts the flow.
# Purpose: DevAgent's dev manager script (v0.26.10.24.7 R2, R3). It reads the state and judges nothing; the judging is a fresh
# agent's, devagent/agents/dev-manager.md. All state is on the repository and in the work folder, so any fresh one picks up where the last stopped.
#   dm.sh loop <job note>   one a minute it runs `next`, with no agent; when a line calls for work and no dev manager runs it starts a fresh
#                           one. It stops on the work folder's dm-stop file, at the note's time limit, or when two passes running end with the
#                           line they began with and the records unmoved, saying so in dm-report.txt. With nothing to do or to wait for for 10
#                           minutes it stays, and reads `next` every 5 minutes (v0.26.10.28.6, R3). Every stop is said where ViD reads it: a
#                           stopped report on vid-results/stopped-<k>, and `vid: stopped <why>` on each open issue it holds work for
#   dm.sh check <job note>  what the dev side needs (v0.26.10.28.3 R2), with no model turn: a line for each thing missing, then `ready`, or `<n> missing` and exit 1
#   dm.sh up <job note>     check, then the loop detached: nohup, its own process group, its output in the work folder's dm-loop.log, its pid and start
#                           stamp in dm-loop.pid; refused while that loop lives; a dm-stop left from before is removed; it returns at once
#   dm.sh down [<job note>] writes dm-stop, which the loop obeys at its next tick, and waits at most 120 seconds for the recorded loop to end; it stops nothing else
#   dm.sh next              one line a ticket, close run (an issue labelled <prefix>run), stage grade (<prefix>grade, v0.26.10.26.1 R7) or deploy okay (<prefix>deploy: staging, v0.26.10.26.2 R8; rehearsal or production, v0.26.10.27.1 R8), lowest first: blocked, left, claim, work, not-yet, merge or wait, then its number; `none` when no line
#   dm.sh start <role> <job note> <clone>   a fresh claude -p on the role's file and a kept copy of the note, nothing else; prints the agent's id
#   dm.sh wait <id>         at most 200 seconds: `running` (75), `quiet` (4), `ended: no hand-back` (3), or the final message (0)
#   dm.sh take <id>         prints the hand-back and marks it taken
#   dm.sh stop <id>         stops that agent, by its recorded pid
#   dm.sh list              whether the loop lives (its pid and minutes) and each live dev manager (0.26.10.28.8, R5), then what is alive,
#                           each ended agent whose hand-back nobody has taken, each live run; `none` when nothing of those
#   dm.sh used              the loop's seconds, of its time limit, and the agents' seconds and turns so far (v0.26.10.28.3 R3)
#   dm.sh follow [<mark>]   (0.26.10.28.8 R12) read only, in the work folder: the passes that ended and the loop's stops since the mark, as they
#                           come, at most 540 seconds a call; with no mark, the mark now. /vid:vid-devagent shows them in a conversation
# The job note's head, `key: value`: repo: (owner/name), labels-prefix:, work: (the work folder, where this copies it, dm-note.txt), time-limit: (the
# loop's seconds), agent-time-limit: (one agent's seconds: past them the loop's tick or `wait` stops it by its pid), agent-turn-limit: (one agent's turns,
# its --max-turns), model: (every agent's, MODEL0 below when it has none, v0.26.10.28.3 R4). The dollar keys before 0.26.10.28.3 are refused by check, up, loop
# and start. dm.sh finds the work folder by DM_WORK, or as the current folder. A job note's `ticket: <n>` line names an agent's ticket. agents/<id>/ keeps its
# note, log, hand-back, pid and start. agents.txt: role, ticket, model, seconds, turns, tab between, a line an ended agent, and `time-limit` after them for one stopped at its time limit.
# Shorter times, for the self-test: DM_TICK 60, DM_IDLE 600, DM_IDLE_TICK 300, DM_QUIET 1200, DM_WAIT 200, DM_FIRST 30, DM_DOWN 120. DM_AGENT_CLAUDE: a stand-in for claude, for every role but the dev manager.
# serves: dev side (0.26.10.28.4, M9)
set -eu
die() { echo "dm.sh: $*" >&2; exit 1; }
CMD=${1:-}; [ $# -eq 0 ] || shift
HERE=$(cd "$(dirname "$0")" && pwd -P); ROOT=$(dirname "$(dirname "$HERE")"); TAB=$(printf '\t')
MODEL0=claude-opus-5-5   # the dev side's one model name, for a job note with no model: (R4)
W=${DM_WORK:-$PWD}; N=$W/dm-note.txt
# invid <folder>: the nearest folder at or above it that holds .vid, ViD's records; nothing when none
invid() { d=$1; while :; do [ ! -e "$d/.vid" ] || { echo "$d"; return 0; }; [ "$d" != / ] || return 0; d=$(dirname "$d"); done; }
# oldkeys <note>: the dollar keys of before 0.26.10.28.3 (R3), refused, the new keys named; the pattern's brackets keep their names out of a search of devagent/
oldkeys() { o=$(grep -E '^(spend-limi[t]|agent-budge[t]):' "$1" 2>/dev/null | sed 's/:.*/:/' | paste -sd ' ' -); [ -z "$o" ] || { echo "the job note holds $o, read no longer: give time-limit: (the loop's seconds), agent-time-limit: (one agent's seconds) and agent-turn-limit: (one agent's turns) in its place"; return 1; }; }
workof() { sed -n 's/^work: *//p' "$1" | head -n 1; }
case $CMD in loop|down) if [ "$CMD" = loop ] || [ -n "${1:-}" ]; then [ -f "${1:-}" ] || die "usage: dm.sh $CMD <job note>"; W=$(workof "$1"); [ -d "$W" ] || die "no work folder '$W'"; W=$(cd "$W" && pwd -P); N=$W/dm-note.txt; fi ;; esac
if [ "$CMD" = loop ]; then v=$(invid "$W"); [ -z "$v" ] || die "the work folder is in $v, a folder of ViD's records"; m=$(oldkeys "$1") || die "$m"
  [ "$1" -ef "$N" ] || cp "$1" "$N"; DM_WORK=$W; export DM_WORK; fi
key() { sed -n "s/^$1: *//p" "$N" 2>/dev/null | head -n 1; }
mdl() { m=$(key model | sed 's/[[:space:]]*$//'); echo "${m:-$MODEL0}"; }   # the job note's model:, else the default (R4)
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
# alive <agent folder>: its pid lives and is the process that start recorded, never another that took the number
alive() { p=$(cat "$1/pid" 2>/dev/null) || return 1; sh "$ROOT/devagent/test-manager/run.sh" is "$p" "$1/lstart"; }   # run.sh's stamp, the same on macOS, Linux, WSL and Git Bash (v0.26.10.25.2.1)
agents() { ls -d "$W"/agents/*/ 2>/dev/null | sed 's|/$||' || true; }
modelof() { grep -m 1 '"subtype":"init"' "$1/log" 2>/dev/null | awk 'match($0, /"model":"[^"]*"/) { print substr($0, RSTART + 9, RLENGTH - 10) }' || true; }
num() { printf '%s' "$2" | awk -v k="$1" 'match($0, "\"" k "\":[0-9.]+") { print substr($0, RSTART + length(k) + 3, RLENGTH - length(k) - 3) }'; }
# sumof <key> <agent folder>: over every result line: a second turn writes a second, each counting its own time and turns
sumof() { grep '"type":"result"' "$2/log" 2>/dev/null | while IFS= read -r l; do num "$1" "$l"; done | awk '{ s += $1; n++ } END { if (n) printf "%d", s }'; }
# the result line's "result" string, decoded; nothing when it holds none
decoded() { LC_ALL=C awk 'BEGIN { ORS = "" } { i = index($0, "\"result\":\""); if (!i) exit; s = substr($0, i + 10)
    while (match(s, /["\\]/)) { o = o substr(s, 1, RSTART - 1); c = substr(s, RSTART, 1); e = substr(s, RSTART + 1, 1); s = substr(s, RSTART + 2)
      if (c == "\"") { print o "\n"; exit } o = o ((e == "n") ? "\n" : (e == "t") ? "\t" : e) } }'; }
# ended <agent folder>: an agent gone is written up once: its hand-back kept, its line in agents.txt. A killed agent, or one past its turns, leaves no hand-back
ended() { [ ! -d "$1/done" ] || return 0; [ -f "$1/pid" ] || return 1; alive "$1" && return 1; mkdir "$1/done" 2>/dev/null || return 0
  r=$(grep '"type":"result"' "$1/log" 2>/dev/null | tail -n 1 || true); printf '%s\n' "$r" | decoded > "$1/handback"; ms=$(sumof duration_ms "$1"); u=$(sumof num_turns "$1")
  case $r in *'"is_error":true'*) : > "$1/handback" ;; esac; grep -q '[^[:space:]]' "$1/handback" || : > "$1/handback"
  [ -n "$ms" ] && s=$((${ms%.*} / 1000)) || s=$(($(date +%s) - $(cat "$1/start")))
  printf '%s\t%s\t%s\t%s\t%s%s\n' "$(cat "$1/role")" "$(cat "$1/ticket")" "$(modelof "$1")" "$s" "$u" "$([ ! -f "$1/time-limit" ] || printf '\ttime-limit')" >> "$W/agents.txt"; }
stop_() { a=$1; alive "$a" || { ended "$a" || true; return 0; }; p=$(cat "$a/pid"); kill -s TERM "$p" 2>/dev/null || true; n=0
  while alive "$a" && [ "$n" -lt 5 ]; do sleep 1; n=$((n + 1)); done; alive "$a" && kill -s KILL "$p" 2>/dev/null || true; sleep 1; ended "$a" || true; }
# model <agent folder>: a first message showing another model than the note's stops that agent
model() { m=$(modelof "$1"); [ -z "$m" ] || [ "$m" = "$(mdl)" ] && return 0; echo "$m" > "$1/refused"; stop_ "$1"; return 1; }
# overtime <agent folder> (R3): alive past the note's agent-time-limit:, it is stopped by its recorded pid, and its line in agents.txt marked time-limit
overtime() { l=$(key agent-time-limit); case $l in ''|*[!0-9]*) return 1 ;; esac; [ ! -d "$1/done" ] && alive "$1" && [ $(($(date +%s) - $(cat "$1/start"))) -ge "$l" ] || return 1; : > "$1/time-limit"; stop_ "$1"; }
# limit <key>: the note's whole number, or a refusal naming the key
limit() { v=$(key "$1"); case $v in ''|*[!0-9]*) die "the job note has no $1: as a whole number" ;; esac; echo "$v"; }
folder() { [ -d "$W/agents/${1:-}" ] || die "no agent '${1:-}'"; echo "$W/agents/$1"; }
# silence <agent folder>: seconds since `wait` or `list` last saw the log grow
silence() { z=$(wc -c < "$1/log"); t=$(date +%s); [ "$(sed -n 1p "$1/seen" 2>/dev/null)" = "$z" ] || printf '%s\n%s\n' "$z" "$t" > "$1/seen"; echo $((t - $(sed -n 2p "$1/seen"))); }
# 0.26.10.28.8 (R1): a grader's own copy of its job note names the plugin folder, which its frozen role file names by the folder the dev side was in
cmd_start() { [ $# -eq 3 ] || die 'usage: dm.sh start <role> <job note> <clone>'; R=$1; [ -f "$2" ] || die "no job note at $2"; [ -d "$3" ] || die "no clone at $3"; C=$(cd "$3" && pwd -P); T='Bash Read Edit Write Grep Glob'; B=${DM_AGENT_CLAUDE:-claude}
  case $R in dev-manager) L=DM; B=claude ;; setup) L=TM; F=$ROOT/devagent/test-manager/setup.md ;; test-author) L=TA ;; test-analyst) L=AN; T='Bash Read Write Grep Glob' ;; builder) L=BU ;; fixer) L=FX ;; grader) L=GR ;; stage-grader) L=GR; T='Bash Read Write Grep Glob' ;; second-reviewer) L=SR; T='Bash Read Write Grep Glob' ;; *) die "no role $R" ;; esac
  F=${F:-$ROOT/devagent/agents/$R.md}; [ -f "$F" ] || die "no role file $F"; for a in $(agents); do [ "$(cat "$a/clone")" != "$C" ] || ! alive "$a" || die "the clone $C holds a live agent, ${a##*/}"; done
  m=$(oldkeys "$N") || die "$m"; TU=$(limit agent-turn-limit); limit agent-time-limit > /dev/null; MD=$(mdl)
  mkdir -p "$W/agents"; k=$(($(ls "$W/agents" | wc -l) + 1)); while ! mkdir "$W/agents/$R-$k" 2>/dev/null; do k=$((k + 1)); done; A=$W/agents/$R-$k; cp "$2" "$A/note"; case $R in grader|stage-grader) printf '\nThe plugin folder, the one your role file means by the folder that holds the dev side, and which holds skills/vid-verify/passes/grader.md and skills/vid-grade/GRADING.md: %s\n' "$ROOT" >> "$A/note" ;; esac; [ ! -d "$C/.git" ] || { git -C "$C" config user.name "DevAgent $L"; git -C "$C" config user.email dev@devagent.invalid; }; echo "$C" > "$A/clone"; echo "$L" > "$A/role"
  t=$(sed -n 's/^ticket: *#*//p' "$2" | head -n 1); echo "${t:--}" > "$A/ticket"; date +%s > "$A/start"; : > "$A/log"
  set -m; ( cd "$C" || exit 1; exec nohup sh -c 'sh "$2" stamp $$ > "$1/lstart"; echo $$ > "$1/pid"; shift 2; exec "$@"' sh "$A" "$ROOT/devagent/test-manager/run.sh" "$B" -p "Read $F whole, then your job note, $A/note, and do as they say." --model "$MD" --settings '{"enabledPlugins":{"vid@vid":false}}' \
      --output-format stream-json --verbose --max-turns "$TU" --add-dir "$W" "$ROOT" --allowedTools $T ) > "$A/log" 2> "$A/err" < /dev/null &   # a group of its own: an agent outlives the dev manager that started it
  set +m
  n=0; while [ "$n" -lt "${DM_FIRST:-30}" ] && [ -z "$(modelof "$A")" ]; do alive "$A" || [ ! -f "$A/pid" ] || break; sleep 1; n=$((n + 1)); done
  model "$A" || die "${A##*/} showed $(cat "$A/refused"), not $MD: stopped"; echo "${A##*/}"; }
cmd_wait() { A=$(folder "${1:-}"); n=0; while [ "$n" -lt "${DM_WAIT:-200}" ]; do model "$A" || { echo "stopped: it showed $(cat "$A/refused")"; exit 5; }; overtime "$A" || true
    if ended "$A"; then if [ -s "$A/handback" ]; then cat "$A/handback"; exit 0; fi; echo 'ended: no hand-back'; [ ! -f "$A/time-limit" ] || echo "stopped at its time limit, $(key agent-time-limit) s"; exit 3; fi
    [ "$(silence "$A")" -lt "${DM_QUIET:-1200}" ] || { echo quiet; exit 4; }; sleep 2; n=$((n + 2)); done; echo running; exit 75; }
# list (0.26.10.28.8, R5): first whether the loop lives, `loop: alive, pid <p>, for <m> min` or `loop: not running`, and each live dev manager,
# `dev manager: <id>, alive, for <m> min`; then the agents, runs and `none` as before. Read only, no model turn, no GitHub call
mins() { s0=$(sed -n 1p "$1" 2>/dev/null) || { echo '?'; return; }; case $s0 in ''|*[!0-9]*) echo '?' ;; *) echo $((($(date +%s) - s0) / 60)) ;; esac; }
cmd_list() { if lalive; then echo "loop: alive, pid $LP, for $(mins "$W/dm-loop.start") min"; else echo 'loop: not running'; fi
  for a in $(agents); do case ${a##*/} in dev-manager-*) ! alive "$a" || echo "dev manager: ${a##*/}, alive, for $(mins "$a/start") min" ;; esac; done
  o=''; for a in $(agents); do i=${a##*/}; case $i in dev-manager-*) continue ;; esac; if alive "$a"; then echo "alive $i ticket $(cat "$a/ticket") clone $(cat "$a/clone")"; o=1
    else ended "$a" || true; [ -f "$a/taken" ] || { echo "ended $i ticket $(cat "$a/ticket") $([ -s "$a/handback" ] && echo "hand-back $a/handback" || echo 'no hand-back')"; o=1; }; fi; done
  for r in "$W"/runs/*/; do [ -f "$r/pid" ] && [ ! -f "$r/exit" ] && alive "${r%/}" || continue; echo "run ${r%/}"; o=1; done; [ -n "$o" ] || echo none; }
# next: one line a ticket, from gh, the record, the agents. The newest of `vid: decide <head>` and `vid: decision <head>` for the pull request's head says what is due; anything for another head is no answer
DMPQ='.[] | [.number, .headRefName, .isDraft, .headRefOid, ([.labels[].name] | join(",")), (.body | split("\n") | .[0]), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), (([.comments[] | select(.body | startswith("vid: decision "))] | last | .body) // ""), .updatedAt] | @tsv'
DMMQ='.[] | [.number, .headRefOid, (.mergeCommit.oid // "-"), (.body | split("\n") | .[0])] | @tsv'
DMIQ='.[] | [.number, ([.labels[].name] | join(",")), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), .updatedAt, ([(.body // "") | split("\n") | .[] | select(startswith("- chunk ")) | ltrimstr("- chunk ") | split(",") | .[0]] | join(" "))] | @tsv'
# runl: a close run's line (v0.26.10.25.3 R8): blocked by its label; work while a chunk of its body has no `vid: reported <chunk>-<k>`, or a `vid: again <chunk>`
# newer than its newest, unless the record's newest `lost <chunk> <k>` came after the k-th again, the last; else wait. A stage grade is one chunk, s1, and a comment begun
# `vid: refused` newer than its newest report calls for its next attempt too, as an again does, but is not counted as one (v0.26.10.26.1 R7). A staging okay is one chunk, d1:
# a `vid: refused d1-<k>` or a ViD comment begun `vid: failed at` newer than its newest report calls for its next attempt as a refusal does (v0.26.10.26.2 R8).
# v0.26.10.27.1 R8: a deploy okay's body begins `okay: rehearsal`, one chunk rh, worked as d1 is, or `okay: production`, one chunk d2, whose next attempt only a
# `vid: again d2` or `vid: refused d2-<k>` calls for; and RM's `Production failed at …` or `Production's deploy of … has not reported` newer than the newest
# `vid: recovered` calls for work, the recovery, whatever its reports. v0.26.10.28.2 (R2): a close run's chunk whose record holds a `lost <chunk> <k>` with no
# `said lost <chunk> <k>` calls for work, the comment that says it, even when every chunk else waits
runl() { case ",$(printf '%s' "$I" | cut -f2)," in *",${P}blocked,"*) echo blocked; return ;; esac
  printf '%s\n' "$I" | cut -f3 | tr '\001' '\n' | awk -v ch="$(printf '%s' "$I" | cut -f5)" -v rec="$W/tickets/$n.txt" 'BEGIN { m = split(ch, c, " ") }
    { for (i = 1; i <= m; i++) { if ($0 ~ ("^vid: reported " c[i] "-[0-9]+$")) r[i] = NR; if ($0 == "vid: again " c[i]) { a[i] = NR; A[i]++ } if (c[i] == "s1" && $0 ~ /^vid: refused( |$)/ || (c[i] == "d1" || c[i] == "rh") && $0 ~ ("^vid: (refused " c[i] "-[0-9]+|failed at )") || c[i] == "d2" && $0 ~ /^vid: refused d2-[0-9]+/) a[i] = NR }
      if ($0 ~ /^Production failed at |^Production.s deploy of /) q = NR; if ($0 ~ /^vid: recovered /) v = NR }
    END { if (c[1] == "d2" && q > v) { print "work"; exit } while ((getline l < rec) > 0) { split(l, x, " "); if (x[1] == "lost") { L[x[2]] = x[3]; U[x[2] " " x[3]] = 1 } if (x[1] == "said" && x[2] == "lost") delete U[x[3] " " x[4]] }
      for (u in U) { split(u, y, " "); if (y[1] ~ /^p[0-9]+c([0-9]+|x)$/) { print "work"; exit } }
      for (i = 1; i <= m; i++) if (!((c[i] in L) && L[c[i]] == A[i] + 0) && (!r[i] || a[i] > r[i])) { print "work"; exit } print "wait" }'; }
cmd_next() { R=$(key repo); P=$(key labels-prefix); [ -n "$R" ] || die "no repo: in $N"; o=''; say() { o=1; echo "$1 $n"; }; F=$W/.next.$$; gh pr list -R "$R" --state open --limit 200 --json number,headRefName,isDraft,headRefOid,labels,body,comments,updatedAt --jq "$DMPQ" > "$F.o" && gh pr list -R "$R" --state merged --limit 20 --search 'sort:updated-desc' --json number,headRefOid,mergeCommit,body --jq "$DMMQ" > "$F.m" && gh issue list -R "$R" --state open --limit 200 --json number,labels,comments,updatedAt,body --jq "$DMIQ" > "$F.i" || { rm -f "$F".?; die 'the repository could not be read'; }
  for n in $(awk -F'\t' -v l=",${P}ticket," -v r=",${P}run," -v g=",${P}grade," -v y=",${P}deploy," 'index("," $2 ",", l) || index("," $2 ",", r) || index("," $2 ",", g) || index("," $2 ",", y) { print $1 }' "$F.i" | sort -n); do I=$(awk -F'\t' -v n="$n" '$1 == n' "$F.i")
    case ",$(printf '%s' "$I" | cut -f2)," in *",${P}run,"*) say "$(runl)"; continue ;; *",${P}grade,"*) I=$(printf '%s\n' "$I" | awk -F'\t' -v OFS='\t' '{ $5 = "s1"; print }'); say "$(runl)"; continue ;;
      *",${P}deploy,"*) b=$(gh issue view "$n" -R "$R" --json body --jq .body) || { rm -f "$F".?; die "the okay #$n could not be read"; }
        case $(printf '%s\n' "$b" | head -n 1) in 'okay: rehearsal') ck=rh ;; 'okay: production') ck=d2 ;; *) ck=d1 ;; esac
        I=$(printf '%s\n' "$I" | awk -F'\t' -v OFS='\t' -v k="$ck" '{ $5 = k; print }'); say "$(runl)"; continue ;; esac
    awk -F'\t' -v n="$n" '$4 ~ ("^ticket: #" n "([^0-9]|$)") { f = 1 } END { exit !f }' "$F.m" && continue; L=$(awk -F'\t' -v n="$n" '$6 ~ ("^ticket: #" n "([^0-9]|$)")' "$F.o" | head -n 1); PN=$(printf '%s' "$L" | cut -f1); H=$(printf '%s' "$L" | cut -f4)
    case ",$(printf '%s' "$I" | cut -f2)," in *",${P}blocked,"*) say blocked; continue ;; esac
    ! grep -q '^left:' "$W/tickets/$n.txt" 2>/dev/null || { say left; continue; }
    printf '%s\n' "$I" | cut -f3 | tr '\001' '\n' | grep -qx 'vid: claimed' || { say claim; continue; }
    [ -n "$PN" ] || { say work; continue; }
    printf '%s\n' "$L" | cut -f7 | tr '\001' '\n' > "$F.c"; d=$(grep -nx "vid: decide $H" "$F.c" | tail -n 1 | cut -d: -f1); e=$(grep -nx "vid: decision $H" "$F.c" | tail -n 1 | cut -d: -f1)
    if [ -z "$d$e" ]; then say work
    elif [ "${d:-0}" -gt "${e:-0}" ]; then u=wait
    else b=$(printf '%s\n' "$L" | cut -f8 | awk '{ gsub(/\\n/, "\n") } 1'); if [ "$(printf '%s\n' "$b" | sed -n 2p)" = 'ticket: accepted' ]; then say merge; continue
      elif printf '%s\n' "$b" | sed -e '1,2d' -e 's/^[^ ]* //' | grep -qE '^(failing|evidence missing)'; then say not-yet; continue; else u=wait; fi; fi
    [ -n "$d$e" ] || continue; for a in $(agents); do [ "$(cat "$a/ticket")" = "$n" ] && alive "$a" && u=work; done; say $u; done
  rm -f "$F".?; [ -n "$o" ] || echo none; }
calls() { printf '%s\n' "$1" | grep -E '^(claim|work|not-yet|merge) ' | head -n 1 || true; }
# sig <line>: the line and the tickets' records. A line can come back with a new head or decision after a pass that moved it; a pass that moved nothing leaves this as it was
sig() { { printf '%s\n' "$1"; cat "$W"/tickets/*.txt 2>/dev/null || true; } | cksum; }
halt() { trap '' TERM INT; echo "$(now) the loop stopped: $1" >> "$W/dm-report.txt"; date +%s >> "$W/dm-loop.start"; for a in $(agents); do [ ! -f "$a/pid" ] || stop_ "$a"; done; for r in "$W"/runs/*/; do [ -f "$r/pid" ] && [ ! -f "$r/exit" ] || continue; sh "$ROOT/devagent/test-manager/run.sh" stop "${r%/}" 2>/dev/null || true; done; said "$1"; notes_save; exit 0; }
# said <why> (v0.26.10.28.6, R3): a stop said where ViD reads it, open work or none. The stopped report, `stopped-<k>/results.txt` (by: DM, the stop's
# words as dm-report.txt has them), on its own branch vid-results/stopped-<k>, made with no work tree; then `vid: stopped <why>` on each open issue
# labelled for ViD's work that holds a claim or a start of this dev side. Each failure is a line of dm-report.txt, never a second halt
said() { C=$W/clones/dm; U=$(git -C "$C" remote get-url origin 2>/dev/null) || { echo "$(now) the stop could not be said: no clone of the repository" >> "$W/dm-report.txt"; return 0; }
  k=$(git -C "$C" ls-remote --heads "$U" 'vid-results/stopped-*' 2>/dev/null | sed -n 's|.*refs/heads/vid-results/stopped-\([0-9][0-9]*\)$|\1|p' | sort -n | tail -n 1); k=$((${k:-0} + 1)); id=stopped-$k
  r=$(printf 'by: DM\nstopped: %s\nat: %s\n' "$1" "$(now)" | git -C "$C" hash-object -w --stdin) && t=$(printf '100644 blob %s\tresults.txt\n' "$r" | git -C "$C" mktree) && t=$(printf '040000 tree %s\t%s\n' "$t" "$id" | git -C "$C" mktree) \
    && c=$(git -C "$C" -c user.name='DevAgent DM' -c user.email=dev@devagent.invalid commit-tree "$t" -m "$id" -m 'Role: DM') && git -C "$C" push -q "$U" "$c:refs/heads/vid-results/$id" 2>/dev/null \
    || echo "$(now) the stopped report could not be pushed" >> "$W/dm-report.txt"
  R=$(key repo); P=$(key labels-prefix); [ -n "$R" ] || return 0
  gh issue list -R "$R" --state open --limit 1000 --json number,labels,comments,updatedAt,body --jq "$DMIQ" > "$W/.said.$$" 2>/dev/null || { rm -f "$W/.said.$$"; echo "$(now) the open issues could not be read to say the stop" >> "$W/dm-report.txt"; return 0; }
  printf 'vid: stopped %s\nby: DM\n' "$1" > "$W/.said.$$.c"
  for n in $(awk -F'\t' -v l=",${P}ticket," -v u=",${P}run," -v g=",${P}grade," -v y=",${P}deploy," '(index("," $2 ",", l) || index("," $2 ",", u) || index("," $2 ",", g) || index("," $2 ",", y)) { m = split($3, c, "\001"); for (i = 1; i <= m; i++) if (c[i] == "vid: claimed" || c[i] == "vid: started") { print $1; break } }' "$W/.said.$$"); do
    gh issue comment "$n" -R "$R" --body-file "$W/.said.$$.c" > /dev/null 2>&1 || echo "$(now) the stop could not be said on #$n" >> "$W/dm-report.txt"; done; rm -f "$W/.said.$$" "$W/.said.$$.c"; }
# the work folder less what is rebuilt, on vid-dev/notes of the code repository (v0.26.10.25.1 R9), so a lost folder comes back: saved each tick of a pass, at its end and at a halt, a commit only when something changed
notes_save() { U=$(git -C "$W/clones/dm" remote get-url origin 2>/dev/null) || return 0; NG=$W/.notes.git; ng() { git --git-dir="$NG" --work-tree="$W" "$@"; }; if [ ! -d "$NG" ]; then git init -q --bare "$NG" 2>/dev/null; git --git-dir="$NG" fetch -q "$U" '+refs/heads/vid-dev/notes:refs/heads/notes' 2>/dev/null || true; git --git-dir="$NG" config core.bare false; printf 'agents/\nclones/\nruns/\nblind/\n.notes.git/\ndm-stop\ndm-loop.*\n.next.*\n' > "$NG/info/exclude"; git --git-dir="$NG" symbolic-ref HEAD refs/heads/notes; fi
  ng add -A --ignore-errors > /dev/null 2>&1 || true; ng -c user.name='DevAgent DM' -c user.email=dev@devagent.invalid commit -qm 'dev notes' -m 'Role: DM' > /dev/null 2>&1 || return 0; ng push -q "$U" 'HEAD:refs/heads/vid-dev/notes' 2>/dev/null || echo "$(now) the notes could not be saved" >> "$W/dm-report.txt"; }
notes_back() { [ ! -f "$W/dev-setup.txt" ] && [ ! -d "$W/tickets" ] || return 0; U=$(gh repo view "$(key repo)" --json url --jq .url) || return 0; T=$W/.notes.back; git clone -q --single-branch -b vid-dev/notes "$U" "$T" 2>/dev/null || { rm -rf "$T"; return 0; }; rm -rf "$T/.git"; cp -R "$T/." "$W/"; rm -rf "$T"; echo "$(now) the notes came back from vid-dev/notes" >> "$W/dm-report.txt"; }
cmd_loop() { T0=$(date +%s); echo "$T0" > "$W/dm-loop.start"; IDLE=$T0; DM=''; BEGAN=''; SAME=0; NR=''; C=$W/clones/dm; trap 'halt "stopped by a signal"' TERM INT
  notes_back
  [ -d "$C" ] || { mkdir -p "$W/clones"; git clone -q "$(gh repo view "$(key repo)" --json url --jq .url)" "$C" || die 'the repository could not be cloned'; }
  while :; do [ ! -f "$W/dm-stop" ] || halt "the stop file: $(cat "$W/dm-stop")"; for a in $(agents); do overtime "$a" || true; done; L=$(key time-limit); [ -z "$L" ] || [ $(($(date +%s) - T0)) -lt "$L" ] || halt "the time limit: ${L}s"
    if [ -n "$DM" ] && alive "$W/agents/$DM"; then [ "$(silence "$W/agents/$DM")" -lt "${DM_QUIET:-1200}" ] || stop_ "$W/agents/$DM"; notes_save; sleep "${DM_TICK:-60}"; continue; fi
    # R3: idle, it stays and reads `next` at the longer tick; the stop file and the time limit are still read at every tick
    if [ -z "$DM" ] && [ -n "$NR" ] && [ "$(date +%s)" -lt "$NR" ]; then sleep "${DM_TICK:-60}"; continue; fi; NR=''
    X=$(cmd_next) || { sleep "${DM_TICK:-60}"; continue; }; A=$(calls "$X")
    if [ -n "$DM" ]; then ended "$W/agents/$DM" || true; : > "$W/agents/$DM/taken"; notes_save; if [ -n "$A" ] && [ "$(sig "$A")" = "$BEGAN" ]; then SAME=$((SAME + 1)); else SAME=0; fi; DM=''; IDLE=$(date +%s); [ "$SAME" -lt 2 ] || halt "a pass ended twice with the line it began with: $A"; fi
    if [ -n "$A" ]; then BEGAN=$(sig "$A"); q=$(mktemp); DM=$(cmd_start dev-manager "$N" "$C" 2> "$q") || { e=$(cat "$q"); rm -f "$q"; sm=$(printf '%s\n' "$e" | sed -n 's/^dm\.sh: dev-manager-[0-9]* showed \(.*\), not .*: stopped$/\1/p' | tail -n 1)   # R6: this start's own words, the model its first message showed
      [ -z "$sm" ] && halt "no dev manager could start${e:+: $(printf '%s' "$e" | tail -n 1 | sed 's/^dm\.sh: //')}" || halt "no dev manager could start: its first message showed the model $sm, not the job note's $(mdl); write the line model: $sm in the job note, the exact name the first message shows, or leave model: out for $MODEL0"; }; rm -f "$q"; IDLE=$(date +%s)
    elif printf '%s\n' "$X" | grep -q '^wait '; then IDLE=$(date +%s)
    elif [ $(($(date +%s) - IDLE)) -ge "${DM_IDLE:-600}" ]; then NR=$(($(date +%s) + ${DM_IDLE_TICK:-300})); fi
    sleep "${DM_TICK:-60}"; done; }
# check <job note> (R2): what the dev side needs, read with no model turn and nothing started; a line for each thing missing
cmd_check() { [ -f "${1:-}" ] || die 'usage: dm.sh check <job note>'; f=$1; k=0; miss() { echo "missing: $*"; k=$((k + 1)); }
  if ! command -v claude > /dev/null 2>&1; then miss 'claude on the PATH'
  elif claude auth --help 2>/dev/null | grep -q '^ *status'; then claude auth status --json 2>/dev/null | grep -q '"loggedIn": *true' || miss 'claude signed in (claude auth status)'
  else echo "unchecked: claude's sign-in, which this claude cannot show without a model turn"; fi
  R=$(sed -n 's/^repo: *//p' "$f" | head -n 1)
  if ! command -v gh > /dev/null 2>&1; then miss 'gh on the PATH'; elif ! gh auth status > /dev/null 2>&1; then miss 'gh signed in (gh auth status)'
  elif [ -n "$R" ]; then q=$(gh repo view "$R" --json viewerPermission --jq .viewerPermission 2>/dev/null || true); case $q in WRITE|MAINTAIN|ADMIN) ;; *) miss "write access to $R, the note's repo: (gh gives ${q:-no answer})" ;; esac; fi
  docker info > /dev/null 2>&1 || miss 'Docker answering (docker info)'
  command -v git > /dev/null 2>&1 || miss 'git on the PATH'
  grep -q '^labels-prefix:' "$f" || miss "the job note's labels-prefix:"
  for x in repo work; do [ -n "$(sed -n "s/^$x: *//p" "$f" | head -n 1)" ] || miss "the job note's $x:"; done
  for x in time-limit agent-time-limit agent-turn-limit; do case $(sed -n "s/^$x: *//p" "$f" | head -n 1) in ''|*[!0-9]*) miss "the job note's $x:, a whole number" ;; esac; done
  m=$(oldkeys "$f") || miss "$m"
  # 0.26.10.28.8 (R6): a model: that cannot be a name a first message shows (a short name, or one without the claude- prefix) is refused here,
  # before the first dev manager's start stops on it; a name of the right form is not judged further
  x=$(sed -n 's/^model: *//p' "$f" | head -n 1 | sed 's/[[:space:]]*$//'); case $x in ''|claude-[a-z0-9]*) case $x in *[!a-z0-9.-]*) miss "the job note's model:, the exact name a first message shows, as $MODEL0 (not '$x')" ;; esac ;; *) miss "the job note's model:, the exact name a first message shows, as $MODEL0 (not '$x')" ;; esac
  w=$(workof "$f"); if [ -n "$w" ]; then if [ ! -d "$w" ]; then miss "the work folder $w"; else v=$(invid "$(cd "$w" && pwd -P)"); [ -z "$v" ] || miss "a work folder outside ViD's records: $w is in $v"; fi; fi
  [ "$k" = 0 ] || { echo "$k missing"; return 1; }; echo ready; }
# lalive: the loop dm-loop.pid records lives, the process its start stamp names
lalive() { [ -f "$W/dm-loop.pid" ] || return 1; LP=$(sed -n 1p "$W/dm-loop.pid"); q=$(mktemp) || return 1; sed 1d "$W/dm-loop.pid" > "$q"; r=0; sh "$ROOT/devagent/test-manager/run.sh" is "$LP" "$q" || r=1; rm -f "$q"; return "$r"; }   # the stamp in a temporary file outside the work folder, so list writes nothing there (R5)
# up <job note> (R2): check, then `dm.sh loop` detached, exactly as a loop started by hand: nothing of the note or the environment is changed
cmd_up() { [ -f "${1:-}" ] || die 'usage: dm.sh up <job note>'; cmd_check "$1" || die 'not started: the lines above name what is missing'
  W=$(cd "$(workof "$1")" && pwd -P); NT=$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")
  # one up at a time: .up.lock, held from the liveness check to the recorded pid; a standing one is never
  # removed by another up, which refuses and names it (one a killed up left is removed by hand)
  mkdir "$W/.up.lock" 2>/dev/null || die "another dm.sh up is starting a loop in $W now, or one was stopped midway: remove $W/.up.lock if no dm.sh up runs"
  trap 'rmdir "$W/.up.lock" 2>/dev/null' EXIT
  ! lalive || die "a loop runs already in $W, pid $LP: dm.sh down first"
  rm -f "$W/dm-stop" "$W/dm-loop.pid"   # the stop file an earlier down left would halt the new loop at its first tick
  set -m; nohup sh -c '{ echo $$; sh "$2" stamp $$; } > "$1.t" && mv "$1.t" "$1"; shift 2; exec "$@"' sh "$W/dm-loop.pid" "$ROOT/devagent/test-manager/run.sh" sh "$HERE/dm.sh" loop "$NT" > "$W/dm-loop.log" 2>&1 < /dev/null &
  set +m; n=0; while [ ! -s "$W/dm-loop.pid" ] && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done; [ -s "$W/dm-loop.pid" ] || die "the loop did not start: $W/dm-loop.log"
  echo "the loop runs, pid $(sed -n 1p "$W/dm-loop.pid"), its output in $W/dm-loop.log. Stop it with: sh $HERE/dm.sh down $NT"; }
# down [<job note>] (R2): the stop file, then at most 120 seconds for the recorded loop to end; nothing is signalled
cmd_down() { echo "down at $(now)" > "$W/dm-stop"; lalive || { echo "the stop file is written; no loop dm.sh up recorded runs in $W"; return 0; }
  n=0; while lalive && [ "$n" -lt "${DM_DOWN:-120}" ]; do sleep 1; n=$((n + 1)); done
  ! lalive || { echo "the loop, pid $LP, still runs after $n s; it stops at its next tick"; return 1; }; echo "the loop, pid $LP, ended"; }
# used (R3): the loop's seconds since its start, or to its halt, of its time-limit; the agents' seconds and turns, the ended from agents.txt, the live so far
cmd_used() { t=$(date +%s); a=$(sed -n 1p "$W/dm-loop.start" 2>/dev/null || true); b=$(sed -n 2p "$W/dm-loop.start" 2>/dev/null || true); echo "loop: $([ -n "$a" ] && echo $((${b:-$t} - a)) || echo -) s of $(key time-limit | grep . || echo -) s"
  S=0; U=0; k=0; for x in $(agents); do [ ! -d "$x/done" ] && alive "$x" || continue; k=$((k + 1)); S=$((S + t - $(cat "$x/start"))); U=$((U + $(sumof num_turns "$x" | grep . || echo 0))); done
  cat "$W/agents.txt" 2>/dev/null | awk -F'\t' -v S="$S" -v U="$U" -v k="$k" '{ S += $4; U += $5; n++ } END { printf "agents: %d s, %d turns; %d ended, %d running\n", S, U, n, k }'; }
# follow [<mark>] (0.26.10.28.8, R12): the conversation's view of the loop, /vid:vid-devagent's. Read only: it writes nothing in the work folder,
# starts and stops nothing, and runs no model; a signal ends it alone. A pass is one dev manager, ended once the loop marks it taken; a stop is
# a `the loop stopped:` line of dm-report.txt (a pass's own report section there is not one). With no mark it prints whether the loop lives
# and `mark: <k>:<n>:<UTC>` (the newest pass written up, the lines of dm-report.txt read, when it was taken), and returns. With one it looks every DM_FOLLOW_TICK seconds (5)
# and returns as soon as a pass has ended, a stop is written or the loop is gone, or after DM_FOLLOW seconds (540, under the 10 minutes a
# conversation's call may take) with `nothing new`. Each pass, at most 5 a call: `pass <id> ended: ticket #<n>` (the tickets its agents and
# records worked on, else those its hand-back names), its hand-back's first 3 lines, each cut at 200 characters, and `pushed:` the
# vid-results branches its agents' logs name; each stop `stop: <line>`, at most 5; `loop: not running`; and the mark, at the last thing
# shown, so what one call leaves out the next shows at once
# (agents by their ids, never by their paths in a word list, so a work folder whose path holds a space is read whole)
# fpasses <after> [cut]: the passes ended past <after>; with cut (the loop gone), also one a halt cut off: written up (done), never taken
fpasses() { ls "$W/agents" 2>/dev/null | sed -n 's/^dev-manager-\([0-9][0-9]*\)$/\1/p' | while read -r k; do f=$W/agents/dev-manager-$k; { [ -f "$f/taken" ] || { [ -n "${2:-}" ] && [ -d "$f/done" ]; }; } && [ "$k" -gt "$1" ] && echo "$k"; done | sort -n || true; }
rlines() { if [ -f "$W/dm-report.txt" ]; then wc -l < "$W/dm-report.txt" | tr -d ' '; else echo 0; fi; }
# fhalts <after> <to> <since>: the numbers of the stop lines of dm-report.txt past line <after>, up to line <to>, written at <since> (UTC) or later:
# a fresh work folder's loop brings back the saved dm-report.txt after the mark was taken, and its old stops are not this loop's
fhalts() { [ -f "$W/dm-report.txt" ] || return 0; awk -v a="$1" -v b="$2" -v s="$3" 'NR > a && NR <= b && $1 >= s && index($0, " the loop stopped: ") { print NR }' "$W/dm-report.txt"; }
tks() { grep -E '^[0-9]+$' | sort -nu | sed 's/^/#/' | paste -sd ',' - | sed 's/,/, /g'; }
# fpass <dev manager's folder>: its end is the loop's taken, else the halt's write-up (done); with no hand-back there, the halt cut it off
fpass() { a=$1; E=$a/taken; v=ended; [ -e "$E" ] || { E=$a/done; [ -s "$a/handback" ] || v='cut off by the stop'; }
  P=$(find "$W/agents" -mindepth 2 -maxdepth 2 -name start -newer "$a/start" ! -newer "$E" 2>/dev/null | sed 's|/start$||; s|.*/||'); t=$({ for x in $P; do cat "$W/agents/$x/ticket" 2>/dev/null; done; find "$W/tickets" -name '*.txt' -newer "$a/start" ! -newer "$E" 2>/dev/null | sed 's|.*/||; s|\.txt$||'; } | tks)
  [ -n "$t" ] || t=$(grep -oiE 'tickets? #[0-9]+' "$a/handback" 2>/dev/null | sed 's/.*#//' | tks)   # a pass that only waited on an agent it did not start: the tickets its hand-back names as such, never a pull request's number
  case $t in '') t='no ticket named' ;; *,*) t="tickets $t" ;; *) t="ticket $t" ;; esac; echo "pass ${a##*/} $v: $t"
  if [ -s "$a/handback" ]; then head -n 3 "$a/handback" | cut -c1-200 | sed 's/^/  /'; else echo '  no hand-back'; fi
  # a report's id ends in its number: the role file's own forms (vid-results/req-<n>-…), which every dev manager reads, are not reports
  r=$(for x in "${a##*/}" $P; do grep -ohE 'pushed vid-results/[A-Za-z0-9._-]+' "$W/agents/$x/log" 2>/dev/null || true; done | sed 's/^pushed //' | grep -E '[0-9]$' | awk '!s[$0]++' | head -n 5 | paste -sd ',' - | sed 's/,/, /g'); echo "  pushed: ${r:-nothing}"; }
# the mark, <k>:<n>:<UTC>: past every pass already written up (an earlier loop's cut-off one included), the report's lines, and when it was taken
cmd_follow() { m=${1:-}; if [ -z "$m" ]; then k=$(fpasses 0 cut | tail -n 1); if lalive; then echo "loop: alive, pid $LP"; else echo 'loop: not running'; fi; echo "mark: ${k:-0}:$(rlines):$(now)"; return 0; fi
  K=${m%%:*}; r0=${m#*:}; NL=${r0%%:*}; S0=${r0#*:}
  case $K:$NL in *[!0-9:]*|:*|*:) die "usage: dm.sh follow [<mark>], a mark as follow printed it" ;; esac; case $S0 in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;; *) die "usage: dm.sh follow [<mark>], a mark as follow printed it" ;; esac
  e=$(($(date +%s) + ${DM_FOLLOW:-540}))
  while :; do P=$(fpasses "$K"); n=$(rlines); H=$(fhalts "$NL" "$n" "$S0"); [ -z "$P" ] && [ -z "$H" ] || break; lalive || break
    [ "$(date +%s)" -lt "$e" ] || { echo "nothing new for ${DM_FOLLOW:-540} s; the loop runs, pid $LP"; echo "mark: $K:$n:$S0"; return 0; }; sleep "${DM_FOLLOW_TICK:-5}"; done
  # the loop gone: everything it wrote before it ended is read again (a halt written just before it), and a pass its halt cut off is shown too
  LA=1; lalive || { LA=''; P=$(fpasses "$K" cut); n=$(rlines); H=$(fhalts "$NL" "$n" "$S0"); }
  MORE=''; c=0; for k in $P; do c=$((c + 1)); [ "$c" -le 5 ] || break; fpass "$W/agents/dev-manager-$k"; K=$k; done; [ "$c" -le 5 ] || { echo 'and more passes: the next call shows them'; MORE=1; }
  c=0; for h in $H; do c=$((c + 1)); [ "$c" -le 5 ] || break; echo "stop: $(sed -n "${h}p" "$W/dm-report.txt")"; NL=$h; done; [ "$c" -le 5 ] || { echo 'and more stops: the next call shows them'; MORE=1; }
  [ "$c" -gt 5 ] || NL=$n
  # a loop that ended on dm.sh's own refusal (a clone that failed at its start, say) writes no stop line: its log's last line says why.
  # Said only once nothing is held back, so a call that stops at its cap is followed by the next, which returns at once
  # (and only when no stop line was written since the mark: an error the loop recovered from is no reason for its stop)
  if [ -z "$LA" ] && [ -z "$MORE" ]; then echo 'loop: not running'; l=$(tail -n 1 "$W/dm-loop.log" 2>/dev/null | cut -c1-300); [ -n "$(fhalts 0 "$n" "$S0")" ] || case $l in 'dm.sh: '*) echo "  last words of its log: $l" ;; esac; fi; echo "mark: $K:$NL:$S0"; }
case $CMD in
  loop) cmd_loop ;; check) cmd_check "$@" ;; up) cmd_up "$@" ;; down) cmd_down ;; next) cmd_next ;; start) cmd_start "$@" ;; wait) cmd_wait "$@" ;; list) cmd_list ;;
  take) A=$(folder "${1:-}"); ended "$A" || die "${1:-} is still alive"; cat "$A/handback"; : > "$A/taken" ;;
  stop) A=$(folder "${1:-}"); stop_ "$A"; : > "$A/taken"; echo "$(now) stopped ${A##*/}: what it started for a look may still stand" >> "$W/dm-report.txt" ;;
  used) cmd_used ;; follow) cmd_follow "$@" ;;
  *) die 'usage: dm.sh loop|check|up|down|next|start|wait|take|stop|list|used|follow …, see its head' ;;
esac

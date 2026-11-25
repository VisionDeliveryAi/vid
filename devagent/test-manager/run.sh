#!/bin/sh
# Purpose: DevAgent's test manager's run script (v0.26.10.24.1 R4, v0.26.10.24.2 R2, R4, R5, v0.26.10.24.4 R2, R4, R5, v0.26.10.26.2 R8). One reported test run: at a
# named commit, in a clean checkout, in every engine, its report pushed alone on its branch in ViD results format 1. It reads
# the dev setup record (setup.md, beside this file) and nothing of ViD's. Each process group it starts is stopped by its
# recorded id. A red-<ticket> ask runs in the primary engine alone and needs its rows: line. `engines:` goes in a report only
# when the run covered every engine the record declares.
#   run.sh run|start --setup <record> --ask <report id without its attempt> --commit <full id> [--select <runner words>]
#                    [--engines "<engine> …"] [--no-product] [--line "<a retested:, stand-in: or rows: line>"]…
#                    a close chunk (v0.26.10.25.3 R8): --ask req-<issue>-p<k>c<k>, the chunk's rows and engines as given, and no line
#   run.sh run|start --setup <record> --ask req-<issue>-p1cx --commit <full id> --leave-out "<row id> …|none" [--select "<runner words>"]
#                    a stage's rest chunk (v0.26.10.26.1 R7): the cases outside the rows, in the primary engine alone: the suite less the cases of the
#                    rows --leave-out names (every chunk's rows and the deploy-owed rows, v0.26.10.26.7 R7): the runner's words, as given and never put in
#                    select-form:, may keep them from running; the report holds none of them, nor their covers:. With no case left, the report holds
#                    none, its outer tag closed, and results.txt the line `none left`
#   run.sh run|start --setup <record> --ask req-<issue>-p<k>c<k> --commit <full id> --against <address> [--signin "<role> <address>"]… [--select …] [--engines …]
#                    a staging run's chunk, CS (v0.26.10.26.2 R8): the asked rows against that address, the runner given it as BASE_URL and the sign-ins as
#                    SIGNIN, a "<role> <address>" line each; nothing is started or stopped, no services: or logs: read. CR and CP chunks too (v0.26.10.27.1 R8)
#   run.sh run|start … --ask req-<issue>-p<k>c<k> … --plant-red <row id>…     the labelled plant, for a test alone (v0.26.10.27.1 R8): each case of that row
#                    reads failed in the pushed report, nothing else changed, and results.txt names it, plant: <row id> — …; refused when the row has no case
#   run.sh run|start --setup <record> --here <clone> [--select <runner words>]
#                    the builder's own run: the clone as it stands, the primary engine, the same environment, limits, watcher
#                    and leftovers check. It fetches nothing, pushes nothing, writes no report; its cases file is named in the result
#   run.sh run|start --setup <record> --ask pr-<n>-<head12> --commit <full id> --faults <list>     list: <row> TAB <patch, from the list's
#                    folder> TAB <control row, or none> TAB <runner words>. One fault at a time, primary engine, a clean checkout; the report is a new attempt
#                    with the newest one's files and faults/<row>/; what could not run has inconclusive.txt, and the next still runs
#   run.sh blind --setup <record> --commit <full id>     prints a fresh folder under the work folder, that tree as one new commit; needs only repo:
#   run.sh grade --setup <record> --ask grade-pr-<n>-<head12> --file <grade.txt> [--second <grade.txt>]     pushes it alone, by: GR first, its commit on origin; with --second, the two readers joined, one line a row (v0.26.10.25.2 R1)
#   (v0.26.10.27.2: an owner's grade ask the same, a finding's severity after its tag, `--reqs -` for a robustify ask's findings alone)
#   run.sh grade --setup <record> --ask grade-<issue> --commit <full id> --reqs "<REQ id> …" --file <grade.txt>     a stage grade, S1 (v0.26.10.26.1 R7): one reader; its
#                    commit the ask's; one line for each requirement the ask names, none other, none twice, each pass, partial, facade or absent with its reason; findings tagged bug or rule
#   run.sh sort --setup <record> --ask sort-pr-<n>-<head12> --lines <to-sort.txt> --file <sorted.txt>     pushes it alone, by: SR first, its commit on origin, its lines those of to-sort.txt one for one
#   run.sh wait <run folder>     at most 200 seconds; prints the result, or `running` and the log's last line; a run gone with no result whose supervisor
#                    file holds a fork failure says it was lost to the host's process limit (v0.26.10.28.2, R1)
#   run.sh slot take <record> <name> run|instance <folder> [<predecessor>] | slot free <name> <folder>     the machine's test environments (v0.26.10.28.2, R1, below), for deploy.sh
#   run.sh stop <run folder>     stops that run, by its pid
# `start` is `run`, detached: it prints the run folder. Exit, and wait's exit: 0 pushed, or an own run ended; 1 not run; 2 no results report
# twice, nothing pushed; 3 stopped by its watcher, a service's death or stop, nothing pushed; 75 still running.
# v0.26.10.24.7: a failed stop: keeps the environment, writes stop-failed in the work folder and stops every later run until a setup pass removes it; a process that cannot be signalled is not gone; stop and wait act on the recorded start alone; a log past log-bytes: (100 MB) keeps its end; memory admission, by the record's measured: and free-memory:.
# serves: dev side (0.26.10.28.4, M9)
set -eu
die() { echo "run.sh: $*" >&2; exit 1; }
# mvr <from> <to> (0.26.11.1.4, R6): a rename tried up to 5 times, 1 s apart, since a synced folder may refuse one for a moment; non-zero, the two as
# they were, when every try fails. ViD's own record writes use the same helper; this script loads none of ViD's
mvr() { _mn=1; until mv -f "$1" "$2"; do [ "$_mn" -lt 5 ] || return 1; _mn=$((_mn + 1)); sleep 1; done; }
CMD=${1:-}; [ $# -eq 0 ] || shift
# stamp <pid>: its start, as nothing moves it (v0.26.10.25.2.1, F-003, F-016): the boot's id and /proc's start in ticks on Linux and WSL, where ps's start
# drifts; under Git Bash, whose /proc start moves with its boot time and whose ps has no -o, the two read together, in seconds; else ps's (macOS)
PROC=${VID_PROC:-/proc}; win() { case $(uname -s) in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac; return 1; }
stamp() { if [ -r "$PROC/$1/stat" ]; then t=$(sed 's/^.*) //' "$PROC/$1/stat" | cut -d' ' -f20); if win; then b=$(sed -n 's/^btime //p' "$PROC/stat" 2>/dev/null); echo $((${b:-0} + t / $(getconf CLK_TCK))); else echo "$(cat "$PROC/sys/kernel/random/boot_id" 2>/dev/null):$t"; fi; else ps -o lstart= -p "$1" 2>/dev/null; fi; }
# is <pid> <file>: it lives, and is the process whose stamp the file holds, never another that took the number; under Git Bash within 1 s, the rounding of the two
is() { r=$(cat "$2" 2>/dev/null) && kill -0 "$1" 2>/dev/null && s=$(stamp "$1") && [ -n "$s" ] || return 1; [ "$s" = "$r" ] && return 0; win || return 1; case $r$s in *[!0-9-]*) return 1 ;; esac; [ $((s - r)) -ge -1 ] && [ $((s - r)) -le 1 ]; }
# same <run folder>: its pid lives, and is the process that recorded its start
same() { p=$(cat "$1/pid"); kill -0 "$p" 2>/dev/null && { [ ! -f "$1/lstart" ] || is "$p" "$1/lstart"; }; }
# v0.26.10.28.2 (R1, X-1): at most max-environments: (3) test environments up at once on the machine, counted across every agent and builder, whatever its
# work folder, in one folder, DEVAGENT_ENVIRONMENTS (~/.devagent/environments): a file a slot, its lines the holder's kind, its folder and, for a deployer's
# instance that replaces another, its predecessor's. A run is live while it runs with no exit, or while the environment its failed stop: kept stands (its
# `kept`, and the work folder's stop-failed); an instance while its checkout stands and its deploy runs, its target's `live` names it, or a recorded member
# lives; a replacement while it or its predecessor is. A slot is taken in one step, under the folder's lock (a mkdir), so two runs starting together never
# both see room. A lock whose holder is dead is cleared by one waiter at a time (`.steal`), which reads it again first; a live holder's never
SL=${DEVAGENT_ENVIRONMENTS:-${HOME:-/tmp}/.devagent/environments}
rlive() { { [ ! -f "$1/exit" ] && [ -f "$1/pid" ] && same "$1"; } || { [ -f "$1/kept" ] && [ -f "$(dirname "$(dirname "$1")")/stop-failed" ]; }; }
ilive() { [ -d "$1/checkout" ] || return 1; _p=$(cat "$1/dp.pid" 2>/dev/null) && is "$_p" "$1/dp.lstart" && return 0; [ "$(cat "${1%/*}/live" 2>/dev/null)" != "${1##*/}" ] || return 0
  _q=$(cat "$1/port" 2>/dev/null || echo 0); [ "${_q:-0}" = 0 ] || ! nc -z -w 1 127.0.0.1 "$_q" > /dev/null 2>&1 || return 0   # its product answering, whatever its group
  for _m in "$1"/m.*; do [ -f "$_m" ] && is "${_m##*/m.}" "$_m" && return 0; done; return 1; }
slive() { _o=''; { read -r _k && read -r _f && { read -r _o || true; }; } < "$1" 2>/dev/null || return 1
  case $_k in run) rlive "$_f" ;; instance) ilive "$_f" || { [ -n "$_o" ] && ilive "$_o"; } ;; *) return 1 ;; esac; }
old() { [ -n "$(find "$1" -prune -mmin +1 2>/dev/null)" ]; }
# hlive: the lock's holder lives, the process its start stamp names (a dead holder's pid taken by another process is no holder)
hlive() { _p=$(cat "$SL/.lock/pid" 2>/dev/null || true); [ -n "$_p" ] && [ -s "$SL/.lock/at" ] && is "$_p" "$SL/.lock/at"; }
sclear() { if mkdir "$SL/.steal" 2>/dev/null; then hlive || { [ ! -s "$SL/.lock/at" ] && ! old "$SL/.lock"; } || rm -rf "$SL/.lock"; rm -rf "$SL/.steal"
  elif old "$SL/.steal"; then rm -rf "$SL/.steal"; fi; }
slock() { mkdir -p "$SL" 2>/dev/null || return 2; while :; do if mkdir "$SL/.lock" 2>/dev/null; then { echo $$ > "$SL/.lock/pid" && stamp $$ > "$SL/.lock/at"; } 2>/dev/null && [ "$(cat "$SL/.lock/pid" 2>/dev/null)" = "$$" ] && return 0
    else hlive || { [ ! -s "$SL/.lock/at" ] && ! old "$SL/.lock"; } || sclear; fi; sleep 1; done; }
# stake <max> <name> <kind> <folder> [<predecessor>]: 0 taken, its slot kept by a live holder of that name (a replacement) or one of fewer than max live; 1 none free; 2 no folder
stake() { slock || return 2; _n=0; for _s in "$SL"/*; do [ -f "$_s" ] && [ "${_s##*/}" != "$2" ] || continue; if slive "$_s"; then _n=$((_n + 1)); else rm -f "$_s"; fi; done
  _r=1; if { [ -f "$SL/$2" ] && slive "$SL/$2"; } || [ "$_n" -lt "$1" ]; then printf '%s\n%s\n%s\n' "$3" "$4" "${5:-}" > "$SL/$2" && _r=0; fi; rm -rf "$SL/.lock"; return $_r; }
# smax <record>: its max-environments:, 3 when it has none
smax() { v=$(sed -n 's/^max-environments: *//p' "$1" | head -n 1 | tr -d ' \r'); case $v in '') echo 3 ;; *[!0-9]*|0*) return 1 ;; *) echo "$v" ;; esac; }
case $CMD in
  stamp) stamp "$1"; exit 0 ;; is) is "$1" "$2" && exit 0; exit 1 ;;
  slot) case ${1:-} in take) [ $# -eq 5 ] || [ $# -eq 6 ] && [ -f "$2" ] && { [ "$4" = run ] || [ "$4" = instance ]; } || die 'usage: run.sh slot take <record> <name> run|instance <folder> [<predecessor>]'
        M=$(smax "$2") || die "the record's max-environments: could not be read as a whole number, 1 or more, in $2"; rc=0; stake "$M" "$3" "$4" "$5" "${6:-}" || rc=$?; exit "$rc" ;;
      free) [ $# -eq 3 ] || die 'usage: run.sh slot free <name> <folder>'; [ -f "$SL/$2" ] || exit 0; slock || exit 0; { [ "$(sed -n 2p "$SL/$2")" = "$3" ] && rm -f "$SL/$2"; } 2>/dev/null || true; rm -rf "$SL/.lock"; exit 0 ;;
      *) die 'usage: run.sh slot take|free …' ;; esac ;;
  wait) [ -d "${1:-}" ] || die "no run folder ${1:-}"; n=0
    while [ "$n" -lt 200 ]; do
      if [ -f "$1/exit" ]; then cat "$1/result"; exit "$(cat "$1/exit")"; fi
      # v0.26.10.28.2 (R1): a supervisor that could not fork dies, its fork error in its supervisor file: the cause is said
      same "$1" || [ -f "$1/exit" ] || { c=$(grep -Ei 'fork(: retry)?: resource temporarily unavailable|fork failed|cannot fork|dofork|errno 11' "$1/supervisor" 2>/dev/null | head -n 1 | cut -c1-160 || true)
        [ -z "$c" ] || c=": lost to the host's process limit ($c)"; echo "stopped: the run at $1 is gone, with no result$c"; exit 3; }
      sleep 2; n=$((n + 2)); done
    echo "running: $(tail -n 1 "$1/log" 2>/dev/null || true)"; exit 75 ;;
  stop) [ -f "${1:-}/pid" ] || die "no run at ${1:-}"; [ ! -f "$1/exit" ] || die "the run at $1 has ended"; same "$1" || die "the run at $1 is gone: its pid is not its start"; kill -s TERM "$(cat "$1/pid")"; exit 0 ;;
  run|start|blind|grade|sort) ;; *) die 'usage: run.sh run|start|blind|grade|sort|wait|stop|slot …, see its head' ;;
esac
HALT=''; trap 'HALT=stop' TERM INT
SETUP=''; ASK=''; COMMIT=''; SELECTION=''; ENGINES=''; NO_PRODUCT=''; LINES=''; D=''; HERE=''; FAULTS=''; FILE=''; PATCH=''; SECOND=''; LEAVE=''; REQS=''; AGAINST=''; SIGNIN=''; PLANT=''
parse() { while [ $# -gt 0 ]; do [ "$1" = --no-product ] && { NO_PRODUCT=1; shift; continue; }
    [ $# -ge 2 ] || die "$1 needs a value"
    case $1 in --setup) SETUP=$2 ;; --ask) ASK=$2 ;; --commit) COMMIT=$2 ;; --select) SELECTION=$2 ;; --engines) ENGINES=$2 ;; --here) HERE=$2 ;; --faults) FAULTS=$2 ;; --file) FILE=$2 ;; --second) SECOND=$2 ;; --lines) SUGG=$2 ;; --leave-out) LEAVE=$2 ;; --reqs) REQS=$2 ;; --against) AGAINST=$2 ;; --plant-red) PLANT="${PLANT:+$PLANT }$2" ;;
      --signin) printf '%s\n' "$2" | grep -Eqx '[A-Za-z][A-Za-z0-9_-]* https?://[^[:space:]]+' || die "--signin is \"<role> <address>\", not '$2'"; SIGNIN="${SIGNIN:+$SIGNIN
}$2" ;;
      --dir) D=$2 ;; --line) case $2 in retested:*|rows:*) ! printf "%s\n" ${2#*:} | LC_ALL=C grep -qv "^[A-Z][A-Z]*-[0-9][A-Za-z0-9-]*\$" || die "row ids alone on this line: $2" ;; stand-in:*) ;; *) die "not a report line: $2" ;; esac
        LINES="$LINES$2
" ;;
      *) die "unknown $1" ;; esac; shift 2; done; }
parse "$@"
ids() { [ -n "$1" ] && ! printf '%s\n' $1 | LC_ALL=C grep -qv "^[A-Z][A-Z]*-[0-9][A-Za-z0-9-]*\$"; }
[ -z "$LEAVE" ] || case $ASK in req-*-p1cx) [ "$LEAVE" = none ] || ids "$LEAVE" || die "--leave-out holds row ids alone, or none: $LEAVE" ;; *) die "--leave-out is a rest chunk's alone, req-<issue>-p1cx" ;; esac
[ -z "$REQS" ] || case $CMD:$ASK in grade:grade-[0-9]*) [ "$REQS" = - ] || ids "$REQS" || die "--reqs holds requirement ids alone, or - for a robustify ask: $REQS" ;; *) die "--reqs is a stage grade's alone, grade-<issue>" ;; esac
[ -z "$SIGNIN" ] || [ -n "$AGAINST" ] || die '--signin goes with --against alone'
[ -z "$PLANT" ] || case $CMD:$ASK in run:req-*-p1cx|start:req-*-p1cx|run:req-*|start:req-*) printf '%s\n' "$ASK" | grep -Eqx 'req-[0-9]+-p[0-9]+c[0-9]+' || die "--plant-red is a close chunk's alone, req-<issue>-p<k>c<k>"
    ids "$PLANT" || die "--plant-red holds a row id: $PLANT"; [ -z "$FAULTS$HERE$LINES" ] || die '--plant-red goes on a close chunk alone' ;; *) die "--plant-red is a close chunk's alone, req-<issue>-p<k>c<k>" ;; esac
[ -z "$AGAINST" ] || { case $CMD:$ASK in run:req-*-p1cx|start:req-*-p1cx) die 'a staging run has no rest chunk' ;; run:req-*|start:req-*) ;; *) die "--against is a staging run's chunk's alone, req-<issue>-p<k>c<k>" ;; esac
  [ -z "$LINES$NO_PRODUCT$HERE$FAULTS$LEAVE" ] || die 'a staging run carries no line and no --no-product, and is no own or fault run'
  printf '%s\n' "$AGAINST" | grep -Eqx 'https?://[^[:space:]]+' || die "--against is not an address, http://… or https://…: '$AGAINST'"; BASE_URL=$AGAINST; export BASE_URL SIGNIN; }
[ -f "$SETUP" ] || die "no dev setup record at '$SETUP': run the setup first"
key() { sed -n "s/^$1: *//p" "$SETUP" | head -n 1; }
KEYS='repo engines environments case-limit start stop run'; case $CMD in blind|grade|sort) KEYS=repo ;; esac; [ "$KEYS" = repo ] || [ ! -f "$(dirname "$SETUP")/stop-failed" ] || die "$(cat "$(dirname "$SETUP")/stop-failed")"; for k in $KEYS; do [ -n "$(key "$k")" ] || die "the record has no $k: line"; done
W=$(cd "$(dirname "$SETUP")" && pwd -P); SETUP=$W/$(basename "$SETUP"); PE=$(key engines); PE=${PE%% *}
[ "$KEYS" = repo ] || MAXE=$(smax "$SETUP") || die "the record's max-environments: could not be read as a whole number, 1 or more"
d=$W; while :; do [ ! -e "$d/.vid" ] || die "the work folder is in $d, a folder of ViD's records"; [ "$d" != / ] || break; d=$(dirname "$d"); done
REPO=$(key repo); full() { case $1 in *[!0-9a-f]*|'') die 'the commit must be a full id' ;; esac; [ "${#1}" -eq 40 ] || die 'the commit must be a full id'; }
# attempts: the newest attempt at $ASK; when git cannot read the branches, its words, whole, and exit 1, so every caller says why (F-005)
attempts() { o=$(git ls-remote --heads "$REPO" "vid-results/$ASK-*" 2>&1) || { echo "the results branches of $REPO could not be read: $(printf '%s' "$o" | tr '\n' ' ')"; return 1; }; printf '%s\n' "$o" | sed -n "s|.*refs/heads/vid-results/$ASK-\([0-9][0-9]*\)\$|\1|p" | sort -n | tail -n 1; }
pushrep() { git -C "$R" init -q; git -C "$R" add "$ID"
  git -C "$R" -c user.name="DevAgent $1" -c user.email=dev@devagent.invalid commit -qm "$ID" -m "Role: $1" > /dev/null 2>&1
  n=0; until git -C "$R" push -q "$REPO" "HEAD:refs/heads/vid-results/$ID" > /dev/null 2>&1; do n=$((n + 1)); [ "$n" -lt 3 ] || return 1; sleep 3; done; }
if [ "$CMD" = blind ]; then full "$COMMIT"; mkdir -p "$W/blind"; B=$(mktemp -d "$W/blind/copy.XXXXXX")
  git clone -q "$REPO" "$B" 2>/dev/null || die "$REPO could not be cloned"; git -C "$B" cat-file -e "$COMMIT^{commit}" 2>/dev/null || die "$COMMIT is not on origin"
  git -C "$B" -c advice.detachedHead=false checkout -q "$COMMIT"; rm -rf "$B/.git"; git -C "$B" init -q; git -C "$B" add -A -f
  git -C "$B" -c user.name=DevAgent -c user.email=dev@devagent.invalid commit -qm 'the blind copy' > /dev/null; echo "$B"; exit 0; fi
# the two readers' join (v0.26.10.25.2 R1), mechanical: nothing can judge whether two wordings are one clause
JOIN='function vd(l,   w) { w = substr(l, index(l, " ") + 1); if (w ~ /^breached product( |$)/) return 3; if (w ~ /^breached test( |$)/) return 2; if (w ~ /^unclear( |$)/) return 1; if (w ~ /^kept( |$)/) return 0; return -1 }
  function no(w) { print "ViD run: refused: " w > "/dev/stderr"; bad = 1; exit 1 }
  FNR == 1 { f++; if ($0 != "by: GR") no("a grade file does not begin by: GR"); next }
  /^commit: / { c[f] = (c[f] == "") ? $2 : c[f]; next }
  /^finding: / { fd[f, ++nf[f]] = $0; next }
  !NF { next }
  { if (vd($0) < 0) no("a line has no verdict: " $0); if (($1 in l1) && f == 1 || ($1 in l2) && f == 2) no("a row is there twice: " $1); if (f == 1) { l1[$1] = $0; o[++n] = $1 } else { l2[$1] = $0; m++ } }
  END { if (bad) exit 1; if (c[1] != c[2]) no("the two name different commits"); if (n != m) no("the two name different rows"); for (i = 1; i <= n; i++) if (!(o[i] in l2)) no("the two name different rows: " o[i])
    print "by: GR"; print "commit: " c[1]
    for (i = 1; i <= n; i++) { r = o[i]; x = l1[r]; y = l2[r]; a = vd(x); b = vd(y)
      if (!a || !b) print ((a || !b) ? x : y); else if (x == y) print x; else print ((b > a) ? y " — also: " substr(x, length(r) + 2) : x " — also: " substr(y, length(r) + 2)) }
    for (i = 1; i <= nf[1]; i++) print fd[1, i]; for (i = 1; i <= nf[2]; i++) print fd[2, i] }'
# a stage grade's form (v0.26.10.26.1 R7), as ViD reads it: every asked requirement once, with one of the four words and its reason, and nothing else but findings
S1='BEGIN { n = split(Q, q, " "); for (i = 1; i <= n; i++) a[q[i]] = 1 }
  function no(w) { print "run.sh: " w "; nothing pushed" > "/dev/stderr"; bad = 1; exit 1 }
  NR == 1 || /^commit: / || !NF { next }
  /^finding: (bug|rule)( (high|medium|low))? — ./ { next }
  /^finding:/ { no("a finding not tagged bug or rule, or its severity not high, medium or low: " $0) }
  { if (!($1 in a)) no("a line for no requirement asked: " $0); if ($1 in s) no("a requirement there twice: " $1); s[$1] = 1
    if (substr($0, length($1) + 2) !~ /^(pass|partial|facade|absent) — ./) no("a line with none of pass, partial, facade or absent and its reason: " $0) }
  END { if (bad) exit 1; for (i = 1; i <= n; i++) if (!(q[i] in s)) no("no line for " q[i]) }'
# FB-8 E3: a grade's or a sort's files are taken with no CR at a line's end, in copies; a file with none is taken as it is, and no file given is changed
nocr() { [ -f "$1" ] && LC_ALL=C awk '/\r$/ { f = 1; exit } END { exit !f }' "$1" || { printf '%s\n' "$1"; return 0; }; mkdir -p "$IN/$2"; LC_ALL=C awk '{ sub(/\r$/, "") } 1' "$1" > "$IN/$2/$(basename "$1")"; printf '%s\n' "$IN/$2/$(basename "$1")"; }
case $CMD in grade|sort) IN=$(mktemp -d) || die 'no temporary folder'; trap 'rm -rf "$IN"' EXIT; GF=$FILE; GL=${SUGG:-}; FILE=$(nocr "$FILE" f); SECOND=$(nocr "$SECOND" s); SUGG=$(nocr "${SUGG:-}" l) ;; esac
if [ "$CMD" = grade ]; then [ -f "$FILE" ] || die "no grade file at '$FILE'"; [ "$(head -n 1 "$FILE")" = 'by: GR' ] || die "a grade's first line is by: GR"
  C=$(sed -n 's/^commit: *//p' "$FILE" | head -n 1); full "$C"
  case $ASK in grade-pr-*) case $ASK in grade-pr-*-"$(printf %s "$C" | cut -c1-12)") ;; *) die "$ASK is not the grade of $C" ;; esac ;;
    *) printf '%s\n' "$ASK" | grep -Eqx 'grade-[0-9]+' || die "$ASK is neither a head's grade, grade-pr-<n>-<head12>, nor a stage's, grade-<issue>"
      [ -z "$SECOND" ] || die 'a stage grade has one reader'; full "$COMMIT"; [ "$C" = "$COMMIT" ] || die "the grade names $C, not the ask's commit $COMMIT; nothing pushed"
      [ -n "$REQS" ] || die 'a stage grade needs --reqs, the requirements its ask names'; Q=$REQS; [ "$Q" != - ] || Q=''; LC_ALL=C awk -v Q="$Q" "$S1" "$FILE" || exit 1 ;; esac
  D=$W/runs/grade-$$; R=$D/report; mkdir -p "$R"; git clone -q "$REPO" "$D/c" 2>/dev/null || die "$REPO could not be cloned"
  git -C "$D/c" cat-file -e "$C^{commit}" 2>/dev/null || die "$C is not on origin; nothing pushed"
  if [ -n "$SECOND" ]; then [ -f "$SECOND" ] || die "no grade file at '$SECOND'"; LC_ALL=C awk "$JOIN" "$FILE" "$SECOND" > "$D/joined" || die 'the two readers cannot be joined; nothing pushed'; FILE=$D/joined; fi
  K=$(attempts) || die "$K"; ID=$ASK-$((${K:-0} + 1)); mkdir "$R/$ID"; cp "$FILE" "$R/$ID/grade.txt"; pushrep GR || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; fi
if [ "$CMD" = sort ]; then [ -f "$FILE" ] && [ -f "${SUGG:-}" ] || die "no sorted file at '$FILE', or no lines at '${SUGG:-}'"; [ "$(head -n 1 "$FILE")" = 'by: SR' ] || die "a sort's first line is by: SR"; C=$(sed -n 's/^commit: *//p' "$FILE" | head -n 1); full "$C"; case $ASK in sort-pr-*-"$(printf %s "$C" | cut -c1-12)") ;; *) die "$ASK is not the sort of $C" ;; esac; LC_ALL=C awk 'FNR <= 2 { next } NR == FNR { q[++n] = $1; t[n] = $0; next } { i++; if (i > n || index($0, q[i] " ") != 1 || substr($0, length($0) - length(t[i]) - 4) != " — " t[i]) b = 1 } END { exit !(i == n + 0 && !b) }' "$SUGG" "$FILE" || die "the lines of $GF are not those of $GL, one for one"
  D=$W/runs/grade-$$; R=$D/report; mkdir -p "$R"; git clone -q "$REPO" "$D/c" 2>/dev/null || die "$REPO could not be cloned"
  git -C "$D/c" cat-file -e "$C^{commit}" 2>/dev/null || die "$C is not on origin; nothing pushed"
  K=$(attempts) || die "$K"; ID=$ASK-$((${K:-0} + 1)); mkdir "$R/$ID"; cp "$FILE" "$R/$ID/sorted.txt"; pushrep SR || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; fi
if [ -n "$FAULTS" ]; then grep -q '[^[:space:]]' "$FAULTS" 2>/dev/null || die "no fault in a list at '$FAULTS': with no needed fault there is no fault run"; [ -z "$ENGINES$LINES$SELECTION$NO_PRODUCT$HERE" ] || die '--faults takes the head report, the commit and its list alone'
  case $ASK in pr-*-*) ;; *) die 'a fault run adds to a head report' ;; esac; ENGINES=$PE; LD=$(cd "$(dirname "$FAULTS")" && pwd -P); fi
if [ -n "$HERE" ]; then
  [ -z "$ASK$COMMIT$LINES$ENGINES$NO_PRODUCT" ] || die '--here takes the record and a selection alone: it reports nothing'
  [ -e "$HERE/.git" ] || die "no clone at $HERE"; HERE=$(cd "$HERE" && pwd -P)
  case $HERE in "$W"/*) ;; *) die "the clone $HERE is not under the work folder $W" ;; esac
  [ -n "$(key entry)" ] || die 'the record names no entry: yet: a setup pass first'; ENGINES=$PE
else
  full "$COMMIT"; [ -n "$ASK" ] || die 'no --ask'
  case $ASK in pr-*-*) [ "${ASK##*-}" = "$(printf %s "$COMMIT" | cut -c1-12)" ] || die "$ASK is not this commit's head report" ;;
    req-*-p1cx) printf '%s\n' "$ASK" | grep -Eqx 'req-[0-9]+-p1cx' || die "$ASK is not a rest chunk's ask, req-<issue>-p1cx"
      [ -z "$LINES$NO_PRODUCT" ] || die 'a close run carries no retested:, stand-in: or rows: line, and has the product running'; [ -n "$LEAVE" ] || die 'a rest chunk needs --leave-out, the row ids its line leaves out, or none'
      [ -z "$ENGINES" ] || [ "$ENGINES" = "$PE" ] || die "a rest chunk is in the primary engine, $PE, alone"; ENGINES=$PE ;;
    req-*) printf '%s\n' "$ASK" | grep -Eqx 'req-[0-9]+-p[0-9]+c[0-9]+' || die "$ASK is not a close chunk's ask, req-<issue>-p<k>c<k>"
      [ -z "$LINES" ] || die 'a close run carries no retested:, stand-in: or rows: line' ;;
    red-*) [ -z "$ENGINES" ] || [ "$ENGINES" = "$PE" ] || die "a red run is in the primary engine, $PE, alone"; ENGINES=$PE
      [ -z "$NO_PRODUCT" ] || die 'a red run has the product running'
      printf '%s' "$LINES" | grep -q '^rows: ' || die "a red run needs its rows: line" ;; esac
  for e in $ENGINES; do case " $(key engines) " in *" $e "*) ;; *) die "the record declares no engine $e" ;; esac; done
fi
if [ "$CMD" = start ]; then
  D=$W/runs/$(date -u '+%Y%m%dT%H%M%SZ')-$$; mkdir -p "$D"
  nohup sh "$0" run --dir "$D" "$@" > "$D/supervisor" 2>&1 < /dev/null &
  echo $! > "$D/pid"; echo "$D"; exit 0
fi
[ -n "$D" ] || { D=$W/runs/$(date -u '+%Y%m%dT%H%M%SZ')-$$; mkdir -p "$D"; }
echo $$ > "$D/pid"; stamp $$ > "$D/lstart.t" && mvr "$D/lstart.t" "$D/lstart"   # whole or not there: a half-written start reads as no start, never another's
LOG=$D/log; : > "$LOG"; : > "$D/groups"; : > "$D/covers"; CO=$D/checkout
RUN_ID=run$$; CASE_LIMIT=$(key case-limit); ALL=$(key engines); [ -n "$ENGINES" ] || ENGINES=$ALL
# the selection's form: bare names go into the record's select-form:, at <words>; runner words, a path, or a record with no form stand
form() { F=$(key select-form); case $F in *'<words>'*) case $1 in ''|-*|*/*|*::*) ;; *) printf '%s' "${F%%<words>*}$1${F#*<words>}"; return ;; esac ;; esac; printf '%s' "$1"; }
case $ASK in req-*-p1cx) ;; *) SELECTION=$(form "$SELECTION") ;; esac
export ENGINE RESULTS SELECTION CASE_LIMIT NO_PRODUCT RUN_ID
SIL=$(key silent-seconds); SIL=${SIL:-1200}; SUL=$(key startup-seconds); SUL=${SUL:-3600}
LIM=$(key run-seconds); LIM=${LIM:-86400}; SVE=$(key service-seconds); SVE=${SVE:-15}; LB=$(key log-bytes); LB=${LB:-104857600}
AW=0; WHY=''; LEFT=''
finish() { { printf '%s\n' "$2" "${LEFT:-leftovers: none}"; [ "$1" -eq 0 ] && cat "$D/sorted" || tail -n 20 "$LOG"; } > "$D/result"
  echo "$1" > "$D/exit"; cat "$D/result"; exit "$1"; }
cap() { WHY="stopped: $2, last output at $LO
analyst due: cap stop=$1 last-output=$LO"; }
# whole <report>: a report counts when it holds a case and ends with the closing tag of what it first opened: a killed
# runner's does not
# v0.26.10.26.7 (R7): a rest chunk's report may hold no case, when every case is a row's: its outer tag still closes (or closes itself)
whole() { case $ASK in req-*-p1cx) [ -s "$1" ] || return 1 ;; *) grep -q "<testcase" "$1" 2>/dev/null || return 1 ;; esac; t=$(grep -Eo "<testsuites?" "$1" | head -n 1); [ -n "$t" ] || return 1
  tail -c 40 "$1" | tr -d " \n\r\t" | grep -q "</${t#<}>$" || { ! grep -q "<testcase" "$1" && [ "$(grep -Eo '<testsuites?[ >/]' "$1" | grep -c .)" = 1 ] && tail -c 40 "$1" | tr -d " \n\r\t" | grep -q '/>$'; }; }   # self-closing: the outer tag alone
# step <start|tests|stop> <command>: its own process group, its output in the log, but start's in start.log: the product
# inherits that, and only what the tests print counts as not silent. One tick a second, counted, so a host sleep never
# counts. The watcher, on the step's own output, sets WHY and takes the group down. RC is the command's exit.
step() { O=$LOG; [ "$1" != start ] || O=$D/start.log; set -m; ( cd "$CO" && exec sh -c "$2" ) >> "$O" 2>&1 < /dev/null & P=$!; set +m
  echo "$P" >> "$D/groups"; SI=0; SU=0; SZ=$(wc -c < "$O"); LO=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); SV=0
  while kill -0 "$P" 2>/dev/null; do sleep 1; AW=$((AW + 1)); SU=$((SU + 1)); SV=$((SV + 1)); B=$(wc -c < "$O")
    if [ "$B" != "$SZ" ]; then SZ=$B; SI=0; LO=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); else SI=$((SI + 1)); fi
    if [ "$B" -gt "$LB" ]; then tail -c "$LB" "$O" > "$O.end"; cat "$O.end" > "$O"; rm -f "$O.end"; SZ=$(wc -c < "$O"); OFF=0; SO=0; fi
    [ "$1" = stop ] && { [ "$SU" -lt "$SUL" ] || break; continue; }
    if [ -n "$HALT" ]; then WHY='stopped: by stop'
    elif [ "$SI" -ge "$SIL" ]; then cap silent "silent for ${SIL}s"
    elif [ "$1" = start ] && [ "$SU" -ge "$SUL" ]; then cap startup "start-up past ${SUL}s"
    elif [ "$AW" -ge "$LIM" ]; then cap limit "the run limit, ${LIM}s"
    elif [ "$1" = tests ] && [ -z "$AGAINST" ] && [ -n "$(key services)" ] && [ "$SV" -ge "$SVE" ]; then SV=0
      o=$( (cd "$CO" && sh -c "$(key services)") 2>/dev/null | head -n 1 || true); [ -z "$o" ] || WHY="stopped: service $o"; fi
    [ -z "$WHY" ] || break
  done
  if kill -0 "$P" 2>/dev/null; then kill -s TERM -- "-$P" 2>/dev/null || true; sleep 1; kill -s KILL -- "-$P" 2>/dev/null || true; fi
  RC=0; wait "$P" 2>/dev/null || RC=$?; }
# sweep: everything the run started has stopped; what has not is stopped now, by its group, and named. A process that cannot be signalled is there, not gone
there() { kill -0 -- "-$1" 2>/dev/null || kill -0 -- "-$1" 2>&1 | grep -q 'not permitted'; }
sweep() { for g in $(cat "$D/groups"); do there "$g" || continue
    kill -s TERM -- "-$g" 2>/dev/null || true; sleep 1; kill -s KILL -- "-$g" 2>/dev/null || true; sleep 1; if there "$g"; then LEFT="${LEFT:-leftovers:} group $g not gone"; else LEFT="${LEFT:-leftovers:} stopped group $g"; fi; done
  : > "$D/groups"; [ -z "$(key leftovers)" ] || { o=$( (cd "$CO" && sh -c "$(key leftovers)") 2>/dev/null | head -n 5 || true)
    [ -z "$o" ] || LEFT="${LEFT:-leftovers:} $o"; }; }
if [ -n "$HERE" ]; then CO=$HERE; else
  git clone -q "$REPO" "$CO" >> "$LOG" 2>&1 || finish 1 "not run: $REPO could not be cloned"
  git -C "$CO" cat-file -e "$COMMIT^{commit}" 2>/dev/null || finish 1 "not run: $COMMIT is not on origin; nothing pushed"
  git -C "$CO" -c advice.detachedHead=false checkout -q "$COMMIT" >> "$LOG" 2>&1
fi
# DROP: a cases file less every testcase whose name matches an id of L: the id within it, - _ and . the same, no letter or digit next to it
XF='function norm(s) { gsub(/[-_.]/, "-", s); return s }
  function hit(n, id,   o, p, a, b, c) { o = 1; while ((p = index(substr(n, o), id)) > 0) { a = o + p - 1; b = (a > 1) ? substr(n, a - 1, 1) : ""; c = substr(n, a + length(id), 1); if (b !~ /[A-Za-z0-9]/ && c !~ /[A-Za-z0-9]/) return 1; o = a + 1 } return 0 }
  function chr(n) { return (n > 8 && n < 127) ? sprintf("%c", n) : "?" }
  function hex(s,   i, v) { v = 0; for (i = 1; i <= length(s); i++) v = v * 16 + index("0123456789abcdef", tolower(substr(s, i, 1))) - 1; return v }
  function dec(s) { gsub(/&lt;/, "<", s); gsub(/&gt;/, ">", s); gsub(/&quot;/, "\"", s); gsub(/&apos;/, "\047", s)
    while (match(s, /&#[0-9]+;/)) s = substr(s, 1, RSTART - 1) chr(substr(s, RSTART + 2, RLENGTH - 3) + 0) substr(s, RSTART + RLENGTH)
    while (match(s, /&#[xX][0-9a-fA-F]+;/)) s = substr(s, 1, RSTART - 1) chr(hex(substr(s, RSTART + 3, RLENGTH - 4))) substr(s, RSTART + RLENGTH)
    gsub(/&amp;/, "\\&", s); return s }
  function tagend(r,   i, c, q) { q = ""; for (i = 1; i <= length(r); i++) { c = substr(r, i, 1); if (q != "") { if (c == q) q = "" } else if (c == "\"" || c == "\047") q = c; else if (c == ">") return i } return 0 }
  function name(t,   v, q, p) { if (!match(t, /[ \t\r\n]name[ \t\r\n]*=[ \t\r\n]*["\047]/)) return ""; q = substr(t, RSTART + RLENGTH - 1, 1); v = substr(t, RSTART + RLENGTH); p = index(v, q); return dec(substr(v, 1, p - 1)) }'
DROP="$XF"'
  { s = s $0 "\n" }
  END { n = split(L, q, " "); for (i = 1; i <= n; i++) q[i] = norm(q[i]); o = ""
    while (match(s, /<testcase[ \t\r\n\/>]/)) { o = o substr(s, 1, RSTART - 1); s = substr(s, RSTART); e = tagend(s); if (!e) break
      if (substr(s, e - 1, 1) == "/") z = e; else { z = index(s, "</testcase>"); if (!z) break; z += 10 }
      m = norm(name(substr(s, 1, e))); k = 0; for (i = 1; i <= n; i++) if (hit(m, q[i])) k = 1
      if (!k) o = o substr(s, 1, z); s = substr(s, z + 1) }
    printf "%s", o s }'
# PLANTX: the plant, a cases file with each testcase of a row of L made to read failed, its opening tag kept; each row hit is written to HF
PLANTX="$XF"'
  { s = s $0 "\n" }
  END { n = split(L, q, " "); for (i = 1; i <= n; i++) { r[i] = q[i]; q[i] = norm(q[i]) } o = ""
    while (match(s, /<testcase[ \t\r\n\/>]/)) { o = o substr(s, 1, RSTART - 1); s = substr(s, RSTART); e = tagend(s); if (!e) break
      if (substr(s, e - 1, 1) == "/") z = e; else { z = index(s, "</testcase>"); if (!z) break; z += 10 }
      m = norm(name(substr(s, 1, e))); k = 0; for (i = 1; i <= n; i++) if (hit(m, q[i])) { k = i; print r[i] >> HF }
      if (!k) o = o substr(s, 1, z); else { t = substr(s, 1, e); if (substr(t, e - 1, 1) == "/") t = substr(t, 1, e - 2) ">"
        o = o t "<failure message=\"a labelled plant (--plant-red " r[k] "): made to read failed\">a labelled plant, for the test alone: the case ran as it ran; nothing else changed</failure></testcase>" }
      s = substr(s, z + 1) }
    printf "%s", o s }'
# admit: first a test environment of the machine's (v0.26.10.28.2, R1), once a run, waited for while max-environments: are up, but a staging run's chunk
# (--against), which starts nothing; then, with another run in its environment, this one waits for the measured memory plus 2 GB; the first is never held back
SLOT=''
admit() { [ -n "$AGAINST$SLOT" ] || { SLOT=run-$$-$(printf %s "$D" | cksum | cut -d' ' -f1); _w=''
    while :; do _m=$(sed -n 's/^max-environments: *//p' "$SETUP" 2>/dev/null | head -n 1 | tr -d ' \r'); case $_m in ''|*[!0-9]*|0*) ;; *) MAXE=$_m ;; esac   # 0.26.10.29.1 (R4): the record's own line, read once a tick, so a cap raised while it waits counts at once; no whole number read keeps the cap it had
      _rc=0; stake "$MAXE" "$SLOT" run "$D" || _rc=$?; [ "$_rc" != 0 ] || break; [ "$_rc" = 1 ] || finish 1 "not run: the machine's environments could not be counted in $SL"
      [ ! -f "$W/stop-failed" ] || finish 1 "not run: $(cat "$W/stop-failed")"; [ -z "$HALT" ] || finish 3 'stopped: by stop, while it waited for a test environment'
      [ "$_w" = "$MAXE" ] || { echo "waiting for a test environment: $MAXE are up on this machine (max-environments: $MAXE)" >> "$LOG"; _w=$MAXE; }; sleep 5; done; }
  m=$(key measured | awk '{ print $2 }'); f=''; if [ -n "$m" ] && [ -n "$(key free-memory)" ]; then while :; do o=''; for r in "$W"/runs/*/; do [ "${r%/}" != "$D" ] && [ -f "$r/admitted" ] && [ ! -f "$r/exit" ] && same "$r" && o=1; done
      [ ! -f "$W/stop-failed" ] || finish 1 "not run: $(cat "$W/stop-failed")"; [ -n "$o" ] && [ -z "$HALT" ] || break; [ "$(sh -c "$(key free-memory)" 2>/dev/null || echo 0)" -lt $((m + 2048)) ] || break; [ -n "$f" ] || { echo 'waiting for memory' >> "$LOG"; f=1; }; sleep 5; done; fi; : > "$D/admitted"; }
# one_run <engine> <results>: a clean tree with $PATCH on it, environment up, selection, down, once more if no report; GONE says why none, EC its exit
one_run() { ENGINE=$1; RESULTS=$2; n=0; GONE=''; admit
  while :; do n=$((n + 1)); rm -f "$RESULTS"
    [ -n "$HERE" ] || { git -C "$CO" reset -q --hard; git -C "$CO" clean -qxffd; [ -z "$PATCH" ] || git -C "$CO" apply "$PATCH" >> "$LOG" 2>&1; }
    echo "== $ENGINE, pass $n, selection ${SELECTION:-all}, at $(date -u '+%Y-%m-%dT%H:%M:%SZ')" | tee -a "$D/start.log" >> "$LOG"
    OFF=$(wc -c < "$LOG"); SO=$(wc -c < "$D/start.log")
    if [ -n "$AGAINST" ]; then echo "against $AGAINST: nothing started" >> "$LOG"; step tests "$(key run)"
    else step start "$(key start)"
      if [ "$RC" -ne 0 ] || [ -n "$WHY" ]; then { tail -c +"$((SO + 1))" "$D/start.log" | tail -n 19; [ -n "$WHY" ] || echo "the environment did not start: exit $RC"; } >> "$LOG"
      else step tests "$(key run)"; fi
      [ -z "$(key logs)" ] || (echo "== pass $n"; cd "$CO" && sh -c "$(key logs)") >> "$D/timeline-$ENGINE.log" 2>&1 || true; fi
    w=$WHY; WHY=''
    if [ -z "$AGAINST" ]; then step stop "$(key stop)"
      if [ "$RC" -ne 0 ]; then GONE="stopped: stop: failed, exit $RC; the environment is kept, and no run goes until a setup pass mends it and removes $W/stop-failed"; EC=3; LEFT='leftovers: the environment, kept'; echo "$GONE" > "$W/stop-failed"; : > "$D/kept"; return 0; fi; fi; sweep
    [ -z "$w" ] || { GONE=$w; EC=3; return 0; }
    if whole "$RESULTS"; then tail -c +"$((OFF + 1))" "$LOG" | grep -a '^covers: [^ ]* [0-9]*$' >> "$D/covers" || true; return 0; fi
    [ "$n" -lt 2 ] || { GONE="no results report: $ENGINE wrote none, twice; nothing pushed; its last lines:"; EC=2; return 0; }
    echo "$ENGINE wrote no results report; once more" >> "$LOG"
  done; }
if [ -z "$FAULTS" ]; then for E in $ENGINES; do one_run "$E" "$D/cases-$E.xml"; [ -z "$GONE" ] || finish "$EC" "$GONE"; done
  # the rest chunk (v0.26.10.26.1 R7): each case whose name matches a row left out, by the format's matching, leaves the report, and that row's covers: line
  if [ -n "$LEAVE" ] && [ "$LEAVE" != none ]; then for f in "$D"/cases-*.xml; do LC_ALL=C awk -v L="$LEAVE" "$DROP" "$f" > "$f.t" && mvr "$f.t" "$f"; done
    LC_ALL=C awk -v L="$LEAVE" 'BEGIN { n = split(L, q, " "); for (i = 1; i <= n; i++) x[q[i]] = 1 } !($2 in x)' "$D/covers" > "$D/covers.t" && mvr "$D/covers.t" "$D/covers"; fi
  # the labelled plant (v0.26.10.27.1 R8): each case of a planted row reads failed; a row with no case plants nothing, and nothing is pushed
  if [ -n "$PLANT" ]; then : > "$D/planted"; for f in "$D"/cases-*.xml; do LC_ALL=C awk -v L="$PLANT" -v HF="$D/planted" "$PLANTX" "$f" > "$f.t" && mvr "$f.t" "$f"; done
    for r in $PLANT; do grep -qx "$r" "$D/planted" || finish 1 "not pushed: the plant's row $r has no case in this run"; done
    for r in $PLANT; do LINES="${LINES}plant: $r — a labelled plant, for the test alone: its cases made to read failed, nothing else changed
"; done; fi
else K=$(attempts) || finish 1 "not run: $K"; [ -n "$K" ] || finish 1 'not run: no head report at this head to add faults to'; TAB=$(printf '\t'); mkdir -p "$D/faults"; awk 1 "$FAULTS" > "$D/list"
  while IFS=$TAB read -r ROW PATCH CTRL SELECTION <&3; do [ -n "$ROW" ] || continue; F=$D/faults/$ROW; mkdir -p "$F"; SELECTION=$(form "$SELECTION")
    case $PATCH in /*) ;; *) PATCH=$LD/$PATCH ;; esac; git -C "$CO" reset -q --hard; git -C "$CO" clean -qxffd
    if ! git -C "$CO" apply --check "$PATCH" >> "$LOG" 2>&1; then echo 'the patch did not apply' > "$F/inconclusive.txt"; continue; fi
    AW=0; one_run "$PE" "$F/cases-$PE.xml"; [ -z "$HALT" ] || finish 3 'stopped: by stop'; [ ! -f "$W/stop-failed" ] || finish 3 "$GONE"
    if [ -n "$GONE" ]; then rm -f "$F/cases-$PE.xml"; printf '%s\n' "$GONE" | sed -e '1!d' -e 's/; nothing pushed.*//' > "$F/inconclusive.txt"
    elif [ "$CTRL" != none ]; then echo "$CTRL" > "$F/control.txt"; fi
  done 3< "$D/list"; fi
# the sort: one tag a line. Broken cases by their first message, and develop's setup and slow triggers
sortc() { awk -v SE="${1:-}" 'BEGIN { RS = "<" }
  function attr(s, k, v) { if (!match(s, " " k "=\"[^\"]*\"")) return ""
    v = substr(s, RSTART + length(k) + 3, RLENGTH - length(k) - 4); sub(/(&#(10|[xX][aA]);|\n).*/, "", v); return v }
  function done_() { if (name == "") return; T[res]++; if (sec > 240) slow = slow (slow == "" ? "" : ", ") name; if (bm != "") { c = ++C[bm]; if (c <= 5) N[bm] = N[bm] (c > 1 ? ", " : "") name; bm = "" }
    if ((res == "failed" || res == "errored") && sec > 60) waited++; name = "" }
  /^testcase / { done_(); name = attr($0, "name"); sec = attr($0, "time") + 0; res = "passed"; next }
  /^(failure|error)[ >\/]/ { m = attr($0, "message"); if (m == "") { m = $0; sub(/^[^>]*>/, "", m); sub(/\n.*/, "", m) }; gsub(/0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]+/, "0x", m)
    res = ($0 ~ /^error/ || m ~ /^setup:/) ? "errored" : "failed"; if (m ~ /^setup:/) S++; bm = (m == "" ? "(no message)" : m); G[bm]++; next }
  /^skipped[ >\/]/ { res = "skipped" }
  END { done_(); printf "cases: %d passed, %d failed, %d errored, %d skipped\n", T["passed"], T["failed"], T["errored"], T["skipped"]; fflush()
    for (m in G) printf "broken: %d %s\n", G[m], m | "sort -t: -k2 -rn"; close("sort -t: -k2 -rn"); fflush(); for (m in N) printf "broken cases: %s%s — %s\n", N[m], (C[m] > 5 ? ", and " (C[m] - 5) " more" : ""), m
    if (waited >= 5) printf "analyst due: setup cases=%d\n", waited; if (slow != "") printf "analyst due: slow cases=%s\n", slow; if (SE != "") print S + 0 > SE }'; }
cat "$D"/cases-*.xml "$D"/faults/*/cases-*.xml 2>/dev/null | sortc "$D/setup-errors" > "$D/sorted"
# the analyst: no fault run asks for it, and a slow case already asked about fires no more
if [ -n "$FAULTS" ]; then { grep -v '^analyst due:' "$D/sorted" || true; } > "$D/s2"; mvr "$D/s2" "$D/sorted"; else A=$W/analyst-asked; touch "$A"; s=$(sed -n 's/^analyst due: slow cases=//p' "$D/sorted" | sed 's/, /,/g' | tr , '\n' | grep -vxF -f "$A" || true); { grep -v '^analyst due: slow' "$D/sorted" || true; [ -z "$s" ] || echo "analyst due: slow cases=$(printf '%s\n' "$s" | paste -sd , - | sed 's/,/, /g')"; } > "$D/s2"; mvr "$D/s2" "$D/sorted"; [ -z "$s" ] || printf '%s\n' "$s" >> "$A"; fi
# R12 (v0.26.10.25.3): a pull request's head runs' setup: errors, counted across its runs in the work folder, setup-errors, as analyst-asked is kept: at 5, whatever
# their time, the analyst is due, once a pull request; a run whose own setup trigger fired says nothing more
case $ASK in pr-*-*) [ -n "$FAULTS" ] || { SF=$W/setup-errors; touch "$SF"
  u=$(awk -v p="${ASK%-*}" -v e="$(cat "$D/setup-errors" 2>/dev/null || echo 0)" -v o="$SF.t" '$1 == p { t = $2; k = $3; a = $4; next } { print > o }
    END { t += e; k++; if (a == "" && t >= 5) { a = "asked"; d = 1 } print p, t, k, a > o; if (d) print "analyst due: setup errors=" t " runs=" k }' "$SF"); mvr "$SF.t" "$SF"
  [ -z "$u" ] || grep -q '^analyst due: setup' "$D/sorted" || echo "$u" >> "$D/sorted"; } ;; esac
[ -z "$FAULTS" ] || for F in "$D"/faults/*; do r=${F##*/}; if [ -f "$F/inconclusive.txt" ]; then echo "fault $r inconclusive: $(cat "$F/inconclusive.txt")"
  else echo "fault $r: $(sortc < "$F/cases-$PE.xml" | sed -n 's/^cases: //p')"; fi; done >> "$D/sorted"
[ -z "$HALT" ] || finish 3 'stopped: by stop'
[ -z "$HERE" ] || finish 0 "own run, reported to nobody, nothing pushed: $D/cases-$PE.xml"
K=$(attempts) || finish 1 "not pushed: $K"; ID=$ASK-$((${K:-0} + 1)); R=$D/report; mkdir -p "$R/$ID"
if [ -n "$FAULTS" ]; then rmdir "$R/$ID"; git -C "$CO" archive "origin/vid-results/$ASK-$K" | tar -x -C "$R"; mvr "$R/$ASK-$K" "$R/$ID"; mkdir -p "$R/$ID/faults"
  for F in "$D"/faults/*; do if [ -f "$F/inconclusive.txt" ] && [ -d "$R/$ID/faults/${F##*/}" ]; then continue; fi; rm -rf "$R/$ID/faults/${F##*/}"; cp -R "$F" "$R/$ID/faults/"; done; pushrep TM || finish 1 "not pushed: vid-results/$ID"; finish 0 "pushed vid-results/$ID"; fi
EL=''; [ "$(printf '%s\n' $ENGINES | sort -u)" != "$(printf '%s\n' $ALL | sort -u)" ] || EL="engines: $ALL
"
NL=''; case $ASK in req-*-p1cx) cat "$D"/cases-*.xml 2>/dev/null | grep -q '<testcase' || NL='none left
' ;; esac   # v0.26.10.26.7 (R7): every case is a row's, whether the runner left them out or the drop did
{ echo 'by: TM'; echo "commit: $COMMIT"; printf '%s' "$EL"; echo "environments: $(key environments)"; sort -k2,2 -k3,3n "$D/covers" | awk '!s[$2]++'; printf '%s' "$LINES$NL"; } > "$R/$ID/results.txt"
for E in $ENGINES; do cp "$D/cases-$E.xml" "$R/$ID/"; done
pushrep TM || finish 1 "not pushed: vid-results/$ID"
finish 0 "pushed vid-results/$ID"

#!/bin/sh
# Purpose: ViD observer — the run seen from outside the session (v0.9.3 spec
# 3.9, 3.12; R13, R16; v0.9.5 3.3, 3.5; R3, R5). Small, dumb, outside: it
# reads records only (.vid/RUN-STATE.md, .vid/HEARTBEAT.md, git, the
# declared watchdog operations, the receipts, the lock and the host lease,
# the briefs, the events file, .vid/hook-times), always reports, probes
# overdue operations under a bound, tells the owner, and never repairs — it
# never kills, restarts, removes a lock or edits a file but its own records
# (the `observe:` heartbeat lines, .vid/NUDGE and its memory
# .vid/observer.state). It never makes the session continue, and no hook
# inside the session takes part (owner rulings, 2026-09-25).
# It runs outside the session: the detached loop develop starts (`start`,
# v0.9.7.0.9, below), or an owner's own scheduler line beside it, one tick
# per interval, VID_OBSERVE_INTERVAL seconds (default 900). A tick covers the
# directory it runs in and every other directory in `git worktree list`
# that holds .vid/RUN-STATE.md; each directory's records, heartbeat lines
# and notices are its own and name it.
# Each tick writes one `observe:` line per observation to the heartbeat:
#   1. session activity age (the newest heartbeat line NOT written by the
#      observer) and git recency — the observer's own lines never refresh
#      the session's clock;
#   2. every declared operation: inside its envelope → nothing; overdue →
#      `VID_OBSERVER=1 sh checks/watchdog.sh check <op>` (bounded; exit 2 the
#      system answered, exit 3 the system is the finding);
#   3. the newest receipt, the lock and lease holders and the run folders
#      under .vid/runs/ (v0.9.6; stale when the pid is gone), free memory against `memory-headroom-mb` where the host exposes
#      it through checks/extractors/memory.sh (reported, never enforced);
#   4. each live brief through `sh checks/brief.sh <file> --at HEAD` →
#      `observe: FLAG stale-brief <file>` when a quoted block differs at HEAD;
#   5. a completion claim — a session heartbeat line saying the run is
#      complete, or RUN-STATE's `run: complete` — while the latest
#      `completion unmet=U strict-gaps=G` event has U or G non-zero, or, with
#      no such event, while `metrics.sh closure` reports unmet rows →
#      `observe: FLAG false-complete`, and the owner is told.
# The owner is told (v0.9.5 3.5), each notice once, keyed on its content and
# cleared when it ends, in both of the tick's branches:
#   - a new question (a `Q<n>` line in RUN-STATE's "Open product questions",
#     keyed on its number and its `asked` time; one notice for a tick's new
#     questions); the question list unreadable (the `questions:` count and
#     the lines disagree, or a line does not parse);
#   - the run waiting on an answer (`run: waiting` with a `Q<n>` line), once
#     per episode and once a day while it lasts; stopped for a reason (not
#     for `owner asked to pause`); its record contradicted by a newer commit
#     or session line; a false completion claim;
#   - a death: a `died` event with no newer `run state` event, while the run
#     is not complete — the text by cause;
#   - gone quiet (3.3): no recorded reason to be still (`run: active`, a
#     `waiting` with no `Q<n>` line, or a bare `stopped`), nothing the run
#     started running (no live `.vid/ledger.lock` holder, no live run folder
#     under .vid/runs/ — v0.9.6 3.7.5 — and no declared
#     operation inside its envelope, either holding for at most 2 h after its
#     start), no activity for one interval (a session heartbeat line, a
#     commit, a timed line in the events or .vid/hook-times — never a
#     `brief-check` line, which the observer's own tick writes), and no
#     death standing with nothing after it. One quiet notice stands at a
#     time; newer activity, or the run leaving that state, clears it.
#   An episode is the `at=` of the newest `run state` event (the session
#   writes one at every write of `run:`), or the `run:` line without one.
#   A notice is recorded once, as an `observe: notice — <text>` heartbeat
#   line; nothing is sent (v0.9.7.0.9, the owner's ruling of 2026-10-04: no
#   pop-ups). Death and quiet notices carry "resume from records".
#   - v0.9.7.0.6 (3.2, R2–R4): a quiet agent — each agent in the hooks'
#     record, its latest episode read from its transcript (agents(), below):
#     no new entry for 20 min while `run:` is active or waiting, once per
#     quiet stretch (keyed on its newest entry), cleared by a new entry, the
#     agent finishing, or the run stopping (the owner's pause included).
#     Every agent's newest entry is the run's activity, and while any
#     episode is working the run's quiet notice is not sent. Spawned agents
#     declare nothing.
#   - v0.9.7.1 (3.9, R9): a Codex builder's job (.vid/jobs/<try>) whose process is alive — its group leader with
#     the recorded start time — and whose events file grew within 1,200 s is a working agent, as a Claude one; a
#     job whose process is gone with no exit= published is told to the owner. While builders are paused
#     (builder-tool=paused: Codex ran out), one plain line: "Codex has run out of allowance (resets <time>).
#     Builders are paused. Say 'use Claude for builders' to continue on Claude, or 'wait for Codex' to resume when
#     it resets." (3.9a, R14): a `takeover started` with no `takeover ended`, once a step started after it, is
#     told to the owner. `resume` adds the open jobs (sh checks/job.sh open), the last return processed, an open
#     takeover and a pause.
# The nudge: only a declared operation whose check exits 3 on two successive
# ticks writes .vid/NUDGE and an `observe: nudge` line (answered by `sh
# checks/watchdog.sh claim run --evidence '<observation>'`); on a third tick
# the owner is told, unless a quiet notice stands. Inactivity writes no nudge:
# when the run goes quiet, the owner is told at once.
# `sh checks/observe.sh resume` prints, from records, what a fresh session
# needs to continue or to say why it cannot (3.12), the open agents' lines
# among it (v0.9.7.0.6).
# v0.9.6 (3.15, R15): the progress update. For a run with `plan: required`
# and `run:` active or waiting, a tick runs `sh checks/progress.sh --record
# --trigger hourly|plan-change --by observer` — at most once — when 3,600 s
# have passed since the last `progress` event (or there is none) or a
# `plan-change` event is newer than it, and records its headline as a
# notice line (keyed on the event's at= and its place). The observer's own
# `progress` lines (by=observer) are never activity: they neither clear nor
# re-arm a quiet notice, nor count after a death; a session's are.
# v0.9.7.0.6 (3.3, R5, R6): every tick writes `tick <epoch>` to
# .vid/observer.state (v0.9.7.0.9: `tick <epoch> <home>`); `sh
# checks/observe.sh alive` reads it (`watcher ok — last tick <n>s ago`). It
# proves a recent tick here, not that anyone read a notice.
# v0.9.7.0.9 (3.8; R11–R14) — develop starts the watcher; nothing is sent:
#   start   (run at the run's home) serialised by .vid/observer.start
#           (mkdir); when .vid/observer.pid's loop is running — its pid alive,
#           its command line holding `observe.sh loop`, the pid file's home
#           this home (pwd -P), and .vid/observer.state holding `loop <token>
#           <home>` with the pid file's token — prints `watcher running (pid
#           <p>)`; otherwise writes a new token, starts `sh checks/observe.sh
#           loop <token>` detached (setsid, else perl's setsid, else HUP
#           ignored; its output to .vid/observer.log, cut to its last 200
#           lines at each start) and waits up to 30 s for the loop's own
#           acknowledgement, `loop <token> <home>` in .vid/observer.state —
#           written as the loop's first tick begins, under the tick's lock:
#           `watcher started (pid <p>)`, or exit 1 naming what is missing.
#           A start that finds this home's loop process (pid alive, `observe.sh
#           loop <token>`, the pid file's home) not yet acknowledged waits for
#           it the same way, and never starts a second loop.
#   loop <token>  each round a tick (every worktree) that writes the
#           acknowledgement, then VID_OBSERVE_INTERVAL seconds of sleep; it ends when
#           RUN-STATE reads `run: complete`, .vid/ is gone, or the pid file
#           holds another token. A reboot or log-out ends it; develop's next
#           resume starts it again.
#   tick [--now]  one tick at a time per worktree: .vid/observer.lock
#           (mkdir, the tick's pid); a held lock is skipped while its holder
#           lives and reclaimed when it is gone (never for its age). Under the
#           lock, a tick less than VID_OBSERVE_INTERVAL − 60 s after the last
#           tick recorded for this home records nothing (an owner's scheduler line may run
#           beside the loop); --now forces it. Every tick records `tick
#           <epoch> <home>`.
#   No notifier: a notice is an `observe: notice — <text>` heartbeat line,
#   once per condition until it clears (the keys as before), and nothing is
#   sent; the send command, its state line and its script are gone, and
#   so is the budget's progress key. The hourly progress update is
#   recorded to .vid/PROGRESS.md as before, its headline a notice line.
#   `alive` exits 0 on a tick within 1,800 s recorded for this home, else 1,
#   printing what is missing and `sh checks/observe.sh start`.
#   The activity line reads `run activity <s>s ago (<source>) · last commit
#   <g>s ago · run: …` — the source that set the newest activity: events,
#   commit hooks, heartbeat, git or agent <id> — or `run activity: none
#   recorded · …`.
# Usage: sh checks/observe.sh [tick [--now]] | start | loop <token> | resume | alive
set -u
IFS='
'
MODE=${1:-tick}
[ "$MODE" = tick ] && [ "${2:-}" = --now ] && { VID_OBSERVE_FORCE=1; export VID_OBSERVE_FORCE; }
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

# --- every worktree (v0.9.5 3.5): tick here, then each other worktree with a run --------
if [ "$MODE" = tick ] && [ -z "${VID_OBSERVE_ONE:-}" ]; then
  HERE=$(pwd -P)
  VID_OBSERVE_ONE=1 sh "$SELF" tick
  for w in $(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do
    [ -f "$w/.vid/RUN-STATE.md" ] || continue
    [ "$(cd "$w" 2>/dev/null && pwd -P)" = "$HERE" ] && continue
    ( cd "$w" && VID_OBSERVE_ONE=1 VID_OBSERVE_LOOP='' sh "$SELF" tick )
  done
  exit 0
fi

# --- v0.9.7.0.9 (3.8, R11): start — one detached watcher loop per run home ---------------------
PIDF=.vid/observer.pid
# loop_proc <pid> <token> <home>: that pid is this home's loop — alive, its command line `observe.sh loop <token>`,
# the pid file's home this home; it is running once .vid/observer.state also holds its acknowledgement
loop_proc() {
  case "$1" in ''|*[!0-9]*) return 1 ;; esac
  kill -0 "$1" 2>/dev/null || return 1
  _c=$(ps -p "$1" -o args= 2>/dev/null || ps -p "$1" -o command= 2>/dev/null)
  case "$_c" in *"observe.sh loop $2"*) ;; *) return 1 ;; esac
  [ "$(sed -n 2p "$PIDF" 2>/dev/null)" = "$3" ]
}
if [ "$MODE" = start ]; then
  HM=$(pwd -P); mkdir -p .vid
  _w=0
  while ! mkdir .vid/observer.start 2>/dev/null; do   # serialised: two starts never race
    _sp=$(cat .vid/observer.start/pid 2>/dev/null || true)
    if [ -n "$_sp" ] && ! kill -0 "$_sp" 2>/dev/null; then rm -rf .vid/observer.start; continue; fi
    _w=$((_w + 1)); [ "$_w" -le 30 ] || { echo "ViD observe: refused — another start holds .vid/observer.start (pid ${_sp:-unknown}) for 30 s"; exit 1; }
    sleep 1
  done
  echo "$$" > .vid/observer.start/pid
  trap 'rm -rf .vid/observer.start' EXIT
  _p=$(sed -n 1p "$PIDF" 2>/dev/null); _tk=$(sed -n 3p "$PIDF" 2>/dev/null)
  if [ -n "$_tk" ] && loop_proc "$_p" "$_tk" "$HM"; then   # this home's loop: its acknowledgement, never a second loop
    _w=0
    while ! grep -qxF "loop $_tk $HM" .vid/observer.state 2>/dev/null; do
      kill -0 "$_p" 2>/dev/null || break
      _w=$((_w + 1)); [ "$_w" -le 30 ] || { echo "ViD observe: the watcher loop (pid $_p) is running but gave no acknowledgement in 30 s — no 'loop $_tk $HM' line in $HM/.vid/observer.state (another tick may hold .vid/observer.lock); its output is in .vid/observer.log"; exit 1; }
      sleep 1
    done
    if grep -qxF "loop $_tk $HM" .vid/observer.state 2>/dev/null; then echo "watcher running (pid $_p)"; exit 0; fi
  fi
  TOK=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
  printf '%s\n%s\n%s\n' - "$HM" "$TOK" > "$PIDF.tmp" && mv "$PIDF.tmp" "$PIDF"   # the token first: the loop checks it
  [ -f .vid/observer.log ] && { tail -n 200 .vid/observer.log > .vid/observer.log.tmp; mv .vid/observer.log.tmp .vid/observer.log; }
  if command -v setsid >/dev/null 2>&1; then setsid sh "$SELF" loop "$TOK" < /dev/null >> .vid/observer.log 2>&1 &
  elif command -v perl >/dev/null 2>&1; then perl -e 'use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' sh "$SELF" loop "$TOK" < /dev/null >> .vid/observer.log 2>&1 &
  else ( trap '' HUP; exec sh "$SELF" loop "$TOK" < /dev/null >> .vid/observer.log 2>&1 ) & fi
  LP=$!
  printf '%s\n%s\n%s\n' "$LP" "$HM" "$TOK" > "$PIDF.tmp" && mv "$PIDF.tmp" "$PIDF"
  _w=0
  while [ "$_w" -lt 30 ]; do
    grep -qxF "loop $TOK $HM" .vid/observer.state 2>/dev/null && { echo "watcher started (pid $LP)"; exit 0; }
    kill -0 "$LP" 2>/dev/null || break
    sleep 1; _w=$((_w + 1))
  done
  if kill -0 "$LP" 2>/dev/null; then echo "ViD observe: the watcher loop (pid $LP) gave no acknowledgement in 30 s — no 'loop $TOK $HM' line in $HM/.vid/observer.state; its output is in .vid/observer.log"
  else echo "ViD observe: the watcher loop (pid $LP) ended before its acknowledgement — no 'loop $TOK $HM' line in $HM/.vid/observer.state; its output is in .vid/observer.log"; fi
  exit 1
fi
# --- v0.9.7.0.9 (3.8, R11): loop <token> — a tick each round, until the run completes ----------
if [ "$MODE" = loop ]; then
  TOK=${2:-}; [ -n "$TOK" ] || { echo 'ViD observe: usage — sh checks/observe.sh loop <token> (started by sh checks/observe.sh start)' >&2; exit 2; }
  HM=$(pwd -P)
  live() { [ -d .vid ] && [ "$(sed -n 3p "$PIDF" 2>/dev/null)" = "$TOK" ] && ! grep -q '^run:[[:space:]]*complete' .vid/RUN-STATE.md 2>/dev/null; }
  while live; do
    _r=0
    while :; do   # the round's tick; one held by another source's live tick is tried again, up to 30 s
      VID_OBSERVE_LOOP="$TOK" sh "$SELF" tick
      grep -qxF "loop $TOK $HM" .vid/observer.state 2>/dev/null && break
      _r=$((_r + 1)); [ "$_r" -lt 15 ] && live || break; sleep 2
    done
    live || break
    sleep "${VID_OBSERVE_INTERVAL:-900}" & wait $! || true
  done
  echo "observe loop $TOK ended at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  exit 0
fi

HB=.vid/HEARTBEAT.md
RS=.vid/RUN-STATE.md
STF=.vid/observer.state
EV=.vid/metrics-events
HT=.vid/hook-times
INT=${VID_OBSERVE_INTERVAL:-900}
HOLD=7200
NOW=${VID_OBSERVE_NOW:-$(date +%s)}   # v0.9.7.0.6: a replay clock for the rehearsal; unset in use

# --- v0.9.7.0.6 (3.3, R5, R6); v0.9.7.0.9 (3.8, R13): `alive` — a recent tick, recorded for this home. Reads, never writes
if [ "$MODE" = alive ]; then
  DIR=$(pwd -P)
  _l=''; [ -f "$STF" ] && _l=$(sed -n 's/^tick //p' "$STF" | tail -n 1)
  _t=${_l%% *}; _h=''; case "$_l" in *' '*) _h=${_l#* } ;; esac
  case "$_t" in ''|*[!0-9]*) _t='' ;; esac
  if [ -n "$_t" ] && [ $((NOW - _t)) -le 1800 ] && [ "$_h" = "$DIR" ]; then echo "watcher ok — last tick $((NOW - _t))s ago"; exit 0; fi
  if [ -z "$_t" ]; then echo "watcher: no tick recorded in $DIR/.vid/observer.state — the watcher has never run here"
  elif [ "$_h" != "$DIR" ]; then echo "watcher: the last tick recorded in $DIR/.vid/observer.state was for ${_h:-no home} — a copied record, not this run's watcher"
  else echo "watcher: the last tick was $((NOW - _t))s ago, older than 30 minutes — the watcher is not running"; fi
  echo "watcher: start it: sh checks/observe.sh start"
  exit 1
fi

# --- records -----------------------------------------------------------------------
rskey() { [ -f "$RS" ] && sed -n "s/^.*$1:[[:space:]]*//p" "$RS" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z-]*:.*$//;s/[[:space:]]*$//'; }
rsline() { [ -f "$RS" ] && sed -n "s/^$1:[[:space:]]*//p" "$RS" | head -n 1 | sed 's/[[:space:]]*$//'; }
RUNV=$(rskey run); RUN=$(printf '%s\n' "$RUNV" | awk '{print $1}'); [ -n "$RUN" ] || RUN=none
RREASON=$(printf '%s\n' "$RUNV" | sed 's/^[^[:space:]]*[[:space:]]*//')
SESSION=$(rsline session)
SLICE=$(rskey slice)
BRIEFS=$(rskey briefs | tr ' ' '\n' | grep -v '^$' | grep -v '^-$' || true)
# the question lines (3.2): `- Q<n> · asked <UTC> · gates <…> · <question>` in "Open product questions"
QSEC=$( [ -f "$RS" ] && awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' "$RS" | awk '/<!--/ { c = 1 } !c && NF { print } /-->/ { c = 0 }' || true)
QLINES=$(printf '%s\n' "$QSEC" | grep -E '^- Q[0-9]+ · asked [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z · gates [^·]+ · .+' || true)
NQ=$(printf '%s\n' "$QLINES" | grep -c . || true)
NQRAW=$(printf '%s\n' "$QSEC" | grep -c . || true)
QKEY=$(rsline questions); QK=$(printf '%s\n' "$QKEY" | awk '{print $1}'); [ "$QK" = - ] && QK=0
# the newest heartbeat line the SESSION wrote (the observer's are prefixed)
act_age() {
  [ -f "$HB" ] || { echo none; return; }
  awk -v now="$NOW" '
    function ep(t,  y,m,d,H,M,S) { y=substr(t,1,4)+0; m=substr(t,6,2)+0; d=substr(t,9,2)+0; H=substr(t,12,2)+0; M=substr(t,15,2)+0; S=substr(t,18,2)+0
      if (m<=2) { y--; m+=12 } return (365*y + int(y/4) - int(y/100) + int(y/400) + int((153*(m-3)+2)/5) + d - 719469)*86400 + H*3600 + M*60 + S }
    /^- [0-9]{4}-[0-9]{2}-[0-9]{2}T/ && $0 !~ /\| observe: / { t=$2 }
    END { if (t=="") print "none"; else print now - ep(t) }' "$HB"
}
git_age() { _c=$(git log -1 --format=%ct 2>/dev/null || true); [ -n "$_c" ] && echo $((NOW - _c)) || echo none; }
ops() { [ -d .vid/watchdog ] && for f in .vid/watchdog/*; do [ -f "$f" ] && echo "${f##*/}"; done; }
okey() { sed -n "s/^$2=//p" ".vid/watchdog/$1" | tail -n 1; }
HOSTD="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"; HOSTD="${HOSTD%/}/vid-host"
alive() { [ -n "$1" ] && kill -0 "$1" 2>/dev/null; }
holders() { # lock and lease lines: `live|STALE <what>`
  if [ -f .vid/ledger.lock/holder ]; then
    _p=$(sed -n 1p .vid/ledger.lock/holder); _t=$(sed -n 3p .vid/ledger.lock/holder)
    if alive "$_p"; then echo "live lock .vid/ledger.lock held by pid $_p"; else echo "STALE lock .vid/ledger.lock — pid ${_p:-unknown} is gone, $((NOW - ${_t:-NOW})) s old; inspect what died, then remove the directory"; fi
  fi
  # v0.9.6 (3.7.5): a gated run takes no lock; its run folder is its holder
  for _h in .vid/runs/*/holder; do
    [ -f "$_h" ] || continue
    _d=${_h%/holder}; _p=$(sed -n 's/^pid=//p' "$_h" | head -n 1); _t=$(sed -n 's/^start=//p' "$_h" | head -n 1)
    case "$_t" in ''|*[!0-9]*) _t=$NOW ;; esac
    if grep -q '^teardown-failed' "$_h"; then echo "STALE run folder $_d — its teardown failed, $((NOW - _t)) s old; its compose project may still be up: bring it down, then remove the folder and its slot"
    elif alive "$_p"; then echo "live run ${_d##*/} held by pid $_p"
    else echo "STALE run folder $_d — pid ${_p:-unknown} is gone, $((NOW - _t)) s old; inspect its compose project's containers, stop them, then remove the folder"; fi
  done
  for _s in "$HOSTD"/stack.*; do
    [ -f "$_s/holder" ] || continue
    [ "$(sed -n 2p "$_s/holder")" = "$PWD" ] || continue
    _p=$(sed -n 1p "$_s/holder"); _t=$(sed -n 4p "$_s/holder")
    if alive "$_p"; then echo "live lease ${_s##*/} held by pid $_p"; else echo "STALE lease $_s — pid ${_p:-unknown} is gone, $((NOW - ${_t:-NOW})) s old; inspect this project's containers, stop them, then remove the directory"; fi
  done
}
receipt_line() {
  if [ -f checks/metrics.sh ]; then _r=$(sh checks/metrics.sh receipt 2>/dev/null | tr ' ' '\n' | sed -n 's/^receipt=//p'); else _r=''; fi
  if [ -n "$_r" ] && [ "$_r" != none ]; then
    _s=${_r##*/}; _s=${_s%.full.xml}; _c=$(git log -1 --format=%ct "$_s" 2>/dev/null || true)
    echo "receipt $_r — current at HEAD${_c:+, its tree committed $((NOW - _c)) s ago}"
  else
    _n=$(ls -t .vid/ledger-results/*.full.xml 2>/dev/null | head -n 1 || true)
    echo "receipt: none current at HEAD${_n:+ (newest full report $_n)}"
  fi
}
# the events, by their last `at=` (v0.9.5 3.11), as epochs: ACT the newest
# activity (never a brief-check line, never a died line — neither is the
# session working), RSE/RSS/RSAT the newest `run state` event, DIEDS the deaths.
EVAWK='function ep(t,  y,m,d,H,M,S) { y=substr(t,1,4)+0; m=substr(t,6,2)+0; d=substr(t,9,2)+0; H=substr(t,12,2)+0; M=substr(t,15,2)+0; S=substr(t,18,2)+0
    if (m<=2) { y--; m+=12 } return (365*y + int(y/4) - int(y/100) + int(y/400) + int((153*(m-3)+2)/5) + d - 719469)*86400 + H*3600 + M*60 + S }
  function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
  function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
ACT=0; ACTS=''; RSE=0; RSS=''; RSAT=''; DIEDS=''
if [ -f "$EV" ]; then
  _o=$(awk "$EVAWK"'
    { a = lastat(); if (a == "") next; e = ep(a) }
    $1 != "brief-check" && $1 != "died" && !($1 == "progress" && kv("by") == "observer") && e > act { act = e }
    $1 == "run" && kv("state") != "" && e >= rse { rse = e; rss = kv("state"); rsat = a }
    $1 == "died" { print "D\t" kv("session") "\t" a "\t" e "\t" kv("reason") }
    END { print "A\t" act + 0 "\t" rse + 0 "\t" rss "\t" rsat }' "$EV")
  ACT=$(printf '%s\n' "$_o" | awk -F'\t' '$1=="A" { print $2 }'); RSE=$(printf '%s\n' "$_o" | awk -F'\t' '$1=="A" { print $3 }')
  RSS=$(printf '%s\n' "$_o" | awk -F'\t' '$1=="A" { print $4 }'); RSAT=$(printf '%s\n' "$_o" | awk -F'\t' '$1=="A" { print $5 }')
  DIEDS=$(printf '%s\n' "$_o" | grep '^D' || true)
  [ "$ACT" -gt 0 ] && ACTS=events
fi
# v0.9.7.0.9 (3.8, R14): ACTS names the source that set ACT
if [ -f "$HT" ]; then
  _h=$(awk "$EVAWK"' { a = lastat(); if (a != "" && ep(a) > h) h = ep(a) } END { print h + 0 }' "$HT")
  [ "$_h" -gt "$ACT" ] && { ACT=$_h; ACTS='commit hooks'; }
fi
AA=$(act_age); GA=$(git_age)
[ "$AA" != none ] && [ $((NOW - AA)) -gt "$ACT" ] && { ACT=$((NOW - AA)); ACTS=heartbeat; }
[ "$GA" != none ] && [ $((NOW - GA)) -gt "$ACT" ] && { ACT=$((NOW - GA)); ACTS=git; }
dfield() { printf '%s\n' "$1" | cut -f"$2"; }

# --- v0.9.7.0.6 (3.2, R2–R4): the agents, from the hooks' record and their transcripts -------
# For each agent id in the events, its latest episode (from its latest
# `agent-start`): finished (a later `agent-stop`, v0.9.8.1 (R9) a later
# `build-cost` or `agent-returned` carrying its `agent=`, or a SubagentHandback call
# after the episode's start whose result, joined by its tool-use id, reports
# success), else working (newest entry under 1,200 s old), quiet (1,200 s or
# more) or unresolved (no transcript, unreadable, or no timestamp in it). The
# age counts from the newest entry, or from the episode's start when the
# episode has no entry yet. The parent transcript is agent-start's
# `transcript=`, else (an older record) that of the newest earlier `session`
# event of the same session id. AGENTS holds one tab-separated line per
# agent: id, state, age, the time the age counts from, task.
AGAWK='function q(k,  s, p, v) { s = " " $0; p = index(s, " " k "="); if (!p) return ""; v = substr(s, p + length(k) + 2)
    if (substr(v, 1, 1) == "\"") { v = substr(v, 2); p = index(v, "\""); return p ? substr(v, 1, p - 1) : v }
    p = index(v, " "); return p ? substr(v, 1, p - 1) : v }
  function lts(  s, p, t, m) { s = $0; m = ""; while ((p = index(s, "\"timestamp\":\"")) > 0) { s = substr(s, p + 13); t = substr(s, 1, 19)
      if (t ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/ && t > m) m = t } return m }'
# the transcript matcher: on stdin an agent's transcript, -v s=<episode start, 19 chars>;
# prints `H|N <newest entry's epoch, 0 for none>` — H when a SubagentHandback call (a tool_use whose
# `"id":"<id>"` sits right before its name, never the tool's definition in a prompt snapshot) after s
# has a tool_result, joined by its tool-use id, whose nested JSON string says success true
HBAWK='{ t = lts(); if (t > m) m = t }
  index($0, "\"name\":\"SubagentHandback\"") && t > s { r = $0
    while ((p = index(r, "\"name\":\"SubagentHandback\"")) > 0) { pre = substr(r, 1, p - 1); id = ""
      while ((k = index(pre, "\"id\":\"")) > 0) { pre = substr(pre, k + 6); id = substr(pre, 1, index(pre, "\"") - 1) }
      if (id != "" && pre == id "\",") hb[id] = 1; r = substr(r, p + 26) } }
  index($0, "\"tool_use_id\":\"") { r = $0
    while ((p = index(r, "\"tool_use_id\":\"")) > 0) { r = substr(r, p + 15); id = substr(r, 1, index(r, "\"") - 1); g = r
      k = index(g, "\"tool_use_id\":\""); if (k) g = substr(g, 1, k - 1)
      if ((id in hb) && g ~ /\\"success\\"[ ]*:[ ]*true/ && g !~ /"is_error":[ ]*true/) done = 1 } }
  END { print (done ? "H" : "N") "\t" (m == "" ? 0 : ep(m)) }'
jdesc() { awk '{ s = $0; p = index(s, "\"description\":\""); if (!p) next; s = substr(s, p + 15); v = ""
    while (length(s)) { c = substr(s, 1, 1); if (c == "\\") { v = v substr(s, 2, 1); s = substr(s, 3); continue } if (c == "\"") break; v = v c; s = substr(s, 2) }
    gsub(/[\t"]/, "'"'"'", v); print v; exit }' "$1" 2>/dev/null; }
ascan() {
  [ -f "$EV" ] || return 0
  awk "$EVAWK$AGAWK"'
    $1 == "session" { st[q("id")] = q("transcript") }
    $1 == "agent-start" { a = q("agent"); if (a == "" || a == "-") next; if (!(a in seen)) { seen[a] = 1; ord[++n] = a }
      s = q("session"); t = q("transcript"); if (t == "" || t == "-") t = (s in st) ? st[s] : ""
      at[a] = q("at"); tr[a] = t; stp[a] = 0 }
    $1 == "agent-stop" { a = q("agent"); if (a in seen) stp[a] = 1 }
    ($1 == "build-cost" || $1 == "agent-returned") { a = q("agent"); if (a in seen) stp[a] = 1 }   # v0.9.8.1 (R9, F-8): its return or cost, after its latest start
    END { for (i = 1; i <= n; i++) { a = ord[i]; e = (at[a] ~ /^[0-9][0-9][0-9][0-9]-/) ? ep(at[a]) : 0
      printf "%s\t%s\t%s\t%s\t%s\n", a, substr(at[a], 1, 19), e, stp[a], tr[a] } }' "$EV" |
  while IFS='	' read -r _id _at _se _sp _tr; do
    _f=''; case "$_tr" in ''|-) ;; *) _f="${_tr%.jsonl}/subagents/agent-$_id.jsonl" ;; esac
    _tk=''; [ -n "$_f" ] && [ -f "${_f%.jsonl}.meta.json" ] && _tk=$(jdesc "${_f%.jsonl}.meta.json")
    _nw=0; _st=''
    if [ -n "$_f" ] && [ -r "$_f" ]; then
      if [ "$_sp" = 1 ]; then _nw=$(tail -n 200 "$_f" | awk "$EVAWK$AGAWK"'{ t = lts(); if (t > m) m = t } END { print (m == "" ? 0 : ep(m)) }'); _st=finished
      else _o=$(awk -v s="$_at" "$EVAWK$AGAWK$HBAWK" "$_f"); _nw=${_o#*	}; [ "${_o%%	*}" = H ] && _st=finished; fi
    elif [ "$_sp" = 1 ]; then _st=finished; fi
    case "$_nw" in ''|*[!0-9]*) _nw=0 ;; esac
    _from=$_nw; [ "$_se" -gt "$_from" ] && _from=$_se
    if [ -z "$_st" ]; then
      if [ -z "$_f" ] || [ ! -r "$_f" ] || [ "$_nw" -eq 0 ]; then _st=unresolved
      elif [ $((NOW - _from)) -lt 1200 ]; then _st=working; else _st=quiet; fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$_id" "$_st" "$((NOW - _from))" "$_from" "$_nw" "$_tk"
  done
}
# agents: one line per open agent — `agent <id> <state> <age>s "<task>"` (unresolved: `-` for the age)
agents() {
  printf '%s\n' "$AGENTS" | while IFS='	' read -r _id _st _ag _fr _nw _tk; do
    case "$_st" in working|quiet) printf 'agent %s %s %ss "%s"\n' "$_id" "$_st" "$_ag" "$_tk" ;; unresolved) printf 'agent %s unresolved - "%s"\n' "$_id" "$_tk" ;; esac
  done
}
AGENTS=$(ascan)
AWORK=no
# R4: the newest entry of any agent's transcript is activity; a working episode holds the run's quiet notice
for _a in $AGENTS; do
  _nw=$(printf '%s\n' "$_a" | cut -f5); [ "$_nw" -gt "$ACT" ] && { ACT=$_nw; ACTS="agent $(printf '%s\n' "$_a" | cut -f1)"; }
  [ "$(printf '%s\n' "$_a" | cut -f2)" = working ] && AWORK=yes
done
# v0.9.7.1 (3.9, R9): a Codex builder's job — its process alive (its group leader with the recorded start time) and
# its events file grown within the quiet window (1,200 s) — is a working agent; a dead one with no exit= is reported
JOBDEAD=''
for _j in $(ls .vid/jobs 2>/dev/null | grep -v '\.'); do
  _f=.vid/jobs/$_j; grep -q '^exit=' "$_f" 2>/dev/null && continue
  _jp=$(sed -n 's/^pgid=//p' "$_f" | tail -n 1); _js=$(sed -n 's/^pid-start=//p' "$_f" | tail -n 1); [ -n "$_jp" ] || continue
  if [ -n "$_js" ] && [ "$(ps -o lstart= -p "$_jp" 2>/dev/null | sed 's/^ *//')" = "$_js" ]; then
    _jm=$(stat -f %m ".vid/jobs/$_j.events" 2>/dev/null || stat -c %Y ".vid/jobs/$_j.events" 2>/dev/null || echo 0)
    if [ $((NOW - _jm)) -lt 1200 ]; then AWORK=yes; [ "$_jm" -gt "$ACT" ] && { ACT=$_jm; ACTS="job $_j"; }; fi
  else JOBDEAD="$JOBDEAD$_j
"; fi
done
# v0.9.7.1 (3.9a, R14): a takeover still open — `takeover started` with no `takeover ended` after it — and whether a step started since
TKO=$( [ -f "$EV" ] && awk '$1 == "takeover" && $2 == "started" { o = $0; s = 0; next } $1 == "takeover" && $2 == "ended" { o = ""; next } $1 == "step-start" && o != "" { s = 1 } END { if (o != "") print (s ? "boundary " : "open ") o }' "$EV")

if [ "$MODE" = resume ]; then
  OPEN=0
  echo "resume — from records only (RUN-STATE, the heartbeat, the events, the receipts, the briefs), never a wedged session's transcript"
  if [ -f "$RS" ]; then
    echo "resume: run: ${RUNV:-none}"
    [ -n "$SESSION" ] && echo "resume: session: $SESSION"
    [ -n "$SLICE" ] && echo "resume: slice $SLICE"
    case "$SLICE" in *open*) OPEN=1 ;; esac
    M=$(rskey modules); C=$(rskey claims); H=$(rskey held)
    [ -n "$M" ] && echo "resume: modules: $M"
    [ -n "$C" ] && [ "$C" != - ] && { echo "resume: claims: $C"; }
    [ -n "$H" ] && [ "$H" != - ] && echo "resume: held (recorded): $H"
    for q in $QLINES; do echo "resume: open question ${q#- }"; OPEN=1; done
  else
    echo 'resume: no .vid/RUN-STATE.md — no run has started'
  fi
  for d in $DIEDS; do
    [ "$RSE" -gt "$(dfield "$d" 4)" ] && continue
    echo "resume: died — session $(dfield "$d" 2) at $(dfield "$d" 3), reason $(dfield "$d" 5); no run state recorded since"; OPEN=1
  done
  if [ -f "$STF" ] && [ -n "$(sed -n 's/^quiet\.standing //p' "$STF" | tail -n 1)" ]; then echo "resume: the owner was told the build went quiet (a quiet notice stands)"; OPEN=1; fi
  if [ -f checks/metrics.sh ]; then
    HC=$(sh checks/metrics.sh row-state --table 2>/dev/null | awk -F'\t' 'NF>=9 && $5!="-" { printf "%s%s(reason=%s)", (n++?" ":""), $1, $5 }')
    [ -n "$HC" ] && echo "resume: held (computed): $HC"
    # v0.9.8.1 (R30, F-19): a hold no open question names, or one whose answer came and was never released — information only
    [ -n "$HC" ] && sh checks/metrics.sh closure 2>/dev/null | grep '^hold FLAG ' | sed 's/^/resume: /'
  fi
  echo "resume: $(receipt_line)"
  for b in $BRIEFS; do
    if [ -f "$b" ]; then echo "resume: live brief $b"; OPEN=1; else echo "resume: brief $b named in RUN-STATE is missing"; OPEN=1; fi
  done
  # v0.9.7.0.6 (3.8): each session's standing re-read debt, with the paths not yet read in full
  for o in .vid/reread-owed.*; do
    [ -f "$o" ] || continue; case "$o" in *.tmp.*) continue ;; esac
    _u=$(awk '/^file / { f[++n] = substr($0, 6) }
      /^cover / { s = substr($0, 7); p = s; sub(/ [0-9]+ [0-9]+ [0-9]+$/, "", p); if (p == s) next
        split(substr(s, length(p) + 2), x, " "); nc[p]++; a[p, nc[p]] = x[1] + 0; b[p, nc[p]] = x[2] + 0; tot[p] = x[3] + 0 }
      END { for (i = 1; i <= n; i++) { p = f[i]; ok = 0
          if (nc[p] > 0) { split("", cov); for (j = 1; j <= nc[p]; j++) for (l = a[p, j]; l <= b[p, j]; l++) cov[l] = 1
            ok = 1; for (l = 1; l <= tot[p]; l++) if (!(l in cov)) { ok = 0; break } }
          if (!ok) printf "%s%s", (m++ ? ", " : ""), p } }' "$o")
    echo "resume: rules re-read owed by session ${o#.vid/reread-owed.} since $(sed -n 's/^since //p' "$o" | head -n 1): ${_u:-none}"; OPEN=1
  done
  for a in $(agents); do echo "resume: $a"; OPEN=1; done
  # v0.9.7.1 (3.8, 3.9; R8, R9): every open job (checks/job.sh open), and the last return processed
  if [ -f checks/job.sh ]; then for j in $(sh checks/job.sh open 2>/dev/null); do echo "resume: $j"; OPEN=1; done; fi
  _lr=$( [ -f "$EV" ] && grep '^agent-returned ' "$EV" | tail -n 1)
  [ -n "$_lr" ] && echo "resume: last return processed: ${_lr#agent-returned }"
  [ -n "$TKO" ] && { echo "resume: takeover still open — ${TKO#* takeover started }"; OPEN=1; }
  [ "$(sed -n 's/^builder-tool=//p' .vid/budget 2>/dev/null | tail -n 1)" = paused ] && { echo 'resume: builders are paused — Codex ran out of allowance; the owner says which tool'; OPEN=1; }
  for op in $(ops); do
    echo "resume: declared operation $op — $((NOW - $(okey "$op" start))) s of $(okey "$op" envelope) s; probe: $(okey "$op" probe)"; OPEN=1
  done
  UC=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null | sed 's/^...//' || true)
  for u in $UC; do echo "resume: uncommitted $u"; OPEN=1; done
  for h in $(holders); do echo "resume: $h"; case "$h" in STALE*) OPEN=1 ;; esac; done
  [ -f .vid/NUDGE ] && { echo "resume: a nudge is pending — $(cat .vid/NUDGE)"; OPEN=1; }
  if [ "$OPEN" -eq 0 ] && [ "$RUN" = complete ]; then echo 'resume: nothing open — run: complete'; fi
  exit 0
fi

# --- the tick ----------------------------------------------------------------------
mkdir -p .vid
[ -f "$HB" ] || printf '# Heartbeat — appended by checks/watchdog.sh (§8.3); newest last\n' > "$HB"
[ -f "$STF" ] || : > "$STF"
obs() { printf -- '- %s | observe: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" >> "$HB"; echo "observe: $1"; }
sget() { sed -n "s/^$1 //p" "$STF" | tail -n 1; }
sset() { grep -v "^$1 " "$STF" > "$STF.tmp" || true; [ -n "$2" ] && printf '%s %s\n' "$1" "$2" >> "$STF.tmp"; mv "$STF.tmp" "$STF"; }
# v0.9.7.0.9 (3.8): one tick at a time here — .vid/observer.lock holds the tick's pid; a live holder's
# lock is skipped, a dead holder's reclaimed (never for its age)
HM=$(pwd -P); LOCKD=.vid/observer.lock; MINE=no
while ! mkdir "$LOCKD" 2>/dev/null; do
  _lp=$(cat "$LOCKD/pid" 2>/dev/null || true)
  if [ -n "$_lp" ] && kill -0 "$_lp" 2>/dev/null; then echo "observe: skipped — a tick is running here (pid $_lp)"; exit 0; fi
  if [ -z "$_lp" ] && [ -d "$LOCKD" ]; then sleep 1; _lp=$(cat "$LOCKD/pid" 2>/dev/null || true); [ -n "$_lp" ] && continue; fi
  rm -rf "$LOCKD"
done
echo "$$" > "$LOCKD/pid"; MINE=yes
# the loop's acknowledgement (its token passed in VID_OBSERVE_LOOP), also written as the tick ends, whatever it did
fin() { [ -n "${VID_OBSERVE_LOOP:-}" ] && sset loop "${VID_OBSERVE_LOOP} $HM"; [ "$MINE" = yes ] && rm -rf "$LOCKD"; MINE=no; }
trap fin EXIT
trap 'exit 130' INT TERM HUP
# no doubled ticks: under the lock, within VID_OBSERVE_INTERVAL − 60 s of the last recorded tick nothing is recorded
_lt=$(sget tick); [ "${_lt#* }" = "$HM" ] || _lt=''   # only a tick recorded for this home (a copied state's is none)
_lt=${_lt%% *}
case "$_lt" in ''|*[!0-9]*) _lt='' ;; esac
if [ -z "${VID_OBSERVE_FORCE:-}" ] && [ -n "$_lt" ] && [ "$NOW" -ge "$_lt" ] && [ $((NOW - _lt)) -lt $((INT - 60)) ]; then
  echo "observe: skipped — the last tick here was $((NOW - _lt))s ago (interval ${INT}s); sh checks/observe.sh tick --now forces one"; exit 0
fi
# v0.9.7.0.6 (3.3, R5); v0.9.7.0.9: every tick records itself, in both branches — its time and the home it ran for
sset tick "$NOW $HM"
sset notifier ''   # an older watcher's line (records 11 and below): nothing is sent, so none is kept
# the loop's acknowledgement as its tick begins — a tick at a large project's scale can take many minutes
[ -n "${VID_OBSERVE_LOOP:-}" ] && sset loop "${VID_OBSERVE_LOOP} $HM"
nudge() { printf '%s\n' "$1" > .vid/NUDGE; obs "nudge — $1 (answer: sh checks/watchdog.sh claim run --evidence '<what you observed>')"; }
LIVE=''   # the notice keys whose condition holds at this tick
# notify <key> <text> [resume]: once per condition until it clears — v0.9.7.0.9 (3.8, R13): a heartbeat line, nothing sent
notify() {
  LIVE="$LIVE $1 "
  [ -n "$(sget "notified.$1")" ] && return 0
  M=$2; [ "${3:-}" = resume ] && M="$M — resume from records: sh checks/observe.sh resume (in $PWD)"
  sset "notified.$1" "$NOW"; obs "notice — $M"; return 0
}
clear_note() { sset "notified.$1" ''; }
cap() { printf '%s' "$1" | awk '{ s = $0; if (length(s) > 300) s = substr(s, 1, 297) "..."; printf "%s", s }'; }

# FLAGs print every tick, whatever the run's state
FLAGS=''
CLAIM=no
[ "$RUN" = complete ] && CLAIM=yes
if [ -f "$HB" ] && grep -v '| observe: ' "$HB" | grep '^- [0-9]' | tail -n 1 | grep -iE '(^|[^a-z])complete([^a-z]|$)' | grep -viqE 'not complete|incomplete'; then CLAIM=yes; fi
FALSEC=no
if [ "$CLAIM" = yes ]; then
  CE=$( [ -f "$EV" ] && grep '^completion ' "$EV" | tail -n 1 || true)
  if [ -n "$CE" ]; then
    U=$(printf '%s\n' "$CE" | tr ' ' '\n' | sed -n 's/^unmet=//p'); G=$(printf '%s\n' "$CE" | tr ' ' '\n' | sed -n 's/^strict-gaps=//p')
    if [ "${U:-x}" != 0 ] || [ "${G:-x}" != 0 ]; then FALSEC=yes; FLAGS="${FLAGS}FLAG false-complete — the run claims completion while the latest completion record says unmet=${U:-?} strict-gaps=${G:-?}
"; fi
  elif [ -f checks/metrics.sh ]; then
    UN=$(sh checks/metrics.sh closure 2>/dev/null | awk '$1=="closure" && ($2=="contract-ambiguity"||$2=="invalid-test-evidence"||$2=="unfinished-implementation") { sub(/^n=/,"",$3); u+=$3; f=1 } END { if (f) print u+0 }')
    if [ -n "$UN" ] && [ "$UN" -gt 0 ]; then FALSEC=yes; FLAGS="${FLAGS}FLAG false-complete — the run claims completion while metrics.sh closure reports $UN unmet row(s)
"; fi
  fi
fi
for h in $(holders); do case "$h" in STALE*) FLAGS="${FLAGS}FLAG $h
" ;; esac; done
if [ -f checks/brief.sh ]; then
  for b in $BRIEFS; do [ -f "$b" ] || continue; sh checks/brief.sh "$b" --at HEAD >/dev/null 2>&1 || FLAGS="${FLAGS}FLAG stale-brief $b — a quoted block differs at HEAD
"; done
fi

# --- the owner's notices (v0.9.5 3.3, 3.5), checked in both branches -------------------
EPI=$RSAT; [ -n "$EPI" ] || EPI="line-$(printf '%s\n' "$RUNV" | cksum | cut -d' ' -f1)"
conditions() {
  case "$RUN" in waiting) STATEBIT='stopped until you answer' ;; active) STATEBIT='still going' ;; *) STATEBIT="stopped (run: $RUNV)" ;; esac
  # new questions: one notice for this tick's new lines, each keyed on its number and asked time
  NEWQ=''; NEWK=''; n=0
  for q in $QLINES; do
    qn=$(printf '%s\n' "$q" | sed 's/^- \(Q[0-9]*\) · .*/\1/'); qa=$(printf '%s\n' "$q" | sed 's/^- Q[0-9]* · asked \([^ ]*\) · .*/\1/')
    qg=$(printf '%s\n' "$q" | sed 's/^- Q[0-9]* · asked [^ ]* · gates \([^·]*\) · .*/\1/;s/[[:space:]]*$//'); qt=$(printf '%s\n' "$q" | sed 's/^- Q[0-9]* · asked [^ ]* · gates [^·]* · //')
    k="q.$qn.$qa"; LIVE="$LIVE $k "
    [ -n "$(sget "notified.$k")" ] && continue
    n=$((n + 1)); NEWK="$NEWK
$k"; NEWQ="$NEWQ${NEWQ:+; }$qn: $(cap "$qt") — it holds up $qg"
  done
  if [ "$n" -gt 0 ]; then
    if [ "$n" -eq 1 ]; then T1="ViD: a question is waiting — ${NEWQ#*: }; the build is $STATEBIT. Answer it in the build's session."
    else T1="ViD: $n questions are waiting — $NEWQ; the build is $STATEBIT. Answer them in the build's session."; fi
    if notify "qbatch.$NOW" "$T1"; then for k in $NEWK; do [ -n "$k" ] && sset "notified.$k" "$NOW"; done; fi
  fi
  # the question list unreadable (only where RUN-STATE carries the 0.9.5 `questions:` key)
  if [ -n "$QKEY" ] && { [ "${QK:-x}" != "$NQ" ] || [ "$NQRAW" != "$NQ" ]; }; then
    notify "qlist.${QK:-x}.$NQRAW" "ViD: the build's list of questions to you can't be read, so a question may be missing from these notices. Open its session and ask what it is waiting on."
  fi
  # waiting on the owner: when the episode begins, then once a day while it lasts
  if [ "$RUN" = waiting ] && [ "$NQ" -gt 0 ]; then
    ES=$RSE; if [ "$ES" -eq 0 ]; then ES=$(sget "epstart.$EPI"); [ -n "$ES" ] || { ES=$NOW; sset "epstart.$EPI" "$NOW"; }; fi
    DAY=$(( (NOW - ES) / 86400 )); LIST=''
    for q in $QLINES; do LIST="$LIST${LIST:+; }$(cap "$(printf '%s\n' "$q" | sed 's/^- \(Q[0-9]*\) · asked [^ ]* · gates [^·]* · /\1 /')")"; done
    notify "waiting.$EPI.$DAY" "ViD: the build has stopped until you answer: $LIST"
  fi
  # stopped for a reason — never the owner's own pause; a bare stopped is quiet's
  if [ "$RUN" = stopped ] && [ -n "$RREASON" ] && [ "$RREASON" != 'owner asked to pause' ]; then
    notify "stopped.$EPI" "ViD: the build stopped: $RREASON"
  fi
  # the record contradicted: a commit or a session line newer than the event that set waiting or stopped
  if [ "$RSE" -gt 0 ] && [ "$RUN" = "$RSS" ] && { [ "$RSS" = stopped ] || { [ "$RSS" = waiting ] && [ "$NQ" -gt 0 ]; }; }; then
    NEWER=no
    [ "$GA" != none ] && [ $((NOW - GA)) -gt "$RSE" ] && NEWER=yes
    [ "$AA" != none ] && [ $((NOW - AA)) -gt "$RSE" ] && NEWER=yes
    [ "$NEWER" = yes ] && notify "state.$EPI" "ViD: the build is working while its record says $RUNV"
  fi
  # a false completion claim
  [ "$FALSEC" = yes ] && notify false-complete "ViD: the build says complete, but the record disagrees"
  # v0.9.7.1 (3.9, R9): Codex ran out — builders paused until the owner says which tool; a job that died without a result
  if [ "$(sed -n 's/^builder-tool=//p' .vid/budget 2>/dev/null | tail -n 1)" = paused ]; then
    _rs=$(awk '$1 == "builder-tool" && $2 == "paused" { for (i = 3; i <= NF; i++) if (index($i, "reset=") == 1) r = substr($i, 7) } END { print r }' "$EV" 2>/dev/null | tr '_' ' ')
    notify codex-paused "Codex has run out of allowance (resets ${_rs:-unknown}). Builders are paused. Say 'use Claude for builders' to continue on Claude, or 'wait for Codex' to resume when it resets."
  fi
  for _j in $JOBDEAD; do notify "jobdead.$_j" "ViD: a Codex builder ($_j) stopped without a result. Open the build's session and ask it to check the job (sh checks/job.sh status $_j)." resume; done
  # v0.9.7.1 (3.9a, R14): a takeover of the builders' tests or commits still open when the next step started
  case "$TKO" in boundary*) notify "takeover.$(printf '%s' "$TKO" | cksum | cut -d' ' -f1)" "ViD: the build's manager took over the builders' tests or commits ($(printf '%s' "${TKO#boundary takeover started }" | sed 's/ at=.*//')) and has not given them back at the next step." ;; esac
  # deaths: a died event with no newer run state event, while the run is not complete
  DSTAND=0
  for d in $DIEDS; do
    ds=$(dfield "$d" 2); da=$(dfield "$d" 3); de=$(dfield "$d" 4); dr=$(dfield "$d" 5)
    [ "$RSE" -gt "$de" ] && continue
    [ "$RUN" = complete ] && continue
    [ "$ACT" -le "$de" ] && DSTAND=1
    case "$dr" in
      rate_limit|usage-limit-waiting) DT="ViD: the build hit your usage limit. It may continue by itself when the limit resets; if it hasn't, open its session and say 'continue'." ;;
      authentication_failed|billing_error|account_on_hold|oauth_org_not_allowed) DT="ViD: the build stopped because your Claude account needs attention. Fix that first, then open its session and say 'continue'." ;;
      max_output_tokens) DT="ViD: the build's last reply was cut off. Open its session and say 'continue'." ;;
      *) DT="ViD: the build stopped on a service or connection error. Once you're back online, open its session and say 'continue' — or in a terminal in $PWD: \`claude --resume $ds\`." ;;
    esac
    notify "died.$ds.$da" "$DT" resume
  done
  # gone quiet (3.3): one standing at a time, cleared by newer activity or a recorded reason
  REASONLESS=no
  case "$RUN" in active) REASONLESS=yes ;; waiting) [ "$NQ" -eq 0 ] && REASONLESS=yes ;; stopped) [ -z "$RREASON" ] && REASONLESS=yes ;; esac
  QS=$(sget quiet.standing)
  if [ -n "$QS" ]; then
    if [ "$REASONLESS" = no ] || [ "$ACT" -gt "${QS#* }" ]; then sset quiet.standing ''; QS=''; fi
  fi
  HELD=no
  if [ -f .vid/ledger.lock/holder ]; then
    _p=$(sed -n 1p .vid/ledger.lock/holder); _t=$(sed -n 3p .vid/ledger.lock/holder)
    case "$_t" in ''|*[!0-9]*) _t=0 ;; esac
    alive "$_p" && [ $((NOW - _t)) -lt "$HOLD" ] && HELD=yes
  fi
  for _h in .vid/runs/*/holder; do   # v0.9.6: a live run folder holds, as the lock does
    [ -f "$_h" ] || continue
    _p=$(sed -n 's/^pid=//p' "$_h" | head -n 1); _t=$(sed -n 's/^start=//p' "$_h" | head -n 1)
    case "$_t" in ''|*[!0-9]*) _t=0 ;; esac
    alive "$_p" && [ $((NOW - _t)) -lt "$HOLD" ] && HELD=yes
  done
  for op in $OPS; do
    _s=$(okey "$op" start); _e=$(okey "$op" envelope)
    case "$_s$_e" in ''|*[!0-9]*) continue ;; esac
    [ $((NOW - _s)) -le "$_e" ] && [ $((NOW - _s)) -lt "$HOLD" ] && HELD=yes
  done
  # v0.9.7.0.6 (3.2, R3): a quiet agent, once per quiet stretch, while the run is active or waiting
  case "$RUN" in active|waiting)
    for _a in $AGENTS; do
      [ "$(printf '%s\n' "$_a" | cut -f2)" = quiet ] || continue
      _id=$(printf '%s\n' "$_a" | cut -f1); _ag=$(printf '%s\n' "$_a" | cut -f3); _fr=$(printf '%s\n' "$_a" | cut -f4); _tk=$(printf '%s\n' "$_a" | cut -f6)
      notify "agentq.$_id.$_fr" "ViD: an agent has had no new step for $((_ag / 60)) min: ${_tk:-agent $_id}. It may be stuck. Open the build's session and ask what it is doing."
    done ;;
  esac
  # (round 1, finding 3): no run-quiet notice while any agent's current episode is working
  if [ -z "$QS" ] && [ "$REASONLESS" = yes ] && [ "$HELD" = no ] && [ "$DSTAND" -eq 0 ] && [ "$AWORK" = no ] && [ $((NOW - ACT)) -gt "$INT" ]; then
    if [ "$ACT" -gt 0 ]; then QTXT="ViD: the build has gone quiet for $(( (NOW - ACT) / 60 )) min without saying why"; else QTXT='ViD: the build has gone quiet without saying why'; fi
    QTXT="$QTXT, and it isn't waiting on an answer from you. It may have stopped by itself, it may be waiting on a permission prompt, or a network drop, sleep or a closed app stopped it. Open its session: answer any prompt, or say 'continue' — or in a terminal in $PWD: \`claude --resume ${SESSION:-<session>}\`."
    if notify "quiet.$ACT" "$QTXT" resume; then QS="quiet.$ACT $NOW"; sset quiet.standing "$QS"; fi
  fi
  [ -n "$QS" ] && LIVE="$LIVE ${QS%% *} "
  # clear what ended: every notice of these kinds whose condition no longer holds
  for k in $(sed -n 's/^notified\.\([^ ]*\) .*/\1/p' "$STF"); do
    case "$k" in q.*|qbatch.*|qlist.*|waiting.*|stopped.*|state.*|died.*|quiet.*|agentq.*|false-complete|codex-paused|jobdead.*|takeover.*) ;; *) continue ;; esac
    case "$LIVE" in *" $k "*) ;; *) clear_note "$k" ;; esac
  done
  for k in $(sed -n 's/^\(epstart\.[^ ]*\) .*/\1/p' "$STF"); do [ "$k" = "epstart.$EPI" ] || sset "$k" ''; done
  return 0
}

# --- v0.9.6 (3.15): the progress update, hourly and after a plan change ---------------
progress_tick() {
  [ -f checks/progress.sh ] && [ -f "$RS" ] || return 0
  [ "$(sed -n 's/^plan:[[:space:]]*//p' "$RS" | head -n 1 | sed 's/[[:space:]]*$//')" = required ] || return 0
  case "$RUN" in active|waiting) ;; *) return 0 ;; esac
  _lp=0; _pc=0
  if [ -f "$EV" ]; then
    _lp=$(awk "$EVAWK"' $1 == "progress" { a = lastat(); if (a != "" && ep(a) > m) m = ep(a) } END { print m + 0 }' "$EV")
    _pc=$(awk "$EVAWK"' $1 == "plan-change" { a = lastat(); if (a != "" && ep(a) > m) m = ep(a) } END { print m + 0 }' "$EV")
  fi
  _tr=''
  if [ "$_lp" -eq 0 ] || [ $((NOW - _lp)) -ge 3600 ]; then _tr=hourly; elif [ "$_pc" -gt "$_lp" ]; then _tr=plan-change; fi
  if [ -n "$_tr" ]; then
    _hl=$(sh checks/progress.sh --record --trigger "$_tr" --by observer 2>/dev/null | tail -n 1)
    _at=$(awk "$EVAWK"' $1 == "progress" { a = lastat(); n++ } END { if (a != "") print a "." n }' "$EV" 2>/dev/null)
    # v0.9.7.0.9 (3.8, R13): the headline is a notice line; nothing is sent
    if [ -n "$_hl" ] && [ -n "$_at" ]; then
      notify "progress.$_at" "ViD progress — $_hl"
      for _k in $(sed -n 's/^\(notified\.progress\.[^ ]*\) .*/\1/p' "$STF"); do [ "$_k" = "notified.progress.$_at" ] || sset "$_k" ''; done
    fi
  fi
  sset progress.pending ''   # an undelivered update of an older watcher: nothing is sent now
  return 0
}

# --- v0.26.10.3 (R6): the drop alarm — passing rows falling sharply, with their causes ---------------------------
# For a run with `plan: required`, each tick reads every row's state (checks/evidence.sh rows over checks/plan.sh map
# --all) and keeps, in .vid/observer.passing, one line per tick of the last 60 minutes: `<epoch> <HH:MM> <passing>
# <ids,…>`. When passing has fallen by 20 rows or more against the highest count among them, it writes one notice,
# keyed on the drop's start (the tick of that high), and records the drop in .vid/observer.drop (`<epoch> <HH:MM>
# <A> <B> <ids at B>`). A further notice comes only when passing falls a further 20 below that notice's B (its causes
# then counted from B's set), or after passing has recovered to within 20 of the drop's high (the drop ends) and
# falls again. The causes, from the rows that lost passing (in the earlier set, not in the current one), each counted
# once, in the first that applies: an `amended` for it since the earlier tick (X, with its commits); its state now red
# (Y); now stale for another reason (Z); now held (H); anything else (O) — so the parts add up to A − B. Counts only.
drop_tick() {
  [ -f checks/evidence.sh ] && [ -f checks/plan.sh ] && [ -f "$RS" ] || return 0
  [ "$(sed -n 's/^plan:[[:space:]]*//p' "$RS" | head -n 1 | sed 's/[[:space:]]*$//')" = required ] || return 0
  _dt=$(mktemp -d) || return 0
  sh checks/plan.sh map --all > "$_dt/map" 2> /dev/null && [ -s "$_dt/map" ] || { rm -rf "$_dt"; return 0; }
  sh checks/evidence.sh rows --at HEAD --map "$_dt/map" > "$_dt/states" 2> /dev/null || { rm -rf "$_dt"; return 0; }
  _hm=$(awk -v e="$NOW" 'BEGIN { s = e % 86400; printf "%02d:%02d", int(s / 3600), int((s % 3600) / 60) }')
  _ids=$(awk -F'\t' '$2 == "pass" { print $1 }' "$_dt/states" | sort | paste -sd, -)
  _np=$(awk -F'\t' '$2 == "pass"' "$_dt/states" | grep -c . || true)
  PF=.vid/observer.passing; DF=.vid/observer.drop
  { [ -f "$PF" ] && awk -v now="$NOW" '$1 + 0 >= now - 3600 && $1 + 0 < now' "$PF"; printf '%s %s %s %s\n' "$NOW" "$_hm" "$_np" "${_ids:--}"; } > "$PF.tmp" && mv "$PF.tmp" "$PF"
  # the earlier snapshot a notice compares with: the drop's B when one stands, else the window's high (its latest tick)
  _cmp=''
  if [ -s "$DF" ]; then
    IFS=' ' read -r _de _dh _da _db _dids < "$DF"
    if [ "$_np" -gt $((_da - 20)) ]; then : > "$DF"; for _k in $(sed -n 's/^\(notified\.drop\.[^ ]*\) .*/\1/p' "$STF"); do sset "$_k" ''; done   # recovered: the drop ends
    elif [ "$_np" -le $((_db - 20)) ]; then _cmp="$_de $_dh $_db $_dids"; fi
  fi
  if [ ! -s "$DF" ] && [ -z "$_cmp" ]; then
    _cmp=$(awk '{ if ($3 + 0 >= m) { m = $3 + 0; l = $0 } } END { print l }' "$PF")
    set -- $(printf '%s\n' "$_cmp" | tr ' ' '\n'); [ $# -ge 3 ] && [ $(($3 - _np)) -ge 20 ] || _cmp=''
  fi
  if [ -n "$_cmp" ]; then
    set -- $(printf '%s\n' "$_cmp" | tr ' ' '\n'); _ce=$1; _ch=$2; _ca=$3; _cids=${4:--}
    printf '%s\n' "$_cids" | tr ',' '\n' | grep -v '^-\?$' > "$_dt/was" || true
    printf '%s\n' "${_ids:--}" | tr ',' '\n' | grep -v '^-\?$' > "$_dt/now" || true
    _parts=$(awk -F'\t' -v ce="$_ce" -v ev="$EV" "$EVAWK"'
      FILENAME == ARGV[1] { N[$0] = 1; next }
      FILENAME == ARGV[2] { S[$1] = $2; next }
      FILENAME == ARGV[3] { if (!($0 in N)) L[$0] = 1; next }
      END { while ((getline line < ev) > 0) { n = split(line, f, " "); if (f[1] != "amended") continue; r = ""; s = ""; a = ""
              for (i = 2; i <= n; i++) { if (index(f[i], "row=") == 1) r = substr(f[i], 5); if (index(f[i], "sha=") == 1) s = substr(f[i], 5); if (index(f[i], "at=") == 1) a = substr(f[i], 4) }
              if ((r in L) && a != "" && ep(a) >= ce + 0) { AM[r] = 1; if (!(s in SH)) { SH[s] = 1; shl = shl (shl == "" ? "" : ", ") s } } }
        for (r in L) { if (r in AM) x++; else if (S[r] == "red") y++; else if (S[r] == "stale") z++; else if (S[r] == "held") h++; else o++ }
        out = ""; if (x) out = out ", " x " reset by an amendment (commits " shl ")"; if (y) out = out ", " y " now red"; if (z) out = out ", " z " not re-run since a test change"
        if (h) out = out ", " h " held"; if (o) out = out ", " o " other"; print substr(out, 3) }' "$_dt/now" "$_dt/states" "$_dt/was")
    notify "drop.$_ce" "ViD: passing rows fell from $_ca to $_np since $_ch UTC: $_parts. Open the session and ask what changed."
    if [ -s "$DF" ]; then IFS=' ' read -r _de _dh _da _db _dids < "$DF"; else _da=$_ca; fi
    printf '%s %s %s %s %s\n' "$NOW" "$_hm" "$_da" "$_np" "${_ids:--}" > "$DF"
  fi
  rm -rf "$_dt"; return 0
}

OPS=$(ops)
if [ "$RUN" != active ] && [ -z "$OPS" ]; then
  if [ "$(sget idle)" != 1 ]; then obs "idle — run: $RUN, nothing declared; silent until a run or an operation begins, but for the owner's notices"; sset idle 1; fi
  for f in $FLAGS; do obs "$f"; done
  progress_tick
  drop_tick
  conditions
  exit 0
fi
sset idle ''

if [ "$ACT" -gt 0 ]; then ACTL="run activity $((NOW - ACT))s ago ($ACTS)"; else ACTL='run activity: none recorded'; fi
if [ "$GA" = none ]; then GAL='last commit: none'; else GAL="last commit ${GA}s ago"; fi
obs "$ACTL · $GAL · run: $RUN${SLICE:+ · slice $SLICE}"
obs "$(receipt_line)"
for h in $(holders); do case "$h" in live*) obs "$h" ;; esac; done
if [ -f checks/extractors/memory.sh ]; then
  FM=$(sh checks/extractors/memory.sh 2>/dev/null | sed -n 's/^free-mb //p' | head -n 1)
  HR=$( [ -f .vid/budget ] && sed -n 's/^memory-headroom-mb=\([0-9]*\).*/\1/p' .vid/budget | head -n 1 || true)
  if [ -n "$FM" ]; then obs "memory free ${FM} MB${HR:+ against a headroom of $HR MB}$( [ -n "$HR" ] && [ "$FM" -lt "$HR" ] && echo ' — BELOW the headroom (reported, never enforced)')"; fi
fi
for f in $FLAGS; do obs "$f"; done

progress_tick
drop_tick
conditions
QSTAND=$(sget quiet.standing)

# declared operations govern
for op in $OPS; do
  S0=$(okey "$op" start); E0=$(okey "$op" envelope)
  case "$S0$E0" in ''|*[!0-9]*) obs "operation $op carries an envelope that is not whole seconds ('$E0') — re-declare it"; continue ;; esac
  if [ $((NOW - S0)) -le "$E0" ]; then sset "fail.$op" ''; clear_note "op.$op"; continue; fi
  RC=0; VID_OBSERVER=1 sh checks/watchdog.sh check "$op" >/dev/null 2>&1 || RC=$?
  if [ "$RC" -eq 2 ] || [ "$RC" -eq 0 ]; then
    obs "operation $op overdue — its probe answered (reported, never escalated)"; sset "fail.$op" ''; clear_note "op.$op"; continue
  fi
  N=$(sget "fail.$op"); N=$(( ${N:-0} + 1 )); sset "fail.$op" "$N"
  obs "operation $op overdue — its probe FAILED (exit $RC), tick $N in a row"
  [ "$N" -eq 2 ] && nudge "declared operation $op failed its probe on two successive ticks"
  if [ "$N" -ge 3 ]; then
    if [ -n "$QSTAND" ]; then obs "operation $op: its notice is held while the quiet notice stands"
    else notify "op.$op" "ViD: declared operation $op failed its probe on $N successive ticks — the system itself is the finding"; fi
  fi
done
exit 0

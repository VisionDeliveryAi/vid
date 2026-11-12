#!/bin/sh
# Purpose: the ticket side's shared helpers (0.26.10.28.4, 9.3 R3, R4, M3, M4), each once: put, the settings reader, the plan-block reader, the
# row-range expander, date to seconds, the timestamp, the event writer and the lock. Each of the 13 ticket scripts, and decisions.sh, loads it from
# beside itself, `. "$HERE/lib.sh"`, after setting HERE; loaded, it defines and runs nothing else. plan.sh and develop's own scripts keep their own.
# serves: tickets
# put <file>: stdin into a dot file beside it, then renamed in, so a record is replaced whole and never emptied first (0.26.10.28.1, F3)
put() { _p=$(dirname "$1")/.put.$$.$(basename "$1"); cat > "$_p" && mv -f "$_p" "$1"; }
# skey <key>: .vid/tw/settings' value of `<key>:`, its trailing space trimmed; twkey, the same
skey() { sed -n "s/^$1:[[:space:]]*//p" .vid/tw/settings 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//'; }
twkey() { skey "$1"; }
# plan_block [<RUN-STATE>]: the vid-plan block's lines under "## The plan", strict fence, trailing space trimmed: plan.sh's `block`, whose hash is the plan's
plan_block() { [ -f "${1:-.vid/RUN-STATE.md}" ] || return 0; awk '/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b { print }' "${1:-.vid/RUN-STATE.md}" | sed 's/[[:space:]]*$//'; }
# rkey: the round's refusal key: the plan block, the handed record and the newest tw-sync's main (0.26.10.28.2, R4), so a refusal is tried again once one
# changes; round.sh's refusals and queue.sh's count of the steps waiting read the one key
rkey() { { plan_block; cat .vid/tw/handed 2>/dev/null; sed -n 's/^sync main=\([^ ]*\) .*/\1/p' .vid/tw/log 2>/dev/null | tail -n 1; } | cksum | tr -d ' '; }
# RNG: the awk function rng(<id or range>), its ids space-separated: <P>-<a>..<P>-<b> written out at a's width, as the plan reads it; prepended to an awk program
RNG='function rng(y,   a, b, p, lo, hi, w, k, r) { if (y !~ /\.\./) return y; a = y; sub(/\.\..*/, "", a); b = y; sub(/.*\.\./, "", b); p = a; sub(/-[0-9]+$/, "", p)
  lo = a; sub(/^.*-/, "", lo); hi = b; sub(/^.*-/, "", hi); w = length(lo); r = ""; for (k = lo + 0; k <= hi + 0; k++) r = r (r == "" ? "" : " ") sprintf("%s-%0" w "d", p, k); return r }'
# epoch <UTC ISO time>: its seconds, BSD's date or GNU's, else 0
epoch() { date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0; }
# stamp, now: the UTC time, ISO
stamp() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
now() { stamp; }
# ev <event line>: through the event.sh beside this file, at the run's home; a failure of event.sh is reported, never written past (9.3 R1, M1)
ev() { sh "$HERE/event.sh" "$1" > /dev/null || echo "ViD: the event was not recorded, event.sh failed: $1" >&2; }
# The lock (9.3 R4, M4): a folder naming its holder in one file, h, written whole and renamed in: `<pid> <start>`, its start as DevAgent's run.sh
# stamp writes one (/proc where it is: boot id and ticks, Git Bash seconds; else ps), so a reader never takes one holder's pid with another's start. A
# holder that is gone, or whose pid another process now has, is no holder: its lock is taken over by one waiter at a time (<folder>.steal), which reads
# h again before it removes anything. A live holder's lock is never taken: lock_take waits for it
pstamp() { if [ -r "/proc/$1/stat" ]; then _t=$(sed 's/^.*) //' "/proc/$1/stat" | cut -d' ' -f20); case $(uname -s) in MINGW*|MSYS*|CYGWIN*) _b=$(sed -n 's/^btime //p' /proc/stat 2>/dev/null); echo $((${_b:-0} + _t / $(getconf CLK_TCK))) ;; *) echo "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null):$_t" ;; esac; else LC_ALL=C TZ=UTC0 ps -o lstart= -p "$1" 2>/dev/null; fi; }   # one locale and one time zone for every reader
# palive <pid> <start>: it lives and is the process that start names (under Git Bash, within the second the two round to)
palive() { kill -0 "$1" 2>/dev/null || return 1; _s=$(pstamp "$1"); [ -n "$_s" ] || return 1; [ "$_s" = "$2" ] && return 0
  case $(uname -s) in MINGW*|MSYS*|CYGWIN*) case $2$_s in *[!0-9-]*) return 1 ;; esac; [ $((_s - $2)) -ge -1 ] && [ $((_s - $2)) -le 1 ] ;; *) return 1 ;; esac; }
lage() { [ -n "$(find "$1" -prune -mmin +1 2>/dev/null)" ]; }
# lheld <folder>: a live holder holds it, or one is still naming itself (a lock younger than a minute with no h yet)
lheld() { [ -d "$1" ] || return 1; _hl=$(cat "$1/h" 2>/dev/null || true); if [ -n "${_hl#* }" ] && [ "${_hl#* }" != "$_hl" ]; then palive "${_hl%% *}" "${_hl#* }"; else ! lage "$1"; fi; }   # a start not read is no start: held a minute
# lclear <folder>: under its guard, <folder>.steal, which names its clearer as a lock names its holder and is removed only once that clearer is gone
# (never for its age alone), renamed first so no fresh guard goes; a lock gone or renamed meanwhile is no dead one
lclear() { if mkdir "$1.steal" 2>/dev/null; then echo "$$ $(pstamp $$)" > "$1.steal/h" 2>/dev/null; _h0=$(cat "$1/h" 2>/dev/null || true)
    if [ -d "$1" ] && ! lheld "$1" && [ "$(cat "$1/h" 2>/dev/null || true)" = "$_h0" ]; then rm -rf "$1"; fi; rm -rf "$1.steal"
  elif ! lheld "$1.steal" && mv "$1.steal" "$1.steal.$$" 2>/dev/null; then rm -rf "$1.steal.$$"; fi; }
# lock_take <folder> [<seconds>]: 0 once held; 1 when a live holder keeps it past the seconds (60)
lock_take() { _l=$1; _w=${2:-60}; _n=0; while :; do
    if mkdir "$_l" 2>/dev/null; then { echo "$$ $(pstamp $$)" > "$_l/.h.$$" && mv -f "$_l/.h.$$" "$_l/h"; } 2>/dev/null && [ "$(cut -d' ' -f1 "$_l/h" 2>/dev/null)" = "$$" ] && return 0; continue; fi
    [ ! -d "$_l" ] || lheld "$_l" || { lclear "$_l"; [ -d "$_l" ] || continue; }; [ "$_n" -lt "$_w" ] || return 1; sleep 1; _n=$((_n + 1)); done; }   # a lock not cleared waits, counted
# lock_free <folder>: its holder's alone
lock_free() { [ "$(cut -d' ' -f1 "$1/h" 2>/dev/null)" != "$$" ] || rm -rf "$1"; }
# rs_edit <command> [<arg>…] (9.3 R2, M2): the run record's one writer on the ticket side. Under its lock (.vid/run-state.lock), the command reads the
# current .vid/RUN-STATE.md on stdin and prints it as it should be; written through put when it succeeded, printed something and changed. Each writer
# reads the record inside the lock, so two at once each get their change in and neither is lost
rs_edit() { _rl=.vid/run-state.lock; lock_take "$_rl" 60 || { echo "ViD: the run record's lock is held by a live process ($(cut -d' ' -f1 "$_rl/h" 2>/dev/null)); RUN-STATE.md not written" >&2; return 1; }
  _rt=.vid/.rs.$$; _rr=1; if "$@" < .vid/RUN-STATE.md > "$_rt" && [ -s "$_rt" ]; then _rr=0; cmp -s "$_rt" .vid/RUN-STATE.md || put .vid/RUN-STATE.md < "$_rt" || _rr=1; fi
  rm -f "$_rt"; lock_free "$_rl"; return $_rr; }

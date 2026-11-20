#!/bin/sh
# Purpose: selftest case — a record is replaced, never emptied first (v0.26.10.28.1, R6). After `printf x | put r`, r holds x, its inode
# changed (a rename), and no .put.* file is left. lib.sh holds that put line, its rename through mvr (0.26.11.1.4, R6), and mvr's line once, byte for byte, no ticket script defines put again, and every
# ticket-side script that writes a record loads lib.sh (0.26.10.28.4).
# A producer that fails stops the script with the record whole: in decide.sh, inside hset, reached through the accept ruling's `||`
# path (its $T/h made a folder, so the write into it fails), .vid/tw/handed is left as it was and the line after it never prints; in
# queue.sh, which has no -e, at the top level (control pause, its RUN-STATE.md unreadable as a file), it is left as it was and nothing after it
# runs. results.sh's stand-in-pr-<n>.txt, rebuilt at every read, is never seen other than whole by a reader looping through the
# reads. Env: CHECKS.
set -eu
T=$(mktemp -d); W=''; trap '[ -z "$W" ] || kill "$W" 2>/dev/null; rm -rf "$T"' EXIT
fail() { echo "put-record: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
PUT='put() { _p=$(dirname "$1")/.put.$$.$(basename "$1"); cat > "$_p" && mvr "$_p" "$1"; }'
MVR='mvr() { _mn=1; until mv -f "$1" "$2"; do [ "$_mn" -lt 5 ] || return 1; _mn=$((_mn + 1)); sleep 1; done; }'
eval "$MVR"; eval "$PUT"
# the helper: content, a new inode, nothing left beside it
mkdir "$T/a"; printf 'old\n' > "$T/a/r"; i0=$(ls -i "$T/a/r" | awk '{ print $1 }')
printf x | put "$T/a/r"; [ "$(cat "$T/a/r")" = x ] || fail "put left: $(cat "$T/a/r")"
i1=$(ls -i "$T/a/r" | awk '{ print $1 }'); [ "$i0" != "$i1" ] || fail 'put wrote in place: the inode is the same'
[ -z "$(ls -A "$T/a" | grep '^\.put\.' || true)" ] || fail "put left a file beside the record: $(ls -A "$T/a")"
# the line once, in lib.sh (0.26.10.28.4, 9.3 R3); no ticket script defines put, and those that write records load lib.sh
[ "$(grep -cxF "$PUT" "$CHECKS/lib.sh" || true)" = 1 ] || fail 'checks/lib.sh does not hold the put line once, byte for byte'
[ "$(grep -cxF "$MVR" "$CHECKS/lib.sh" || true)" = 1 ] || fail 'checks/lib.sh does not hold the mvr line once, byte for byte (0.26.11.1.4, R6)'
for s in decide land close queue results round writer planner walk grade end github; do ! grep -qE '(^|[;{ ]) *put\(\) *\{' "$CHECKS/$s.sh" || fail "checks/$s.sh defines put again"
  grep -qxF '. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file' "$CHECKS/$s.sh" || fail "checks/$s.sh does not load lib.sh"; done
# a stub mktemp: decide.sh's temporary folder holds h as a folder, so hset's write into it fails
MK=$(command -v mktemp); mkdir "$T/stub"
cat > "$T/stub/mktemp" <<EOF
#!/bin/sh
d=\$("$MK" "\$@") || exit 1
case "\$d" in */.vid/decide/tmp.*) mkdir "\$d/h" ;; esac
echo "\$d"
EOF
chmod +x "$T/stub/mktemp"
mkdir -p "$T/d/.vid/decide" "$T/d/.vid/tw"; cd "$T/d"
printf 'ROW-001\theld\tevidence missing\t4\tabcdef123456\t2026-11-11T10:00:00Z\n' > .vid/decide/state
printf 'ROW-001\tROW-001\t-\theld\t-\t-\t0\tpassed\t-\t0\t-\n' > .vid/decide/pr-4-abcdef123456.rows
printf 'ROW-001\n' > .vid/decide/record; printf 'row ROW-001 held | stand-in: decision\nrow ROW-002 accepted | stand-in: decision\n' > .vid/tw/handed; cp .vid/tw/handed "$T/handed"
RC=0; PATH="$T/stub:$PATH" sh "$CHECKS/decide.sh" rule ROW-001 accept > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'decide.sh went on past a failed write in hset'
! grep -q '^recorded: ' "$T/out" || fail 'the line after hset ran: the script did not stop'
cmp -s .vid/tw/handed "$T/handed" || fail "the handed record changed: $(cat .vid/tw/handed)"
# queue.sh, no -e: control pause at the top level, its write through the run record's writer (0.26.10.28.4, R2) failing where it reads the
# record: RUN-STATE.md a folder, as on every host
mkdir -p "$T/q/.vid/decide/queue" "$T/q/.vid/tw" "$T/q/.vid/RUN-STATE.md"; cd "$T/q"; printf 'labels-prefix:\n' > .vid/tw/settings; : > .vid/RUN-STATE.md/kept
RC=0; sh "$CHECKS/queue.sh" control pause 'hold on' > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'queue.sh went on past a failed write'; ! grep -q '^run: ' "$T/out" || fail 'the line after the write ran: the script did not stop'
[ -d .vid/RUN-STATE.md ] && [ -f .vid/RUN-STATE.md/kept ] || fail 'RUN-STATE.md changed'; ! grep -q 'control:pause' .vid/decide/queue/answers 2>/dev/null || fail 'the answer after the write was recorded'
[ ! -e .vid/run-state.lock ] || fail "the run record's lock was left after a failed write"
# results.sh: the stand-in record rebuilt at each read, watched by a reader the whole time
. "$CHECKS/selftest/fixtures/results-reports.sh"
R=$CHECKS/results.sh; rr_project; rr_good
sh "$R" read --ticket 3 --pr 4 --head "$RR_H" > "$T/out" 2>&1 || fail 'the first read failed'
O=.vid/results/stand-in-pr-4.txt; E=$(cat "$O"); [ -n "$E" ] || fail 'no stand-in line to watch'
( while [ -d "$T" ] && [ ! -f "$T/stop" ]; do c=$(cat "$O" 2>/dev/null) || c='(absent)'; [ "$c" = "$E" ] || printf '[%s]\n' "$c" >> "$T/seen"; done ) &
W=$!
for i in 1 2 3 4 5 6 7 8; do sh "$R" read --ticket 3 --pr 4 --head "$RR_H" > "$T/out" 2>&1 || fail "read $i failed"; done
: > "$T/stop"; wait "$W" 2>/dev/null || true; W=''
[ ! -s "$T/seen" ] || fail "a reader saw the stand-in record other than whole: $(head -n 3 "$T/seen" | tr '\n' ' ')"
[ "$(cat "$O")" = "$E" ] || fail "the stand-in record changed: $(cat "$O")"
[ -z "$(ls -A .vid/results | grep '^\.put\.' || true)" ] || fail 'a .put file is left beside the stand-in record'
exit 0

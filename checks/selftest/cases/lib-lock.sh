#!/bin/sh
# Purpose: selftest case — one lock on ViD's side (0.26.10.28.4, 9.3 R4, M4), lib.sh's lock_take and lock_free. A dead holder's lock is taken over; so is
# one whose pid another process has since taken. A live holder's lock is waited on, and taken once it is freed; past the wait it is not taken. Eight
# takers at once, over a dead holder's lock, hold it one at a time. lock_free frees only its holder's. decisions.sh next takes the decision-id lock
# from a dead holder with no person, and leaves none behind; a live holder's it still waits on, and refuses after its wait. Env: CHECKS.
set -eu
T=$(mktemp -d); Z=''; trap 'for p in $Z; do kill "$p" 2>/dev/null || true; done; rm -rf "$T"' EXIT
fail() { echo "lib-lock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
HERE=$CHECKS; . "$CHECKS/lib.sh"; L=$T/l.lock
sh -c 'exit 0' & dp=$!; wait "$dp" || true
# a dead holder's
mkdir "$L"; echo "$dp a start long gone" > "$L/h"; lock_take "$L" 2 || fail "a dead holder's lock was not taken"; [ "$(cat "$L/h")" = "$$ $(pstamp $$)" ] || fail 'the lock does not name its new holder and its start'
lock_free "$L"; [ ! -e "$L" ] || fail 'lock_free left the lock'
# a live pid, its start not the holder's: no holder
sleep 300 & lp=$!; Z="$Z $lp"; mkdir "$L"; echo "$lp another start" > "$L/h"; lock_take "$L" 2 || fail 'a lock on a pid another process took was not taken'; lock_free "$L"
# a live holder: waited on, taken once freed; past the wait, not taken
mkdir "$L"; echo "$lp $(pstamp "$lp")" > "$L/h"; RC=0; lock_take "$L" 2 || RC=$?; [ "$RC" = 1 ] && [ "$(cut -d' ' -f1 "$L/h")" = "$lp" ] || fail "a live holder's lock was taken: $RC"
( sleep 2; rm -rf "$L" ) & fp=$!; t0=$(date +%s); lock_take "$L" 20 || fail 'a freed lock was not taken'; [ $(($(date +%s) - t0)) -ge 1 ] || fail 'a live lock was not waited on'; wait "$fp" || true; lock_free "$L"
# a holder stamped under another locale is still its own (macOS reads ps lstart, which a locale changes)
if [ ! -r /proc/$$/stat ] && locale -a 2>/dev/null | grep -qx 'de_DE.UTF-8'; then ( HERE=$CHECKS; . "$CHECKS/lib.sh"; LC_ALL=de_DE.UTF-8; export LC_ALL; lock_take "$L" 2; sleep 4; lock_free "$L" ) & hp=$!; sleep 1
  RC=0; ( LC_ALL=C; export LC_ALL; lock_take "$L" 1 ) || RC=$?; [ "$RC" = 1 ] || fail "a holder stamped under another locale lost its lock: $RC"; wait "$hp" || true; fi
# and one stamped under another time zone
if [ ! -r /proc/$$/stat ]; then ( HERE=$CHECKS; . "$CHECKS/lib.sh"; TZ=UTC0; export TZ; lock_take "$L" 2; sleep 4; lock_free "$L" ) & hp=$!; sleep 1
  RC=0; ( TZ=Asia/Tokyo; export TZ; lock_take "$L" 1 ) || RC=$?; [ "$RC" = 1 ] || fail "a holder stamped under another time zone lost its lock: $RC"; wait "$hp" || true; fi
# a holder whose start could not be read is held a minute, not taken at once
mkdir "$L"; echo "$lp " > "$L/h"; RC=0; lock_take "$L" 1 || RC=$?; [ "$RC" = 1 ] || fail "a holder named with no start was taken at once: $RC"; rm -rf "$L"
# a clearer's guard held by a live clearer stays, whatever its age; a dead clearer's goes
sleep 300 & cp=$!; Z="$Z $cp"; mkdir "$L" "$L.steal"; echo "$dp gone" > "$L/h"; echo "$cp $(pstamp "$cp")" > "$L.steal/h"; touch -t 202001010000 "$L.steal"; RC=0; lock_take "$L" 1 || RC=$?
[ "$RC" = 1 ] && [ -d "$L.steal" ] || fail "a live clearer's old guard was removed: $RC"; echo "$dp gone" > "$L.steal/h"; lock_take "$L" 3 || fail "a dead clearer's guard kept the lock"; lock_free "$L"; [ ! -e "$L.steal" ] || fail 'the guard was left'
# lock_free frees its holder's alone
mkdir "$L"; echo "$lp $(pstamp "$lp")" > "$L/h"; lock_free "$L"; [ -d "$L" ] || fail "lock_free freed another's lock"; rm -rf "$L"
# eight at once over a dead holder's lock: one at a time
mkdir "$L"; echo "$dp gone" > "$L/h"; Q=''
for i in 1 2 3 4 5 6 7 8; do ( HERE=$CHECKS; . "$CHECKS/lib.sh"; lock_take "$L" 30 || exit 1; echo "in $i" >> "$T/log"; n=$(ls "$T" | grep -c '^in-' || true); : > "$T/in-$i"; [ "$n" = 0 ] || echo "overlap $i" >> "$T/log"; sleep 1; rm -f "$T/in-$i"; lock_free "$L" ) & Q="$Q $!"; done
for q in $Q; do wait "$q" || fail 'a taker was refused'; done; [ "$(grep -c '^in ' "$T/log")" = 8 ] && ! grep -q '^overlap' "$T/log" || fail "the eight: $(tr '\n' ' ' < "$T/log")"
# decisions.sh next: a dead holder's decision-id lock taken with no person, none left; a live holder's waited on
mkdir -p "$T/p/checks" && cd "$T/p" && git init -q && cp "$CHECKS/decisions.sh" "$CHECKS/lib.sh" checks/ && mkdir -p .vid
mkdir .vid/decision-ids.lock; echo "$dp gone" > .vid/decision-ids.lock/h
id=$(sh checks/decisions.sh next 2> "$T/out") || fail 'decisions.sh next refused a dead holder lock'; [ "$id" = D-001 ] || fail "decisions.sh next: $id"; [ ! -e .vid/decision-ids.lock ] || fail 'the decision-id lock was left'
mkdir .vid/decision-ids.lock; echo "$lp $(pstamp "$lp")" > .vid/decision-ids.lock/h; ( sleep 2; rm -rf .vid/decision-ids.lock ) & fp=$!
id=$(sh checks/decisions.sh next 2> "$T/out") || fail 'decisions.sh next did not wait for a live holder'; [ "$id" = D-002 ] || fail "decisions.sh next after the wait: $id"; wait "$fp" || true
echo 'lib-lock: ok'

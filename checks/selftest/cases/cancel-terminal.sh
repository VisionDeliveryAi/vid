#!/bin/sh
# Purpose: selftest case — a finished ticket, or a stale pid, is never signalled (v0.9.7.1 spec 3.6, R6). Two
# tickets of try t6: one `done` whose `pid` is now a live process (a reused pid), one `running` whose `pid` is
# alive but started at another time than its `pid-start`. Convicts unless `cancel --try t6` leaves the done ticket
# alone (no mark, `left alone`), marks the running one without signalling (its pid is stale), and both processes
# are alive afterwards. Env: CHECKS.
set -eu
T=$(mktemp -d); P1=''; P2=''; trap 'kill $P1 $P2 2>/dev/null; rm -rf "$T"' EXIT
fail() { echo "cancel-terminal: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; cp "$CHECKS/test.sh" checks/
D1=.vid/requests/20990101T000000Z-aaa1; D2=.vid/requests/20990101T000000Z-aaa2; mkdir -p $D1 $D2
sleep 60 & P1=$!; sleep 60 & P2=$!
printf 'type=iterate\nrole=builder\ntry=t6\n' > $D1/request; echo done > $D1/state; echo $P1 > $D1/pid; ps -o lstart= -p $P1 | sed 's/^ *//' > $D1/pid-start
printf 'type=iterate\nrole=builder\ntry=t6\n' > $D2/request; echo running > $D2/state; echo $P2 > $D2/pid; echo 'Thu Jan  1 00:00:00 1970' > $D2/pid-start
sh checks/test.sh cancel --try t6 > "$T/out" 2>&1 || fail 'cancel failed'
[ ! -f $D1/cancel ] || fail 'a done ticket was marked'
grep -q 'aaa1: done — left alone' "$T/out" || fail 'the done ticket is not said left alone'
[ -f $D2/cancel ] || fail 'the running ticket was not marked'
grep -q 'TERM sent' "$T/out" && fail 'a stale pid was signalled'
sleep 1; kill -0 $P1 && kill -0 $P2 || fail 'a process was signalled'
exit 0

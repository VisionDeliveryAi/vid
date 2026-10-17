#!/bin/sh
# Purpose: selftest case — cancelling a run served inside an agent's sandbox (v0.9.7.1 spec 3.6, R6; found in
# rehearsal R-6: there serve can't read a start time, so `pid-start` is empty). A running ticket of try t9 whose
# `pid-start` is empty and whose `pid` is the child of a process whose command is `… serve <the ticket's folder>`,
# recorded as its `supervisor`. Convicts unless `cancel --try t9` sends TERM to that child; and, the same ticket
# with a supervisor whose command names another ticket, sends nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'kill $SP1 $SP2 2>/dev/null; rm -rf "$T"' EXIT; SP1=''; SP2=''
fail() { echo "cancel-sandboxed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; cp "$CHECKS/test.sh" checks/
mk() { # <ticket> <the folder named in the supervisor's command> → SUP, KID
  D=.vid/requests/$1; mkdir -p "$D"; printf 'type=iterate\nrole=builder\ntry=t9\n' > "$D/request"; echo running > "$D/state"
  sh -c 'sleep 60 & echo $! > "$0.kid"; wait' "$T/$1" serve "$2" & SUP=$!
  i=0; while [ ! -s "$T/$1.kid" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i + 1)); done
  KID=$(cat "$T/$1.kid"); echo "$KID" > "$D/pid"; : > "$D/pid-start"; echo "$SUP" > "$D/supervisor"; }
mk 20990101T000000Z-aaa1 "$(pwd)/.vid/requests/20990101T000000Z-aaa1"; SP1=$SUP; K1=$KID
sh checks/test.sh cancel --try t9 > "$T/out" 2>&1 || fail 'cancel failed'
grep -q 'TERM sent' "$T/out" || fail 'the run of a ticket served by its own serve was not signalled'
sleep 1; kill -0 "$K1" 2>/dev/null && fail 'the child is still alive'
rm -rf .vid/requests/*
mk 20990101T000000Z-aaa2 "$(pwd)/.vid/requests/another"; SP2=$SUP; K2=$KID
sh checks/test.sh cancel --try t9 > "$T/out" 2>&1 || fail 'cancel failed'
grep -q 'TERM sent' "$T/out" && fail 'a process whose supervisor names another ticket was signalled'
kill -0 "$K2" 2>/dev/null || fail 'an unverified process was signalled'
exit 0

#!/bin/sh
# Purpose: selftest case — nothing is signalled before its trap is set (v0.9.7.1 spec 3.6, R6). A ticket whose
# state is still `queued` — its run started, its trap perhaps not yet set — with a live process at `pid` and that
# process's own start time at `pid-start`. Convicts unless `cancel --try t5` writes the mark and sends no signal:
# the process is alive afterwards; and the run, reading the mark itself, takes its own path. Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap '[ -z "$P" ] || kill "$P" 2>/dev/null; rm -rf "$T"' EXIT
fail() { echo "cancel-trap-window: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks" "$T/p/.vid/requests/20990101T000000Z-aaaa"; cd "$T/p"; cp "$CHECKS/test.sh" checks/
D=.vid/requests/20990101T000000Z-aaaa
sleep 60 & P=$!
printf 'type=iterate\nrole=builder\ntry=t5\n' > $D/request; echo queued > $D/state; echo $P > $D/pid
ps -o lstart= -p $P | sed 's/^ *//' > $D/pid-start
sh checks/test.sh cancel --try t5 > "$T/out" 2>&1 || fail 'cancel failed'
[ -f $D/cancel ] || fail 'no mark'
sleep 1; kill -0 $P 2>/dev/null || fail 'a queued ticket'"'"'s process was signalled'
exit 0

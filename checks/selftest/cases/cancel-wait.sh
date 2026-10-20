#!/bin/sh
# Purpose: selftest case — `cancelled` is terminal in `wait` (v0.9.7.1 spec 3.6, R6). A ticket folder already
# `cancelled` with its exit 77 and result. Convicts unless `wait` prints the result at once and exits 77 (not 75,
# not the run's 130), and a ticket marked but not yet ended is still reported pending (75). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "cancel-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; cp "$CHECKS/test.sh" checks/
D=.vid/requests/20990101T000000Z-bbbb; mkdir -p $D
printf 'type=iterate\nrole=builder\ntry=t1\nestimate=10\nsilence=1200\nstartup=3600\nlimit=86400\ncreated=%s\n' "$(date +%s)" > $D/request
echo cancelled > $D/state; echo 77 > $D/exit; printf 'cancelled by run-manager\nstatus=77 ran-to-end=no capped=no report=none\n' > $D/result
S0=$(date +%s); RC=0; VID_WAIT_MAX=20 sh checks/test.sh wait 20990101T000000Z-bbbb > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 77 ] || fail "wait exited $RC, not 77"
[ $(( $(date +%s) - S0 )) -le 3 ] || fail 'wait did not return at once'
sed -n 1p "$T/out" | grep -qx 'cancelled by run-manager' || fail 'the result is not printed'
echo queued > $D/state; rm $D/exit $D/result; printf 'by=x\n' > $D/cancel
RC=0; VID_WAIT_MAX=2 sh checks/test.sh wait 20990101T000000Z-bbbb > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 75 ] || fail "a marked, unfinished ticket exited $RC, not 75"
exit 0

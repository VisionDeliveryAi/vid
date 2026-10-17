#!/bin/sh
# Purpose: selftest case — a green pass keeps today's tail (v0.9.8.1 R27). A gated request whose pass is green, on a
# stack logging 30,000 lines, keeps timeline.inline.log taken with --tail (the stub's last lines), and writes no
# timeline.inline.log.gz. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "timeline-green-tail: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
: > "$STUB_LOG"
STUB_LOG_LINES=30000 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a green pass' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the green run did not pass'
waitfor ".vid/requests/$TK/timeline.inline.log" 60 || fail 'no timeline.inline.log'
grep -qx 'logs-tail=yes' "$STUB_LOG" || fail 'the green timeline was not taken with a tail'
[ ! -f ".vid/requests/$TK/timeline.inline.log.gz" ] || fail 'a green pass kept the whole compressed timeline'
exit 0

#!/bin/sh
# Purpose: selftest case — a capped pass keeps its logs (v0.9.8.1 R44, F-36, widening R27). A held request stopped
# by its watcher on 5 s of silence (v0.26.10.4; was a 4 s cap): before its down, its ticket keeps the whole timeline (timeline.inline.log.gz, no tail, every line
# the stack printed) and each service's last 200 lines (last-lines.inline.log, a --tail 200), and both outlive the
# run folder. A cancelled running request keeps them the same way. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "timeline-capped-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export STUB_LOG_LINES=300 STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
kept_logs() { # <ticket dir> <what>
  [ -s "$1/timeline.inline.log.gz" ] || fail "the $2 pass kept no whole timeline"
  [ "$(gzip -dc "$1/timeline.inline.log.gz" | grep -c ' line [0-9]* of the stack ')" -eq 300 ] || fail "the $2 pass's timeline is not whole"
  [ -s "$1/last-lines.inline.log" ] && grep -q '^stub-logs ' "$1/last-lines.inline.log" || fail "the $2 pass kept no last lines"
  [ -z "$(ls .vid/runs 2>/dev/null)" ] || fail "the $2 pass's run folder was kept"
  awk '/^logs-tail=no$/ { w = NR } /^logs-tail=yes$/ { l = NR } /^[^|]*\|.* down( |$)/ { if (!d) d = NR } END { exit !(w && l && d && w < d && l < d) }' "$STUB_LOG" ||
    fail "the $2 pass's logs were not taken (whole and --tail) before its down"
}
touch "$T/hold"; : > "$STUB_LOG"
VID_SILENCE_SECONDS=5 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'capped' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || true
[ "$(cat ".vid/requests/$A/state")" = capped ] || fail 'the run was not capped'
kept_logs ".vid/requests/$A" capped
touch "$T/hold"; rm -f "$T/entered"; : > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'cancelled' -- tests/b > "$T/out" 2>&1 || fail 'the second request was refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); waitfor "$T/entered" || fail 'the second request did not start'
sh checks/test.sh cancel --ticket "$B" --by selftest > "$T/out" 2>&1 || fail 'the cancel failed'
VID_WAIT_MAX=60 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || true
[ "$(cat ".vid/requests/$B/state")" = cancelled ] || fail 'the second request was not cancelled'
kept_logs ".vid/requests/$B" cancelled
exit 0

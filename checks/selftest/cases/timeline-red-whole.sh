#!/bin/sh
# Purpose: selftest case — a red pass keeps its whole timeline (v0.9.8.1 R27, F-16). A gated request whose pass is red
# (a failed case, exit 1) on a stack logging 30,000 lines keeps timeline.inline.log.gz, taken with no --tail and
# before its teardown: uncompressed it holds every line, the first and the last; no plain timeline.inline.log is left.
# With VID_TIMELINE_CAP far below the compressed size, the file is cut: its first line says so, its last line is the
# stack's last, and the run's log says it was cut. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "timeline-red-whole: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
red() { : > "$STUB_LOG"
  STUB_CASE=failed STUB_STATUS=1 STUB_LOG_LINES=30000 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$1" -- tests/x > "$T/out" 2>&1 || fail "the request '$1' was refused"
  TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
  waitfor ".vid/requests/$TK/timeline.inline.log.gz" 60 || fail "no timeline.inline.log.gz for '$1'"; }
red 'a red pass'
G=".vid/requests/$TK/timeline.inline.log.gz"
[ "$(gzip -dc "$G" | grep -c ' line [0-9]* of the stack ')" -eq 30000 ] || fail 'the timeline does not hold every line'
gzip -dc "$G" | grep -q ' line 1 of the stack ' && gzip -dc "$G" | grep -q ' line 30000 of the stack ' || fail 'the first or the last line is missing'
grep -qx 'logs-tail=no' "$STUB_LOG" || fail 'the whole timeline was taken with a tail'
grep -nE ' logs --timestamps| down ' "$STUB_LOG" | head -n 1 | grep -q 'logs --timestamps' || fail 'the logs were not taken before the teardown'
[ ! -f ".vid/requests/$TK/timeline.inline.log" ] || fail 'a red pass left the plain tail too'
VID_TIMELINE_CAP=20000; export VID_TIMELINE_CAP
red 'a red pass, cut'
G=".vid/requests/$TK/timeline.inline.log.gz"
gzip -dc "$G" | head -n 1 | grep -q '^ViD test: timeline cut — its first [0-9]* of [0-9]* bytes dropped' || fail 'the cut is not said in the file'
gzip -dc "$G" | tail -n 1 | grep -q ' line 30000 of the stack ' || fail 'the cut did not keep the end'
[ "$(wc -c < "$G")" -le 20000 ] || fail 'the cut file is over its cap'
grep -q 'the timeline of this red pass was cut' ".vid/requests/$TK/log" || fail 'the run does not say the timeline was cut'
exit 0

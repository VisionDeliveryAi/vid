#!/bin/sh
# Purpose: selftest case — the run manager's own context (v0.9.7.1 spec 3.8, R8). Convicts unless `sh
# checks/brief.sh context` prints `context: unknown` with no RUN-STATE, and with no session event matching it;
# with RUN-STATE's `session: S2` it reads the transcript of the `session id=S2` event — the latest call's input +
# cache read + cache creation — and a side session's later event (S3, a bigger context) does not change it.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "context-session: $*" >&2; exit 1; }
mkdir -p "$T/p/checks" "$T/p/.vid"; cd "$T/p"; cp "$CHECKS/brief.sh" checks/
[ "$(sh checks/brief.sh context)" = 'context: unknown' ] || fail 'no RUN-STATE does not read unknown'
tr_() { printf '{"type":"assistant","message":{"id":"m1","role":"assistant","usage":{"input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":%s}}}\n' "$2" "$3" "$4" > "$1"; }
tr_ "$T/s2.jsonl" 10 120000 5000; printf '{"type":"assistant","message":{"id":"m2","role":"assistant","usage":{"input_tokens":20,"cache_read_input_tokens":200000,"cache_creation_input_tokens":1000}}}\n' >> "$T/s2.jsonl"
tr_ "$T/s3.jsonl" 1 900000 0
printf 'run: active\nsession: S2\nplan: required\n' > .vid/RUN-STATE.md
[ "$(sh checks/brief.sh context)" = 'context: unknown' ] || fail 'no matching session event does not read unknown'
printf 'session id=S1 source=startup transcript=%s vid=x at=2026-10-11T00:00:00Z\n' "$T/s3.jsonl" > .vid/metrics-events
printf 'session id=S2 source=startup transcript=%s vid=x at=2026-10-11T00:01:00Z\n' "$T/s2.jsonl" >> .vid/metrics-events
[ "$(sh checks/brief.sh context)" = 'context: 201020' ] || fail "S2's latest call is not read: $(sh checks/brief.sh context)"
printf 'session id=S3 source=startup transcript=%s vid=x at=2026-10-11T00:02:00Z\n' "$T/s3.jsonl" >> .vid/metrics-events
[ "$(sh checks/brief.sh context)" = 'context: 201020' ] || fail 'a side session changed the reading'
exit 0

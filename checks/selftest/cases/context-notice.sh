#!/bin/sh
# Purpose: selftest case — a notice, never a stop (v0.9.7.1 spec 3.8, R8). The brief-write fixture; RUN-STATE's
# session S2 and its transcript. Convicts unless, with the context at 400000, `write` and `return` both succeed,
# each prints `context 400000`, and `context-high n=400000` is recorded once; after a `session id=S2
# source=compact` event a new crossing records it again; and at 300000 nothing prints and nothing is recorded.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "context-notice: $*" >&2; cat "$T/wout" "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
ctx() { printf '{"type":"assistant","message":{"id":"m%s","role":"assistant","usage":{"input_tokens":0,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}\n' "$1" "$1" >> "$T/s2.jsonl"; }
printf 'run: active\nsession: S2\nplan: required\n' > .vid/RUN-STATE.md
printf 'session id=S2 source=startup transcript=%s vid=x at=2026-10-11T00:01:00Z\n' "$T/s2.jsonl" >> .vid/metrics-events
ctx 400000
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'write was refused at a high context'
grep -q '^context 400000' "$T/wout" || fail 'write did not print the notice'
bw_return || fail 'bw_return'; bw_agent a1 edit
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$(bw_out)" "$(git rev-parse HEAD)" "$GREEN" > "$T/rf.return.md"
sh checks/brief.sh return "$T/rf.return.md" > "$T/out" 2>&1 || fail 'return was refused at a high context'
grep -q '^context 400000' "$T/out" || fail 'return did not print the notice'
[ "$(grep -c '^context-high n=400000 ' .vid/metrics-events)" = 1 ] || fail "context-high is not recorded once: $(grep -c '^context-high' .vid/metrics-events)"
printf 'session id=S2 source=compact transcript=%s vid=x at=2026-10-11T01:00:00Z\n' "$T/s2.jsonl" >> .vid/metrics-events
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'write refused'
[ "$(grep -c '^context-high ' .vid/metrics-events)" = 2 ] || fail 'a new crossing after the compaction is not recorded'
ctx 300000; N=$(grep -c . .vid/metrics-events)
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'write refused'
grep -q '^context ' "$T/wout" && fail 'a notice printed below 350000'
[ "$(grep -c '^context-high ' .vid/metrics-events)" = 2 ] || fail 'context-high recorded below 350000'
exit 0

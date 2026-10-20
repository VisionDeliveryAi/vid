#!/bin/sh
# Purpose: selftest case — the run manager's usage in four kinds (v0.26.10.6 spec R17c). The brief-write fixture with
# bw_builder and bw_return, and a run-manager transcript: a streamed message's two entries (the first with partial
# output), a call with a 1-hour cache write and a `<synthetic>` entry. Convicts unless the first `return` writes,
# beside `manager-cost`, `usage agent=manager session=S9 tool=claude model=… effort=unknown calls=2 input= cache-read=
# cache-write= cache-write-1h= output= scope=since:-` — each message id's last entry (not mcost's first), the synthetic
# entry skipped; unless the next return file's record covers only the calls after the first window, `scope=since:<the
# first manager-cost's at>`; and unless a re-check of the same file writes none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "usage-record-manager: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep -E '^(manager-cost|usage) ' .vid/metrics-events >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'bw_return'
B=$(bw_out)
M=$T/mgr.jsonl
mc() { printf '{"type":"assistant","timestamp":"%s","message":{"model":"%s","id":"%s","role":"assistant","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s,"cache_creation":{"ephemeral_1h_input_tokens":%s}}}}\n' "$@" >> "$M"; }
mc 2026-10-11T00:00:01.000Z claude-opus-5-5 msg_1 100 10 1000 2 0
mc 2026-10-11T00:00:01.500Z claude-opus-5-5 msg_1 100 10 1000 50 0
mc 2026-10-11T00:00:02.000Z claude-opus-5-5 msg_2 200 20 2000 60 20
mc 2026-10-11T00:00:03.000Z '<synthetic>' msg_x 9 9 9 9 0
printf 'run: active\nsession: S9\nplan: required\n' > .vid/RUN-STATE.md
printf 'session id=S9 source=startup transcript=%s vid=x at=2026-10-11T00:00:00Z\n' "$M" >> .vid/metrics-events
bw_agent a1 edit
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$B" "$(git rev-parse HEAD)" "$GREEN" > "$T/r1.return.md"
sh checks/brief.sh return "$T/r1.return.md" > "$T/out" 2>&1 || fail 'return refused'
grep -q '^manager-cost ' .vid/metrics-events || fail 'no manager-cost'
grep -qE '^usage agent=manager session=S9 tool=claude model=claude-opus-5-5 effort=unknown calls=2 input=300 cache-read=3000 cache-write=30 cache-write-1h=20 output=110 scope=since:- at=' .vid/metrics-events || fail "the manager's first window is not its transcript's sums: $(grep '^usage' .vid/metrics-events)"
sh checks/brief.sh return "$T/r1.return.md" > "$T/out" 2>&1 || fail 're-check refused'
[ "$(grep -c '^usage agent=manager ' .vid/metrics-events)" = 1 ] || fail 'a re-check recorded the manager'"'"'s usage again'
S1=$(grep '^manager-cost ' .vid/metrics-events | sed 's/.* at=//')
mc 2099-01-01T00:00:00.000Z claude-opus-5-5 msg_3 7 0 70 8 0
cp "$T/r1.return.md" "$T/r2.return.md"
sh checks/brief.sh return "$T/r2.return.md" > "$T/out" 2>&1 || fail 'the second return refused'
grep -q "^usage agent=manager session=S9 tool=claude model=claude-opus-5-5 effort=unknown calls=1 input=7 cache-read=70 cache-write=0 cache-write-1h=0 output=8 scope=since:$S1 at=" .vid/metrics-events || fail "the second window is not since the first: $(grep '^usage' .vid/metrics-events | tail -n 1)"
exit 0

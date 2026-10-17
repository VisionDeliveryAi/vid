#!/bin/sh
# Purpose: selftest case — cost for every role and for the run manager (v0.9.7.1 spec 3.11, R11). The brief-write
# fixture with bw_builder and bw_return. Convicts unless `cost <grader brief> --agent g1` records `build-cost
# role=grader … rows-passed=- peak=5000 total=13502 before-change=unknown tool=claude model=m` from the agent's
# transcript, and a second call records nothing; `cost` refuses a builder's brief (its cost is return's); and each
# `return` records `manager-cost calls=<n> input=<sum> since=<previous|->` from RUN-STATE's session transcript —
# 2 calls (one message id twice counts once) summing 3300 at the first, the calls after it at the next return
# file, and nothing at a re-check of the same file. v0.9.8.1 (R7): a call naming the brief by its absolute path is the same brief, recorded once. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "cost-roles: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'bw_return'
B=$(bw_out)
mkdir -p .vid/ledger-results; bw_write --role grader --slice 1 --rows ROW-101 --receipt "$GREEN" || fail 'grader brief'; G=$(bw_out)
bw_agent g1 edit
sh checks/brief.sh cost "$G" --agent g1 > "$T/out" 2>&1 || fail 'cost refused'
grep -q "^build-cost role=grader slice=1 step=- brief=$G rows=1 rows-passed=- peak=5000 total=13502 before-change=unknown tool=claude model=m effort=unknown brief-bytes=[0-9]* agent=g1 at=" .vid/metrics-events || fail "the grader's build-cost is not as computed: $(grep "brief=$G" .vid/metrics-events)"
sh checks/brief.sh cost "$G" --agent g1 > "$T/out" 2>&1 || fail 'the second cost call failed'
[ "$(grep -c "^build-cost .*brief=$G " .vid/metrics-events)" = 1 ] || fail 'a second cost call recorded again'
sh checks/brief.sh cost "$(pwd -P)/${G#./}" --agent g1 > "$T/out" 2>&1 || fail 'the cost call by the absolute path failed'   # v0.9.8.1 (R7)
[ "$(grep -c "^build-cost .*brief=" .vid/metrics-events)" = 1 ] || fail 'a cost call naming the brief by its absolute path recorded again'
if sh checks/brief.sh cost "$B" --agent g1 > "$T/out" 2>&1; then fail 'cost took a builder brief'; fi
# the run manager's cost
M=$T/mgr.jsonl
mc() { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","role":"assistant","usage":{"input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}\n' "$1" "$2" "$3" "$4" >> "$M"; }
mc 2026-10-11T00:00:01.000Z msg_1 100 1000; mc 2026-10-11T00:00:01.000Z msg_1 100 1000; mc 2026-10-11T00:00:02.000Z msg_2 200 2000
printf 'run: active\nsession: S9\nplan: required\n' > .vid/RUN-STATE.md
printf 'session id=S9 source=startup transcript=%s vid=x at=2026-10-11T00:00:00Z\n' "$M" >> .vid/metrics-events
bw_agent a1 edit
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$B" "$(git rev-parse HEAD)" "$GREEN" > "$T/r1.return.md"
sh checks/brief.sh return "$T/r1.return.md" > "$T/out" 2>&1 || fail 'return refused'
grep -q "^manager-cost calls=2 input=3300 since=- return=$T/r1.return.md " .vid/metrics-events || fail "the manager's cost is not as computed: $(grep '^manager-cost' .vid/metrics-events)"
sh checks/brief.sh return "$T/r1.return.md" > "$T/out" 2>&1 || fail 're-check refused'
[ "$(grep -c '^manager-cost ' .vid/metrics-events)" = 1 ] || fail 'a re-check recorded the manager'"'"'s cost again'
S1=$(grep '^manager-cost ' .vid/metrics-events | sed 's/.* at=//')
mc 2099-01-01T00:00:00.000Z msg_3 7 0
cp "$T/r1.return.md" "$T/r2.return.md"
sh checks/brief.sh return "$T/r2.return.md" > "$T/out" 2>&1 || fail 'the second return refused'
grep -q "^manager-cost calls=1 input=7 since=$S1 return=$T/r2.return.md " .vid/metrics-events || fail "the second manager-cost is not since the first: $(grep '^manager-cost' .vid/metrics-events | tail -n 1)"
exit 0

#!/bin/sh
# Purpose: selftest case — an agent whose return or cost is recorded is finished (v0.9.8.1 R9, F-8). Toy events and
# transcripts, every agent's newest entry 25 min old. Convicts unless resume lists no line for an agent with a
# later `build-cost … agent=<id>`, nor for one with a later `agent-returned … agent=<id>`; still calls quiet a resumed
# agent whose cost came before its latest start, and an agent whose cost carries no agent= (an older record); and the
# watcher sends no quiet-agent notice for the two finished ones. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=observe-finished-not-quiet
. "$CHECKS/selftest/fixtures/observer-lib.sh"
. "$CHECKS/selftest/fixtures/agent-lib.sh"
res() { sh checks/observe.sh resume > "$T/tick.out" 2>&1; }
line() { grep "^resume: agent $1 " "$T/tick.out" || true; }
bc() { printf 'build-cost role=%s slice=1 step=- brief=.vid/briefs/1/x-%s.md rows=1 rows-passed=- peak=1 total=1 before-change=unknown tool=claude model=m effort=e brief-bytes=9%s at=%s\n' "$1" "$2" "$3" "$(ago "$4")" >> .vid/metrics-events; }
reset; rs active
start fc 3600; entry fc 1500; bc grader fc ' agent=fc' 1400
start fr 3600; entry fr 1500; printf 'agent-returned role=builder n=3 try=t agent=fr at=%s\n' "$(ago 1400)" >> .vid/metrics-events
start rs 7200; bc grader rs ' agent=rs' 7000; start rs 3600; entry rs 1500
start old 3600; entry old 1500; bc grader old '' 1400
res
[ -z "$(line fc)" ] || fail "an agent with a later cost record is not finished: $(line fc)"
[ -z "$(line fr)" ] || fail "an agent with a later return record is not finished: $(line fr)"
line rs | grep -q '^resume: agent rs quiet ' || fail "a resumed agent's earlier cost finished its latest episode: $(line rs)"
line old | grep -q '^resume: agent old quiet ' || fail "an older cost record with no agent= finished an agent: $(line old)"
hb "$(ago 0)" 'working'; tick
grep -q 'an agent has had no new step for [0-9]* min: agent rs\.' "$T/notify.log" || fail 'the watcher did not tell the quiet resumed agent'
grep -q 'no new step for [0-9]* min: agent f[cr]\.' "$T/notify.log" && fail 'the watcher told a finished agent'
exit 0

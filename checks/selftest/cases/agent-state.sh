#!/bin/sh
# Purpose: selftest case — the watcher reads agents from the hooks' record
# (v0.9.7.0.6 spec 3.1, 3.2, R2; §6 A-2). Toy events and toy transcripts
# shaped as Claude Code writes them. Convicts unless `sh checks/observe.sh
# resume` reads: an open agent with an entry 5 min ago `working`, and at 25
# min `quiet`; a SubagentHandback whose result reports success after the
# latest start `finished` (no line); a handback only before the latest start,
# a handback whose result reports failure, and a bare end of turn not
# finished; nor the tool's definition in a prompt snapshot, even beside a
# success result for an id written before it; a later agent-stop `finished`; a missing transcript `unresolved`;
# a start without `transcript=` takes the newest earlier `session` event of
# its own session id (S1 and S2 interleaved), and with none is `unresolved`;
# and the task comes from the agent's meta.json. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-state
. "$CHECKS/selftest/fixtures/observer-lib.sh"
. "$CHECKS/selftest/fixtures/agent-lib.sh"
res() { sh checks/observe.sh resume > "$T/tick.out" 2>&1; }
line() { grep "^resume: agent $1 " "$T/tick.out" || true; }
want() { line "$1" | grep -q "^resume: agent $1 $2 " || fail "agent $1 is not $2: $(line "$1")"; }
gone() { [ -z "$(line "$1")" ] || fail "agent $1 is not finished: $(line "$1")"; }
reset; rs active
start w5 1800; entry w5 300; task w5 'Build "slice" 3'
start w25 1800; entry w25 1500
start hb 1800; entry hb 1600; handback hb 1500
start old 3600; entry old 3500; handback old 3400; start old 1800; entry old 1700
start bad 1800; entry bad 1600; handback bad 1500 false
start et 1800; entry et 1600; endturn et 300
start st 1800; entry st 1700; stop st 1600
start sn 1800; snapshot sn 1700; entry sn 1500
start gone 1800
session S1 7200; session S2 7100; start leg 1800 S1 no-transcript; session S2 1900; entry leg 120
start none 1800 S3 no-transcript
res
want w5 working; line w5 | grep -q '"Build .slice. 3"$' || fail 'the task is not shown from meta.json'
want w25 quiet
gone hb
want old quiet
want bad quiet
want et working
gone st
want sn quiet
want gone unresolved
want leg working
want none unresolved
# the legacy fallback takes its own session's transcript, never the interleaved S2's
printf '{"timestamp":"%s"}\n' "$(ts 60)" > "$(af leg2 S2)"
start leg2 1800 S1 no-transcript
res; want leg2 unresolved
exit 0

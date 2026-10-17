#!/bin/sh
# Purpose: selftest case — a commit-msg refusal is recorded (v0.9.6.2 spec
# 3.4, R4; §6 case 17). In a scratch repository with checks/event.sh beside
# the hook: a message with no Decisions: line is refused and writes
# `refused phase=commit-msg by=decisions attempt=<id>`; a commit adding a
# ledger file without Tests-by: writes `by=tests-by`; an accepted message
# writes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "refused-commit-msg: $*" >&2; cat .vid/metrics-events >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks/hooks" "$T/p/tests/invariants"; cd "$T/p"; git init -q
cp "$CHECKS/hooks/commit-msg" checks/hooks/; cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
printf 'no decisions here\n' > "$T/m1"
if sh checks/hooks/commit-msg "$T/m1" 2>/dev/null; then fail 'a message without Decisions: was accepted'; fi
tail -n 1 .vid/metrics-events | grep -qxE "refused phase=commit-msg by=decisions attempt=[0-9]{8}T[0-9]{6}Z-[0-9a-f]{4} $ATRE" || fail 'the decisions refusal is not recorded in its form'
printf '# Purpose: t\n' > tests/invariants/t.sh; git add tests/invariants/t.sh
printf 'add a test\n\nDecisions: none — nothing surprising\n' > "$T/m2"
if sh checks/hooks/commit-msg "$T/m2" 2>/dev/null; then fail 'a ledger file without Tests-by: was accepted'; fi
tail -n 1 .vid/metrics-events | grep -q '^refused phase=commit-msg by=tests-by ' || fail 'the tests-by refusal is not recorded'
N=$(grep -c . .vid/metrics-events)
printf 'add a test\n\nDecisions: none — nothing surprising\nTests-by: test-author 2026-10-01 b1\n' > "$T/m3"
sh checks/hooks/commit-msg "$T/m3" 2>/dev/null || fail 'a valid message was refused'
[ "$(grep -c . .vid/metrics-events)" -eq "$N" ] || fail 'an accepted message wrote an event'
exit 0

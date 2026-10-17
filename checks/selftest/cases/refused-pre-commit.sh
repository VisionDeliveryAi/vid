#!/bin/sh
# Purpose: selftest case — a pre-commit refusal is named (v0.9.6.2 spec
# 3.4, R4; §6 case 16). Stub courts under the real hook, with checks/event.sh
# beside it. A commit refused by the census writes `refused
# phase=pre-commit by=census attempt=<UTC time plus 4 hex>` to the events
# and its hook-times line carries `by=census` before `at=`; inventory and
# census failing together give `by=inventory,census`; a protected path
# staged without VID_ROLE=fix gives `by=protected-paths`; a passing attempt
# writes no refused event and no by=. Env: CHECKS. v0.9.6.2.2: VID_ROLE
# is unset first — a project's checks/ refresh commits with VID_ROLE=fix,
# which would let the protected path through. v0.9.7.3: the last `refused` line is read, since `court-refused` events follow it (R5).
set -eu
unset VID_ROLE
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
g add -A; g commit -qm 'the event helper' --no-verify
fail() { echo "refused-pre-commit: $*" >&2; cat .vid/hook-times .vid/metrics-events "$T/out" >&2 2>/dev/null; exit 1; }
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
run() { rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$T/out" 2>&1; }
stage one
run || fail 'the passing attempt was refused'
grep -q '^refused ' .vid/metrics-events 2>/dev/null && fail 'a passing attempt wrote a refused event'
grep -q ' by=' .vid/hook-times && fail 'a passing line carries by='
: > .fail/census
run && fail 'the census refusal passed'
grep "^refused " .vid/metrics-events | tail -n 1 | grep -qxE "refused phase=pre-commit by=census attempt=[0-9]{8}T[0-9]{6}Z-[0-9a-f]{4} $ATRE" || fail 'the refused event is not in its form'
tail -n 1 .vid/hook-times | grep -qE "^hook result=refused .* redstamp=- by=census $ATRE\$" || fail 'hook-times does not carry by=census before at='
: > .fail/inventory
run && fail 'two failing courts passed'
grep "^refused " .vid/metrics-events | tail -n 1 | grep -q '^refused phase=pre-commit by=inventory,census ' || fail 'two failing courts are not both named, inventory and census apart'
rm -f .fail/*
mkdir -p tests/invariants; printf '# Purpose: x\n' > tests/invariants/t.sh; g add tests/invariants/t.sh
run && fail 'a protected path passed'
grep "^refused " .vid/metrics-events | tail -n 1 | grep -q '^refused phase=pre-commit by=protected-paths ' || fail 'the protected-path refusal is not named'
A1=$(grep '^refused ' .vid/metrics-events | sed 's/.* attempt=\([^ ]*\) .*/\1/' | sort | uniq -d)
[ -z "$A1" ] || fail 'two refusals share an attempt id'
exit 0

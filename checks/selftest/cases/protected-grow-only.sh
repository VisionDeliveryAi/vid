#!/bin/sh
# Purpose: selftest case — the protected: line only grows (v0.9.7.2 spec 3.3, R4). Adding an id is accepted; a change
# removing one is refused naming it, under breadth first and under depth first alike, and the plan keeps its recorded
# hash. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "protected-grow-only: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" 'protected: ROW-007' > /dev/null
replan "$S1L" "$S2L" "$H1L" 'protected: ROW-007 ROW-008'
chg other 'ROW-008 guards the tenant boundary too' > "$T/out" 2>&1 || fail 'adding a protected id was refused'
H0=$(grep '^plan-change' .vid/metrics-events | tail -n 1)
replan "$S1L" "$S2L" "$H1L" 'protected: ROW-008'
if chg other 'ROW-007 no longer matters' > "$T/out" 2>&1; then fail 'a protected id was removed under breadth first'; fi
grep -q 'only grows; this change removes ROW-007' "$T/out" || fail 'the refusal does not name the removed id'
sh checks/plan.sh strategy depth-first --by owner --words 'depth' > /dev/null
replan "$S1L" "$S2L" "$H1L"
if chg other 'drop the line' > "$T/out" 2>&1; then fail 'the protected: line was dropped under depth first'; fi
grep -q 'this change removes ROW-007 ROW-008' "$T/out" || fail 'the depth-first refusal does not name both ids'
[ "$(grep '^plan-change' .vid/metrics-events | tail -n 1)" = "$H0" ] || fail 'a refused removal was recorded'
exit 0

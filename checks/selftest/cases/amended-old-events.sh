#!/bin/sh
# Purpose: selftest case — an `amended … by=fail-if` written under records 22 still wipes (v0.26.10.3 R1, §5
# amended-old-events). A gated toy run: ROW-001 KEPT and passing on a receipt; a later commit and, in the events, the old
# hook's `amended row=ROW-001 sha=<it> by=fail-if`. Convicts unless the row's verdict is gone (row-state latest NONE),
# it reads stale, and it is not listed to confirm (an old event is a wipe, never a confirmation). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "amended-old-events: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows S1 1 1; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(utcnow)" >> .vid/metrics-events
rcpt r1 HEAD inline ROW-001=passed
[ "$(state ROW-001)" = pass ] || fail "ROW-001 is $(state ROW-001) before the old event, not pass"
sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $3 }' | grep -qx KEPT || fail 'ROW-001 is not KEPT before the old event'
printf 'later\n' > app/s1/notes.txt; commit_all 'a later commit'
printf 'amended row=ROW-001 sha=%s by=fail-if at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(utcnow)" >> .vid/metrics-events
sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $3 }' | grep -qx NONE || fail 'the old by=fail-if event did not wipe the verdict'
[ "$(state ROW-001)" = stale ] || fail "ROW-001 is $(state ROW-001) after the old event, not stale"
sh checks/metrics.sh to-confirm 2>/dev/null | grep -q 'row=ROW-001 ' && fail 'an old amended event was read as a row to confirm'
exit 0

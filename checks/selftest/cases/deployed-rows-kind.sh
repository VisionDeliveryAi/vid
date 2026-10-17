#!/bin/sh
# Purpose: selftest case — a deployed request refuses rows it can't credit
# (v0.9.7.0.11 spec 3.9, R9). With the harness declaring
# deployed-selector:, `request --type deployed` naming a journey row, a
# behavior row and a behavior row whose actor is `(process)` is refused at
# once — no ticket — naming the behavior row only and saying to request it
# inline; the journey and the (process) rows alone are accepted. A row not
# in INVENTORY.md is refused too. `checks/evidence.sh kinds` prints `id
# kind actor` for the rows it finds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "deployed-rows-kind: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
plan_repo "$T/repo"; rows s1 1 1 journey; rows s1 2 3
awk '/^ROW-003 / { sub(/\| anon \|/, "| (process) |") } { print }' INVENTORY.md > i && mv i INVENTORY.md; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null || fail 'S1 did not start'
printf 'ROW-001\nROW-002\nROW-003\nROW-999\n' > "$T/rows"
sh checks/evidence.sh kinds "$T/rows" > "$T/out"
[ "$(cat "$T/out")" = "ROW-001 journey anon
ROW-002 behavior anon
ROW-003 behavior (process)" ] || fail 'kinds does not print id kind actor for the rows it finds'
dep() { sh checks/test.sh request --type deployed --role builder --try t1 --rows "$1" --why 'the deployed shape' -- sel-dep > "$T/out" 2>&1; }
NT=$(ls .vid/requests 2>/dev/null | grep -c . || true)
if dep ROW-001,ROW-002,ROW-003; then fail 'a deployed request naming a behavior row was accepted'; fi
grep -q 'a deployed run credits only journey and (process) rows; not: ROW-002 — request them inline' "$T/out" || fail 'the refusal does not name ROW-002 alone'
[ "$(ls .vid/requests 2>/dev/null | grep -c . || true)" -eq "$NT" ] || fail 'a refused request left a ticket'
if dep ROW-001,ROW-999; then fail 'a deployed request naming a row not in INVENTORY.md was accepted'; fi
grep -q 'not: ROW-999' "$T/out" || fail 'the refusal does not name the unknown row'
dep ROW-001,ROW-003 || fail 'a deployed request of a journey and a (process) row was refused'
VID_WAIT_MAX=30 sh checks/test.sh wait "$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")" > /dev/null 2>&1 || true
exit 0

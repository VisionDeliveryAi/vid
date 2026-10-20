#!/bin/sh
# Purpose: selftest case — a changed test or contract stales the old pass
# (v0.9.6 spec 3.3, R3; §7 case 24). A receipt passing a row is no longer
# current after: a changed assertion in the row's test file; a case added
# to it; an `amended` event for the row — including one written by
# checks/hooks/post-commit for a commit in a builder worktree, routed to the
# home; and for a later run whose base does not contain the amendment
# commit. A run whose base contains it counts again. A case naming its row
# in a test function's spelling (test_ROW_001_…) joins it. 24b (deployed
# eligibility): with a deployed selector declared, a journey row with a
# deployed failure and a later inline pass on the same tree is red, and
# with only an inline pass (no deployed receipt) it is never run. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "currency-tests: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 3 journey; commit_all rows
cp "$CHECKS/hooks/post-commit" checks/hooks/ 2>/dev/null || { mkdir -p checks/hooks; cp "$CHECKS/hooks/post-commit" checks/hooks/; }
cp "$CHECKS/inventory.sh" checks/   # v0.26.10.3 (R1): the hook's row sets come from inventory.sh impact
commit_all 'the post-commit hook'
g config core.hooksPath checks/hooks
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: journey | modules: app/s2 | builds-on: - | rows: ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
B0=$(git rev-parse HEAD)
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
[ "$(state ROW-001)" = pass ] || fail 'the fixture receipt is not current'
g checkout -q -b assertion "$B0"; sed 's/def test_1(): pass/def test_1(): assert 2 > 1/' tests/invariants/test_s1.py > x && mv x tests/invariants/test_s1.py; commit_all 'a changed assertion'
[ "$(state ROW-001 HEAD)" = stale ] || fail 'a changed assertion kept the old pass'
g checkout -q -b added "$B0"; printf 'def test_1b(): pass  # ROW-001\n' >> tests/invariants/test_s1.py; commit_all 'a case added'
[ "$(state ROW-001 HEAD)" = stale ] || fail 'an added case kept the old pass'
g checkout -q master 2>/dev/null || g checkout -q main
# an amendment committed in a builder worktree lands at the home
g worktree add -q "$T/builder" -b builder "$B0" 2>/dev/null
mkdir -p .vid/briefs/1; printf 'role: builder    slice: 1    step: S1\n' > .vid/briefs/1/builder-1.md
( cd "$T/builder" && sh checks/plan.sh home --brief "$T/repo/.vid/briefs/1/builder-1.md" > /dev/null \
  && sed 's/^\(ROW-002 | behavior | s2 | anon | - | \)x/\1changed obligation/' INVENTORY.md > x && mv x INVENTORY.md \
  && g add INVENTORY.md && g commit -qm 'ROW-002 amended in a builder' )
A=$(git -C "$T/builder" rev-parse --short=12 HEAD)
grep -q "^amended row=ROW-002 sha=$A " .vid/metrics-events || fail 'the builder worktree'"'"'s amendment did not land at the home'
[ ! -f "$T/builder/.vid/metrics-events" ] || ! grep -q '^amended' "$T/builder/.vid/metrics-events" || fail 'the amendment was written in the builder worktree'
[ "$(state ROW-002 "$A")" = stale ] || fail 'an amended row kept the pass from before its amendment'
[ "$(state ROW-001 "$A")" = pass ] || fail 'the amendment of ROW-002 staled ROW-001'
rcpt r2 "$B0" inline ROW-002=passed
[ "$(state ROW-002 "$A")" = stale ] || fail 'a later run whose base lacks the amendment counted'
rcpt r3 "$A" inline ROW-002=passed
[ "$(state ROW-002 "$A")" = pass ] || fail 'a run whose base holds the amendment did not count'
# a case naming its row in the identifier spelling (ROW_001) joins as ROW-001 does
g checkout -q -b idspelling "$B0"
printf '<report><case name="tests/invariants/test_s1.py::test_ROW_001_the_first" status="failed" time="0.1"/></report>\n' > .vid/ledger-results/r-id
sh checks/extractors/results.sh .vid/ledger-results/r-id > .vid/ledger-results/r-id.cases
printf 'tree=%s\nbase=%s\nfrozen-at=%s\nshape=inline\n' "$(git rev-parse 'HEAD^{tree}')" "$(git rev-parse --short=12 HEAD)" "$(utcnow)" > .vid/ledger-results/r-id.tree
printf 'ledger-run seconds=1 kind=scoped report=r-id status=0 at=%s\n' "$(utcnow)" >> .vid/metrics-events
[ "$(state ROW-001 HEAD)" = red ] || fail 'a case named test_ROW_001_… did not join ROW-001'
g checkout -q master 2>/dev/null || g checkout -q main
# 24b: the deployed shape
printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]\n  deployed-selector: sel-dep\n  processes: [worker]\nservices:\n  product:\n    image: toy:test\n  tests:\n    image: runner\n' > docker-compose.test.yml
commit_all 'a deployed selector'; C=$(git rev-parse HEAD)
rcpt r4 "$C" inline ROW-003=passed
[ "$(state ROW-003 "$C")" = never ] || fail 'a journey row with only an inline pass is not never run in the deployed shape'
rcpt r5 "$C" deployed ROW-003=failed
rcpt r6 "$C" inline ROW-003=passed
[ "$(state ROW-003 "$C")" = red ] || fail 'an inline pass outranked a deployed failure'
exit 0

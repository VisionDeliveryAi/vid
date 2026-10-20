#!/bin/sh
# Purpose: selftest case — cost per accepted outcome, nothing shared out (v0.26.10.6 spec R12). The viewer fixture (its
# two receipts' runs name no try, step or rows; ROW-001 kept at 10:45) with planted: a builder's try on S2 whose
# accepted return passes ROW-001, ROW-002 and ROW-003, all three later kept, one test pass of that try (60 s running),
# S2 closed, one manager window and one more pass naming nothing. Convicts unless S2 is listed closed with that try and
# its 60 s, each of the three rows lists the try whole with its return's three lines (never a share), and shared work
# counts the manager's one record and the three passes owned by none. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-econ-outcomes: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/2
printf 'brief: .vid/briefs/2/builder-9.md\nROW-001 | pass | r2\nROW-002 | pass | r2\nROW-003 | pass | r2\n' > .vid/briefs/2/builder-9.return.md
vev 11:10 'build-cost role=builder slice=2 step=S2 brief=.vid/briefs/2/builder-9.md rows=3 rows-passed=3 peak=50 total=900 before-change=unknown'
vev 11:08 'ledger-run seconds=100 kind=scoped report=q.xml status=0 role=builder run=RQ request=20260101T110000Z-q001 type=iterate rows=3 try=2-builder-9 overhead=40 why="x"'
vev 11:20 'verdict slice=2 row=ROW-002 result=KEPT class=product brief=.vid/briefs/2/grader-1.md quoted-at=x'
vev 11:21 'verdict slice=2 row=ROW-003 result=KEPT class=product brief=.vid/briefs/2/grader-1.md quoted-at=x'
vev 11:30 'step-closed step=S2 report=q.xml'
vev 11:31 'manager-cost calls=5 input=100 since=- return=.vid/briefs/2/builder-9.return.md'
vev 11:32 'ledger-run seconds=5 kind=scoped report=none status=1 role=- why="x"'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
O=$(vel "$T/out/now.html" '"outcomes":{')
printf '%s' "$O" | grep -qF '{"step":"S2","closed":"2026-01-01T11:30:00Z","tries":["2-builder-9"],"testSeconds":60}' || fail "S2's outcome: $O"
for r in ROW-001 ROW-002 ROW-003; do printf '%s' "$O" | grep -o "{\"row\":\"$r\",\"kept\":\"[^\"]*\",\"tries\":\[[^]]*\]}" | grep -qF '{"try":"2-builder-9","rows":3}' || fail "$r does not list the try whole: $O"; done
printf '%s' "$O" | grep -qF '"shared":{"managerRecords":1,"testsOwnedByNone":3}' || fail "shared work: $O"
vel "$T/out/now.html" '"try":"2-builder-9",' | grep -F '"kind":"total"' | grep -qF '"total":900' || fail "the try's tokens are not whole in its one usage entry"
exit 0

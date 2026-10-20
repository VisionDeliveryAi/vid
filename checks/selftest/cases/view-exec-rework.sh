#!/bin/sh
# Purpose: selftest case — attempts per step and row (v0.26.10.6 spec R8). The viewer fixture (S1's builder-1 accepted,
# ROW-002 broken once) with S2's tries planted: builder-40 accepted (its build-cost names S2), fixer-41 handed back
# with no acceptance (its step from its brief), the Codex job builder-42 (its job's step), and one step-closed naming
# S1 and S2; ROW-004 named by two returns; ROW-003 broken by two graders, then kept. Convicts unless S2's briefs,
# returned, closed and tries, each row's briefs, broken and keptLast, and noAcceptance are as recorded. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-rework: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/1 .vid/jobs
printf 'role: fixer    slice: 1    step: S2\n' > .vid/briefs/1/fixer-41.md
printf 'brief: .vid/briefs/1/builder-40.md\nROW-004 | pass | r2\nROW-005 | pass | r2\n' > .vid/briefs/1/builder-40.return.md
printf 'brief: .vid/briefs/1/fixer-41.md\nROW-004 | pass | r2\n' > .vid/briefs/1/fixer-41.return.md
printf 'step=S2\ntry=1-builder-42\nbrief=.vid/briefs/1/builder-42.md\n' > .vid/jobs/1-builder-42
vev 11:06 'build-cost role=builder slice=1 step=S2 brief=.vid/briefs/1/builder-40.md rows=2 rows-passed=2 peak=5 total=9 before-change=unknown'
vev 11:07 'job-start try=1-builder-42 step=S2'
vev 11:08 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=.vid/briefs/1/grader-2.md quoted-at=x'
vev 11:09 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=.vid/briefs/1/grader-3.md quoted-at=x'
vev 11:09:30 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=.vid/briefs/1/grader-3.md quoted-at=x'
vev 11:10 'verdict slice=1 row=ROW-003 result=KEPT class=product brief=.vid/briefs/1/grader-4.md quoted-at=x'
vev 11:12 'step-closed step=S1 S2 report=r2'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
R=$(vel "$T/out/now.html" '"rework":{')
printf '%s' "$R" | grep -qF '{"step":"S2","briefs":3,"returned":1,"closed":"2026-01-01T11:12:00Z","tries":[' || fail "S2's attempts: $R"
for t in 1-builder-40 1-fixer-41 1-builder-42; do printf '%s' "$R" | grep -o '{"step":"S2"[^}]*}' | grep -qF "\"$t\"" || fail "S2 does not list $t: $R"; done
printf '%s' "$R" | grep -qF '{"step":"S1","briefs":1,"returned":1,"closed":"2026-01-01T11:12:00Z","tries":["1-builder-1"]}' || fail "S1's attempts, closed again with S2: $R"
printf '%s' "$R" | grep -o '{"row":"ROW-004"[^}]*}' | grep -qF '"briefs":2,"broken":0,"keptLast":false' || fail "ROW-004: $R"
printf '%s' "$R" | grep -qF '{"row":"ROW-003","briefs":0,"broken":2,"keptLast":true,"tries":[]}' || fail "ROW-003, broken by two graders, then kept: $R"
printf '%s' "$R" | grep -qF '{"row":"ROW-002","briefs":1,"broken":1,"keptLast":false,"tries":["1-builder-1"]}' || fail "ROW-002: $R"
printf '%s' "$R" | grep -qF '{"row":"ROW-001"' && fail "ROW-001, named once and never broken, is listed: $R"
printf '%s' "$R" | grep -qF '"noAcceptance":[{"try":"1-fixer-41","file":".vid/briefs/1/fixer-41.return.md","refusedAt":null}]' || fail "noAcceptance: $R"
exit 0

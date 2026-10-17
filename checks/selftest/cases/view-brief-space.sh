#!/bin/sh
# Purpose: selftest case — the viewer reads a brief path with spaces whole (v0.9.8.1 R7, F-1). The viewer fixture in
# a folder whose path holds spaces and ends in one, its builder's build-cost recording brief= as an older record
# did — the absolute path — and a second build-cost naming a hand-back the project lacks. Convicts unless the
# snapshot shows ROW-001 and ROW-002 built (the absolute path read up to the next field, its prefix removed), and the
# missing hand-back is said, not counted. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-brief-space: $*" >&2; cat "$T/r" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/a b /c "; view_project "$T/a b /c /repo"
H=$(pwd -P)
awk -v h="$H" '$1 == "build-cost" { sub(/ brief=\.vid\//, " brief=" h "/.vid/") } { print }' .vid/metrics-events > .vid/e.x && mv .vid/e.x .vid/metrics-events
grep -q "brief=$H/.vid/briefs/1/builder-1.md rows=" .vid/metrics-events || fail 'the fixture did not take the absolute path'
printf 'build-cost role=builder slice=1 step=S2 brief=.vid/briefs/1/builder-9.md rows=1 rows-passed=1 peak=1 total=1 before-change=unknown at=%s\n' "$(vt 11:12)" >> .vid/metrics-events
vview . --out "$T/out" > "$T/r" 2>&1 || fail 'the run failed'
vdata "$T/out/now.html" > "$T/n"
grep -q '{"id":"ROW-001",.*"built":true' "$T/n" && grep -q '{"id":"ROW-002",.*"built":true' "$T/n" || fail 'the rows of a brief recorded by an absolute path with spaces are not built'
grep -q 'the hand-back .*builder-9.return.md, named by a build-cost record, is not in the project' "$T/r" || fail 'the missing hand-back is not said'
exit 0

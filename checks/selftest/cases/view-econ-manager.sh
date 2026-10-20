#!/bin/sh
# Purpose: selftest case — the run manager apart, one entry per window (v0.26.10.6 spec R10). The viewer fixture with
# two planted windows: an older one (a `manager-cost` alone: its calls and its mixed total) and one recorded in kinds
# (a `manager-cost` and, beside it, a `usage agent=manager` over the same window). Convicts unless `manager` holds
# exactly two entries — the older with its total and no kinds, the newer with its four kinds and model and no total —
# and no usage entry names the manager. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-econ-manager: $*" >&2; exit 1; }
view_project "$T/repo"
vev 11:00 'manager-cost calls=5 input=100 since=- return=.vid/briefs/1/builder-1.return.md'
vev 11:10 'manager-cost calls=2 input=50 since=2026-01-01T11:00:00Z return=.vid/briefs/1/builder-2.return.md'
vev 11:10 'usage agent=manager session=S1 tool=claude model=claude-opus-5-5 effort=high calls=2 input=4 cache-read=40 cache-write=6 cache-write-1h=6 output=9 scope=since:2026-01-01T11:00:00Z'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
M=$(vel "$T/out/now.html" '"manager":[')
printf '%s' "$M" | grep -qF '"manager":[{"at":"2026-01-01T11:00:00Z","since":null,"calls":5,"total":100,"model":null,"input":null,"cacheRead":null,"cacheWrite":null,"cacheWrite1h":null,"output":null},{"at":"2026-01-01T11:10:00Z","since":"2026-01-01T11:00:00Z","calls":2,"total":null,"model":"claude-opus-5-5","input":4,"cacheRead":40,"cacheWrite":6,"cacheWrite1h":6,"output":9}]' || fail "the manager's windows: $M"
vel "$T/out/now.html" '"agent":"manager"' && fail 'a usage entry names the manager'
vel "$T/out/now.html" '"managerRecords":2,' > /dev/null || fail 'shared work does not count two manager records'
exit 0

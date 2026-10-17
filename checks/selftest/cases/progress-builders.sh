#!/bin/sh
# Purpose: selftest case — the builders' cost in the progress table and the metrics (v0.9.7.0.7 spec
# 3.5, R9; §6 D-4). The plan-run fixture. Convicts unless `sh checks/progress.sh` prints `| Builders |
# none yet · lanes: builder 0 · run manager 0 |` (v0.9.7.0.9: the lanes, no step started) with no build-cost event; and, with three — slice 1: rows 3 passed 2 before-change 100;
# slice 1: rows 4 passed 1 before-change 300 shell; slice 2: rows 3 passed 0 before-change unknown —
# prints `3 handed back · rows passed 3 of 10 · before first change: median 100 (1 unknown)`; and
# `sh checks/metrics.sh --slice 1` prints the two slice-1 events as `cost build-cost …` lines and
# not slice 2's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-builders: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 4; commit_all rows
plan 'step S1 | name: tenants | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -qx '| Builders | none yet · lanes: builder 0 · run manager 0 |' "$T/out" || fail 'no event did not say none yet'
printf '%s\n' 'build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-1.md rows=3 rows-passed=2 peak=900 total=5000 before-change=100 at=2026-10-02T10:00:00Z' \
  'build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-2.md rows=4 rows-passed=1 peak=900 total=5000 before-change=300 shell at=2026-10-02T10:10:00Z' \
  'build-cost role=fixer slice=2 step=- brief=.vid/briefs/2/fixer-1.md rows=3 rows-passed=0 peak=unknown total=unknown before-change=unknown at=2026-10-02T10:20:00Z' >> .vid/metrics-events
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -qx '| Builders | 3 handed back · rows passed 3 of 10 · before first change: median 100 (1 unknown) · lanes: builder 0 · run manager 0 |' "$T/out" || fail "the Builders row is not as computed: $(grep Builders "$T/out")"
sh checks/metrics.sh --slice 1 > "$T/out" 2>&1 || true
grep -qx 'cost build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-1.md rows=3 rows-passed=2 peak=900 total=5000 before-change=100' "$T/out" || fail 'metrics --slice 1 lacks the first build-cost line'
grep -qx 'cost build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-2.md rows=4 rows-passed=1 peak=900 total=5000 before-change=300 shell' "$T/out" || fail 'metrics --slice 1 lacks the second build-cost line'
grep -q 'fixer-1' "$T/out" && fail "metrics --slice 1 printed slice 2's build-cost"
exit 0

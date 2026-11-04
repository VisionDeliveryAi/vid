#!/bin/sh
# Purpose: selftest case — notices in the progress print (v0.26.10.24 R7). The plan-run fixture with the watcher beside
# progress.sh. With no notice standing the table has no Notices row; with a builder briefed again after a hand-back that
# passed 11 of 29, its first row is `| Notices |`, holding the notice's text. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-notices: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; cp "$CHECKS/observe.sh" checks/; commit_all rows
plan 'step S2 | name: tenants | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -q '^| Notices |' "$T/out" && fail 'a Notices row with no notice standing'
[ "$(sed -n '/^|---|---|$/{n;p;q;}' "$T/out" | cut -d'|' -f2)" = ' Passing ' ] || fail 'the table does not start as before'
mkdir -p .vid/briefs/1; B=.vid/briefs/1/builder-2.md
printf 'role: builder    slice: 1    step: S2\n' > "$B"
printf 'build-cost role=builder slice=1 step=S2 brief=.vid/briefs/1/builder-1.md rows=29 rows-passed=11 peak=1 total=1 before-change=1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
printf 'brief-written path=%s role=builder try=- bytes=9 at=%s\n' "$B" "$(utcnow)" >> .vid/metrics-events
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
[ "$(sed -n '/^|---|---|$/{n;p;q;}' "$T/out" | cut -d'|' -f2)" = ' Notices ' ] || fail 'the first row is not Notices'
grep -qF "| Notices | ViD: step S2's next builder was briefed ($B) after its last hand-back passed 11 of 29 rows, with no plan change between. |" "$T/out" || fail "the row does not hold the notice's text"
exit 0

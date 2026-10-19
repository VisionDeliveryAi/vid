#!/bin/sh
# Purpose: selftest case — steps per module (v0.26.10.2 spec R4). The viewer fixture with view_arch, and a plan at
# now whose S1 names `app.s1/` (dotted, a trailing slash) and `data`, a name with no row, and S2 names app/s2 and
# app/s1. Convicts unless app/s1's steps are S1 and S2 (joined as brief.sh archrows joins them), app/s2's S2, and
# planOnly lists data, as written, with S1. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-steps: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
plan 'step S1 | name: Shoppers find things | modules: app.s1/ data | builds-on: - | rows: ROW-001..ROW-003 ROW-006 | lane: builder' \
  'step S2 | name: Owners restock | modules: app/s2, app/s1 | builds-on: S1 | rows: ROW-004 ROW-005 ROW-007 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change other 'modules named again' --trigger scope-change --evidence step:S1 --expect 'the same steps' > "$T/p" 2>&1 || fail "the plan change failed: $(cat "$T/p")"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
vmod "$N" app/s1 | grep -qF '"steps":["S1","S2"]' || fail "app/s1's steps are not S1 and S2: $(vmod "$N" app/s1)"
vmod "$N" app/s2 | grep -qF '"steps":["S2"]' || fail "app/s2's steps are not S2: $(vmod "$N" app/s2)"
varch "$N" | grep -qF '"planOnly":[{"name":"data","steps":["S1"]}]' || fail "data is not plan-only with S1: $(varch "$N" | grep planOnly)"
exit 0

#!/bin/sh
# Purpose: selftest case — the delegated mark in every snapshot (v0.9.7.4 spec 3.9, 3.5, R10). The viewer fixture.
# After a first run, `metrics.sh delegated --answer A-002` (an answer live from the first ratification). Convicts unless
# the next run computes no past moment again, yet every page holding answers shows A-002 delegated and lists it under
# what needs the owner — the past snapshots too — and A-001 and A-003 stay unmarked; and unless the page made before
# the mark showed A-002 undelegated, whatever its wording. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-delegated: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r1" 2>&1 || fail "the first run failed: $(cat "$T/r1")"
vdata "$T/out/now.html" | grep -q '{"id":"A-002",.*"delegated":false}' || fail 'A-002 read as delegated from its wording alone'
sh checks/metrics.sh delegated --answer A-002 > /dev/null || fail 'the mark was refused'
vview . --out "$T/out" > "$T/r2" 2>&1 || fail "the second run failed: $(cat "$T/r2")"
if grep '^ViD view: computed ' "$T/r2" | grep -v 'computed now.html' | grep -q .; then fail "a past moment was computed again: $(grep computed "$T/r2")"; fi
n=0
for f in "$T"/out/*.html; do b=$(basename "$f")
  vdata "$f" > "$T/d"; grep -q '{"id":"A-002",' "$T/d" || continue; n=$((n + 1))
  grep -q '{"id":"A-002",.*"delegated":true}' "$T/d" || fail "$b does not show A-002 delegated"
  grep -q '^"delegated":\["A-002"\]},$' "$T/d" || fail "$b does not list A-002 under what needs the owner"
  if grep -q '{"id":"A-00[13]",.*"delegated":true}' "$T/d"; then fail "$b marks an answer never marked"; fi
done
[ "$n" = 9 ] || fail "$n pages hold A-002, not all 9"
exit 0

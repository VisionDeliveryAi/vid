#!/bin/sh
# Purpose: selftest case — a moment inserted between others (v0.9.7.4 spec 3.5, R6). The viewer fixture. Convicts
# unless, after a first run, `--at 2026-01-01T10:45:00Z` computes that moment's data alone, and the snapshots either side
# (S1 closed at 10:40, slice 1 closed at 10:50) are reassembled to name it as their next and previous, and the
# slice close's change window now starts at it. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-insert: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r1" 2>&1 || fail "the first run failed: $(cat "$T/r1")"
vview . --out "$T/out" --at 2026-01-01T10:45:00Z > "$T/r2" 2>&1 || fail "the --at run failed: $(cat "$T/r2")"
[ "$(grep -c '^ViD view: computed ' "$T/r2")" = 1 ] && grep -q '^ViD view: computed 20260101T104500Z-requested.html ' "$T/r2" || fail "more than the new moment was computed: $(grep computed "$T/r2")"
vdata "$T/out/20260101T104000Z-step-closed.html" | grep -q '"next":{"label":"Requested","time":"2026-01-01T10:45:00Z",.*"file":"20260101T104500Z-requested.html"}' || fail "S1's close does not name the new moment next"
vdata "$T/out/20260101T105000Z-slice-closed.html" > "$T/s"
grep -q '"previous":{"label":"Requested",.*"file":"20260101T104500Z-requested.html"}' "$T/s" || fail "the slice close does not name the new moment previous"
# the verdicts at 10:45 now fall in the new moment's window, not the slice close's
if grep -q '"kind":"review"' "$T/s"; then fail "the slice close's window still holds the 10:45 reviews"; fi
vdata "$T/out/20260101T104500Z-requested.html" | grep -q '"kind":"review","ids":\["ROW-001"\]' || fail 'the new moment does not carry its window'"'"'s reviews'
exit 0

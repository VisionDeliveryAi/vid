#!/bin/sh
# Purpose: selftest case — a spec-only init's milestone (v0.26.10.9 spec R6; §5 view-init-spec). The viewer fixture:
# its init end without made= gives the snapshot "Setup done"; with `made=spec` on the same event, "Spec ratified". The
# kind is setup-done in both (the snapshot's file name and its milestones), so readers of viewer-data 4 keep working.
# Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-init-spec: $*" >&2; exit 1; }
view_project "$T/repo"
snap() { vview . --out "$1" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
  vdata "$1/index.html" | sed -n 's/.*"snapshots":\[\(.*\)\]},$/\1/p' | awk '{ gsub(/\},\{"label"/, "}\n{\"label\""); print }' | grep '"file":"20260101T100000Z-setup-done.html"' || true; }
S=$(snap "$T/o1"); [ -n "$S" ] || fail 'no setup-done snapshot without made='
printf '%s\n' "$S" | grep -q '^{"label":"Setup done"' || fail "without made= the label is not Setup done: $S"
grep -q '^stage name=init state=end ' .vid/metrics-events || fail 'the fixture has no init end event'
sed 's/^stage name=init state=end /stage name=init state=end made=spec /' .vid/metrics-events > .vid/e.x && mv .vid/e.x .vid/metrics-events
S=$(snap "$T/o2"); [ -n "$S" ] || fail 'no setup-done snapshot with made=spec'
printf '%s\n' "$S" | grep -q '^{"label":"Spec ratified"' || fail "with made=spec the label is not Spec ratified: $S"
printf '%s\n' "$S" | grep -q '"milestones":\[[^]]*"setup-done"' || fail "with made=spec the milestone kind is not setup-done: $S"
exit 0

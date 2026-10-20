#!/bin/sh
# Purpose: selftest case — a snapshot shows only what is recorded (v0.26.10.6 spec R18a). The viewer fixture. Convicts
# unless no built snapshot or index carries the design's VID_EXEC_SAMPLE or VID_EXEC_DATASET hook, and each holds the
# execution switch at "as recorded" (so the design's edge-state and past-snapshot previews, which build invented data,
# never render). Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-no-sample: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
n=0; for f in "$T"/out/*.html; do n=$((n + 1)); b=$(basename "$f")
  grep -q 'VID_EXEC_SAMPLE' "$f" && fail "$b carries the design's VID_EXEC_SAMPLE hook"
  grep -q 'VID_EXEC_DATASET' "$f" && fail "$b carries the design's VID_EXEC_DATASET hook"
  grep -qF "const ds=this.props.dataset||'full',smp='as recorded';" "$f" || fail "$b does not hold the execution switch at as recorded"
done
[ "$n" -ge 2 ] || fail "too few pages were built: $n"
exit 0

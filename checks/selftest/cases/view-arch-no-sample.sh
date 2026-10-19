#!/bin/sh
# Purpose: selftest case — a snapshot shows only what is recorded (v0.26.10.2 spec R11b, R11a). The viewer fixture
# with view_arch. Convicts unless no built snapshot or index carries the design's VID_ARCH_SAMPLE hook, each holds the
# architecture switch at "as recorded" (so the design's edge-state and past-snapshot previews, which build invented
# data, never render), none names the design's sample project, and each names its own project from the data. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-no-sample: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
n=0; for f in "$T"/out/*.html; do n=$((n + 1)); b=$(basename "$f")
  grep -q 'VID_ARCH_SAMPLE' "$f" && fail "$b carries the design's VID_ARCH_SAMPLE hook"
  grep -qF "const ds=this.props.dataset??'full',as='as recorded';" "$f" || fail "$b does not hold the architecture switch at as recorded"
  grep -q 'Sample Job Board' "$f" && fail "$b names the design's sample project"
  grep -qF 'replayed,project:m.project,' "$f" || fail "$b does not read the project's name from the data"
  vdata "$f" | grep -qF '"project":"Toy Shop"' || fail "$b's data does not name its project"
done
[ "$n" -ge 2 ] || fail "too few pages were built: $n"
exit 0

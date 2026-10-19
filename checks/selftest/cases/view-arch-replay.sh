#!/bin/sh
# Purpose: selftest case — the architecture at each moment (v0.26.10.2 spec R8). The viewer fixture with view_arch
# at 11:40, then app/s1's responsibility rewritten at 11:50; a snapshot requested at the 11:40 commit. Convicts
# unless the requested snapshot reads the module table at its own commit and now reads the later one, and a
# snapshot from before ARCHITECTURE.md existed says it is not recorded. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-replay: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40; A=$(git rev-parse HEAD)
sed 's/| Finding things |/| Finding every thing |/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A; vcommit 11:50 'a wider responsibility'
vview . --out "$T/out" --at "$A" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
vmod "$T/out/20260101T114000Z-requested.html" app/s1 | grep -qF '"responsibility":"Finding things"' || fail "the requested snapshot does not read its own module table: $(vmod "$T/out/20260101T114000Z-requested.html" app/s1)"
vmod "$T/out/now.html" app/s1 | grep -qF '"responsibility":"Finding every thing"' || fail "now does not read the later module table: $(vmod "$T/out/now.html" app/s1)"
varch "$T/out/20260101T112000Z-checkpoint.html" | grep -qF '{"part":"modules","why":"There is no ARCHITECTURE.md at this commit."}' || fail 'the checkpoint, before ARCHITECTURE.md, does not say it is not recorded'
exit 0

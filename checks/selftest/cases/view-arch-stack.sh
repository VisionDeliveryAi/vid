#!/bin/sh
# Purpose: selftest case — the stack as written (v0.26.10.2 spec R6). The viewer fixture with view_arch. Convicts
# unless now's stack is the first table under `## Stack` only — Language and Database, each choice and its ruled-out
# alternatives as written — and a third column whose header does not start FORBIDDEN gives null. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-stack: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
varch "$N" | grep -qF '"stack":[{"layer":"Language","choice":"Lang A 3","ruledOut":"Lang B, Lang C"}' || fail "the stack is not as written: $(varch "$N" | grep -A2 stack)"
varch "$N" | grep -qF '{"layer":"Database","choice":"Store X 16","ruledOut":"Store Y"}' || fail 'Database is missing'
varch "$N" | grep -q '"Not"' && fail 'a second table under Stack was read'
sed 's/| FORBIDDEN alternatives (named) |/| Notes |/' BASELINE.md > B.x && mv B.x BASELINE.md; g add -A; vcommit 11:50 'no ruled-out column'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
varch "$N" | grep -qF '{"layer":"Language","choice":"Lang A 3","ruledOut":null}' || fail "a column that rules nothing out is read as one: $(varch "$N" | grep Language)"
exit 0

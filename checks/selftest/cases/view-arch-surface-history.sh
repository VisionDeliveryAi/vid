#!/bin/sh
# Purpose: selftest case — the way in and its history (v0.26.10.2 spec R16). The viewer fixture with view_arch at
# 11:40 (every row added), app/s1's surface changed at 11:50, its responsibility alone at 12:00, its surface again at
# 12:10, and a commit at 12:05 on a side branch, not on HEAD's first-parent history. Convicts unless now's app/s1
# lists three surface changes (the row added, from null; then each change, from and to), the responsibility-only
# commit none, a snapshot requested at 11:50 the first two only, and the side commit's snapshot null. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-surface-history: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40; A=$(git rev-parse --short=7 HEAD)
sed 's/— find() |/— find(), count() |/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A; vcommit 11:50 'count'; B=$(git rev-parse --short=7 HEAD)
sed 's/| Finding things |/| Finding all things |/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A; vcommit 12:00 'wording'
BR=$(git rev-parse --abbrev-ref HEAD); git checkout -q -b side; printf 'side\n' > side.txt; g add -A; vcommit 12:05 'a side commit'; SIDE=$(git rev-parse HEAD); git checkout -q "$BR"
sed 's/— find(), count() |/— find() |/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A; vcommit 12:10 'count gone'; D=$(git rev-parse --short=7 HEAD)
vview . --out "$T/out" --at "$B" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
vview . --out "$T/out" --at "$SIDE" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
H1="{\"commit\":\"$A\",\"time\":\"2026-01-01T11:40:00Z\",\"from\":null,\"to\":\"\`app.s1.api\` — find()\"}"
H2="{\"commit\":\"$B\",\"time\":\"2026-01-01T11:50:00Z\",\"from\":\"\`app.s1.api\` — find()\",\"to\":\"\`app.s1.api\` — find(), count()\"}"
H3="{\"commit\":\"$D\",\"time\":\"2026-01-01T12:10:00Z\",\"from\":\"\`app.s1.api\` — find(), count()\",\"to\":\"\`app.s1.api\` — find()\"}"
vmod "$T/out/now.html" app/s1 | grep -qF "\"surfaceHistory\":[$H1,$H2,$H3]}" || fail "now's app/s1 history is not the three surface changes: $(vmod "$T/out/now.html" app/s1)"
vmod "$T/out/20260101T115000Z-requested.html" app/s1 | grep -qF "\"surfaceHistory\":[$H1,$H2]}" || fail "the 11:50 snapshot's history is not the first two: $(vmod "$T/out/20260101T115000Z-requested.html" app/s1)"
vmod "$T/out/20260101T120500Z-requested.html" app/s1 | grep -qF '"surfaceHistory":null}' || fail "the side commit's history is not null: $(vmod "$T/out/20260101T120500Z-requested.html" app/s1)"
exit 0

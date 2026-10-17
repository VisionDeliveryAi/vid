#!/bin/sh
# Purpose: selftest case — read only on a live run (v0.9.7.4 spec 3.1–3.2, R2, R3). The viewer fixture, its run
# active, with a second live run in a linked worktree of the same repository (its own .vid/RUN-STATE.md, run:
# active, a plan block of its own) — the checkouts a helper looking for "the" live run would find. Convicts
# unless a run leaves both checkouts, the shared .git and both .vid/ byte for byte as they were; and unless the
# test states read come from the view root: the worktree's plan (ROW-001 in a step S9) appears in no snapshot.
Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-readonly-live: $*" >&2; exit 1; }
view_project "$T/repo"
g worktree add -q --detach "$T/wt" HEAD 2>/dev/null || fail 'no worktree'
mkdir -p "$T/wt/.vid"; printf 'run: active\nsession: S2\nplan: required\n\n## The plan\n\n```vid-plan\nstep S9 | name: elsewhere | modules: app/s3 | builds-on: - | rows: ROW-001 | lane: builder\nshared: x\n```\n' > "$T/wt/.vid/RUN-STATE.md"
printf 'stage name=develop state=start session=S2 at=%s\n' "$(utcnow)" > "$T/wt/.vid/metrics-events"
snap() { (cd "$T" && find repo wt -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(git hash-object "$f")" "$f"; done) > "$1"; }
snap "$T/before"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
snap "$T/after"
cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2; fail 'a checkout changed'; }
for f in "$T"/out/*.html; do if vdata "$f" | grep -q '"S9"'; then fail "$(basename "$f") read the worktree's plan"; fi; done
vdata "$T/out/now.html" | grep -q '{"id":"ROW-001","kind":"behavior",.*"step":"S1"' || fail 'ROW-001 is not in S1 at now'
exit 0

#!/bin/sh
# Purpose: selftest case — work done once stays done (v0.9.7.4 spec 3.5, R6). The viewer fixture. Convicts unless a
# second run with nothing new prints "nothing new" and leaves every file of the output folder, its cache included,
# as it was; after one new commit only now's data is computed again; and after one new milestone (a step closed at
# 11:45, after a commit at 11:40) only that moment's data and now's are computed, its neighbours' pages naming it as
# their next and previous. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-incremental: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r1" 2>&1 || fail "the first run failed: $(cat "$T/r1")"
snap() { (cd "$T/out" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s %s\n' "$(git hash-object "$f")" "$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f")" "$f"; done) > "$1"; }
snap "$T/a"; sleep 1
vview . --out "$T/out" > "$T/r2" 2>&1 || fail "the second run failed: $(cat "$T/r2")"
grep -q '^ViD view: nothing new' "$T/r2" || fail "the second run did not say nothing new: $(cat "$T/r2")"
snap "$T/b"; cmp -s "$T/a" "$T/b" || { diff "$T/a" "$T/b" >&2; fail 'a run with nothing new wrote'; }
printf 'more\n' >> README.md; g add -A; vcommit 11:40 'one commit'
vview . --out "$T/out" > "$T/r3" 2>&1 || fail "the third run failed: $(cat "$T/r3")"
[ "$(grep '^ViD view: computed ' "$T/r3" | sed 's/^ViD view: computed \([^ ]*\) .*/\1/')" = now.html ] || fail "one commit computed more than now: $(grep computed "$T/r3")"
printf 'step-closed step=S2 report=r2 at=%s\n' "$(vt 11:45)" >> .vid/metrics-events
vview . --out "$T/out" > "$T/r4" 2>&1 || fail "the fourth run failed: $(cat "$T/r4")"
[ "$(grep '^ViD view: computed ' "$T/r4" | sed 's/^ViD view: computed \([^ ]*\) .*/\1/' | LC_ALL=C sort | tr '\n' ' ')" = '20260101T114500Z-step-closed.html now.html ' ] || fail "one milestone computed other moments: $(grep computed "$T/r4")"
vdata "$T/out/20260101T112000Z-checkpoint.html" | grep -q '"next":{"label":"S2 closed","time":"2026-01-01T11:45:00Z","commit":"[0-9a-f]*","file":"20260101T114500Z-step-closed.html"}' || fail "the checkpoint's next is not the new moment"
vdata "$T/out/now.html" | grep -q '"previous":{"label":"S2 closed",.*"file":"20260101T114500Z-step-closed.html"}' || fail "now's previous is not the new moment"
exit 0

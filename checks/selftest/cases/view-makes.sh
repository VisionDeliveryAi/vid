#!/bin/sh
# Purpose: selftest case — the command (v0.9.7.4 spec 3.1, R1). The viewer fixture. Convicts unless one run
# of viewer/view.sh says before it starts how many snapshots it will compute (no estimate on a first run), makes
# now.html, index.html and one file per distinct milestone moment named <UTC>-<milestone>.html (the seven of the
# fixture), and ends naming what it made and the seconds it took; and unless, after one new commit, the next run
# prints an estimate from the previous run's per-snapshot time, labelled an estimate. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-makes: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/run1" 2>&1 || fail "the run failed: $(cat "$T/run1")"
grep -q '^ViD view: 8 snapshot(s) to compute for repo — no estimate yet' "$T/run1" || fail "no count before the start: $(head -n 2 "$T/run1")"
for f in 20260101T091000Z-prd-ratified 20260101T092000Z-prd-ratified 20260101T100000Z-setup-done 20260101T101000Z-building-started 20260101T104000Z-step-closed 20260101T105000Z-slice-closed 20260101T112000Z-checkpoint now index; do
  [ -s "$T/out/$f.html" ] || fail "$f.html was not made"; done
[ "$(ls "$T/out" | grep -c '\.html$')" = 9 ] || fail "not nine pages: $(ls "$T/out")"
tail -n 1 "$T/run1" | grep -qE '^ViD view: made 8 snapshot\(s\).* in [0-9]+ s — ' || fail "the end does not say what it made and its time: $(tail -n 1 "$T/run1")"
printf 'more\n' >> README.md; g add -A; vcommit 11:40 'more docs'
vview . --out "$T/out" > "$T/run2" 2>&1 || fail "the second run failed: $(cat "$T/run2")"
grep -qE '^ViD view: 1 snapshot\(s\) to compute for repo — estimate about [0-9]+ s, from the previous run'"'"'s [0-9]+ s per snapshot \(an estimate\)' "$T/run2" || fail "no estimate from the previous run: $(head -n 2 "$T/run2")"
exit 0

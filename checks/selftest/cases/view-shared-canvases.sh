#!/bin/sh
# Purpose: selftest case — snapshots share their canvases (v0.9.8.1 R23). The viewer fixture: every snapshot naming it loads
# the canvas by <script src="canvases/<key>.js">, one asset for all of them, holding the canvas once; no snapshot
# carries the canvas inline. The canvas changed in a later commit and the viewer run again: a second asset, the
# snapshots before the change still loading the first, which is kept, and the new one loading the second. Each
# snapshot passes the check. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-shared-canvases: $*" >&2; cat "$T/r" >&2 2>/dev/null; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail 'the run failed'
srcs() { grep -oE 'src="canvases/[0-9a-f]+\.js"' "$1" | sed 's/^src="//; s/"$//'; }
[ "$(ls "$T/out/canvases" | grep -c '\.js$')" -eq 1 ] || fail "not one canvas asset: $(ls "$T/out/canvases")"
A1=$(ls "$T/out/canvases")
for f in "$T"/out/*.html; do
  _s=$(srcs "$f"); [ -z "$_s" ] || [ "$_s" = "canvases/$A1" ] || fail "$(basename "$f") does not load the one asset"   # none before the design exists
  grep -q 'CANVAS_RUNTIME = 1' "$f" && fail "$(basename "$f") carries the canvas inline"
  sh "$VIEWER_SH" --check "$f" > "$T/r" 2>&1 || fail "$(basename "$f") fails the check"
done
[ "$(srcs "$T/out/now.html")" = "canvases/$A1" ] || fail 'the latest snapshot does not load the asset'
[ "$(grep -o 'CANVAS_RUNTIME = 1' "$T/out/canvases/$A1" | grep -c .)" -eq 1 ] || fail 'the asset does not hold the canvas once'
# the canvas changes later: a second asset, the older snapshots keep the first
OLD=$(ls "$T"/out/*checkpoint*.html | head -n 1)
sed 's/the empty shelf/the empty shelf, redrawn/' "design/screens/P Pages.dc.html" > x && mv x "design/screens/P Pages.dc.html"
g add -A; vcommit 11:40 'the canvas redrawn'
vview . --out "$T/out" > "$T/r" 2>&1 || fail 'the second run failed'
[ "$(ls "$T/out/canvases" | grep -c '\.js$')" -eq 2 ] || fail "the redrawn canvas is not a second asset: $(ls "$T/out/canvases")"
[ "$(srcs "$OLD")" = "canvases/$A1" ] && [ -f "$T/out/canvases/$A1" ] || fail 'an older snapshot lost its own canvas'
[ "$(srcs "$T/out/now.html")" != "canvases/$A1" ] || fail 'the latest snapshot does not load the redrawn canvas'
grep -q 'redrawn' "$T/out/$(srcs "$T/out/now.html")" || fail 'the new asset is not the redrawn canvas'
exit 0

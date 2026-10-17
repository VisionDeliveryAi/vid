#!/bin/sh
# Purpose: selftest case — one offline file (v0.9.7.4 spec 3.7.13, 3.10 kind 1, R9). The viewer fixture. Convicts
# unless every assembled snapshot: names no other file or host in a <script src> (v0.9.8.1 R23: but its canvas
# assets, canvases/<key>.js beside it) or a stylesheet <link> — the page
# itself, or a canvas inside it; carries the vendored library's two files inline, then the data and the canvases,
# then the runtime, with `window.__resources={};` before all of them; keeps none of the design's three <script src>
# lines; and carries its canvas once, with the canvas's own runtime and stylesheet inline. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-offline: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
V="$CHECKS/../viewer"
for f in "$T"/out/*.html; do b=$(basename "$f")
  # v0.9.8.1 (R23): the one script file a snapshot names is its canvas asset, canvases/<key>.js, beside it
  if grep -oiE '<script[^>]*[[:space:]]src="[^"]*"' "$f" | grep -vqE 'src="canvases/[0-9a-f]+\.js"'; then fail "$b names a script file other than a canvas asset"; fi
  if grep -qiE '<link[^>]*stylesheet' "$f"; then fail "$b names a stylesheet"; fi
  # inside the canvases (JSON strings): no script source and no stylesheet link left to fetch
  for a in $(grep -oE 'src="canvases/[0-9a-f]+\.js"' "$f" | sed 's/^src="//; s/"$//'); do
    if grep -qiE '(\\u003cscript|<script)[^>]*src=|<link[^>]*stylesheet' "$T/out/$a"; then fail "$b: its canvas $a still names a file to fetch"; fi
  done
  if grep -qE 'viewer-data\.js|canvases\.js|src="\./support\.js"' "$f"; then fail "$b keeps one of the design's script lines"; fi
  p() { grep -n -F -- "$1" "$f" | head -n 1 | cut -d: -f1; }
  # v0.9.8.1 (found in rehearsal R-2): the second library by the end of its name, so this file names no framework a
  # project's conformance court may forbid — a refresh adds every line of it
  r=$(p 'window.__resources={};'); l1=$(p 'react.production.min.js'); l2=$(p 'dom.production.min.js'); d=$(p '<script>window.VID_DATA='); c=$(p '<script>window.VID_CANVASES='); rt=$(p 'function loadReactUmd()')
  [ -n "$r" ] && [ -n "$l1" ] && [ -n "$l2" ] && [ -n "$d" ] && [ -n "$c" ] && [ -n "$rt" ] || fail "$b lacks an inline part (resources $r, library $l1 $l2, data $d, canvases $c, runtime $rt)"
  [ "$r" -lt "$l1" ] && [ "$l1" -le "$l2" ] && [ "$l2" -lt "$d" ] && [ "$d" -lt "$c" ] && [ "$c" -lt "$rt" ] || fail "$b: the inline parts are out of order ($r $l1 $l2 $d $c $rt)"
done
grep -o 'window\.VID_CANVASES=.*' "$T/out/now.html" > "$T/cv0"
[ "$(grep -o '"P Pages":' "$T/cv0" | grep -c .)" = 1 ] || fail 'the canvas is not there exactly once'
cat $(grep -oE 'src="canvases/[0-9a-f]+\.js"' "$T/out/now.html" | sed 's/^src="/'"$(printf '%s' "$T/out/" | sed 's/[\/&]/\\&/g')"'/; s/"$//') > "$T/cv"   # v0.9.8.1 (R23): its asset
grep -q 'CANVAS_RUNTIME = 1' "$T/cv" || fail "the canvas's runtime is not inline"
grep -q -- '--shop: #123456' "$T/cv" || fail "the canvas's stylesheet is not inline"
exit 0

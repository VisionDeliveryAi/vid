#!/bin/sh
# Purpose: selftest case — a copied viewer folder still opens (v0.9.8.1 R23). The viewer fixture's output copied to a
# folder whose path holds spaces: every <script src> of every snapshot is relative and resolves inside the copy, and
# each copied snapshot passes the check; with its canvas asset removed from the copy, the check refuses it, naming the
# asset; and a snapshot naming a script outside canvases/ is refused. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-offline-copied-folder: $*" >&2; cat "$T/r" >&2 2>/dev/null; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail 'the run failed'
mkdir -p "$T/a copy /viewer"; cp -R "$T/out/." "$T/a copy /viewer/"; C="$T/a copy /viewer"
for f in "$C"/*.html; do
  for s in $(grep -oE '<script[^>]*[[:space:]]src="[^"]*"' "$f" | sed -E 's/.*src="([^"]*)"/\1/'); do
    case "$s" in /*|*://*) fail "$(basename "$f") loads $s, which is not relative" ;; esac
    [ -f "$C/$s" ] || fail "$(basename "$f") loads $s, which the copy lacks"
  done
  sh "$VIEWER_SH" --check "$f" > "$T/r" 2>&1 || fail "the copied $(basename "$f") fails the check"
done
A=$(ls "$C/canvases" | head -n 1); rm "$C/canvases/$A"
if sh "$VIEWER_SH" --check "$C/now.html" > "$T/r" 2>&1; then fail 'a snapshot whose canvas asset is gone passed the check'; fi
grep -q "loads canvases/$A, which is not beside it" "$T/r" || fail 'the check does not name the missing asset'
sed 's#<script src="canvases/#<script src="https://example.invalid/#' "$T/out/now.html" > "$T/bad.html"
if sh "$VIEWER_SH" --check "$T/bad.html" > "$T/r" 2>&1; then fail 'a snapshot loading another host passed the check'; fi
exit 0

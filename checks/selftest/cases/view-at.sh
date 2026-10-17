#!/bin/sh
# Purpose: selftest case — one extra snapshot at a commit or a time (v0.9.7.4 spec 3.1, R1). The viewer fixture.
# Convicts unless `--at <commit>` (the documents commit, 09:30) makes 20260101T093000Z-requested.html at that commit and
# `--at 2026-01-01T10:15:00Z` makes 20260101T101500Z-requested.html at the last first-parent commit by then (the same
# commit), both marked requested in the index's snapshot list and kept by a later run without --at; and unless an
# --at naming neither a commit nor a UTC time is refused. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-at: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" --at "$C_DOCS" > "$T/r" 2>&1 || fail "--at a commit failed: $(cat "$T/r")"
vview . --out "$T/out" --at 2026-01-01T10:15:00Z > "$T/r" 2>&1 || fail "--at a time failed: $(cat "$T/r")"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run without --at failed: $(cat "$T/r")"
for f in 20260101T093000Z-requested 20260101T101500Z-requested; do [ -s "$T/out/$f.html" ] || fail "$f.html was not made"; done
vdata "$T/out/index.html" > "$T/j"
S=$(git rev-parse --short=7 "$C_DOCS")
for f in 20260101T093000Z-requested.html 20260101T101500Z-requested.html; do
  grep -q "{\"label\":\"Requested\",\"moment\":{\"commit\":\"$S\",\"time\":\"[^\"]*\"},\"milestones\":\[\"requested\"\],\"file\":\"$f\",\"replayed\":true,\"requested\":true}" "$T/j" || fail "$f is not listed as requested at $S"; done
vdata "$T/out/20260101T101500Z-requested.html" | grep -q '"requested":true,"mode":"snapshot"' || fail 'the requested snapshot does not say it was requested'
if vview . --out "$T/out" --at yesterday > "$T/r" 2>&1; then fail '--at yesterday was accepted'; fi
grep -q 'neither a commit nor a UTC time' "$T/r" || fail "the refusal does not say why: $(cat "$T/r")"
exit 0

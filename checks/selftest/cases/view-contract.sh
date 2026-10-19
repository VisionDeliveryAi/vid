#!/bin/sh
# Purpose: selftest case — the data contract (v0.9.7.4 spec 3.6, R7). The viewer fixture. Convicts unless `view.sh
# --check` passes every snapshot and the index, and fails, naming the fault, each of: a promise without its id, a
# field of the wrong type, a promise citing a step no snapshot part holds, a page with no data, and data that is not
# JSON; and (v0.26.10.2 R10, with view_arch) a module missing its placement, a mayUse name that is no module, a
# module step no snapshot part holds and a module decision that is no technical decision. And unless viewer/DATA.md
# names every part the check requires. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-contract: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
for f in "$T"/out/*.html; do sh "$VIEWER_SH" --check "$f" > "$T/c" 2>&1 || fail "$(basename "$f") fails the check: $(cat "$T/c")"; done
bad() { # <what> <sed expression> <expected message>
  sed "$2" "$T/out/now.html" > "$T/out/bad.html"   # v0.9.8.1 (R23): beside its canvas assets
  if sh "$VIEWER_SH" --check "$T/out/bad.html" > "$T/c" 2>&1; then fail "the check passed $1"; fi
  grep -q "$3" "$T/c" || fail "the check did not name $1: $(cat "$T/c")"; }
bad 'a promise without its id' 's/{"id":"ROW-003","kind"/{"kind"/' '\.promises\[2\]\.id is missing'
bad 'a field of the wrong type' 's/"built":true/"built":"yes"/' '\.promises\[\]\.built is string, not boolean'
bad 'a dangling step' 's/"step":"S2"/"step":"S9"/' 'cites S9, which is no step'
bad 'a page with no data' '/^<script>window\.VID_DATA=/d' 'carries no window.VID_DATA'
bad 'data that is not JSON' 's/^\("promises":\[\)/\1,/' 'not JSON'
bad 'a module without its placement' 's/"placement":"level","level":0,//' 'placement is missing'
bad 'a may-use name that is no module' 's/"mayUse":\["app\/s3"\]/"mayUse":["app\/s9"]/' 'cites app/s9, which is no module'
bad 'a module step that is no step' 's/"steps":\["S2"\],"placement"/"steps":["S7"],"placement"/' 'cites S7, which is no step'
bad 'a module decision that is no technical decision' 's/"decisions":\[{"id":"D-001","by":"label"/"decisions":[{"id":"D-077","by":"label"/' 'cites D-077, which is no technical decision'
for part in meta goals capabilities users journeys requirements nonGoals screens promises steps decisions architecture needsYou activity counts changes; do
  grep -q "^### \`$part\`" "$CHECKS/../viewer/DATA.md" || fail "viewer/DATA.md does not name the part $part"; done
exit 0

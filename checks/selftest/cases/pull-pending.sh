#!/bin/sh
# Purpose: selftest case — an unfinished run's report is fetched later (v0.26.10.12 spec R6, R9). The planner's toy
# (fixtures/tickets.sh gh_vid) and the fake gh: `github.sh pull --commit` on a commit whose CI run is in progress
# downloads nothing and leaves no <run>-<attempt>.none; once the run is complete with its report, the next pull fetches
# it. A complete run whose report is missing leaves .none, and when the report appears the next pull fetches it and
# drops the .none — never cached forever. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "pull-pending: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
awk '/^labels-prefix:/ { print; print "ci-workflow: CI"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A && g commit -qm 'ci-workflow'
tk_dev 'a merge' app/main.py 'x'; C=$(git -C "$T/code.git" rev-parse main); D=.vid/tickets/commit-$C/artifacts
printf '<testsuites><testsuite name="t"><testcase classname="tests/invariants/test_a.py" name="test_1[ROW-001]" time="0.1"/></testsuite></testsuites>\n' > "$T/r.xml"
printf '500 1 %s CI workflow_dispatch in_progress -\n' "$C" > "$T/gh/runs"
sh checks/github.sh pull --commit "$C" > "$T/out" 2>&1 || fail 'pull failed'
[ ! -e "$D/500-1.none" ] || fail 'an in-progress run left a .none'
[ ! -d "$D/500-1" ] || fail 'an in-progress run was downloaded'
grep -q '^gh run download 500' "$T/gh/log" && fail 'the report of an in-progress run was asked for'
printf '500 1 %s CI workflow_dispatch completed success\n' "$C" > "$T/gh/runs"; mkdir -p "$T/gh/artifacts/500/vid-junit-1"; cp "$T/r.xml" "$T/gh/artifacts/500/vid-junit-1/"
sh checks/github.sh pull --commit "$C" > "$T/out" 2>&1 || fail 'the second pull failed'
[ -f "$D/500-1/r.xml" ] || fail 'the completed run'"'"'s report was not fetched'
# a complete run with its report missing, then present
printf '501 1 %s CI push completed success\n' "$C" >> "$T/gh/runs"
sh checks/github.sh pull --commit "$C" > "$T/out" 2>&1; [ -f "$D/501-1.none" ] || fail 'a complete run without a report left no .none'
mkdir -p "$T/gh/artifacts/501/vid-junit-1"; cp "$T/r.xml" "$T/gh/artifacts/501/vid-junit-1/"
sh checks/github.sh pull --commit "$C" > "$T/out" 2>&1
[ -f "$D/501-1/r.xml" ] && [ ! -e "$D/501-1.none" ] || fail 'a missing report was cached: the next pull did not fetch it'
exit 0

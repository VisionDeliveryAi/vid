#!/bin/sh
# Purpose: selftest case — shared test code edited (v0.9.6.1 spec 3.4,
# revision 11, amendment 5; §6). The import above the first test changes,
# naming no row: all three rows still pass — the close's rows file names
# what such a change affects. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-shared-top: $*" >&2; exit 1; }
edit_repo "$T/repo"
line 1 'import sys'; commit_all 'the import changed'
for r in ROW-001 ROW-002 ROW-003; do [ "$(state "$r")" = pass ] || fail "$r went stale on a shared line that names no row"; done
exit 0

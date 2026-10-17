#!/bin/sh
# Purpose: selftest case — a test renamed (v0.9.6.1 spec 3.4, revision 11,
# amendment 5; §6). test_002 becomes test_two: the receipt's case name is
# not found in the file at now, so ROW-002 falls back to the whole file and
# reads stale; ROW-003, whose test is untouched, still passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-renamed: $*" >&2; exit 1; }
edit_repo "$T/repo"
line 8 'def test_two():'; commit_all 'test_002 renamed'
[ "$(state ROW-002)" = stale ] || fail "the renamed test's row did not fall back to the whole file: $(state ROW-002)"
[ "$(state ROW-003)" = pass ] || fail 'the rename staled ROW-003'
exit 0

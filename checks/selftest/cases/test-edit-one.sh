#!/bin/sh
# Purpose: selftest case — one test edited (v0.9.6.1 spec 3.4, revision 11,
# amendment 5; §6). Three row tests in one file pass on a receipt; the body
# of the middle one changes. Under the gate only ROW-002 reads stale; the
# other two still pass, labelled with the commit they passed at. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-one: $*" >&2; exit 1; }
edit_repo "$T/repo"
line 10 '    b = 3'; commit_all 'test_002 changed'
[ "$(state ROW-002)" = stale ] || fail "the edited test's row is not stale: $(state ROW-002)"
[ "$(state ROW-001)" = pass ] && [ "$(state ROW-003)" = pass ] || fail 'an edit to test_002 staled its neighbours'
sh checks/plan.sh map --all > "$T/map"; sh checks/evidence.sh rows --at HEAD --map "$T/map" | grep -q '^ROW-001	pass	passed at ' || fail 'the older pass is not labelled with its commit'
exit 0

#!/bin/sh
# Purpose: selftest case — a line deleted inside a test (v0.9.6.1 spec 3.4,
# revision 11, amendment 5; §6). A pure deletion in test_002's body stales
# ROW-002 only. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-deletion: $*" >&2; exit 1; }
edit_repo "$T/repo"
awk 'NR != 9' "$G4FILE" > "$G4FILE.x" && mv "$G4FILE.x" "$G4FILE"; commit_all 'a line of test_002 deleted'
[ "$(state ROW-002)" = stale ] || fail "the deletion did not stale ROW-002: $(state ROW-002)"
[ "$(state ROW-001)" = pass ] && [ "$(state ROW-003)" = pass ] || fail 'the deletion staled a neighbour'
exit 0

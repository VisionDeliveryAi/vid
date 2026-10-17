#!/bin/sh
# Purpose: selftest case — the red result names the assertion's line from the failure's text
# (v0.9.7.0.7 spec 3.4, R8; §6 D-1). The red-line fixture. A failure whose text holds frames
# `/app/tests/invariants/links.sh:12`, `tests/invariants/links.sh:40` and then
# `tests/invariants/harness.sh:99`, its testcase declared at line 8. Convicts unless `sh
# checks/evidence.sh red` prints the case with ` at tests/invariants/links.sh:40` — the last frame in
# the row's test file, not the harness's, not the declaration — keeps the summary and the group line,
# and gives a case naming ROW_1010 (a longer id) its own file's frame, never links.sh's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/red-line.sh"
fail() { echo "red-line-text: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rl_dir
rl_case 'test_ROW_101_resolves' ' file="tests/invariants/links.sh" line="8"' 'def helper(): ...
/app/tests/invariants/links.sh:12: in test_ROW_101_resolves
tests/invariants/links.sh:40: in check
    assert got == want
tests/invariants/harness.sh:99: AssertionError'
rl_case 'test_ROW_1010_other' ' file="tests/invariants/other.sh" line="3"' 'tests/invariants/links.sh:7: in shared
tests/invariants/other.sh:21: AssertionError'
rl_red
grep -q '^red r.xml setup=0 failed=2$' "$T/out" || fail 'the summary line changed'
grep -q '^group failed n=2 message="AssertionError: wrong"$' "$T/out" || fail 'the group line changed'
grep -qx '    tests.invariants.links::test_ROW_101_resolves at tests/invariants/links.sh:40' "$T/out" || fail 'the case does not name the assertion line links.sh:40'
grep -qx '    tests.invariants.links::test_ROW_1010_other at tests/invariants/other.sh:21' "$T/out" || fail 'the ROW_1010 case was not given its own file'"'"'s frame'
exit 0

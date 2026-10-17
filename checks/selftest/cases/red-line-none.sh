#!/bin/sh
# Purpose: selftest case — with neither a frame nor attributes, the red case prints as before
# (v0.9.7.0.7 spec 3.4, R8; §6 D-3). The red-line fixture. A failure whose text names no line of the
# row's test file and whose testcase has no file= or line=. Convicts unless the case line is exactly
# `    tests.invariants.links::test_ROW_101_resolves`, with nothing after it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/red-line.sh"
fail() { echo "red-line-none: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rl_dir
rl_case 'test_ROW_101_resolves' '' 'expected 302, got 404'
rl_red
grep -qx '    tests.invariants.links::test_ROW_101_resolves' "$T/out" || fail 'the case line is not as before'
exit 0

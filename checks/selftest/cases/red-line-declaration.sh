#!/bin/sh
# Purpose: selftest case — the red result falls back to the testcase's attributes, marked (v0.9.7.0.7
# spec 3.4, R8; §6 D-2). The red-line fixture. A failure whose text names no line of the row's test
# file (only `tests/invariants/harness.sh:99`), declared at `file="tests/invariants/links.sh"
# line="853"`. Convicts unless the case prints ` at tests/invariants/links.sh:853 (declaration)`.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/red-line.sh"
fail() { echo "red-line-declaration: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rl_dir
rl_case 'test_ROW_101_resolves' ' file="tests/invariants/links.sh" line="853"' 'tests/invariants/harness.sh:99: AssertionError'
rl_red
grep -qx '    tests.invariants.links::test_ROW_101_resolves at tests/invariants/links.sh:853 (declaration)' "$T/out" || fail 'the attributes are not the marked fallback'
exit 0

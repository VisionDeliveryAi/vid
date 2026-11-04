#!/bin/sh
# Purpose: selftest case — the one report reader (v0.26.10.9 spec R17; §5 junit-reader). A JUnit XML report with one
# case of each status — passed (self-closing, its classname the test path), failed (a failure child, the path in its
# file attribute), error (its name already `<test path>::<name>`) and skipped — gives exactly four `case` lines, ids
# `<test path>::<name>`, with their statuses and seconds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "junit-reader: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/r.xml" <<'X'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites><testsuite name="acceptance" tests="4">
  <testcase classname="tests/acceptance/test_notes.py" name="test_saved[ROW-002]" time="0.12"/>
  <testcase classname="acceptance.notes" file="tests/acceptance/test_notes.py" name="test_own[ROW-003]" time="0.2">
    <failure message="expected &quot;mine&quot;">a trace</failure>
  </testcase>
  <testcase name="tests/acceptance/test_signin.py::test_wrong[ROW-001]" time="1"><error message="boom"/></testcase>
  <testcase classname="tests/acceptance/test_signin.py" name="test_later[ROW-004]"><skipped/></testcase>
</testsuite></testsuites>
X
sh "$CHECKS/ticket.sh" junit "$T/r.xml" > "$T/out" 2>&1 || fail 'the reader failed'
cat > "$T/want" <<'W'
case tests/acceptance/test_notes.py::test_saved[ROW-002] passed 0.12
case tests/acceptance/test_notes.py::test_own[ROW-003] failed 0.2
case tests/acceptance/test_signin.py::test_wrong[ROW-001] error 1
case tests/acceptance/test_signin.py::test_later[ROW-004] skipped 0
W
cmp -s "$T/want" "$T/out" || { diff "$T/want" "$T/out" >&2; fail 'the four case lines differ'; }
exit 0

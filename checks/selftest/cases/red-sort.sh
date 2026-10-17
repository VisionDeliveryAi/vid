#!/bin/sh
# Purpose: selftest case — red sorted by where it stops (v0.9.6 spec 3.11,
# R11; §7 case 32). A JUnit receipt with 23 failures sharing one message,
# 2 failures with another, 4 errors and passes: `evidence.sh red` prints
# `setup=4 failed=25`, one `setup` group of 4 and a `failed` group of 23
# before the group of 2, each with its cases. A receipt in another format
# (the results reader's case lines) is sorted setup and failed, ungrouped
# by message. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; mkdir -p checks/extractors .vid/ledger-results
cp "$CHECKS/evidence.sh" checks/
fail() { echo "red-sort: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ printf '<testsuite>\n'
  i=1; while [ $i -le 23 ]; do printf '<testcase classname="tests.j1" name="test_%s"><failure message="login fixture returned 403&#10;detail">x</failure></testcase>\n' $i; i=$((i + 1)); done
  printf '<testcase classname="tests.m1" name="test_a"><failure message="wrong total">x</failure></testcase>\n<testcase classname="tests.m1" name="test_b"><failure message="wrong total">x</failure></testcase>\n'
  i=1; while [ $i -le 4 ]; do printf '<testcase classname="tests.boot" name="test_%s"><error message="no database">x</error></testcase>\n' $i; i=$((i + 1)); done
  printf '<testcase classname="tests.ok" name="test_pass"/>\n</testsuite>\n'; } > .vid/ledger-results/r.xml
sh checks/evidence.sh red r.xml > "$T/out" || fail 'evidence.sh red failed'
grep -qx 'red r.xml setup=4 failed=25' "$T/out" || fail 'the counts are not setup=4 failed=25'
grep -qx 'group setup n=4' "$T/out" || fail 'no setup group of 4'
[ "$(grep '^group failed' "$T/out" | head -n 1)" = 'group failed n=23 message="login fixture returned 403"' ] || fail 'the 23 sharing one message are not one group, first'
grep -qx 'group failed n=2 message="wrong total"' "$T/out" || fail 'no group of 2'
[ "$(grep -c '^    tests\.j1::test_' "$T/out")" -eq 23 ] || fail 'the group does not list its 23 cases'
printf 'case t.py::a failed 0.1\ncase t.py::b error 0.1\ncase t.py::c passed 0.1\n' > .vid/ledger-results/o.txt.cases; printf 'x\n' > .vid/ledger-results/o.txt
sh checks/evidence.sh red o.txt > "$T/out" || fail 'the other format failed'
grep -qx 'red o.txt setup=1 failed=1' "$T/out" || fail 'the other format is not sorted'
exit 0

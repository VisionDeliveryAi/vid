#!/bin/sh
# Purpose: selftest case — prd.sh's command line (v0.9.4 spec §3.1, §7 case
# 15): an unknown `--*` argument exits 1 with a message naming it, never
# read as the file path (the 0.9.3 court took `--pausee` as a missing file
# and exited 0 — failing open), whether or not a PRD.md is present;
# `--pause` is a flag separate from the mode, so `--pause --report` is
# defined: it prints the pause material and the report line last, and
# exits 0 even on a convicted file. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-flags: $*" >&2; exit 1; }
cp "$FIXTURES/prd-094-good.md" PRD.md
set +e
sh "$COURT" PRD.md --pausee >out.txt 2>err.txt; rc=$?
set -e
[ "$rc" -eq 1 ] || fail "--pausee exited $rc, expected 1"
grep -qF "unknown flag '--pausee'" err.txt || fail 'the unknown flag is not named'
mkdir empty && cd empty
set +e
sh "$COURT" --pausee >/dev/null 2>&1; rc=$?
set -e
[ "$rc" -eq 1 ] || fail "--pausee with no PRD.md exited $rc, expected 1"
cd ..
sh "$COURT" PRD.md --pause --report >rep0.txt 2>&1 || fail '--pause --report on the known-good fixture did not exit 0'
grep -q '^pause material (checks/prd.sh --pause, grammar 0.9.4)$' rep0.txt || fail '--pause --report printed no material'
grep -q '^size: demand=9 pilot=8 ' rep0.txt || fail '--pause --report printed no size line'
tail -n 1 rep0.txt | grep -q '^prd: items=' || fail 'the report line is not the last line'
sed 's/^\(REQ-003 .*\) | feature: FEAT-02$/\1/' PRD.md > BAD.md
if sh "$COURT" BAD.md --pause >/dev/null 2>&1; then fail 'the convicted file acquits under --pause'; fi
sh "$COURT" BAD.md --pause --report >rep.txt 2>&1 || fail '--pause --report on a convicted file did not exit 0'
grep -q '^GAP  join 16 (REQ-003)' rep.txt || fail '--pause --report did not print the gap'
grep -q '^prd: items=' rep.txt || fail '--pause --report did not print the report line'
grep -q '^pause material ' rep.txt || fail '--pause --report printed no material on a convicted file'
exit 0

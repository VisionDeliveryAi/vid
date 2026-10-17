#!/bin/sh
# Purpose: selftest case — the census leaves no broken-pipe line (v0.9.8.1 R13). An inventory larger than a pipe's
# buffer, holding a state-machine rule whose transition table alone is larger, with a site moving through its first
# transition and a guard reading its first state; the census runs with SIGPIPE ignored, as a parent process may pass
# it down. Convicts unless the census passes with nothing on standard error (a reader closing a pipe early — head,
# grep -q — left its writer a "Broken pipe" there). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "census-no-broken-pipe: $*" >&2; cat "$T/err" >&2 2>/dev/null; exit 1; }
mkdir -p tests/invariants; touch tests/invariants/test_rule911.py
{ printf '# toy\n```vid-inventory\ngrammar: 0.9.3\n'
  printf 'rule | RULE-911 | state-machine status: a>b'; i=0; while [ $i -lt 6000 ]; do printf ' s%d>t%d' $i $i; i=$((i + 1)); done
  printf " | printf 'app/a.py:10 a>b\\\\napp/g.py:7 a\\\\n' | T1 | tests/invariants/test_rule911.py\n"
  i=0; while [ $i -lt 2000 ]; do printf 'ROW-%04d | behavior | REQ-001 | n/a | n/a | padding %d | REQ-001 | owed: prerequisite — x\n' $i $i; i=$((i + 1)); done
  printf '```\n'; } > INVENTORY.md
[ "$(wc -c < INVENTORY.md)" -gt 200000 ] || fail 'the fixture is not larger than a pipe buffer'
ST=0; ( trap '' PIPE; sh "$CHECKS/census.sh" > "$T/out" 2> "$T/err" ) || ST=$?
[ "$ST" -eq 0 ] || fail "the census failed (exit $ST)"
[ ! -s "$T/err" ] || fail 'the census wrote to standard error'
exit 0

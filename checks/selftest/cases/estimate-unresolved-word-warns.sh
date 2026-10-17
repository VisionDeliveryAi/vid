#!/bin/sh
# Purpose: selftest case — a selection word the estimate cannot resolve is said (v0.9.8.1 R26, F-15). Kept receipts
# with t.py's cases: a request selecting `-k slow` keeps the rows' figure and prints `selection reaches more than the
# rows: give --expect`, naming the words; a request selecting the file prints no such line; with --expect given
# nothing is said. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/estimate-files.sh"
fail() { echo "estimate-unresolved-word-warns: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"; gate_on
F=tests/invariants/t.py
ef_hist h1 inline 540 "$F::test_a[ROW-001]=10" "$F::test_b=200" "$F::test_c=300"
touch "$T/hold"; export STUB_HOLD="$T/hold"
ef_req 'a keyword' -- -k slow
grep -q '^estimate [0-9]*s (start-up [0-9]*s + cases 10s) ' "$T/out" || fail "an unresolved selection changed the estimate: $(grep '^estimate' "$T/out")"
grep -q '^selection reaches more than the rows: give --expect (-k slow — no recorded case)' "$T/out" || fail 'the unresolved words are not said'
ef_req 'the file' -- "$F"
grep -q '^selection reaches more than the rows' "$T/out" && fail 'a resolved file was said to reach more'
ef_req 'a keyword, expected' --expect 99 -- -k slow
grep -q '^selection reaches more than the rows' "$T/out" && fail 'the warning was printed beside --expect'
rm -f "$T/hold"
exit 0

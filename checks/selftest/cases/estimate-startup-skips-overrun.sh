#!/bin/sh
# Purpose: selftest case — the start-up median leaves out a receipt whose case seconds exceed its wall time (v0.9.8.1
# R11, F-10). Kept receipts at the home with start-ups 60, 70 and 66 s, and two whose case seconds exceed their event
# seconds (a merged split run): the estimate's start-up is 66 s, the median of the three, never pulled down by the
# two counted as 0 (which would give 60). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate-startup-skips-overrun: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
hist() { _n=$1; _s=$2; _c=$3; mkdir -p .vid/ledger-results
  printf 'case tests/invariants/t.py::test_009[ROW-009] passed %s\n' "$_c" > ".vid/ledger-results/$_n.cases"
  printf 'ledger-run seconds=%s kind=scoped report=%s status=0 role=builder at=%s\n' "$_s" "$_n" "$(utcnow)" >> .vid/metrics-events; }
gated_repo "$T/r"; gate_on
hist a 70 10; hist b 80 10; hist m1 18957 25431; hist m2 6686 12248; hist c 76 10
touch "$T/hold"; export STUB_HOLD="$T/hold"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the start-up' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
grep -q '^estimate [0-9]*s (start-up 66s + ' "$T/out" || fail "the start-up is not the median of the three that tell it: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")" > /dev/null 2>&1 || true
exit 0

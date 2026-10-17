#!/bin/sh
# Purpose: selftest case — an iterate's deployed pass that repeats the inline cases counts them again (v0.9.8.1 R12,
# F-11). With history giving ROW-001 10 s and no start-up history (90 s), under a harness declaring
# deployed-selector:: an iterate whose deployed selection repeats its inline file is estimated with the start-up and
# the cases once a pass (200 s), --expect too (280 s); one whose deployed selection shares no word with the
# inline one counts the cases once (190 s). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate-deployed-repeat: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"
printf '%s' "$COMPOSEFILE" | awk '{ print } /^x-vid-harness:/ { print "  deployed-selector: -m deployed" }' > docker-compose.test.yml
g add -A && g commit -qm 'a deployed selector'; gate_on
mkdir -p .vid/ledger-results; printf 'case tests/invariants/t.py::test_001[ROW-001] passed 10\n' > .vid/ledger-results/h.cases
printf 'ledger-run seconds=5 kind=scoped report=h status=0 role=builder at=%s\n' "$(utcnow)" >> .vid/metrics-events
touch "$T/hold"; export STUB_HOLD="$T/hold"
req() { _w=$1; shift; sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$_w" "$@" > "$T/out" 2>&1 || fail "the request '$_w' was refused"; }
req 'repeats' -- tests/invariants/t.py --deployed-selection tests/invariants/t.py -m deployed
grep -q '^estimate 200s (start-up 2 × 90s + cases 2 × 10s) ' "$T/out" || fail "a deployed pass repeating the inline file did not count the cases again: $(grep '^estimate' "$T/out")"
req 'repeats, expected' --expect 50 -- tests/invariants/t.py --deployed-selection tests/invariants/t.py
grep -q '^estimate 280s (start-up 2 × 90s + cases 2 × 50s, from --expect) ' "$T/out" || fail "--expect is not one pass's seconds: $(grep '^estimate' "$T/out")"
req 'apart' -- tests/invariants/t.py --deployed-selection tests/invariants/d.py
grep -q '^estimate 190s (start-up 2 × 90s + cases 10s) ' "$T/out" || fail "a deployed selection sharing no word counted the cases twice: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
exit 0

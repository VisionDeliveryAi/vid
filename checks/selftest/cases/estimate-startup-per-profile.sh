#!/bin/sh
# Purpose: selftest case — each pass's start-up from its own profile (v0.9.8.1 R32). Under a harness declaring
# deployed-selector:, inline overheads 30, 30, 30 and deployed ones 100, 100, 100: an iterate carrying both passes is
# estimated with start-up 30 s + 100 s deployed; an inline-only iterate with 30 s. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/estimate-files.sh"
fail() { echo "estimate-startup-per-profile: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ov() { printf 'ledger-run seconds=200 kind=%s report=%s status=0 tree=x run=r overhead=%s at=%s\n' "$1" "$2" "$3" "$(utcnow)" >> .vid/metrics-events; }
gated_repo "$T/r"
printf '%s' "$COMPOSEFILE" | awk '{ print } /^x-vid-harness:/ { print "  deployed-selector: -m deployed" }' > docker-compose.test.yml
g add -A && g commit -qm 'a deployed selector'; gate_on
for n in 1 2 3; do ov scoped "i$n.live.xml" 30; ov deployed "d$n.deployed.xml" 100; done
touch "$T/hold"; export STUB_HOLD="$T/hold"
ef_req 'both passes' -- tests/invariants/a.py --deployed-selection tests/invariants/d.py
grep -q '^estimate [0-9]*s (start-up 30s + 100s deployed + ' "$T/out" || fail "the two passes' start-ups are not their own: $(grep '^estimate' "$T/out")"
ef_req 'inline only' -- tests/invariants/a.py
grep -q '^estimate [0-9]*s (start-up 30s + ' "$T/out" || fail "an inline-only iterate is not on the inline start-up: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
exit 0

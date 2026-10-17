#!/bin/sh
# Purpose: selftest case — a capped result gives its retry figure (v0.9.7.3 spec 3.9, R9). ROW-003's history is a 1 s
# red; its green is held until the cap stops it, so a request at the red pace (cases=1) is capped: its result prints
# `retry: --expect 2` — twice the ticket's case seconds; a request that ends green prints no retry line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/hold*; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "cap-retry-figure: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"; gate_on
mkdir -p checks/extractors; printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh; g add -A && g commit -qm 'a reader'
mkdir -p .vid/ledger-results; printf 'case tests/invariants/t.py::test_003[ROW-003] failed 1\n' > .vid/ledger-results/red.cases
printf 'ledger-run seconds=1 kind=scoped report=red status=0 role=builder at=%s\n' "$(utcnow)" >> .vid/metrics-events
ask() { sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"; sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
waitend() { _i=0; while :; do _w=0; VID_WAIT_MAX=10 sh checks/test.sh wait "$1" > "$T/out" 2>&1 || _w=$?; [ "$_w" -eq 75 ] && [ "$_i" -lt 120 ] || return "$_w"; _i=$((_i + 1)); done; }
touch "$T/hold1"   # held until the cap stops it, never for a time
E=$(STUB_HOLD="$T/hold1" ask --type iterate --role builder --try t1 --rows ROW-003 --why 'the green, at the red pace' -- tests/x)
grep -qx 'cases=1' ".vid/requests/$E/request" || fail 'the ticket does not carry cases=1'
waitend "$E" || true; rm -f "$T/hold1"
[ "$(cat ".vid/requests/$E/state")" = capped ] || fail 'the slow green at the red pace was not capped'
grep -qx 'retry: --expect 2' ".vid/requests/$E/result" || fail 'the capped result has no retry figure of twice cases='
G=$(ask --type iterate --role builder --try t1 --rows ROW-003 --expect 10 --why 'expected slow' -- tests/x)
waitend "$G" || fail 'the run with --expect did not end green'
grep -q '^retry:' ".vid/requests/$G/result" && fail 'a result that was not capped prints a retry line'
exit 0

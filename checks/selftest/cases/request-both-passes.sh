#!/bin/sh
# Purpose: selftest case — one request, both passes (v0.9.7.0.9 spec 3.5,
# R6). With a harness declaring deployed-selector:, `request --type iterate
# --role builder -- <selection> --deployed-selection <selection>` makes one
# ticket and one queue position, estimated with the start-up twice and the
# cases once; its run takes one slot and runs the inline pass with its
# selection, then the deployed pass with its own on the deployed profile,
# each on its own stack (a down after each), and keeps two receipts —
# <head>.live.sel-<hash>.run-<id>.xml and
# <head>.live.deployed.sel-<hash>.run-<id>.xml, one run id — both named in
# the result. Refused: with a harness that declares no deployed-selector:,
# from the testenv role, and on a prove-red request. A red inline pass that
# did not run to its end runs no deployed pass. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-both-passes: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
PLAIN=$COMPOSEFILE
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-declared
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
gated_repo "$T/r"; gate_on
SHA=$(git rev-parse --short=12 HEAD)
: > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'both passes' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the request with both passes was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
[ -n "$TK" ] && [ "$(ls .vid/requests | grep -c .)" -eq 1 ] || fail 'not exactly one ticket'
grep -q '^estimate 190s (start-up 2 × 90s + cases 10s) · cap 380s ' "$T/out" || fail "the start-up is not counted twice and the cases once: $(grep '^estimate' "$T/out")"
grep -qx 'hasdsel=yes' ".vid/requests/$TK/request" && grep -qx 'dsel=tests/d' ".vid/requests/$TK/request" || fail 'the ticket does not carry the deployed selection'
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not end green'
L=$(grep '^r|' "$STUB_LOG")
printf '%s\n' "$L" | grep 'up --build --exit-code-from tests tests' | cut -d'|' -f4 | grep -qx 'tests/x' || fail 'the inline pass did not run its own selection'
printf '%s\n' "$L" | grep -- '--profile deployed up --exit-code-from tests tests' | cut -d'|' -f4 | grep -qx 'tests/d' || fail 'the deployed pass did not run its own selection'
printf '%s\n' "$L" | grep -q 'sel-declared' && fail 'the declared deployed selector reached the run'
printf '%s\n' "$L" | grep -q -- '-f [^ ]*override.yml down --remove-orphans --volumes$' || fail 'the inline pass was not brought down with its volumes before the deployed pass'
printf '%s\n' "$L" | grep -q -- '--profile deployed down --remove-orphans --volumes$' || fail 'the deployed pass was not brought down'
[ "$(printf '%s\n' "$L" | cut -d'|' -f2 | sort -u | grep -c .)" -eq 1 ] || fail 'the two passes did not run in one slot'
H1=$(printf '%s' tests/x | cksum | cut -d' ' -f1); H2=$(printf '%s' tests/d | cksum | cut -d' ' -f1)
R1=$(kept | grep -E "^$SHA\.live\.sel-$H1\.run-[0-9TZ]+-[0-9]+\.xml\$" || true)
R2=$(kept | grep -E "^$SHA\.live\.deployed\.sel-$H2\.run-[0-9TZ]+-[0-9]+\.xml\$" || true)
[ -n "$R1" ] && [ -n "$R2" ] || fail "not the two receipts: $(kept)"
[ "$(kept | grep -c .)" -eq 2 ] || fail "more than two receipts: $(kept)"
[ "${R1#*.run-}" = "${R2#*.run-}" ] || fail 'the two receipts are not of one run'
grep -qx 'shape=deployed' ".vid/ledger-results/$R2.tree" || fail 'the deployed receipt is not shape=deployed'
grep -q "^status=0 ran-to-end=yes capped=no report=$R1,$R2\$" "$T/out" || fail 'the result does not name both receipts'
[ "$(grep -c "^ledger-run .* request=$TK " .vid/metrics-events)" -eq 2 ] || fail 'not two ledger-run events for the one ticket'
# a red inline pass that did not run to its end: no deployed pass, no deployed receipt
: > "$STUB_LOG"
STUB_STATUS=2 sh checks/test.sh request --type iterate --role fixer --try t1 --rows ROW-001 --why 'stopped inline' -- tests/y --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the fixer'"'"'s request was refused'
TK2=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK2" > "$T/out" 2>&1 || true
grep -q -- '--profile deployed' "$STUB_LOG" && fail 'a pass that did not run to its end was followed by the deployed pass'
# refusals: testenv; prove-red; a harness with no deployed-selector:
for a in 'iterate testenv' 'prove-red test-author'; do
  set -- $a; RC=0; sh checks/test.sh request --type "$1" --role "$2" --rows ROW-001 --why 'refused' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || RC=$?
  [ "$RC" -eq 2 ] || fail "a $1 request by $2 with --deployed-selection was accepted"
done
COMPOSEFILE=$PLAIN; gated_repo "$T/plain"; gate_on
RC=0; sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'no selector' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] && grep -q 'declares no deployed-selector:' "$T/out" || fail 'a harness with no deployed-selector: took --deployed-selection'
[ -z "$(ls .vid/requests 2>/dev/null)" ] || fail 'a refused request made a ticket'
exit 0

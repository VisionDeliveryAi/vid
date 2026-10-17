#!/bin/sh
# Purpose: selftest case — the test-environment pass makes real requests
# (v0.9.7.0.2 spec 3.4; §6 C-5b, round 2 finding 1). Before any step-start
# (the plan holds ROW-001 in an unstarted S1), `testenv.sh measure --rows
# ROW-001 -- <selection>` runs as a `testenv` request — a ticket with an
# estimate and a cap, its event role=testenv with request= and cap= —
# exempt from the unstarted-step refusal (a builder's request for the same
# row is refused); `prove` reuses its rows in its two requests, each
# carrying the proof id. v0.9.7.0.8 (T3): measure is given `--expect 120`;
# its ticket and both proof tickets must record `expect=120` — the request
# takes `--expect` and `120` only as two words (as one, `--expect 120`, it
# is refused at its usage, and testenv says the test manager did not
# accept the run). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-request: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
cp "$CHECKS/testenv.sh" checks/; commit_all testenv
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
if sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'before the step starts' -- tests/x > "$T/out" 2>&1; then fail 'a builder request for an unstarted row was accepted'; fi
touch "$T/hold"; ( sleep 3; rm -f "$T/hold" ) & _mt=$!
STUB_HOLD="$T/hold" sh checks/testenv.sh measure --rows ROW-001 --expect 120 -- 'tests/x' > "$T/out" 2>&1 || fail 'measure --expect 120, before any step-start, was refused'
wait "$_mt" || true   # v0.9.8.1 (R2): the hold's timer ends before the next step makes its own hold
wait
[ "$(ls .vid/requests | grep -c .)" -eq 1 ] || fail 'measure made no request'
M=.vid/requests/$(ls .vid/requests)
grep -qx 'role=testenv' "$M/request" && grep -qx 'type=iterate' "$M/request" && grep -qE '^cap=[0-9]+$' "$M/request" || fail 'the measure request is not a capped testenv request'
grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -qE " role=testenv .*request=${M##*/} type=iterate rows=1 estimate=[0-9]+ cap=[0-9]+ " || fail 'the measure event is not a testenv request with its cap'
grep -qx 'expect=120' "$M/request" || fail 'the measure request did not take --expect 120 as two words'
grep -qx 'rows=ROW-001' .vid/testenv || fail 'measure did not keep its rows'
sh checks/testenv.sh pick > "$T/out" 2>&1; grep -q '^testenv pick k=3 ' "$T/out" || fail 'the pick is not 3'
touch "$T/hold"; release_overlap "$T/hold" 2; _mt=$!   # v0.9.8.1 (R25): prove waits for free slots first, so released on both runs up
STUB_HOLD="$T/hold" sh checks/testenv.sh prove > "$T/out" 2>&1 || fail 'the proof failed'
wait "$_mt" || true   # v0.9.8.1 (R2): the hold's timer ends before the next step makes its own hold
wait
[ "$(ls .vid/requests | grep -c .)" -eq 3 ] || fail 'prove did not make two requests'
for d in $(ls .vid/requests | sed 1d); do
  grep -qx 'rows=1' ".vid/requests/$d/request" && grep -qx 'ROW-001' ".vid/requests/$d/rows" && grep -qE '^prove=prove-' ".vid/requests/$d/request" || fail "the proof request $d does not reuse the rows and carry the proof id"
  grep -qx 'expect=120' ".vid/requests/$d/request" || fail "the proof request $d did not take the measured --expect 120 as two words"
done
exit 0

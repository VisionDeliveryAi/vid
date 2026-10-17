#!/bin/sh
# Purpose: selftest case — the proof of two environments (v0.9.6 spec 3.9,
# R9; §7 case 17). From an absent budget, after a measure and a pick of k=3:
# no run but the proof gets a second slot (a plain gated run beside a held
# one is refused); prove holds exactly two slots, both marked with its
# proof id, and a third run under the same id is refused; both runs publish
# under different names, their cases equal the serial receipt's, and
# record writes stacks=3, unverified-rows=180, env-mb and testenv=proved to
# .vid/budget with a `testenv` event. When the proof's results differ from
# the serial receipt, prove fails, an `incident` is recorded, and record
# keeps stacks=1 (testenv=one). With k=1 no proof runs. v0.9.7.0.1 (3.2,
# R6; §6 B-3): the measure run and both proof runs are recorded
# role=testenv. v0.9.8.1 (R2): the live project's race fix (its 916db80) — measure waits for its hold's
# timer, and the cleanup never decides the verdict — and the first plain run is awaited at its own stub, not
# at slot 1, which the measure's run still holds through its final teardown after its result. Env: CHECKS.
set -eu
# cleanup never decides the verdict: a detached stub teardown may still be writing under $T when the case ends
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-prove: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
TE() { sh checks/testenv.sh "$@" > "$T/out" 2>&1; }
# the hold's timer is waited for before measure returns, so it never removes a later step's hold (a race: measure ending inside 3 s)
measure() { touch "$T/hold"; ( sleep 3; rm -f "$T/hold" ) & _mt=$!; _mr=0; STUB_HOLD="$T/hold" sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' > "$T/out" 2>&1 || _mr=$?; wait "$_mt" || true; return "$_mr"; }
measure || fail 'measure'
grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -q ' role=testenv ' || fail 'the measure run is not recorded role=testenv'   # v0.9.7.0.1 B-3
TE pick; grep -q '^testenv pick k=3 ' "$T/out" || fail 'the pick is not 3'
[ ! -f .vid/budget ] || fail 'measure or pick wrote the budget'
# before the proof, one slot for everyone else
touch "$T/hold"
_i=0; while [ -d "$T/run/vid-host/stack.1" ] && [ "$_i" -lt 120 ]; do sleep 1; _i=$((_i + 1)); done   # the measure's run, through its teardown
( STUB_HOLD="$T/hold" STUB_ENTER="$T/p1-up" VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- a > "$T/o1" 2>&1 ) & P1=$!
waitfor "$T/p1-up" 60 || { cat "$T/o1" >&2; fail "the first plain run took no slot"; }
if VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- b > "$T/out" 2>&1; then fail 'a second plain run got a slot before the proof'; fi
rm -f "$T/hold"; wait "$P1" || true
# the proof: exactly two slots under its id
touch "$T/hold"
( STUB_HOLD="$T/hold" sh checks/testenv.sh prove > "$T/prove.out" 2>&1 ) & PP=$!
waitfor "$T/run/vid-host/stack.2/holder" || fail 'the proof did not take two slots'
sleep 1
ID=$(sed -n 's/^prove=//p' "$T/run/vid-host/stack.1/holder")
[ -n "$ID" ] && [ "$(sed -n 's/^prove=//p' "$T/run/vid-host/stack.2/holder")" = "$ID" ] || fail 'the two slots are not marked with one proof id'
[ ! -d "$T/run/vid-host/stack.3" ] || fail 'the proof took a third slot'
if VID_TESTENV_PROVE=$ID VID_REQUEST=selftest-direct sh checks/test.sh --role testenv -- 'tests/x' > "$T/out" 2>&1; then fail 'a third run under the proof id was admitted'; fi
rm -f "$T/hold"; wait "$PP" || { cat "$T/prove.out" >&2; fail 'the proof failed'; }
grep -q "^testenv prove ok id=$ID receipts=" "$T/prove.out" || fail 'the proof did not report both receipts'
[ "$(grep '^ledger-run ' .vid/metrics-events | tail -n 2 | grep -c ' role=testenv ')" -eq 2 ] || fail 'the two proof runs are not recorded role=testenv'
TE record || fail 'record'
for kv in stacks=3 unverified-rows=180 env-mb=512 "testenv=proved harness=$(cksum < docker-compose.test.yml | cut -d' ' -f1)"; do grep -qx "$kv" .vid/budget || fail "the budget lacks $kv"; done
tail -n 1 .vid/metrics-events | grep -qE '^testenv stacks=3 env-mb=512 docker-mb=8192 other-mb=0 case-seconds=0.1 compose=2.29.1 resets=yes at=' || { tail -n 1 .vid/metrics-events >&2; fail 'no testenv event'; }
# results that differ: the proof fails, stacks stays 1
rm -f .vid/budget
measure || fail 'the second measure'; TE pick
if STUB_CASE=failed sh checks/testenv.sh prove > "$T/out" 2>&1; then fail 'a proof whose results differ passed'; fi
grep -q 'differ from the serial receipt' "$T/out" || fail 'the failed proof does not say why'
grep -q '^incident slice=1 testenv proof prove-.* failed: ' .vid/metrics-events || fail 'no incident for the failed proof'
TE record; grep -qx 'stacks=1' .vid/budget && grep -qx 'testenv=one' .vid/budget || fail 'a failed proof recorded more than one environment'
# k=1: no proof
DOCKER_TOTAL_MB=3000 measure; TE pick
if TE prove; then fail 'a proof ran at k=1'; fi
exit 0

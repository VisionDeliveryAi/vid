#!/bin/sh
# Purpose: selftest case — slots reserve their memory (v0.9.7.0.11 spec
# 3.5, R5). Two proved environments (.vid/budget stacks=2, env-mb=4000,
# memory-headroom-mb=1000) on a Docker of 8000 MB with a non-ViD container
# using 2000 MB: while request A holds slot 1, request B waits — its
# `holders` says `waiting for memory: estimate 2000 MB, needed 5000 MB`,
# no slot 2 is taken — and runs once A ends. With 16000 MB, B takes slot 2
# beside A. With no env-mb in the budget, no check: B takes slot 2. The
# first slot is never held back, however short the memory. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "slot-memory: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export DSTUB_HOME="$(pwd -P)"
printf 'c-preview\tpreview-db\t/elsewhere\t2000MiB\n' > "$T/others"
budget() { printf 'stacks=2\nunverified-rows=120\n%stestenv=proved harness=%s\nmemory-headroom-mb=1000\n' "$1" "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget; }
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
ask() { STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$1" -- tests/x > "$T/out" 2>&1 || fail "the request '$1' was refused"; tk; }
# pair <total MB> <label>: A held, then B; B's ticket in $B
pair() { : > "$T/hold"; export DOCKER_TOTAL_MB=$1
  A=$(ask "A $2"); waitfor "$T/run/vid-host/stack.1/holder" || fail "$2: A took no slot"
  B=$(ask "B $2"); sleep 4; }
budget 'env-mb=4000
'
pair 8000 short
[ ! -d "$T/run/vid-host/stack.2" ] || fail 'short: B took slot 2 though the memory is short'
[ "$(cat ".vid/requests/$B/state")" = queued ] || fail 'short: B is not queued'
grep -q 'waiting for memory: estimate 2000 MB, needed 5000 MB' ".vid/requests/$B/holders" || fail 'short: B does not say it waits for memory'
VID_WAIT_MAX=3 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || true
grep -q 'waiting for memory' "$T/out" || fail 'short: wait does not show why B waits'
rm -f "$T/hold"
VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || fail 'short: A did not pass'
VID_WAIT_MAX=60 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || fail 'short: B did not run once A ended'
sleep 2
pair 16000 enough
waitfor "$T/run/vid-host/stack.2/holder" 5 || fail 'enough: B did not take slot 2 beside A'
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > /dev/null 2>&1 || true; VID_WAIT_MAX=60 sh checks/test.sh wait "$B" > /dev/null 2>&1 || true
sleep 2
budget ''
pair 8000 'no env-mb'
waitfor "$T/run/vid-host/stack.2/holder" 5 || fail 'no env-mb: B was held back'
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > /dev/null 2>&1 || true; VID_WAIT_MAX=60 sh checks/test.sh wait "$B" > /dev/null 2>&1 || true
sleep 2
# the first slot: never held back
budget 'env-mb=4000
'
export DOCKER_TOTAL_MB=1000
A=$(ask 'first, memory short'); VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || fail 'the first slot was held back'
exit 0

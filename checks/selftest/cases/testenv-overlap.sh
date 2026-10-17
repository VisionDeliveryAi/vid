#!/bin/sh
# Purpose: selftest case — the proof must overlap (v0.9.7.0.11 spec 3.5,
# R5). After a measure and a pick of k=3, with .vid/budget already holding
# env-mb=512 and memory-headroom-mb=7500 (a re-proof on a Docker of 8192
# MB), the memory admission makes the proof's second run wait for the
# first: both publish and their cases equal the serial receipt's, yet
# prove fails — `the two runs did not overlap in time` — records an
# incident, and record keeps one environment (stacks=1, testenv=one). With
# headroom 2048 they overlap and the proof holds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-overlap: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
touch "$T/hold"; ( sleep 3; rm -f "$T/hold" ) & _mt=$!; STUB_HOLD="$T/hold" sh checks/testenv.sh measure --rows ROW-001 --expect 60 -- 'tests/x' > "$T/out" 2>&1 || fail 'measure'
wait "$_mt" || true   # v0.9.8.1 (R2): the hold's timer ends before the next step makes its own hold
sh checks/testenv.sh pick > "$T/out" 2>&1; grep -q '^testenv pick k=3 ' "$T/out" || fail 'the pick is not 3'
# v0.9.8.1 (R25): prove waits for free slots before its runs, so a timer started here could free the hold before
# they start: the run that must overlap is released once both are up (release_overlap); the serialised one by time
prove() { printf 'env-mb=512\nmemory-headroom-mb=%s\n' "$1" > .vid/budget
  touch "$T/hold"; if [ "${2:-}" = overlap ]; then release_overlap "$T/hold" 2; _mt=$!; else ( sleep 3; rm -f "$T/hold" ) & _mt=$!; fi
  _pr=0; STUB_HOLD="$T/hold" sh checks/testenv.sh prove > "$T/out" 2>&1 || _pr=$?; wait "$_mt" || true; return "$_pr"; }
if prove 7500; then fail 'a proof whose runs did not overlap passed'; fi
grep -q 'the two runs did not overlap in time' "$T/out" || fail 'the failed proof does not say the runs did not overlap'
grep -q '^incident slice=1 testenv proof prove-.* failed: the two runs did not overlap' .vid/metrics-events || fail 'no incident for the serialised proof'
sh checks/testenv.sh record > "$T/out" 2>&1; grep -qx 'stacks=1' .vid/budget && grep -qx 'testenv=one' .vid/budget || fail 'a serialised proof recorded more than one environment'
prove 2048 overlap || fail 'a proof whose runs overlapped failed'
grep -q '^testenv prove ok ' "$T/out" || fail 'the overlapping proof did not report ok'
exit 0

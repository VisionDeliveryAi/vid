#!/bin/sh
# Purpose: selftest case — a Compose that refuses !reset (v0.9.6 spec
# 3.7.8, R7; §7 case 9). The stub refuses `config` whenever the override
# carries the tag: the run still gets the image and results overrides
# (without the resets), says so, publishes its receipt and tears down; a
# second run while the first holds slot 1, under `stacks=2 testenv=proved`,
# takes slot 2 and is refused with the note; with a Compose that takes the
# tag, the same second run is admitted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "compose-no-reset: $*" >&2; cat "$T"/out* >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
export STUB_NORESET=1
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh --role builder -- x > "$T/out" 2>&1 ) & P=$!
waitfor "$T/entered" || fail 'the run never reached its up'
RF=$(ls -d .vid/runs/*)
grep -q '!reset' "$RF/override.yml" && fail 'the override kept the refused tag'
grep -q 'image: vid-s1-repo:run' "$RF/override.yml" && grep -q '/results:/vid-results' "$RF/override.yml" || fail 'the image or results override was dropped with the resets'
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
if sh checks/test.sh --role builder -- y > "$T/out2" 2>&1; then fail 'slot 2 was admitted without the resets'; fi
grep -q 'refuses the !reset tag' "$T/out2" && grep -q 'refused — slot 2' "$T/out2" || fail 'the refusal of slot 2 does not say why'
unset STUB_NORESET
sh checks/test.sh --role builder -- z > "$T/out3" 2>&1 || fail 'slot 2 was refused with a Compose that takes the tag'
export STUB_NORESET=1
rm -f "$T/hold"; wait "$P" || fail 'the first run failed'
grep -q 'refuses the !reset tag' "$T/out" || fail 'the first run did not say it runs without the resets'
[ "$(kept | grep -c '\.sel-')" -eq 2 ] || fail 'the runs without and with the resets did not both publish'
grep -c ' down --remove-orphans' "$STUB_LOG" | grep -qx 2 || fail 'the two runs that came up did not both tear down'
[ "$(nruns)" -eq 0 ] || fail 'a run folder was left'
exit 0

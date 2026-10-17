#!/bin/sh
# Purpose: selftest case — runs of the same tree and selection never share a
# receipt (v0.9.6 spec 3.7.4, R7; §7 case 7). Under `stacks=2
# testenv=proved`, two stub runs started together — scoped, then full with
# its deployed pass — each hold their own slot and publish their own kept
# receipt, twice over: every `ledger-run` event names a distinct kept
# receipt that exists and whose report came from that run's own frozen copy
# (no run read another's pending.xml); every kept full receipt has its
# deployed twin by the existing lookup; the commit-named <head>.full.xml and
# <head>.deployed.xml are copies of the newest; a full receipt named by an
# `invalidated … report=` event survives a rerun on the same commit under
# its own name, the rerun's receipt distinct from it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/hold*; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "identical-runs: $*" >&2; cat "$T"/out.* "$STUB_LOG" >&2 2>/dev/null; ls .vid/ledger-results >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
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
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
SHA=$(git rev-parse --short=12 HEAD)
pair() { # $1=label, $2… the test.sh arguments: two runs held until both are in
  L=$1; shift
  touch "$T/hold.$L"; rm -f "$T/in.$L.a" "$T/in.$L.b"
  ( STUB_HOLD="$T/hold.$L" STUB_ENTER="$T/in.$L.a" sh checks/test.sh "$@" > "$T/out.$L.a" 2>&1 ) & PA=$!
  ( STUB_HOLD="$T/hold.$L" STUB_ENTER="$T/in.$L.b" sh checks/test.sh "$@" > "$T/out.$L.b" 2>&1 ) & PB=$!
  waitfor "$T/in.$L.a" && waitfor "$T/in.$L.b" || fail "the pair $L did not both start (two slots)"
  [ -d "$T/run/vid-host/stack.1" ] && [ -d "$T/run/vid-host/stack.2" ] || fail "the pair $L does not hold two slots"
  rm -f "$T/hold.$L"; wait "$PA" || fail "run a of $L failed"; wait "$PB" || fail "run b of $L failed"
}
for round in 1 2; do
  pair "s$round" --role builder -- 'tests/same'
  pair "f$round" --role close
done
# every event resolves to its own existing kept receipt, from its own frozen copy
grep '^ledger-run ' .vid/metrics-events > "$T/ev"
[ "$(grep -c . "$T/ev")" -eq 12 ] || fail "not twelve ledger-run events (4 scoped, 4 full, 4 deployed)"
sed -n 's/.* report=\([^ ]*\) .*/\1/p' "$T/ev" | sort | uniq -d | grep -q . && fail 'two events name the same receipt'
while IFS= read -r l; do
  R=$(printf '%s\n' "$l" | sed -n 's/.* report=\([^ ]*\) .*/\1/p'); ID=$(printf '%s\n' "$l" | sed -n 's/.* run=\([^ ]*\) .*/\1/p')
  case "$R" in *".run-$ID."*) ;; *) fail "event report $R does not carry its run id $ID" ;; esac
  [ -f ".vid/ledger-results/$R" ] || fail "event names $R, which does not exist"
  grep -q "ctx=\"[^\"]*/.vid/runs/$ID/ctx\"" ".vid/ledger-results/$R" || fail "$R holds another run's report"
done < "$T/ev"
for f in $(ls .vid/ledger-results | grep -E "^$SHA\.run-.*\.full\.xml\$"); do
  [ -f ".vid/ledger-results/${f%.full.xml}.deployed.xml" ] || fail "no deployed twin for $f"
done
NF=$(grep ' kind=full ' "$T/ev" | tail -n 1 | sed -n 's/.* report=\([^ ]*\) .*/\1/p'); ND=$(grep ' kind=deployed ' "$T/ev" | tail -n 1 | sed -n 's/.* report=\([^ ]*\) .*/\1/p')
cmp -s ".vid/ledger-results/$SHA.full.xml" ".vid/ledger-results/$NF" || fail 'the commit-named full receipt is not the newest'
cmp -s ".vid/ledger-results/$SHA.deployed.xml" ".vid/ledger-results/$ND" || fail 'the commit-named deployed receipt is not the newest'
# invalidated by name, then run again on the same commit
printf 'invalidated slice=1 report=%s boot race at=%s\n' "$NF" "$(utcnow)" >> .vid/metrics-events
sh checks/test.sh --role close > "$T/out.re" 2>&1 || fail 'the rerun failed'
RE=$(grep '^ledger-run .* kind=full ' .vid/metrics-events | tail -n 1 | sed -n 's/.* report=\([^ ]*\) .*/\1/p')
[ "$RE" != "$NF" ] && [ -f ".vid/ledger-results/$NF" ] && [ -f ".vid/ledger-results/$RE" ] || fail 'the rerun overwrote the invalidated receipt'
grep -q "^invalidated .* report=$NF " .vid/metrics-events || fail 'the invalidation no longer names its receipt'
[ "$(nruns)" -eq 0 ] || fail 'run folders outlived their runs'
exit 0

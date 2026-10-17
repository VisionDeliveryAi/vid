#!/bin/sh
# Purpose: selftest case — a gated request's result before its final
# teardown (v0.9.7.0.10 spec 3.1, R1–R4). Inside a develop run, with the
# teardown blocked: `wait` returns the result and the run's own exit
# status — 0 for a passing run, 1 for a failing one — followed by
# `teardown pending`, while the slot and the run folder are still held and
# the ledger-run event is written but no teardown event yet; the cap's
# watcher has stopped. Released, the teardown frees both, writes `teardown
# seconds=<s> report=<the receipt>`, and the result is left as the run
# wrote it. The published seconds hold no teardown. (R2) Outside a develop
# run two requests in a row, each with a slow teardown, both pass: the
# first's wait returns only after its cleanup. (R3) A teardown failing
# between the two passes of one request stops the deployed pass: a
# non-zero exit, a result naming it, the slot and the run folder kept, a
# `teardown-failed request=<ticket>` event. (R4) A final teardown failing
# after the result: the result and its exit stand, `teardown-failed
# request=<ticket> project=<p>`, the slot kept, and `wait` says so.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "result-before-teardown: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# gone <path> [seconds]: wait until the path is gone
gone() { _i=0; while [ -e "$1" ] && [ "$_i" -lt "${2:-20}" ]; do sleep 1; _i=$((_i + 1)); done; [ ! -e "$1" ]; }
gated_repo "$T/repo"; gate_on
# R1: passing, then failing, each with its teardown blocked
for c in passed:0 failed:1; do
  CS=${c%%:*}; RC0=${c#*:}
  : > "$T/hold"; N0=$(grep -c '^teardown ' .vid/metrics-events || true)
  STUB_DOWN_HOLD="$T/hold" STUB_CASE=$CS STUB_STATUS=$RC0 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "a $CS run" -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
  TK=$(tk); TD=.vid/requests/$TK
  RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
  [ "$RC" -eq "$RC0" ] || fail "$CS: wait exited $RC, not the run's own $RC0"
  sed -n 1p "$T/out" | grep -q "^status=$RC0 ran-to-end=yes capped=no report=" || fail "$CS: the first line is not the status line"
  tail -n 1 "$T/out" | grep -qx 'teardown pending' || fail "$CS: wait does not say teardown pending"
  [ -d "$T/run/vid-host/stack.1" ] || fail "$CS: the slot was released before the teardown"
  [ "$(nruns)" -eq 1 ] || fail "$CS: the run folder was removed before the teardown"
  grep -q "^ledger-run .* request=$TK " .vid/metrics-events || fail "$CS: no ledger-run event before the teardown"
  [ "$(grep -c '^teardown ' .vid/metrics-events || true)" -eq "$N0" ] || fail "$CS: a teardown event before the teardown"
  [ "$(cat "$TD/state")" = done ] && [ "$(cat "$TD/exit")" = "$RC0" ] || fail "$CS: the state or the exit is not the run's"
  kill -0 "$(cat "$TD/watcher")" 2>/dev/null && fail "$CS: the cap's watcher outlived the result"
  R0=$(cksum < "$TD/result"); RF=$(cat "$TD/run")   # v0.9.8.1 (R45): `run` goes with its folder — read it while held
  rm -f "$T/hold"
  gone "$T/run/vid-host/stack.1" || fail "$CS: the slot was not freed after the teardown"
  gone "$RF" || fail "$CS: the run folder was not removed after the teardown"
  _i=0; while kill -0 "$(cat "$TD/supervisor")" 2>/dev/null && [ "$_i" -lt 20 ]; do sleep 1; _i=$((_i + 1)); done   # serve's own end
  REP=$(sed -n 's/.* report=\([^ ]*\)$/\1/p' "$TD/result" | head -n 1)
  grep -qE "^teardown seconds=[0-9]+ report=$REP at=" .vid/metrics-events || fail "$CS: no teardown event naming the receipt $REP"
  [ "$(cksum < "$TD/result")" = "$R0" ] || fail "$CS: the result was written again after the teardown"
  VID_WAIT_MAX=5 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
  grep -q 'teardown pending' "$T/out" && fail "$CS: teardown pending after the run folder is gone"
done
# the published seconds hold no teardown
STUB_DOWN_SLEEP=4 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a slow teardown' -- tests/x > "$T/out" 2>&1 || fail 'the slow-teardown request was refused'
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the slow-teardown run did not pass'
gone "$T/run/vid-host/stack.1" 30 || fail 'the slow teardown did not end'
S=$(grep "^ledger-run .* request=$TK " .vid/metrics-events | sed -n 's/^ledger-run seconds=\([0-9]*\) .*/\1/p')
D=$(grep '^teardown ' .vid/metrics-events | tail -n 1 | sed -n 's/^teardown seconds=\([0-9]*\) .*/\1/p')
[ "${D:-0}" -ge 4 ] && [ "${S:-99}" -lt 4 ] || fail "the published seconds ($S) hold the teardown ($D)"
# R4: a final teardown failing after the result
STUB_DOWN_FAIL=1 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a failing teardown' -- tests/x > "$T/out" 2>&1 || fail 'the R4 request was refused'
TK=$(tk); RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 0 ] || fail "R4: the result does not stand (wait exited $RC)"
_i=0; while ! grep -q "^teardown-failed request=$TK " .vid/metrics-events && [ "$_i" -lt 20 ]; do sleep 1; _i=$((_i + 1)); done
grep -qE "^teardown-failed request=$TK project=vid-s1-repo at=" .vid/metrics-events || fail 'R4: no teardown-failed event naming the request and the project'
[ -d "$T/run/vid-host/stack.1" ] || fail 'R4: the slot was released after a failed teardown'
RC=0; VID_WAIT_MAX=5 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 0 ] && grep -q '^teardown failed — ' "$T/out" && sed -n 1p "$T/out" | grep -q '^status=0 ' || fail 'R4: wait does not keep the result and say the teardown failed'
# R3: a teardown failing between the two passes stops the deployed pass (R4's kept slot freed by hand first)
rm -rf "$T/run/vid-host"
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
gated_repo "$T/two"; gate_on
: > "$STUB_LOG"
STUB_DOWN_FAIL=1 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'both passes' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || fail 'the R3 request was refused'
TK=$(tk); RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -ne 0 ] || fail 'R3: a failed teardown between the passes exited 0'
grep -q -- '--profile deployed' "$STUB_LOG" && fail 'R3: the deployed pass ran after a failed teardown'
grep -q '^why: teardown FAILED between the passes' "$T/out" || fail 'R3: the result does not name the failed teardown'
_i=0; while ! grep -q "^teardown-failed request=$TK " .vid/metrics-events && [ "$_i" -lt 20 ]; do sleep 1; _i=$((_i + 1)); done
grep -q "^teardown-failed request=$TK project=" .vid/metrics-events || fail 'R3: no teardown-failed event'
[ "$(nruns)" -eq 1 ] && ls "$T/run/vid-host" | grep -q '^stack\.' || fail 'R3: the slot and the run folder were not kept'
# R2: outside a develop run, two requests in a row with a slow teardown — the second is not refused
rm -rf "$T/run/vid-host"
gated_repo "$T/plain"
for n in 1 2; do
  STUB_DOWN_SLEEP=3 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "ungated $n" -- tests/x > "$T/out" 2>&1 || fail "R2: request $n was refused"
  TK=$(tk); RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
  [ "$RC" -eq 0 ] || fail "R2: ungated request $n exited $RC"
  grep -q 'teardown pending' "$T/out" && fail "R2: an ungated request said teardown pending"
  [ ! -d .vid/ledger.lock ] || fail "R2: request $n's result came before its cleanup (the lock is held)"
done
exit 0

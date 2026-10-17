#!/bin/sh
# Purpose: selftest case — every Compose call and the harness contract read
# name the frozen copy's file (v0.9.6 spec 3.7.3, R7; §7 case 6). A gated
# full run with a deployed selector, held open in its inline pass while a
# commit changes docker-compose.test.yml (a new deployed selector and a new
# process): the deployed pass still runs the old selector and the old
# profile services, and every Compose call — the config check, both passes,
# every teardown — names <run>/ctx/docker-compose.test.yml and the run's
# override, never the live file. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "frozen-compose: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-old
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
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh --role close > "$T/out" 2>&1 ) &
P=$!
waitfor "$T/entered" || fail 'the run never reached its inline up'
sed 's/sel-old/sel-new/; s/processes: \[worker\]/processes: [worker, mailer]/' docker-compose.test.yml > x && mv x docker-compose.test.yml
printf '  mailer:\n    image: toy:test\n    profiles: [deployed]\n' >> docker-compose.test.yml
g add docker-compose.test.yml && g commit -qm 'a compose change during the run'
rm -f "$T/hold"; wait "$P" || fail 'the run failed'
grep -q '|sel-old|.*--profile deployed up --exit-code-from tests tests' "$STUB_LOG" || fail 'the deployed pass did not run the frozen selector'
grep -q 'sel-new' "$STUB_LOG" && fail 'the committed selector reached the run'
grep 'up -d --build product' "$STUB_LOG" | grep -q 'mailer' && fail 'the committed process reached the deployed bring-up'
grep 'up -d --build product worker' "$STUB_LOG" >/dev/null || fail 'the deployed bring-up lost the frozen process'
N=$(grep -c '^repo|' "$STUB_LOG"); F=$(grep '^repo|' "$STUB_LOG" | grep -c -- '--project-directory [^ ]*/\.vid/runs/[^ ]*/ctx -f [^ ]*/\.vid/runs/[^ ]*/ctx/docker-compose\.test\.yml -f [^ ]*/\.vid/runs/[^ ]*/override\.yml ')
[ "$N" -ge 6 ] && [ "$N" -eq "$F" ] || fail "$F of $N Compose calls named the frozen files"
grep -c ' down ' "$STUB_LOG" | grep -qx 2 || fail 'not two teardowns'
exit 0

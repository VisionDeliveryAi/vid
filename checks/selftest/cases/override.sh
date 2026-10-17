#!/bin/sh
# Purpose: selftest case — the run's compose override (v0.9.6 spec 3.7.3,
# R7; §7 case 8). A gated run held open over a compose file with a product,
# two declared processes, a transport service, fixed ports and a fixed
# container name: its override.yml names the one image vid-s1-<folder>:run
# for the product and every `processes:` service and for nothing else, maps
# the tests service's /vid-results to the run's results folder, and resets
# ports: and container_name: on every service; the base
# docker-compose.test.yml is byte-identical afterwards and the worktree
# clean. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "override: $*" >&2; cat "$T/out" "$T/ov" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: web
  completed: [0, 1]
  processes: [worker, beat]
services:
  web:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
    container_name: toy-web
    ports:
      - "8000:8000"
  worker:
    image: toy:test
    profiles: [deployed]
  beat:
    image: toy:test
    profiles: [deployed]
  queue:
    image: queue:1
    ports:
      - "5672:5672"
  tests:
    image: runner
    volumes:
      - ${VID_TEST_CONTEXT:-.}:/app:ro
      - ./.vid/ledger-results:/vid-results
'
gated_repo "$T/my Repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
cp docker-compose.test.yml "$T/base.before"
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh --role builder -- x > "$T/out" 2>&1 ) & P=$!
waitfor "$T/entered" || fail 'the run never reached its up'
RF=$(ls -d .vid/runs/*); cp "$RF/override.yml" "$T/ov"
rm -f "$T/hold"; wait "$P" || fail 'the run failed'
IMG='vid-s1-my-repo:run'
svc() { awk -v s="  $1:" '$0 == s { on = 1; next } on && /^  [^ ]/ { exit } on' "$T/ov"; }
for s in web worker beat; do svc "$s" | grep -qxF "    image: $IMG" || fail "$s does not carry the run image"; done
for s in queue tests; do svc "$s" | grep -q 'image:' && fail "$s was given the run image"; done
svc tests | grep -qxF "      - \"$(pwd -P)/$RF/results:/vid-results\"" || fail 'the results mount is not the run folder'
for s in web worker beat queue tests; do
  svc "$s" | grep -qxF '    ports: !reset []' && svc "$s" | grep -qxF '    container_name: !reset null' || fail "$s is not reset"
done
cmp -s "$T/base.before" docker-compose.test.yml || fail 'the base compose file changed'
[ -z "$(git status --porcelain)" ] || fail 'the worktree is not clean'
exit 0

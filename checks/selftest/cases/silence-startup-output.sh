#!/bin/sh
# Purpose: selftest case — what counts as output in a pass's start-up and
# after its tests start (v0.26.10.4 spec R1, R3; §5 silence-startup-output).
# A docker stub answers for the run's compose project from $T/watch (the
# containers) and each container's last log line from $T/logs.<name>; the
# services watcher polls every second; the silence limit is 10 s. (1) In the
# inline pass's start-up a datastore's new lines keep a silent runner alive
# for 20 s (phase=startup); once the tests container runs (tests-at.inline),
# the datastore's lines no longer count and the run is stopped,
# reason=silent. (2) A pass with no services watcher whose Compose output
# grows (compose.inline.err) is not stopped in 20 s. (3) The deployed pass's
# start-up is judged as start-up: its services watcher starts with its
# bring-up and the datastore's lines keep it alive for 20 s (pass=deployed
# phase=startup). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold" "$T/tick"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "silence-startup-output: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
case "$1" in
  ps) ls "$SD"/up.* > /dev/null 2>&1 && awk -F'|' '{ print "id-" NR }' "$SD/watch" ;;
  inspect) ls "$SD"/up.* > /dev/null 2>&1 && cat "$SD/watch" ;;
  logs) for a in "$@"; do n=$a; done; [ -f "$SD/logs.$n" ] && tail -n 1 "$SD/logs.$n" ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1 VID_SILENCE_SECONDS=10
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  tests:
    image: runner
'
gated_repo "$T/repo"
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
g add -A && g commit -qm 'one row'
gate_on
DB='db|running|0|false|2026-01-01T00:00:01Z|0001-01-01T00:00:00Z|/p-db-1'
TS='tests|running|0|false|2026-01-01T00:00:10Z|0001-01-01T00:00:00Z|/p-tests-1'
: > "$T/tick"; ( _n=0; while [ -f "$T/tick" ]; do _n=$((_n + 1)); echo "db line $_n" >> "$T/logs.p-db-1"; sleep 1; done ) &
echo 'tests line 1' > "$T/logs.p-tests-1"
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# (1) the inline pass: the datastore's lines count in start-up, not after the tests start
printf '%s\n' "$DB" > "$T/watch"; touch "$T/hold"
STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a quiet start-up' -- tests/a > "$T/out" 2>&1 || fail 'the first request was refused'
TD=".vid/requests/$(tk)"; waitfor "$TD/running-at" 30 || fail 'the first run did not start'
sleep 20
[ ! -f "$TD/cap-hit" ] || fail "a start-up whose datastore logs was stopped as silent: $(cat "$TD/cap-hit")"
grep -q ' pass=inline phase=startup ' "$TD/watch" || fail "the watch file does not say the inline pass's start-up: $(cat "$TD/watch")"
printf '%s\n%s\n' "$DB" "$TS" > "$T/watch"
waitfor "$TD/tests-at.inline" 15 || fail 'no tests-at.inline once the tests ran'
waitfor "$TD/cap-hit" 40 || fail "after the tests started the datastore's lines kept the run alive"
grep -qx 'reason=silent' "$TD/cap-hit" || fail "the stop's reason is not silent: $(cat "$TD/cap-hit")"
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$(tk)" > /dev/null 2>&1 || true
# (2) no services watcher: Compose's own output counts in start-up
touch "$T/hold"
VID_DOCKER='' STUB_CHATTY_ERR=1 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t2 --rows ROW-001 --why 'a long build' -- tests/b > "$T/out" 2>&1 || fail 'the second request was refused'
TK=$(tk); TD=".vid/requests/$TK"; waitfor "$TD/running-at" 30 || fail 'the second run did not start'
sleep 20
[ -s "$TD/compose.inline.err" ] || fail 'the Compose output is not in the ticket folder'
[ ! -f "$TD/cap-hit" ] || fail "a start-up whose Compose output grows was stopped: $(cat "$TD/cap-hit")"
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the second run did not end green'
# (3) the deployed pass's start-up is start-up, its services watched from its bring-up
printf '%s\n' "$DB" > "$T/watch"; touch "$T/hold"
STUB_HOLD_DEPLOYED="$T/hold" sh checks/test.sh request --type full --role orchestrator --why 'a quiet deployed start-up' > "$T/out" 2>&1 || fail 'the third request was refused'
TK=$(tk); TD=".vid/requests/$TK"
_i=0; until grep -q ' pass=deployed ' "$TD/watch" 2>/dev/null || [ "$_i" -ge 60 ]; do sleep 1; _i=$((_i + 1)); done
grep -q ' pass=deployed phase=startup ' "$TD/watch" || fail "the deployed pass is not judged as start-up: $(cat "$TD/watch" 2>/dev/null)"
sleep 20
[ ! -f "$TD/cap-hit" ] || fail "the deployed pass's start-up whose datastore logs was stopped: $(cat "$TD/cap-hit")"
[ -f "$TD/svcout.deployed" ] && grep -q '^db	db line ' "$TD/svcout.deployed" || fail "the deployed pass's services were not watched from its bring-up"
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the third run did not end green'
exit 0

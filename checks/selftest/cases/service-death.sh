#!/bin/sh
# Purpose: selftest case — the run watches its stack while the tests run,
# and keeps each pass's container states (v0.9.7.0.11 spec 3.3, 3.4; R3,
# R4). A docker stub answers for the run's compose project from $T/watch
# (the watcher's lines) and $T/svc (the states' lines); the watcher polls
# every second (VID_SERVICE_POLL=1). A gated request whose datastore exits
# 1 while the tests container runs stops at once: the result's first line
# is `stopped: service db exited code 1 at <UTC> — see
# services.inline.txt`, the exit is non-zero, the state `stopped`, the
# event `report=none … stopped=service:db`, no receipt is kept, and the
# ticket's services.inline.txt holds the datastore's line (state, exit,
# memory kill, health, restarts, started-at, kept-healthy-at (v0.9.8, was ready-at) — the first passing
# check of its health log, which Docker gives as a quoted time — finished-at). A memory kill is named so. The
# controls, each kept with no stop: a one-shot service that exited 0; a
# service that died before the tests started; a service stopped by
# Compose (137) after the tests exited. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "service-death: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
ls "$SD"/up.* > /dev/null 2>&1 || exit 0
case "$1" in
  ps) awk -F'|' '{ print "id-" NR }' "$SD/watch" ;;
  inspect) case "$*" in *Health.Log*) cat "$SD/svc" ;; *) cat "$SD/watch" ;; esac ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1
gated_repo "$T/repo"; gate_on
Z=0001-01-01T00:00:00Z
printf '/vid-s1-repo-db-1|exited|1|false|healthy|0|2026-01-01T00:00:01.5Z|2026-01-01T00:00:20Z|\"2026-01-01T00:00:03.25Z\" \"2026-01-01T00:00:04Z\" \n/vid-s1-repo-tests-1|running|0|false|-|0|2026-01-01T00:00:10Z|%s|\n' "$Z" > "$T/svc"
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# go <watch lines> <why>: a request held about 4 s, the watcher's view while it runs; its ticket in $TK, its result in $T/out, the wait's exit in $WX
go() { printf '%s\n' "$1" > "$T/watch"; : > "$T/hold"; ( sleep 4; rm -f "$T/hold" ) &
  STUB_HOLD="$T/hold" STUB_DOWN_ENDS=1 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$2" -- tests/x > "$T/out" 2>&1 || fail "the request '$2' was refused"
  TK=$(tk); WX=0; VID_WAIT_MAX=40 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || WX=$?; }
ev() { grep "^ledger-run .* request=$TK " .vid/metrics-events; }
# a datastore exits 1 while the tests run
go "tests|running|0|false|2026-01-01T00:00:10Z|$Z
db|exited|1|false|2026-01-01T00:00:01Z|2026-01-01T00:00:20Z" 'a datastore dies'
[ "$WX" -ne 0 ] || fail 'a run whose datastore died exited 0'
head -n 1 "$T/out" | grep -qx 'stopped: service db exited code 1 at 2026-01-01T00:00:20Z — see services.inline.txt' || fail "the result's first line does not name the death"
[ "$(cat ".vid/requests/$TK/state")" = stopped ] || fail "the state is $(cat ".vid/requests/$TK/state"), not stopped"
ev | grep -q ' report=none .* stopped=service:db ' || fail 'the event does not say report=none stopped=service:db'
[ -z "$(kept)" ] || fail 'a receipt was kept'
grep -qx 'vid-s1-repo-db-1 state=exited exit=1 memory-kill=no health=healthy restarts=0 started-at=2026-01-01T00:00:01.5Z kept-healthy-at=2026-01-01T00:00:03.25Z finished-at=2026-01-01T00:00:20Z' ".vid/requests/$TK/services.inline.txt" || fail 'services.inline.txt does not hold the datastore line'
grep -qx 'vid-s1-repo-tests-1 state=running exit=0 memory-kill=no health=- restarts=0 started-at=2026-01-01T00:00:10Z kept-healthy-at=- finished-at=-' ".vid/requests/$TK/services.inline.txt" || fail 'services.inline.txt does not hold the tests line'
# killed for memory
go "tests|running|0|false|2026-01-01T00:00:10Z|$Z
search|exited|137|true|2026-01-01T00:00:01Z|2026-01-01T00:00:30Z" 'a search engine killed for memory'
head -n 1 "$T/out" | grep -q '^stopped: service search killed for memory at 2026-01-01T00:00:30Z' || fail 'a memory kill is not named'
# the controls: kept, no stop
for _w in "tests|running|0|false|2026-01-01T00:00:10Z|$Z
migrate|exited|0|false|2026-01-01T00:00:01Z|2026-01-01T00:00:20Z" "tests|running|0|false|2026-01-01T00:00:10Z|$Z
db|exited|1|false|2026-01-01T00:00:01Z|2026-01-01T00:00:05Z" "tests|exited|0|false|2026-01-01T00:00:10Z|2026-01-01T00:00:40Z
db|exited|137|false|2026-01-01T00:00:01Z|2026-01-01T00:00:41Z"; do
  go "$_w" 'a control'
  [ "$WX" -eq 0 ] || fail "a control run was stopped: $(printf '%s' "$_w" | tail -n 1)"
  grep -q '^stopped' "$T/out" && fail "a control run names a death: $(printf '%s' "$_w" | tail -n 1)"
  ev | grep -q ' report=none ' && fail 'a control run kept no receipt'
  waitfor ".vid/requests/$TK/services.inline.txt" || fail 'a control run has no services.inline.txt'
done
exit 0

#!/bin/sh
# Purpose: selftest case — a run stopped during start-up cleans up (v0.9.7.0.12 spec 3.9; R9; §6 E). A request's run
# is signalled while its pass's Compose `up` runs. Its Compose call gets TERM and is reaped, then the pass's down;
# Docker (a stub) shows the project has no container: the slot and the run folder are released, no teardown-failed.
# Containers left after a down: 10 s, the down again; gone then, released; still there, the slot and the run
# folder kept (`teardown-failed`). Docker unable to say: kept. A Compose call that outlives TERM by VID_UP_REAP
# seconds: kept. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "stop-during-up: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
case "$1" in
  ps) case " $* " in *' -a '*) echo "ps-a" >> "$SD/docker.log"; [ -f "$SD/psfail" ] && exit 1; [ -f "$SD/left" ] && cat "$SD/left" ;; esac ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh"
gated_repo "$T/repo"; gate_on
slots() { ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null | grep -c . || true; }
# go: a request held in its up, signalled there; $TD its ticket, $DOWNS the downs its project saw
go() { : > "$T/hold"; rm -f "$T/entered"; : > "$T/docker.log"
  STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$1" -- tests/x > "$T/out" 2>&1 || fail "the request '$1' was refused"
  TD=.vid/requests/$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
  waitfor "$T/entered" 30 || fail "'$1' never reached its up"
  kill -TERM "$(cat "$TD/pid")"
  VID_WAIT_MAX=60 sh checks/test.sh wait "${TD##*/}" > "$T/out" 2>&1 || true
  [ "$(cat "$TD/state")" = stopped ] || fail "'$1' is $(cat "$TD/state"), not stopped"
  DOWNS=$(grep -c ' down ' "$STUB_LOG" || true); : > "$STUB_LOG"; }
released() { [ "$(slots)" -eq 0 ] && [ "$(nruns)" -eq 0 ] || fail "$1: the slot or the run folder was kept"
  grep -q '^teardown-failed ' .vid/metrics-events && fail "$1: a teardown-failed was recorded"; return 0; }
kept() { [ "$(slots)" -eq 1 ] && [ "$(nruns)" -eq 1 ] || fail "$1: the slot and the run folder were not kept"
  grep -q '^teardown-failed' "$XDG_RUNTIME_DIR"/vid-host/*/holder || fail "$1: the slot is not marked teardown-failed"
  grep -q '^teardown-failed ' .vid/metrics-events || fail "$1: no teardown-failed event"
  rm -rf "$XDG_RUNTIME_DIR"/vid-host/* .vid/runs/*; grep -v '^teardown-failed ' .vid/metrics-events > "$T/ev"; cat "$T/ev" > .vid/metrics-events; }
# clean: reaped, one down, no container
go 'stopped in its up'
[ "$DOWNS" -eq 1 ] && [ "$(grep -c '^ps-a$' "$T/docker.log")" -ge 1 ] || fail "a clean stop: $DOWNS downs, Docker not asked"
released 'a clean stop'
# a container left once: the down again after 10 s, then released
echo id-1 > "$T/left"; ( sleep 5; rm -f "$T/left" ) &
go 'a container left once'; wait
[ "$DOWNS" -eq 2 ] || fail "a container left once: $DOWNS downs, not 2"
released 'a container left once'
# a container left after both downs: kept
echo id-1 > "$T/left"
go 'a container left'; rm -f "$T/left"
[ "$DOWNS" -eq 2 ] || fail "a container left: $DOWNS downs, not 2"
kept 'a container left'
# Docker cannot say: kept
: > "$T/psfail"; go 'Docker unable to say'; rm -f "$T/psfail"
kept 'Docker unable to say'
# the Compose call outlives TERM: kept
export STUB_UP_NOTERM=1 VID_UP_REAP=3
go 'a Compose call that outlives TERM'; rm -f "$T/hold"
grep -q 'still running 3 s after TERM' "$TD/log" || fail 'the live Compose call is not named'
kept 'a Compose call that outlives TERM'
exit 0

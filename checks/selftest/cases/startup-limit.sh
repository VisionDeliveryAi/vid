#!/bin/sh
# Purpose: selftest case — the start-up limit (v0.26.10.4 spec R2, R4; §5
# startup-limit). A stack that keeps logging but never starts its tests: a
# docker stub answers for the run's compose project with a datastore whose
# last log line changes each second, and no tests container. With the
# start-up limit at 15 s (VID_STARTUP_SECONDS) the run is stopped,
# reason=startup, the result's first line `stopped: the inline pass's
# start-up passed 15 s`, the event `capped=yes stop=startup`, no tests-at.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold" "$T/tick"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "startup-limit: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
case "$1" in
  ps) ls "$SD"/up.* > /dev/null 2>&1 && echo id-1 ;;
  inspect) ls "$SD"/up.* > /dev/null 2>&1 && echo 'db|running|0|false|2026-01-01T00:00:01Z|0001-01-01T00:00:00Z|/p-db-1' ;;
  logs) tail -n 1 "$SD/logs.db" 2>/dev/null ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1
gated_repo "$T/repo"; gate_on
: > "$T/tick"; ( _n=0; while [ -f "$T/tick" ]; do _n=$((_n + 1)); echo "db retry $_n" >> "$T/logs.db"; sleep 1; done ) &
touch "$T/hold"
VID_STARTUP_SECONDS=15 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a stack that never comes up' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
grep -q ' · stops after 20 min with no output, 15 s of start-up, or 24 h$' "$T/out" || fail "the request's line does not name the start-up limit"
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
waitfor "$TD/cap-hit" 60 || fail 'a stack that never started its tests was not stopped'
grep -qx 'reason=startup' "$TD/cap-hit" || fail "the stop's reason is not startup: $(cat "$TD/cap-hit")"
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 130 ] || fail "the stopped run's wait exited $RC, not 130"
head -n 1 "$T/out" | grep -qx "stopped: the inline pass's start-up passed 15 s" || fail "the result's first line does not say why"
[ "$(cat "$TD/state")" = capped ] || fail 'the final state is not capped'
grep -q "^ledger-run .* request=$TK .* capped=yes stop=startup " .vid/metrics-events || fail 'the event does not carry capped=yes stop=startup'
[ ! -f "$TD/tests-at.inline" ] || fail 'tests-at.inline was written though the tests never ran'
exit 0

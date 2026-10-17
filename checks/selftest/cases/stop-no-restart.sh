#!/bin/sh
# Purpose: selftest case — a stop is final (v0.9.8.1 R45, F-37). A held request is cancelled while its pass's Compose
# call runs. Before the TERM reaches that call, the stop path sets no restart policy on the compose project's
# containers (`docker update --restart=no <ids>`), so none can start again before the down; after the TERM no
# Compose call starts anything (no up, start or restart) before the down, and the request ends cancelled. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "stop-no-restart: $*" >&2; grep -v '^repo|' "$STUB_LOG" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
echo "docker $*" >> "$STUB_LOG"
case "$1" in
  ps) ls "$SD"/up.* > /dev/null 2>&1 && printf 'cid-tests\ncid-db\n' ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh"
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"; : > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'stopped' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); waitfor "$T/entered" || fail 'the request did not start'
sh checks/test.sh cancel --ticket "$A" --by selftest > "$T/out" 2>&1 || fail 'the cancel failed'
VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || true
[ "$(cat ".vid/requests/$A/state")" = cancelled ] || fail 'the request was not cancelled'
awk '/^docker update --restart=no cid-tests cid-db$/ { if (!u) u = NR } /^ended-by-term / { if (!t) t = NR } /^[^|]*\|.* down( |$)/ { if (!d) d = NR }
  END { exit !(u && t && d && u < t && t < d) }' "$STUB_LOG" || fail 'no restart policy was cleared on the containers before the TERM'
awk '/^ended-by-term / { t = 1; next } t && /^[^|]*\|.* down( |$)/ { exit } t && /^[^|]*\|.* (up|start|restart)( |$)/ { bad = 1 } END { exit bad }' "$STUB_LOG" || fail 'a Compose call started something after the TERM'
exit 0

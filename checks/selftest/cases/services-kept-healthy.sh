#!/bin/sh
# Purpose: selftest case — a pass's container states name what Docker kept (v0.9.8 R17). A gated request whose docker
# stub answers one healthy service, its health log holding two passing checks, writes services.inline.txt with
# `kept-healthy-at=<the first one kept>` and its header naming kept-healthy-at; no line says ready-at=. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "services-kept-healthy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
ls "$SD"/up.* > /dev/null 2>&1 || exit 0
case "$1" in
  ps) echo id-1 ;;
  inspect) case "$*" in *Health.Log*) cat "$SD/svc" ;; *) printf 'tests|running|0|false|2026-01-01T00:00:10Z|0001-01-01T00:00:00Z\n' ;; esac ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1
gated_repo "$T/repo"; gate_on
printf '/vid-s1-repo-db-1|running|0|false|healthy|0|2026-01-01T00:00:01Z|0001-01-01T00:00:00Z|"2026-01-01T00:00:07Z" "2026-01-01T00:00:37Z" \n' > "$T/svc"
: > "$T/hold"; ( sleep 3; rm -f "$T/hold" ) &
STUB_HOLD="$T/hold" STUB_DOWN_ENDS=1 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the states' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=40 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
F=".vid/requests/$TK/services.inline.txt"; [ -f "$F" ] || fail 'no services.inline.txt'
grep -qx 'vid-s1-repo-db-1 state=running exit=0 memory-kill=no health=healthy restarts=0 started-at=2026-01-01T00:00:01Z kept-healthy-at=2026-01-01T00:00:07Z finished-at=-' "$F" || fail "the service's line is not kept-healthy-at: $(cat "$F")"
head -n 1 "$F" | grep -q ' kept-healthy-at ' || fail 'the header does not name kept-healthy-at'
grep -q 'ready-at' "$F" && fail 'a line still says ready-at'
exit 0

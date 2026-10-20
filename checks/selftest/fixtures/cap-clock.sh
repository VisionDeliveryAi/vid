# Purpose: selftest fixture — a held request whose tests start late (v0.9.8.1 R40; v0.26.10.4: its limits, not a cap).
# Sourced after gated-run.sh in the gated repository (Env: T). A fake docker answers the services watcher from
# $T/watch (`service|state|exit|oom|started|finished` lines) while a stub `up` holds. cc_req <start-up seconds>: a
# held iterate request with that start-up limit (VID_STARTUP_SECONDS), its ticket folder in $Q.
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
ls "$SD"/up.* > /dev/null 2>&1 || exit 0
case "$1" in
  ps) awk -F'|' '{ print "id-" NR }' "$SD/watch" ;;
  inspect) cat "$SD/watch" ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"; export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1
cc_req() { printf 'db|running|0|false|2026-01-01T00:00:01Z|0001-01-01T00:00:00Z\n' > "$T/watch"; : > "$T/hold"
  VID_STARTUP_SECONDS=$1 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a late start' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
  Q=.vid/requests/$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); _i=0; until [ -s "$Q/running-at" ] || [ "$_i" -ge 120 ]; do sleep 1; _i=$((_i + 1)); done; }


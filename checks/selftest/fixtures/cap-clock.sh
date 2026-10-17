# Purpose: selftest fixture — a held request whose tests start late, for the cap-clock cases (v0.9.8.1 R40, R43).
# Sourced after gated-run.sh in the gated repository (Env: T). A fake docker answers the services watcher from
# $T/watch (`service|state|exit|oom|started|finished` lines) while a stub `up` holds. cc_req <cap scale>: a held
# iterate request (estimate 100 s with no history, so its cap is 200 × the scale), its ticket folder in $Q. cc_at <s>:
# waits until <s> seconds after the request took its slot (running-at). cc_tests: the tests container shown running.
# cc_clock: puts a `date` on PATH whose `date +%s` reads $T/offset seconds ahead (R43's simulated host sleep: the
# case writes a jump there while the watcher sleeps); cc_jump <s>: sets the offset.
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
  VID_CAP_SCALE=$1 STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the cap clock' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
  Q=.vid/requests/$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); _i=0; until [ -s "$Q/running-at" ] || [ "$_i" -ge 120 ]; do sleep 1; _i=$((_i + 1)); done; }
cc_at() { while [ "$(date +%s)" -lt $(( $(cat "$Q/running-at") + $1 )) ]; do sleep 1; done; }
cc_tests() { printf 'db|running|0|false|2026-01-01T00:00:01Z|0001-01-01T00:00:00Z\ntests|running|0|false|2026-01-01T00:00:10Z|0001-01-01T00:00:00Z\n' > "$T/watch"; }
cc_clock() { mkdir -p "$T/bin"; echo 0 > "$T/offset"; export CC_OFFSET="$T/offset"; CC_PATH=$PATH; PATH="$T/bin:$PATH"
  printf '#!/bin/sh\nif [ "$*" = +%%s ]; then echo $(( $(/bin/date +%%s) + $(cat "$CC_OFFSET" 2>/dev/null || echo 0) )); else exec /bin/date "$@"; fi\n' > "$T/bin/date"; chmod +x "$T/bin/date"; }
cc_jump() { echo "$1" > "$T/offset"; }

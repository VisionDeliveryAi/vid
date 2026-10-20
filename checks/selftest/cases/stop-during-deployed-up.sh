#!/bin/sh
# Purpose: selftest case — an interrupted start-up can't restart a service (v0.26.10.3 R11; §5 stop-during-deployed-up).
# A deployed-only request is sent TERM while its first Compose call, `--profile deployed up -d`, runs. Convicts unless
# the stop path clears the restart policy of the project's containers (`docker update --restart=no <ids>`) before it
# collects any logs, and before the down; and the request ends stopped. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "stop-during-deployed-up: $*" >&2; cat "$STUB_LOG" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-declared
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
    build:
      context: ${VID_TEST_CONTEXT:-.}
      target: tests
'
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
echo "docker $*" >> "$STUB_LOG"
case "$1" in ps) printf 'cid-product\n' ;; esac
exit 0
STUB
# the Compose stub, wrapped: its first `up -d` sends TERM to the request's run (its pid from the run folder's holder)
cat > "$T/wrap.sh" <<'STUB'
#!/bin/sh
case " $* " in *' up -d '*)
  if [ ! -f "$(dirname "$STUB_LOG")/termed" ]; then : > "$(dirname "$STUB_LOG")/termed"
    for a in "$@"; do case "$a" in */override.yml) kill -TERM "$(sed -n 's/^pid=//p' "${a%/override.yml}/holder")" ;; esac; done; fi ;;
esac
exec sh "$STUB_REAL" "$@"
STUB
chmod +x "$T/docker.sh" "$T/wrap.sh"; export VID_DOCKER="$T/docker.sh" STUB_REAL="$T/stub.sh" VID_COMPOSE="$T/wrap.sh"
gated_repo "$T/r"; gate_on
: > "$STUB_LOG"
sh checks/test.sh request --type deployed --role builder --try t1 --rows ROW-001 --why 'stopped in its first up' -- tests/d > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || true
[ -f "$T/termed" ] || fail 'the up -d never ran'
[ "$(cat ".vid/requests/$TK/state")" = stopped ] || fail "the request is $(cat ".vid/requests/$TK/state"), not stopped"
awk '/^docker update --restart=no cid-product$/ { if (!u) u = NR } /^[^|]*\|.* logs( |$)/ { if (!l) l = NR } /^[^|]*\|.* down( |$)/ { if (!d) d = NR }
  END { exit !(u && d && u < d && (!l || u < l)) }' "$STUB_LOG" || fail 'no restart policy was cleared before the logs and the down'
grep -q '^[^|]*|.* logs' "$STUB_LOG" || fail 'the stop path collected no logs (the case would prove nothing)'
exit 0

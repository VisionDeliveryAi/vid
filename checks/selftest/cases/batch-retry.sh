#!/bin/sh
# Purpose: selftest case — a chunk is retried once, alone, only after a cap, a signal or a non-product service's
# death (v0.9.7.0.12 spec 3.4; R4; §6 B). Phase 1 is one chunk (both S2 rows in one group). A signal to its run:
# retried from the export, the retry green, the batch green, retried=1. A datastore's death: retried and green. A
# cap, then a cap of its retry: `incomplete phase 1, chunks 1` with `incomplete chunk=1 why=its retry was lost too
# (cap)`. A run whose tests exit outside `completed:`: incomplete, no retry. The product's death: red, naming the
# chunk, no retry. Each batch at a tree of its own. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-retry: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" >&2 || true; exit 1; }
# a docker stub: a chunk's first run sees $T/watch (touching $T/died once it shows a death), its retry $T/watch.ok
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
SD=$(dirname "$STUB_LOG")
ls "$SD"/up.* > /dev/null 2>&1 || exit 0
W="$SD/watch"; case "${VID_REQUEST:-}" in *-retry) W="$SD/watch.ok" ;; esac
case "$1" in
  ps) awk -F'|' '{ print "id-" NR }' "$W" ;;
  inspect) case "$*" in *Health.Log*) : ;; *) cat "$W"; grep -q '|exited|1|' "$W" && : > "$SD/died" ;; esac ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"
Z=0001-01-01T00:00:00Z
batch_repo "$T/repo"
printf 'ROW-003,ROW-004 | %s %s |\n' "$(w 2 3)" "$(w 2 4)" > "$T/p1"; groups "$T/p2" 1 2
n=0; fresh() { n=$((n + 1)); printf '# %s\n' "$n" > "app/s3/t$n.py"; commit_all "t$n"; rm -f "$T/died"; }
# held(): the first chunk's up is held until the stub has shown it a death (at most 120 s; v0.9.8.1: 30 before)
held() { : > "$T/hold"; ( i=0; while [ ! -f "$T/died" ] && [ "$i" -lt 120 ]; do sleep 1; i=$((i + 1)); done; sleep 2; rm -f "$T/hold" ) & }
go() { batch || fail "batch $n was refused"; TD=.vid/requests/$TK; RC=0; bwait 60 || RC=$?; }
ev() { grep "^close-batch id=$TK " .vid/metrics-events; }
# a signal: retried alone, green
fresh; STUB_SIGNAL_SEL=$(w 2 3) go; unset STUB_SIGNAL_SEL
[ "$RC" -eq 0 ] && head -n 1 "$TD/result" | grep -qx green || fail "a signalled chunk's batch did not end green ($RC)"
[ "$(cat "$TD/chunks/1/outcome")" = retry ] && [ "$(cat "$TD/chunks/1-retry/outcome")" = green ] || fail 'the signalled chunk was not retried green'
grep -q '^chunk 1-retry phase=1 green' "$TD/result" || fail 'the result does not show the retry'
grep -qx "id=$TK/1-retry" "$TD/chunks/1-retry/request" && grep -q "^export=.*/.vid/requests/$TK/export$" "$TD/chunks/1-retry/request" || fail 'the retry does not run from the export'
ev | grep -q ' retried=1 ' || fail 'close-batch does not count the retry'
[ ! -d "$TD/chunks/3-retry" ] && [ ! -d "$TD/chunks/2-retry" ] || fail 'a chunk not signalled was retried'
# a datastore dies: retried, green
export VID_DOCKER="$T/docker.sh" VID_SERVICE_POLL=1
printf 'db|running|0|false|2026-01-01T00:00:01Z|%s\n' "$Z" > "$T/watch.ok"
fresh; printf 'tests|running|0|false|2026-01-01T00:00:10Z|%s\ndb|exited|1|false|2026-01-01T00:00:01Z|2026-01-01T00:00:20Z\n' "$Z" > "$T/watch"
held
VID_CAP_SCALE=100 STUB_HOLD="$T/hold" go; unset STUB_HOLD VID_CAP_SCALE
[ "$RC" -eq 0 ] || fail "a datastore's death was not retried green ($RC)"
grep -q '^stopped: service db ' "$TD/chunks/1/stopped" && [ "$(cat "$TD/chunks/1/outcome")" = retry ] || fail 'the datastore death was not the retry cause'
# the product dies: red, no retry
fresh; printf 'tests|running|0|false|2026-01-01T00:00:10Z|%s\nproduct|exited|1|false|2026-01-01T00:00:01Z|2026-01-01T00:00:20Z\n' "$Z" > "$T/watch"
held
VID_CAP_SCALE=100 STUB_HOLD="$T/hold" go; unset STUB_HOLD VID_CAP_SCALE
[ "$RC" -eq 1 ] && head -n 1 "$TD/result" | grep -qx 'red phase 1, chunks 1' || fail "the product's death did not end the batch red at chunk 1 ($RC)"
grep -q "^red chunk=1 why=the product's process product died" "$TD/result" && [ ! -d "$TD/chunks/1-retry" ] || fail "the product's death was retried or not named"
unset VID_DOCKER VID_SERVICE_POLL
# tests exit outside completed: incomplete, no retry
fresh; STUB_STATUS=2 go; unset STUB_STATUS
[ "$RC" -eq 1 ] && head -n 1 "$TD/result" | grep -qx 'incomplete phase 1, chunks 1' || fail "an exit outside completed: did not end incomplete ($RC)"
[ ! -d "$TD/chunks/1-retry" ] && ev | grep -q ' retried=0 ' || fail 'an exit outside completed: was retried'
# a cap, then its retry's cap: incomplete
fresh; : > "$T/hold"; VID_CAP_SCALE=1 STUB_HOLD="$T/hold" go; unset STUB_HOLD VID_CAP_SCALE; rm -f "$T/hold"
[ "$RC" -eq 1 ] && head -n 1 "$TD/result" | grep -qx 'incomplete phase 1, chunks 1' || fail "a capped retry did not end incomplete ($RC)"
grep -q '^incomplete chunk=1 why=its retry was lost too (cap)' "$TD/result" && ev | grep -q ' retried=1 ' || fail 'the lost retry is not named'
[ "$(cat "$TD/chunks/1/state")" = capped ] && [ "$(cat "$TD/chunks/1-retry/state")" = capped ] || fail 'the chunk and its retry were not both capped'
exit 0

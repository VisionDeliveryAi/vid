#!/bin/sh
# Purpose: selftest case — a publish lock not got in 20 s takes the
# no-report path (0.26.10.28.3, R6, M16). Inside a develop run: (1) a live
# holder (a process of this case, its pid and start time in the lock's
# `pid`) holds the lock past 20 s while a request's passing run publishes —
# the report stays beside as <report>.unpublished, no receipt is kept, the
# ticket's passes line is the `none` one, one `ledger-run report=none
# status=0 … pid=<holder> why=publish-lock-held` event, the result's `why:`
# names the holder and the .unpublished path, and the run exits 1 (wait
# exits 1); the holder's lock is left as it was. (2) A standing
# .publish.reclaim beside a dead holder's lock, with two publishers waiting
# under two proved slots: neither removes it nor the lock, and both take
# the no-report path naming the reclaim folder, each with its .unpublished
# report and its `why=publish-reclaim-stands` event, both exiting non-zero.
# Env: CHECKS.
set -eu
T=$(mktemp -d)
DP=''   # the live stand-in holder this case started, while it runs
trap 'set +e; [ -z "$DP" ] || kill "$DP" 2>/dev/null; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "publish-lock-held: $*" >&2; for f in "$T"/out*; do [ -f "$f" ] && { echo "== $f"; cat "$f"; }; done >&2; ls -la .vid/ledger-results >&2 2>/dev/null; exit 1; }
L=.vid/ledger-results/.publish.lock; RC=.vid/ledger-results/.publish.reclaim
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
unpub() { ls .vid/ledger-results | grep -c '\.unpublished$' || true; }

# 1. a live holder past 20 s
gated_repo "$T/r1"; gate_on; mkdir -p .vid/ledger-results
sleep 600 & DP=$!
mkdir "$L"; printf '%s %s\n' "$DP" "$(ps -o lstart= -p "$DP" | sed 's/^ *//; s/ *$//')" > "$L/pid"; L0=$(cat "$L/pid")
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a held lock' -- tests/x > "$T/out" 2>&1 || fail '1: the request was refused'
TK=$(tk); TD=.vid/requests/$TK
RC1=0; VID_WAIT_MAX=90 sh checks/test.sh wait "$TK" > "$T/out.wait" 2>&1 || RC1=$?
[ "$RC1" -eq 1 ] || fail "1: wait exited $RC1, not 1, for a passing run with no receipt"
[ "$(cat "$TD/exit")" = 1 ] || fail "1: the run's exit is $(cat "$TD/exit"), not 1"
sed -n 1p "$TD/result" | grep -q '^status=1 ran-to-end=yes capped=no report=none$' || fail "1: the result's status line: $(sed -n 1p "$TD/result")"
[ "$(unpub)" -eq 1 ] || fail '1: the report is not kept beside as .unpublished'
U=$(ls .vid/ledger-results | grep '\.unpublished$')
[ -z "$(kept | grep -v '\.unpublished$')" ] || fail "1: a receipt was kept: $(kept)"
grep -q 'ROW-001' ".vid/ledger-results/$U" || fail '1: the .unpublished file is not the run'"'"'s report'
[ "$(cat "$TD/passes")" = "$(printf 'none\tscoped\t0\tyes\t-')" ] || fail "1: the passes line: $(cat "$TD/passes")"
[ "$(grep -c '^ledger-run ' .vid/metrics-events)" -eq 1 ] || fail '1: not one ledger-run event'
grep -qE "^ledger-run seconds=[0-9]+ kind=scoped report=none status=0 role=builder .* request=$TK .* pid=$DP why=publish-lock-held at=" .vid/metrics-events || fail "1: the event: $(grep '^ledger-run ' .vid/metrics-events)"
grep -qE "^why: no report — the publish lock is held by pid $DP since [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z; the report is at .*/$U\$" "$TD/result" || fail "1: the result's why: $(grep '^why:' "$TD/result")"
[ "$(cat "$L/pid" 2>/dev/null)" = "$L0" ] || fail '1: the live holder'"'"'s lock was touched'
kill "$DP" 2>/dev/null || true; wait "$DP" 2>/dev/null || true; DP=''

# 2. a standing reclaim folder beside a dead holder's lock, two publishers waiting
gated_repo "$T/r2"; gate_on; mkdir -p .vid/ledger-results
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
sleep 0 & D=$!; wait "$D" || true
mkdir "$L" "$RC"; printf '%s Thu Jan  1 00:00:00 1970\n' "$D" > "$L/pid"; L0=$(cat "$L/pid")
VID_REQUEST=selftest-direct sh checks/test.sh --role close > "$T/out.a" 2>&1 & PA=$!
VID_REQUEST=selftest-direct sh checks/test.sh --role close > "$T/out.b" 2>&1 & PB=$!
RA=0; wait "$PA" || RA=$?; RB=0; wait "$PB" || RB=$?
[ "$RA" -ne 0 ] && [ "$RB" -ne 0 ] || fail "2: a publisher with no receipt exited 0 ($RA, $RB)"
[ -d "$RC" ] || fail '2: the standing reclaim folder was removed by a publisher'
[ "$(cat "$L/pid" 2>/dev/null)" = "$L0" ] || fail '2: the dead holder'"'"'s lock was removed without the reclaim folder'
for o in a b; do
  grep -q "^ViD test: no report — the publish lock's reclaim folder .*/.vid/ledger-results/.publish.reclaim stands; remove it if no ViD test runs; the report is at .*\.unpublished\$" "$T/out.$o" || fail "2: publisher $o does not name the reclaim folder"
done
[ "$(unpub)" -eq 2 ] || fail '2: not two .unpublished reports'
[ -z "$(kept | grep -v '\.unpublished$')" ] || fail "2: a receipt was kept: $(kept)"
[ "$(grep -c "^ledger-run .* report=none status=0 .* pid=$D why=publish-reclaim-stands at=" .vid/metrics-events)" -eq 2 ] || fail "2: not two reclaim-stands events: $(grep '^ledger-run ' .vid/metrics-events)"
exit 0

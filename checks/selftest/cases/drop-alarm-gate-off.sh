#!/bin/sh
# Purpose: selftest case — the drop alarm reads no map while the gate is off (FIX-BATCH-T1 §16, B-4). A gated toy run, 30
# rows passing on a receipt, the observer ticking on a replay clock. Convicts unless: a tick with the run active keeps 30
# passing; with `run: complete`, and then with a plain `run: stopped`, a tick records no new line in .vid/observer.passing and
# raises no drop notice (plan.sh map prints its note then, exit 0, and the alarm took it for a map of no rows); and with the
# run active again and 25 rows red, a tick raises the notice as before. And in ticket mode (both GitHub modes), whose loop keeps ticking after
# run: complete: ticks after it record nothing and raise no notice. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "drop-alarm-gate-off: $*" >&2; cat "$T/tick.out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" checks/; rm -f checks/progress.sh
rows S1 1 30
sed 's/^def test_\([0-9]\)(/def test_00\1(/; s/^def test_\([0-9][0-9]\)(/def test_0\1(/' tests/invariants/test_S1.py > x && mv x tests/invariants/test_S1.py
commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-030' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
all() { _i=$1; while [ "$_i" -le "$2" ]; do printf 'ROW-%03d=%s\n' "$_i" "$3"; _i=$((_i + 1)); done; }
rcpt r1 HEAD inline $(all 1 30 passed)
export VID_OBSERVE_INTERVAL=60
N0=$(date +%s)
tick() { VID_OBSERVE_NOW=$((N0 + $1)) sh checks/observe.sh tick > "$T/tick.out" 2>&1 || true; }
notes() { sed -n 's/^- [^|]* | observe: notice — \(ViD: passing rows fell.*\)$/\1/p' .vid/HEARTBEAT.md 2>/dev/null; }
runis() { sed "s/^run:.*/run: $1/" .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md; }
tick 0
[ "$(awk '{ print $3 }' .vid/observer.passing | tail -n 1)" = 30 ] || fail "the first tick did not keep 30 passing: $(cat .vid/observer.passing 2>/dev/null)"
n=1
for r in complete stopped; do
  runis "$r"; L0=$(grep -c . .vid/observer.passing)
  tick $((n * 60)); n=$((n + 1))
  [ "$(grep -c . .vid/observer.passing)" -eq "$L0" ] || fail "with run: $r a tick recorded passing: $(tail -n 1 .vid/observer.passing | cut -d' ' -f1-3)"
  [ -z "$(notes)" ] || fail "with run: $r a drop notice was raised: $(notes)"
done
runis active
rcpt r2 HEAD inline $(all 1 5 passed) $(all 6 30 failed)
tick $((n * 60))
notes | grep -q 'fell from 30 to 5' || fail "a real fall of 25 with the gate on raised no notice: $(notes)"
# ticket mode (both GitHub modes): the gate is held by a run stage, and the loop keeps ticking after run: complete
rcpt r3 HEAD inline $(all 1 30 passed); : > .vid/observer.passing; : > .vid/observer.drop
sed '/^## The plan/i\
mode: tickets
' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md; [ -f "$CHECKS/planner.sh" ] && cp "$CHECKS/planner.sh" "$CHECKS/lib.sh" checks/
printf 'stage name=run state=start session=S1 records=29 at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/plan.sh gate > "$T/gate" 2>&1 || fail "ticket mode: the gate is off with a run stage started: $(cat "$T/gate")"
N1=$(notes | grep -c . || true); n=$((n + 10)); tick $((n * 60))
[ "$(awk '{ print $3 }' .vid/observer.passing | tail -n 1)" = 30 ] || fail "ticket mode: the tick did not keep 30 passing: $(cat .vid/observer.passing)"
runis complete; L0=$(grep -c . .vid/observer.passing)
for k in 1 2; do n=$((n + 1)); tick $((n * 60)); done
[ "$(grep -c . .vid/observer.passing)" -eq "$L0" ] || fail "ticket mode, run: complete: a tick recorded passing: $(tail -n 1 .vid/observer.passing | cut -d' ' -f1-3)"
[ "$(notes | grep -c . || true)" -eq "$N1" ] || fail "ticket mode, run: complete: a drop notice was raised: $(notes | tail -n 1)"
exit 0

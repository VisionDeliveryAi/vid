#!/bin/sh
# Purpose: selftest case — the overrun notice (v0.26.10.24 R6, R7). A request whose estimate is forced small and whose
# stub runner holds past twice it: one `overrun` event, written once. It ends before the watcher's first tick, and a
# deploy start then a develop start follow; that tick gives one notice naming the ticket; another gives no repeat. A second
# such request still running: `observe.sh notices` prints it while it runs and not after. `mode: tickets`: no notice.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold" "$T/hold2"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "notice-overrun: $*" >&2; cat "$T/out" .vid/metrics-events .vid/HEARTBEAT.md >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
cp "$CHECKS/observe.sh" "$CHECKS/event.sh" checks/
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
g add -A && g commit -qm 'one row'
gate_on
export VID_OBSERVE_INTERVAL=60
# three recorded runs with no start-up, so the estimate is --expect's 1 s alone
for _r in a b c; do printf 'ledger-run seconds=1 kind=scoped report=%s status=0 tree=x run=r overhead=0 at=%s\n' "$_r" "$(utcnow)" >> .vid/metrics-events; done
# ask <hold file>: a request of 1 s, held; TK its ticket, TD its folder, once the overrun is recorded
ask() {
  touch "$1"
  STUB_HOLD="$1" sh checks/test.sh request --type full --role orchestrator --why 'a run past its estimate' --expect 1 > "$T/out" 2>&1 || fail 'the request was refused'
  TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
  _i=0; while ! grep -q "^overrun ticket=$TK " .vid/metrics-events && [ "$_i" -lt 60 ]; do sleep 1; _i=$((_i + 1)); done
  grep -q "^overrun ticket=$TK estimate=[0-9]* awake=[0-9]* at=" .vid/metrics-events || fail "no overrun event for $TK"
}
# end <hold file>: the run released, and over
end() { rm -f "$1"; _i=0; while ! grep -qxE 'done|capped|stopped|failed-to-start' "$TD/state" 2>/dev/null && [ "$_i" -lt 60 ]; do sleep 1; _i=$((_i + 1)); done; grep -qxE 'done|capped|stopped|failed-to-start' "$TD/state" || fail 'the run did not end'; }
tick() { sh checks/observe.sh tick --now > "$T/tick.out" 2>&1 || fail 'the tick failed'; }
nn() { grep -c "observe: notice — ViD: test run ${1:-}" .vid/HEARTBEAT.md 2>/dev/null || true; }
ask "$T/hold"; T1=$TK
sleep 6
end "$T/hold"
[ "$(grep -c "^overrun ticket=$T1 " .vid/metrics-events)" -eq 1 ] || fail 'the overrun was written more than once'
printf 'stage name=deploy state=start session=S1 records=28 at=%s\n' "$(utcnow)" >> .vid/metrics-events
printf 'stage name=develop state=start session=S1 records=29 at=%s\n' "$(utcnow)" >> .vid/metrics-events
tick
[ "$(nn "$T1")" -eq 1 ] || fail 'the tick gave no notice naming the ticket'
grep -q "ViD: test run $T1 passed twice its estimate ([0-9]* min) at [0-9]* min\." .vid/HEARTBEAT.md || fail 'the notice is not in its form'
tick
[ "$(nn "$T1")" -eq 1 ] || fail 'the notice repeated'
ask "$T/hold2"; T2=$TK
sh checks/observe.sh notices > "$T/out" 2>&1
[ "$(cut -f1 "$T/out")" = "overrun.$T2" ] || fail "notices does not print the running request's overrun, and only it"
end "$T/hold2"
sh checks/observe.sh notices > "$T/out" 2>&1
[ ! -s "$T/out" ] || fail 'notices still prints a request that ended'
cp .vid/RUN-STATE.md "$T/rs"; printf 'mode: tickets\n' >> .vid/RUN-STATE.md
tick
[ "$(nn "$T2")" -eq 0 ] || fail 'mode: tickets gave a notice'
cp "$T/rs" .vid/RUN-STATE.md
tick
[ "$(nn "$T2")" -eq 1 ] || fail 'the second overrun gave no notice'
exit 0

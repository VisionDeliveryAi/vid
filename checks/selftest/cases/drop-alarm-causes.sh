#!/bin/sh
# Purpose: selftest case — the observer's drop alarm and its causes (v0.26.10.3 R6; §5 drop-alarm-causes). A gated
# toy run, 50 rows passing on a receipt, the observer ticking on a replay clock (VID_OBSERVE_NOW). Convicts unless: a
# fall of 19 gives no notice; one more row lost (a fall of 20 within the window) gives one notice, "fell from 50 to 30
# since <the high's HH:MM> UTC", whose parts add up to the 20 rows lost — 5 reset by an amendment (naming its commit),
# 5 now red, 5 not re-run since a test change, 1 held (a scope breach), 4 other (owed now); a tick with no change gives
# no second notice; a further fall of 20 gives a second notice counted from the first one's 30 (20 now red); and the
# state is kept in .vid/observer.passing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "drop-alarm-causes: $*" >&2; cat "$T/tick.out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"
cp "$CHECKS/observe.sh" "$CHECKS/watchdog.sh" checks/; rm -f checks/progress.sh
rows S1 1 50
sed 's/^def test_\([0-9]\)(/def test_00\1(/; s/^def test_\([0-9][0-9]\)(/def test_0\1(/' tests/invariants/test_S1.py > x && mv x tests/invariants/test_S1.py   # the receipt's case names
commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-050' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
all() { _i=$1; while [ "$_i" -le "$2" ]; do printf 'ROW-%03d=%s\n' "$_i" "$3"; _i=$((_i + 1)); done; }
rcpt r1 HEAD inline $(all 1 50 passed)
export VID_OBSERVE_INTERVAL=60
N0=$(date +%s)
tick() { VID_OBSERVE_NOW=$((N0 + $1)) sh checks/observe.sh tick > "$T/tick.out" 2>&1 || true; }
notes() { sed -n 's/^- [^|]* | observe: notice — \(ViD: passing rows fell.*\)$/\1/p' .vid/HEARTBEAT.md 2>/dev/null; }
HM0=$(awk -v e="$N0" 'BEGIN { s = e % 86400; printf "%02d:%02d", int(s / 3600), int((s % 3600) / 60) }')
tick 0
[ "$(awk '{ print $3 }' .vid/observer.passing | tail -n 1)" = 50 ] || fail "the first tick did not keep 50 passing: $(cat .vid/observer.passing 2>/dev/null)"
# 19 rows lost: 5 stale by a test change, 5 reset by an amendment, 5 red, 1 held by a scope breach, 3 owed
for n in 011 012 013 014 015; do sed "s/^def test_\([0-9]*\)(): pass  # ROW-$n\$/def test_\1(): assert True  # ROW-$n/" tests/invariants/test_S1.py > x && mv x tests/invariants/test_S1.py; done
commit_all 'five tests changed'
AM=$(git rev-parse --short=12 HEAD)
for n in 001 002 003 004 005; do printf 'amended row=ROW-%s sha=%s by=obligation at=%s\n' "$n" "$AM" "$(utcnow)" >> .vid/metrics-events; done
rcpt r2 HEAD inline $(all 6 10 failed)
printf 'verdict slice=1 row=ROW-016 result=BREACHED class=product scope="who decides?" brief=b1 quoted-at=%s at=%s\n' "$AM" "$(utcnow)" >> .vid/metrics-events
owe() { for n in "$@"; do sed "s#^\(ROW-$n | .*| REQ-001 | \)tests/invariants/test_S1.py\$#\1owed: prerequisite — a clock; paid at slice 2#" INVENTORY.md > i && mv i INVENTORY.md; done; commit_all "owed $*"; }
owe 017 018 019
tick 600
[ -z "$(notes)" ] || fail "a fall of 19 gave a notice: $(notes)"
[ "$(awk '{ print $3 }' .vid/observer.passing | tail -n 1)" = 31 ] || fail "the second tick does not read 31 passing: $(awk '{ print $1, $3 }' .vid/observer.passing)"
owe 020
tick 1200
[ "$(notes | grep -c .)" -eq 1 ] || fail "a fall of 20 did not give exactly one notice: $(notes)"
[ "$(notes)" = "ViD: passing rows fell from 50 to 30 since $HM0 UTC: 5 reset by an amendment (commits $AM), 5 now red, 5 not re-run since a test change, 1 held, 4 other. Open the session and ask what changed." ] || fail "the notice: $(notes)"
tick 1500
[ "$(notes | grep -c .)" -eq 1 ] || fail "a tick with no further fall gave another notice: $(notes)"
HM2=$(awk -v e="$((N0 + 1200))" 'BEGIN { s = e % 86400; printf "%02d:%02d", int(s / 3600), int((s % 3600) / 60) }')
rcpt r3 HEAD inline $(all 31 50 failed)
tick 1800
[ "$(notes | grep -c .)" -eq 2 ] || fail "a further fall of 20 did not give a second notice: $(notes)"
[ "$(notes | tail -n 1)" = "ViD: passing rows fell from 30 to 10 since $HM2 UTC: 20 now red. Open the session and ask what changed." ] || fail "the second notice: $(notes | tail -n 1)"
exit 0

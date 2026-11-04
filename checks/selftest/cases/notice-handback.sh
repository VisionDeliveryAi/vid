#!/bin/sh
# Purpose: selftest case — the hand-back notice (v0.26.10.24 R5, R7). A develop run, a plan change, then a builder's
# hand-back of S2 that passed 11 of 29 and a new builder brief for S2: one notice naming S2 and "11 of 29", no repeat at a
# second tick, `observe.sh notices` prints it; that brief's own hand-back clears it, and so does a newer brief for the step.
# 14 of 29 gives a notice, 15 of 29 none; a plan change between, none; a brief before the run's start, none; `mode:
# tickets`, none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-handback
. "$CHECKS/selftest/fixtures/observer-lib.sh"
cp "$CHECKS/plan.sh" checks/
export VID_OBSERVE_INTERVAL=1
mkdir -p .vid/briefs/1
B1=.vid/briefs/1/builder-2.md; B2=.vid/briefs/1/builder-3.md
printf 'role: builder    slice: 1    step: S2\n# the brief\n' > "$B1"; cp "$B1" "$B2"
cost() { ev "build-cost role=${4:-builder} slice=1 step=S2 brief=$1 rows=$3 rows-passed=$2 peak=1 total=1 before-change=1" "$(ago "$5")"; }
wrote() { ev "brief-written path=$1 role=builder try=- bytes=9" "$(ago "$2")"; }
# start <k> <n>: a develop run and a plan change, S2 handed back at k of n
start() { reset; rs active; ev 'stage name=develop state=start session=S1 records=29' "$(ago 500)"; ev 'plan-change what=create hash=abc why="x"' "$(ago 400)"; cost .vid/briefs/1/builder-1.md "$1" "$2" builder 300; }
sn() { sh checks/observe.sh notices 2> /dev/null; }
start 11 29; wrote "$B1" 200
tick; [ "$(nnote "step S2's next builder was briefed ($B1) after its last hand-back passed 11 of 29 rows, with no plan change between")" -eq 1 ] || fail 'no notice naming S2 and 11 of 29'
tick; [ "$(nnote 'next builder was briefed')" -eq 1 ] || fail 'the notice repeated'
K=handback.$(printf '%s' "$B1" | cksum | cut -d' ' -f1)
[ "$(sn | grep -c "^$K	ViD: step S2's next builder")" -eq 1 ] || fail 'observe.sh notices does not print it with its key'
grep -q "^notified\.$K " .vid/observer.state || fail 'the notice is not held under its key'
cost "$B1" 20 29 builder 100
[ -z "$(sn)" ] || fail 'the handed-back brief still stands in notices'
tick; grep -q "^notified\.$K " .vid/observer.state && fail "the brief's hand-back did not clear the notice"
start 11 29; wrote "$B1" 200
tick; grep -q "^notified\.$K " .vid/observer.state || fail 'no notice for the first brief'
wrote "$B2" 100
K2=handback.$(printf '%s' "$B2" | cksum | cut -d' ' -f1)
[ "$(sn | cut -f1)" = "$K2" ] || fail 'a newer brief did not replace the first in notices'
tick; grep -q "^notified\.$K " .vid/observer.state && fail 'a newer brief did not clear the first'
start 14 29; wrote "$B1" 200; tick; [ "$(nnote '14 of 29')" -eq 1 ] || fail '14 of 29 gave no notice'
start 15 29; wrote "$B1" 200; tick; [ "$(nnote 'next builder was briefed')" -eq 0 ] || fail '15 of 29 gave a notice'
start 3 15; wrote "$B1" 200; tick; [ "$(nnote "3 of 15")" -eq 1 ] || fail "3 of 15 gave no notice: the counts compared as text"
start 50 99; wrote "$B1" 200; tick; [ "$(nnote "next builder was briefed")" -eq 0 ] || fail "50 of 99 gave a notice: the counts compared as text"
start 11 29; ev 'plan-change what=rows hash=abd why="y"' "$(ago 250)"; wrote "$B1" 200
tick; [ "$(nnote 'next builder was briefed')" -eq 0 ] || fail 'a plan change between gave a notice'
start 11 29; wrote "$B1" 200; ev 'stage name=deploy state=start session=S1 records=28' "$(ago 100)"; ev 'stage name=develop state=start session=S1 records=29' "$(ago 90)"
tick; [ "$(nnote 'next builder was briefed')" -eq 0 ] || fail "a brief before the run's start gave a notice"
start 11 29; wrote "$B1" 200; rs active; awk '{ print } /^session:/ { print "mode: tickets" }' .vid/RUN-STATE.md > "$T/rs"; cp "$T/rs" .vid/RUN-STATE.md
tick; [ "$(nnote 'next builder was briefed')" -eq 0 ] && [ -z "$(sn)" ] || fail 'mode: tickets gave a notice'
exit 0

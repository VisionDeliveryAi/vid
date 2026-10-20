#!/bin/sh
# Purpose: selftest case — reach, checked before each pass is published
# (v0.9.7.0.2 spec 3.3, R7; v0.9.7.0.11 spec 3.1, R1: the spec's
# `outside-rows`). A request whose report's cases the existing join
# (checks/evidence.sh reach --raw) credits to a row outside the request — by
# the row id, and separately by the derived REQ fallback — is published and
# kept all the same: its receipt, its `.rows` (the frozen rows) beside it,
# its event with `outside=<n>`; the result says `outside n=<n> rows=<…> —
# not credited` and the ticket's `outside` names the rows; its exit comes
# from its cases (0 here). `evidence.sh credit` gives only the frozen rows
# and the credit-bearing `reach` leaves the outside row out, while `reach
# --raw` still names it. In a two-pass close an outside inline pass is
# followed by its deployed pass, whose receipt carries `.rows` too, and the
# commit-named copies carry it. The control: a run that stays inside its
# rows keeps its receipt and names no row outside. v0.9.7.3 (R7): each request is waited on until it ends, its cap
# scaled out. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "reach-outside: $*" >&2; cat "$T/out" "$T/res" >&2 2>/dev/null; exit 1; }
# report <file> <case name…>: a report of passed cases
report() { _f=$1; shift; { printf '<report>\n'; for _c in "$@"; do printf '<case name="%s" status="passed" time="0.1"/>\n' "$_c"; done; printf '</report>\n'; } > "$_f"; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
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
    image: runner
'
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 3; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null || fail 'S1 did not start'
TF=tests/invariants/test_s1.py
WST=0
run() { # <report> <request arguments…>: the ticket folder; the wait's exit in $T/wst
  _r=$1; shift
  STUB_REPORT=$_r sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"
  _k=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
  # v0.9.7.3 (R7): waited until the ticket ends (the wait's 75: still queued or running), not for one bounded call
  _i=0; while :; do _w=0; VID_WAIT_MAX=10 sh checks/test.sh wait "$_k" > "$T/res" 2>&1 || _w=$?; [ "$_w" -eq 75 ] && [ "$_i" -lt 120 ] || break; _i=$((_i + 1)); done
  echo "$_w" > "$T/wst"
  echo ".vid/requests/$_k"
}
reps() { grep "^ledger-run .* request=${1##*/} " .vid/metrics-events | sed -n 's/.* report=\([^ ]*\) .*/\1/p'; }
outside_kept() { # <ticket folder> <n> <frozen rows, comma-separated> <label>
  _e=$(grep "^ledger-run .* request=${1##*/} " .vid/metrics-events | head -n 1)
  printf '%s\n' "$_e" | grep -q ' report=none ' && fail "$4: the report was withheld"
  printf '%s\n' "$_e" | grep -q " outside=$2 " || fail "$4: the event does not carry outside=$2"
  _k=$(reps "$1" | head -n 1); [ -f ".vid/ledger-results/$_k" ] || fail "$4: no receipt kept"
  [ "$(paste -sd ',' - < ".vid/ledger-results/$_k.rows")" = "$3" ] || fail "$4: the receipt's .rows is not the frozen rows $3"
  [ "$(sh checks/evidence.sh credit "$_k" | paste -sd ',' -)" = "$3" ] || fail "$4: credit is not the frozen rows"
  sh checks/evidence.sh reach "$_k" | cut -f2 | grep -qvxF -f ".vid/ledger-results/$_k.rows" && fail "$4: the credit-bearing reach names an outside row"
  sh checks/evidence.sh reach "$_k" --raw | cut -f2 | grep -qvxF -f ".vid/ledger-results/$_k.rows" || fail "$4: reach --raw does not name the outside row"
  grep -q "^outside n=$2 rows=.* — not credited$" "$T/res" || fail "$4: the result does not say the outside rows are not credited"
  [ "$(cat "$T/wst")" = 0 ] || fail "$4: the exit is $(cat "$T/wst"), not its cases' 0"
  ls "$1"/*.xml > /dev/null 2>&1 && fail "$4: a candidate was kept in the ticket folder"
  return 0
}
# by id: ROW-002's own case in a request for ROW-001
report "$T/r1" "$TF::test_1[ROW-001]" "$TF::test_2[ROW-002]"
D=$(run "$T/r1" --type iterate --role builder --try t1 --rows ROW-001 --why 'a whole file for one row' -- "$TF")
outside_kept "$D" 1 ROW-001 'by id'
grep -qx 'ROW-002' "$D/outside" || fail 'by id: ROW-002 is not named'
# by the REQ fallback: a case naming only REQ-001, which ROW-002 derives from
report "$T/r2" "$TF::test_1[ROW-001]" "$TF::test_req[REQ_001]"
D=$(run "$T/r2" --type iterate --role builder --try t1 --rows ROW-001 --why 'a REQ-level case' -- "$TF")
outside_kept "$D" 1 ROW-001 'by REQ'
grep -qx 'ROW-002' "$D/outside" || fail 'by REQ: ROW-002 is not named'
# a two-pass close of S1 reaching ROW-003 (S2's) inline: kept, and the deployed pass runs
mkdir -p .vid/close; : > .vid/close/1.rows
report "$T/r3" "$TF::test_1[ROW-001]" "$TF::test_2[ROW-002]" "tests/invariants/test_s2.py::test_3[ROW-003]"
: > "$STUB_LOG"
D=$(run "$T/r3" --type close --role orchestrator --steps S1 --why 'the close of S1' -- 'sel-s1' --deployed-selection 'sel-dep')
outside_kept "$D" 1 ROW-001,ROW-002 'close'
grep -q 'profile deployed' "$STUB_LOG" || fail 'close: the deployed pass did not run after an outside inline pass'
[ "$(reps "$D" | grep -c .)" -eq 2 ] || fail 'close: both passes were not published'
for _k in $(reps "$D"); do [ -f ".vid/ledger-results/$_k.rows" ] || fail "close: $_k carries no .rows"; done
H=$(git rev-parse --short=12 HEAD)
for _c in "$H.close.xml" "$H.close.deployed.xml"; do cmp -s ".vid/ledger-results/$_c.rows" "$D/rows" || fail "close: the copy $_c does not carry the frozen rows"; done
# the control: inside its rows, the receipt is kept and nothing is named outside
report "$T/r4" "$TF::test_1[ROW-001]" "$TF::test_2[ROW-002]"
D=$(run "$T/r4" --type iterate --role builder --try t1 --rows ROW-001,ROW-002 --why 'both rows of the file' -- "$TF")
_k=$(reps "$D"); [ -f ".vid/ledger-results/$_k" ] || fail 'control: the receipt inside its rows was not kept'
grep "^ledger-run .* request=${D##*/} " .vid/metrics-events | grep -q ' outside=' && fail 'control: the event carries outside='
[ ! -f "$D/outside" ] || fail 'control: rows were named outside'
grep -q '^outside ' "$T/res" && fail 'control: the result names rows outside'
exit 0

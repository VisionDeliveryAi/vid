#!/bin/sh
# Purpose: selftest case — a worktree with no run of its own and no
# .vid/home finds the one live develop run among the repository's
# checkouts (v0.9.7.0.1 spec 3.1, R1, R3, R4; §6 A-1, A-2). A linked
# worktree with no .vid/ at all: `plan.sh gate` is on at the main
# checkout's run; a scoped `test.sh --role builder` run there takes a
# slot and no lock, and publishes its receipt and event at the main
# checkout, writing nothing under its own .vid/. The same with the live
# run in another linked worktree (main holding none): the run is found
# there. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "home-discover: $*" >&2; cat "$T"/out* >&2 2>/dev/null; exit 1; }
# A-1: the live run in the main checkout
gated_repo "$T/main"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
HOMEP=$(pwd -P)
g worktree add -q "$T/W" -b w 2>/dev/null
cd "$T/W"
[ ! -e .vid ] || fail 'the fixture worktree carries a .vid/'
[ "$(sh checks/plan.sh gate 2>&1)" = "on $HOMEP" ] || { sh checks/plan.sh gate > "$T/out.g" 2>&1; fail 'the gate in the unlinked worktree is not on at the main checkout'; }
[ "$(sh checks/plan.sh home-of)" = "$HOMEP" ] || fail 'home-of does not print the main checkout'
touch "$T/hold"; ( STUB_HOLD="$T/hold" STUB_ENTER="$T/in" sh checks/test.sh --role builder -- 'tests/x' > "$T/out.1" 2>&1 ) & P=$!
waitfor "$T/in" || fail 'the run never came up'
[ -d "$XDG_RUNTIME_DIR/vid-host/stack.1" ] || fail 'the run took no slot'
[ ! -d .vid/ledger.lock ] || fail 'the run took the lock (it ran ungated)'
rm -f "$T/hold"; wait "$P" || fail 'the discovered run failed'
cd "$HOMEP"
[ "$(kept | grep -c '\.live\.sel-')" -eq 1 ] || fail "the receipt is not at the main checkout: $(kept)"
grep -q '^ledger-run .* kind=scoped .* role=builder .* run=' .vid/metrics-events || fail 'the event is not at the main checkout'
[ ! -e "$T/W/.vid" ] || [ -z "$(find "$T/W/.vid" -type f)" ] || fail "the worktree's own .vid/ holds records: $(find "$T/W/.vid" -type f)"
# A-2: the live run in another linked worktree, the main checkout holding none
cd "$T"; rm -rf "$T/run"; mkdir -p "$T/run"; : > "$STUB_LOG"
gated_repo "$T/main2"
g worktree add -q "$T/O" -b orch 2>/dev/null
g worktree add -q "$T/B" -b b 2>/dev/null
cd "$T/O"; mkdir -p .vid; gate_on; OP=$(pwd -P)
cd "$T/B"
[ "$(sh checks/plan.sh gate 2>&1)" = "on $OP" ] || { sh checks/plan.sh gate > "$T/out.g" 2>&1; fail 'the gate in the unlinked worktree is not on at the linked home'; }
sh checks/test.sh --role builder -- 'tests/x' > "$T/out.2" 2>&1 || fail 'the run found in a linked worktree failed'
cd "$OP"
[ "$(kept | grep -c '\.live\.sel-')" -eq 1 ] || fail "the receipt is not at the linked home: $(kept)"
grep -q '^ledger-run .* role=builder .* run=' .vid/metrics-events || fail 'the event is not at the linked home'
[ ! -e "$T/main2/.vid/metrics-events" ] && [ -z "$(ls "$T/main2/.vid/ledger-results" 2>/dev/null)" ] || fail 'the main checkout received records'
[ ! -e "$T/B/.vid" ] || [ -z "$(find "$T/B/.vid" -type f)" ] || fail "the worktree's own .vid/ holds records"
exit 0

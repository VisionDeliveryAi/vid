#!/bin/sh
# Purpose: selftest case — a dirty worktree: refused when asked, waited out
# when queued (v0.9.7.0.11 spec 3.6, R6). An export-backed request (here
# `full`) asked while an untracked file exists is refused at once, naming
# the file, with no ticket. A clean request queued behind a held slot,
# whose worktree turns dirty while it waits, waits — its `holders` says
# `waiting for a clean worktree: <path>` — then runs once the change is
# committed, HEAD's tree at serve (its receipt's base is the new commit).
# With the bound lowered for the test (VID_DIRTY_WAIT=3), a worktree still
# dirty is refused as before: no receipt, the result says why. A scoped
# request is never held for a dirty worktree. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "request-dirty: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > /dev/null || fail 'S1 did not start'
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
full() { sh checks/test.sh request --type full --role orchestrator --why "$1" > "$T/out" 2>&1; }
hold() { : > "$T/hold"; STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'holds the slot' -- tests/x > "$T/out" 2>&1 || fail 'the holding request was refused'
  HK=$(tk); waitfor "$T/run/vid-host/stack.1/holder" || fail 'the holding request took no slot'; }
# 1. asked dirty: refused now, no ticket
printf 'scaffold\n' > scratch.txt
NT=$(ls .vid/requests 2>/dev/null | grep -c . || true)
if full 'dirty at request'; then fail 'a full request was accepted on a dirty worktree'; fi
grep -q 'uncommitted changes.*scratch.txt' "$T/out" || fail 'the refusal does not name the untracked file'
[ "$(ls .vid/requests 2>/dev/null | grep -c . || true)" -eq "$NT" ] || fail 'a refused request left a ticket'
rm -f scratch.txt
# 2. dirty while queued: waited out, then HEAD's tree at serve
hold
full 'clean at request' || fail 'a clean full request was refused'; F=$(tk)
printf 'main v2\n' > app/main.py
rm -f "$T/hold"; VID_WAIT_MAX=30 sh checks/test.sh wait "$HK" > /dev/null 2>&1 || true
sleep 3
[ "$(cat ".vid/requests/$F/state")" = queued ] || fail "the request did not wait for the dirty worktree (state $(cat ".vid/requests/$F/state"))"
grep -q 'waiting for a clean worktree: app/main.py' ".vid/requests/$F/holders" || fail 'the request does not say it waits for a clean worktree'
commit_all 'the change in progress'; NEW=$(git rev-parse --short=12 HEAD)
VID_WAIT_MAX=60 sh checks/test.sh wait "$F" > "$T/out" 2>&1 || fail 'the request did not run once the worktree was clean'
R=$(grep "^ledger-run .* request=$F " .vid/metrics-events | head -n 1 | sed -n 's/.* report=\([^ ]*\) .*/\1/p')
grep -qx "base=$NEW" ".vid/ledger-results/$R.tree" || fail 'the run did not test HEAD at serve'
# 3. still dirty past the bound: refused as before
export VID_DIRTY_WAIT=3
hold
full 'clean at request, dirty for good' || fail 'the third full request was refused'; F=$(tk)
printf 'main v3\n' > app/main.py
rm -f "$T/hold"
if VID_WAIT_MAX=60 sh checks/test.sh wait "$F" > "$T/out" 2>&1; then fail 'a request still dirty past the bound ran'; fi
grep -q 'uncommitted changes' "$T/out" || fail 'the result does not say the worktree was dirty'
grep "^ledger-run .* request=$F " .vid/metrics-events | grep -qv ' report=none ' && fail 'a receipt was kept'
# 4. a scoped request is never held for a dirty worktree
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'scoped, dirty' -- tests/x > "$T/out" 2>&1 || fail 'a scoped request on a dirty worktree was refused'
VID_WAIT_MAX=30 sh checks/test.sh wait "$(tk)" > "$T/out" 2>&1 || fail 'a scoped request on a dirty worktree did not run'
exit 0

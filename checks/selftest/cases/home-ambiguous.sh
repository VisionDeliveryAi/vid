#!/bin/sh
# Purpose: selftest case — two live develop runs among the checkouts never
# pick one and never run ungated (v0.9.7.0.1 spec 3.1, R2; §6 A-3). In a
# worktree with no run and no .vid/home: `plan.sh gate` exits 3 (`off
# ambiguous …`); `test.sh` refuses with exit 2 naming `plan.sh home
# --brief`, and no environment comes up (no Compose call, no slot, no
# lock); `plan.sh start`, the admission through `brief.sh` and `plan.sh
# redstamp --staged` refuse — none passes as "rules off". With a .vid/home
# link to one of the runs, every one of them goes there. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "home-ambiguous: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/main"; rows s1 1 2; commit_all rows
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
HOMEP=$(pwd -P)
plan 'step S1 | name: base | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
mkdir -p .vid/briefs/1; printf 'role: builder    slice: 1    step: S1\n' > .vid/briefs/1/builder-1.md
g worktree add -q "$T/W1" -b w1 2>/dev/null
( cd "$T/W1" && mkdir -p .vid && gate_on )
g worktree add -q "$T/X" -b x 2>/dev/null
cd "$T/X"
# ambiguous
RC=0; sh checks/plan.sh gate > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 3 ] || fail "plan.sh gate exited $RC, not 3"
grep -q '^off ambiguous' "$T/out" && grep -qF 'plan.sh home --brief' "$T/out" || fail 'the gate does not say ambiguous, naming plan.sh home --brief'
: > "$STUB_LOG"
RC=0; sh checks/test.sh --role builder -- 'tests/x' > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] || fail "test.sh exited $RC on ambiguity, not 2"
grep -qF 'plan.sh home --brief' "$T/out" || fail 'the refusal does not name plan.sh home --brief'
[ ! -s "$STUB_LOG" ] || fail "an environment was touched: $(cat "$STUB_LOG")"
[ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null)" ] || fail 'a slot was taken'
[ ! -d .vid/ledger.lock ] || fail 'the lock was taken'
RC=0; sh checks/plan.sh start S1 > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] && grep -q 'cannot tell which run' "$T/out" || fail "plan.sh start passed on ambiguity (exit $RC)"
brief .vid/briefs/1/builder-1.md builder S1 ROW-001
if sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1; then fail 'the admission through brief.sh passed on ambiguity'; fi
grep -q 'cannot tell which run' "$T/out" || fail 'the brief refusal does not say why'
RC=0; sh checks/plan.sh redstamp --staged > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] && grep -q 'cannot tell which run' "$T/out" || fail "redstamp passed on ambiguity (exit $RC)"
grep -q '^step-start' "$HOMEP/.vid/metrics-events" && fail 'a step started on ambiguity'
# linked to one of them
sh checks/plan.sh home --brief "$HOMEP/.vid/briefs/1/builder-1.md" > "$T/out" 2>&1 || fail 'plan.sh home refused'
[ "$(sh checks/plan.sh gate 2>&1)" = "on $HOMEP" ] || fail 'the linked gate is not on at the named home'
sh checks/test.sh --role builder -- 'tests/x' > "$T/out" 2>&1 || fail 'the linked run failed'
( cd "$HOMEP" && [ "$(kept | grep -c '\.live\.sel-')" -eq 1 ] ) || fail 'the linked receipt is not at the home'
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'plan.sh start refused once linked'
grep -q '^step-start step=S1 ' "$HOMEP/.vid/metrics-events" || fail 'the step-start is not at the home'
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'the brief was refused once linked'
sh checks/plan.sh redstamp --staged > "$T/out" 2>&1 || fail 'redstamp refused once linked'
exit 0

#!/bin/sh
# Purpose: selftest case — a builder worktree's records land at the run's
# home (v0.9.6 spec 3.6, R6; §7 case 28). `plan.sh home --brief <brief>`
# in a builder worktree records the worktree holding the brief in
# .vid/home; the builder's scoped run publishes its receipt and event
# there, and a commit amending a row writes its `amended` event there, none
# of it in the builder's own .vid/. A linked worktree with neither
# .vid/home nor RUN-STATE finds the one live run, v0.9.7.0.1 (3.1, R1):
# `plan.sh gate` is on there, at the home. In a repository with no live
# run it has no gated run: the gate is off there and its test run takes
# the lock. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "home: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
mkdir -p checks/hooks; cp "$CHECKS/hooks/post-commit" checks/hooks/; commit_all 'the post-commit hook'
g config core.hooksPath checks/hooks
HOMEP=$(pwd -P)
mkdir -p .vid/briefs/1; printf 'role: builder    slice: 1    step: S1\n' > .vid/briefs/1/builder-1.md
g worktree add -q "$T/builder" -b builder 2>/dev/null
g worktree add -q "$T/stray" -b stray 2>/dev/null
cd "$T/builder"
sh checks/plan.sh home --brief "$HOMEP/.vid/briefs/1/builder-1.md" > "$T/out" 2>&1 || fail 'home --brief was refused'
[ "$(cat .vid/home)" = "$HOMEP" ] || fail ".vid/home does not name the brief's worktree"
VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/x' > "$T/out" 2>&1 || fail 'the builder run failed'   # v0.9.7.0.2: a direct call, as the test manager makes
sed 's/^\(ROW-001 | behavior | s1 | anon | - | \)x/\1amended here/' INVENTORY.md > x && mv x INVENTORY.md
g add INVENTORY.md && g commit -qm 'ROW-001 amended in the builder' > /dev/null
cd "$HOMEP"
grep -q '^ledger-run .* role=builder ' .vid/metrics-events || fail "the builder's event is not at the home"
[ "$(kept | grep -c .)" -eq 1 ] || fail "the builder's receipt is not at the home"
grep -q '^amended row=ROW-001 ' .vid/metrics-events || fail "the builder's amendment is not at the home"
[ -z "$(ls "$T/builder/.vid/ledger-results" 2>/dev/null)" ] && [ ! -f "$T/builder/.vid/metrics-events" ] || fail "the builder's own .vid/ holds records"
cd "$T/stray"
[ "$(sh checks/plan.sh gate 2>&1)" = "on $HOMEP" ] || { sh checks/plan.sh gate > "$T/out" 2>&1; fail 'the stray worktree did not find the live run'; }
sed 's/^run: .*/run: stopped owner asked to pause/' "$HOMEP/.vid/RUN-STATE.md" > "$T/rs" && mv "$T/rs" "$HOMEP/.vid/RUN-STATE.md"
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'the gate is on in a worktree with no home, no RUN-STATE and no live run'; fi
touch "$T/hold"; ( STUB_HOLD="$T/hold" STUB_ENTER="$T/in" sh checks/test.sh -- x > "$T/out2" 2>&1 ) & P=$!
waitfor "$T/in" || fail 'the stray run never came up'
[ -d .vid/ledger.lock ] || fail 'the stray worktree'"'"'s run took no lock (it ran gated)'
rm -f "$T/hold"; wait "$P" || true
exit 0

#!/bin/sh
# Purpose: selftest case — a brief path with spaces is never cut, and a missing hand-back is said (v0.9.8.1 R7, F-1;
# the live project's A-272). The brief-write fixture in a folder whose path holds spaces and ends in one: a builder's
# return naming its brief by the absolute path records `brief=` relative to the home; a second check of it records
# nothing, and so does a check after an older record of the same brief by its absolute path. Then progress, with a
# Codex build-cost recording an absolute brief path (an older record) and one naming a hand-back the home lacks,
# counts the Codex row passed and says one hand-back was not found. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "progress-brief-space: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep '^build-cost' .vid/metrics-events >&2; exit 1; }
bw_plugin; bw_repo "$T/a b /c /repo "; bw_builder; bw_return || fail 'the fixture brief was refused'
H=$(pwd -P); B=$(bw_out); B=${B#./}; case "$B" in /*) B=${B#"$H"/} ;; esac
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$H/$B" "$(git rev-parse HEAD)" "$GREEN" > "${B%.md}.return.md"
sh checks/brief.sh return "${B%.md}.return.md" > "$T/out" 2>&1 || fail 'the return naming its brief by the absolute path was refused'
grep -q "^build-cost .* brief=$B rows=" .vid/metrics-events || fail 'build-cost does not record brief= relative to the home'
sh checks/brief.sh return "${B%.md}.return.md" > "$T/out" 2>&1 || fail 'the second check failed'
[ "$(grep -c '^build-cost ' .vid/metrics-events)" = 1 ] || fail 'a second check recorded again'
# an older record by the absolute path: the guard reads it whole
grep -v '^build-cost ' .vid/metrics-events > .vid/e.x; grep '^build-cost ' .vid/metrics-events | sed "s# brief=$B # brief=$H/$B #" >> .vid/e.x; mv .vid/e.x .vid/metrics-events
grep -q "brief=$H/$B rows=" .vid/metrics-events || fail 'the fixture did not take the absolute path'
sh checks/brief.sh return "${B%.md}.return.md" > "$T/out" 2>&1 || fail 'the check after an older record failed'
grep -q 'already recorded' "$T/out" && [ "$(grep -c '^build-cost ' .vid/metrics-events)" = 1 ] || fail 'an older record by the absolute path was not read whole by the guard'
# progress: a Codex build-cost by an absolute path with spaces, one whose hand-back is missing
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
EV="$T/ev"; cp .vid/metrics-events "$EV"
plan_repo "$T/d e /run "; cp "$CHECKS/plan.sh" checks/; rows s1 1 2; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one' --trigger initial --expect x > /dev/null
R=$(pwd -P); mkdir -p .vid/briefs/1
printf 'brief: x\nagent: codex:t1\nbranch: b\ncommit: x\nROW-001 | pass | r1\nROW-002 | not | none | not built\n' > .vid/briefs/1/builder-3.return.md
printf 'brief: x\n' > .vid/briefs/1/builder-3.md
printf 'build-cost role=builder slice=1 step=S1 brief=%s/.vid/briefs/1/builder-3.md rows=2 rows-passed=1 peak=unknown total=1 before-change=unknown tool=codex model=m effort=e brief-bytes=9 at=%s\n' "$R" "$(utcnow)" >> .vid/metrics-events
printf 'build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-4.md rows=1 rows-passed=1 peak=unknown total=1 before-change=unknown tool=codex model=m effort=e brief-bytes=9 at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep '^| By builder tool ' "$T/out" | grep -q 'codex: steps 1 · follow-up briefs 1 · rows passed 1 ' || fail "the Codex row passed is not counted: $(grep '^| By builder tool' "$T/out")"
grep '^| By builder tool ' "$T/out" | grep -q 'hand-backs not found 1 (their rows not counted)' || fail "the missing hand-back is not said: $(grep '^| By builder tool' "$T/out")"
exit 0

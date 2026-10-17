#!/bin/sh
# Purpose: selftest case — builders at once (v0.9.7.2 spec 3.11, R15). At 12:00: a builder agent from 09:00 to 11:00, a
# fixer from 11:30 still open, a grader (not counted), a Codex job from 09:00 whose latest event is
# job-recovery-required (stays open), and one from 02:00 to 04:00 (outside the 6 hours). Progress reads `2 open ·
# target 3 · last 6 h average 0.9` (2 + 0.5 + 3 hours over 6), the target the owner's .vid/budget value; without one,
# `target none`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "builders-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
{ D=2026-10-13
  echo "job-start try=1-builder-0 step=S1 at=${D}T02:00:00Z"; echo "job-exit try=1-builder-0 exit=0 reason=exit at=${D}T04:00:00Z"
  echo "agent-start session=S1 agent=b1 type=vid:builder at=${D}T09:00:00Z"; echo "job-start try=1-builder-1 step=S1 at=${D}T09:00:00Z"
  echo "agent-start session=S1 agent=g1 type=vid:grader at=${D}T09:30:00Z"
  echo "job-stop try=1-builder-1 saved=no at=${D}T10:00:00Z"; echo "job-recovery-required try=1-builder-1 reason=group-remains at=${D}T10:00:01Z"
  echo "agent-stop session=S1 agent=b1 type=vid:builder transcript=x at=${D}T11:00:00Z"
  echo "agent-start session=S1 agent=f1 type=vid:fixer at=${D}T11:30:00Z"; } >> .vid/metrics-events
VID_PROGRESS_AT=2026-10-13T12:00:00Z sh checks/progress.sh > "$T/out" 2>&1
grep -qxF '| Builders at once | 2 open · target none · last 6 h average 0.9 |' "$T/out" || fail "the line: $(grep '^| Builders at once' "$T/out")"
printf 'builders-target=3\n' >> .vid/budget
VID_PROGRESS_AT=2026-10-13T12:00:00Z sh checks/progress.sh > "$T/out" 2>&1
grep -qxF '| Builders at once | 2 open · target 3 · last 6 h average 0.9 |' "$T/out" || fail "the target: $(grep '^| Builders at once' "$T/out")"
exit 0

#!/bin/sh
# Purpose: selftest case — develop's skeleton runs outside the gate (v0.26.10.9 spec R5; §5 skeleton-plan-gate).
# RUN-STATE `run: active`, develop's stage start: with `plan: skeleton` the gate is off and says why; with `plan:
# required` and develop's start again it is on. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "skeleton-plan-gate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q; cp "$CHECKS/plan.sh" checks/
printf 'run: active\nsession: S1\nplan: skeleton\nstage: 1\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=29 at=2026-10-24T10:00:00Z\n' > .vid/metrics-events
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'the gate is on under plan: skeleton'; fi
grep -q '^off plan: skeleton' "$T/out" || fail 'the gate does not say plan: skeleton'
sed 's/^plan: skeleton$/plan: required/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=29 at=2026-10-24T11:00:00Z\n' >> .vid/metrics-events
sh checks/plan.sh gate > "$T/out" 2>&1 || fail 'the gate is off under plan: required with develop started'
exit 0
